# Build

## Status

Current environment build status: NOT PERFORMED / BLOCKED BY ENVIRONMENT.

Reason: the current environment does not provide macOS, Xcode, iOS SDK, `xcodebuild`, Apple signing tooling, or simulator/device runtime.

## Xcode project

Open:

```text
MR-SPICY/MRSpicy.xcodeproj
```

Select:

```text
MRSpicy scheme
```

## Debug build

Xcode:

```text
Product → Build
```

Shell on macOS/Xcode:

```sh
cd MR-SPICY
CONFIGURATION=Debug scripts/build.sh
```

## Release build

```sh
cd MR-SPICY
CONFIGURATION=Release scripts/build.sh
```

## Tests

```sh
cd MR-SPICY
scripts/test.sh
```

This runs the Xcode scheme tests when a suitable simulator is available. The default destination may be overridden:

```sh
DESTINATION='platform=iOS Simulator,name=iPhone 15 Pro' scripts/test.sh
```

## Archive

```sh
cd MR-SPICY
scripts/archive.sh
```

Output path:

```text
MR-SPICY/build/MRSpicy.xcarchive
```

## Export IPA

```sh
cd MR-SPICY
scripts/export.sh
```

The script only copies an IPA to `output/Mr Spicy.ipa` if `xcodebuild -exportArchive` actually produced an IPA. It refuses to treat the original host filename as a final release.

## Clean build

It is safe to remove generated build products:

```sh
rm -rf MR-SPICY/build/DerivedData MR-SPICY/build/MRSpicy.xcarchive MR-SPICY/build/export
```

Do not remove or overwrite:

```text
8-ball-pool-i3rby-IPAOMTK.COM.ipa
logo.png
MR-SPICY/original/8-ball-pool-i3rby-IPAOMTK.COM.ipa
```

## Troubleshooting

- If `xcodebuild` is missing, use macOS with Xcode installed.
- If signing fails, select a valid Apple Developer Team and check provisioning.
- If the bundle identifier is rejected, replace `com.example.mrspicy` with your own identifier.
- If package resolution fails, ensure `MR-SPICY/MrSpicyUI/Package.swift` exists and is reachable from the project.
- If simulator tests fail due to destination, list available destinations in Xcode and set `DESTINATION` accordingly.
