FROM node:20.16.0

COPY ./realtime-notification-api-for-documentdb /app/realtime-notification-api-for-documentdb
COPY ./schema /app/realtime-notification-api-for-documentdb/packages/schema

WORKDIR /app/realtime-notification-api-for-documentdb

RUN npm ci && \
    npx prisma generate --schema=./packages/schema/prisma/schema-postgresql.prisma && \
    npm run build && \
    npm prune --omit=dev

ENTRYPOINT ["sh", "-c"]
CMD ["npm run start:prod"]