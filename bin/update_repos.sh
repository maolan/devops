#!/bin/sh

export BIN_DIR=`dirname $0`
export PROJECT_ROOT=`readlink -f "${BIN_DIR}/.."`

cd "${PROJECT_ROOT}"
git pull
cd libmaolan
git pull
