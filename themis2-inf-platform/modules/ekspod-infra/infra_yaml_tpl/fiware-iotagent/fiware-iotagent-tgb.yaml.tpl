apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  namespace: default
  name: ${sys_name}-${env}-iotagent-json-tgb
spec:
  serviceRef:
    name: ${sys_name}-${env}-iotagent-json-svc
    port: 4041
  targetGroupARN: ${iotagent_json_tg_arn}
  targetType: ip
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: ${pub_sg}
      ports:
      - protocol: TCP
