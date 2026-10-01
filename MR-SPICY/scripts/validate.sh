#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PROJECT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"
python3 MR-SPICY/tools/inspect_ipa.py --root .
python3 MR-SPICY/tools/validate_mr_spicy.py

if [ -f "MR-SPICY/output/Mr Spicy.ipa" ]; then
  shasum -a 256 "MR-SPICY/output/Mr Spicy.ipa" > "MR-SPICY/output/Mr Spicy.sha256"
else
  echo "Final IPA not present. FINAL IPA = NOT PRODUCED YET."
fi
