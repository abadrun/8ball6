# Host Integration Holding Area

This directory records factual host-inspection outputs and future authorized host integration notes.

Current status:

- The original host artifact remains at repository root: `8-ball-pool-i3rby-IPAOMTK.COM.ipa`.
- `MR-SPICY/original/8-ball-pool-i3rby-IPAOMTK.COM.ipa` is a symlink/reference to that root artifact, not a final release.
- No host source project, Xcode workspace, signing identity, or provisioning profile is present in the current environment.
- No binary patching is performed here.

Future authorized integration should use the source-level adapter contract under `integration/adapters/` and must build/sign/export through Apple's normal tooling.
