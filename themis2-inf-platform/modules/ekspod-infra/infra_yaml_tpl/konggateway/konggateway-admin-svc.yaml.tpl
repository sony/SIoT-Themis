#Kong Gateway Service Admin
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-external-kong-admin-svc
  labels:
   app: external-kong
spec:
  type: ClusterIP
  selector:
    app: external-kong
  ports:
  - name: admin
    port: 8001
    targetPort: 8001
  - name: admin-ssl
    port: 8444
    targetPort: 8444
