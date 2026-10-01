# Xcode Setup

## Current repository entry point

Open:

```text
MR-SPICY/MRSpicy.xcodeproj
```

Select shared scheme:

```text
MRSpicy
```

The app target uses the local Swift Package:

```text
MR-SPICY/MrSpicyUI/Package.swift
```

## Requirements

A real build/archive/export requires a macOS environment with Xcode and the iOS SDK. A specific Xcode version was not verified in this environment because Xcode is unavailable here.

## Project configuration

The Xcode project includes:

- iOS app target: `MRSpicy`
- Unit test target: `MRSpicyTests`
- UI test target: `MRSpicyUITests`
- Shared scheme: `MRSpicy`
- Local Swift Package: `MrSpicyUI`
- Debug and Release configurations
- Archive action configured in the shared scheme
- Asset catalog with `AppIcon` and MR. SPICY logo assets
- App `Info.plist`
- Placeholder bundle identifier: `com.example.mrspicy`
- Automatic signing placeholder with no embedded Team ID

## Developer-specific setup

Before distribution, a developer must:

1. Open `MRSpicy.xcodeproj` in Xcode.
2. Select the `MRSpicy` target.
3. Replace `com.example.mrspicy` with their own bundle identifier.
4. Select their own Apple Developer Team.
5. Configure Automatic Signing or Manual Signing.
6. Provide any required provisioning profile/certificate through Xcode.
7. Confirm the local package `MrSpicyUI` resolves.

No Apple credentials, private keys, provisioning profiles, or Team IDs are stored in the repository.

## Build

In Xcode:

```text
Product → Build
```

or in a configured macOS shell:

```sh
cd MR-SPICY
scripts/build.sh
```

## Test

In Xcode:

```text
Product → Test
```

or:

```sh
cd MR-SPICY
scripts/test.sh
```

The default test destination in the script is a placeholder simulator destination and may need to be changed for the installed Xcode/simulator set.

## Archive

In Xcode:

```text
Product → Archive
```

or:

```sh
cd MR-SPICY
scripts/archive.sh
```

The archive path is:

```text
MR-SPICY/build/MRSpicy.xcarchive
```

## Export IPA

Use Xcode Organizer or:

```sh
cd MR-SPICY
scripts/export.sh
```

The export template is:

```text
MR-SPICY/ExportOptions.plist
```

Update `method`, signing style, Team, certificate, and provisioning choices as appropriate for the actual distribution path. Do not embed private credentials in the repository.

## Final IPA placement

Only after a genuine export, place/copy the generated artifact as:

```text
MR-SPICY/output/Mr Spicy.ipa
```

Then generate:

```text
MR-SPICY/output/Mr Spicy.sha256
MR-SPICY/output/release-manifest.json
```

## Current environment status

Xcode, `xcodebuild`, Apple signing tools, a signing identity, provisioning profiles, and an iOS installation target are not available in the current environment, so compilation/archive/export/signing/installation were not performed here.
