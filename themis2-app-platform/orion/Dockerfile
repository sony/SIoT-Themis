FROM fiware/orion:4.0.0

USER root

RUN mkdir -p /setup

COPY init.sh /setup/init.sh

ENTRYPOINT [ "/setup/init.sh" ]

