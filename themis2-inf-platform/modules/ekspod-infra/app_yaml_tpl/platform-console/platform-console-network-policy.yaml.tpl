apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-platform-console-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: platform-console
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
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: app
              name: eltres-agent
        - podSelector:
            matchLabels:
              app: external-kong
      ports:
        - protocol: TCP
          port: 3000
    - to:
        - podSelector:
            matchLabels:
              app: keycloak
      ports:
        - protocol: TCP
          port: 8080
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
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
