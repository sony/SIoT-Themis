# eltres-agent

## アプリ起動手順
### themis2-app-platformディレクトリのdocker compose環境を起動する。（themis2-app-platformのOrionやnetworkなどを利用するため）
### docker実行ディレクトリへ移動
```
cd SIoT-Themis/themis2-app-option/
```
#### externals/themis2-app/schema/prisma/.env を作成し、以下内容にする
```
POSTGRES_DATABASE_URL=postgresql://themis2:password@postgres:5432/themis2?schema=public
```
### docker 立ち上げ
```
docker compose up -d eltres-agent
```
### 証明書ファイルの配置
- eltres-agent直下に`certs`ディレクトリを作成し、以下のファイルを配置します。
  - ルート証明書（例: `certs/AmazonRootCA.crt`）
  - クライアント証明書（例: `certs/certificate.pem`）
  - クライアント秘密鍵（例: `certs/private-client.key`）
### 環境設定
#### .envファイルの配置
- eltres-agent直下の`.env`ファイルを以下の内容にあわせ修正します。
##### 環境変数
- **HOST**: 接続先のホスト名
- **PORT**: 接続に使用するポート番号
- **CA_PATH**: ルート証明書のパス
- **CERT_PATH**: クライアント証明書のパス
- **KEY_PATH**: クライアント秘密鍵のパス
- **TOPICS**: サブスクライブするトピックのリスト
- **DUPLICATION_CHECK_TTL**: 重複チェック用データのメモリ保持時間(s)
- **MAPPINGS_PATH**: マッピング用jsonファイルのパス
- **ORION_URL**: Orionの接続先URL
- **FIWARE_SERVICE**: OrionのFIWAREサービス名
- **FIWARE_SERVICE_PATH**: OrionのFIWAREサービスパス
##### 設定例
- 以下は設定例です。
```javascript
HOST=XXXXXXXXXXXXXX-ats.iot.ap-northeast-1.amazonaws.com
PORT=8883
CA_PATH=certs/AmazonRootCA.crt
CERT_PATH=certs/certificate.pem
KEY_PATH=certs/private-client.key
DUPLICATION_CHECK_TTL=60
TOPICS=["topicName1","topicName2"]
MAPPINGS_PATH=mappings/mappings.json
ORION_URL=http://orion:1026
FIWARE_SERVICE=
FIWARE_SERVICE_PATH=/
REDIS_HOST=redis
REDIS_PORT=6379
NODE_ENV=development
REDIS_RETRIES=3
REDIS_PREFIX="mqtt-message"
```
### マッピング用jsonファイルの配置
- eltres-agent直下に`mappings`ディレクトリを作成し、以下のファイルを配置します。
  - マッピング用jsonファイル `mappings/mappings.json`
#### マッピング用JSONの説明
- 【IoTデータプラットフォーム】オペレータ様向け利用手順書.xlsx
  - シート：ELTRESエージェント 参照
#### マッピング用JSON設定例
```JSON
{
    "groups": {
        "sensorTypeA": [
            1,
            2,
            3
        ],
        "sensorTypeB": [
            {
                "from": 100,
                "to": 200
            }
        ],
        "sensorTypeC": [
            4,
            5,
            6,
            {
                "from": 300,
                "to": 400
            }
        ]
    },
    "definitions": {
        "sensorTypeA": {
            "type": "ship",
            "definition": {
                "gnss": {
                    "offset": 0,
                    "length": 8
                },
                "latitude": {
                    "offset": 8,
                    "length": 25,
                    "gain": 0.000008888888888888888,
                    "bias": -90
                },
                "longitude": {
                    "offset": 33,
                    "length": 26,
                    "gain": 0.000008888888888888888,
                    "bias": -180
                },
                "height": {
                    "offset": 59,
                    "length": 14,
                    "bias": -1000
                },
                "speed": {
                    "offset": 73,
                    "length": 14,
                    "gain": 0.1
                },
                "course": {
                    "offset": 87,
                    "length": 12,
                    "gain": 0.1
                },
                "adc": {
                    "offset": 99,
                    "length": 10
                },
                "temperature": {
                    "offset": 109,
                    "length": 8,
                    "bias": -128
                },
                "sos": {
                    "offset": 117,
                    "length": 2
                },
                "userdata": {
                    "offset": 119,
                    "length": 9
                }
            }
        },
        "sensorTypeB": {
            "type": "car",
            "definition": {
                "rssi": {
                    "offset": 0,
                    "length": 8
                }
            }
        }
    }
}
```
### eltres-agent コンテナでの作業
#### コンテナに接続
```
docker compose exec eltres-agent /bin/bash
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
### build前準備
- [証明書ファイルの配置](#証明書ファイルの配置)を行う。
- [サブモジュールの利用法](#サブモジュールの利用法)を行う。
- [マッピング用jsonファイルの配置](#マッピング用jsonファイルの配置)を行う。

### buildコマンド（themis2-app-optionで実行）
```
docker build -t eltres-agent:latest -f eltres-agent/Dockerfile .
```

### runコマンド（開発環境での動作確認用）
```
docker run -p 6000:3000 --name eltres-agent --network themis2-app-platform \
-e POSTGRES_DATABASE_URL=[PostgreSQLの接続文字列] \
-e HOST=[MQTT Brokerのホスト名] \
-e PORT=8883 \
-e CA_PATH=certs/AmazonRootCA.crt \
-e CERT_PATH=certs/certificate.pem \
-e KEY_PATH=certs/private-client.key \
-e DUPLICATION_CHECK_TTL=60 \
-e TOPICS=["topicName1","topicName2"] \
-e MAPPINGS_PATH=mappings/mappings.json \
-e ORION_URL=http://orion:1026 \
-e FIWARE_SERVICE= \
-e FIWARE_SERVICE_PATH=/ \
-e REDIS_HOST=redis \
-e RREDIS_PORT=6379 \
-e NODE_ENV=production \
-e REDIS_RETRIES=3 \
-e REDIS_PREFIX="mqtt-message" \
eltres-agent
```
### Redis を使用した重複データの排除

- **RedisService**：Redis接続および操作を管理するサービス
    - 構成可能なホストおよびポートを使用してRedisインスタンスに接続（環境変数`REDIS_HOST`および`REDIS_PORT`にて設定）
- **Redis設定**：メモリ使用量を制限するためにmaxmemory(e.g.,4GB)で設定

### 重複排除テスト用エンドポイント

#### 概要

- ファイル：`src/test-endpoint/data/data.controller.ts`
- エンドポイント：`POST /data`
- 機能：`{ value }`を受信し、Redisに保存することで重複チェックをテスト。(開発環境でredisSericeのaddToUniqueSet関数をテストするために使用)  

例）

```sh
curl --location 'http://localhost:6000/data/add' \
--header 'Content-Type: application/json' \
--data '{
    "value": '1-169616666' 
}'
```

## 環境へのマッピング用JSON設定更新手順

1. 前提条件
   - 環境構築が終了していること

2. GitHub Environmentに設定したMAPPINGSの変更を行う
   - 参考：[Github Actions環境変数設定](../../README.md#github-actions環境変数設定)の「3. Github Environmentsを設定する」セクション内のVariables

3. GitHub Actionsの「Deploy EltresAgent」ワークフローを手動実行する
   - 実行時パラメータ
     - Github Environment name：MAPPINGSを変更したGitHub Environmentの環境名を指定する（例：dev、stg、prod）
     - restart-pods：ONにする
