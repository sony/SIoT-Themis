apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-docdb-data-controller-api
  labels:
    app: app
    name: docdb-data-controller-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
      name: docdb-data-controller-api
  template:
    metadata:
      labels:
        app: app
        name: docdb-data-controller-api
    spec:
      containers:
        - name: docdb-data-controller-api
          image: ${ecr_url}:latest
          args:
          - |
            POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${aurora_db_endpoint}:5432/$(PG_DATABASE)?schema=public" npm run start:prod
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
          - name: MONGO_DATABASE_URL
            value: "${cygnus_mongo_uri}"
          ports:
          - containerPort: 3000
            name: data-ctrl-port
            protocol: TCP
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
