FROM node:20.16.0

COPY . /app/schema

WORKDIR /app/schema

RUN npm ci

ENTRYPOINT ["sh", "-c"]
CMD ["npx prisma migrate deploy --schema=./prisma/schema-postgresql.prisma && npx ts-node --compiler-options '{\"module\": \"CommonJS\", \"target\": \"ES2021\"}' ./prisma/seed.ts"]

