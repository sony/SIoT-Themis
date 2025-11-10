apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-docdb-data-controller-api-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: docdb-data-controller-api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: external-kong
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to:
        - ipBlock:
            cidr: ${eks_data_plane_subnet_cidr_blocks["subnet1"]}
        - ipBlock:
            cidr: ${eks_data_plane_subnet_cidr_blocks["subnet2"]}
      ports:
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
