#Kong Gateway Service Proxy
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-external-kong-proxy-svc
  labels:
   app: external-kong
spec:
  type: ClusterIP
  selector:
    app: external-kong
  ports:
  - name: proxy
    port: 8000
    targetPort: 8000
  - name: proxy-ssl
    port: 8443
    targetPort: 8443
