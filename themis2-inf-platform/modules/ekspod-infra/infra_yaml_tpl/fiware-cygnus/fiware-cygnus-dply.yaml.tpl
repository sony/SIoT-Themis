apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-cygnus
  labels:
    app: fiware
    name: cygnus
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fiware
      name: cygnus
  template:
    metadata:
      labels:
        app: fiware
        name: cygnus
    spec:
      volumes:
        - name: init-script-volume
          configMap:
            name: init-orion
        - name: script-tmp-volume
          emptyDir: {}
        - name: cygnus-config-volume
          configMap:
            name: cygnus-agent-conf
      initContainers:
        - name: init-cygnus
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_infra_value}/cygnus/${env}:latest
          imagePullPolicy: Always
          volumeMounts:
            - name: init-script-volume
              mountPath: /scripts
          command: 
            - /bin/sh
            - -c
            - |
              set -euvx
              cp /scripts/init-orion.sh /tmp/init-orion.sh
              chmod +x /tmp/init-orion.sh
              /tmp/init-orion.sh http://${sys_name}-${env}-orion-svc:1026 http://${sys_name}-${env}-cygnus-svc:5051
      containers:
        - name: ${sys_name}-${env}-cygnus
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_infra_value}/cygnus/${env}:latest
          imagePullPolicy: Always
          volumeMounts:
            - name: cygnus-config-volume
              mountPath: /opt/apache-flume/conf/agent.conf
              subPath: agent.conf
          env: 
          - name: CYGNUS_SERVICE_PORT
            value: "5051"
          - name: CYGNUS_API_PORT
            value: "5081"
          - name: CYGNUS_MONGO_ENABLE_ENCODING
            value: "true"
          - name: CYGNUS_MONGO_DATA_MODEL
            value: dm-by-service-path
          - name: CYGNUS_MONGO_ATTR_PERSISTENCE
            value: "column"
          - name: CYGNUS_LOG_LEVEL
            value: "INFO"
          - name: CYGNUS_SKIP_CONF_GENERATION
            value: "true"
          ports:
          - containerPort: 5051
            name: service-port
            protocol: TCP
          - containerPort: 5081
            name: api-port
            protocol: TCP
          livenessProbe:
            failureThreshold: 30
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 1
            httpGet:
              path: /v1/version
              port: 5081
            timeoutSeconds: 1
          readinessProbe:
            failureThreshold: 10
            initialDelaySeconds: 5
            periodSeconds: 3
            successThreshold: 1
            httpGet:
              path: /v1/version
              port: 5081
            timeoutSeconds: 1
          resources:
            requests:
              cpu: 25m
              memory: 512Mi
            limits:
              cpu: 100m
              memory: 2Gi
