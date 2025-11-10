apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  namespace: default
  name: ${sys_name}-${env}-visualize-tracker2-tgb
spec:
  serviceRef:
    name: ${sys_name}-${env}-visualize-tracker2-svc
    port: 3000
  targetGroupARN: ${sample_tracker2_tg_arn}
  targetType: ip
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: ${pub_sg}
      ports:
      - protocol: TCP
