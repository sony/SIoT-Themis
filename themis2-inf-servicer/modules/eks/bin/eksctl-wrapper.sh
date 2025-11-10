#!/bin/bash
## Terraform 向け eksctl ラッパー (eksctl create/update/scale nodegroup)
set -eu

## エラーコードの定義
readonly EX_NOINPUT=66
readonly EX_UNAVAILABLE=69

# jq で渡された引数を変数に展開
jq_output=$(jq -r '@sh "config_file_path=\(.config_file_path) cluster_name=\(.cluster_name) cluster_region=\(.cluster_region) remote_cluster_config_data=\(.remote_cluster_config_data)"')

# stderr に出力
echo "[DEBUG] jq output before eval:" >&2
echo "${jq_output}" >&2

# 変数定義を実行
eval "${jq_output}"

## 入力チェック
if [[ -z ${cluster_name} ]] || [[ -z ${cluster_region} ]]; then
  echo '{"error": "cluster_name または cluster_region が未指定です"}'
  exit ${EX_NOINPUT}
fi

if [[ ! -f ${config_file_path} ]]; then
  echo '{"error": "設定ファイル '"${config_file_path}"' が見つかりません"}'
  exit ${EX_NOINPUT}
fi

if [[ -z $(command -v eksctl) ]]; then
  echo '{"error": "eksctl コマンドが見つかりません"}'
  exit ${EX_UNAVAILABLE}
fi

## スケール構成の差異を検出
diff_scale_configuration() {
  set +e
  diff <(yq '.[] | {DesiredCapacity: .DesiredCapacity, MinxSize: .MinSize, MaxSize: .MaxSize}' \
    <(eksctl get nodegroup --cluster ${cluster_name} --region ${cluster_region} --output yaml)) \
    <(yq '.managedNodeGroups[] | {DesiredCapacity: .desiredCapacity, MinxSize: .minSize, MaxSize: .maxSize}' "${config_file_path}") &>/dev/null
  local result=${?}
  set -e
  return ${result}
}

## eksctl の実行
main() {
  case "${remote_cluster_config_data}" in
  '"[]\n"' | '"Error: No nodegroups found\n"')

    eksctl_output=$(eksctl create nodegroup --config-file "${config_file_path}" 2>&1)
    eksctl_status=${?}

    if [[ ${eksctl_status} -eq 0 ]]; then
      echo "${eksctl_output}" >&2

      if echo "${eksctl_output}" | grep -q 'created 0 managed nodegroup'; then
        echo '{"result": "eksctl: すでに存在しているためスキップ"}'
        exit 0
      fi

      node_group_name=$(yq '.managedNodeGroups[0].name' "${config_file_path}" | tr -d '"')
      if [[ -z "${node_group_name}" ]]; then
        echo '{"error": "ノードグループ名が取得できませんでした。"}'
        exit 1
      fi

      stack_name="eksctl-${cluster_name}-nodegroup-${node_group_name}"

      aws cloudformation wait stack-create-complete \
        --stack-name "${stack_name}" \
        --region "${cluster_region}"
      status=${?}

      if [[ ${status} -eq 0 ]]; then
        echo '{"result": "eksctl create 成功"}'
      else
        echo '{"error": "CloudFormationスタックの作成に失敗しました。"}'
        exit 1
      fi
    else
      echo "${eksctl_output}" >&2
      echo '{"error": "eksctl create に失敗しました"}'
      exit 1
    fi
    ;;
  *)
    if diff_scale_configuration; then
      if eksctl update nodegroup --config-file "${config_file_path}" >&2; then
        echo '{"result": "eksctl update 成功"}'
      else
        echo '{"error": "eksctl update に失敗しました"}'
        exit 1
      fi
    else
      if eksctl scale nodegroup --config-file "${config_file_path}" >&2; then
        echo '{"result": "eksctl scale 成功"}'
      else
        echo '{"error": "eksctl scale に失敗しました"}'
        exit 1
      fi
    fi
    ;;
  esac
}

main
