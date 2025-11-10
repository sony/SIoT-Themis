# visualize-tracker

## gitクローンからアプリ起動までの手順

### themis2-app-platformディレクトリのdocker compose環境を起動する。（themis2-app-platformのnetworkを利用するため）

### 以下を起動する

- themis2-app-platformディレクトリ：data-controller-api
- themis2-app-platformディレクトリ：realtime-notification-api

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
docker compose up -d visualize-tracker
```

### visualize-tracker コンテナに接続

```
docker compose exec visualize-tracker /bin/bash
```

### 環境変数設定

1. visualize-tracker ディレクトリに `.env.local` を作成する
2. `.env` を参考に、 `.env.local` に下記の内容を追加する
   - Maps JavaScript API の apiKey を取得し、NEXT_PUBLIC_GOOGLE_MAPS_JAVASCRIPT_API_KEY= の右辺に記載する
   - プラットフォーム管理コンソールで取得したAPI Keyを、BACKEND_API_KEY = の右辺に記載する  
     `.env.local` の記載例
   ```
   NEXT_PUBLIC_GOOGLE_MAPS_JAVASCRIPT_API_KEY='取得したapiKeyの内容'
   BACKEND_API_KEY='取得したapiKeyの内容'
   ```

### visualize-tracker コンテナで以下コマンドを実行

```
# npm ci
# npm run dev
```

## 画面表示タブ の データソース選択項目 について
メニューの画面表示タブから選択できるデータソース選択項目は  
src/data/metrics.jsonから取得しており、以下のような構成である。

- field → セレクトボックスを選択したときに取得する値
- display → セレクトボックスに表示する文字列
- gain → 選択したデータソースと該当のアイコンに重畳して表示する円の半径を算出するときに使われる係数
  - 円の半径はデータソースの数値の2乗根に係数を掛けた値で、計算式は以下である  
    `半径 ＝ √| 数値 | * 係数`

metrics.jsonの例：
```
[
  {
    "field": "data.temperature",
    "display": "温度",
    "gain": 10000
  },
  {
    "field": "timestamp",
    "display": "時刻"
  }
]
```

## データ検索タブ の キーバリュー検索内のフィールド選択項目 について
メニューのデータ検索タブのキーバリュー検索内の検索項目の設定は
src/data/searchMetrics.jsonから取得しており、以下のような構成である。

- field → 検索を行うフィールドのパス
  - data / serviceTag内の値のみ使用可能
- display → 検索を行うフィールド名（フィールド選択項目セレクトボックスに表示される文字列）
- type → 検索を行うフィールドの型
  - string / numberのみ使用可能
  - 省略した場合はnumberとして扱われる

searchMetrics.jsonの例：
```
[
  {
    "field": "data.temperature",
    "display": "温度",
    "type": "number"
  },
  {
    "field": "data.humidity",
    "display": "湿度",
    "type": "number"
  },
  {
    "field": "serviceTag.serviceId",
    "display": "サービスID",
    "type": "string"
  }
]
```
## 本番用Docker Image作成とその起動
### buildコマンド（themis2-app-servicerで実行）
```
docker build -t visualize-tracker:latest \
--build-arg NEXT_PUBLIC_GOOGLE_MAPS_JAVASCRIPT_API_KEY=[Google MapのAPI KEY] \
.
```
### runコマンド（開発環境での動作確認用）
```
docker run -p 5000:3000 --name visualize-tracker --network themis2-app-platform \
-e BACKEND_API_KEY=[プラットフォーム管理コンソールで取得したAPI KEY] \
-e DATA_CONTROLLER_API_ORIGIN=http://kong:8000/data-controller-api \
-e VISUALIZE_TRACKER_ORIGIN=http://visualize-tracker:3000 \
-e REALTIME_NOTIFICATION_API_ORIGIN=http://kong:8000/realtime-notification-api \
visualize-tracker
```