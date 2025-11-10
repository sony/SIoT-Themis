apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${sys_name}-${env}-iotagent-json
  namespace: default
  labels:
    app: fiware
    name: iotagent-json
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fiware
      component: iotagent-json
  template:
    metadata:
      labels:
        app: fiware
        component: iotagent-json
    spec:
      containers:
        - name: ${sys_name}-${env}-iotagent-json
          image: telefonicaiot/iotagent-json:3.8.0
          imagePullPolicy: Always
          env:
            - name: IOTA_MQTT_PORT
              value: "8883"
            - name: IOTA_MQTT_PROTOCOL
              value: "mqtts"
            - name: IOTA_MQTT_QOS
              value: "1"
            - name: IOTA_MQTT_HOST
              value: "${iot_core_endpoint}"
            - name: IOTA_MQTT_CA
              value: "/iotagent-json/certs/AmazonRootCA.crt"
            - name: IOTA_MQTT_CERT
              value: "/iotagent-json/certs/certificate.pem"
            - name: IOTA_MQTT_KEY
              value: "/iotagent-json/certs/private-client.key"
            - name: IOTA_MQTT_SUBSCRIBE_BATCH_SIZE
              value: "8"
            - name: IOTA_CB_HOST
              value: "${sys_name}-${env}-orion-svc.default.svc.cluster.local"
            - name: IOTA_CB_PORT
              value: "1026"
            - name: IOTA_CB_NGSI_VERSION
              value: "v2"
            - name: IOTA_REGISTRY_TYPE
              value: "mongodb"
            - name: IOTA_MONGO_HOST
              valueFrom:
                secretKeyRef:
                  name: auth-host-secret
                  key: auth-host
            - name: IOTA_MONGO_PORT
              value: "${docdb_port}"
            - name: IOTA_MONGO_DB
              value: "iotagentjson"
            - name: IOTA_NORTH_PORT
              value: "4041"  
            - name: IOTA_MONGO_EXTRAARGS
              value: "{\"replicaSet\":\"rs0\",\"tls\":true,\"retryWrites\":false,\"tlsAllowInvalidCertificates\":true,\"authMechanism\":\"SCRAM-SHA-1\"}"
            - name: IOTA_LOG_LEVEL
              value: "INFO"
            - name: IOTA_TIMESTAMP
              value: "true"
            - name: IOTA_AMQP_ENABLED
              value: "false"
            - name: IOTA_TRANSPORTS
              value: "HTTP,MQTT"
          ports:
            - containerPort: 4041
              name: iotagent
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /iot/about
              port: 4041
            initialDelaySeconds: 20
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /iot/about
              port: 4041
            initialDelaySeconds: 10
            periodSeconds: 5
          volumeMounts:
            - name: json-certs-volume
              mountPath: /iotagent-json/certs
              readOnly: true
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
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
