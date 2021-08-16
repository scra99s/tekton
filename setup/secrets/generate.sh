#!/usr/bin/bash

function generateCertificates() {
  declare workingDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  # Create CA certificate and key
  openssl req -newkey rsa:4096 -x509 -nodes \
    -keyout $workingDir/serverCA.key -new -out $workingDir/serverCA.crt \
    -subj /CN=docker-registry.jerra.io -sha256 -days 3650

  # Create Server Key
  openssl req -new -sha256 -nodes -out $workingDir/server.csr -newkey rsa:2048 \
    -keyout $workingDir/server.key -config <( cat $workingDir/server-root.cnf )

  # Create server cert
  openssl x509 -req -in $workingDir/server.csr -CA $workingDir/serverCA.crt \
    -CAkey $workingDir/serverCA.key -CAcreateserial -out $workingDir/server.crt \
    -days 3650 -sha256 -extfile $workingDir/version3-extension.cnf
}

generateCertificates
