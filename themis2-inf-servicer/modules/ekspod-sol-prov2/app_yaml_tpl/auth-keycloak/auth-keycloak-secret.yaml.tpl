apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: keycloak-secret
type: Opaque
data:
  kcadminname: ${base64_keycloak_admin}
  kcpassword: ${base64_keycloak_admin_password}
