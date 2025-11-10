FROM node:22-slim

# Install OpenSSL libraries required for Prisma to work
RUN apt-get update && apt-get install -y \
    openssl \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY ./ /app/eltres-console

WORKDIR /app/eltres-console

ARG NEXTAUTH_URL
ENV NEXTAUTH_URL=$NEXTAUTH_URL

RUN npm ci && npm run build && npm prune --omit=dev

ENTRYPOINT ["sh", "-c"]
CMD ["npm run start"]