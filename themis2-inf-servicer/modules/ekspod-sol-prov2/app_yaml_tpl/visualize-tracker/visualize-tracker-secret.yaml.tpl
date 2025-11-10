apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: ${sys_name}-${env}-visualize-tracker-secret
  labels:
    app: app
    name: platform-console
type: Opaque
data:
  BACKEND_API_KEY: ${base64_backend_api_key}
