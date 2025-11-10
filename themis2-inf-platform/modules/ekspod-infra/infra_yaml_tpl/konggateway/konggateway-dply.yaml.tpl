apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-external-kong
  labels:
   app: external-kong
spec:
  replicas: 2
  selector:
    matchLabels:
      app: external-kong
  template:
    metadata:
      labels:
        app: external-kong
    spec:
      volumes:
        - name: init-script-volume
          configMap:
            name: init-kong
      serviceAccountName: ${sys_name}-${env}-external-kong-serviceaccount
      initContainers:
      - name: kong-init
        image: kong:3.4.2
        env:
        - name: KONG_DATABASE
          value: "postgres"
        - name: KONG_PG_HOST
          value: "${aurora_db_endpoint}"
        - name: KONG_PG_PORT
          value: "5432"
        - name: KONG_PG_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: postgresql_user
        - name: KONG_PG_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: postgresql_password
        - name: KONG_PG_DATABASE
          value: "kong"
        - name: KONG_ADMIN_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_LISTEN
          value: "0.0.0.0:8001, 0.0.0.0:8444 ssl"
        args:
          - kong
          - migrations
          - bootstrap
      containers:
      - name: ${sys_name}-${env}-external-kong
        image: kong:3.4.2
        env:
        - name: KONG_DATABASE
          value: "postgres"
        - name: KONG_PG_HOST
          value: "${aurora_db_endpoint}"
        - name: KONG_PG_PORT
          value: "5432"
        - name: KONG_PG_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: postgresql_user
        - name: KONG_PG_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: postgresql_password
        - name: KONG_PG_DATABASE
          value: "kong"
        - name: KONG_PROXY_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_ADMIN_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_PROXY_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_LISTEN
          value: "0.0.0.0:8001"
        ports:
        - name: proxy
          containerPort: 8000
        - name: proxy-ssl
          containerPort: 8443
        - name: admin
          containerPort: 8001
        livenessProbe:
          httpGet:
            path: /status
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /status
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 1Gi
          limits:
            cpu: 400m
            memory: 2Gi
