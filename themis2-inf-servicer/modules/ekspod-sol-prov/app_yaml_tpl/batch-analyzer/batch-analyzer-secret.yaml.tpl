apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: ${sys_name}-${env}-batch-analyzer-secret
  labels:
    app: app
    name: batch-analyzer
type: Opaque
data:
  DATA_CONTROLLER_API_KEY: ${data_controller_api_key}
