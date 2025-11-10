apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-platform-console
  labels:
    app: app
    name: platform-console
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
      name: platform-console
  template:
    metadata:
      labels:
        app: app
        name: platform-console
    spec:
      initContainers:
      - name: schema
        image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${sys_name}/platform-console/${env}:latest
        args:
        - |
          export POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${aurora_db_endpoint}:5432/$(PG_DATABASE)?schema=public" ; npx prisma migrate deploy --schema=./packages/schema/prisma/schema-postgresql.prisma && npx ts-node --compiler-options '{"module": "commonjs", "target": "ES2021"}' ./packages/schema/prisma/seed.ts
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
      - name: platform-console
        image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${sys_name}/platform-console/${env}:latest
        args:
        - |
          POSTGRES_DATABASE_URL="postgresql://$(PG_USERNAME):$(PG_PASSWORD)@${aurora_db_endpoint}:5432/$(PG_DATABASE)?schema=public" NEXTAUTH_SECRET="ZYaibr2LG9ikxV/txr34VWiglVHH1JqK/sV/e+tr9s8=" npm run start
        ports:
        - containerPort: 3000
          name: pf-csl-port
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
        - name: KONG_GATEWAY_ORIGIN
          value: http://${sys_name}-${env}-external-kong-admin-svc.default.svc.cluster.local:8001
        - name: REALTIME_NOTIFICATION_API_ORIGIN
          value: "http://${sys_name}-${env}-external-kong-proxy-svc.default.svc.cluster.local:8000/realtime-notification-api"
        - name: ELTRES_AGENT_ORIGIN
          value: http://${sys_name}-${env}-eltres-agent-svc.default.svc.cluster.local:3000
        - name: KEYCLOAK_ENDPOINT
          value: ${keycloak_endpoint_url}
        - name: KEYCLOAK_REALM
          value: ${keycloak_realm}
        - name: KEYCLOAK_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: ${sys_name}-${env}-platform-console-secret
              key: KEYCLOAK_CLIENT_ID
        - name: KEYCLOAK_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: ${sys_name}-${env}-platform-console-secret
              key: KEYCLOAK_CLIENT_SECRET
        - name: ORION_ENDPOINT
          value: "http://${sys_name}-${env}-orion-svc:1026"
        - name: CYGNUS_ENDPOINT
          value: http://${sys_name}-${env}-cygnus-svc:5051
        - name: FIWARE_SERVICE
          value: ${sys_name}

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
