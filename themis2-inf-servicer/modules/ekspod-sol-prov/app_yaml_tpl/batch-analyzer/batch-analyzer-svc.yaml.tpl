apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-batch-analyzer-svc
  labels:
    app: app
    name: batch-analyzer
spec:
  type: ClusterIP
  selector:
    app: app
    name: batch-analyzer
  ports:
  - name: bat-anl-port
    port: 3000
    protocol: TCP
    targetPort: 3000
