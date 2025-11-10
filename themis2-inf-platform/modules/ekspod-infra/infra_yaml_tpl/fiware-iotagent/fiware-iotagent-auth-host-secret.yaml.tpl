apiVersion: v1
kind: Secret
metadata:
  name: auth-host-secret
  namespace: default
  labels:
    app: fiware
    name: iotagent-json
type: Opaque
data:
  auth-host: ${auth_host}
