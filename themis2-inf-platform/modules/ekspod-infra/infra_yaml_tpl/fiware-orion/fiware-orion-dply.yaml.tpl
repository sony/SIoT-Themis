apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-orion
  labels:
    app: fiware
    name: orion
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fiware
      name: orion
  template:
    metadata:
      labels:
        app: fiware
        name: orion
    spec:
      containers:
        - name: ${sys_name}-${env}-orion
          image: fiware/orion:4.0.0
          imagePullPolicy: Always
          env:
            - name: ORION_PORT
              value: "1026"
            - name: ORION_LOG_LEVEL
              value: "INFO"
            - name: ORION_MONGO_URI
              value: "${orion_mongo_uri}"
            - name: ORION_MONGO_DB
              value: "orion"
            - name: ORION_MONGO_USER
              valueFrom:
                secretKeyRef:
                  key: orion-mongo-admin
                  name: orion-mongo-secret
                  optional: false
            - name: ORION_MONGO_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: orion-mongo-admin-password
                  name: orion-mongo-secret
                  optional: false
          ports:
          - containerPort: 1026
            name: orion
            protocol: TCP
          livenessProbe:
            failureThreshold: 5
            initialDelaySeconds: 60
            periodSeconds: 1
            successThreshold: 1
            httpGet:
              path: /version
              port: 1026
            timeoutSeconds: 1
          readinessProbe:
            failureThreshold: 3
            initialDelaySeconds: 60
            periodSeconds: 1
            successThreshold: 1
            httpGet:
              path: /version
              port: 1026
            timeoutSeconds: 1
          resources:
            requests:
              cpu: 25m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 512Mi
