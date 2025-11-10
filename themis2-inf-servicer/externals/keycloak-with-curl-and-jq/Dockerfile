FROM kong:3.4.2
USER root
RUN apt-get -y update && \
    apt-get -y --no-install-recommends install curl \
                       jq && \
    apt-get clean all
USER kong
