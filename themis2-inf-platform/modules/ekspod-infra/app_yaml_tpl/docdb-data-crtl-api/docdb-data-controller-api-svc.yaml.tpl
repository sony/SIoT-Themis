apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-docdb-data-controller-svc
  labels:
    app: app
    name: docdb-data-controller-api
spec:
  type: ClusterIP
  selector:
    app: app
    name: docdb-data-controller-api
  ports:
  - name: docdb-data-ctrl-port
    port: 3000
    protocol: TCP
    targetPort: 3000
