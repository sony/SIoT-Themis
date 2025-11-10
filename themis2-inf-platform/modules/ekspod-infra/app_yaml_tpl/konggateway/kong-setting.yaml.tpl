apiVersion: batch/v1
kind: Job
metadata:
  namespace: default
  name: ${sys_name}-${env}-kong-setting
  labels:
    app: app
    name: kong-setting
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: kong-setting
          image: ${kong_setting_ecr_url}:latest
          env:
            - name: KONG_ADMIN_ENDPOINT
              value: http://${sys_name}-${env}-external-kong-admin-svc:8001
            - name: DATA_CONTROLLER_API_ENDPOINT
              value: http://${sys_name}-${env}-docdb-data-controller-svc:3000
            - name: REALTIME_NOTIFICATION_API_ENDPOINT
              value: http://${sys_name}-${env}-docdb-realtime-notification-svc:3000
            - name: IOT_AGENT_ENDPOINT
              value: http://${sys_name}-${env}-iotagent-json-svc:4041
