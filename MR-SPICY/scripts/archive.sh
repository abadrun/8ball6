#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT="${PROJECT_DIR}/MRSpicy.xcodeproj"
SCHEME="MRSpicy"
ARCHIVE_PATH="${PROJECT_DIR}/build/MRSpicy.xcarchive"
DERIVED_DATA="${PROJECT_DIR}/build/DerivedData"
BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-com.example.mrspicy}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not available. ARCHIVE = NOT PERFORMED / BLOCKED BY ENVIRONMENT." >&2
  exit 127
fi

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  -derivedDataPath "${DERIVED_DATA}" \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
  archive
