# test-device

## アプリ起動手順
### themis2-app-platformディレクトリのdocker compose環境を起動する。（themis2-app-platformのnetworkを利用するため）
### docker実行ディレクトリへ移動
```
cd SIoT-Themis/themis2-app-option/
```
### docker 立ち上げ
```
docker compose up -d test-device
```
### コンテナに接続
```
docker compose exec test-device /bin/bash
```
### nodeパッケージインストール
```
npm ci
```
### 設定ファイルの確認
- [証明書ファイルの配置](#証明書ファイルの配置)を行う。
- [mqtt接続項目の設定](#mqtt接続項目の設定)を行う。

### アプリ起動
#### 以下コマンドでバッチ実行が正常に完了することを確認する。
```
npm run send-data -- \
 --data '[{"gnss": 63, "latitude": 40.68921777777777, "longitude": -74.04456, "height": 100, "speed": 40, "course": 135, "adc": 500, "temperature": 32, "userdata": 80,  "sos": 1},{"gnss": 63, "latitude": 40.68921777777777, "longitude": -74.04456, "height": 100, "speed": 40, "course": 135, "adc": 500, "temperature": 27, "userdata": 80,  "sos": 0}]' \
 --topic 'eltres/1000/300003/1/rx/payload' \
 --loop 
```

## 証明書ファイルの配置
- test-device直下に`certs`ディレクトリを作成し、以下のファイルを配置します。
  - ルート証明書（例: `certs/AmazonRootCA.crt`）
  - クライアント証明書（例: `certs/certificate.pem`）
  - クライアント秘密鍵（例: `certs/private-client.key`）

## mqtt接続項目の設定
- test-device直下の`mqtt-config.json`を以下の通り設定します。
  - **endpoint**: 接続先のホスト名
  - **caPath**: ルート証明書のパス
  - **certificatePath**: クライアント証明書のパス
  - **keyPath**: クライアント秘密鍵のパス
  - **port**: 接続に使用するポート番号

### 設定例
以下は実際の設定例です。
- mqtt-config.json (endpointを修正して実行してください)

```json
{
     "endpoint": "XXXXXXXXXXXXXX-ats.iot.ap-northeast-1.amazonaws.com",
     "caPath": "./certs/AmazonRootCA.crt",
     "certificatePath": "./certs/certificate.pem",
     "keyPath": "./certs/private-client.key",
     "port": 8883
}
```

## その他設定項目
1.  IoT Coreに送信するデータのフォーマットをtemplates/eltres.json で設定します。
2.  1.のdataPayload部分の変換定義をmapping-assignment.jsonで設定します。

### 設定例
- templates/eltres.json (dataPayload、txTimeは送信時に可変されます)

```json
{
    "version": 3,
    "dataPayload": "WILL_BE_CHANGED_TO_DATA",
    "lfourId": 99531,
    "txTime": 0,
    "rssi": 16,
    "serviceTag": {
        "serviceId": "00000184cb"
    },
    "minver": 0,
    "rssi_dbm": -65.214,
    "snr": 13.98,
    "foffset": -16.4,
    "delay": 18.3,
    "nwpId": 1001,
    "stId": 1,
    "stDevId": 1
}
```

- mapping-assignment.json

```json
{
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
```

## コマンドの実行
- test-deviceは `npm run send-data` で実行します。

### 実行例
- オプションを含んだコマンドの実行例は下記の通りです。

```
npm run send-data -- \
 --data '[{"gnss": 63, "latitude": 40.68921777777777, "longitude": -74.04456, "height": 100, "speed": 40, "course": 135, "adc": 500, "temperature": 32, "userdata": 80,  "sos": 1},{"gnss": 63, "latitude": 40.68921777777777, "longitude": -74.04456, "height": 100, "speed": 40, "course": 135, "adc": 500, "temperature": 27, "userdata": 80,  "sos": 0}]' \
 --topic 'eltres/1000/300003/1/rx/payload' \
 --loop
```

### コマンドオプションの補足
- dataオプションで指定する値は、--definitions オプション(指定しない場合はmapping-assignment.json)で指定されたマッピング定義を元に16進数変換されて、dataPayloadの値が生成されます。
- マッピング定義に存在しないキーを--dataで 指定した場合は、dataPayload生成時には無視されます。
- マッピング定義に存在するキーを--dataオプションで指定しない場合は、該当するキーの値は0でdataPayloadが生成されます。
(該当するキーの値が0の場合でも、マッピング定義にgainやbiasが存在する場合は、-bias / gainの値でdataPayloadが生成されます。)

### eltres を send-data Script でテストする
```
npm run send-data -- --eltres  --topic "topicName" --data '{"temperature":25, "humidity":60, "sos":0,"lfourId":1,"txTime": 16961600}' --template templates/eltres.json --definitions mapping-assignment.json --interval 10
```
### テストデバイス
1. MQTTトピックをサブスクライブします。（npm run receive-data）
```
npm run receive-data -- --eltres  --topic "/<Apikey>/eltres-device-1/attrs" --data '{"temperature":25, "humidity":60, "sos":0,"lfourId":1,"txTime": 16961600}' --template templates/eltres.json --definitions mapping-assignment.json --interval 10 --loop
```
2. 公開を開始するには、{"send-data":"on"} を送信します。
```
mosquitto_pub  --host xxxxxxxxxxxxxxxx-ats.iot.ap-northeast-1.amazonaws.com  --port 8883  --cafile certs/AmazonRootCA.crt  --cert certs/certificate.pem  --key certs/private-client.key  --topic "/<Apikey>/eltres-device-1/cmd" --message '{"send-data":"on"}'  --debug
```
3. 公開を停止するには、{"send-data":"off"} を送信します。
```
mosquitto_pub  --host xxxxxxxxxxxxxxxx-ats.iot.ap-northeast-1.amazonaws.com  --port 8883  --cafile certs/AmazonRootCA.crt  --cert certs/certificate.pem  --key certs/private-client.key  --topic "/<Apikey>/eltres-device-1/cmd" --message '{"send-data":"off"}'  --debug
```
4. バイナリでデータを送信します。
```
npm run send-data -- --topic "topicName" --data '{"temperature":25, "humidity":60, "sos":0,"lfourId":1,"txTime": 16961600}' --template templates/binary.json --definitions mapping-assignment.json --interval 10 --binary "path/to/your/image" --loop
```
※注意：--binary の場合は --data の内容は無視される
### Publish Topic
```
/<apiKey>/<deviceName>/cmdexe
```
1. Example
Given the following device-config.json
```
{
  "deviceName":"eltres-device-1",
  "apiKey":"Kh6iHcJLitn3Zz3iV8y3mnHmB9s9bPk3"
}
```