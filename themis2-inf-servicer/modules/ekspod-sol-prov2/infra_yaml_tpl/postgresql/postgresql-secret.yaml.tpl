apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: postgresql-secret
type: Opaque
data:
  postgresql_user: ${base64_postgresql_admin}
  postgresql_password: ${base64_postgresql_admin_password}
