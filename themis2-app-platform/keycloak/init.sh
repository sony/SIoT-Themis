#!/bin/bash

# Postgresql に必要テーブルとユーザの作成
# docker compose exec postgres psql -U $POSTGRES_USER -c "SELECT 1 FROM pg_database WHERE datname = 'keycloak'" | grep -q 1 || \
# docker compose exec postgres psql -U $POSTGRES_USER -c "CREATE DATABASE keycloak;"
# docker compose exec postgres psql -U $POSTGRES_USER -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO $POSTGRES_USER;" > /dev/null

# ------------------------------------------
# 事前に.envに環境変数を設定してください。
# ------------------------------------------

# 環境変数が全て設定されているかチェック
env_vars=(KEYCLOAK_ENDPOINT KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD KEYCLOAK_REALM PLATFORM_CONSOLE_CLIENT_ID PLATFORM_CONSOLE_URL ELTRES_CONSOLE_CLIENT_ID ELTRES_CONSOLE_URL USER_USERNAME USER_EMAIL USER_FIRST_NAME USER_LAST_NAME USER_PASSWORD)
for var in "${env_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "環境変数 $var が設定されていません。" >&2
        exit 1
    fi
done

# ※本スクリプトは最新の REST API 仕様に基づいています。詳細は
# https://www.keycloak.org/docs-api/latest/rest-api/index.html をご確認ください。

# --- 1. 管理者トークンの取得 ---
TOKEN_RESPONSE=$(curl -s --data "client_id=admin-cli&grant_type=password&username=${KEYCLOAK_ADMIN}&password=${KEYCLOAK_ADMIN_PASSWORD}" "${KEYCLOAK_ENDPOINT}/realms/master/protocol/openid-connect/token")
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
  "realm": "${KEYCLOAK_REALM}",
  "enabled": true
}
EOF
)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_ENDPOINT}/admin/realms" \
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
  "clientId": "${PLATFORM_CONSOLE_CLIENT_ID}",
  "enabled": true,
  "protocol": "openid-connect",
  "publicClient": false,
  "clientAuthenticatorType": "client-secret",
  "serviceAccountsEnabled": true,
  "authorizationServicesEnabled": true,
  "directAccessGrantsEnabled": false,
  "redirectUris": ["${PLATFORM_CONSOLE_URL}/*"],
  "webOrigins": ["${PLATFORM_CONSOLE_URL}"]
}
EOF
)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/clients" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}" \
  -d "${CLIENT_PAYLOAD}")

if [ "$HTTP_CODE" -ne 201 ] && [ "$HTTP_CODE" -ne 204 ] && [ "$HTTP_CODE" -ne 409 ]; then
    echo "Client 作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# 作成済みの client UUID を取得（一覧から clientId をキーに検索）
CLIENTS_RESPONSE=$(curl -s -X GET "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/clients" \
  -H "${AUTH_HEADER}")
CLIENT_UUID=$(echo "${CLIENTS_RESPONSE}" | jq -r --arg cid "${PLATFORM_CONSOLE_CLIENT_ID}" '.[] | select(.clientId == $cid) | .id')
if [ -z "$CLIENT_UUID" ] || [ "$CLIENT_UUID" == "null" ]; then
    echo "Client の UUID 取得に失敗しました。" >&2
    exit 1
fi


ELTRES_CLIENT_PAYLOAD=$(cat <<EOF
{
  "clientId": "${ELTRES_CONSOLE_CLIENT_ID}",
  "enabled": true,
  "protocol": "openid-connect",
  "publicClient": false,
  "clientAuthenticatorType": "client-secret",
  "serviceAccountsEnabled": true,
  "authorizationServicesEnabled": true,
  "directAccessGrantsEnabled": false,
  "redirectUris": ["${ELTRES_CONSOLE_URL}/*"],
  "webOrigins": ["${ELTRES_CONSOLE_URL}"]
}
EOF
)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/clients" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}" \
  -d "${ELTRES_CLIENT_PAYLOAD}")

if [ "$HTTP_CODE" -ne 201 ] && [ "$HTTP_CODE" -ne 204 ] && [ "$HTTP_CODE" -ne 409 ]; then
    echo "Client 作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# 作成済みの client UUID を取得（一覧から clientId をキーに検索）
ELTRES_CLIENTS_RESPONSE=$(curl -s -X GET "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/clients" \
  -H "${AUTH_HEADER}")
ELTRES_CLIENT_UUID=$(echo "${ELTRES_CLIENTS_RESPONSE}" | jq -r --arg cid "${ELTRES_CONSOLE_CLIENT_ID}" '.[] | select(.clientId == $cid) | .id')
if [ -z "$ELTRES_CLIENT_UUID" ] || [ "$ELTRES_CLIENT_UUID" == "null" ]; then
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
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/users" \
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
USER_RESPONSE=$(curl -s -X GET "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/users?username=${USER_USERNAME}" \
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
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/users/${USER_ID}/reset-password" \
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
CLIENT_SECRET_RESPONSE=$(curl -s -X GET "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/clients/${CLIENT_UUID}/client-secret" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}")

CLIENT_SECRET=$(echo "${CLIENT_SECRET_RESPONSE}" | jq -r '.value')
if [ -z "${CLIENT_SECRET}" ] || [ "${CLIENT_SECRET}" == "null" ]; then
    echo "Client Secret の取得に失敗しました。" >&2
    exit 1
fi

ELTRES_CLIENT_SECRET_RESPONSE=$(curl -s -X GET "${KEYCLOAK_ENDPOINT}/admin/realms/${KEYCLOAK_REALM}/clients/${ELTRES_CLIENT_UUID}/client-secret" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE_HEADER}")

ELTRES_CLIENT_SECRET=$(echo "${ELTRES_CLIENT_SECRET_RESPONSE}" | jq -r '.value')

if [ -z "${ELTRES_CLIENT_SECRET}" ] || [ "${ELTRES_CLIENT_SECRET}" == "null" ]; then
    echo "ELTRES Client Secret の取得に失敗しました。" >&2
    exit 1
fi

# --- 7. .env.localの作成 ---
NEXTAUTH_SECRET=$(openssl rand -base64 32)
ENV_TEXT=$(cat <<EOF
NEXTAUTH_SECRET="${NEXTAUTH_SECRET}"
KEYCLOAK_CLIENT_SECRET=${CLIENT_SECRET}
KEYCLOAK_REALM=${KEYCLOAK_REALM}
KEYCLOAK_CLIENT_ID=${PLATFORM_CONSOLE_CLIENT_ID}
EOF
)

NEXTAUTH_SECRET_ELTRES=$(openssl rand -base64 32)
ENV_TEXT_ELTRES=$(cat <<EOF
NEXTAUTH_SECRET="${NEXTAUTH_SECRET_ELTRES}"
KEYCLOAK_CLIENT_SECRET=${ELTRES_CLIENT_SECRET}
KEYCLOAK_REALM=${KEYCLOAK_REALM}
KEYCLOAK_CLIENT_ID=${ELTRES_CONSOLE_CLIENT_ID}
EOF
)


echo "$ENV_TEXT" > .env.local.platform
echo "$ENV_TEXT_ELTRES" > .env.local.eltres
echo "Keycloak environment variables were saved to the file .env.local"
