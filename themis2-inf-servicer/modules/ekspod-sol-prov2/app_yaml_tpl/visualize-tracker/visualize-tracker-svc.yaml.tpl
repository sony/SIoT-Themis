apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-visualize-tracker2-svc
  labels:
    app: app
    name: visualize-tracker
spec:
  type: ClusterIP
  selector:
    app: app
    name: visualize-tracker
  ports:
  - name: vsl-trk-port
    port: 3000
    protocol: TCP
    targetPort: 3000
