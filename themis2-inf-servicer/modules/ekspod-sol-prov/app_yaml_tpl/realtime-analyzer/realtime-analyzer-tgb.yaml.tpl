apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  namespace: default
  name: ${sys_name}-${env}-realtime-analyzer-tgb
spec:
  serviceRef:
    name: ${sys_name}-${env}-realtime-analyzer-svc
    port: 3000
  targetGroupARN: ${sample_analyzer_tg_arn}
  targetType: ip
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: ${pub_sg}
      ports:
      - protocol: TCP
