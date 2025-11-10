# data-filtering-api
## gitクローンからアプリ起動までの手順
### gitクローン (developブランチ)
```
git clone -b develop git@github.com:Planet-MIMAMORI/SIoT-Themis.git
```
### プラットフォーム管理コンソール起動
platform-consoleのREADMEにしたがってアプリを起動する
### プラットフォーム管理コンソールでデータ登録
- プラットフォーム管理コンソールにログインし、「可視化サービス」を選択する。
- 「追加」を選択する。
- サービス名に「test」と入力する。
- アクセス権限にノードID「99531」を追加する。
- 保存する。

※保存押下時にエラーが出てもDBには登録されているので気にせず次の手順に進んでください。
### データ操作API起動
data-controller-apiのREADMEにしたがって起動する
### 環境変数ファイルの作成
#### data-filtering-apiディレクトリへ移動
```
cd SIoT-Themis/themis2-app-servicer/data-filtering-api
```
#### 環境変数ファイル作成
```
touch .env
```
#### .envに以下を追記
```
BACKEND_API_KEY=<"プラットフォームコンソールで発行したAPIキー">
DATA_CONTROLLER_API_URL="http://kong:8000/data-controller-api"
```
#### schemaディレクトリへ移動
```
cd ../schema
```
#### 環境変数ファイル作成
```
touch .env
```
#### .envに以下を追記
```
POSTGRES_DATABASE_URL="postgresql://servicer:password@servicer-postgres:5432/servicer"
```
### themis2-app-servicerディレクトリへ移動
```
cd ..
```
### docker 立ち上げ
```
docker compose up data-filtering-api -d
docker compose up servicer-schema -d
docker compose up servicer-postgres -d
```
### servicer-schema コンテナでの作業
#### コンテナに接続
```
docker compose exec servicer-schema /bin/bash
```
#### パッケージインストール
```
npm ci
```
#### マイグレーションの適用
```
npx prisma migrate dev
```
### servicer-postgresコンテナでの作業
#### コンテナに接続
```
docker compose exec servicer-postgres /bin/bash
```
#### postgresに接続
```
psql "postgresql://servicer:password@servicer-postgres:5432/servicer"
```
#### テストデータ登録
```
INSERT INTO customers (name, api_key, created_at, updated_at) VALUES ('アーベルソフト', '1234567890abcdef1234567890abcdef', NOW(), NOW());
INSERT INTO types (customer_id, type) VALUES (1, 'ship');
INSERT INTO conditions (type_id, key, operator, value) VALUES (1, 'serviceTag.serviceId', '==', '''00000184cb''');
INSERT INTO conditions (type_id, key, operator, value) VALUES (1, 'data.temperature', '>', '30');
```
### data-filtering-api コンテナでの作業
#### コンテナに接続
```
docker compose exec data-filtering-api /bin/bash
```
#### パッケージインストール
```
npm ci
```
#### アプリ起動
```
npm run start:dev
```
### パターン別動作確認用コマンド
#### 401エラー
```
curl "http://localhost:5005/search?type=ship" -H "Authorization: aaa"
```
#### 403エラー
```
curl "http://localhost:5005/search?type=car" -H "Authorization: 1234567890abcdef1234567890abcdef"
```
#### 502エラー
データ操作APIを落とす
```
curl "http://localhost:5005/search?type=ship" -H "Authorization: 1234567890abcdef1234567890abcdef"
```
#### 422エラー
```
curl "localhost:5005/search?type=ship&geoattr=location&georel=coveredB&geometry=polygon&coords=35.234,123.24;35,124;37,124;35.234,123.24" -H 'authorization:1234567890abcdef1234567890abcdef'
```
#### 400エラー
```
curl "http://localhost:5005/search" -H "Authorization: 1234567890abcdef1234567890abcdef"
```
#### 全データ返ってくるやつ
```
curl "http://localhost:5005/search?type=ship" -H "Authorization: 1234567890abcdef1234567890abcdef"
```
#### 空が返ってくるやつ
```
curl "localhost:5005/search?type=ship&q=data.temperature>100" -H 'authorization:1234567890abcdef1234567890abcdef'
```
## 本番用Docker Image作成とその起動
### buildコマンド（リポジトリのルートで実行）
```
docker build -t data-filtering-api:latest -f data-filtering-api/Dockerfile .
```
### runコマンド（開発環境での動作確認用）
```
docker run -p 5005:3000 --name data-filtering-api --network themis2-app-platform \
-e BACKEND_API_KEY="<プラットフォーム管理コンソールで取得したAPIキー>" \
-e DATA_CONTROLLER_API_URL="http://kong:8000/data-controller-api" \
data-filtering-api
```