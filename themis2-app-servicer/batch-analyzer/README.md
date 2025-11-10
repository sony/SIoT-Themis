# batch-analyzer
## gitクローンからアプリ起動までの手順
### themis2-app-platformリポジトリのdocker compose環境を起動する。（themis2-app-platformのnetworkを利用するため）
### 以下を起動する
- themis2-app-platformディレクトリ：data-controller-api
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
docker compose up -d batch-analyzer
```
### コンテナに接続
```
docker compose exec batch-analyzer /bin/bash
```
### nodeパッケージインストール
```
npm ci
```
### .envファイルの編集
- [.envの設定](#envの設定)を行う。

### アプリ起動
```
npm run start -- --key temperature
```
- 上記コマンドを入力後にエラーなく終了し、batch-analyzer直下に`{NEXT_PROCESSING_FOLDER}/next-processing-temperature.json`が保存されていれば確認完了です。

## .envの設定
- batch-analyzer直下に`.env`ファイルを作成し、以下の通り設定をします。
  - **NEXT_PROCESSING_FOLDER**: 次回実行時に必要なパラメータを記録したファイルを格納するフォルダ (batch-analyzer直下からのパス)
  - **DATA_CONTROLLER_API_ORIGIN**: データ操作APIのホスト名
  - **DATA_CONTROLLER_API_KEY**: データ操作APIに接続する際のAPIキー

### 設定例

以下は実際の設定例です。

```env
NEXT_PROCESSING_FOLDER=saves
DATA_CONTROLLER_API_ORIGIN=http://kong:8000/data-controller-api
DATA_CONTROLLER_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## 本番用Docker Image作成とその起動
### buildコマンド（themis2-app-servicerで実行）
```
docker build -t batch-analyzer:latest .
```
### runコマンド（一回限りの実行、開発環境での動作確認用）
```
docker run --name batch-analyzer --network themis2-app-platform \
-e NEXT_PROCESSING_FOLDER=saves \
-e DATA_CONTROLLER_API_ORIGIN=http://kong:8000/data-controller-api \
-e DATA_CONTROLLER_API_KEY=[プラットフォーム管理コンソールで取得したAPI Key] \
batch-analyzer \
"npm run start -- --type ship --key temperature"
```
### runコマンド（cron形式での実行、開発環境での動作確認用）
```
docker run --name batch-analyzer --network themis2-app-platform \
-e NEXT_PROCESSING_FOLDER=saves \
-e DATA_CONTROLLER_API_ORIGIN=http://kong:8000/data-controller-api \
-e DATA_CONTROLLER_API_KEY=[プラットフォーム管理コンソールで取得したAPI Key] \
batch-analyzer \
"npm run daemon -- --type ship --key temperature --interval '*/10 * * * *'"
```
※注意
--key で temperature が指定されたら temperature が分析対象。
--key で data.temperature が指定されたら data.temperature が分析対象。
--key で hoge が指定されたら hoge が分析対象。
--key で data.hoge が指定されたら data.hoge が分析対象。