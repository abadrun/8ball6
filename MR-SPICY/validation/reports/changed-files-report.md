# Changed Files Report

## Scope

This report records intentional repository changes for MR. SPICY 1.0.0. The original root artifacts were not overwritten, renamed, or modified:

- `8-ball-pool-i3rby-IPAOMTK.COM.ipa`
- `logo.png`

No final IPA was created.

## Meaningful changes

| Area | Original state | New state | Reason | Expected effect | Ownership | Confidence | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| `original/` | Not present | Root original reference, hash, manifest | Satisfy original preservation/reference requirement without duplicating large binary | Baseline host remains independently visible | MR. SPICY preservation metadata | HIGH | SHA verified | DONE |
| `MR-SPICY/original/` | Not present | Original-host reference, SHA file, manifest | Preserve and identify baseline under project tree | Original host remains distinct from final release | MR. SPICY generated layer | HIGH | SHA verified | DONE |
| `MR-SPICY/MRSpicy.xcodeproj/` | Not present | Xcode project with app/test/UI-test targets and shared scheme | Make repo Xcode-openable | Developer can open `MRSpicy.xcodeproj` in Xcode | MR. SPICY Xcode project | MEDIUM | Structural validation passed; Xcode not available here | DONE |
| `MR-SPICY/MRSpicy/` | Not present | iOS demo app target with AppDelegate, SceneDelegate, root controller, Info.plist, localization, assets | Provide coherent app entry path | Xcode app target can host MR. SPICY UI demo | MR. SPICY app shell | MEDIUM | Structural validation passed; compile not performed | DONE |
| `MR-SPICY/MrSpicyUI/` | Not present | Canonical Swift Package with reusable UIKit source, resources, localization, tests | Reusable MR. SPICY UI layer | Package can be consumed by Xcode project/future host | MR. SPICY UI package | HIGH | Structural validation passed | DONE |
| `MR-SPICY/mr-spicy-ui` | Not present | Compatibility symlink to `MrSpicyUI` | Preserve previous lowercase path references | Existing reports/scripts can still resolve sources | MR. SPICY compatibility reference | HIGH | Symlink resolves | DONE |
| `MR-SPICY/assets/` | Not present | Logo reference and derived branding/icon areas | Keep original logo unchanged while supporting branding | Branding assets separated from original | MR. SPICY assets | HIGH | Logo hash verified | DONE |
| `MR-SPICY/integration/` | Not present | Source-level integration adapter/configuration | Define lawful host boundary | Future authorized integration has truthful adapter model | MR. SPICY integration | HIGH | File review | DONE |
| `MR-SPICY/Tests/` and `MR-SPICY/UITests/` | Not present | Unit/UI tests for free model, localization, launch, no artificial locks | Xcode test coverage preparation | Future Xcode test run can validate behavior | MR. SPICY tests | MEDIUM | Structural validation passed; Xcode test not run | DONE |
| `MR-SPICY/scripts/` | Not present | build/test/archive/export/validate scripts | Documented repeatable workflows | Future Xcode environment can build/test/archive/export | MR. SPICY tooling | HIGH | `bash -n` passed; xcodebuild unavailable | DONE |
| `MR-SPICY/ExportOptions.plist` | Not present | IPA export template | Prepare export configuration | Developer can adapt method/team/provisioning | MR. SPICY release prep | MEDIUM | Plist parsed | DONE |
| `MR-SPICY/documentation/` | Not present | Required docs including XCODE-SETUP and final report | Factual project guidance | Maintainers can continue without reconstructing | MR. SPICY documentation | HIGH | Structural validation passed | DONE |
| `MR-SPICY/validation/` | Not present | Inspection reports, manifests, matrices | Evidence-driven status tracking | Validation can be regenerated | MR. SPICY validation | HIGH | Tools executed successfully | DONE |
| `MR-SPICY/output/` | Not present | Empty local release directory | Reserved for genuine release artifacts | No fake final IPA present | MR. SPICY release management | HIGH | Final IPA absence checked | DONE |

## Files intentionally not changed

| File | Status | Evidence |
|---|---|---|
| `8-ball-pool-i3rby-IPAOMTK.COM.ipa` | UNCHANGED | SHA-256 verified as `59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8` |
| `logo.png` | UNCHANGED | SHA-256 verified as `2056971c95da6f04ddf546c8409100604302c3deb5e47a7b29418ed220d44dc9` |
| `.gitattributes` | UNCHANGED | Baseline repository configuration only |

## Release artifact status

`MR-SPICY/output/Mr Spicy.ipa` does not exist. This is intentional because no actual MR. SPICY build/archive/sign/export flow was performed in the current environment.
