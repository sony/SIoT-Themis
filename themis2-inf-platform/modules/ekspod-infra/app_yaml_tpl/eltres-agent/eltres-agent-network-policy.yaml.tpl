apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-eltres-agent-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: eltres-agent
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: app
              name: platform-console
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 3000
    - from:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 1883
  egress:
    - to:
%{ for cidr in servicer_nat_gateway_cidr_blocks ~}
        - ipBlock:
            cidr: ${cidr}
%{ endfor ~}
      ports:
        - protocol: TCP
          port: 3000
    - to:
        - podSelector:
            matchLabels:
              app: fiware
              name: orion
      ports:
        - protocol: TCP
          port: 1026
    - to:
        - ipBlock:
            cidr: ${eks_data_plane_subnet_cidr_blocks["subnet1"]}
        - ipBlock:
            cidr: ${eks_data_plane_subnet_cidr_blocks["subnet2"]}
      ports:
        - protocol: TCP
          port: 5432
        - protocol: TCP
          port: 6379
        - protocol: TCP
          port: 6380
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 6379
