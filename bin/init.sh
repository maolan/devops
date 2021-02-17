#!/bin/sh

export BIN_DIR=`dirname $0`
export PROJECT_ROOT=`readlink -f "${BIN_DIR}/.."`

cd "${PROJECT_ROOT}"
git clone https://github.com/maolan/libmaolan
git clone https://github.com/maolan/maolan
git clone https://github.com/maolan/maomix
