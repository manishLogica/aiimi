#!/bin/bash


RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

RELEASE='staging'
CONTAINER=''
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--container)
      CONTAINER="$2"
      shift # past argument
      shift # past value
      ;;
    
    -r|--release)
      RELEASE="$2"
      shift # past argument
      shift # past value
      ;;
  esac
done
echo "${RELEASE}"
echo "${CONTAINER}"

CONTAINERS=("${RELEASE}-admin-api" "${RELEASE}-search-api" "${RELEASE}-elastic" "${RELEASE}-security-agent" "${RELEASE}-source-agent")
# echo "$CONTAINER"
if ! [[ -z $CONTAINER ]] && [[ "${CONTAINER}" != "" ]]; then
    CONTAINERS=($CONTAINER)
fi
echo "${CONTAINERS[@]}"
for TOCHECK in "${CONTAINERS[@]}"
    do
        echo -e "${BLUE}Checking $TOCHECK health${NC}"
        ATTEMPTS=0
        MAX_ATTEMPTS=120
        FOUND=0
        until [ "$ATTEMPTS" -gt "$MAX_ATTEMPTS" ] || [ "$FOUND" -eq "1" ]; do
            IFS=','
            # place healthy container names into a comma delimited string
            conts=$(docker container ls | grep 'healthy' | awk '{print $NF}' | sed -z 's/\n/,/g;s/,$/\n/')
            # parse the healthy container names into an array
            HEALTHY=($conts)
            # HEALTHY=$()
            printf "${BLUE}.${NC}"
            # echo "first = '${HEALTHY[0]}'"
            for container in "${HEALTHY[@]}"
            do
                # echo "Container > $container = $TOCHECK"
                if [[ "$container" = "$TOCHECK" ]]; then
                    printf "%*s\r${GREEN}${TOCHECK} is healthy${NC}\n"
                    FOUND="1"
                fi
            done
            
            sleep 1s
            ATTEMPTS=$(($ATTEMPTS+1))
        done
        if [ "$FOUND" -eq "0" ]; then
            printf "%*s\r${RED}${TOCHECK} is not healthy${NC}\n"
            docker logs "${TOCHECK}" | tail
            exit 1
        fi
    done
    unset IFS