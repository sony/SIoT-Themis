apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-realtime-analyzer
  labels:
    app: app
    name: realtime-analyzer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
      name: realtime-analyzer
  template:
    metadata:
      labels:
        app: app
        name: realtime-analyzer
    spec:
      containers:
        - name: realtime-analyzer
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_sample_value}/realtime-analyzer/${env}:latest
          ports:
          - containerPort: 3000
            name: rt-anl-port
            protocol: TCP
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - kill -INT $(pidof node)
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
