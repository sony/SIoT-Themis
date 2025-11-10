apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-postgresql-svc
  labels:
    app: postgres
spec:
  selector:
    app: postgres
  type: ClusterIP
  ports:
  - name: postgres-svc
    port: 5432
    protocol: TCP
    targetPort: 5432
  clusterIP: None
