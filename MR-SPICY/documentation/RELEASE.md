# Release Management

## Current release state

- Original host: PRESERVED.
- Original IPA SHA-256: VERIFIED.
- Original logo SHA-256: VERIFIED.
- MR. SPICY source layer: PRESENT.
- Xcode project: PRESENT (`MRSpicy.xcodeproj`).
- MR. SPICY free/ad-free feature model: PRESENT structurally.
- Build: NOT PERFORMED in current environment.
- Archive: NOT PERFORMED in current environment.
- Signing: NOT PERFORMED in current environment.
- IPA export: NOT PERFORMED in current environment.
- Installation test: NOT PERFORMED.
- Final IPA: `Mr Spicy.ipa` NOT PRODUCED YET.

## Release pipeline

```text
preserve original → hash → inspect → MR. SPICY source → Xcode project → build → test → archive → authorized signing/export → output/Mr Spicy.ipa → hash → validate → report
```

## Output contract

Before a genuine release exists, `MR-SPICY/output/` must not contain `Mr Spicy.ipa`.

After a genuine build/export, expected files are:

```text
MR-SPICY/output/
  Mr Spicy.ipa
  Mr Spicy.sha256
  release-manifest.json
  build-report.md
  validation-report.md
  compatibility-report.md
  installation-report.md
  changed-files-report.md
```

## Export flow

1. Open `MRSpicy.xcodeproj` in Xcode.
2. Select `MRSpicy` scheme.
3. Select developer Team and configure signing.
4. Set bundle identifier.
5. Build and run tests.
6. Product → Archive.
7. Organizer → Distribute App.
8. Export IPA.
9. Name final artifact `Mr Spicy.ipa`.
10. Place it in `MR-SPICY/output/`.
11. Run validation and hash generation.

## Non-negotiable release rules

- Never rename `8-ball-pool-i3rby-IPAOMTK.COM.ipa` to `Mr Spicy.ipa`.
- Never copy the original IPA to output as a fake release.
- Never fabricate a final SHA-256.
- Never fabricate build, archive, signing, export, installation, or compatibility results.
- Never add MR. SPICY paywalls, ad-gated features, or artificial PRO locks.
- Never bypass host/third-party DRM, licensing, payment, authorization, signing, or anti-cheat.
