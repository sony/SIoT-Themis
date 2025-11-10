apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-cygnus-svc
  labels:
    app: fiware
    name: cygnus
spec:
  type: ClusterIP
  selector:
    app: fiware
    name: cygnus
  ports:
  - name: service-port
    port: 5051
    protocol: TCP
    targetPort: service-port
  - name: api-port
    port: 5081
    protocol: TCP
    targetPort: api-port
