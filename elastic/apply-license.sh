#!/bin/bash

curl -XPUT -u $ELASTIC_USER:$ELASTIC_PASSWORD "https://${COMPOSE_PROJECT_NAME}-elastic:9200/_license" -H "Content-Type: application/json" -d @license.dev.json --insecure