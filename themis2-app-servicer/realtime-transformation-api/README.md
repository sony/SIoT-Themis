# realtime-transformation-api

## gitクローンからアプリ起動までの手順
### gitクローン (developブランチ)
```
git clone -b develop git@github.com:Planet-MIMAMORI/SIoT-Themis.git
```
### docker実行ディレクトリへ移動
```
cd SIoT-Themis/themis2-app-servicer/
```
### docker 立ち上げ
```
docker compose up realtime-transformation-api -d
```
### realtime-transformation-api コンテナでの作業
#### コンテナに接続
```
docker compose exec realtime-transformation-api /bin/bash
```
#### nodeパッケージインストール
```
npm ci
```
#### アプリ起動
```
npm run start:dev
```

## 本番用Docker Image作成とその起動
### buildコマンド（themis2-app-servicerで実行）
```
docker build -t realtime-transformation-api:latest .
```
### runコマンド（開発環境での動作確認用）
```
docker run -p 5004:3000 --name realtime-transformation-api --network themis2-app-platform \
-e GRAFANA_ENDPOINT='http://grafana:3000' \
-e GRAFANA_ENDPOINT_PUSH_PATH='orion' \
realtime-transformation-api
```
