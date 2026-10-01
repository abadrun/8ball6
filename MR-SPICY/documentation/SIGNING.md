# Signing

## Current status

Signing was not performed in the current environment.

The Xcode project is prepared with signing placeholders only:

- `CODE_SIGN_STYLE = Automatic`
- `DEVELOPMENT_TEAM = ""`
- Placeholder bundle identifier: `com.example.mrspicy`

No Apple Team ID, certificate, private key, provisioning profile, password, token, or credential is stored in the repository.

## Legitimate signing setup

In Xcode:

1. Open `MR-SPICY/MRSpicy.xcodeproj`.
2. Select the `MRSpicy` target.
3. Open **Signing & Capabilities**.
4. Replace the placeholder bundle identifier with your own.
5. Select your Apple Developer Team.
6. Choose Automatic Signing or configure Manual Signing with your own provisioning profile.
7. Build/archive/export through Xcode.

## Manual signing placeholders

If manual signing is required, configure developer-specific values outside version control or in local Xcode settings:

- `DEVELOPMENT_TEAM`
- `CODE_SIGN_IDENTITY`
- `PROVISIONING_PROFILE_SPECIFIER`
- export `teamID` in a local ExportOptions file when needed

## Future validation

After a real export, validate:

- app signature
- embedded frameworks
- nested code
- entitlements
- provisioning
- bundle identifier
- signing team
- architectures

Do not claim signing success until those checks are actually performed in an authorized Apple environment.
