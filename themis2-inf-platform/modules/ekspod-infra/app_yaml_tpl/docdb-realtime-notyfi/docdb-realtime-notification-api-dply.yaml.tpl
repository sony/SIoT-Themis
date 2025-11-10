apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-docdb-realtime-notification-api
  labels:
    app: app
    name: docdb-realtime-notification-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
      name: docdb-realtime-notification-api
  template:
    metadata:
      labels:
        app: app
        name: docdb-realtime-notification-api
    spec:
      containers:
        - name: docdb-realtime-notification-api
          image: ${ecr_url}:latest
          args:
          - |
            POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${aurora_db_endpoint}:5432/$(PG_DATABASE)?schema=public" npm run start:prod
          command:
          - /bin/sh
          - -c
          env:
          - name: PG_USERNAME
            valueFrom:
              secretKeyRef:
                name: postgresql-secret
                key: postgresql_user
          - name: PG_PASSWORD
            valueFrom:
              secretKeyRef:
                name: postgresql-secret
                key: postgresql_password
          - name: PG_DATABASE
            value: ${sys_name}
          - name: ORION_URL
            value: "http://${sys_name}-${env}-orion-svc:1026"
          ports:
          - containerPort: 3000
            name: rt-notify-port
            protocol: TCP
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
