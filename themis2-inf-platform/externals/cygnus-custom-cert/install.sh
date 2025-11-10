#!/bin/bash

csplit -f cert_ -b "%02d.pem" global-bundle.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
rm cert_00.pem

i=0
for cert in cert_*.pem; do
    echo "Importing $cert"
    keytool -importcert -noprompt -trustcacerts \
        -file "$cert" \
        -cacerts \
        -storepass changeit \
        -alias customcert$i
    i=$((i + 1))
done
