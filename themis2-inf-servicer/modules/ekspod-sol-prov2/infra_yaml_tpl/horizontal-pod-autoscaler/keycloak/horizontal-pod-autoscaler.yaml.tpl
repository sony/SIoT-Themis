apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  namespace: default
  name: ${sys_name}-${env}-keycloak
  labels:
    app.kubernetes.io/name: keycloak
    app.kubernetes.io/managed-by: terraform
    app.kubernetes.io/component: authentication
    app.kubernetes.io/part-of: platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${sys_name}-${env}-keycloak
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 90
