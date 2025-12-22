#!/bin/sh
set -e

until node -e '
  const net = require("net");
  const socket = net.createConnection(5432, "postgres");
  socket.on("connect", () => process.exit(0));
  socket.on("error", () => process.exit(1));
' >/dev/null 2>&1
do
  echo "waiting for Postgres"
  sleep 1
done
npm ci
npx prisma generate --schema=./prisma/schema-postgresql.prisma
npx prisma migrate dev --schema=./prisma/schema-postgresql.prisma
npx prisma generate --schema=./prisma/schema-mongodb.prisma
npx prisma db push --schema=./prisma/schema-mongodb.prisma
npx ts-node --compiler-options '{"module":"CommonJS"}' ./prisma/seed.ts
