#!/bin/bash
## Terraform 向け eksctl ラッパー (eksctl delete nodepool)
set -euvx

## エラーコードの定義
readonly EX_NOINPUT=66
readonly EX_UNAVAILABLE=69

## 動作に必要な事前確認
if [[ -z ${cluster_name} ]] ||
   [[ -z ${cluster_region} ]] ||
   [[ -z ${node_group_name} ]] ; then
  cat << EOS >&2
以下の変数のいずれかが設定されていません。
- cluster_name
- cluster_region
- node_group_name
EOS
  exit ${EX_NOINPUT}
fi

if [[ -z $(command -v eksctl) ]]; then
  echo "eksctl が見つかりません。" >&2
  exit ${EX_UNAVAILABLE}
fi

## eksctl の実行
eksctl delete nodegroup \
  --cluster ${cluster_name} \
  --region ${cluster_region} \
  --name ${node_group_name} \
  --disable-eviction \
  --drain=false \
  --wait
exit ${?}
