apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  namespace: default
  name: ${sys_name}-${env}-keycloak-tgb
spec:
  serviceRef:
    name: ${sys_name}-${env}-keycloak-svc
    port: 8080
  targetGroupARN: ${keycloak_tg_arn}
  targetType: ip
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: ${pub_sg}
      ports:
      - protocol: TCP
