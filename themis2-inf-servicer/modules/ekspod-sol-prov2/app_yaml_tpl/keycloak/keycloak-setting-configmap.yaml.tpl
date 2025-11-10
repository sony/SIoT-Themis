apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: ${sys_name}-${env}-keycloak-setting-configmap
  labels:
    app: app
    name: keycloak-setting
data:
  init.sh: |
    ${init_script}
