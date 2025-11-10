apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: keycloak-secret
type: Opaque
data:
  kcadminname: ${keycloak_setting_admin_username}
  kcpassword: ${keycloak_setting_admin_password}
