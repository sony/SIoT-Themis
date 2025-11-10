#!/bin/bash

# ------------------------------------------
# 事前に以下の環境変数を設定してください。
KEYCLOAK_URL=${KEYCLOAK_URL:-'http://themis2-dev-keycloak-svc:8080'}
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
NEW_REALM=${NEW_REALM:-'themis2'}
CLIENT_ID_VALUE=${CLIENT_ID_VALUE:-'console'}
CLIENT_ROOT_URL=${CLIENT_ROOT_URL:-'https://dev-iotagent.unvs-themis.com'}
USER_USERNAME=${USER_USERNAME}
USER_EMAIL=${USER_EMAIL:-'mail@example.com'}
USER_FIRST_NAME=${USER_FIRST_NAME:-'test'}
USER_LAST_NAME=${USER_LAST_NAME:-'test'}
USER_PASSWORD=${USER_PASSWORD}
# ------------------------------------------

# ※本スクリプトは最新の REST API 仕様に基づいています。詳細は
# https://www.keycloak.org/docs-api/latest/rest-api/index.html をご確認ください。

# デフォルト値が無い環境変数の存在を確認してから処理を進む
MISSING_VARS=""
if [ -z "$ADMIN_USERNAME" ]; then
    MISSING_VARS="${MISSING_VARS}ADMIN_USERNAME "
fi
if [ -z "$ADMIN_PASSWORD" ]; then
    MISSING_VARS="${MISSING_VARS}ADMIN_PASSWORD "
fi
if [ -z "$USER_USERNAME" ]; then
    MISSING_VARS="${MISSING_VARS}USER_USERNAME "
fi
if [ -z "$USER_PASSWORD" ]; then
    MISSING_VARS="${MISSING_VARS}USER_PASSWORD "
fi

if [ -n "$MISSING_VARS" ]; then
    echo "環境変数: ${MISSING_VARS}が設定されていません。" >&2
    exit 1
fi

