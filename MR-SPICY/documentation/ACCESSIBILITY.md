# Accessibility

## Implemented source-level support

MR. SPICY source includes:

- VoiceOver labels and hints on primary controls.
- Button accessibility traits.
- Dynamic Type through `UIFontMetrics` and `adjustsFontForContentSizeCategory`.
- Minimum touch targets of at least 44 points for buttons.
- Semantic direction support for RTL languages.
- Reduce Motion handling through `UIAccessibility.isReduceMotionEnabled`.
- Non-color state indicators using text/status/modal state, not color alone.
- Safe-area aware header and panel layout.

## UI areas covered

- Header logo/actions/status.
- Feature circles.
- Modal actions and state text.
- Settings rows.
- Account/license truthful status cards.
- Overlay state transitions.

## Current validation level

Structural source validation has been performed. Runtime VoiceOver focus order, actual contrast measurement, device Dynamic Type snapshots, and Reduce Motion behavior require an iOS runtime and were not performed here.

## Future runtime test checklist

- VoiceOver reads header controls in logical order in English and Arabic.
- Arabic RTL focus order is natural for RTL users.
- Dynamic Type large accessibility sizes do not clip essential controls.
- Buttons remain at least 44 points.
- Reduce Motion disables substantial transition duration.
- Status is understandable without relying on color alone.
- Portrait and landscape layouts avoid safe-area collisions.
