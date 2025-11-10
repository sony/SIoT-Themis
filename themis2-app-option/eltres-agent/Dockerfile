FROM node:20.16.0

COPY ./themis2-app-option/eltres-agent /app/eltres-agent
COPY  ./themis2-app-platform/schema /app/eltres-agent/packages/schema

WORKDIR /app/eltres-agent

RUN npm ci && \
    npx prisma generate --schema=./packages/schema/prisma/schema-postgresql.prisma && \
    npm run build && \
    npm prune --omit=dev

ENTRYPOINT ["sh", "-c"]
CMD ["npm run start:prod"]