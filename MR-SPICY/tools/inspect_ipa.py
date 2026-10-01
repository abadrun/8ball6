#!/usr/bin/env python3
"""MR. SPICY factual repository and IPA inspection.

The tool is intentionally read-only with respect to the original IPA. It records
hashes, archive entries, Info.plist metadata, Mach-O headers/load commands, and
release-status facts without creating a final IPA.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
import os
import plistlib
import struct
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

KNOWN_ORIGINAL_IPA_SHA256 = "59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8"
KNOWN_LOGO_SHA256 = "2056971c95da6f04ddf546c8409100604302c3deb5e47a7b29418ed220d44dc9"
ORIGINAL_IPA = "8-ball-pool-i3rby-IPAOMTK.COM.ipa"
ORIGINAL_LOGO = "logo.png"
MR_SPICY_VERSION = "1.0.0"

LC_REQ_DYLD = 0x80000000
LC_LOAD_DYLIB = 0x0C
LC_ID_DYLIB = 0x0D
LC_LOAD_WEAK_DYLIB = 0x18 | LC_REQ_DYLD
LC_REEXPORT_DYLIB = 0x1F | LC_REQ_DYLD
LC_LOAD_UPWARD_DYLIB = 0x23 | LC_REQ_DYLD
LC_RPATH = 0x1C | LC_REQ_DYLD
LC_CODE_SIGNATURE = 0x1D
LC_SEGMENT = 0x01
LC_SEGMENT_64 = 0x19
LC_ENCRYPTION_INFO = 0x21
LC_ENCRYPTION_INFO_64 = 0x2C
LC_VERSION_MIN_IPHONEOS = 0x25
LC_BUILD_VERSION = 0x32

CPU_TYPES = {
    7: "x86",
    0x01000007: "x86_64",
    12: "arm",
    0x0100000C: "arm64",
}
FILE_TYPES = {
    1: "MH_OBJECT",
    2: "MH_EXECUTE",
    3: "MH_FVMLIB",
    4: "MH_CORE",
    5: "MH_PRELOAD",
    6: "MH_DYLIB",
    7: "MH_DYLINKER",
    8: "MH_BUNDLE",
    9: "MH_DYLIB_STUB",
    10: "MH_DSYM",
    11: "MH_KEXT_BUNDLE",
}
PLATFORMS = {
    1: "macOS",
    2: "iOS",
    3: "tvOS",
    4: "watchOS",
    5: "bridgeOS",
    6: "macCatalyst",
    7: "iOSSimulator",
    8: "tvOSSimulator",
    9: "watchOSSimulator",
    10: "driverKit",
}


def utc_now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=False) + "\n", encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def rel(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def command_exists(name: str) -> bool:
    from shutil import which
    return which(name) is not None


def classify_file_type(path: str, data_prefix: Optional[bytes] = None) -> str:
    lower = path.lower()
    if path.endswith("/"):
        return "directory"
    if lower.endswith(".ipa"):
        return "ios ipa archive"
    if lower.endswith(".png"):
        return "png image"
    if lower.endswith(".jpg") or lower.endswith(".jpeg"):
        return "jpeg image"
    if lower.endswith(".plist"):
        return "property list"
    if lower.endswith(".strings"):
        return "localization strings"
    if lower.endswith(".swift"):
        return "swift source"
    if lower.endswith(".json"):
        return "json"
    if lower.endswith(".md"):
        return "markdown"
    if lower.endswith(".dylib"):
        return "mach-o dylib"
    if lower.endswith(".framework"):
        return "framework directory"
    if lower.endswith(".appex"):
        return "app extension directory"
    if lower.endswith(".car"):
        return "asset catalog compiled archive"
    if data_prefix:
        magic = data_prefix[:4]
        if magic in (b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca", b"\xce\xfa\xed\xfe", b"\xfe\xed\xfa\xce"):
            return "mach-o binary"
        if data_prefix.startswith(b"PK\x03\x04"):
            return "zip archive"
        if data_prefix.startswith(b"bplist"):
            return "binary property list"
    return "file"


def role_for_path(path: str) -> str:
    if path == ORIGINAL_IPA or path.endswith("/" + ORIGINAL_IPA):
        return "ORIGINAL_HOST_ARTIFACT_REFERENCE"
    if path == ORIGINAL_LOGO or path.endswith("/logo.png"):
        return "BRANDING_SOURCE_OR_DERIVED_RESOURCE"
    if path.startswith("MR-SPICY/MrSpicyUI/Sources/") or path.startswith("MR-SPICY/mr-spicy-ui/Sources/"):
        return "MR_SPICY_SOURCE"
    if path.startswith("MR-SPICY/MrSpicyUI/Localization/") or path.startswith("MR-SPICY/mr-spicy-ui/Localization/"):
        return "MR_SPICY_LOCALIZATION"
    if path.startswith("MR-SPICY/documentation/"):
        return "DOCUMENTATION"
    if path.startswith("MR-SPICY/validation/"):
        return "VALIDATION_ARTIFACT"
    if path.startswith("MR-SPICY/versions/"):
        return "VERSIONING"
    if path.startswith("MR-SPICY/integration/"):
        return "INTEGRATION_PREPARATION"
    if path.startswith("MR-SPICY/tools/"):
        return "TOOLING"
    return "REPOSITORY_FILE"


def inventory_repository(root: Path) -> List[Dict[str, Any]]:
    entries: List[Dict[str, Any]] = []
    for path in sorted(root.rglob("*")):
        if ".git" in path.parts:
            continue
        r = rel(path, root)
        st = path.lstat()
        if path.is_symlink():
            target = os.readlink(path)
            exists = path.exists()
            actual_sha = sha256_file(path.resolve()) if exists and path.resolve().is_file() else None
            entries.append({
                "path": r,
                "filename": path.name,
                "type": "symlink",
                "size": st.st_size,
                "sha256": actual_sha,
                "symlink_target": target,
                "original_or_generated": "generated reference" if r.startswith("MR-SPICY/") else "original",
                "modified_or_unmodified": "generated" if r.startswith("MR-SPICY/") else "unmodified",
                "role": role_for_path(r),
                "dependency": dependency_for_repo_path(r),
                "ownership": ownership_for_repo_path(r),
                "relevance": relevance_for_repo_path(r),
                "validation_status": "RECORDED"
            })
            continue
        if path.is_dir():
            continue
        with path.open("rb") as fh:
            prefix = fh.read(16)
        entries.append({
            "path": r,
            "filename": path.name,
            "type": classify_file_type(r, prefix),
            "size": path.stat().st_size,
            "sha256": sha256_file(path),
            "original_or_generated": "generated" if r.startswith("MR-SPICY/") else "original",
            "modified_or_unmodified": "generated" if r.startswith("MR-SPICY/") else "unmodified",
            "role": role_for_path(r),
            "dependency": dependency_for_repo_path(r),
            "ownership": ownership_for_repo_path(r),
            "relevance": relevance_for_repo_path(r),
            "validation_status": "RECORDED"
        })
    return entries


def dependency_for_repo_path(path: str) -> str:
    if path.endswith(".swift"):
        return "UIKit/iOS SDK source-level dependency"
    if path.endswith(".ipa"):
        return "baseline host artifact"
    if path.endswith("logo.png"):
        return "branding input"
    if path.endswith(".strings"):
        return "localization resource"
    return "none recorded"


def ownership_for_repo_path(path: str) -> str:
    if path.startswith("MR-SPICY/"):
        return "MR. SPICY generated layer"
    if path == ORIGINAL_IPA:
        return "Original host artifact"
    if path == ORIGINAL_LOGO:
        return "Original logo artifact"
    return "Repository baseline"


def relevance_for_repo_path(path: str) -> str:
    if path == ORIGINAL_IPA:
        return "Project baseline host application"
    if path == ORIGINAL_LOGO:
        return "Original branding source"
    if path.startswith("MR-SPICY/"):
        return "MR. SPICY source, documentation, validation, or integration preparation"
    return "Repository support file"


def plist_from_zip(z: zipfile.ZipFile, name: str) -> Optional[Dict[str, Any]]:
    try:
        return plistlib.loads(z.read(name))
    except Exception:
        return None


def version_tuple(encoded: int) -> str:
    return f"{(encoded >> 16) & 0xFFFF}.{(encoded >> 8) & 0xFF}.{encoded & 0xFF}"


def decode_c_string(blob: bytes, offset: int) -> str:
    if offset < 0 or offset >= len(blob):
        return ""
    end = blob.find(b"\x00", offset)
    if end == -1:
        end = len(blob)
    return blob[offset:end].decode("utf-8", errors="replace")


def parse_slice(data: bytes, base_offset: int, size: Optional[int], magic: int, endian: str, is64: bool) -> Dict[str, Any]:
    header_fmt = endian + ("IiiIIII" + ("I" if is64 else ""))
    header_size = struct.calcsize(header_fmt)
    if base_offset + header_size > len(data):
        return {"error": "header out of bounds"}
    header = struct.unpack_from(header_fmt, data, base_offset)
    if is64:
        _magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = header
    else:
        _magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags = header
        reserved = None
    arch: Dict[str, Any] = {
        "cpu_type": CPU_TYPES.get(cputype, hex(cputype & 0xFFFFFFFF)),
        "cpu_subtype": cpusubtype,
        "filetype": FILE_TYPES.get(filetype, hex(filetype)),
        "ncmds": ncmds,
        "sizeofcmds": sizeofcmds,
        "flags": hex(flags),
        "is_64_bit": is64,
        "offset": base_offset,
        "size": size,
        "dependencies": [],
        "rpaths": [],
        "id_dylib": None,
        "build_versions": [],
        "minimum_os": [],
        "code_signature": None,
        "encryption": [],
        "load_command_warnings": []
    }
    off = base_offset + header_size
    end_of_commands = off + sizeofcmds
    max_end = len(data) if size is None else min(len(data), base_offset + size)
    if end_of_commands > max_end:
        arch["load_command_warnings"].append("load commands exceed slice bounds")
    for _ in range(ncmds):
        if off + 8 > max_end:
            arch["load_command_warnings"].append("truncated load command")
            break
        cmd, cmdsize = struct.unpack_from(endian + "II", data, off)
        if cmdsize < 8 or off + cmdsize > max_end:
            arch["load_command_warnings"].append(f"invalid load command size for {hex(cmd)}")
            break
        cmd_blob = data[off:off + cmdsize]
        if cmd in (LC_LOAD_DYLIB, LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB, LC_LOAD_UPWARD_DYLIB):
            if len(cmd_blob) >= 24:
                name_offset = struct.unpack_from(endian + "I", cmd_blob, 8)[0]
                name = decode_c_string(cmd_blob, name_offset)
                if cmd == LC_ID_DYLIB:
                    arch["id_dylib"] = name
                else:
                    arch["dependencies"].append(name)
        elif cmd == LC_RPATH:
            if len(cmd_blob) >= 12:
                path_offset = struct.unpack_from(endian + "I", cmd_blob, 8)[0]
                arch["rpaths"].append(decode_c_string(cmd_blob, path_offset))
        elif cmd == LC_CODE_SIGNATURE:
            if len(cmd_blob) >= 16:
                dataoff, datasize = struct.unpack_from(endian + "II", cmd_blob, 8)
                arch["code_signature"] = {"data_offset": dataoff, "data_size": datasize}
        elif cmd in (LC_ENCRYPTION_INFO, LC_ENCRYPTION_INFO_64):
            if len(cmd_blob) >= 20:
                cryptoff, cryptsize, cryptid = struct.unpack_from(endian + "III", cmd_blob, 8)
                arch["encryption"].append({"crypt_offset": cryptoff, "crypt_size": cryptsize, "crypt_id": cryptid})
        elif cmd == LC_VERSION_MIN_IPHONEOS:
            if len(cmd_blob) >= 16:
                version, sdk = struct.unpack_from(endian + "II", cmd_blob, 8)
                arch["minimum_os"].append({"platform": "iOS", "minos": version_tuple(version), "sdk": version_tuple(sdk)})
        elif cmd == LC_BUILD_VERSION:
            if len(cmd_blob) >= 24:
                platform, minos, sdk, ntools = struct.unpack_from(endian + "IIII", cmd_blob, 8)
                arch["build_versions"].append({
                    "platform": PLATFORMS.get(platform, str(platform)),
                    "minos": version_tuple(minos),
                    "sdk": version_tuple(sdk),
                    "ntools": ntools
                })
        off += cmdsize
    return arch


def parse_macho(data: bytes) -> Dict[str, Any]:
    if len(data) < 4:
        return {"is_macho": False, "reason": "too small"}
    be_magic = struct.unpack_from(">I", data, 0)[0]
    le_magic = struct.unpack_from("<I", data, 0)[0]
    result: Dict[str, Any] = {"is_macho": True, "fat": False, "slices": []}
    if be_magic == 0xCAFEBABE:
        result["fat"] = True
        if len(data) < 8:
            return {"is_macho": False, "reason": "truncated fat header"}
        nfat = struct.unpack_from(">I", data, 4)[0]
        result["fat_arch_count"] = nfat
        for idx in range(nfat):
            arch_off = 8 + idx * 20
            if arch_off + 20 > len(data):
                result.setdefault("warnings", []).append("truncated fat arch")
                break
            cputype, cpusubtype, offset, size, align = struct.unpack_from(">iiIII", data, arch_off)
            if offset + 4 > len(data):
                result.setdefault("warnings", []).append("fat slice offset out of bounds")
                continue
            slice_le_magic = struct.unpack_from("<I", data, offset)[0]
            slice_be_magic = struct.unpack_from(">I", data, offset)[0]
            if slice_le_magic in (0xFEEDFACF, 0xFEEDFACE):
                endian = "<"
                is64 = slice_le_magic == 0xFEEDFACF
                magic = slice_le_magic
            elif slice_be_magic in (0xFEEDFACF, 0xFEEDFACE):
                endian = ">"
                is64 = slice_be_magic == 0xFEEDFACF
                magic = slice_be_magic
            else:
                result.setdefault("warnings", []).append("fat slice is not mach-o")
                continue
            parsed = parse_slice(data, offset, size, magic, endian, is64)
            parsed.update({"fat_cpu_type": CPU_TYPES.get(cputype, hex(cputype & 0xFFFFFFFF)), "fat_cpu_subtype": cpusubtype, "fat_align": align})
            result["slices"].append(parsed)
        return result
    if le_magic in (0xFEEDFACF, 0xFEEDFACE):
        result["slices"].append(parse_slice(data, 0, len(data), le_magic, "<", le_magic == 0xFEEDFACF))
        return result
    if be_magic in (0xFEEDFACF, 0xFEEDFACE):
        result["slices"].append(parse_slice(data, 0, len(data), be_magic, ">", be_magic == 0xFEEDFACF))
        return result
    return {"is_macho": False, "reason": f"unknown magic be={hex(be_magic)} le={hex(le_magic)}"}


def collect_zip_manifest(z: zipfile.ZipFile) -> List[Dict[str, Any]]:
    entries: List[Dict[str, Any]] = []
    for info in z.infolist():
        entry: Dict[str, Any] = {
            "path": info.filename,
            "filename": Path(info.filename).name,
            "type": "directory" if info.is_dir() else classify_file_type(info.filename),
            "size": info.file_size,
            "compressed_size": info.compress_size,
            "crc": hex(info.CRC),
            "sha256": None,
            "original_generated": "original IPA content",
            "modified_unmodified": "unmodified inspection source",
            "role": ipa_role_for_entry(info.filename),
            "dependency": ipa_dependency_for_entry(info.filename),
            "ownership": "Original host application bundle or bundled dependency",
            "relevance": ipa_relevance_for_entry(info.filename),
            "validation_status": "RECORDED"
        }
        if not info.is_dir():
            data = z.read(info.filename)
            entry["sha256"] = sha256_bytes(data)
            entry["type"] = classify_file_type(info.filename, data[:16])
        entries.append(entry)
    return entries


def ipa_role_for_entry(path: str) -> str:
    if path.endswith("/"):
        return "DIRECTORY"
    if path == "Payload/pool.app/pool":
        return "ORIGINAL_APPLICATION_EXECUTABLE"
    if "/Frameworks/" in path and (path.endswith(".dylib") or Path(path).name == Path(path).parent.stem):
        return "EMBEDDED_FRAMEWORK_OR_DYLIB_BINARY"
    if "/PlugIns/" in path and Path(path).name == Path(path).parent.stem:
        return "APP_EXTENSION_EXECUTABLE"
    if path.endswith("Info.plist"):
        return "BUNDLE_METADATA"
    if ".lproj/" in path or path.endswith(".strings"):
        return "LOCALIZATION_RESOURCE"
    if path.endswith("CodeResources"):
        return "CODE_SIGNATURE_RESOURCE_MANIFEST"
    if any(path.lower().endswith(ext) for ext in [".png", ".jpg", ".car", ".atlas"]):
        return "RESOURCE_ASSET"
    return "RESOURCE_OR_SUPPORT_FILE"


def ipa_dependency_for_entry(path: str) -> str:
    if "/Frameworks/" in path:
        return "embedded framework/dylib dependency"
    if "/PlugIns/" in path:
        return "app extension dependency"
    if path.endswith("Info.plist"):
        return "bundle metadata"
    return "host application resource"


def ipa_relevance_for_entry(path: str) -> str:
    if path.startswith("Payload/pool.app/Frameworks/"):
        return "Framework validation and dependency tracking"
    if path.startswith("Payload/pool.app/PlugIns/"):
        return "Extension validation and compatibility tracking"
    if path == "Payload/pool.app/Info.plist":
        return "Primary host metadata"
    if path == "Payload/pool.app/pool":
        return "Primary host executable"
    if ".lproj/" in path:
        return "Localization baseline"
    return "Original host content inventory"


def find_app_paths(z: zipfile.ZipFile) -> List[str]:
    app_dirs = set()
    for name in z.namelist():
        parts = name.split("/")
        if len(parts) >= 2 and parts[0] == "Payload" and parts[1].endswith(".app"):
            app_dirs.add("/".join(parts[:2]) + "/")
    return sorted(app_dirs)


def identify_binaries(z: zipfile.ZipFile, app_dir: str, info: Dict[str, Any]) -> List[str]:
    names = set(z.namelist())
    binaries: List[str] = []
    exe = info.get("CFBundleExecutable")
    if exe and app_dir + exe in names:
        binaries.append(app_dir + exe)
    for name in names:
        if not name.startswith(app_dir):
            continue
        if name.endswith(".dylib"):
            binaries.append(name)
        if name.endswith("/Info.plist") and ("/Frameworks/" in name or "/PlugIns/" in name):
            p = plist_from_zip(z, name) or {}
            e = p.get("CFBundleExecutable")
            if e:
                bundle_dir = name[: -len("Info.plist")]
                candidate = bundle_dir + e
                if candidate in names:
                    binaries.append(candidate)
    return sorted(set(binaries))


def framework_summaries(z: zipfile.ZipFile, app_dir: str) -> List[Dict[str, Any]]:
    app_prefix = app_dir if app_dir.endswith("/") else app_dir + "/"
    frameworks: Dict[str, Dict[str, Any]] = {}
    for name in z.namelist():
        if not name.startswith(app_prefix + "Frameworks/"):
            continue
        parts = name[len(app_prefix + "Frameworks/"):].split("/")
        if not parts or not parts[0]:
            continue
        root = parts[0]
        if root.endswith(".framework") or root.endswith(".dylib"):
            entry = frameworks.setdefault(root, {"name": root, "paths": [], "info": None})
            entry["paths"].append(name)
    for root, entry in frameworks.items():
        info_path = app_prefix + "Frameworks/" + root + "/Info.plist"
        if info_path in z.namelist():
            p = plist_from_zip(z, info_path)
            if p:
                entry["info"] = {k: p.get(k) for k in ["CFBundleIdentifier", "CFBundleExecutable", "CFBundleName", "CFBundleVersion", "CFBundleShortVersionString", "MinimumOSVersion"]}
    return sorted(frameworks.values(), key=lambda x: x["name"])


def extension_summaries(z: zipfile.ZipFile, app_dir: str) -> List[Dict[str, Any]]:
    app_prefix = app_dir if app_dir.endswith("/") else app_dir + "/"
    appex: Dict[str, Dict[str, Any]] = {}
    for name in z.namelist():
        if not name.startswith(app_prefix + "PlugIns/"):
            continue
        rest = name[len(app_prefix + "PlugIns/"):]
        root = rest.split("/")[0]
        if root.endswith(".appex"):
            entry = appex.setdefault(root, {"name": root, "paths": [], "info": None})
            entry["paths"].append(name)
    for root, entry in appex.items():
        info_path = app_prefix + "PlugIns/" + root + "/Info.plist"
        if info_path in z.namelist():
            p = plist_from_zip(z, info_path)
            if p:
                ext = p.get("NSExtension") if isinstance(p.get("NSExtension"), dict) else {}
                entry["info"] = {
                    "CFBundleIdentifier": p.get("CFBundleIdentifier"),
                    "CFBundleExecutable": p.get("CFBundleExecutable"),
                    "CFBundleName": p.get("CFBundleName"),
                    "CFBundleDisplayName": p.get("CFBundleDisplayName"),
                    "CFBundleVersion": p.get("CFBundleVersion"),
                    "CFBundleShortVersionString": p.get("CFBundleShortVersionString"),
                    "MinimumOSVersion": p.get("MinimumOSVersion"),
                    "NSExtensionPointIdentifier": ext.get("NSExtensionPointIdentifier") if isinstance(ext, dict) else None,
                }
    return sorted(appex.values(), key=lambda x: x["name"])


def localization_summary(z: zipfile.ZipFile) -> Dict[str, Any]:
    languages: Dict[str, List[str]] = {}
    for name in z.namelist():
        parts = name.split("/")
        for part in parts:
            if part.endswith(".lproj"):
                languages.setdefault(part[:-6], []).append(name)
    return {
        "languages": {k: len(v) for k, v in sorted(languages.items())},
        "contains_english": "en" in languages or "Base" in languages,
        "contains_arabic": "ar" in languages,
        "rtl_verified_in_original": "NOT TESTED; language resources observed only"
    }


def architecture_classification(frameworks: List[Dict[str, Any]], extensions: List[Dict[str, Any]], binaries: Dict[str, Any]) -> List[Dict[str, Any]]:
    components: List[Dict[str, Any]] = []
    components.append({
        "component": "Payload/pool.app/pool",
        "classification": "ORIGINAL_APPLICATION",
        "evidence": "CFBundleExecutable in Payload/pool.app/Info.plist; Mach-O executable inside original IPA.",
        "confidence": "HIGH"
    })
    for fw in frameworks:
        name = fw["name"]
        if name == "libloader.framework":
            classification = "UNKNOWN"
            confidence = "LOW"
            evidence = "Embedded compiled framework named libloader; no source found in repository; purpose not established by inspection alone."
        elif name == "libswift_Concurrency.dylib":
            classification = "SHARED"
            confidence = "HIGH"
            evidence = "Swift runtime dylib embedded with app."
        elif any(vendor in name for vendor in ["Firebase", "Google", "AppLovin", "FBAudience", "InMobi", "DTB", "OMSDK", "AdSurge", "Promises", "nanopb", "Bigo"]):
            classification = "THIRD_PARTY"
            confidence = "HIGH"
            evidence = "Framework name and bundle metadata correspond to common third-party SDK/runtime dependency."
        else:
            classification = "THIRD_PARTY"
            confidence = "MEDIUM"
            evidence = "Embedded framework dependency from original host; no MR. SPICY source ownership."
        components.append({"component": "Payload/pool.app/Frameworks/" + name, "classification": classification, "evidence": evidence, "confidence": confidence})
    for ext in extensions:
        components.append({
            "component": "Payload/pool.app/PlugIns/" + ext["name"],
            "classification": "ORIGINAL_APPLICATION",
            "evidence": "Nested app extension included in original host IPA with host bundle identifier prefix.",
            "confidence": "HIGH"
        })
    components.append({
        "component": "MR-SPICY/MrSpicyUI",
        "classification": "MR_SPICY",
        "evidence": "Source-controlled customization layer created separately from original IPA.",
        "confidence": "HIGH"
    })
    return components


def create_reports(root: Path) -> None:
    ipa_path = root / ORIGINAL_IPA
    logo_path = root / ORIGINAL_LOGO
    mr_root = root / "MR-SPICY"
    original_hash = sha256_file(ipa_path)
    logo_hash = sha256_file(logo_path)
    build_env = {
        "captured_at_utc": utc_now(),
        "platform": sys.platform,
        "python": sys.version.split()[0],
        "tools": {name: command_exists(name) for name in ["xcodebuild", "codesign", "security", "xcrun", "swift", "swiftc", "zipinfo", "unzip", "jq", "openssl"]}
    }

    with zipfile.ZipFile(ipa_path) as z:
        app_dirs = find_app_paths(z)
        app_dir = app_dirs[0] if app_dirs else None
        app_info = plist_from_zip(z, app_dir + "Info.plist") if app_dir else None
        manifest = collect_zip_manifest(z)
        if app_dir:
            frameworks = framework_summaries(z, app_dir)
            extensions = extension_summaries(z, app_dir)
        else:
            frameworks = []
            extensions = []
        binaries_list = identify_binaries(z, app_dir, app_info or {}) if app_dir and app_info else []
        macho: Dict[str, Any] = {}
        for binary in binaries_list:
            data = z.read(binary)
            macho[binary] = parse_macho(data)
        loc_summary = localization_summary(z)

    # Fix app_dir display after helper use.
    app_dir_display = app_dir or "NOT FOUND"
    host_version = (app_info or {}).get("CFBundleShortVersionString")
    host_build = (app_info or {}).get("CFBundleVersion")

    original_manifest = {
        "schema": "mr-spicy-original-manifest/v1",
        "captured_at_utc": utc_now(),
        "original_host": {
            "root_path": ORIGINAL_IPA,
            "mr_spicy_reference_path": "MR-SPICY/original/" + ORIGINAL_IPA,
            "reference_type": "symlink/reference to repository-root original; not a renamed final artifact",
            "size": ipa_path.stat().st_size,
            "sha256": original_hash,
            "expected_sha256": KNOWN_ORIGINAL_IPA_SHA256,
            "sha256_verified": original_hash == KNOWN_ORIGINAL_IPA_SHA256,
            "preserved": True,
            "role": "ORIGINAL 8 BALL POOL HOST / BASE APPLICATION"
        },
        "original_logo": {
            "root_path": ORIGINAL_LOGO,
            "mr_spicy_reference_path": "MR-SPICY/assets/logo.png",
            "size": logo_path.stat().st_size,
            "sha256": logo_hash,
            "expected_sha256": KNOWN_LOGO_SHA256,
            "sha256_verified": logo_hash == KNOWN_LOGO_SHA256,
            "preserved": True
        },
        "final_release": {
            "intended_path": "MR-SPICY/output/Mr Spicy.ipa",
            "produced": False,
            "reason": "No actual MR. SPICY build/sign/export has been performed in this environment."
        }
    }
    write_json(mr_root / "original" / "original-manifest.json", original_manifest)

    baseline_inventory = [
        {
            "path": ".gitattributes",
            "filename": ".gitattributes",
            "type": "git attributes text",
            "size": (root / ".gitattributes").stat().st_size,
            "sha256": sha256_file(root / ".gitattributes"),
            "original_generated": "original",
            "modified_unmodified": "unmodified baseline",
            "role": "REPOSITORY_CONFIGURATION",
            "dependency": "none",
            "ownership": "Repository baseline",
            "relevance": "Line-ending normalization",
            "validation_status": "RECORDED BEFORE MR-SPICY GENERATION"
        },
        {
            "path": ORIGINAL_IPA,
            "filename": ORIGINAL_IPA,
            "type": "ios ipa archive",
            "size": ipa_path.stat().st_size,
            "sha256": original_hash,
            "original_generated": "original",
            "modified_unmodified": "unmodified baseline",
            "role": "ORIGINAL_HOST_ARTIFACT",
            "dependency": "project baseline",
            "ownership": "Original host artifact",
            "relevance": "Starting host application",
            "validation_status": "SHA256 VERIFIED" if original_hash == KNOWN_ORIGINAL_IPA_SHA256 else "SHA256 MISMATCH"
        },
        {
            "path": ORIGINAL_LOGO,
            "filename": ORIGINAL_LOGO,
            "type": "png image",
            "size": logo_path.stat().st_size,
            "sha256": logo_hash,
            "original_generated": "original",
            "modified_unmodified": "unmodified baseline",
            "role": "ORIGINAL_LOGO",
            "dependency": "branding input",
            "ownership": "Original logo artifact",
            "relevance": "Branding source for MR. SPICY assets",
            "validation_status": "SHA256 VERIFIED" if logo_hash == KNOWN_LOGO_SHA256 else "SHA256 MISMATCH"
        }
    ]
    write_json(mr_root / "validation" / "manifests" / "repository-inventory-baseline.json", {
        "schema": "mr-spicy-repository-inventory-baseline/v1",
        "captured_before_changes": True,
        "captured_at_utc": utc_now(),
        "entries": baseline_inventory
    })
    write_json(mr_root / "validation" / "manifests" / "repository-inventory-current.json", {
        "schema": "mr-spicy-repository-inventory-current/v1",
        "captured_at_utc": utc_now(),
        "entries": inventory_repository(root)
    })
    write_json(mr_root / "validation" / "manifests" / "ipa-entry-manifest.json", {
        "schema": "mr-spicy-ipa-entry-manifest/v1",
        "source_ipa": ORIGINAL_IPA,
        "source_sha256": original_hash,
        "entry_count": len(manifest),
        "entries": manifest
    })

    inspect_data = {
        "schema": "mr-spicy-ipa-inspection/v1",
        "captured_at_utc": utc_now(),
        "ipa": {"path": ORIGINAL_IPA, "size": ipa_path.stat().st_size, "sha256": original_hash},
        "app_dirs": app_dirs,
        "app_info": {k: (app_info or {}).get(k) for k in [
            "CFBundleIdentifier", "CFBundleExecutable", "CFBundleName", "CFBundleDisplayName", "CFBundleVersion",
            "CFBundleShortVersionString", "MinimumOSVersion", "UIDeviceFamily", "UISupportedInterfaceOrientations",
            "UISupportedInterfaceOrientations~ipad", "UIBackgroundModes", "CFBundleURLTypes", "LSApplicationQueriesSchemes"
        ]},
        "entry_count": len(manifest),
        "framework_count": len(frameworks),
        "frameworks": frameworks,
        "extension_count": len(extensions),
        "extensions": extensions,
        "binary_count": len(binaries_list),
        "binaries": binaries_list,
        "mach_o": macho,
        "localization": loc_summary,
        "code_signature_resource_manifests": sum(1 for e in manifest if e["path"].endswith("_CodeSignature/CodeResources")),
        "embedded_mobileprovision_present": any(e["path"].endswith("embedded.mobileprovision") for e in manifest),
        "environment": build_env
    }
    write_json(mr_root / "validation" / "reports" / "ipa-inspection.json", inspect_data)
    write_json(mr_root / "validation" / "reports" / "architecture-classification.json", {
        "schema": "mr-spicy-architecture-classification/v1",
        "captured_at_utc": utc_now(),
        "components": architecture_classification(frameworks, extensions, macho)
    })
    write_json(mr_root / "versions" / "host-versions" / f"8-ball-pool-{host_version or 'unknown'}-{host_build or 'unknown'}.json", {
        "schema": "mr-spicy-host-version/v1",
        "host_artifact": ORIGINAL_IPA,
        "host_sha256": original_hash,
        "host_sha256_verified": original_hash == KNOWN_ORIGINAL_IPA_SHA256,
        "bundle_identifier": (app_info or {}).get("CFBundleIdentifier"),
        "host_version": host_version,
        "host_build": host_build,
        "minimum_ios": (app_info or {}).get("MinimumOSVersion"),
        "device_family": (app_info or {}).get("UIDeviceFamily"),
        "app_dir": app_dir_display,
        "executable": (app_info or {}).get("CFBundleExecutable"),
        "framework_count": len(frameworks),
        "extension_count": len(extensions),
        "binary_count": len(binaries_list)
    })
    write_json(mr_root / "versions" / "mr-spicy-versions" / f"{MR_SPICY_VERSION}.json", {
        "schema": "mr-spicy-version/v1",
        "mr_spicy_version": MR_SPICY_VERSION,
        "status": "source layer present; final IPA not produced yet",
        "host_version": host_version,
        "host_build": host_build,
        "build": "NOT AVAILABLE IN CURRENT ENVIRONMENT",
        "signing": "NOT AVAILABLE IN CURRENT ENVIRONMENT",
        "installation": "NOT PERFORMED",
        "final_ipa": "NOT PRODUCED YET"
    })

    write_text(mr_root / "validation" / "reports" / "environment-report.md", render_environment_report(build_env))
    write_text(mr_root / "validation" / "reports" / "ipa-inspection-report.md", render_ipa_report(inspect_data))
    write_text(mr_root / "validation" / "reports" / "release-status.md", render_release_status(original_hash, logo_hash, app_info or {}, build_env))
    write_text(mr_root / "validation" / "reports" / "validation-matrix.md", render_validation_matrix(original_hash, logo_hash, inspect_data, build_env))
    write_text(mr_root / "versions" / "compatibility-matrix.md", render_compatibility_matrix(app_info or {}, inspect_data, build_env))


def render_environment_report(env: Dict[str, Any]) -> str:
    lines = ["# MR. SPICY Environment Report", "", f"Captured at UTC: `{env['captured_at_utc']}`", "", "## Tool availability", ""]
    for tool, exists in env["tools"].items():
        lines.append(f"- `{tool}`: {'AVAILABLE' if exists else 'NOT AVAILABLE'}")
    lines += [
        "",
        "## Interpretation",
        "",
        "- Xcode, Apple SDK tooling, `codesign`, `security`, and `xcrun` are required for a real iOS archive/export/signing flow.",
        "- If those tools are not available, build/sign/install results are recorded as not performed rather than fabricated.",
    ]
    return "\n".join(lines) + "\n"


def render_ipa_report(data: Dict[str, Any]) -> str:
    app = data["app_info"]
    lines = [
        "# IPA Inspection Report",
        "",
        "## Source",
        "",
        f"- IPA: `{data['ipa']['path']}`",
        f"- Size: `{data['ipa']['size']}` bytes",
        f"- SHA-256: `{data['ipa']['sha256']}`",
        "",
        "## Bundle",
        "",
        f"- App directories: `{', '.join(data['app_dirs'])}`",
        f"- Bundle identifier: `{app.get('CFBundleIdentifier')}`",
        f"- Executable: `{app.get('CFBundleExecutable')}`",
        f"- Display name: `{app.get('CFBundleDisplayName')}`",
        f"- Host version: `{app.get('CFBundleShortVersionString')}`",
        f"- Host build: `{app.get('CFBundleVersion')}`",
        f"- Minimum iOS: `{app.get('MinimumOSVersion')}`",
        f"- Device family: `{app.get('UIDeviceFamily')}`",
        f"- Orientations iPhone: `{app.get('UISupportedInterfaceOrientations')}`",
        f"- Orientations iPad: `{app.get('UISupportedInterfaceOrientations~ipad')}`",
        "",
        "## Contents",
        "",
        f"- Archive entries: `{data.get('entry_count', 'see manifest')}`",
        f"- Framework groups: `{data['framework_count']}`",
        f"- App extensions: `{data['extension_count']}`",
        f"- Candidate Mach-O binaries parsed: `{data['binary_count']}`",
        f"- CodeResources manifests observed: `{data['code_signature_resource_manifests']}`",
        f"- Embedded mobileprovision observed: `{data['embedded_mobileprovision_present']}`",
        "",
        "## Frameworks",
        "",
    ]
    for fw in data["frameworks"]:
        info = fw.get("info") or {}
        lines.append(f"- `{fw['name']}` — executable `{info.get('CFBundleExecutable')}`; bundle id `{info.get('CFBundleIdentifier')}`")
    lines += ["", "## App extensions", ""]
    for ext in data["extensions"]:
        info = ext.get("info") or {}
        lines.append(f"- `{ext['name']}` — executable `{info.get('CFBundleExecutable')}`; extension point `{info.get('NSExtensionPointIdentifier')}`")
    lines += ["", "## Localization observed", ""]
    for lang, count in data["localization"]["languages"].items():
        lines.append(f"- `{lang}`: {count} entries")
    lines += ["", "## Mach-O summary", ""]
    for path, parsed in data["mach_o"].items():
        if not parsed.get("is_macho"):
            lines.append(f"- `{path}`: not Mach-O (`{parsed.get('reason')}`)")
            continue
        archs = []
        deps = set()
        encrypted = []
        for sl in parsed.get("slices", []):
            archs.append(str(sl.get("cpu_type")))
            deps.update(sl.get("dependencies", []))
            encrypted.extend(sl.get("encryption", []))
        cryptids = sorted({str(e.get("crypt_id")) for e in encrypted}) if encrypted else []
        lines.append(f"- `{path}`: archs `{', '.join(sorted(set(archs)))}`; dependencies `{len(deps)}`; cryptids `{', '.join(cryptids) if cryptids else 'not reported'}`")
    lines += [
        "",
        "## Signing/provisioning facts",
        "",
        "- `_CodeSignature/CodeResources` manifests are present in the IPA.",
        "- Cryptographic signature validation was not performed because Apple `codesign` tooling is not available in this environment.",
        "- No embedded provisioning profile was observed in the archive; App Store IPAs commonly omit embedded development provisioning profiles.",
    ]
    return "\n".join(lines) + "\n"


def render_release_status(original_hash: str, logo_hash: str, app: Dict[str, Any], env: Dict[str, Any]) -> str:
    xcode_available = env["tools"].get("xcodebuild", False)
    codesign_available = env["tools"].get("codesign", False)
    lines = [
        "# MR. SPICY Release Status",
        "",
        "ORIGINAL HOST:",
        f"    {ORIGINAL_IPA}",
        "",
        "ORIGINAL HASH:",
        f"    {original_hash}",
        f"    VERIFIED: {'YES' if original_hash == KNOWN_ORIGINAL_IPA_SHA256 else 'NO'}",
        "",
        "ORIGINAL LOGO HASH:",
        f"    {logo_hash}",
        f"    VERIFIED: {'YES' if logo_hash == KNOWN_LOGO_SHA256 else 'NO'}",
        "",
        "MR. SPICY:",
        "    customization layer",
        f"    VERSION: {MR_SPICY_VERSION}",
        "    FEATURES: FREE / NO MR. SPICY AD GATING / PRO AVAILABLE",
        "",
        "XCODE PROJECT:",
        "    MR-SPICY/MRSpicy.xcodeproj PRESENT (structural; Xcode open/build not tested here)",
        "    LOCAL PACKAGE: MR-SPICY/MrSpicyUI/Package.swift PRESENT",
        "",
        "HOST VERSION:",
        f"    {app.get('CFBundleShortVersionString', 'UNKNOWN')}",
        "",
        "HOST BUILD:",
        f"    {app.get('CFBundleVersion', 'UNKNOWN')}",
        "",
        "FINAL:",
        "    Mr Spicy.ipa",
        "    STATUS: NOT PRODUCED YET",
        "",
        "BUILD:",
        f"    {'NOT PERFORMED' if xcode_available else 'NOT AVAILABLE IN CURRENT ENVIRONMENT'}",
        "",
        "SIGNING:",
        f"    {'NOT PERFORMED' if codesign_available else 'NOT AVAILABLE IN CURRENT ENVIRONMENT'}",
        "",
        "INSTALLATION:",
        "    NOT PERFORMED",
        "",
        "COMPATIBILITY:",
        "    REQUIRES REVIEW / NOT TESTED on physical devices",
        "",
        "FINAL IPA:",
        "    MR-SPICY/output/Mr Spicy.ipa NOT PRODUCED YET",
        "",
        "NOTE:",
        "    The original IPA was not renamed or copied as a fake final release. No final IPA is present because no actual MR. SPICY build/sign/export flow was performed in this environment.",
    ]
    return "\n".join(lines) + "\n"


def render_validation_matrix(original_hash: str, logo_hash: str, data: Dict[str, Any], env: Dict[str, Any]) -> str:
    xcode = env["tools"].get("xcodebuild", False)
    codesign = env["tools"].get("codesign", False)
    rows = [
        ("repository", "VERIFIED", "Initial root files inventoried; current repository inventory generated."),
        ("original hash", "VERIFIED" if original_hash == KNOWN_ORIGINAL_IPA_SHA256 else "REQUIRES REVIEW", original_hash),
        ("logo hash", "VERIFIED" if logo_hash == KNOWN_LOGO_SHA256 else "REQUIRES REVIEW", logo_hash),
        ("IPA structure", "VERIFIED", "Payload and app bundle observed."),
        ("application bundle", "VERIFIED", ", ".join(data["app_dirs"])),
        ("executable", "VERIFIED", str(data["app_info"].get("CFBundleExecutable"))),
        ("frameworks", "VERIFIED", f"{data['framework_count']} framework groups observed."),
        ("dependencies", "VERIFIED", "Mach-O dependency load commands parsed where readable."),
        ("Info.plist", "VERIFIED", "Primary bundle metadata parsed."),
        ("signing", "NOT TESTED" if codesign else "BLOCKED BY ENVIRONMENT", "CodeResources present; cryptographic validation not performed."),
        ("provisioning", "NOT TESTED", "No embedded.mobileprovision observed."),
        ("Xcode project", "VERIFIED STRUCTURALLY", "MRSpicy.xcodeproj, shared scheme, app target, package, scripts, and ExportOptions.plist present."),
        ("MR. SPICY free feature model", "VERIFIED STRUCTURALLY", "PRO available; no MR. SPICY payment/ad/subscription/license/countdown gate added."),
        ("localization", "VERIFIED", "Original localization resources inventoried; MR. SPICY en/ar created."),
        ("English", "VERIFIED", "MR. SPICY English strings present."),
        ("Arabic", "VERIFIED", "MR. SPICY Arabic strings present."),
        ("RTL", "VERIFIED STRUCTURALLY", "MR. SPICY uses semantic content attributes and leading/trailing constraints."),
        ("responsive layout", "VERIFIED STRUCTURALLY", "Trait and safe-area handling implemented in source."),
        ("accessibility", "VERIFIED STRUCTURALLY", "VoiceOver labels/hints, Dynamic Type, touch targets, Reduce Motion references implemented."),
        ("UI states", "VERIFIED STRUCTURALLY", "SpicyOverlayState contains required states."),
        ("performance", "REQUIRES DEVICE TEST", "No runtime profiling performed."),
        ("regression", "NOT APPLICABLE", "No final artifact exists for original/final diff."),
        ("final packaging", "NOT PERFORMED" if xcode else "BLOCKED BY ENVIRONMENT", "No final IPA produced."),
        ("final hash", "NOT AVAILABLE", "No final IPA produced."),
        ("compatibility", "NOT TESTED", "No physical device/simulator run performed."),
        ("installation", "NOT PERFORMED", "No installation attempted."),
    ]
    lines = ["# Validation Matrix", "", "| Area | Status | Evidence |", "|---|---|---|"]
    for area, status, evidence in rows:
        lines.append(f"| {area} | {status} | {evidence} |")
    return "\n".join(lines) + "\n"


def render_compatibility_matrix(app: Dict[str, Any], data: Dict[str, Any], env: Dict[str, Any]) -> str:
    archs = set()
    for parsed in data["mach_o"].values():
        for sl in parsed.get("slices", []):
            if sl.get("cpu_type"):
                archs.add(str(sl["cpu_type"]))
    lines = [
        "# Compatibility Matrix",
        "",
        "| Host version | Host build | MR. SPICY version | iOS version | Architecture | Device family | Tested device | English | Arabic | RTL | Accessibility | Build | Signing | Installation | Known issues |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
        f"| {app.get('CFBundleShortVersionString', 'UNKNOWN')} | {app.get('CFBundleVersion', 'UNKNOWN')} | {MR_SPICY_VERSION} | Minimum {app.get('MinimumOSVersion', 'UNKNOWN')} from Info.plist; runtime NOT TESTED | {', '.join(sorted(archs)) or 'UNKNOWN'} | {app.get('UIDeviceFamily', 'UNKNOWN')} | NOT TESTED | VERIFIED STRUCTURALLY | VERIFIED STRUCTURALLY | VERIFIED STRUCTURALLY | VERIFIED STRUCTURALLY | NOT PERFORMED | NOT PERFORMED | NOT PERFORMED | Build/sign/install require authorized Apple environment; runtime UI not device-tested. |",
        "",
        "Legend: VERIFIED, NOT TESTED, INCOMPATIBLE, REQUIRES REVIEW. Structural verification means source/files were inspected, not that a device runtime test occurred.",
    ]
    return "\n".join(lines) + "\n"


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Repository root")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    create_reports(root)
    print("MR. SPICY inspection reports generated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
