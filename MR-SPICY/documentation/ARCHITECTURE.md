# Architecture

## Identity model

```text
8-ball-pool-i3rby-IPAOMTK.COM.ipa  →  original host/base artifact
MR. SPICY                          →  customization/UI/source layer
Mr Spicy.ipa                       →  future genuine final release artifact
```

These are separate. The final IPA has not been produced yet.

## Xcode-ready structure

```text
MR-SPICY/
  MRSpicy.xcodeproj/    # Xcode project with MRSpicy app, unit tests, UI tests, shared scheme
  MRSpicy/              # standalone iOS demo shell for the MR. SPICY UI
  MrSpicyUI/            # reusable Swift Package consumed by the app target
  integration/          # source-level adapter contract and host boundary
  validation/           # factual manifests/reports
```

Open `MRSpicy.xcodeproj` in Xcode. The project depends on local package `MrSpicyUI`.

## MR. SPICY UI package

`MrSpicyUI/Sources/` contains:

- `SpicyTheme.swift` — centralized design system.
- `SpicyLocalization.swift` — English/Arabic strings and RTL semantic direction.
- `SpicyFeatureCircle.swift` — feature/category control.
- `SpicyHeaderView.swift` — logo/title/action/status header.
- `SpicyModalView.swift` — reusable modal states.
- `SpicySettingsView.swift` — settings list.
- `SpicyAccountView.swift` — truthful account/license presentation.
- `SpicyOverlayViewController.swift` — root overlay state controller.

The package has no external dependencies beyond Apple-native frameworks.

## Free feature model

MR. SPICY-owned features are modeled as free and open directly. PRO is a MR. SPICY presentation/category and is available without payment, subscription, ad unlock, license key, trial, or countdown. This free model does not bypass any host or third-party access control.

## Original host inspection

Inspection observed:

- App bundle: `Payload/pool.app/`
- Main executable: `pool`
- Bundle identifier: `com.miniclip.8ballpoolmult`
- Version/build: `56.30.0` / `5328`
- Minimum iOS: `13.0`
- Device family: iPhone and iPad
- Embedded frameworks and app extensions present

The host source project is not present. Compiled Mach-O binaries are not source.

## State model

`SpicyOverlayState` includes closed, minimized, expanded, modal, settings, account, language, help, about, disabled, loading, error, and success. The disabled state is available for legitimate external-unavailable conditions, not for artificial MR. SPICY paywalls or ad locks.

## Component classification

Generated classification is stored in:

```text
MR-SPICY/validation/reports/architecture-classification.json
```
