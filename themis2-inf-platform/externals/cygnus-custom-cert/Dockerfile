FROM fiware/cygnus-ngsi:3.16.0 AS truststore
COPY install.sh /tmp/install.sh
RUN cd /tmp && \
    chmod +x install.sh && \
    curl -LO https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem && \
    ./install.sh
USER cygnus