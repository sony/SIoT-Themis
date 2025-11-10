# realtime-analyzer
## gitクローンからアプリ起動までの手順
### themis2-app-platformディレクトリのdocker compose環境を起動する。（themis2-app-platformのnetworkを利用するため）
### gitクローン (developブランチ)
```
git clone -b develop git@github.com:Planet-MIMAMORI/SIoT-Themis.git
```
### docker実行ディレクトリへ移動
```
cd SIoT-Themis.git/themis2-app-servicer
```
### docker 立ち上げ
```
docker compose up -d realtime-analyzer
```
### コンテナに接続
```
docker compose exec realtime-analyzer /bin/bash
```
### nodeパッケージインストール
```
npm ci
```
### アプリ起動
```
npm run start:dev
```

## 本番用Docker Image作成とその起動
### buildコマンド（themis2-app-servicerで実行）
```
docker build -t realtime-analyzer:latest .
```
### runコマンド（開発環境での動作確認用）
```
docker run -p 5001:3000 --name realtime-analyzer --network themis2-app-platform realtime-analyzer
```
