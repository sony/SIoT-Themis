#Grafana Gateway Service
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: ${sys_name}-${env}-grafana-svc
  labels:
   app: grafana
spec:
  type: ClusterIP
  selector:
    app: grafana
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
