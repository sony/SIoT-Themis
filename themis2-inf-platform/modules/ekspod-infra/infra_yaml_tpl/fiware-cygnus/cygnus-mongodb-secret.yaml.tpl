apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: cygnus-mongodb-secret
type: Opaque
data:
  cygnus-mongo-admin: ${cygnus_mongo_admin}
  cygnus-mongo-admin-password: ${cygnus_mongo_admin_password}
