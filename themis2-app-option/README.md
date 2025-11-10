# themis2-app-option

## docker-compose-prod.ymlを利用した環境起動方法
1. .env準備
    ```bash
    cd themis2-app-option
    cp _env .env
    ```

2. .env修正
    - CHANGE_TO_*と記載されている箇所を修正

3. themis2-app-platformを先に起動
    - themis2-app-platform - [README.md](../themis2-app-platform/README.md)

4. 直下ディレクトリにcertsディレクトリを作成し、以下のファイルを配置
    - eltres-agent
    - iotagent-json
    - test-device
        - ルート証明書（例: certs/AmazonRootCA.crt）
        - クライアント証明書（例: certs/certificate.pem）
        - クライアント秘密鍵（例: certs/private-client.key）

5. eltres-agent直下に`mappings`ディレクトリを作成し、以下のファイルを配置
    - マッピング用jsonファイル `mappings/mappings.json`
    ※ eltres-agentのREADMEを参照 - [README.md](eltres-agent/README.md)

6. 起動
    ```bash
    docker compose -f docker-compose-prod.yml build --no-cache
    docker compose -f docker-compose-prod.yml up
    ```

## アプリ単位で起動する方法
- eltres-agent - [README.md](eltres-agent/README.md)
- eltres-console - [README.md](eltres-console/README.md)
- iotagent-json - [README.md](iotagent-json/README.md)
- test-device - [README.md](test-device/README.md)