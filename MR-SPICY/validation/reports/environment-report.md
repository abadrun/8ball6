# MR. SPICY Environment Report

Captured at UTC: `2026-10-01T07:48:09+00:00`

## Tool availability

- `xcodebuild`: NOT AVAILABLE
- `codesign`: NOT AVAILABLE
- `security`: NOT AVAILABLE
- `xcrun`: NOT AVAILABLE
- `swift`: NOT AVAILABLE
- `swiftc`: NOT AVAILABLE
- `zipinfo`: AVAILABLE
- `unzip`: AVAILABLE
- `jq`: AVAILABLE
- `openssl`: AVAILABLE

## Interpretation

- Xcode, Apple SDK tooling, `codesign`, `security`, and `xcrun` are required for a real iOS archive/export/signing flow.
- If those tools are not available, build/sign/install results are recorded as not performed rather than fabricated.
