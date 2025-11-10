# Realtime Notification API for DocumentDB

リアルタイム通知APIの開発・運用ドキュメント

## 目次
- [Realtime Notification API for DocumentDB](#realtime-notification-api-for-documentdb)
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
        - [Schemaコンテナでの作業](#schemaコンテナでの作業)
      - [4. API起動](#4-api起動)
  - [動作確認](#動作確認)
    - [リアルタイム通知APIのエンドポイント](#リアルタイム通知apiのエンドポイント)
      - [利用可能なエンドポイント](#利用可能なエンドポイント)
    - [Condition仕様](#condition仕様)
      - [サポートされる条件タイプ](#サポートされる条件タイプ)
    - [基本的な動作確認](#基本的な動作確認)
      - [Kong経由でのアクセス（推奨）](#kong経由でのアクセス推奨)
      - [1. サブスクリプション登録（疑似円検索）](#1-サブスクリプション登録疑似円検索)
      - [2. サブスクリプション登録（キーバリュー条件）](#2-サブスクリプション登録キーバリュー条件)
      - [3. サブスクリプション登録（複合条件）](#3-サブスクリプション登録複合条件)
      - [4. サブスクリプション登録（ポリゴン条件）](#4-サブスクリプション登録ポリゴン条件)
      - [5. サブスクリプション一覧取得](#5-サブスクリプション一覧取得)
      - [6. サブスクリプション更新](#6-サブスクリプション更新)
      - [7. サブスクリプション削除](#7-サブスクリプション削除)
      - [8. 一括サブスクリプション削除](#8-一括サブスクリプション削除)
    - [直接アクセス（開発・デバッグ用）](#直接アクセス開発デバッグ用)
      - [直接アクセスの例](#直接アクセスの例)
    - [疑似円検索の動作確認](#疑似円検索の動作確認)
      - [距離による動作の違い](#距離による動作の違い)
      - [疑似円変換の詳細仕様](#疑似円変換の詳細仕様)
    - [サブスクリプション動作確認-テストデータ送信](#サブスクリプション動作確認-テストデータ送信)
      - [センサーデータ送信](#センサーデータ送信)
      - [エンティティデータ確認](#エンティティデータ確認)
      - [Orionサブスクリプション確認](#orionサブスクリプション確認)
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
docker compose -f docker-compose-prod.yml up realtime-notification-api-for-documentdb -d
```

#### 3. 起動確認
```bash
# リアルタイム通知APIの起動確認
curl -X GET http://localhost:4003/notify

# Orionの起動確認
curl -X GET http://localhost:1026/v2/subscriptions
```

#### 自動化される処理内容

**データベース初期化（schemaコンテナで自動実行）:**
- PostgreSQL接続待機
- 依存関係インストール（`npm ci`）
- Prismaクライアント生成
- データベースマイグレーション実行
- シードデータ投入

**リアルタイム通知API起動:**
- コンテナビルド
- 環境変数設定
- 依存関係インストール
- 開発サーバー起動（`npm run start:dev`）

**関連サービス起動:**
- PostgreSQL（ポート5432）
- MongoDB（ポート27017）
- Orion（ポート1026）
- Cygnus（ポート5051, 5080）
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

##### Schemaコンテナでの作業
```bash
# コンテナに接続
docker compose exec schema /bin/bash

# 環境変数設定
# 既存の.envファイルがある場合はPOSTGRES_DATABASE_URLの行のみを更新（他の設定は保持）
# .envファイルが存在しない場合は新規作成
sed -i 's|POSTGRES_DATABASE_URL=.*|POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public|' .env 2>/dev/null || echo "POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public" > .env

# 依存関係インストールとマイグレーション
npm ci
npx prisma migrate dev --schema=./prisma/schema-postgresql.prisma
npx prisma db seed

# データベース確認（オプション）
npx prisma studio --schema=./prisma/schema-postgresql.prisma
```

#### 4. API起動
```bash
# APIコンテナに接続
docker compose exec realtime-notification-api-for-documentdb /bin/bash

# 依存関係インストールと起動
npm ci
npm run start:dev
```

## 動作確認

### リアルタイム通知APIのエンドポイント

#### 利用可能なエンドポイント
- `POST /notify` - サブスクリプション登録
- `GET /notify` - サブスクリプション一覧取得
- `PATCH /notify/:id` - サブスクリプション更新
- `DELETE /notify/:id` - サブスクリプション削除
- `DELETE /notify/bulk` - 一括サブスクリプション削除

### Condition仕様

リアルタイム通知APIのconditionは以下の構造で定義されます：

```json
{
  "condition": {
    "expression": {
      "georel": "string",      // 地理的関係（オプション）
      "geometry": "string",    // ジオメトリタイプ（オプション）
      "coords": "string",      // 座標（オプション）
      "q": "string"           // キーバリュー条件（オプション）
    }
  }
}
```

#### サポートされる条件タイプ

**1. 地理的条件（Geospatial Conditions）**
- `georel`: 地理的関係
  - `"near;maxDistance:<距離>"` - 指定座標からの距離条件
- `geometry`: ジオメトリタイプ
  - `"point"` - 点（疑似円検索用）
  - `"polygon"` - ポリゴン（自動変換後）
- `coords`: 座標
  - 形式: `"緯度,経度"` (例: `"35.6895,139.6917"`)

**2. キーバリュー条件（Key-Value Conditions）**
- `q`: キーバリュー条件式
  - 形式: `"属性名.フィールド名==値;属性名.フィールド名>値"`
  - 例: `"data.temperature>=30;data.humidity<80;serviceTag.serviceId==99531"`

### 基本的な動作確認

#### Kong経由でのアクセス（推奨）

**基本URL**: `http://localhost:8000/realtime-notification-api`

#### 1. サブスクリプション登録（疑似円検索）
```bash
curl -X POST http://localhost:8000/realtime-notification-api/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "near;maxDistance:10000",
        "geometry": "point",
        "coords": "35.6895,139.6917"
      }
    }
  }'
```

#### 2. サブスクリプション登録（キーバリュー条件）
```bash
curl -X POST http://localhost:8000/realtime-notification-api/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "q": "data.temperature>=30;data.humidity<80"
      },
      "attrs": ["data", "location"]
    }
  }'
```

#### 3. サブスクリプション登録（複合条件）
```bash
curl -X POST http://localhost:8000/realtime-notification-api/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "near;maxDistance:10000000",
        "geometry": "point",
        "coords": "35.6895,139.6917",
        "q": "data.temperature>=30"
      }
    }
  }'
```

#### 4. サブスクリプション登録（ポリゴン条件）
```bash
curl -X POST http://localhost:8000/realtime-notification-api/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "coveredBy",
        "geometry": "polygon",
        "coords": "35,135;35,136;36,136;36,135;35,135"
      }
    }
  }'
```

#### 5. サブスクリプション一覧取得
```bash
curl -X GET http://localhost:8000/realtime-notification-api/notify \
  -H "Authorization: <APIキー>"
```

#### 6. サブスクリプション更新
```bash
curl -X PATCH "http://localhost:8000/realtime-notification-api/notify/<サブスクリプションID>" \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "near;maxDistance:5000000",
        "geometry": "point",
        "coords": "35.6895,139.6917"
      }
    }
  }'
```

#### 7. サブスクリプション削除
```bash
curl -X DELETE "http://localhost:8000/realtime-notification-api/notify/<サブスクリプションID>" \
  -H "Authorization: <APIキー>"
```

#### 8. 一括サブスクリプション削除
```bash
curl -X DELETE "http://localhost:8000/realtime-notification-api/notify/bulk" \
  -H "Authorization: <APIキー>"
```

### 直接アクセス（開発・デバッグ用）

開発やデバッグ時にリアルタイム通知APIを直接叩く場合の方法です。

**基本URL**: `http://localhost:4003`

#### 直接アクセスの例
```bash
# サブスクリプション登録
curl -X POST http://localhost:4003/notify \
  -H "Content-Type: application/json" \
  -H "Fiware-Service: themis2" \
  -H "Fiware-ServicePath: <サービスパス>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "near;maxDistance:1000",
        "geometry": "point",
        "coords": "35.6895,139.6917"
      }
    }
  }'

# サブスクリプション一覧取得
curl -X GET http://localhost:4003/notify \
  -H "Fiware-Service: themis2" \
  -H "Fiware-ServicePath: <サービスパス>"
```

### 疑似円検索の動作確認

#### 距離による動作の違い

**1000万メートル以下（疑似円に変換）**
```bash
curl -X POST http://localhost:8000/realtime-notification-api/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "near;maxDistance:10000000",
        "geometry": "point",
        "coords": "35.6895,139.6917"
      }
    }
  }'
```
→ 疑似円（ポリゴン）に変換されてOrionに登録されます

**1000万メートル超（ジオロケーション条件を除去）**
```bash
curl -X POST http://localhost:8000/realtime-notification-api/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: <APIキー>" \
  -d '{
    "type": "ship",
    "url": "http://example.com/notify",
    "condition": {
      "expression": {
        "georel": "near;maxDistance:10000001",
        "geometry": "point",
        "coords": "35.6895,139.6917"
      }
    }
  }'
```
→ ジオロケーション条件が除去されてOrionに登録されます

#### 疑似円変換の詳細仕様

**変換条件**
- `geometry: "point"` かつ `georel: "near;maxDistance:<距離>"` の場合
- 距離が1000万メートル以下（10,000,000m）の場合に疑似円変換が実行される

**変換結果**
- `geometry`: `"point"` → `"polygon"`
- `georel`: `"near;maxDistance:<距離>"` → `"coveredBy"`
- `coords`: 点座標 → 64角形のポリゴン座標（セミコロン区切り）

### サブスクリプション動作確認-テストデータ送信

#### センサーデータ送信
```bash
curl -X POST 'http://localhost:1026/v2/op/update' \
  -H "Fiware-Service: themis2" \
  -H "Fiware-ServicePath: <サービスパス>" \
  -H 'Content-Type: application/json' \
  -d '{
    "actionType": "append",
    "entities": [
      {
        "id": "99532",
        "type": "ship",
        "timestamp": {
          "type": "DateTime",
          "value": "2024-11-14T12:09:13.529Z"
        },
        "location": {
          "type": "geo:json",
          "value": {
            "type": "Point",
            "coordinates": [0, 89]
          }
        },
        "data": {
          "type": "StructuredValue",
          "value": {
            "gnss": 63,
            "height": 100,
            "speed": 40,
            "course": 135,
            "adc": 500,
            "temperature": 32,
            "humidity": 32,
            "sos": 1,
            "userdata": 80
          }
        },
        "_version": {
          "type": "Integer",
          "value": 3
        },
        "_lfourId": {
          "type": "Integer",
          "value": 99531
        },
        "_txTime": {
          "type": "Integer",
          "value": 1731586153.529
        },
        "_dataPayload": {
          "type": "Text",
          "value": "3f6bda83c49c22e2260320a8cfa50250"
        },
        "_rssi": {
          "type": "Integer",
          "value": 16
        },
        "serviceTag": {
          "type": "StructuredValue",
          "value": {
            "service_id": "99531",
            "serviceId": "99531"
          }
        }
      }
    ]
  }'
```

#### エンティティデータ確認
```bash
curl -X GET "http://localhost:1026/v2/entities/"
```

#### Orionサブスクリプション確認
```bash
curl -X GET "http://localhost:1026/v2/subscriptions/"
```

## 本番環境用Docker Image作成とその起動

### Docker Image作成
```bash
# themis2-app-platformで実行
docker build -t realtime-notification-api-for-documentdb:latest \
  -f realtime-notification-api-for-documentdb/Dockerfile .
```

### 本番環境用イメージの開発環境での実行方法

#### データベース初期化
```bash
docker run --name realtime-notification-api-for-documentdb \
  --network themis2-app-platform \
  -e POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public \
  realtime-notification-api-for-documentdb \
  "npx prisma migrate deploy --schema=./packages/schema/prisma/schema-postgresql.prisma && \
   npx ts-node ./packages/schema/prisma/seed.ts"
```

#### アプリケーション起動
```bash
docker run -p 4003:3000 \
  --name realtime-notification-api-for-documentdb \
  --network themis2-app-platform \
  -e POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public \
  -e ORION_URL=http://orion:1026 \
  realtime-notification-api-for-documentdb
```
