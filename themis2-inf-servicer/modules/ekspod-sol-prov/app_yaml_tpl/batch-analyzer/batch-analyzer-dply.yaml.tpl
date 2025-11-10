apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: ${sys_name}-${env}-batch-analyzer
  labels:
    app: app
    name: batch-analyzer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
      name: batch-analyzer
  template:
    metadata:
      labels:
        app: app
        name: batch-analyzer
    spec:
      containers:
      - name: batch-analyzer
        image: ${aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${ns_sample_value}/batch-analyzer/${env}:latest
        args:
        - |
          npm run daemon -- ${batch_analyzer_key_command}
        env:
        - name: NEXT_PROCESSING_FOLDER
          value: "saves"
        - name: DATA_CONTROLLER_API_ORIGIN
          value: "https://kong.${env}.unvs-themis.com/data-controller-api"
        - name: DATA_CONTROLLER_API_KEY
          valueFrom:
            secretKeyRef:
              name: ${sys_name}-${env}-batch-analyzer-secret
              key: DATA_CONTROLLER_API_KEY
        ports:
        - containerPort: 3000
          name: bat-anl-port
          protocol: TCP
