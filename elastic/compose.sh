#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VOLATILE=''
CERTS='certs'
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--volatile)
      VOLATILE="-volatile"
      NODES="1"
      shift # past argument
      ;;
    
    -n|--nodes)
      NODES="$2"
      shift # past argument
      shift # past value
      ;;
    
    -g|--network)
      NETWORK="$2"
      shift # past argument
      shift # past value
      ;;
    
    -c|--certs)
      CERTS="$2"
      shift # past argument
      shift # past value
      ;;
  esac
done
echo "${VOLATILE}"
source ./env.rc


DEFAULT_NODES=3
re='^[0-9]+$'
if [[ -z $NODES ]] || [[ "$NODES" = "" ]] || [[ !  $NODES =~ $re ]]; then
  echo "How many Elastic Nodes? [ENTER for ${DEFAULT_NODES}]"
  read NODES
fi
if ! [[ $NODES =~ $re ]] ; then
  NODES="${DEFAULT_NODES}"
fi

DEFAULT_NETWORK='aiimi'
if [[ -z $NETWORK ]] || [[ "$NETWORK" = "" ]]; then
  echo "What will be the name of your Docker network? [ENTER for ${DEFAULT_NETWORK}]"
  read NETWORK
fi
if [[ -z $NETWORK ]] || [[ "$NETWORK" = "" ]]; then
# if [[ NODES = '' ]] || ! [[ -z NODES ]]; then
  NETWORK="${DEFAULT_NETWORK}"
fi
export COMPOSE_PROJECT_NAME="${NETWORK}"

HOSTS=()
HOSTS_QUOTED=()
HOSTNAMES=()
YML=()
VOLUMES=()
BALANCING=()
echo "upstream ${COMPOSE_PROJECT_NAME}-loadbalancer {" > ./loadbalancer/elastic.conf
for (( c=1; c<=$NODES; c++ ))
do
  if [ ${#c} = 1 ]; then 
    ID="0${c}" 
  else 
    ID="${c}" 
  fi
  PORT_NUM=$(($c-1))
  if [ ${#c} = 1 ]; then 
    PORT="920${PORT_NUM}" 
  else 
    PORT="92${PORT_NUM}" 
  fi
  HOSTNAME="${COMPOSE_PROJECT_NAME}${ID}"

  HOSTS+=("https://${HOSTNAME}:${PORT}")
  HOSTS_QUOTED+=("\"https://${HOSTNAME}:${PORT}\"")
  HOSTNAMES+=("$HOSTNAME")
  NODEPORT="${PORT}"
  NODENAME="${COMPOSE_PROJECT_NAME}${ID}"
  NODEVOLUME="${COMPOSE_PROJECT_NAME}data${ID}"
  if ! [[ $VOLATILE = "-volatile" ]]; then
    VOLUMES+=("\"$NODEVOLUME\"")
  fi
  BALANCING+=("${HOSTNAME}:${PORT}")

  echo "    server ${HOSTNAME}:9200 weight=2;" >> ./loadbalancer/elastic.conf

  CONF=$(sed "s|NODENAME|${NODENAME}|g" <<< $(cat "elastic-node${VOLATILE}.yml"))
  CONF=$(sed "s|NODEPORT|${NODEPORT}|g" <<< $CONF)
  CONF=$(sed "s|NODENAME|${NODENAME}|g" <<< $CONF)
  CONF=$(sed "s|NODEVOLUME|${NODEVOLUME}|g" <<< $CONF)
  CONF=$(sed "s|CERTS_PATH|${CERTS}|g" <<< $CONF)

  YML+=("$CONF")
done
if [[ $CERTS = 'certs' ]]; then
  VOLUMES+=("\"$CERTS\"")
fi

NODE_NAMES=$(IFS=","; echo "${HOSTNAMES[*]}")


COMPOSE_VOLUMES=$(IFS=","; echo "${VOLUMES[*]}")
  COMPOSED_VOLUMES=$(sed "s|COMPOSE_VOLUMES|${COMPOSE_VOLUMES}|g" <<< $(cat "volumes.yml"))
  
ELASTIC_NODES=$(IFS=""; echo "${YML[*]}")
SETUP=$(sed "s|NODE_NAMES|${NODE_NAMES}|g" <<< $(cat setup-compose.yml))
echo "${SETUP}" > docker-compose.yml
echo "${ELASTIC_NODES}" >> docker-compose.yml
cat loadbalancer.yml | sed "s|NETWORKNAME|${COMPOSE_PROJECT_NAME}|g" | sed "s|CERTS_PATH|${CERTS}|g" >> docker-compose.yml
cat downloader.yml | sed "s|NETWORKNAME|${COMPOSE_PROJECT_NAME}|g" | sed "s|CERTS_PATH|${CERTS}|g" >> docker-compose.yml
cat kibana.yml | sed "s|NETWORKNAME|${COMPOSE_PROJECT_NAME}|g" | sed "s|CERTS_PATH|${CERTS}|g" >> docker-compose.yml
echo "${COMPOSED_VOLUMES}" >> docker-compose.yml


echo "export IM_ELASTIC_SERVERS=\"https://${COMPOSE_PROJECT_NAME}-elastic:9200\"" > ./elastic.rc
echo "export ELASTICSEARCH_HOSTS='[\"https://${COMPOSE_PROJECT_NAME}-elastic:9200\"]'" >> ./elastic.rc

echo "
}
server {
    listen 9200 ssl;
    ssl_certificate /usr/share/elasticsearch/config/certificates/instance/instance.crt;
    ssl_certificate_key /usr/share/elasticsearch/config/certificates/instance/instance.key;
    server_name localhost ${COMPOSE_PROJECT_NAME}-elastic;
    location / {
        proxy_pass https://${COMPOSE_PROJECT_NAME}-loadbalancer;
    }
}"  >> ./loadbalancer/elastic.conf

source ./elastic.rc
echo "${ELASTICSEARCH_HOSTS}"
docker network create "${COMPOSE_PROJECT_NAME}"

if [[ $CERTS = 'certs' ]]; then
docker-compose -f create-certs.yml run --rm create_certs
fi

# if containers fail with max_map_count error, check https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode for guidance to increase it
docker-compose up -d

docker-compose -f apply-license.yml run --rm elastic_license

# go to localhost:5601
# username: elastic
# password: changeme

# run query
# GET /_ssl/certificates
# this will return the paths for the certificates

# should be 
#  /usr/share/elasticsearch/config/certificates/ca/ca.crt
#  /usr/share/elasticsearch/config/certificates/instance/instance.crt


if [[ $CERTS = 'certs' ]]; then
  echo "You can download your new certificates:"
  echo "bundled: http://localhost:9201/certs/bundle.zip"
  echo "certificate p12: http://localhost:9201/certs/elastic-certificates.p12"
  echo "ca p12: http://localhost:9201/certs/elastic-stack-ca.p12"
fi