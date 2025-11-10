apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: orion-mongo-secret
type: Opaque
data:
  orion-mongo-admin: ${orion_mongo_admin}
  orion-mongo-admin-password: ${orion_mongo_admin_password}
