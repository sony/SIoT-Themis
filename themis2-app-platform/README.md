# themis2-app-platform

## docker-compose-prod.ymlを利用した環境起動方法
1. .env準備
    ```bash
    cd themis2-app-platform
    cp _env .env
    ```

2. .env修正
    - CHANGE_TO_RANDOM_STRINGと記載されている箇所を修正

3. themis2-app-platform/mongo-init/mongo-init.js修正
    - CYGNUS_MONGO_PASSを.envに設定したものと合わせて記載

4. 起動
    ```bash
    docker compose -f docker-compose-prod.yml build --no-cache
    docker compose -f docker-compose-prod.yml up
    ```

## アプリ単位で起動する方法
- schema - [README.md](schema/README.md)
- kong - [README.md](kong/README.md)
- orion - [README.md](orion/README.md)
- platform-console - [README.md](platform-console/README.md)
- data-controller-api-for-documentdb - [README.md](data-controller-api-for-documentdb/README.md)
- realtime-notification-api-for-documentdb - [README.md](realtime-notification-api-for-documentdb/README.md)

## 開発中は以下コマンドで Kong Gateway 用の DB を作成

以下のコマンドで postgres コンテナに入り psql 起動

```bash
docker compose exec postgres psql -U themis2
```

以下の SQL で Kong Gateway 用の DB を作成

```sql
CREATE DATABASE kong;
GRANT ALL PRIVILEGES ON DATABASE kong TO themis2;
```

## 開発中は以下コマンドで keycloak 用の DB を作成

以下のコマンドで postgres コンテナに入り psql 起動

```bash
docker compose exec postgres psql -U themis2
```

以下の SQL で keycloak 用の DB を作成

```sql
CREATE DATABASE keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO themis2;
```

## 補足 本番環境の挙動をローカルで再現する
### gitクローンからOrion→Cygnusへのサブスクリプションを行うまでの手順（開発時には利用していない）
#### gitクローン (developブランチ)
```
git clone -b develop git@github.com:Planet-MIMAMORI/themis2-app.git
```
#### docker実行ディレクトリへ移動
```
cd themis2-app/
```
#### docker 立ち上げ
```
docker compose up -d
```
#### mongoコンテナでの作業
```
docker compose exec mongodb /bin/bash
```
```
mongosh
```
```
use sth_themis2
db.createCollection('sth_x002f');
db.createUser( { user: "themis2", pwd: "password", roles: [] } );
```
#### データ操作APIで利用しているMongoDBの接続文字列の変更
- schema/.env の内容を以下に修正する
```
MONGO_DATABASE_URL=mongodb://themis2:password@mongodb:27017/sth_themis2?authSource=admin&replicaSet=rs0
```
#### Orion へ Cygnus 用のサブスクリプション設定を行う
```
./orion/init.sh http://localhost:1026 http://cygnus:5051
```