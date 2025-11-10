FROM node:20.16.0

COPY ./data-controller-api-for-documentdb /app/data-controller-api-for-documentdb
COPY ./schema /app/data-controller-api-for-documentdb/packages/schema

WORKDIR /app/data-controller-api-for-documentdb

RUN npm ci && \
    npx prisma generate --schema=./packages/schema/prisma/schema-postgresql.prisma && \
    npx prisma generate --schema=./packages/schema/prisma/schema-mongodb.prisma && \
    npm run build && \
    npm prune --omit=dev

ENTRYPOINT ["sh", "-c"]
CMD ["npm run start:prod"]