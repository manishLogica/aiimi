#!/bin/bash
#namespace=$1
RELEASE_TO_BUILD=staging
PORT=443
#if ! [[ -z $namespace ]] && [[ "${namespace}" != "" ]]; then
#    RELEASE_TO_BUILD=$namespace
#fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--release)
      RELEASE_TO_BUILD="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--port)
      PORT="$2"
      shift # past argument
      shift # past value
      ;;
  esac
done

echo "Release: ${RELEASE_TO_BUILD}"
export RELEASE=${RELEASE_TO_BUILD}
export COMPOSE_PROJECT_NAME=AIE-QA-${RELEASE}
export IM_INTERNAL_CERTS=/usr/share/elasticsearch/config/certificates
export IM_CA_PASSWORD=changeme
export IM_CERT_PASSWORD=changeme
export IM_LOGS=/var/log/insightmaker
export IM_AGENTS_COMMON_VOLUME=/agenttmp
export IM_LOG_VOLUME=/var/logs
export IM_DOTNET=dotnet
export IM_LICENSE_KEY=
export IM_LICENSE_SECRET=
export IM_INTERNAL_CERTS=/usr/share/elasticsearch/config/certificates
export IM_ELASTIC_PREFIX=dev
export IM_ELASTIC_SERVERS="https://${RELEASE}-elastic:9200"
export IM_ELASTIC_USER=elastic
export IM_CA_PASSWORD=changeme
export IM_CERT_PASSWORD=changeme
export IM_SYSTEM_SECRET=
export IM_ELASTIC_PASSWORD=changeme
export IM_PORT_JOB_AGENT=2220
export IM_PORT_SOURCE_AGENT=2221
export IM_PORT_SECURITY_AGENT=2222
export IM_PORT_ENRICHMENT_AGENT=2223
export IM_PORT_OCR_AGENT=2224
export IM_PORT_CONTENT_AGENT=2225
export IM_PORT_MIGRATION_AGENT=2226
export IM_HOST_JOB_AGENT=${RELEASE}-job-agent
export IM_HOST_SOURCE_AGENT=${RELEASE}-source-agent
export IM_HOST_SECURITY_AGENT=${RELEASE}-security-agent
export IM_HOST_ENRICHMENT_AGENT=${RELEASE}-enrichment-agent
export IM_HOST_OCR_AGENT=${RELEASE}-ocr-agent
export IM_HOST_CONTENT_AGENT=${RELEASE}-content-agent
export IM_HOST_MIGRATION_AGENT=${RELEASE}-migration-agent
export IM_PORT_ADMIN_API=5001
export IM_PORT_SEARCH_API=5003
export IM_PORT_DS_API=5004
export IM_HOST_ADMIN_API=${RELEASE}-admin-api
export IM_HOST_SEARCH_API=${RELEASE}-search-api
export IM_HOST_DS_API=${RELEASE}-ds-api
export IM_PORT_TIKA=9998
export IM_HOST_TIKA=${RELEASE}-tika
export IM_HOST_FRONTEND=${RELEASE}-frontend

export IM_PORT=${PORT}

export ELASTICSEARCH_HOSTS="[\"https://${RELEASE}-elastic:9200\"]"
echo "${ELASTICSEARCH_HOSTS}"
echo "Release: ${RELEASE}"

if [[ $RELEASE = 'staging2' ]]; then
    docker rmi "labsaiimi/be:${RELEASE}" --force
    docker rmi "labsaiimi/fe:${RELEASE}" --force
fi

SCRIPT_PIPELINE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_PIPELINE_DIR}"

# uncomment the next line, to start kibana also
# docker-compose -f kibana-compose.yml up -d

docker-compose -f create-certs.yml run --rm create_certs
docker-compose -f elastic-container.yml up -d

./waitForContainer.sh -c "${RELEASE}-elastic" || exit 1

docker-compose -f agents-compose.yml up -d

docker-compose -f apis-compose.yml up -d

docker-compose -f frontend-compose.yml up -d

./waitForContainer.sh -r "${RELEASE}" || exit 1

docker-compose -f ingress-compose.yml up -d


echo "Security & Source Agents and Admin & Search APIs are up"
# curl --header "authorization: Bearer insightmaker"  https://localhost/security/status --insecure
# curl --header "authorization: Bearer insightmaker"  https://localhost/content/status --insecure
# curl --header "authorization: Bearer insightmaker"  https://localhost/admin/status --insecure

docker container ls