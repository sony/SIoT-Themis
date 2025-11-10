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
            - name: PG_USERNAME
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: postgresql_user
            - name: PG_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: postgresql_password
            - name: PG_DATABASE
              value: ${sys_name}
            - name: POSTGRES_DATABASE_URL
              value: postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local:5432/$(PG_DATABASE)?schema=public
