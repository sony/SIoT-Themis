apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-realtime-transformation-api
  labels:
    app: app
    name: realtime-transformation-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
      name: realtime-transformation-api
  template:
    metadata:
      labels:
        app: app
        name: realtime-transformation-api
    spec:
      containers:
        - name: realtime-transformation-api
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_sample_value}/realtime-transformation-api/${env}:latest
          env:
          - name: GRAFANA_ENDPOINT
            value: "http://${sys_name}-${env}-grafana-svc.default.svc.cluster.local:3000"
          - name: GRAFANA_ENDPOINT_PUSH_PATH
            value: "orion"
          ports:
          - containerPort: 3000
            name: rt-trans-port
            protocol: TCP
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
