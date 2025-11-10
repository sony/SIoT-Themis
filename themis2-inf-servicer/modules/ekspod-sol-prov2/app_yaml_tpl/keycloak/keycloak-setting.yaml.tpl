apiVersion: batch/v1
kind: Job
metadata:
  namespace: default
  name: ${sys_name}-${env}-keycloak-setting
  labels:
    app: app
    name: keycloak-setting
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: keycloak-setting
          image: curlimages/curl:latest
          command: ["/bin/sh", "-c"]
          args:
            - |
              sh /init-scripts/init.sh 1>/dev/null
              cat output.txt
          env:
            - name: KEYCLOAK_URL
              value: http://${sys_name}-${env}-keycloak3-svc:8080
            - name: ADMIN_USERNAME
              value: ${admin_username}
            - name: ADMIN_PASSWORD
              value: ${admin_password}
            - name: NEW_REALM
              value: ${new_realm}
            - name: CLIENT_ID_VALUE
              value: ${client_id_value}
            - name: CLIENT_ROOT_URL
              value: ${client_root_url}
            - name: USER_USERNAME
              value: ${user_username}
            - name: USER_PASSWORD
              value: ${user_password}
          volumeMounts:
            - name: init-vol
              mountPath: /init-scripts
      volumes:
        - name: init-vol
          configMap:
            name: ${sys_name}-${env}-keycloak-setting-configmap
