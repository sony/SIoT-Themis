apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-external-kong-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: external-kong
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
%{ for cidr in servicer_nat_gateway_cidr_blocks ~}
        - ipBlock:
            cidr: ${cidr}
%{ endfor ~}
      ports:
        - protocol: TCP
          port: 8001
        - protocol: TCP
          port: 8444
    - from:
        - ipBlock:
            cidr: ${vpc_cidr_block}
      ports:
        - protocol: TCP
          port: 3000
        - protocol: TCP
          port: 8001
        - protocol: TCP
          port: 8444
    - from:
        - podSelector:
            matchLabels:
              app: app
              name: platform-console
      ports:
        - protocol: TCP
          port: 3000
    - from:
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 3000
        - protocol: TCP
          port: 8001
        - protocol: TCP
          port: 8443
        - protocol: TCP
          port: 8444          
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: app
              name: docdb-data-controller-api
        - podSelector:
            matchLabels:
              app: app
              name: docdb-realtime-notification-api
      ports:
        - protocol: TCP
          port: 3000
    - to:
        - podSelector:
            matchLabels:
              app: fiware
              name: iotagent-json
      ports:
        - protocol: TCP
          port: 4041
        - protocol: TCP
          port: 7896
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
