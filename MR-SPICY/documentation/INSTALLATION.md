# Installation

## Current installation status

Installation test: NOT PERFORMED.

No iOS simulator/device installation was attempted in the current environment. An IPA existing on disk would not, by itself, prove installation readiness.

## Installation readiness checklist for a future final IPA

A future `Mr Spicy.ipa` must be validated for:

- valid `Payload/` structure
- application bundle presence
- executable presence
- framework/dylib embedding
- nested app extensions
- Info.plist metadata
- supported architectures
- valid signatures
- valid provisioning/entitlements where applicable
- minimum iOS compatibility
- device family compatibility
- successful installation on a declared target device or simulator where permitted

## Reporting rule

If installation is not actually performed, the status must remain:

```text
INSTALLATION TEST = NOT PERFORMED
```

Do not write installation success unless there is real installation evidence.
