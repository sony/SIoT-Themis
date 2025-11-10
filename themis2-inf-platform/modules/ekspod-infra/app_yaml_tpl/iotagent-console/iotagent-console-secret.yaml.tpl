apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: ${sys_name}-${env}-iotagent-console-secret
type: Opaque
data:
  clientsecret: ${iotagent_console_keycloak_client_secret}
