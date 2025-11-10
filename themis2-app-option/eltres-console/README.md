# eltres-console

## アプリ起動手順
### themis2-app-platformディレクトリのdocker compose環境を起動する。（themis2-app-platformのnetworkを利用するため）
### docker実行ディレクトリへ移動
```
cd SIoT-Themis/themis2-app-option/
```
### docker立ち上げ
```
docker compose up -d eltres-console
```
### eltres-console配下に.env.localを新規作成する
### .env.localに以下の内容をコピーする
```
NEXTAUTH_SECRET=
KEYCLOAK_REALM=
KEYCLOAK_CLIENT_ID=
KEYCLOAK_CLIENT_SECRET=
```
### 【開発者向け】ELTRES受信機管理コンソール設計.xlsxの「２ログイン機能利用手順書」シートを参考にKeycloakの設定と、.env.localに環境変数の設定をする
### コンテナに接続
```
docker compose exec -it eltres-console /bin/bash
```
### eltres-consoleコンテナで以下コマンドを実行
```
npm ci
npm run dev
```
## 本番用Docker Image作成とその起動
### buildコマンド（Dockerfileがあるディレクトリで実行）
```
docker build -t eltres-console:latest --build-arg NEXTAUTH_URL=[eltres-consoleのURL] .
```
### buildコマンド（Dockerfileがあるディレクトリで実行、開発環境での動作確認用）
```
docker build -t eltres-console:latest --build-arg NEXTAUTH_URL=http://localhost:6001 .
```
### runコマンド（開発環境での動作確認用）
```
docker run -p 6001:3000 --name eltres-console --network themis2-app-platform \
-e KEYCLOAK_ENDPOINT=http://keycloak:8080 \
-e NEXTAUTH_SECRET=[`openssl rand -base64 32`を実行し作成したランダム文字列] \
-e KEYCLOAK_REALM=[Keycloakで作成したRealm名] \
-e KEYCLOAK_CLIENT_ID=[Keycloakで作成したClient ID] \
-e KEYCLOAK_CLIENT_SECRET=[Keycloakで作成したClient Secret] \
eltres-console
```
