FROM node:20.16.0

COPY . /app/schema

WORKDIR /app/schema

RUN npm ci

ENTRYPOINT ["sh", "-c"]
CMD ["npx prisma migrate deploy"]
