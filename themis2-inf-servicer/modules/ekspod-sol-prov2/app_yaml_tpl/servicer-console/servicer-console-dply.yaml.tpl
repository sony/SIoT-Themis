apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-servicer2-console
  labels:
    app: app
    name: servicer-console
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
      name: servicer-console
  template:
    metadata:
      labels:
        app: app
        name: servicer-console
    spec:
      initContainers:
      - name: schema
        image: ${ecr_url}:latest
        args:
        - |
          export POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local:5432/$(PG_DATABASE)?schema=public"
        command: ["/bin/sh", "-c"]
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
      containers:
      - name: servicer2-console
        image: ${ecr_url}:latest
        args:
        - |
          POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local:5432/$(PG_DATABASE)?schema=public" NEXTAUTH_SECRET="ZYaibr2LG9ikxV/txr34VWiglVHH1JqK/sV/e+tr9s8=" npm run start
        ports:
        - containerPort: 3000
          name: svc-csl-port
          protocol: TCP
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
        - name: REALTIME_NOTIFICATION_API_ENDPOINT
          value: "https://kong.${env}.unvs-themis.com/realtime-notification-api"
        - name: KEYCLOAK_ENDPOINT
          value: ${keycloak_endpoint_url}
        - name: KEYCLOAK_REALM
          value: ${keycloak_realm}
        - name: KEYCLOAK_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: ${sys_name}-${env}-servicer2-console-secret
              key: KEYCLOAK_CLIENT_ID
        - name: KEYCLOAK_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: ${sys_name}-${env}-servicer2-console-secret
              key: KEYCLOAK_CLIENT_SECRET
        - name: REALTIME_NOTIFICATION_API_KEY
          value: ${realtime_notification_api_key}
        lifecycle:
          preStop:
            exec:
              command:
                - /bin/sh
                - -c
                - kill -INT $(pidof node)
