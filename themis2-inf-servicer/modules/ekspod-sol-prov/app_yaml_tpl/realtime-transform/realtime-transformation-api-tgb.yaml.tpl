apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  namespace: default
  name: ${sys_name}-${env}-realtime-transformation-tgb
spec:
  serviceRef:
    name: ${sys_name}-${env}-realtime-transformation-svc
    port: 3000
  targetGroupARN: ${transformation_tg_arn}
  targetType: ip
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: ${pub_sg}
      ports:
      - protocol: TCP
