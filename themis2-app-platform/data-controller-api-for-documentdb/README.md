# Data Controller API for DocumentDB

データ操作APIの開発・運用ドキュメント

## 目次

- [Data Controller API for DocumentDB](#data-controller-api-for-documentdb)
  - [目次](#目次)
  - [開発環境セットアップ](#開発環境セットアップ)
    - [推奨方法: docker-compose-prod.ymlを使用した自動セットアップ](#推奨方法-docker-compose-prodymlを使用した自動セットアップ)
      - [1. ディレクトリ移動](#1-ディレクトリ移動)
      - [2. 本番環境用Docker Composeで起動](#2-本番環境用docker-composeで起動)
      - [3. 起動確認](#3-起動確認)
      - [自動化される処理内容](#自動化される処理内容)
    - [代替方法: 手動セットアップ](#代替方法-手動セットアップ)
      - [1. ディレクトリ移動](#1-ディレクトリ移動-1)
      - [2. 基本Docker環境起動](#2-基本docker環境起動)
      - [3. データベース初期化](#3-データベース初期化)
        - [MongoDBコンテナでの作業](#mongodbコンテナでの作業)
        - [Schemaコンテナでの作業](#schemaコンテナでの作業)
        - [テストデータの準備](#テストデータの準備)
      - [4. API起動](#4-api起動)
  - [動作確認](#動作確認)
    - [データ操作APIのエンドポイント](#データ操作apiのエンドポイント)
      - [利用可能なエンドポイント](#利用可能なエンドポイント)
      - [検索クエリパラメータ](#検索クエリパラメータ)
      - [サポートされる検索条件](#サポートされる検索条件)
    - [基本的な動作確認](#基本的な動作確認)
      - [Kong経由でのアクセス（推奨）](#kong経由でのアクセス推奨)
      - [1. 基本検索](#1-基本検索)
      - [2. データ追加](#2-データ追加)
      - [3. データ更新](#3-データ更新)
      - [4. データ削除](#4-データ削除)
    - [直接アクセス（開発・デバッグ用）](#直接アクセス開発デバッグ用)
      - [直接アクセスの例](#直接アクセスの例)
    - [検索機能の動作確認](#検索機能の動作確認)
      - [時間範囲検索](#時間範囲検索)
      - [ポリゴン検索](#ポリゴン検索)
      - [疑似円検索](#疑似円検索)
      - [キーバリュー検索](#キーバリュー検索)
      - [複合検索](#複合検索)
    - [データ操作機能の動作確認](#データ操作機能の動作確認)
      - [登録されているデータの確認](#登録されているデータの確認)
      - [データ追加](#データ追加)
      - [データベース直接確認](#データベース直接確認)
      - [データ更新](#データ更新)
      - [データ削除](#データ削除)
  - [本番環境用Docker Image作成とその起動](#本番環境用docker-image作成とその起動)
    - [Docker Image作成](#docker-image作成)
    - [本番環境用イメージの開発環境での実行方法](#本番環境用イメージの開発環境での実行方法)
      - [データベース初期化](#データベース初期化)
      - [アプリケーション起動](#アプリケーション起動)

## 開発環境セットアップ

### 推奨方法: docker-compose-prod.ymlを使用した自動セットアップ

**最も簡単で確実な方法**です。データベース初期化からAPI起動まで自動化されています。

#### 1. ディレクトリ移動
```bash
cd SIoT-Themis/themis2-app-platform/
```

#### 2. 本番環境用Docker Composeで起動
```bash
docker compose -f docker-compose-prod.yml up data-controller-api-for-documentdb -d
```

#### 3. 起動確認
```bash
# データ操作APIの起動確認
curl -X GET http://localhost:4002/search?type=ship -H "collection: /servicers/1"

# Kongの起動確認
curl -X GET http://localhost:8000/data-controller-api/search?type=ship -H "Authorization: <APIキー>"
```

#### 自動化される処理内容

**データベース初期化（schemaコンテナで自動実行）:**
- PostgreSQL接続待機
- MongoDB接続待機とレプリカセット設定
- 依存関係インストール（`npm ci`）
- Prismaクライアント生成
- データベースマイグレーション実行
- シードデータ投入

**データ操作API起動:**
- コンテナビルド
- 環境変数設定
- 依存関係インストール
- 開発サーバー起動（`npm run start:dev`）

**関連サービス起動:**
- PostgreSQL（ポート5432）
- MongoDB（ポート27017）
- Kong（ポート8000, 8001）
- Keycloak（ポート8080）

### 代替方法: 手動セットアップ

旧来のやり方です。

#### 1. ディレクトリ移動
```bash
cd SIoT-Themis/themis2-app-platform/
```

#### 2. 基本Docker環境起動
```bash
docker compose up -d
```

#### 3. データベース初期化

##### MongoDBコンテナでの作業
```bash
# コンテナに接続
docker compose exec mongodb /bin/bash

# mongoシェルの立ち上げ
mongosh

# レプリカセットを設定する
use admin
rs.initiate();
db.createUser( { user: "themis2", pwd: "password", roles: [] } );
```

##### Schemaコンテナでの作業
```bash
# コンテナに接続
docker compose exec schema /bin/bash

# 環境変数設定
# 既存の.envファイルがある場合はPOSTGRES_DATABASE_URLとMONGO_DATABASE_URLの行のみを更新（他の設定は保持）
# .envファイルが存在しない場合は新規作成
sed -i 's|POSTGRES_DATABASE_URL=.*|POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public|' .env 2>/dev/null || echo "POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public" >> .env
sed -i 's|MONGO_DATABASE_URL=.*|MONGO_DATABASE_URL=mongodb://themis2:password@mongodb:27017/sth_themis2?authSource=admin\&replicaSet=rs0|' .env 2>/dev/null || echo "MONGO_DATABASE_URL=mongodb://themis2:password@mongodb:27017/sth_themis2?authSource=admin&replicaSet=rs0" >> .env

# 依存関係インストールとマイグレーション
npm ci
# Prisma Migrate が MongoDB をサポートしていないため push にて DB へ反映
npx prisma db push --schema=./prisma/schema-mongodb.prisma
npx prisma migrate dev --schema=./prisma/schema-postgresql.prisma
npx prisma db seed

# データベース確認（オプション）
npx prisma studio --schema=./prisma/schema-postgresql.prisma
npx prisma studio --schema=./prisma/schema-mongodb.prisma
```

##### テストデータの準備
```bash
# MongoDBコンテナに接続
docker compose exec mongodb /bin/bash

# mongoシェルでテストデータ挿入
mongosh
use sth_themis2

# テストデータの挿入
db.sth_x002fservicersx002f1.insertOne({
  _id: ObjectId('66d181a9561c941d5c4b2ba0'),
  entityId: "99531",
  entityType: "ship",
  timestamp: ISODate("2024-08-26T16:52:57.000Z"),
  location: {
    type: "Point",
    coordinates: [121, 35]
  },
  data: {
    temperature: 35,
    humidity: 58
  },
  serviceTag: {
    serviceId: "00000184cb"
  },
  _version: 3,
  _dataPayload: "3f6ba7e7c4878a221080003e24dd0000",
  _lfourId: 99531,
  _rssi: 16,
  _minver: 0,
  _rssi_dbm: -65.214,
  _snr: 13.98,
  _foffset: -16.4,
  _delay: 18.3,
  _nwpId: 1001,
  _stId: 1,
  _stDevId: 1,
  _txTime: 1729587522
})

# 地理空間インデックスの追加
db.sth_x002fservicersx002f1.createIndex({ "location": "2dsphere" })
```

#### 4. API起動
```bash
# APIコンテナに接続
docker compose exec data-controller-api-for-documentdb /bin/bash

# 環境変数設定（必要に応じて）
echo 'MONGO_COLLECTION_NAME="/servicers/1"' > .env

# 依存関係インストールと起動
npm ci
npm run start:dev
```

## 動作確認

### データ操作APIのエンドポイント

#### 利用可能なエンドポイント
- `GET /search` - データ検索
- `POST /` - データ追加・作成
- `POST /:objectId` - データ更新
- `DELETE /:objectId` - データ削除

#### 検索クエリパラメータ
- `type`: エンティティタイプ（必須）
- `q`: キーバリュー条件（オプション）
- `geoattr`: 地理属性名（オプション）
- `georel`: 地理的関係（オプション）
- `geometry`: ジオメトリタイプ（オプション）
- `coords`: 座標（オプション）
- `limit`: 結果数制限（オプション）

#### サポートされる検索条件

**1. 地理的条件（Geospatial Conditions）**
- `georel`: 地理的関係
  - `"near;maxDistance:<距離>"` - 指定座標からの距離条件
  - `"coveredBy"` - ポリゴン内包含条件
- `geometry`: ジオメトリタイプ
  - `"point"` - 点（疑似円検索用）
  - `"polygon"` - ポリゴン
- `coords`: 座標
  - 形式: `"緯度,経度"` (例: `"35.6895,139.6917"`)
  - ポリゴンの場合: `"lat1,lon1;lat2,lon2;lat3,lon3;lat1,lon1"`

**2. キーバリュー条件（Key-Value Conditions）**
- `q`: キーバリュー条件式
  - 形式: `"属性名.フィールド名==値;属性名.フィールド名>値"`
  - 例: `"data.temperature>=30;data.humidity<80;serviceTag.serviceId==99531"`

### 基本的な動作確認

#### Kong経由でのアクセス（推奨）

**基本URL**: `http://localhost:8000/data-controller-api`

#### 1. 基本検索
```bash
curl -X GET http://localhost:8000/data-controller-api/search?type=ship \
  -H "Authorization: <APIキー>"
```

#### 2. データ追加
```bash
curl -X POST http://localhost:8000/data-controller-api \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "entityId": "99531",
    "entityType": "ship",
    "timestamp": "2024-08-26T16:52:57.000Z",
    "location": {
      "type": "Point",
      "coordinates": [121, 35]
    },
    "data": {
      "temperature": 35,
      "humidity": 58
    },
    "serviceTag": {
      "serviceId": "00000184cb"
    }
  }'
```

#### 3. データ更新
```bash
curl -X POST http://localhost:8000/data-controller-api/<ObjectId> \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "data": {
      "temperature": 100,
      "humidity": 100
    }
  }'
```

#### 4. データ削除
```bash
curl -X DELETE http://localhost:8000/data-controller-api/<ObjectId> \
  -H "Authorization: <APIキー>"
```

### 直接アクセス（開発・デバッグ用）

開発やデバッグ時にデータ操作APIを直接叩く場合の方法です。

**基本URL**: `http://localhost:4002`

#### 直接アクセスの例
```bash
# 基本検索
curl -X GET http://localhost:4002/search?type=ship \
  -H "collection: /servicers/1"

# データ追加
curl -X POST http://localhost:4002 \
  -H "Content-Type: application/json" \
  -H "collection: /servicers/1" \
  -d '{
    "entityId": "99531",
    "entityType": "ship",
    "timestamp": "2024-08-26T16:52:57.000Z",
    "location": {
      "type": "Point",
      "coordinates": [121, 35]
    },
    "data": {
      "temperature": 35,
      "humidity": 58
    }
  }'
```

### 検索機能の動作確認

#### 時間範囲検索
```bash
# Kong経由
curl "http://localhost:8000/data-controller-api/search?type=ship&q=timestamp>=2024-08-26T15:30:00;timestamp<=2024-08-26T18:30:00" \
  -H "Authorization: <APIキー>"

# 直接アクセス
curl "http://localhost:4002/search?type=ship&q=timestamp>=2024-08-26T15:30:00;timestamp<=2024-08-26T18:30:00" \
  -H "collection: /servicers/1"
```

#### ポリゴン検索
```bash
# Kong経由
curl "http://localhost:8000/data-controller-api/search?type=ship&geoattr=location&georel=coveredBy&geometry=polygon&coords=41.12,120.23;33.45,112.5;33.9,127.66;41.12,120.23" \
  -H "Authorization: <APIキー>"

# 直接アクセス
curl "http://localhost:4002/search?type=ship&geoattr=location&georel=coveredBy&geometry=polygon&coords=25,122;35,124;37,124;25,122" \
  -H "collection: /servicers/1"
```

#### 疑似円検索
距離はメートル単位です。
```bash
# Kong経由
curl "http://localhost:8000/data-controller-api/search?type=ship&geoattr=location&georel=near;maxDistance:1000&geometry=point&coords=35,121" \
  -H "Authorization: <APIキー>"

# 直接アクセス
curl "http://localhost:4002/search?type=ship&geoattr=location&georel=near;maxDistance:1000&geometry=point&coords=35,121" \
  -H "collection: /servicers/1"
```

#### キーバリュー検索

**温度による検索**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=data.temperature>10" \
  -H "Authorization: <APIキー>"
```

**ノードIDによる検索**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=entityId=='99531'" \
  -H "Authorization: <APIキー>"
```
curl "http://localhost:4002/search?type=ship&q=timestamp>=2024-08-26T15:30:00;timestamp<=2024-08-26T18:30:00" -H "collection: /servicers/1"
curl "http://localhost:4002/search?type=ship&q=timestamp>=2000-08-26T15:30:00;timestamp<=2000-08-26T18:30:00" -H "collection: /servicers/1"
```

**複数条件の組み合わせ**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=data.temperature>10;entityId=='99531';serviceTag.serviceId=='00000184cb';location.type=='Point'" \
  -H "Authorization: <APIキー>"
```

#### 複合検索

**キーバリューと時間範囲**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=data.temperature>10;timestamp>=2020-08-26T15:30:00" \
  -H "Authorization: <APIキー>"
```

**キーバリューとポリゴン**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=data.temperature>10&geoattr=location&georel=coveredBy&geometry=polygon&coords=41.12,120.23;33.45,112.5;33.9,127.66;41.12,120.23" \
  -H "Authorization: <APIキー>"
```

**時間範囲とポリゴン**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=timestamp>=2020-08-26T15:30:00&geoattr=location&georel=coveredBy&geometry=polygon&coords=41.12,120.23;33.45,112.5;33.9,127.66;41.12,120.23" \
  -H "Authorization: <APIキー>"
```

**全条件の組み合わせ**
```bash
curl "http://localhost:8000/data-controller-api/search?type=ship&q=data.temperature>10;entityId=='99531';serviceTag.serviceId=='00000184cb';location.type=='Point';timestamp>=2020-08-26T15:30:00;timestamp<=2025-08-26T23:59:59&geoattr=location&georel=coveredBy&geometry=polygon&coords=41.12,120.23;33.45,112.5;33.9,127.66;41.12,120.23" \
  -H "Authorization: <APIキー>"
```

### データ操作機能の動作確認

データ更新・削除は登録されているデータの「_id」(ObjectId)を指定することでデータを特定します。

#### 登録されているデータの確認
```bash
# Kong経由
curl "http://localhost:8000/data-controller-api/search?type=ship" \
  -H "Authorization: <APIキー>"

# 直接アクセス
curl "http://localhost:4002/search?type=ship" \
  -H "collection: /servicers/1"
```

#### データ追加

**基本的なデータ追加**
```bash
# Kong経由
curl -X POST http://localhost:8000/data-controller-api \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "entityId": "99531",
    "_lfourId": 99531,
    "entityType": "ship",
    "timestamp": "2024-08-26T16:52:57.000Z",
    "location": {
      "type": "Point",
      "coordinates": [121, 35]
    },
    "data": {
      "temperature": 0,
      "humidity": 0
    },
    "serviceTag": {
      "serviceId": "00000184cb"
    },
    "_version": 3,
    "_dataPayload": "3f6ba7e7c4878a221080003e24dd0000",
    "_rssi": 16,
    "_minver": 0,
    "_rssi_dbm": -65.214,
    "_snr": 13.98,
    "_foffset": -16.4,
    "_delay": 18.3,
    "_nwpId": 1001,
    "_stId": 1,
    "_stDevId": 1,
    "_txTime": 1729587522
  }'

# 直接アクセス
curl -X POST http://localhost:4002 \
  -H "Content-Type: application/json" \
  -H "collection: /servicers/1" \
  -d '{
    "entityId": "99531",
    "entityType": "ship",
    "timestamp": "2024-08-26T16:52:57.000Z",
    "location": {
      "type": "Point",
      "coordinates": [121, 35]
    },
    "data": {
      "temperature": 0,
      "humidity": 0
    }
  }'
```

**デバイスデータ追加**
```bash
curl -X POST http://localhost:8000/data-controller-api \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "entityId": "device:99531",
    "entityType": "ship",
    "timestamp": "2024-08-26T16:52:57.000Z",
    "location": {
      "type": "Point",
      "coordinates": [121, 35]
    },
    "data": {
      "temperature": 0,
      "humidity": 0
    },
    "serviceTag": {
      "serviceId": "00000184cb"
    }
  }'
```

#### データベース直接確認
```bash
# 基本コレクションの確認
DB_NAME='sth_themis2'
docker compose exec mongodb mongosh --eval "db = db.getSiblingDB('${DB_NAME}'); print(db.getName()); db.sth_x002f.find()"

# デバイスデータコレクションの確認
docker compose exec mongodb mongosh --eval "db = db.getSiblingDB('${DB_NAME}'); print(db.getName()); db.sth_x002fservicersx002f1.find()"
```

#### データ更新
更新対象のデータが登録されていない場合はデータが追加(上書き)されます。
```bash
# Kong経由
curl -X POST http://localhost:8000/data-controller-api/<ObjectId> \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "data": {
      "temperature": 100,
      "humidity": 100
    }
  }'

# 直接アクセス
curl -X POST http://localhost:4002/<ObjectId> \
  -H "Content-Type: application/json" \
  -H "collection: /servicers/1" \
  -d '{
    "data": {
      "temperature": 100,
      "humidity": 100
    }
  }'
```

#### データ削除
```bash
# Kong経由
curl -X DELETE http://localhost:8000/data-controller-api/<ObjectId> \
  -H "Authorization: <APIキー>"

# 直接アクセス
curl -X DELETE http://localhost:4002/<ObjectId> \
  -H "collection: /servicers/1"
```

## 本番環境用Docker Image作成とその起動

### Docker Image作成
```bash
# リポジトリルートで実行
docker build -t data-controller-api-for-documentdb:latest \
  -f data-controller-api-for-documentdb/Dockerfile .
```

### 本番環境用イメージの開発環境での実行方法

#### データベース初期化
```bash
docker run --name data-controller-api-for-documentdb \
  --network themis2-app-platform \
  -e POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public \
  -e MONGO_DATABASE_URL=mongodb://themis2:password@mongodb:27017/sth_themis2?authSource=admin \
  data-controller-api-for-documentdb \
  "npx prisma migrate deploy --schema=./packages/schema/prisma/schema-postgresql.prisma && \
   npx ts-node ./packages/schema/prisma/seed.ts"
```

#### アプリケーション起動
```bash
docker run -p 4002:3000 \
  --name data-controller-api-for-documentdb \
  --network themis2-app-platform \
  -e POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public \
  -e MONGO_DATABASE_URL=mongodb://themis2:password@mongodb:27017/sth_themis2?authSource=admin \
  -e MONGO_COLLECTION_NAME=/servicers/1 \
  data-controller-api-for-documentdb
```
