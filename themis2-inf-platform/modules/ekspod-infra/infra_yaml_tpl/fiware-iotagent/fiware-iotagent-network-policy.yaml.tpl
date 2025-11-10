apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-iotagent-json-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: fiware
      name: iotagent-json
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: ${eks_data_plane_subnet_cidr_blocks["subnet1"]}
        - ipBlock:
            cidr: ${eks_data_plane_subnet_cidr_blocks["subnet2"]}
      ports:
        - protocol: TCP
          port: 1883
    - from:
        - podSelector:
            matchLabels:
              app: external-kong
      ports:
        - protocol: TCP
          port: 4041
        - protocol: TCP
          port: 7896
    - from:
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 1883
        - protocol: TCP
          port: 4041
        - protocol: TCP
          port: 7896
  egress:
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
          port: 1883
        - protocol: TCP
          port: 27017
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
