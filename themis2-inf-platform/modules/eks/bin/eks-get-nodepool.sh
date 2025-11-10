#!/bin/bash
## Terraform 向け eksctl ラッパー (eksctl get nodepool)
set -euvx

## エラーコードの定義
readonly EX_NOINPUT=66
readonly EX_UNAVAILABLE=69

## 動作に必要な事前確認
### [TODO] コメントアウト部分について、eksctl update nodegroup 向けに別ファイルへ移行する
###        サンプル: eksctl get nodegroup --cluster themis2-(プロジェクト環境:prdなど)-eks-cp-(クラスター識別子:infraなど) --region ap-northeast-1
eval "$(jq -r '@sh "CLUSTER_NAME=\(.cluster_name) REGION=\(.region)"')" 

if [[ $(which eksctl) == "" ]] ; then
  echo コマンド: eksctl が見つかりません。 >&2
  exit ${EX_UNAVAILABLE}
fi

## eksctl の実行
execute_eksctl() {
  set +e
  local eksctl_output=$(eksctl get nodegroup --cluster ${CLUSTER_NAME} --region ${REGION} --output yaml 2>&1)
  local eksctl_exit=${?}
  local eksctl_output_to_json=$(echo "${eksctl_output}" | jq -R -s '.')
  set -e
  
  if [[ ${eksctl_exit} -eq 0 ]] ||
     [[ "${eksctl_output_to_json}" == "Error: No nodegroups found\n" ]] ; then
    jq -n --arg exit_code "${eksctl_exit}" --arg messages "${eksctl_output_to_json}" \
      '{"exit_code": $exit_code, "messages": $messages}'
    return 0
  else 
    jq -n --arg exit_code "${eksctl_exit}" --arg messages "${eksctl_output_to_json}" \
      '{"exit_code": $exit_code, "error": $messages}' >&2
    return ${exit_code}
  fi
}

execute_eksctl
exit ${?}
