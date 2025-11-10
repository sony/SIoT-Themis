apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-agent
  labels:
    app: app
    name: eltres-agent
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
      name: eltres-agent
  template:
    metadata:
      labels:
        app: app
        name: eltres-agent
    spec:
      containers:
        - name: eltres-agent
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_option_value}/eltres-agent/${env}:latest
          ports:
          - containerPort: 3000
            name: eltres-ag-port
            protocol: TCP
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
          - name: HOST
            value: ${iot_core_endpoint}
          - name: PORT
            value: "8883"
          - name: CA_PATH
            value: /eltres-json/certs/AmazonRootCA.crt
          - name: CERT_PATH
            value: /eltres-json/certs/certificate.pem
          - name: KEY_PATH
            value: /eltres-json/certs/private-client.key
          - name: DUPLICATION_CHECK_TTL
            value: "60"
          - name: TOPICS
            value: '${eltres_agent_topics}'
          - name: MAPPINGS_PATH
            value: mappings/mappings.json
          - name: ORION_URL
            value: http://${sys_name}-${env}-orion-svc.default.svc.cluster.local:1026
          - name: REDIS_HOST
            value: ${elasticache_endpoint}
          - name: REDIS_PORT
            value: "6379"
          - name: REDIS_RETRIES
            value: "3"
          - name: REDIS_PREFIX
            value: "mqtt-message" 
          - name: FIWARE_SERVICE
            value: ${sys_name}
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - kill -INT $(pidof node)
          volumeMounts:
            - name: json-certs-volume
              mountPath: /eltres-json/certs
              readOnly: true
      volumes:
        - name: json-certs-volume
          secret:
            secretName: ${sys_name}-${env}-json-certs
            items:
              - key: AmazonRootCA.crt
                path: AmazonRootCA.crt
              - key: certificate.pem
                path: certificate.pem
              - key: private-client.key
                path: private-client.key
