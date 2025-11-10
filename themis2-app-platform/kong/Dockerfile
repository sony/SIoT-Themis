FROM kong:3.4.2

USER root

RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /setup

COPY init.sh /setup/kong-init.sh

COPY collection_plugin.lua /setup/collection_plugin.lua

COPY fiware_header_plugin.lua /setup/fiware_header_plugin.lua

ENTRYPOINT ["/setup/kong-init.sh"]



