# Structural Test Checklist

This checklist maps to `MR-SPICY/tools/validate_mr_spicy.py` and future XCTest coverage.

- Required Swift source files exist.
- `SpicyOverlayState` declares: closed, minimized, expanded, modal, settings, account, language, help, about, disabled, loading, error, success.
- English and Arabic localization keys match.
- RTL hooks use semantic content attributes and right-to-left layout direction.
- Accessibility hooks include labels, hints, Dynamic Type, and Reduce Motion.
- No fake `Mr Spicy.ipa` exists in output.
