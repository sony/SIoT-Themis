apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-visualize-tracker-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: visualize-tracker
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
%{ for cidr in platform_nat_gateway_cidr_blocks ~}
        - ipBlock:
            cidr: ${cidr}
%{ endfor ~}
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
