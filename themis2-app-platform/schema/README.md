## 本番用Docker Image作成とその起動
### buildコマンド
```
cd schema
docker build -t schema-image .
```
### PostgreSQL初期設定用runコマンド（開発環境での動作確認用）
```
docker run --name schema-container --network themis2-app-platform \
-e POSTGRES_DATABASE_URL=[PostgreSQLの接続文字列] \
schema-image
```