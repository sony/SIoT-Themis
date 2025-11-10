FROM node:20.16.0

COPY ./servicer-console /app/servicer-console
COPY ./schema /app/servicer-console/packages/schema

WORKDIR /app/servicer-console

ARG NEXTAUTH_URL
ENV NEXTAUTH_URL=$NEXTAUTH_URL

RUN npm ci && \
    npx prisma generate --schema=./packages/schema/prisma/schema.prisma && \
    npm run build && \
    npm prune --omit=dev

ENTRYPOINT ["sh", "-c"]
CMD ["npm run start"]