FROM node:20.16.0

RUN apt-get update && apt-get install -y bc

COPY . /app/test-device
WORKDIR /app/test-device

RUN npm ci

ENTRYPOINT ["/bin/bash","/app/test-device/send-data.sh"]
