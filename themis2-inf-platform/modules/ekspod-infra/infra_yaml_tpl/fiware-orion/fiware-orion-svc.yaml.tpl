apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-orion-svc
  labels:
    app: fiware
    name: orion
spec:
  type: ClusterIP
  selector:
    app: fiware
    name: orion
  ports:
  - name: orion
    port: 1026
    protocol: TCP
    targetPort: 1026
