#!/bin/bash

# Postgresql に必要データベースの作成と権限設定
# Postgresqlコンテナへの接続とデータベースの存在確認
DB_COUNT=$(docker compose exec servicer-postgres psql -U servicer -t -c "SELECT COUNT(*) FROM pg_database WHERE datname = 'keycloak'" 2>/dev/null | tr -d ' ')
if [ "$DB_COUNT" = "1" ]; then
    echo "keycloak database already exists."
else
    # Postgresqlコンテナへの接続が出来なかったまたはデータベースが存在しない
    echo "keycloak database does not exist or is not accessible."

    # データベースが存在が確認出来ない場合は作成してみる
    # エラーが発生した場合スクリプトを止める
    if ! docker compose exec servicer-postgres psql -U servicer -c "CREATE DATABASE keycloak;" >/dev/null 2>&1; then
      echo "Failed to create keycloak database." >&2
      exit 1
    fi
fi

# データベースの権限設定
if ! docker compose exec servicer-postgres psql -U servicer -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO servicer;" >/dev/null 2>&1; then
    echo "Failed to grant privileges on keycloak database." >&2
    exit 1
fi

# ------------------------------------------
# 事前に以下の環境変数を設定してください。
export KEYCLOAK_URL="http://servicer-keycloak:8081"
export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="admin"
export NEW_REALM="themis2"
export CLIENT_ID_VALUE="servicer-console"
export CLIENT_ROOT_URL="http://localhost:5006"
export USER_USERNAME="testuser"
export USER_EMAIL="test@example.com"
export USER_FIRST_NAME="Test"
export USER_LAST_NAME="User"
export USER_PASSWORD="password123"
# ------------------------------------------

# 環境変数が全て設定されているかチェック
env_vars=(KEYCLOAK_URL ADMIN_USERNAME ADMIN_PASSWORD NEW_REALM CLIENT_ID_VALUE CLIENT_ROOT_URL USER_USERNAME USER_EMAIL USER_FIRST_NAME USER_LAST_NAME USER_PASSWORD)
for var in "${env_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "環境変数 $var が設定されていません。" >&2
        exit 1
    fi
done

# ※本スクリプトは最新の REST API 仕様に基づいています。詳細は
# https://www.keycloak.org/docs-api/latest/rest-api/index.html をご確認ください。

# --- 1. 管理者トークンの取得 ---
TOKEN_RESPONSE=$(curl -s --data "client_id=admin-cli&grant_type=password&username=${ADMIN_USERNAME}&password=${ADMIN_PASSWORD}" "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token")
ACCESS_TOKEN=$(echo "${TOKEN_RESPONSE}" | jq -r '.access_token')
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "トークンの取得に失敗しました。" >&2
    exit 1
fi

# 共通ヘッダー設定
AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"
CONTENT_TYPE_HEADER="Content-Type: application/json"

# --- 2. Realm 作成 ---
REALM_PAYLOAD=$(cat <<EOF
{
  "realm": "${NEW_REALM}",
  "enabled": true
}
EOF
)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}" \
  -d "${REALM_PAYLOAD}")

if [ "$HTTP_CODE" -ne 201 ] && [ "$HTTP_CODE" -ne 204 ] && [ "$HTTP_CODE" -ne 409 ]; then
    echo "Realm 作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# --- 3. Client 作成 ---
CLIENT_PAYLOAD=$(cat <<EOF
{
  "clientId": "${CLIENT_ID_VALUE}",
  "enabled": true,
  "protocol": "openid-connect",
  "publicClient": false,
  "clientAuthenticatorType": "client-secret",
  "serviceAccountsEnabled": true,
  "authorizationServicesEnabled": true,
  "directAccessGrantsEnabled": false,
  "redirectUris": ["${CLIENT_ROOT_URL}/*"],
  "webOrigins": ["${CLIENT_ROOT_URL}"]
}
EOF
)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/clients" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}" \
  -d "${CLIENT_PAYLOAD}")

if [ "$HTTP_CODE" -ne 201 ] && [ "$HTTP_CODE" -ne 204 ] && [ "$HTTP_CODE" -ne 409 ]; then
    echo "Client 作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# 作成済みの client UUID を取得（一覧から clientId をキーに検索）
CLIENTS_RESPONSE=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/clients" \
  -H "${AUTH_HEADER}")
CLIENT_UUID=$(echo "${CLIENTS_RESPONSE}" | jq -r --arg cid "${CLIENT_ID_VALUE}" '.[] | select(.clientId == $cid) | .id')
if [ -z "$CLIENT_UUID" ] || [ "$CLIENT_UUID" == "null" ]; then
    echo "Client の UUID 取得に失敗しました。" >&2
    exit 1
fi

# --- 4. ユーザー作成 ---
USER_PAYLOAD=$(cat <<EOF
{
  "username": "${USER_USERNAME}",
  "email": "${USER_EMAIL}",
  "firstName": "${USER_FIRST_NAME}",
  "lastName": "${USER_LAST_NAME}",
  "enabled": true
}
EOF
)
SKIP_PASSWORD="false"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/users" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}" \
  -d "${USER_PAYLOAD}")

if [ "$HTTP_CODE" -eq 409 ]; then
    SKIP_PASSWORD="true"
elif [ "$HTTP_CODE" -ne 201 ] && [ "$HTTP_CODE" -ne 204 ]; then
    echo "ユーザー作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# 作成したユーザーの ID を取得（username パラメータで検索）
USER_RESPONSE=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/users?username=${USER_USERNAME}" \
  -H "${AUTH_HEADER}")
USER_ID=$(echo "${USER_RESPONSE}" | jq -r '.[0].id')
if [ -z "$USER_ID" ] || [ "$USER_ID" == "null" ]; then
    echo "ユーザー ID の取得に失敗しました。" >&2
    exit 1
fi

# --- 5. ユーザーのパスワード設定 ---
if [ "$SKIP_PASSWORD" = "false" ]; then
    PASSWD_PAYLOAD=$(cat <<EOF
    {
    "type": "password",
      "value": "${USER_PASSWORD}",
  "temporary": false
    }
EOF
    )
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/users/${USER_ID}/reset-password" \
    -H "${AUTH_HEADER}" \
    -H "${CONTENT_TYPE_HEADER}" \
    -d "${PASSWD_PAYLOAD}")

    if [ "$HTTP_CODE" -ne 204 ]; then
        echo "パスワード設定エラー。HTTP ステータス: ${HTTP_CODE}" >&2
        exit 1
    fi
fi

# --- 6. Client Secret の取得 ---
# echo "Client Secret を取得中..."
CLIENT_SECRET_RESPONSE=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/clients/${CLIENT_UUID}/client-secret" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}")

CLIENT_SECRET=$(echo "${CLIENT_SECRET_RESPONSE}" | jq -r '.value')
if [ -z "${CLIENT_SECRET}" ] || [ "${CLIENT_SECRET}" == "null" ]; then
    echo "Client Secret の取得に失敗しました。" >&2
    exit 1
fi

# --- 7. .env.localの作成 ---
NEXTAUTH_SECRET=$(openssl rand -base64 32)
ENV_TEXT=$(cat <<EOF
POSTGRES_DATABASE_URL=postgresql://servicer:password@servicer-postgres:5432/servicer
NEXTAUTH_SECRET="${NEXTAUTH_SECRET}"
KEYCLOAK_REALM=themis2
KEYCLOAK_CLIENT_ID=servicer-console
KEYCLOAK_CLIENT_SECRET=${CLIENT_SECRET}
EOF
)

echo "$ENV_TEXT" > .env.local
echo "Keycloak environment variables were saved to the file .env.local"
