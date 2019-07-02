#!/bin/sh

export BIN_DIR=`dirname $0`
export PROJECT_ROOT=`readlink -f "${BIN_DIR}/.."`
. "${PROJECT_ROOT}/bin/common.sh"

cd "${PROJECT_ROOT}"
git pull
for service in $SERVICES; do
  echo "${service}"
  cd "${service}"
  git pull
  cd -
done
