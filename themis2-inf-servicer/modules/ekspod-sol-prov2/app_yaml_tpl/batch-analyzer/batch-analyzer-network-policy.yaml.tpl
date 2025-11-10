apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-batch-analyzer-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: batch-analyzer
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 443
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 3000
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
