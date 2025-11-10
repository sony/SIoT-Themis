# KeyCloak
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-keycloak
  labels:
    app: keycloak
spec:
  selector:
    matchLabels:
      app: keycloak
  replicas: 1
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: ${sys_name}-${env}-keycloak
          image: quay.io/keycloak/keycloak:25.0.4
          args: ["start-dev"]
          env:
            - name: KC_HOSTNAME
              value: "${keycloak_endpoint_url}"
            - name: KC_HOSTNAME_BACKCHANNEL_DYNAMIC
              value: "true"
            - name: KC_LOG_LEVEL
              value: "INFO"
            - name: TZ
              value: "Asia/Tokyo"
            - name: KC_DB
              value: "postgres"
            - name: KC_DB_URL
              value: "jdbc:postgresql://${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local:5432/keycloak"
            - name: KC_PROXY_HEADERS
              value: "xforwarded"
            - name: KC_HEALTH_ENABLED
              value: "true"
            - name: KC_CACHE
              value: "local"
            - name: KC_CACHE_STACK
              value: "kubernetes"
            - name: JAVA_OPTS_APPEND
              value: "-Djgroups.dns.query=${sys_name}-${env}-keycloak-svc.default.svc.cluster.local"
            - name: KEYCLOAK_ADMIN
              valueFrom:
                secretKeyRef:
                  name: keycloak-secret
                  key: kcadminname
            - name: KEYCLOAK_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-secret
                  key: kcpassword
            - name: KC_DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: postgresql_user
            - name: KC_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: postgresql_password
          ports:
            - name: http
              containerPort: 8080
            - name: health
              containerPort: 9000
          livenessProbe:
            failureThreshold: 5
            initialDelaySeconds: 60
            periodSeconds: 15
            successThreshold: 1
            httpGet:
              path: /health/ready
              port: 9000
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 15
            successThreshold: 1
            httpGet:
              path: /health/ready
              port: 9000
            timeoutSeconds: 10
          resources:
            requests:
              cpu: 100m
              memory: 1Gi
            limits:
              cpu: 400m
              memory: 2Gi
