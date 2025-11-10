apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: postgresql-secret
type: Opaque
data:
  postgresql_user: ${postgresql_user}
  postgresql_password: ${postgresql_password}
