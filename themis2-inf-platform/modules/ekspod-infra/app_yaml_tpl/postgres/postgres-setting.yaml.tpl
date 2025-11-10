apiVersion: batch/v1
kind: Job
metadata:
  namespace: default
  name: ${sys_name}-${env}-postgres-setting
  labels:
    app: app
    name: postgres-setting
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: postgres-setting
          image: ${postgres_setting_ecr_url}:latest
          env:
            - name: POSTGRES_DATABASE_URL
              value: ${aurora_db_endpoint}
