#!/usr/bin/env python3
"""Build profile-specific IL-2 loading version labels.

The tool extracts ConsoleGL0Render from verified SFS archives and replaces only
the single UTF-8 constant used twice by the render method. It never rewrites an
SFS archive. Profile 4 deliberately simplifies the stock 4.09 beta label.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path

LOOSE_NAME = "B44652EE36C23D32"
CLASS_NAME = "com.maddox.il2.engine.ConsoleGL0Render"
SOURCE_HASHES = {
    1: "CD09B7F1F663F75663512161D2C4E6ABDC2A53D3FC272349F8135B58497FAD05",
    2: "CD09B7F1F663F75663512161D2C4E6ABDC2A53D3FC272349F8135B58497FAD05",
    3: "CD09B7F1F663F75663512161D2C4E6ABDC2A53D3FC272349F8135B58497FAD05",
    4: "B90A1539D2BAF31A7837C61D1FF138E2B1591A11C95AEA7A00EE7ED1E32B9F30",
    5: "19C827922B2F62BBD41CFEB84EA046A139C8D188E0A37E26D4D2BD63181542AF",
    6: "19C827922B2F62BBD41CFEB84EA046A139C8D188E0A37E26D4D2BD63181542AF",
    7: "F57769F2C10E5672035715161C6A142FA36D57A8A26141F7519847314EDF61A4",
    8: "F57769F2C10E5672035715161C6A142FA36D57A8A26141F7519847314EDF61A4",
    9: "F57769F2C10E5672035715161C6A142FA36D57A8A26141F7519847314EDF61A4",}
PROFILE_DATA = (
    (1, "4.08 Mods OFF (Original)", "V 4.08m", None),
    (2, "4.08 Mods ON (NO 6DOF)", "V 4.08m", "V 4.08m - mod no 6DOF"),
    (3, "4.08 Mods ON 6DOF", "V 4.08m", "V 4.08m - mod 6DOF"),
    (4, "4.09b Mods OFF (Original)", "V 4.09b", None),
    (5, "4.09b Mods ON (NO 6DOF)", "V 4.09b1m", "V 4.09b - mod no 6DOF"),
    (6, "4.09b Mods ON 6DOF", "V 4.09b1m", "V 4.09b - mod 6DOF"),
    (7, "4.09m Mods OFF (Original)", "V 4.09m", None),
    (8, "4.09m Mods ON (NO 6DOF)", "V 4.09m", "V 4.09m - mod no 6DOF"),
    (9, "4.09m Mods ON 6DOF", "V 4.09m", "V 4.09m - mod 6DOF"),
)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def load_sfs_tool(path: Path):
    spec = importlib.util.spec_from_file_location("analyze_sfs_for_labels", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.SfsArchive


def utf8_constants(data: bytes) -> list[tuple[int, int, bytes]]:
    if data[:4] != b"\xca\xfe\xba\xbe":
        raise ValueError("Not a Java class")
    cp_count = struct.unpack_from(">H", data, 8)[0]
    result: list[tuple[int, int, bytes]] = []
    offset = 10
    index = 1
    while index < cp_count:
        tag = data[offset]
        offset += 1
        if tag == 1:
            length = struct.unpack_from(">H", data, offset)[0]
            start = offset - 1
            value_start = offset + 2
            value = data[value_start:value_start + length]
            result.append((start, value_start + length, value))
            offset = value_start + length
        elif tag in (3, 4):
            offset += 4
        elif tag in (5, 6):
            offset += 8
            index += 1
        elif tag in (7, 8, 16, 19, 20):
            offset += 2
        elif tag in (9, 10, 11, 12, 17, 18):
            offset += 4
        elif tag == 15:
            offset += 3
        else:
            raise ValueError(f"Unsupported constant-pool tag {tag} at index {index}")
        index += 1
    return result


def labels(data: bytes) -> list[str]:
    result = []
    for _, _, raw in utf8_constants(data):
        try:
            value = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if value.startswith("V 4."):
            result.append(value)
    return result


def replace_label(data: bytes, old: str, new: str) -> bytes:
    old_bytes = old.encode("utf-8")
    new_bytes = new.encode("utf-8")
    matches = [(start, end) for start, end, value in utf8_constants(data) if value == old_bytes]
    if len(matches) != 1:
        raise ValueError(f"Expected one {old!r} constant, found {len(matches)}")
    start, end = matches[0]
    replacement = bytes((1,)) + struct.pack(">H", len(new_bytes)) + new_bytes
    output = data[:start] + replacement + data[end:]
    if labels(output) != [new]:
        raise ValueError("Output label verification failed")
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository-root", type=Path, default=Path(__file__).resolve().parents[3])
    args = parser.parse_args()
    root = args.repository_root.resolve()
    switch_root = root / "_Game Switcher"
    Archive = load_sfs_tool(root / "WIP/development/tools/Analyze-Sfs.py")
    report = {
        "schemaVersion": 1,
        "checkedUtc": datetime.now(timezone.utc).isoformat(),
        "class": CLASS_NAME,
        "looseName": LOOSE_NAME,
        "method": "Read-only SFS extraction followed by one guarded Java constant-pool UTF-8 replacement; SFS archives remain unchanged.",
        "networkCompatibilityChanged": False,
        "profiles": [],
    }
    for number, folder, expected, replacement in PROFILE_DATA:
        archive_path = switch_root / folder / "files.SFS"
        with Archive(archive_path) as archive:
            extracted = archive.extract_class(CLASS_NAME)
        found = labels(extracted)
        if found != [expected]:
            raise ValueError(f"Profile {number}: expected {[expected]!r}, found {found!r}")
        actual_hash = sha(extracted)
        if actual_hash != SOURCE_HASHES[number]:
            raise ValueError(f"Profile {number}: unexpected source class {actual_hash}")
        item = {
            "number": number,
            "folder": folder,
            "archive": archive_path.relative_to(root).as_posix(),
            "extractedSize": len(extracted),
            "extractedSha256": actual_hash,
            "originalDisplayLabel": expected,
            "installedDisplayLabel": replacement or expected,
        }
        target = switch_root / folder / "Profiles/Files" / LOOSE_NAME
        if replacement is not None:
            output = replace_label(extracted, expected, replacement)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(output)
            item.update({
                "output": target.relative_to(root).as_posix(),
                "outputSize": len(output),
                "outputSha256": sha(output),
            })
        elif target.exists():
            target.unlink()
        if number == 4:
            item["historicalUnmodifiedLabel"] = "V 4.09b1m"
            item["archivePatchManifest"] = "WIP/development/manifests/stock-409b-loading-label-v1.15.json"
        report["profiles"].append(item)
    report_path = root / "WIP/development/manifests/profile-loading-labels-v1.15.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: verified 9 current archive labels and built 6 loose display overrides; report={report_path}")
    for item in report["profiles"]:
        print(item["number"], item["originalDisplayLabel"], "=>", item["installedDisplayLabel"], item.get("outputSha256", item["extractedSha256"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())