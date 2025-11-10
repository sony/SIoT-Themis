apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-data-filtering-api-svc
  labels:
    app: app
    name: data-filtering-api
spec:
  type: ClusterIP
  selector:
    app: app
    name: data-filtering-api
  ports:
  - name: data-filt-port
    port: 3000
    protocol: TCP
    targetPort: 3000
