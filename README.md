# 環境構築手順

## リポジトリ概要
このリポジトリは、IoTデバイスから収集したデータをリアルタイムに処理・管理するためのプラットフォームです。
認証・認可機能には Keycloak を用い、データは PostgreSQL および DocumentDB に保存されます。

## 目次
- [リポジトリ概要](#リポジトリ概要)
- [目次](#目次)
- [システム構成](#システム構成)
- [ディレクトリ構成](#ディレクトリ構成)
- [構築手順](#構築手順)
    - [前提](#前提)
    - [SSH公開鍵作成](#ssh公開鍵作成)
    - [GithubActions環境設定](#github-actions環境設定)
    - [OIDC認証追加](#oidc認証追加)
    - [GithubActions実行iacサーバー](#githubactions実行iacサーバー)
    - [GithubActions実行データプラットフォーム](#githubactions実行データプラットフォーム)
    - [サービサー用APIキー取得・設定](#サービサー用apiキー取得設定)
      - [apiキーの取得・設定](#apiキーの取得・設定)
    - [GithubActions実行サービサー](#githubactions実行サービサー)
    - [サービサー構築後設定作業](#サービサー構築後設定作業)
      - [リアルタイム分析サービスの有効化](#リアルタイム分析サービスの有効化)
- [Elastic IPのquota上限変更申請手順](#elastic-ipのquota上限変更申請手順)
- [各アプリへの接続方法接続(接続URL)](#各アプリへの接続方法接続url)
- [利用バージョン](#利用バージョン)

## システム構成
![システム構成図](./picture/基本設計書_システム構成図.png)
| サービス名 | 用途 |
|------|----------|
| Virtual Private Cloud (VPC) | リソースを作成するネットワークの作成をする。 |
| Elastic Container Registry (ECR) | アプリケーションのDockerイメージを保管する。 |
| Elastic Kubernetes Service (EKS) | アプリケーションのコンテナを起動する。また、AWSアドオンを利用したサービスの管理を行う。 |
| Elastic Compute Cloud (EC2) | 本システムのインフラを構築するコード（IaC）を実行する。 |
| Simple Storage Service (S3) | 本システムのインフラを構築するコード（IaC）による状態を管理するファイルを保管する |
| Identity and Access Management (IAM) | AWS のサービスやリソースにアクセスできるユーザーやグループと、それらのアクセス権限を管理する |
| CloudFront | アプリケーションへのアクセスに対する負荷対策を行う。 |
| Web Application Firewall (WAF) | 一般的な攻撃からアプリケーションを保護する。 |
| CloudWatch | 各AWSサービスやリソース、その他任意のログやメトリクスを一元管理し、表示する。また、外形監視、トレース情報収集についても収集、表示する。 |
| IoT Core | IoTデバイスからの接続を受け付け、そのデバイスからのメッセージをEKS内のアプリケーションにルーティングする。 |
| Document DB | Fiware OrionおよびCygnusの永続ストレージであり、それらのデータを保管する。 |
| Aurora PostgreSQL | Fiware OrionおよびCygnusを除く、各種アプリケーションの永続ストレージであり、それらのデータを保管する |
| Application Load Balancer (ALB) | データ分析およびデータ可視化管理コンソール向けで、HTTP(S)に対応した負荷分散を行う。 |
| Route53 | ホストゾーンおよびレコードに関するサービスであり、それらの管理を行う。 |
| Certifyicate Manager | AWS のサービスと接続されたリソースを使用した SSL/TLS 証明書のプロビジョニングと管理を行う。 |
| Elasti Cache | ELTRESエージェントの重複排除処理のインメモリキャッシュとして利用する。 |

| アプリ名 | 用途 |
|------|----------|
| プラットフォーム管理コンソール | 可視化・分析サービスの利用登録・設定を行う。 |
| サービサー管理コンソール | 顧客と顧客が閲覧可能なデータを管理する。 |
| サンプル可視化サービス(Grafana) | センサーデータの内容や分析結果を図やグラフとして可視化する。 |
| サンプル可視化サービス(Tracker) | センサーデータ（type=ship）の内容や分析結果を地図上に可視化する。 |
| サンプル分析サービス(バッチ) | センサーデータの内容を定期分析する。 |
| サンプル分析サービス(リアルタイム) | センサーデータの内容をリアルタイムに分析する。 |
| ELTRESエージェント | センサーデータを登録する。また、プラットフォーム管理コンソールでリアルタイム通知を有効にするとリアルタイム分析設定を更新する。 |
| IoT Agent for JSON | IoTデバイスから送られてくるデータをFIWARE Orionが理解できる形式に変換する。 |
| データフィルタリングAPI | 全データからユーザーがサンプル可視化サービス(Grafana)で閲覧可能なデータのみを表示させるためにデータをフィルタリングするAPI。 |
| データ操作API | リクエストに含まれている条件でDocumentDBからデータを取得する。また、データの登録・更新・削除のリクエストを受けてもそのまま実行する。 |
| リアルタイム通知API | 可視化サービスでセンサーデータをリアルタイムで確認するためのサブスクリプション設定をするAPI |
| リアルタイムデータ変換API | サンプル可視化サービス(Grafana)でリアルタイム表示をする際にGrafanaが対応している形式にデータを変換するAPI。 |

## ディレクトリ構成
├── themis2-app-platform/ # データプラットフォーム関連のアプリ  
│   ├── data-controller-api-for-documentdb/ # データ操作APIに関連するファイルが格納されている  
│   ├── keycloak/ # プラットフォーム側のkeycloakに関連するファイルが格納されている  
│   ├── kong/ # KongGatewayに関連するファイルが格納されている    
│   ├── mongo-init/ # ローカル環境でmongoコンテナを自動で起動する際に使用されるスクリプトが格納されている    
│   ├── orion/ # FIWARE Orionに関連するファイルが格納されている    
│   ├── platform-console/ # プラットフォーム管理コンソールに関連するファイルが格納されている    
│   ├── postgresql/ # PostgreSQLに関連するファイルが格納されている    
│   └── realtime-notification-api-for-documentdb/ # リアルタイム通知APIに関連するファイルが格納されている    
├── themis2-app-servicer/ # サービサー関連のアプリ  
│   ├── batch-analyzer/ # バッチ分析サービスに関連するファイルが格納されている    
│   ├── data-filtering-api/ # データフィルタリングAPIに関連するファイルが格納されている    
│   ├── grafana/ # サンプル可視化サービス(Grafana)に関連するファイルが格納されている    
│   ├── keycloak/ # サービサー側のkeycloakに関連するファイルが格納されている    
│   ├── realtime-analyzer/ # リアルタイム分析サービスに関連するファイルが格納されている    
│   ├── realtime-transformation-api/ # リアルタイムデータ変換APIに関連するファイルが格納されている    
│   ├── schema/ # データベースの設定やマイグレーションファイルなどが格納されている    
│   ├── servicer-console/ # サービサー管理コンソールに関連するファイルが格納されている    
│   └── visualize-tracker/ # サンプル可視化サービス(Tracker)に関連するファイルが格納されている   
├── themis2-app-option/ # IoTデータを扱うアプリ   
│   ├── config/ # IoT Agent for JSONの設定が記載されたファイルが格納されている    
│   ├── eltres-agent/ # ELTRESエージェントに関連するファイルが格納されている    
│   ├── eltres-console/ # ELTRES受信機管理コンソールに関連するファイルが格納されている    
    │   ├── iotagent-json/ # IoT Agent for JSONに関連するファイルが格納されている    
│   └── test-device/ # テストデバイスに関連するファイルが格納されている   
├── themis2-inf-platform/ # データプラットフォーム関連のリソース  
│   ├── environments/ # 環境で使用するモジュールの呼び出しや変数の定義が含まれたファイルが格納されている    
│   ├── externals/ # スクリプトやDockerfileが格納されている    
│   └── modules/ # 特定のリソースを構築するためのコードなどが格納されている    
├── themis2-inf-servicer/ # サービサー関連のリソース    
│   ├── environments/ # 環境で使用するモジュールの呼び出しや変数の定義が含まれたファイルが格納されている    
│   ├── externals/ # スクリプトやDockerfileが格納されている    
│   └── modules/ # 特定のリソースを構築するためのコードなどが格納されている    


# 構築手順

## 前提

このリポジトリを利用する前に、以下の準備を済ませておく必要があります。

- セルフホステッドランナー用のIAMユーザーを作成しておくこと
- サブドメインを作成しておくこと
- Route53でホストゾーンを作成しておくこと  
  ※ Route53以外で取得したドメインを利用する場合は、ドメイン取得元のDNSにNSレコードを登録する必要あり

## SSH公開鍵作成
※以下手順はローカルのWSL環境で作業を行ってください
1. `cd ~`でホームディレクトリに移動する
2. `ssh-keygen -t rsa -b 2048`を実行する(コマンド実行時に出てくる質問は入力せず、すべてEnterを押下する)
3. `ls -la ~/.ssh/`でキーが作成されたことを確認する
4. 作成した秘密鍵をローカル端末の任意のフォルダに格納する
5. `cat ~/.ssh/id_rsa.pub`を実行し公開鍵の内容をコピーする
6. コピーした内容を後続の環境変数設定で、`SERVICER_EC2_KEY_PAIR_CONTENT`と`PLATFORM_EC2_KEY_PAIR_CONTENT`に設定する

## Github Actions環境変数設定
1. 以下のURLからGitHubページにアクセスする  
   https://github.com/Planet-MIMAMORI/SIoT-Themis/settings/secrets/actions

2. **Secrets** および **Variables** の値を以下赤枠のボタンより変更する。
![add-environments](./picture/add-environments.png)

### Variables
| 項目 | 設定内容 | 設定例 |
|------|----------| ---- |
| ALLOWED_CIDR_BLOCKS | アプリへのアクセス許可IP(利用者環境のグローバルIP) | [  "118.238.7.66/32",  "118.238.7.69/32"]  |
| AVAILABILITY_ZONES | 構築するAWSのavailability zone | {  "subnet1" = "ap-northeast-1a",  "subnet2" = "ap-northeast-1d"  } |
| BASE_AMI_ID | EC2のAMI ID(後述の手順で作成) | ami-0a9d744335cc5cf00 |
| CLUSTER_AUTOSCALER_VERSION | EKSのCluster Autoscalerのバージョン | v1.32.1 |
| COREDNS_VERSION | CoreDNSのバージョン | v1.11.4-eksbuild.14 |
| DOMAIN | ドメイン | unvs-themis.com |
| ELTRES_AGENT_TOPICS | eltresエージェントのtopic群 | ["$share/dev/eltres/global/payload-with-principalId"] |
| EXTRA_USERS | EC2ユーザーおよび公開鍵 | [  { "id": "t-test", "publicKey": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAaABAQCjaZcsPgTsKwFdrDd0f8XfUgIc8UqOgir9b8x+13hWGIJjpd8LVDs/p7dAZosqkjb6tfLq+cmGaJ8ZNlsDwCmy164amDo8SH6kPlc8eiCyS6ECafXVog0UNLwgLN0MYp+QnNDqSWlr/BGcIZzb+BmslAM7GFaVXi5aoJflqa5PChxuGbsKQmbhB3C5qCu4Mlp4pJqCnep8JIxLNi22Oft+cSOtSeKt3/uHA7DjUCSL8PERSWQcwN1kfuKGrupNPFLnPYJiHS/WG0sgtXeVu2vNZ10CbgbsopzC1Ms/iThdaaS0114e3TSGAH5NWEld1hZXTDBx04YPpJNhuNSq7WdP ubuntu-user@test-999" },  { "id": "test", "publicKey": "ssh-aa99999 AAAABBBBCcdeuisndnN4ASEGF8sdT8dsdfJJDSkfambngf/uJs6YE d-test@test-111" }] |
| iac_allow_cidr_blocks | EC2アクセス許可IP(利用者環境のグローバルIP) | [  "118.238.7.66/32",  "118.238.7.69/32"] |
| KEYCLOAK_ADMIN_1 | サービサー1用keycloakログインユーザー名 | keycloak-admin |
| KEYCLOAK_ADMIN_2 | サービサー2用keycloakログインユーザー名 | keycloak-admin |
| KEYCLOAK_ADMIN_USERNAME | データプラットフォーム用keycloakログインユーザー名 | keyckloak-admin |
| KEYCLOAK_USER_USERNAME | データプラットフォーム管理コンソールのユーザー名 | eltres-user |
| KEYCLOAK_USER_USERNAME_1 | サービサー1用サービサー管理コンソールのユーザー名 | servicer-user1 |
| KEYCLOAK_USER_USERNAME_2 | サービサー2用サービサー管理コンソールのユーザー名 | servicer-user2 |
| KEYCLOAK_PROXY_VERSION | keycloakのバージョン | v1.32.3-eksbuild.7 |
| NEW_REALM | keycloakで作る新しいレルムの名前 | themis2 |
| PLATFORM_EC2_KEY_PAIR_CONTENT | EC2のSSH公開鍵(プラットフォーム用) | ssh-rsa +8C5azLLcxLWN5w6AiKkGSFJn083aooLPc4sZ4ISNw/KsCqd48tio8sRzkUti/t-test@test-777 |
| POSTGRESQL_ADMIN_1 | サービサー1用postgresのdb名 | postgres |
| POSTGRESQL_ADMIN_2 | サービサー2用postgresのdb名 | postgres |
| SERVICER_CONSOLE_KEYCLOAK_CLIENT_ID_1 | サービサー1用keycloakのクライアントID | dummy |
| SERVICER_CONSOLE_KEYCLOAK_CLIENT_ID_2 | サービサー2用keycloakのクライアントID | dummy |
| SERVICER_EC2_KEY_PAIR_CONTENT | EC2のSSH公開鍵(サービサー用) | ssh-rsa +8C5azLLcxLWN5w6AiKkGSFJn083aooLPc4sZ4ISNw/KsCqd48tio8sRzkUti/t-test@test-777 |
| TOFU_WORK_DIR | tofuコマンドを使用するディレクトリ | environments/prd |
| VPC_CNI_VERSION | AWS VPC CNIプラグインのバージョン | v1.19.5-eksbuild.3 |

### Secrets
| 項目 | 設定内容 | 設定例 |
|------|----------| ---- |
| AURORA_MASTER_PASSWORD | auroradbのマスター権限ユーザーのパスワード(8文字以上) | adminadmin |
| BACTH_ANALYZER_DATA_CONTROLLER_API_KEY_1 | データ操作APIからサービサー1用バッチアナライザーを使う時に使用するAPIキー | badfbadbvaduusafhasiu |
| BACTH_ANALYZER_DATA_CONTROLLER_API_KEY_2 | データ操作APIからサービサー2用バッチアナライザーを使う時に使用するAPIキー | sdfhjsnioermpbosbdz |
| CYGNUS_DOCDB_MASTER_PASSWORD | Cygnus用DocumentDBのマスター権限ユーザーのパスワード(8~100文字) | jsduadasi |
| DATA_FILTERING_API_BACKEND_API_KEY_1 | サービサー1用データフィルタリングAPIのAPIキー | mchwspdsgjqsa |
| DATA_FILTERING_API_BACKEND_API_KEY_2 | サービサー2用データフィルタリングAPIのAPIキー | hsfoiewsp9swo |
| GH_PAT | Githubリポジトリにアクセスするためのトークン | github_pat_11BLED6AQ09cVhIyDM_Y4y0OVhsFjBjdZU3qvpbVs0tGlXClUg67RTEPPu2e |
| GH_PAT_ADMIN | 管理者権限付きのGithubトークン | github_pat_85GML9D2APScEjPuMT_AiSFMop9qFESi3Wts0hbcowshAjfdE24HsqfPVM0o |
| NEXT_PUBLIC_GOOGLE_MAPS_JAVASCRIPT_API_KEY | Trackerのマップを表示するためのAPIキー | BNGMDOFQFNNDSK |
| KEYCLOAK_ADMIN_PASSWORD | データプラットフォーム用keycloakのadminユーザーのパスワード(文字数制限なし) | admin |
| KEYCLOAK_ADMIN_PASSWORD_1 | サービサー1用keycloakのadminユーザーのパスワード(文字数制限なし) | admin |
| KEYCLOAK_ADMIN_PASSWORD_2 | サービサー2用keycloakのadminユーザーのパスワード(文字数制限なし) | admin |
| KEYCLOAK_USER_PASSWORD | データプラットフォーム管理コンソールのユーザーのパスワード(文字数制限なし) | admin |
| KEYCLOAK_USER_PASSWORD_1 | サービサー1用サービサー管理コンソールのユーザーのパスワード(文字数制限なし) | admin |
| KEYCLOAK_USER_PASSWORD_2 | サービサー2用サービサー管理コンソールのユーザーのパスワード(文字数制限なし) | admin |
| MONGO_SSL_TRUSTSTORE_PASSWORD | mongoをsslで使用するときに行われる検証に使用するトラストストアを開くためのパスワード | changeit |
| ORION_DOCDB_MASTER_PASSWORD | Orion用DocumentDBのマスター権限ユーザーのパスワード(8~100文字) | s5e2Pcy2TBJG |
| PGPASSWORD | Aurora postgres接続時のパスワード(8文字以上) | JZh4TXM01z25 |
| POSTGRESQL_ADMIN_PASSWORD_1 | サービサー1用postgresのadminパスワード(8文字以上) | adminadmin |
| POSTGRESQL_ADMIN_PASSWORD_2 | サービサー2用postgresのadminパスワード(8文字以上) | adminadmin |
| REALTIME_NOTIFICATION_API_KEY_1 | サービサー1用リアルタイム通知APIのAPIキー | cCtCu8llnnpPEvMagvZ4YfUSXmvMDgIN |
| REALTIME_NOTIFICATION_API_KEY_2 | サービサー2用リアルタイム通知APIののAPIキー | nBrjIkRlZumXH9CeIKgntHlPSKkrXUHM |
| SAMPLE_TRACKER_BACKEND_API_KEY_1 | サービサー1用トラッカー用のAPIキー | BADFVMMEETQTG |
| SAMPLE_TRACKER_BACKEND_API_KEY_2 | サービサー2用トラッカー用のAPIキー2 | NUSDGNJNMOQGE |
| SERVICER_CONSOLE_KEYCLOAK_CLIENT_SECRET | サービサー用keycloakのクライアントシークレット | BNUIGWBLGNOQINGNOK |

3. Github Environmentsを設定する
![add-github-environments1](./picture/add-github-environments1.png)
![add-github-environments2](./picture/add-github-environments2.png)
![add-github-environments3](./picture/add-github-environments3.png)
### Variables
| 項目 | 設定内容 | 設定例 |
|------|----------| ---- |
| AWS_ACCOUNT | AWSアカウントID | 012345678900 |
| EKS_ADMIN_USER_ARNS | EKSの管理者権限を付与するIAMユーザーもしくはロール | [  "arn:aws:iam::012345678900:user/User1",  "arn:aws:iam::012345678900:user/User2",  "arn:aws:iam::012345678900:user/User3""arn:aws:iam::012345678900:role/testrole"] |
| ENV | 環境名 | dev |
| MAPPINGS | [ELTRES Agentデータ送受信設定](####ELTRESエージェントの送受信データ設定) | [MAPPINGS例](####MAPPINGS)|

#### ELTRESエージェントの送受信データ設定

**_groups_**

   同じマッピング定義を使うセンサ（NodeID）のをグループを定義します。  
   groupsの第2階層のキー（右例のsensorTypeAやsensorTypeB）は、definitionsの第2階層のキーに対応しています。  
   groupsの第2階層の値（右例の[1や2や3など]）には、definitionsに対応するNodeIDを記載します。  
   - 1つ1つ記載：NodeIDの1,2,3を利用する場合  
      `[　1,　2,　3  ]`

   - 範囲で記載：NodeIDの100から200を利用する場合  
      `[  { "from": 100, "to": 200 }  ]`
   - 1つ１つと範囲の複合で記載：NodeIDの1,2,3と100から200を利用する場合  
      `[   4,  5,  6,  { "from": 300, "to": 400 }  ]`
<br>
<br>

**_definitions_** (マッピングの定義)  
センサ種別ごとのマッピングの定義を記載します。  

- **第2階層のキー（右例のsensorTypeAやsensorTypeB）**  
    groups のキー（KEY）とリンクし、definitions の中で同じキーを持つオブジェクトに対応します。  

- **type**  
   必須項目で、データの種類を表します（右例のshipやcar）。サンプル可視化サービス(Tracker)に表示するためにはtype=shipにする必要があります。

-  **offset**  
   dataPayload をビット変換した際の開始ビット位置を表します。  
   これは、データがどのビット位置から始まるかを示します。

-  **length**  
    データのビット長を表します。例えば、lengthが8であれば、そのデータは8ビットの長さを持ちます。

-  **gain**  
   データに対する調整用の係数（乗算）です。
      offset lengthを利用して取得した2進数データを10進数に変換後、この係数をかけて補正します。
      例えば、gain が 0.1 で、対象データを10進数に変換した値が10の場合1になります。

-  **bias**  
      データに対する固定の補正値（加算）です。
      gainがない場合はoffset lengthを利用して取得した2進数データを10進数に変換後、この係数を加算して補正します。
      gainがある場合はgainを処理後、この係数を加算して補正します。
      例えば、bias が -90 で、対象データを10進数に変換した値が10の場合-80になります。

#### MAPPINGS例
※サンプル可視化サービス(Tracker)に表示するためにはtype=shipにする必要があります
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

## OIDC認証追加
1. AWSコンソールにログインし、左上の検索ボックスに`IAM`と入力して出てきたサービスを選択する
![search-iam-service](./picture/search-iam-service.png)

2. 左のサイドメニューから`IDプロバイダ`を選択し、画面右上の**プロバイダを追加**ボタンをクリックする
![choice-add-provider](./picture/choice-add-provider.png)

3. プロバイダータイプは`OpenID Connect`を選択してプロバイダのURLに`https://token.actions.githubusercontent.com`、対象者に`sts.amazon.com`を入力して右下の**プロバイダを追加**ボタンをクリックする
![add-provider](./picture/add-provider.png)

4. 左のサイドメニューから`ロール`を選択し、画面右上の**ロールを作成**ボタンをクリックする
![create-role](./picture/create-role.png)

5. 信頼されたエンティティタイプは`ウェブアイデンティティ`を選択し、アイデンティティプロバイダーに`token.actions.githubusercontent.com`、Audienceに`sts.amazonaws.com`を選択し、Github organizationに`Planet-MIMAMORI`と入力し、右下の**次へ**ボタンをクリックする
![setting-input-role](./picture/setting-input-role.png) 

6. 許可ポリシーに`AdoministratorAccess`を選択を選択し、右下の**次へ**ボタンをクリックする
![choice-authorization-policy](./picture/choice-authorization-policy.png)

7. ロール名に`GithubActionsOIDCRole`と入力し、右下の**ロールを作成**ボタンをクリックする
![add-role](./picture/add-role.png)

## Elastic IPのquota上限変更申請
1. AWSコンソールにログインし、左上の検索ボックスに`quota`と入力して出てきたサービスを選択する
![search-quota-service](./picture/search-quota-service.png)

2. 左のメニューから`AWSのサービス`を選び、検索ボックスに`compute`と入力して出てきたサービスをクリックする(Amazon Elastic Compute Cloud(Amazon EC2)が出てくる)
![search-aws-service](./picture/search-aws-service.png)

3. 検索ボックスに`Elastic`と入力し、出てきたクォータをクリックする(EC2-VPC Elastic IPs)をクリックする
![search-quota](./picture/search-quota.png)

4. 画面右上の**アカウントレベルでの引き上げをリクエスト**ボタンをクリックする
![click-quota-request](./picture/click-quota-request.png)

5. 以下の赤枠部分に引き上げたいクォータ値を入力し、右下のリクエストボタンをクリックする
![increase-quota](./picture/increase-quota.png)

6.しばらく時間を置くことでリクエストが承認される

## EC2 AMIイメージを作成
1. AWSコンソールにログインし、EC2にて新規インスタンス作成する

以下が前提条件

- AMI：ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20251022
- 作業端末からSSH接続が可能であること
- インターネット接続が可能であること

2. 作成したEC2にSSH接続しgithub runnerセットアップ用シェルを配置する
- 対象スクリプト：themis2-inf-platform/modules/ec2/templates/setup_github_runner.sh
- 配置先：/opt　※パーミッションを777に設定

3. コマンドインストールスクリプトを任意のディレクトリに配置し実行する

※出力の最後に「All installations completed.」と表示されていること

```
sh ./init_script.sh 
```

4. インスタンスを停止しイメージを作成する
![ec2-snap-shot-01](./picture/ec2-snapshot-01.png)

5. 任意のAMI名を指定し、イメージを作成をクリックする 
![ec2-snap-shot-02](./picture/ec2-snapshot-02.png)

6. AMI一覧に移動し、作成したAMI IDを控える
![ec2-snap-shot-03](./picture/ec2-snapshot-03.png)

7. 控えたAMI IDをGithubのVariablesの「BASE_AMI_ID」に入力する


## GithubActions実行(IaCサーバー)
1. 以下のURLからGitHubページにアクセスする  
   https://github.com/Planet-MIMAMORI/SIoT-Themis/actions

2. 左下の**show more workflows** をクリックする
![show-more-workflows](./picture/show-more-workflows.png)

3. **Provision IaC Environment(S3/VPC/EC2)** をクリックする
![choice-workflow(platform-IaC)](./picture/choice-workflow(platform-IaC).png)

4. ファイル名からplatform側であることを確認し、画面右の**Run workflow**ボタンから実行ブランチ(Use workflow from)を設定し(例：main)、環境変数(target_env)に環境名(例：prd)を入力して**Run workflow**ボタンをクリックする
![platform-IaC-execution](./picture/platform-IaC-execution.png)

5. 各ジョブが正常に終了し、ワークフローが正常に完了できていることを確認する

6. 再び左下の**show more workflows**をクリックする
![show-more-workflows](./picture/show-more-workflows.png)

7. **Provision IaC Environment(S3/VPC/EC2)** をクリックする
![choice-workflow(servicer-IaC)](./picture/choice-workflow(servicer-IaC).png)

8. ファイル名からservicer側であることを確認し、画面右の**Run workflow**ボタンから実行ブランチ(Use workflow from)を設定し(例：main)、環境変数(target_env)に環境名(例：prd)を入力して**Run workflow**ボタンをクリックする
![servicer-IaC-execution](./picture/servicer-IaC-execution.png)

9. 各ジョブが正常に終了し、ワークフローが正常に完了できていることを確認する

## GithubActions実行(データプラットフォーム)
1. 以下のURLからGitHubページにアクセスする  
   https://github.com/Planet-MIMAMORI/SIoT-Themis/actions

2. 左下の**show more workflows**をクリックする
   ![show-more-workflows](./picture/show-more-workflows.png)

3. **Provision environment to AWS(Platform-inf)** をクリックする
![choice-workflow(platform-inf)](./picture/choice-workflow(platform-inf).png)

4. 画面右の**Run workflow**ボタンから実行ブランチ(Use workflow from)を設定し(例：main)、環境変数(target_env)に環境名(例：prd)を入力して**Run workflow**ボタンをクリックする
![platform-inf-execution](./picture/platform-inf-execution.png)

5. 各ジョブが正常に終了し、ワークフローが正常に完了できていることを確認する

6. 再び左下の**show more workflows**をクリックする
![show-more-workflows](./picture/show-more-workflows.png)

7. **Provision environment to AWS(Platform-app)** をクリックする
![choice-workflow(platform-app)](./picture/choice-workflow(platform-app).png)

8. 画面右下の**Run workflow**ボタンから実行ブランチ(Use workflow from)を設定し(例：main)、環境変数(target_env)に環境名(例：prd)を入力して**Run workflow**ボタンをクリックする
![platform-app-execution](./picture/platform-app-execution.png)

9. 各ジョブが正常に終了し、ワークフローが正常に完了できていることを確認する

## サービサー用APIキー取得・設定
### IoTCore証明書ID取得
後続手順で利用するIoTCore証明書IDを事前に確認する

1. GithubActionsの**Provision environment to AWS(Platform-inf)** をクリックする
![choice-workflow(platform-inf)](./picture/choice-workflow(platform-inf).png)

2. IoTCoreが初めて成功したワークフローを選択し画面下部のIoT Core証明書IDを控える
![check-iotcore-certificate](./picture/iotcore-certificate.png)

### APIキーの取得・設定
1. 以下のURLからプラットフォーム管理コンソールにアクセスする  
   https://platform.[環境名].[DOMAINの値]

2. **Sign in With Keycloak** をクリックする
![Sign in with Keycloak](./picture/Sign-in-with-Keycloak.png)

3. 環境変数に設定したユーザー名・パスワードをそれぞれ入力し、**Sign In** ボタンをクリックする  
ユーザー名：KEYCLOAK_USER_USERNAME  
パスワード：KEYCLOAK_USER_PASSWORD
![Sign in](./picture/Sign-in.png)


4. **追加** ボタンをクリックする
![add-service](./picture/add-service.png)

5. **サービサー名** 、**リアルタイム分析用API Endpoint** 、**Principal ID**を追加・入力し、**保存**ボタンをクリックする  
リアルタイム分析用API Endpoint：https://analyzer.[ENVの値].[DOMAINの値]/realtime-analyzer  
Principal ID：IoT Coreの証明書ID
![create-new-service](./picture/create-new-service.png)

6. 表示されたAPIキーをコピーしておく
![copy-api-key](./picture/copy-api-key.png)

7. 一覧へ戻り、再度**追加** ボタンをクリックする
![add-service](./picture/add-service.png)

8. **サービサー名** 、**リアルタイム分析用API Endpoint** 、**Principal ID**を追加・入力し、**保存**ボタンをクリックする  
リアルタイム分析用API Endpoint：https://analyzer.[ENVの値].[DOMAINの値]/realtime-analyzer
Principal ID：IoT Coreの証明書ID
![create-new-service](./picture/create-new-service.png)

9. 表示されたAPIキーをコピーしておく
![copy-api-key2](./picture/copy-api-key2.png)

10. 以下のURLからGitHubページにアクセスする
   https://github.com/Planet-MIMAMORI/SIoT-Themis/settings

11. Secrets and variablesのActionsからSecrets内にある**BATCH_ANALYZER_DATA_CONTROLLER_API_KEY_1**の右側にある鉛筆マークをクリックする
![choice-batch-api-key1](./picture/choice-batch-api-key1.png)

12. valueに初めにコピーしたAPIキーを入力し、**Update secret**ボタンをクリックする
![update-batch-api-key1](./picture/update-batch-api-key1.png)

13. 同様に**BATCH_ANALYZER_DATA_CONTROLLER_API_KEY_2**の右側にある鉛筆マークをクリックする
![choice-batch-api-key2](./picture/choice-batch-api-key2.png)

14. valueに2つめにコピーしたAPIキーを入力し、**Update secret**ボタンをクリックする
![update-batch-api-key2](./picture/update-batch-api-key2.png)

15. 上記**11~14**の手順を以下の環境変数でも同様に繰り返す
- DATA_FILTERING_API_BACKEND_API_KEY_1
- DATA_FILTERING_API_BACKEND_API_KEY_2
- SAMPLE_TRACKER_BACKEND_API_KEY_1
- SAMPLE_TRACKER_BACKEND_API_KEY_2
- BACTH_ANALYZER_DATA_CONTROLLER_API_KEY_1
- BACTH_ANALYZER_DATA_CONTROLLER_API_KEY_2
- REALTIME_NOTIFICATION_API_KEY_1
- REALTIME_NOTIFICATION_API_KEY_2

## GithubActions実行(サービサー)
1. 以下のURLからGitHubページにアクセスする  
   https://github.com/Planet-MIMAMORI/SIoT-Themis/actions

2. 左下の**show more workflows**をクリックする
   ![show-more-workflows](./picture/show-more-workflows.png)

3. **Provision environment to AWS(Servicer-inf)** をクリックする
![choice-workflow(servicer-inf)](./picture/choice-workflow(servicer-inf).png)

4. 画面右の**Run workflow**ボタンから実行ブランチ(Use workflow from)を設定し(例：main)、環境変数(target_env)に環境名(例：prd)を入力して**Run workflow**ボタンをクリックする
![servicer-inf-execution](./picture/servicer-inf-execution.png)

5. 各ジョブが正常に終了していることを確認する

6. 再び左下の**show more workflows**をクリックする
![show-more-workflows](./picture/show-more-workflows.png)

7. **Provision environment to AWS(Servicer-app)**をクリックする
![choice-workflow(servicer-app)](./picture/choice-workflow(servicer-app).png)

8. 画面右下の**Run workflow**ボタンから実行ブランチ(Use workflow from)を設定し(例：main)、環境変数(target_env)に環境名(例：prd)を入力して**Run workflow**ボタンをクリックする
![servicer-app-execution](./picture/servicer-app-execution.png)

9. 各ジョブが正常に終了していることを確認する

## サービサー構築後設定作業
### リアルタイム分析サービスの有効化
1. 以下のURLからプラットフォーム管理コンソールにアクセスする  
   https://platform.[環境名].[DOMAINの値]

2. **Sign in With Keycloak** をクリックする
![Sign in with Keycloak](./picture/Sign-in-with-Keycloak.png)

3. 環境変数に設定したユーザー名・パスワードをそれぞれ入力し、**Sign In** ボタンをクリックする  
ユーザー名：KEYCLOAK_USER_USERNAME  
パスワード：KEYCLOAK_USER_PASSWORD
![Sign in](./picture/Sign-in.png)   
※ユーザー名・パスワードはそれぞれkeycloakのinit.shで設定されたものを使用します

4. サービスを選択する  
![choice-service](./picture/choice-service.png)

5. **リアルタイム分析**の右にあるトグルボタンをオンにする
![realtime-on](./picture/realtime-on.png)

6. **保存**ボタンをクリックする  
![save-realtime](./picture/save-realtime.png)

## 各アプリへの接続方法(接続URL)
keycloakコンソール：https://auth.[ENVの値].[DOMAINの値] 
※ユーザー名・パスワードはそれぞれ環境変数で指定している値で設定されます

プラットフォーム管理コンソール：https://platform.[ENVの値].[DOMAINの値]     
- ユーザー名：KEYCLOAK_USER_USERNAME  
- パスワード：KEYCLOAK_USER_PASSWORD

Grafana：https://grafana.[ENVの値].[DOMAINの値] 
- ユーザーネーム：`admin`
- パスワード：`admin`   
※それぞれ初回ログイン時のものです

Grafana2：https://grafana2.[ENVの値].[DOMAINの値] 
- ユーザーネーム：`admin`
- パスワード：`admin`   
※それぞれ初回ログイン時のものです

Tracker：https://tracker.[ENVの値].[DOMAINの値] 

Tracker2：https://tracker2.[ENVの値].[DOMAINの値] 

## デバイスへ登録するIoTCore証明書の取得方法

1. GithubActionsの**Provision environment to AWS(Platform-inf)** をクリックする
![choice-workflow(platform-inf)](./picture/choice-workflow(platform-inf).png)

2. IoTCoreが初めて成功したワークフローを選択し画面下部のArtifactsに表示されているダウンロードアイコンをクリックする
![download-iotcore-certificate](./picture/iotcore-certificate-download.png)


## 各アプリローカル起動手順
- [プラットフォーム管理コンソール](./themis2-app-platform/platform-console)
- [バッチ分析サービス](./themis2-app-servicer/batch-analyzer/README.md)
- [リアルタイム分析サービス](./temis2-app-servicer/realtime-analyzer/README.md)
- [サンプル可視化サービス(トラッカー)](./themis2-app-servicer/visualize-tracker/README.md)
- [サンプル可視化サービス(Grafana)](./themis2-app-servicer/grafana/README.md)
- [データフィルタリングAPI](./themis2-app-servicer/data-filtering-api/README.md)
- [リアルタイムデータ変換API](./themis2-app-servicer/realtime-transformation-api/README.md)
- [データ操作API](./themis2-app-platform/data-controller-api-for-documentdb/README.md)
- [リアルタイム通知API](./themis2-app-platform/realtime-notification-api-for-documentdb/README.md)
- [サービサー管理コンソール](./themis2-app-servicer/servicer-console/README.md)
- [ELTRESエージェント](./themis2-app-option/eltres-agent/README.md)
- [ELTRES受信機管理コンソール](./themis2-app-option/eltres-console/README.md)
- [IoT Agent for JSON](./themis2-app-option/iotagent-json/README.md)
- [テストデバイス](./themis2-app-option/test-device/README.md)

## 利用バージョン
- next : 15.4.1
- nest : 11.0.5
- react : 18.3.1
- typescript : 5.8.3
- eslint : 8.57.1
- prettier : 3.6.2
- papaparse : 5.5.3
- jest : 29.7.0
- prisma : 5.19.0
- postgresql : 16.3
- FIWARE Orion : 4.0.0
- FIWARE Cygnus : 3.16.0
- keycloak : 25.0.4
- mongoDB : 5.0.31
- node : 20.16.0
