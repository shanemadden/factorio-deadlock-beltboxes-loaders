#!/usr/bin/env bash
set -euo pipefail

MOD_NAME=$(python3 -c 'import json; print(json.load(open("info.json"))["name"])')
VERSION=$(python3 -c 'import json; print(json.load(open("info.json"))["version"])')
FOLDER_NAME="${MOD_NAME}_${VERSION}"
DIST_DIR="dist"
STAGE_ROOT="${DIST_DIR}/stage"
STAGE_MOD_DIR="${STAGE_ROOT}/${FOLDER_NAME}"
ZIP_PATH="${DIST_DIR}/${FOLDER_NAME}.zip"

rm -rf "${DIST_DIR}"
mkdir -p "${STAGE_MOD_DIR}"

rsync -a \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='dist' \
  --exclude='package.ps1' \
  --exclude='package.sh' \
  ./ "${STAGE_MOD_DIR}/"

(
  cd "${STAGE_ROOT}"
  zip -r "../${FOLDER_NAME}.zip" "${FOLDER_NAME}"
)

rm -rf "${STAGE_ROOT}"
echo "Created ${ZIP_PATH}"
