#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_DIR
ARCHIVE_PATH="${PROJECT_DIR}/build/MRSpicy.xcarchive"
EXPORT_DIR="${PROJECT_DIR}/build/export"
OUTPUT_DIR="${PROJECT_DIR}/output"
EXPORT_OPTIONS="${PROJECT_DIR}/ExportOptions.plist"
FINAL_IPA="${OUTPUT_DIR}/Mr Spicy.ipa"
FINAL_SHA="${OUTPUT_DIR}/Mr Spicy.sha256"
ORIGINAL_IPA_NAME="8-ball-pool-i3rby-IPAOMTK.COM.ipa"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not available. IPA EXPORT = NOT PERFORMED / BLOCKED BY ENVIRONMENT." >&2
  exit 127
fi

if [ ! -d "${ARCHIVE_PATH}" ]; then
  echo "Archive not found at ${ARCHIVE_PATH}. Run scripts/archive.sh first." >&2
  exit 1
fi

rm -rf "${EXPORT_DIR}"
mkdir -p "${EXPORT_DIR}" "${OUTPUT_DIR}"

xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_DIR}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}"

GENERATED_IPA="$(find "${EXPORT_DIR}" -maxdepth 1 -type f -name '*.ipa' | head -n 1 || true)"
if [ -z "${GENERATED_IPA}" ]; then
  echo "No IPA was exported by xcodebuild." >&2
  exit 1
fi

if [ "$(basename "${GENERATED_IPA}")" = "${ORIGINAL_IPA_NAME}" ]; then
  echo "Refusing to treat the original host filename as the MR. SPICY final release." >&2
  exit 1
fi

cp "${GENERATED_IPA}" "${FINAL_IPA}"
shasum -a 256 "${FINAL_IPA}" > "${FINAL_SHA}"

python3 - <<'PY'
import json, os, pathlib, subprocess
project = pathlib.Path(os.environ.get('PROJECT_DIR', '.')).resolve()
final_ipa = project / 'output' / 'Mr Spicy.ipa'
manifest = {
    'schema': 'mr-spicy-release-manifest/v1',
    'produced': final_ipa.exists(),
    'filename': 'Mr Spicy.ipa',
    'sha256': subprocess.check_output(['shasum','-a','256',str(final_ipa)], text=True).split()[0] if final_ipa.exists() else None,
    'mr_spicy_version': '1.0.0',
    'build_configuration': 'Release',
    'signing_status': 'REQUIRES VALIDATION FROM XCODE EXPORT LOGS',
    'installation_status': 'NOT PERFORMED',
    'compatibility': 'REQUIRES DEVICE TEST',
    'validation_status': 'EXPORT COMPLETED; RUN scripts/validate.sh'
}
(project / 'output' / 'release-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
PY

echo "Exported genuine build artifact to: ${FINAL_IPA}"
