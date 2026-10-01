# Integration

## Current integration status

No legitimate host integration has been performed in the current environment. The repository contains:

- The preserved original IPA.
- The MR. SPICY source layer.
- A source-level adapter contract under `MR-SPICY/integration/adapters/`.
- Configuration under `MR-SPICY/integration/configuration/`.

The repository does not contain an authorized Xcode host source project, signing identity, provisioning profile, or Apple export environment.

## Required integration approach

MR. SPICY must be integrated through legitimate source-level or approved extension points. Acceptable approaches include:

1. Adding `MR-SPICY/MrSpicyUI` as a Swift Package or source module to an authorized host project.
2. Wiring `SpicyOverlayViewController` into a sanctioned UI location in the host app.
3. Supplying truthful account/entitlement/license state through `SpicyHostIntegrationAdapter`.
4. Building and signing through Xcode/Apple tooling using authorized identities and provisioning.

## Explicitly forbidden integration approaches

Do not use:

- blind binary patching
- global string replacement
- arbitrary Mach-O editing
- executable replacement
- framework replacement without source-level ownership and signing
- entitlement spoofing
- payment/subscription/license bypass
- ad bypass
- anti-cheat evasion
- gameplay automation, aim assistance, or server-state manipulation

## MR. SPICY-owned feature access

MR. SPICY-owned UI/PRO/features are free and open directly. Integration must not add MR. SPICY payment, subscription, advertisement, license-key, trial, or countdown gates. This does not permit bypassing host or third-party systems.

## Adapter truth model

The adapter layer must report real external host state. If state is unavailable, it must say unavailable/unknown. It must not fabricate:

- account identity
- external/host PRO entitlement state
- external/host license activation
- subscription
- payment status
- server authorization
- installation success
- signing success
- compatibility success

## Current blocker summary

This environment is sufficient for inspection, source creation, localization, documentation, and structural validation. It is not sufficient for a genuine final IPA because Xcode, Apple SDK tooling, codesign/security/xcrun, signing identities, provisioning profiles, and an installation target are not available here.

This is a current environment limitation, not a declaration that a future authorized final release is impossible.
