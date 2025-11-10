apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: default
  name: ${sys_name}-${env}-external-kong-serviceaccount
  labels:
   app: external-kong
