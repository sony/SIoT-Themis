apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-servicer-console-svc
  labels:
    app: app
    name: servicer-console
spec:
  type: ClusterIP
  selector:
    app: app
    name: servicer-console
  ports:
  - name: svc-csl-port
    port: 3000
    protocol: TCP
    targetPort: 3000
