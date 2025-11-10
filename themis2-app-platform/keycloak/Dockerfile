FROM alpine:3.20

RUN apk add --no-cache bash curl jq docker-cli openssl

RUN mkdir -p /setup

WORKDIR /setup
COPY ./init.sh .
RUN chmod +x init.sh

ENTRYPOINT ["/setup/init.sh"]