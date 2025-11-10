apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-console-configmap
  labels:
    app: app
    name: eltres-console
data:
  init-eltres-console.sh: |
    #!/bin/sh
    echo "NEXTAUTH_SECRET=$(openssl rand -base64 32)" > /secrettmp/secret.txt
