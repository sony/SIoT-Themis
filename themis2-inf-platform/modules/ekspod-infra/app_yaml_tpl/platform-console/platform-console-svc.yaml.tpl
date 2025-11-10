apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-platform-console-svc
  labels:
    app: app
    name: platform-console
spec:
  type: ClusterIP
  selector:
    app: app
    name: platform-console
  ports:
  - name: pf-csl-port
    port: 3000
    protocol: TCP
    targetPort: 3000
