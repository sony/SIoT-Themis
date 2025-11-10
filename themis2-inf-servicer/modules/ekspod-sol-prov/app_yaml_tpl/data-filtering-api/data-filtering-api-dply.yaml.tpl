apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-data-filtering-api
  labels:
    app: app
    name: data-filtering-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
      name: data-filtering-api
  template:
    metadata:
      labels:
        app: app
        name: data-filtering-api
    spec:
      containers:
        - name: data-filtering-api
          image: ${ecr_url}:latest
          args:
          - |
            POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local:5432/$(PG_DATABASE)?schema=public" npm run start:prod
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
          - name: BACKEND_API_KEY
            valueFrom:
              secretKeyRef:
                name: ${sys_name}-${env}-data-filtering-api-secret
                key: BACKEND_API_KEY
          - name: DATA_CONTROLLER_API_URL
            value: "https://kong.${env}.unvs-themis.com/data-controller-api"
          ports:
          - containerPort: 3000
            name: data-filt-port
            protocol: TCP
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
