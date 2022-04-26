#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# if containers fail with max_map_count error, check https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode for guidance to increase it
echo "Starting the test ElasticSearch"
docker-compose -f ./elastic-container.yml up -d
