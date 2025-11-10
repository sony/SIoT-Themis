#!/bin/bash
set -euvx

# ロードバランサーコントローラーのバージョン[helm search repo eks/aws-load-balancer-controller --versions | head]で確認する
LB_CONTROLLER_VERSION="v2.13.2"
CHART_VERSION="1.13.2"

# ロックファイルで排他制御
LOCKFILE="/tmp/lbcontroller.lock"
exec 200>$LOCKFILE
flock 200

# 本シェルはAWS公式手順を利用し、HelmにてAWS LB Controllerをインストールするシェルとなる
# https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-helm.html

## AWS LB Controller policyのダウンロード
cd /tmp
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LB_CONTROLLER_VERSION}/docs/install/iam_policy.json

## ポリシーがすでに存在するか確認
POLICY_EXISTS=$(aws iam list-policies --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].PolicyName" --output text)

## AWS LB Controller用 IAM Policy作成
if [[ "${POLICY_EXISTS}" == "AWSLoadBalancerControllerIAMPolicy" ]]; then
  echo "Policy AWSLoadBalancerControllerIAMPolicy already exists. Skipping creation."
  # ポリシーARNの取得
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" --output text)
else
  echo "Creating AWSLoadBalancerControllerIAMPolicy policy..."
  aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
  # ポリシーARNの取得
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" --output text)
fi

## AWS LB Controller用 IAM Role作成
eksctl create iamserviceaccount \
  --cluster=${cluster_name} \
  --region=${cluster_region} \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name ${cluster_name}-${cluster_region}-LBControllerRole \
  --attach-policy-arn=arn:aws:iam::${account_id}:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --override-existing-serviceaccounts

## Helmを利用してリポジトリを追加 ##helm repo remove eks
helm repo add eks https://aws.github.io/eks-charts
helm repo update

## Helmを利用してAWS LB Controllerをインストール ##helm uninstall aws-load-balancer-controller -n kube-system
## serviceAccountがない場合は--set serviceAccount.create=true
## kubectl get serviceaccount -n kube-system | grep aws-load-balancer-controller
context=$(aws eks update-kubeconfig --region ${cluster_region} --name ${cluster_name} | grep '^Updated context' | sed -E 's/^Updated context (.+) in .*/\1/')
export HELM_KUBECONTEXT="$context"
 
is_create_service_account=true
if [[ "$(kubectl get serviceaccount -n kube-system | grep -c aws-load-balancer-controller)" -eq 1 ]]; then
  is_create_service_account=false
fi
flock -u 200

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --version ${CHART_VERSION} \
  --set clusterName=${cluster_name} \
  --set serviceAccount.create=${is_create_service_account} \
  --set serviceAccount.name=aws-load-balancer-controller
  # aws-load-balancer-controllerのPodが正常になるまで待機

echo "Waiting for aws-load-balancer-controller pod to be healthy..."
for i in {1..60}; do
  STATUS=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o json | jq -r '.items[]? | select(.status.containerStatuses != null) | .status.containerStatuses[]? | select(.name=="aws-load-balancer-controller") | .ready' | grep -q false && echo "false" || echo "true")
  if [[ "$STATUS" == "true" ]]; then
    echo "aws-load-balancer-controller pod is healthy."
    break
  fi
  if [[ $i -eq 60 ]]; then
    echo "Timeout waiting for aws-load-balancer-controller pod to be healthy."
    exit 1
  fi
  echo "Waiting 10 seconds"
  sleep 10
done
