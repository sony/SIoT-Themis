#/bin/bash
set -efu

## エラーコードの定義
readonly EX_USAGE=64
readonly EX_NOINPUT=66
readonly EX_UNAVAILABLE=69

## グローバル変数の定義
readonly patch_template_file=../templates/kubectl-patch.json.tmpl

## 動作に必要な事前確認
if [[ $(which kubectl) == "" ]] ; then
  echo コマンド kubectl が見つかりません。 >&2
  exit ${EX_UNAVAILABLE}
fi

if [[ ! -f ${patch_template_file} ]] ; then
  echo テンプレートファイル ${patch_template_file} が見つかりません。 >&2
  exit ${EX_NOINPUT}
fi

if [[ ${#} -lt 1 ]] ; then
  echo "Usage: ${0} {npm run 以降の引数}" >&2
  exit ${EX_USAGE}
fi

## 関数: ダブルクォートのエスケープ
escape_quart() {
  local convert_string=${@//\"/\\\"}
  echo ${convert_string}
}

## 関数: テンプレートファイルから引数を置き換える
replace_patch_file() {
  while read line; do
    echo -n ${line//%REPLACE_STRING%/${@}}
  done < ${patch_template_file}
}

## 関数: kubectl patch コマンドを実行する
execute_kubectl_patch() {
  kubectl patch deployment themis2-dev-batch-analyzer --patch-file <(replace_patch_file ${@})
  return ${?}
}

## 関数: メイン処理
main() {
  local arg_strings=$(escape_quart ${@})
  execute_kubectl_patch ${arg_strings}
  return ${?}
}

main ${@}
exit ${?}
