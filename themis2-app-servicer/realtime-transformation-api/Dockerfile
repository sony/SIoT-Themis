FROM node:20.16.0

COPY ./ /app

WORKDIR /app

RUN npm ci && npm run build && npm prune --omit=dev

ENTRYPOINT ["sh", "-c", "npm run start:prod"]