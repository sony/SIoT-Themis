apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-iotagent-json-svc
  labels:
    app: fiware
    name: iotagent-json
spec:
  type: ClusterIP
  selector:
    app: fiware
    component: iotagent-json
  ports:
    - name: http
      port: 4041
      targetPort: 4041
      protocol: TCP
    - name: device
      port: 7896
      targetPort: 7896
      protocol: TCP
