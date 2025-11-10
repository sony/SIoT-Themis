apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-console
  labels:
    app: app
    name: eltres-console
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
      name: eltres-console
  template:
    metadata:
      labels:
        app: app
        name: eltres-console
    spec:
      initContainers:
        - name: init-eltres
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_option_value}/eltres-console/${env}:latest
          workingDir: /config
          command:
            - /bin/sh
            - -c
            - |
              set -euvx
              sh ./init-eltres-console.sh
          volumeMounts: 
            - name: nextauthvolume
              mountPath: /config
            - name: secretvolume
              mountPath: /secrettmp
      containers:
        - name: eltres-console
          image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_option_value}/eltres-console/${env}:latest
#          command:
#            - /bin/sh
#            - -c
#            - |
#              set -euvx
#              source /secrettmp/secret.txt
          env:
          - name: NEXTAUTH_URL
            value: "${iotagent_endpoint_url}"
          - name: NEXTAUTH_SECRET
            value: "ZYaibr2LG9ikxV/txr34VWiglVHH1JqK/sV/e+tr9s8="
          - name: KEYCLOAK_ENDPOINT
            value: "${keycloak_endpoint_url}"
          - name: KEYCLOAK_REALM
            value: "themis2"
          - name: KEYCLOAK_CLIENT_ID
            value: "console"
          - name: KEYCLOAK_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: ${sys_name}-${env}-iotagent-console-secret
                key: clientsecret
          ports:
          - containerPort: 3000
            name: eltres-csl-port
            protocol: TCP
          volumeMounts: 
            - name: nextauthvolume
              mountPath: /config
            - name: secretvolume
              mountPath: /secrettmp
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 512Mi
      volumes: 
      - name: nextauthvolume
        configMap:
          name: ${sys_name}-${env}-eltres-console-configmap
      - name: secretvolume
        emptyDir: {}