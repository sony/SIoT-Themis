apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: ${sys_name}-${env}-servicer-console-secret
  labels:
    app: app
    name: servicer-console
type: Opaque
data:
  KEYCLOAK_CLIENT_ID: ${keycloak_client_id}
  KEYCLOAK_CLIENT_SECRET: ${keycloak_client_secret}
