apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-fiware-orion-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
      name: fiware-orion
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: app
              name: docdb-realtime-notification-api    
        - podSelector:
            matchLabels:
              app: app
              name: eltres-agent
        - podSelector:
            matchLabels:
              app: fiware
              name: iotagent-json
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 1026
    - from:
        - podSelector:
            matchLabels:
              app: app
              name: platform-console
      ports:
        - protocol: TCP
          port: 8080

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
        - podSelector:
            matchLabels:
              app: fiware
              name: cygnus
%{ for cidr in servicer_nat_gateway_cidr_blocks ~}
        - ipBlock:
            cidr: ${cidr}
%{ endfor ~}
      ports:
        - protocol: TCP
          port: 3000
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
