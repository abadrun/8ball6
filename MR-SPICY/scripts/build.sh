#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT="${PROJECT_DIR}/MRSpicy.xcodeproj"
SCHEME="MRSpicy"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${PROJECT_DIR}/build/DerivedData"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not available. BUILD = NOT PERFORMED / BLOCKED BY ENVIRONMENT." >&2
  exit 127
fi

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  build
