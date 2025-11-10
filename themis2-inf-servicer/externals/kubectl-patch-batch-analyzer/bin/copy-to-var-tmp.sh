#!/bin/bash
set -eu
readonly SCRIPT_DIR=$(cd $(dirname $0); pwd)
cp -rpv ${SCRIPT_DIR}/../ /var/tmp
exit ${?}
