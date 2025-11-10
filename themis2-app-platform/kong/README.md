## 本番用Docker Image作成とその起動
### Kong 初期設定用 Docker イメージのビルドコマンド（themis2-app-platformで実行）
```
docker build -t kong-init:latest -f kong/Dockerfile kong
```
### Kong 初期設定用コンテナの実行コマンド（開発環境での動作確認用）
```
docker run \
  --network themis2-app-platform \
  -e KONG_ADMIN_ENDPOINT=http://kong:8001 \
  -e DATA_CONTROLLER_API_ENDPOINT=http://data-controller-api-for-documentdb:3000 \
  -e REALTIME_NOTIFICATION_API_ENDPOINT=http://realtime-notification-api-for-documentdb:3000 \
  -e IOT_AGENT_ENDPOINT=http://iot-agent:4041 \
  --name kong-container \
  kong-init:latest
```