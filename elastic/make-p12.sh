#!/bin/bash
CERTS_DIR="/certs"
cd "${CERTS_DIR}/"
chmod +r bundle.zip

cd "${CERTS_DIR}/ca"
echo "IM_CA_PASSWORD=${IM_CA_PASSWORD}"
openssl pkcs12 -export -password env:IM_CA_PASSWORD -out elastic-stack-ca.p12 -inkey *.key -in *.crt
cp elastic-stack-ca.p12 ../elastic-stack-ca.p12
chmod +r ../elastic-stack-ca.p12

cd "${CERTS_DIR}/instance"
echo "IM_CERT_PASSWORD=${IM_CERT_PASSWORD}"
openssl pkcs12 -export -password env:IM_CERT_PASSWORD -out elastic-certificates.p12 -inkey *.key -in *.crt
cp elastic-certificates.p12 ../elastic-certificates.p12
chmod +r ../elastic-certificates.p12