#!/bin/sh

BIN_DIR=$(dirname ${0})
REPOS="baseview maolan engine esaxx generate mixosc plugin-protocol plugins trainer vocal widgets"

cd "${BIN_DIR}/.."
for repo in ${REPOS}; do
  git clone "https://github.com/maolan/${repo}"
done
