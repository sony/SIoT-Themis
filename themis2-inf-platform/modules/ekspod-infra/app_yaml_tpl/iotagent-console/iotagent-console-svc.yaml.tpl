apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-console-svc
  labels:
    app: app
    name: eltres-console
spec:
  type: ClusterIP
  selector:
    app: app
    name: eltres-console
  ports:
  - name: eltres-csl-port
    port: 3000
    protocol: TCP
    targetPort: 3000
