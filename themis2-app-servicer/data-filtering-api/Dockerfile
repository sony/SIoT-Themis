FROM node:20.16.0

COPY ./data-filtering-api /app/data-filtering-api
COPY ./schema /app/data-filtering-api/packages/schema

WORKDIR /app/data-filtering-api

RUN npm ci &&\
    npx prisma generate --schema=./packages/schema/prisma/schema.prisma &&\
    npm run build &&\
    npm prune --omit=dev

ENTRYPOINT [ "sh", "-c" ]

CMD [ "npm run start:prod" ]