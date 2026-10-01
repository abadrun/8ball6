#!/usr/bin/env python3
"""Structural validation for the MR. SPICY source layer.

This is not a substitute for Xcode compilation, iOS simulator testing, signing,
or installation. It validates source presence, localization parity, state names,
forbidden-output rules, and documentation presence in the current environment.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

REQUIRED_SWIFT_FILES = [
    "SpicyTheme.swift",
    "SpicyFeatureCircle.swift",
    "SpicyHeaderView.swift",
    "SpicyModalView.swift",
    "SpicySettingsView.swift",
    "SpicyAccountView.swift",
    "SpicyLocalization.swift",
    "SpicyOverlayViewController.swift",
]
REQUIRED_STATES = [
    "closed", "minimized", "expanded", "modal", "settings", "account", "language",
    "help", "about", "disabled", "loading", "error", "success"
]
REQUIRED_DOCS = [
    "README.md", "ARCHITECTURE.md", "INTEGRATION.md", "BUILD.md", "SIGNING.md",
    "INSTALLATION.md", "RELEASE.md", "LOCALIZATION.md", "ACCESSIBILITY.md", "CHANGELOG.md",
    "XCODE-SETUP.md"
]
FORBIDDEN_FINAL_PATHS = [
    "MR-SPICY/output/Mr Spicy.ipa",
    "output/Mr Spicy.ipa",
]

REQUIRED_XCODE_PATHS = [
    "MR-SPICY/MRSpicy.xcodeproj/project.pbxproj",
    "MR-SPICY/MRSpicy.xcodeproj/xcshareddata/xcschemes/MRSpicy.xcscheme",
    "MR-SPICY/MRSpicy/Info.plist",
    "MR-SPICY/MRSpicy/App/AppDelegate.swift",
    "MR-SPICY/MRSpicy/App/SceneDelegate.swift",
    "MR-SPICY/MRSpicy/App/MRSpicyRootViewController.swift",
    "MR-SPICY/MRSpicy/Assets.xcassets/Contents.json",
    "MR-SPICY/MRSpicy/Assets.xcassets/AppIcon.appiconset/Contents.json",
    "MR-SPICY/MrSpicyUI/Package.swift",
    "MR-SPICY/ExportOptions.plist",
    "MR-SPICY/scripts/build.sh",
    "MR-SPICY/scripts/test.sh",
    "MR-SPICY/scripts/archive.sh",
    "MR-SPICY/scripts/export.sh",
    "MR-SPICY/scripts/validate.sh",
    "MR-SPICY/Tests/MRSpicyTests.swift",
    "MR-SPICY/UITests/MRSpicyUITests.swift",
]

FORBIDDEN_MR_SPICY_LOCK_COPY = [
    "WATCH AD",
    "WATCH AD TO CONTINUE",
    "WATCH AD TO UNLOCK",
    "REWARDED AD",
    "AD COUNTDOWN",
    "PAYMENT REQUIRED",
    "SUBSCRIPTION REQUIRED",
    "LICENSE REQUIRED",
    "COUNTDOWN REQUIRED",
]


def parse_strings(path: Path) -> Dict[str, str]:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r'^\s*"(?P<key>(?:[^"\\]|\\.)+)"\s*=\s*"(?P<value>(?:[^"\\]|\\.)*)"\s*;\s*$', re.MULTILINE)
    return {m.group("key"): m.group("value") for m in pattern.finditer(text)}


def validate(root: Path) -> Tuple[List[Tuple[str, str, str]], bool]:
    rows: List[Tuple[str, str, str]] = []
    ok = True

    sources = root / "MR-SPICY" / "MrSpicyUI" / "Sources"
    for name in REQUIRED_SWIFT_FILES:
        path = sources / name
        exists = path.exists()
        rows.append((f"source {name}", "PASS" if exists else "FAIL", str(path)))
        ok = ok and exists

    overlay_text = (sources / "SpicyOverlayViewController.swift").read_text(encoding="utf-8") if (sources / "SpicyOverlayViewController.swift").exists() else ""
    for state in REQUIRED_STATES:
        present = re.search(r"case\s+" + re.escape(state) + r"\b", overlay_text) is not None
        rows.append((f"overlay state {state}", "PASS" if present else "FAIL", "SpicyOverlayState"))
        ok = ok and present

    en = parse_strings(root / "MR-SPICY" / "MrSpicyUI" / "Localization" / "en.lproj" / "Localizable.strings")
    ar = parse_strings(root / "MR-SPICY" / "MrSpicyUI" / "Localization" / "ar.lproj" / "Localizable.strings")
    parity = set(en.keys()) == set(ar.keys()) and len(en) > 0
    rows.append(("English/Arabic localization key parity", "PASS" if parity else "FAIL", f"en={len(en)} ar={len(ar)}"))
    ok = ok and parity

    localization_text = (sources / "SpicyLocalization.swift").read_text(encoding="utf-8") if (sources / "SpicyLocalization.swift").exists() else ""
    uses_rtl = ".forceRightToLeft" in localization_text and "rightToLeft" in localization_text
    rows.append(("true RTL source hooks", "PASS" if uses_rtl else "FAIL", "semanticContentAttribute + layoutDirection"))
    ok = ok and uses_rtl

    accessibility_text = "\n".join(p.read_text(encoding="utf-8") for p in sources.glob("*.swift"))
    accessibility = all(token in accessibility_text for token in ["accessibilityLabel", "accessibilityHint", "adjustsFontForContentSizeCategory", "isReduceMotionEnabled"])
    rows.append(("accessibility source hooks", "PASS" if accessibility else "FAIL", "VoiceOver + Dynamic Type + Reduce Motion"))
    ok = ok and accessibility


    for required_path in REQUIRED_XCODE_PATHS:
        path = root / required_path
        exists = path.exists() and (path.is_dir() or path.stat().st_size > 0)
        rows.append((f"xcode-ready path {required_path}", "PASS" if exists else "FAIL", str(path)))
        ok = ok and exists

    pbxproj = root / "MR-SPICY" / "MRSpicy.xcodeproj" / "project.pbxproj"
    if pbxproj.exists():
        pbx = pbxproj.read_text(encoding="utf-8")
        required_settings = [
            "PRODUCT_BUNDLE_IDENTIFIER", "PRODUCT_NAME", "MARKETING_VERSION",
            "CURRENT_PROJECT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET",
            "TARGETED_DEVICE_FAMILY", "SWIFT_VERSION", "INFOPLIST_FILE",
            "ASSETCATALOG_COMPILER_APPICON_NAME", "CODE_SIGN_STYLE", "Release", "Debug"
        ]
        has_settings = all(setting in pbx for setting in required_settings)
        rows.append(("Xcode build settings", "PASS" if has_settings else "FAIL", ", ".join(required_settings)))
        ok = ok and has_settings

    package = root / "MR-SPICY" / "MrSpicyUI" / "Package.swift"
    if package.exists():
        package_text = package.read_text(encoding="utf-8")
        package_valid_structure = all(token in package_text for token in ["products", "targets", ".iOS(.v13)", "MrSpicyUI", ".testTarget"])
        rows.append(("Swift Package structure", "PASS" if package_valid_structure else "FAIL", "products/targets/resources/platform/tests"))
        ok = ok and package_valid_structure

    for name in REQUIRED_DOCS:
        path = root / "MR-SPICY" / "documentation" / name
        exists = path.exists() and path.stat().st_size > 0
        rows.append((f"documentation {name}", "PASS" if exists else "FAIL", str(path)))
        ok = ok and exists


    source_text = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in [*sources.glob("*.swift"), *(root / "MR-SPICY" / "MrSpicyUI" / "Localization").glob("**/*.strings"), root / "MR-SPICY" / "MRSpicy" / "App" / "MRSpicyRootViewController.swift"] if p.exists())
    upper_source = source_text.upper()
    forbidden_present = [phrase for phrase in FORBIDDEN_MR_SPICY_LOCK_COPY if phrase in upper_source]
    no_locks = not forbidden_present
    rows.append(("no artificial MR. SPICY lock/ad-gate copy", "PASS" if no_locks else "FAIL", ", ".join(forbidden_present) if forbidden_present else "no forbidden lock phrases"))
    ok = ok and no_locks

    free_markers = ["featureAccessFree", "proAvailable", "noAdGating", "noArtificialLocks"]
    has_free_model = all(marker in source_text for marker in free_markers)
    rows.append(("free MR. SPICY feature model", "PASS" if has_free_model else "FAIL", ", ".join(free_markers)))
    ok = ok and has_free_model

    for forbidden in FORBIDDEN_FINAL_PATHS:
        exists = (root / forbidden).exists()
        rows.append((f"fake/final IPA absent: {forbidden}", "PASS" if not exists else "FAIL", "final IPA must only exist after real build"))
        ok = ok and not exists

    return rows, ok


def write_report(root: Path, rows: List[Tuple[str, str, str]], ok: bool) -> None:
    report = root / "MR-SPICY" / "validation" / "reports" / "structural-check-report.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# MR. SPICY Structural Check Report",
        "",
        f"Overall: {'PASS' if ok else 'FAIL'}",
        "",
        "This report verifies source structure only. It does not claim Xcode compilation, signing, installation, or runtime compatibility.",
        "",
        "| Check | Result | Evidence |",
        "|---|---|---|",
    ]
    for check, result, evidence in rows:
        lines.append(f"| {check} | {result} | {evidence} |")
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")

    json_report = root / "MR-SPICY" / "validation" / "reports" / "structural-check-report.json"
    json_report.write_text(json.dumps({"overall": "PASS" if ok else "FAIL", "rows": rows}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    root = Path.cwd()
    rows, ok = validate(root)
    write_report(root, rows, ok)
    print(f"MR. SPICY structural checks: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
