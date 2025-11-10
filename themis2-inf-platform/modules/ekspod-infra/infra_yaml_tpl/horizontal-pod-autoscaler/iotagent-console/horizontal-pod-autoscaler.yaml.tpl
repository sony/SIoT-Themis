apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-console
  labels:
    app.kubernetes.io/name: eltres-console
    app.kubernetes.io/managed-by: terraform
    app.kubernetes.io/component: eltres-console
    app.kubernetes.io/part-of: platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${sys_name}-${env}-eltres-console
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 90