# # --- 1. 管理者トークンの取得 ---
TOKEN_RESPONSE=$(curl -s -c cookie.txt --data "client_id=admin-cli&grant_type=password&username=${ADMIN_USERNAME}&password=${ADMIN_PASSWORD}" "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token")
ACCESS_TOKEN=$(echo "${TOKEN_RESPONSE}" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\(.*\)"/\1/')
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "トークンの取得に失敗しました。" >&2
    exit 1
fi

# 共通ヘッダー設定
AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"
CONTENT_TYPE_HEADER="Content-Type: application/json"

# トークンが有効になるまでリトライする
TOKEN_READY=false
TOKEN_ATTEMPTS=0
MAX_ATTEMPTS=24

while [ "$TOKEN_READY" = false ] && [ $TOKEN_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    TOKEN_ATTEMPTS=$((TOKEN_ATTEMPTS + 1))
    echo "Attempt $TOKEN_ATTEMPTS: トークンの有効性を確認..."
    
    # トークンの有効性を確認するために、簡単な管理APIコールを実行
    TOKEN_TEST=$(curl -s -b cookie.txt -w "%{http_code}" -o /dev/null -X GET "${KEYCLOAK_URL}/admin/realms" \
      -H "${AUTH_HEADER}")
    
    if [ "$TOKEN_TEST" = "200" ]; then
        TOKEN_READY=true
    else
        echo "トークンが有効になっていません。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$TOKEN_READY" = false ]; then
    echo "トークンの取得に失敗しました。" >&2
    exit 1
fi

# --- 2. Realm 作成 ---
REALM_PAYLOAD=$(cat <<EOF
{
  "realm": "${NEW_REALM}",
  "enabled": true
}
EOF
)

# レルムが作成されるまでリトライする
REALM_READY=false
REALM_ATTEMPTS=0

while [ "$REALM_READY" = false ] && [ $REALM_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    REALM_ATTEMPTS=$((REALM_ATTEMPTS + 1))
    echo "Attempt $REALM_ATTEMPTS: レルムを作成中..."
    
    # レルム作成を試行
    REALM_RESPONSE=$(curl -s -b cookie.txt -w "\n%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms" \
      -H "${AUTH_HEADER}" \
      -H "${CONTENT_TYPE_HEADER}" \
      -d "${REALM_PAYLOAD}")
    
    HTTP_CODE=$(echo "$REALM_RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 204 ] || [ "$HTTP_CODE" -eq 409 ]; then
        REALM_READY=true
    else
        echo "レルムが作成されていません。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$REALM_READY" = false ]; then
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

# クライアントが作成されるまでリトライする
CLIENT_CREATED=false
CLIENT_ATTEMPTS=0

while [ "$CLIENT_CREATED" = false ] && [ $CLIENT_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    CLIENT_ATTEMPTS=$((CLIENT_ATTEMPTS + 1))
    echo "Attempt $CLIENT_ATTEMPTS: クライアントを作成..."
    
    CLIENT_RESPONSE=$(curl -s -b cookie.txt -w "\n%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/clients" \
      -H "${AUTH_HEADER}" \
      -H "${CONTENT_TYPE_HEADER}" \
      -d "${CLIENT_PAYLOAD}")
    
    HTTP_CODE=$(echo "$CLIENT_RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 204 ] || [ "$HTTP_CODE" -eq 409 ]; then
        CLIENT_CREATED=true
    else
        echo "クライアントが作成されていません。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$CLIENT_CREATED" = false ]; then
    echo "Client 作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# クライアントが利用可能になるまで待機してUUIDを取得
CLIENT_READY=false
CLIENT_UUID_ATTEMPTS=0

while [ "$CLIENT_READY" = false ] && [ $CLIENT_UUID_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    CLIENT_UUID_ATTEMPTS=$((CLIENT_UUID_ATTEMPTS + 1))
    echo "Attempt $CLIENT_UUID_ATTEMPTS: クライアント ${CLIENT_ID_VALUE} を検索中..."
    
    CLIENTS_RESPONSE=$(curl -s -b cookie.txt -X GET "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/clients" \
      -H "${AUTH_HEADER}")
    CLIENT_UUID=$(echo "${CLIENTS_RESPONSE}" | grep -o '{[^}]*}' | grep "\"clientId\":\"${CLIENT_ID_VALUE}\"" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
    
    if [ -n "$CLIENT_UUID" ] && [ "$CLIENT_UUID" != "null" ]; then
        CLIENT_READY=true
    else
        echo "クライアントのUUIDがまだ利用できません。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$CLIENT_READY" = false ]; then
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

# ユーザー作成を適切なエラーハンドリングでリトライ
SKIP_PASSWORD="false"
USER_CREATED=false
USER_ATTEMPTS=0

while [ "$USER_CREATED" = false ] && [ $USER_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    USER_ATTEMPTS=$((USER_ATTEMPTS + 1))
    echo "Attempt $USER_ATTEMPTS: ユーザー ${USER_USERNAME} を作成中..."
    
    USER_CREATE_RESPONSE=$(curl -s -b cookie.txt -w "\n%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/users" \
      -H "${AUTH_HEADER}" \
      -H "${CONTENT_TYPE_HEADER}" \
      -d "${USER_PAYLOAD}")
    
    HTTP_CODE=$(echo "$USER_CREATE_RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" -eq 409 ]; then
        SKIP_PASSWORD="true"
        USER_CREATED=true
    elif [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 204 ]; then
        USER_CREATED=true
    else
        echo "ユーザーが作成されていません。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$USER_CREATED" = false ]; then
    echo "ユーザー作成エラー。HTTP ステータス: ${HTTP_CODE}" >&2
    exit 1
fi

# ユーザーが準備できるまで待機してユーザーIDを取得
USER_READY=false
USER_ID_ATTEMPTS=0

while [ "$USER_READY" = false ] && [ $USER_ID_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    USER_ID_ATTEMPTS=$((USER_ID_ATTEMPTS + 1))
    echo "Attempt $USER_ID_ATTEMPTS: ユーザー ${USER_USERNAME} を検索中..."
    
    USER_RESPONSE=$(curl -s -b cookie.txt -X GET "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/users?username=${USER_USERNAME}" \
      -H "${AUTH_HEADER}")
    USER_ID=$(echo "${USER_RESPONSE}" | grep -o '{[^}]*}' | head -n 1 | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
    
    if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
        USER_READY=true
    else
        echo "ユーザーがまだ準備できていません。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$USER_READY" = false ]; then
    echo "ユーザー ID の取得に失敗しました。" >&2
    exit 1
fi

# --- 5. ユーザーのパスワード設定 ---
if [ "$SKIP_PASSWORD" = "false" ]; then
    PASSWORD_PAYLOAD=$(cat <<EOF
    {
    "type": "password",
    "value": "${USER_PASSWORD}",
    "temporary": false
    }
EOF
    )
    
    # パスワード設定をリトライ
    PASSWORD_SET=false
    PASSWORD_ATTEMPTS=0
    
    while [ "$PASSWORD_SET" = false ] && [ $PASSWORD_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        PASSWORD_ATTEMPTS=$((PASSWORD_ATTEMPTS + 1))
        echo "Attempt $PASSWORD_ATTEMPTS: ユーザー ${USER_USERNAME} のパスワードを設定中..."
        
        PASSWORD_RESPONSE=$(curl -s -b cookie.txt -w "\n%{http_code}" -X PUT "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/users/${USER_ID}/reset-password" \
        -H "${AUTH_HEADER}" \
        -H "${CONTENT_TYPE_HEADER}" \
        -d "${PASSWORD_PAYLOAD}")
        
        HTTP_CODE=$(echo "$PASSWORD_RESPONSE" | tail -n1)
        
        if [ "$HTTP_CODE" -eq 204 ]; then
            PASSWORD_SET=true
        else
            echo "パスワード設定に失敗しました。5秒後に再確認..."
            sleep 5
        fi
    done
    
    if [ "$PASSWORD_SET" = false ]; then
        echo "パスワード設定エラー。HTTP ステータス: ${HTTP_CODE}" >&2
        exit 1
    fi
fi


# --- 6. Client Secret の取得 ---
SECRET_RETRIEVED=false
SECRET_ATTEMPTS=0

while [ "$SECRET_RETRIEVED" = false ] && [ $SECRET_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    SECRET_ATTEMPTS=$((SECRET_ATTEMPTS + 1))
    echo "Attempt $SECRET_ATTEMPTS: Client Secretを取得中..."
    
    CLIENT_SECRET_RESPONSE=$(curl -s -b cookie.txt -X GET "${KEYCLOAK_URL}/admin/realms/${NEW_REALM}/clients/${CLIENT_UUID}/client-secret" \
      -H "${AUTH_HEADER}" \
      -H "${CONTENT_TYPE_HEADER}")
    
    CLIENT_SECRET=$(echo "${CLIENT_SECRET_RESPONSE}" | grep -o '"value":"[^"]*"' | sed 's/"value":"\([^"]*\)"/\1/')
    
    if [ -n "${CLIENT_SECRET}" ] && [ "${CLIENT_SECRET}" != "null" ]; then
        SECRET_RETRIEVED=true
    else
        echo "Client Secret の取得に失敗しました。5秒後に再確認..."
        sleep 5
    fi
done

if [ "$SECRET_RETRIEVED" = false ]; then
    echo "Client Secret の取得に失敗しました。" >&2
    exit 1
fi

cat <<EOF > output.txt
{
  "CLIENT_ID_VALUE": "$CLIENT_ID_VALUE",
  "CLIENT_SECRET": "$CLIENT_SECRET"
}
EOF
echo "Client ID and Client Secret were saved to the file output.txt"