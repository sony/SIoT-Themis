apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${sys_name}-${env}-grafana-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: grafana
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: app
              name: realtime-transformation-api
      ports:
        - protocol: TCP
          port: 3000
    - from:
        - ipBlock:
            cidr: ${iac_subnet_cidr_block}
      ports:
        - protocol: TCP
          port: 443
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: app
              name: data-filtering-api
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
