# grafana

## 環境変数について
### grafanaディレクトリ内に.env.localを作成する
- .env.localの記述
    ```
    DATA_CONTROLLER_API=http://kong:8000/data-controller-api
    BACKEND_API_KEY=
    ```
### プラットフォーム管理コンソールにログインし、可視化サービスにあるAPIキーをコピーする
※可視化サービスが登録されていない場合は新たに登録してください
### .env.localのBACKEND_API_KEYにコピーしたAPIキーを貼り付ける

## grafana初回ログインについて
### grafanaに初回アクセスするとログイン画面が表示されるので以下を入力する
- ユーザーネーム
    ```
    admin
    ```
- パスワード
    ```
    admin
    ```
### パスワードを設定する画面に切り替わるので任意のパスワードを設定する。
※今後ログインを求められたときに使用します

## 本番用Docker Image作成とその起動
### buildコマンド（themis2-app-servicerで実行）
```
docker build -t grafana:latest .
```
### ※dockercomposeで起動したことがない場合は以下のコマンドを実行してください
```
docker volume create sample_grafana-storage
```
### runコマンド（開発環境での動作確認用）
```
docker run -p 5003:3000 --name grafana \
--volume sample_grafana-storage:/var/lib/grafana \
--network themis2-app-platform \
-e DATA_CONTROLLER_API=http://kong:8000/data-controller-api \
-e BACKEND_API_KEY=[プラットフォーム管理コンソールで取得したAPI Key] \
-e EDITABLE_PROVISIONED_RESOURCE=true
grafana
```