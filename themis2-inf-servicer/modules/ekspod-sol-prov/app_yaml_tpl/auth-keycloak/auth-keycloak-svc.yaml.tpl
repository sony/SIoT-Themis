apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-keycloak2-svc
  labels:
    app: keycloak
spec:
  type: ClusterIP
  selector:
    app: keycloak
  ports:
    - name: "http"
      port: 8080
      protocol: "TCP"
      targetPort: 8080
