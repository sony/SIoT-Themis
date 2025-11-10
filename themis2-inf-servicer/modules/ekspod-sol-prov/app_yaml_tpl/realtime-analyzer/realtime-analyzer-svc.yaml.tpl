apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-realtime-analyzer-svc
  labels:
    app: app
    name: realtime-analyzer
spec:
  type: ClusterIP
  selector:
    app: app
    name: realtime-analyzer
  ports:
  - name: rt-anl-port
    port: 3000
    protocol: TCP
    targetPort: 3000
