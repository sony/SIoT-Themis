apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-eltres-console-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: eltres-console
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: keycloak
      ports:
        - protocol: TCP
          port: 8080
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 3000
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
