# Localization

## Scope

MR. SPICY includes localizable user-facing text in:

- `MR-SPICY/MrSpicyUI/Sources/SpicyLocalization.swift`
- `MR-SPICY/MrSpicyUI/Localization/en.lproj/Localizable.strings`
- `MR-SPICY/MrSpicyUI/Localization/ar.lproj/Localizable.strings`

Minimum languages implemented:

- English (`en`)
- Arabic (`ar`)

## English

English strings cover titles, labels, buttons, descriptions, loading, success, error, disabled states, account/license truth-state text, and accessibility labels/hints.

## Arabic

Arabic strings are real translations for the MR. SPICY interface. They cover labels, buttons, status text, settings, account/license truth state, modals, and accessibility text.

## True RTL

Arabic is not implemented by merely right-aligning English text. The source includes:

- `SpicyLanguage.layoutDirection`
- `SpicyLanguage.semanticContentAttribute`
- `.forceRightToLeft` for Arabic
- recursive application of semantic direction to views
- leading/trailing Auto Layout anchors throughout the UI
- natural text alignment in labels

## Validation

The structural validation script checks English/Arabic localization key parity:

```sh
python3 MR-SPICY/tools/validate_mr_spicy.py
```

Runtime line wrapping, mixed text, Arabic number formatting, VoiceOver pronunciation, and modal layout should be tested on an iOS simulator/device in a future Xcode environment.
