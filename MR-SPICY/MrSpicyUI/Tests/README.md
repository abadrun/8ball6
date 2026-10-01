# MR. SPICY UI Tests

The current environment does not include Xcode or the iOS SDK, so XCTest/iOS compilation was not performed here.

Structural validation is provided by:

```sh
python3 MR-SPICY/tools/validate_mr_spicy.py
```

A future authorized Apple build environment should add and run XCTest coverage for:

- overlay state transitions
- English/Arabic localization parity
- true RTL layout snapshots
- Dynamic Type sizes
- VoiceOver labels and hints
- Reduce Motion behavior
- account/license truth-state rendering
- responsive iPhone/iPad portrait/landscape layouts
