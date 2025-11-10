apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-agent-svc
  labels:
    app: app
    name: eltres-agent
spec:
  type: ClusterIP
  selector:
    app: app
    name: eltres-agent
  ports:
  - name: eltres-ag-port
    port: 3000
    protocol: TCP
    targetPort: 3000
