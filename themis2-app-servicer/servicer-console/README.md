# servicer-console

## gitクローンからアプリ起動までの手順

## 前提

themis2-app-servicerリポジトリはthemis2-app-platformリポジトリを前提に動きます

### themis2-app-platform realtime-notification-api-for-documentdb用のAPIキーを作成

#### themis2-app-platform platform-console コンテナの起動

参考: <https://github.com/Planet-MIMAMORI/themis2-app-platform/blob/develop/platform-console/README.md>
　　　「必要に応じてschema コンテナでseed機能を実行」まで実施する
　　　※ themis2-app-optionリポジトリ：eltres-agentの起動は不要
　　　※ themis2-app-platformリポジトリ：realtime-notification-api-for-documentdbの起動はアプリを使うために必要
　　　　 realtime-notification-api-for-documentdbコンテナの起動を次のステップで行う

参考: <https://github.com/Planet-MIMAMORI/themis2-app-platform/blob/develop/README.md>
　　　「開発中は以下コマンドで keycloak 用の DB を作成」まで実施する

#### ※ themis2-app-platform realtime-notification-api-for-documentdb コンテナの起動

※ servicer-consoleの顧客追加編集画面機能を使うためにrealtime-notification-api-for-documentdbコンテナを起動する
必要がある
参考: <https://github.com/Planet-MIMAMORI/themis2-app-platform/blob/develop/realtime-notification-api-for-documentdb/README.md>

#### platform-console ログインとAPIキー生成

1. localhost:3000にアクセスし作成したkeycloakアカウントでログインする
2. 一覧から「可視化サービス」を選択し可視化サービス一覧の「追加」ボタンをクリックする
3. サービス追加画面で「サービス名」と「アクセス権限」の「ノードID」を入力し「保存」ボタンをクリックする
4. 生成されたAPI Keyをコピーしservicer-consoleの.envのREALTIME_NOTIFICATION_API_KEYに貼り付ける
5. servicer-consoleの.envのREALTIME_NOTIFICATION_API_ENDPOINTに
"http://<Kongコンテナ名>:8000/<realtime-notification-api-for-documentdbコンテナ名>" を設定する

### gitクローン (developブランチ)

```
git clone -b develop git@github.com:Planet-MIMAMORI/themis2-app-servicer.git
```

### docker実行ディレクトリへ移動

```
cd themis2-app-servicer/
```

### docker 立ち上げ

```
docker compose up -d
```

### schema コンテナでの作業

#### コンテナに接続

```
docker compose exec servicer-schema /bin/bash
```

#### nodeパッケージインストール

```
npm ci
```

#### postgresテーブル作成

```
npx prisma migrate dev
```

### postgres コンテナでの作業

#### コンテナに接続

```
docker compose exec servicer-postgres /bin/bash
```

#### DBに接続する

```
psql "postgresql://servicer:password@servicer-postgres:5432/servicer"
```

#### servicer-keycloak用のDBを作成

```
CREATE DATABASE keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO servicer;
```

### servicer-console配下に.env.localを新規作成する

#### .env.localに以下の内容をコピーする

```
POSTGRES_DATABASE_URL="postgresql://servicer:password@servicer-postgres:5432/servicer"
NEXTAUTH_SECRET=
KEYCLOAK_REALM=
KEYCLOAK_CLIENT_ID=
KEYCLOAK_CLIENT_SECRET=
```

### 【開発者向け】 サービサー管理コンソール (顧客管理).xlsxの「ログイン機能利用手順書」シートを参考にservicer-keycloakの設定と、.env.localに環境変数の設定をする

### servicer-console コンテナでの作業

#### コンテナに接続

```
docker compose exec servicer-console /bin/bash
```

#### nodeパッケージインストール

```
npm ci
```

#### アプリ起動

```
npm run dev
```

## 本番用Docker Image作成とその起動
### buildコマンド（リポジトリのルートで実行）
```
docker build -t servicer-console:latest -f servicer-console/Dockerfile --build-arg NEXTAUTH_URL=[servicer-consoleのURL] .
```
### PostgreSQL初期設定用runコマンド
```
docker run --name servicer-console --network themis2-app-platform \
-e POSTGRES_DATABASE_URL=[PostgreSQLの接続文字列] \
servicer-console \
"npx prisma migrate deploy --schema=./packages/schema/prisma/schema.prisma"
```
### アプリケーション起動用runコマンド（開発環境での動作確認用）
```
docker run -p 5006:3000 --name servicer-console --network themis2-app-platform \
-e POSTGRES_DATABASE_URL=[PostgreSQLの接続文字列] \
-e REALTIME_NOTIFICATION_API_KEY=[platform-consoleで生成した可視化サービスAPIキー] \
-e REALTIME_NOTIFICATION_API_ENDPOINT=http://kong:8000/realtime-notification-api-for-documentdb \
-e NEXTAUTH_URL=http://localhost:5006 \
-e NEXTAUTH_SECRET=[`openssl rand -base64 32`を実行し作成したランダム文字列] \
-e KEYCLOAK_ENDPOINT=http://servicer-keycloak:8081 \
-e KEYCLOAK_REALM=[Keycloakで作成したRealm名] \
-e KEYCLOAK_CLIENT_ID=[Keycloakで作成したClient ID] \
-e KEYCLOAK_CLIENT_SECRET=[Keycloakで作成したClient Secret] \
servicer-console
```