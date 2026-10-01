# MR. SPICY

MR. SPICY is the source-controlled customization/UI/branding layer and Xcode-ready demo/integration project for the supplied original host artifact.

## Three distinct identities

| Concept | Artifact/name | Status |
|---|---|---|
| Original host | `8-ball-pool-i3rby-IPAOMTK.COM.ipa` | Preserved baseline |
| Customization | `MR. SPICY` | Source layer + Xcode project |
| Final release | `Mr Spicy.ipa` | Not produced yet |

The original IPA is not the final release. `Mr Spicy.ipa` must only be created by a real build/archive/sign/export process.

## Verified baseline

- Original IPA SHA-256: `59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8` — VERIFIED.
- Original logo SHA-256: `2056971c95da6f04ddf546c8409100604302c3deb5e47a7b29418ed220d44dc9` — VERIFIED.
- Host bundle observed: `Payload/pool.app/`.
- Host version/build observed: `56.30.0` / `5328`.

## Xcode entry point

Open this project in Xcode:

```text
MR-SPICY/MRSpicy.xcodeproj
```

Select the shared scheme:

```text
MRSpicy
```

The reusable UI module is a local Swift Package:

```text
MR-SPICY/MrSpicyUI/Package.swift
```

The Xcode project references that local package. The legacy path `MR-SPICY/mr-spicy-ui` is a compatibility symlink to `MR-SPICY/MrSpicyUI`.

## Free MR. SPICY feature model

MR. SPICY-owned functionality is intentionally free:

- No MR. SPICY payment requirement.
- No MR. SPICY subscription requirement.
- No MR. SPICY license-key requirement.
- No MR. SPICY ad gating.
- No MR. SPICY countdown gating.
- MR. SPICY PRO is an available presentation/category in the MR. SPICY UI.

This does **not** authorize bypassing the host app's third-party DRM, signing, licensing, payments, subscriptions, server entitlements, access controls, or anti-cheat.

## Repository structure

```text
MR-SPICY/
  MRSpicy.xcodeproj/       # Xcode-openable iOS app project
  MRSpicy/                 # Demo app target: app entry point, Info.plist, assets, app localization
  MrSpicyUI/               # Reusable Swift Package with MR. SPICY UIKit UI
  Tests/                   # Xcode unit tests for app integration/free model
  UITests/                 # Xcode UI tests for launch/navigation/ad-lock absence
  original/                # Reference to preserved original host + manifest/hash
  assets/                  # Original logo reference and derived branding/icon areas
  integration/             # Source-level adapter and configuration boundaries
  versions/                # Host/MR. SPICY version and compatibility tracking
  documentation/           # Documentation including Xcode setup/build/sign/export
  scripts/                 # build/test/archive/export/validate scripts
  validation/              # Manifests and factual inspection reports
  tools/                   # Python inspection/validation tooling
  build/                   # Dedicated local build output area
  output/                  # Genuine release artifacts only; no final IPA yet
```

## Build status in this environment

This repository is prepared for Xcode, but the current environment does not include macOS/Xcode/iOS SDK/signing tools. Therefore:

- Swift/Xcode compilation: NOT PERFORMED.
- Archive: NOT PERFORMED.
- Signing: NOT PERFORMED.
- IPA export: NOT PERFORMED.
- Installation test: NOT PERFORMED.
- Final IPA: NOT PRODUCED YET.

## Commands

Structural validation available in this environment:

```sh
python3 MR-SPICY/tools/inspect_ipa.py --root .
python3 MR-SPICY/tools/validate_mr_spicy.py
```

Xcode/macOS commands for a future authorized environment:

```sh
cd MR-SPICY
scripts/build.sh
scripts/test.sh
scripts/archive.sh
scripts/export.sh
scripts/validate.sh
```

The build/archive/export scripts intentionally fail if `xcodebuild` is not available.

## Documentation

Start with:

- `documentation/XCODE-SETUP.md`
- `documentation/BUILD.md`
- `documentation/SIGNING.md`
- `documentation/RELEASE.md`
- `documentation/release/final-report.md`
