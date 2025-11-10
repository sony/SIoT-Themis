apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-docdb-realtime-notification-svc
  labels:
    app: app
    name: docdb-realtime-notification-api
spec:
  type: ClusterIP
  selector:
    app: app
    name: docdb-realtime-notification-api
  ports:
  - name: docdb-rt-notify-port
    port: 3000
    protocol: TCP
    targetPort: 3000
