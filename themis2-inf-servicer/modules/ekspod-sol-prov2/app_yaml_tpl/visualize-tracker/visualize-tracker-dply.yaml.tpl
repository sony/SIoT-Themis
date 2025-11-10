apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-visualize-tracker
  labels:
    app: app
    name: visualize-tracker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
      name: visualize-tracker
  template:
    metadata:
      labels:
        app: app
        name: visualize-tracker
    spec:
      containers:
        - name: visualize-tracker
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_sample_value}/visualize-tracker/${env}:latest
          ports:
          - containerPort: 3000
            name: vsl-trk-port
            protocol: TCP
          env:
          - name: BACKEND_API_KEY
            valueFrom:
              secretKeyRef:
                name: ${sys_name}-${env}-visualize-tracker-secret
                key: BACKEND_API_KEY
          - name: DATA_CONTROLLER_API_ORIGIN
            value: "https://kong.${env}.unvs-themis.com/data-controller-api"
          - name: VISUALIZE_TRACKER_ORIGIN
            value: "https://tracker2.${env}.unvs-themis.com"
          - name: REALTIME_NOTIFICATION_API_ORIGIN
            value: "https://kong.${env}.unvs-themis.com/realtime-notification-api"
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - kill -INT $(pidof node)
