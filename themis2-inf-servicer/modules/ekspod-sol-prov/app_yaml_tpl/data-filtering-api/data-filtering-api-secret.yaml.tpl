apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: ${sys_name}-${env}-data-filtering-api-secret
  labels:
    app: app
    name: data-filtering-api
type: Opaque
data:
  BACKEND_API_KEY: ${base64_backend_api_key}
