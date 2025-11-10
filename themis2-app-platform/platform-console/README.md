# platform-console

## アプリ起動手順

### ディレクトリ移動

```sh
cd SIoT-Themis/themis2-app-platform/
```

### platform-console の起動に必要なコンテナの立ち上げ

```sh
docker compose up -d schema postgres platform-console
```

### schema の設定

1. schema/.env を作成し、内容を以下に修正する

    ```dotenv
    POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public
    ```

2. schema コンテナ内で以下コマンドを実行

    ※コンテナ接続コマンド：`docker compose exec schema /bin/bash`

    ```sh
    npm ci
    npx prisma migrate dev --schema=./prisma/schema-postgresql.prisma
    npx prisma db seed
    ```

### platform-console の正常動作に必要なコンテナの立ち上げ

```sh
docker compose up -d keycloak realtime-notification-api-for-documentdb kong
```

### .env.localの設定

#### 自動手順

1. keycloak/init.shを実行する
2. init.shによって生成された .env.local を platform-console/ 以下に配置する

#### 手動手順

1. platform-console/.env.local 新規作成する
2. schema/.env の内容を platform-console/.env.local にコピーする
3. 【開発者向け】ELTRES受信機管理コンソール設計.xlsxの「2 ログイン機能利用手順書」シートを参考に、.env.localに環境変数を設定する

### アプリケーション 起動

1. realtime-notification-api-for-documentdb 起動  
    - realtime-notification-api-for-documentdbの[README.md](https://github.com/Planet-MIMAMORI/SIoT-Themis/blob/main/themis2-app-platform/realtime-notification-api-for-documentdb/README.md)を参照

2. platform-console 起動  
    ※接続コマンド：`docker compose exec platform-console /bin/bash`

    ```sh
    npm ci
    npm run dev
    ```

## 本番用Docker Image作成とその起動
### buildコマンド（themis2-app-platformで実行）
```
docker build -t platform-console:latest -f platform-console/Dockerfile --build-arg NEXTAUTH_URL=[platform-consoleのURL] .
```
### buildコマンド（themis2-app-platformで実行、開発環境での動作確認用）
```
docker build -t platform-console:latest -f platform-console/Dockerfile --build-arg NEXTAUTH_URL=http://localhost:3000 .
```
### PostgreSQL初期設定用runコマンド（開発環境での動作確認用）
```
docker run --name platform-console --network themis2-app-platform \
-e POSTGRES_DATABASE_URL=[PostgreSQLの接続文字列] \
platform-console \
"npx prisma migrate deploy --schema=./packages/schema/prisma/schema-postgresql.prisma && \
npx ts-node --compiler-options '{\"module\": \"commonjs\", \"target\": \"ES2021\"}' ./packages/schema/prisma/seed.ts"
```
### アプリケーション起動用runコマンド（開発環境での動作確認用）
```
docker run -p 3000:3000 --name platform-console --network themis2-app-platform \
-e POSTGRES_DATABASE_URL=[PostgreSQLの接続文字列] \
-e KONG_GATEWAY_ORIGIN=http://kong:8001 \
-e REALTIME_NOTIFICATION_API_ORIGIN=http://kong:8000/realtime-notification-api \
-e NEXTAUTH_SECRET=[`openssl rand -base64 32`を実行し作成したランダム文字列] \
-e KEYCLOAK_ENDPOINT=http://keycloak:8080 \
-e KEYCLOAK_REALM=[Keycloakで作成したRealm名] \
-e KEYCLOAK_CLIENT_ID=[Keycloakで作成したClient ID] \
-e KEYCLOAK_CLIENT_SECRET=[Keycloakで作成したClient Secret] \
-e FIWARE_SERVICE=themis2
platform-console
```
