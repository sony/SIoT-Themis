apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  namespace: default
  name: ${sys_name}-${env}-eltres-agent
  labels:
    app.kubernetes.io/name: eltres-agent
    app.kubernetes.io/managed-by: terraform
    app.kubernetes.io/component: eltres-agent
    app.kubernetes.io/part-of: platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${sys_name}-${env}-eltres-agent
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 90
