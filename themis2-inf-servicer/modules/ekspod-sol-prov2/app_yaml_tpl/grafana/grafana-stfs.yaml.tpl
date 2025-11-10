# Grafana
apiVersion: apps/v1
kind: StatefulSet
metadata:
  namespace: default
  name: ${sys_name}-${env}-grafana
  labels:
    app: grafana
spec:
  serviceName: grafana
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        fsGroup: 472
        supplementalGroups:
          - 0
      containers:
        - name: ${sys_name}-${env}-grafana
          image: ${ecr_url}:latest
          env:
            - name: GF_SECURITY_ADMIN_USER
              value: "admin"
            - name: GF_SECURITY_ADMIN_PASSWORD
              value: "admin"
            - name: DATA_CONTROLLER_API
              value: "http://${sys_name}-${env}-data-filtering-api-svc:3000"
            - name: EDITABLE_PROVISIONED_RESOURCE
              value: "true"
          ports:
            - containerPort: 3000
          volumeMounts:
            - name: grafana-persistent-storage
              mountPath: /var/lib/grafana
  volumeClaimTemplates:
    - metadata:
        name: grafana-persistent-storage
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 30Gi
        storageClassName: "gp2"
