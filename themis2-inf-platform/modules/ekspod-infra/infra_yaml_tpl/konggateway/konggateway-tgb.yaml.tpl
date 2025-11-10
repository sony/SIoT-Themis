apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  namespace: default
  name: ${sys_name}-${env}-konggateway-tgb
spec:
  serviceRef:
    name: ${sys_name}-${env}-external-kong-proxy-svc
    port: 8000
  targetGroupARN: ${external_kong_tg_arn}
  targetType: ip
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: ${pub_sg}
      ports:
      - protocol: TCP
