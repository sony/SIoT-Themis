## 本番用Docker Image作成とその起動
### Orion初期設定用コンテナのbuildコマンド
```
docker build -t orion-init orion
```

### Orion初期設定用runコマンド（開発環境での動作確認用）
```
docker run --network themis2-app-platform \
  -e ORION_ENDPOINT=http://orion:1026 \
  -e CYGNUS_ENDPOINT=http://cygnus:5080 \
  orion-init
```