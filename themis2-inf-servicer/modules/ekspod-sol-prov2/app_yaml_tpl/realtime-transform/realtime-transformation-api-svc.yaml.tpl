apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-realtime-transformation2-svc
  labels:
    app: app
    name: realtime-transformation-api
spec:
  type: ClusterIP
  selector:
    app: app
    name: realtime-transformation-api
  ports:
  - name: rt-trans-port
    port: 3000
    protocol: TCP
    targetPort: 3000
