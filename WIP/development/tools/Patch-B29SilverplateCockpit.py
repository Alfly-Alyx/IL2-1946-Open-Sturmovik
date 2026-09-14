#!/usr/bin/env python3
"""Patch only the B-29 Silverplate pilot-cockpit constants in its class file."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path


REPLACEMENTS = {
    "class$com$maddox$il2$objects$air$CockpitB29":
        "class$com$maddox$il2$objects$air$CockpitB29SP",
    "com.maddox.il2.objects.air.CockpitB29":
        "com.maddox.il2.objects.air.CockpitB29SP",
    "com/maddox/il2/objects/air/CockpitB29":
        "com/maddox/il2/objects/air/CockpitB29SP",
}
REQUIRED_OLD = {
    "class$com$maddox$il2$objects$air$CockpitB29",
    "com.maddox.il2.objects.air.CockpitB29",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def patch_constant_pool(data: bytes) -> tuple[bytes, list[str]]:
    if len(data) < 10 or data[:4] != b"\xCA\xFE\xBA\xBE":
        raise ValueError("the input is not a Java class file")

    constant_count = struct.unpack_from(">H", data, 8)[0]
    output = bytearray(data[:10])
    offset = 10
    index = 1
    changed: list[str] = []
    utf8_values: list[str] = []
    while index < constant_count:
        tag = data[offset]
        output.append(tag)
        offset += 1
        if tag == 1:
            length = struct.unpack_from(">H", data, offset)[0]
            offset += 2
            raw = data[offset:offset + length]
            offset += length
            text = raw.decode("utf-8")
            replacement = REPLACEMENTS.get(text, text)
            utf8_values.append(replacement)
            encoded = replacement.encode("utf-8")
            output.extend(struct.pack(">H", len(encoded)))
            output.extend(encoded)
            if replacement != text:
                changed.append(f"{text} -> {replacement}")
        elif tag in (3, 4):
            output.extend(data[offset:offset + 4])
            offset += 4
        elif tag in (5, 6):
            output.extend(data[offset:offset + 8])
            offset += 8
            index += 1
        elif tag in (7, 8):
            output.extend(data[offset:offset + 2])
            offset += 2
        elif tag in (9, 10, 11, 12):
            output.extend(data[offset:offset + 4])
            offset += 4
        else:
            raise ValueError(f"unsupported constant-pool tag {tag} at index {index}")
        index += 1
    output.extend(data[offset:])

    patched = bytes(output)
    old_tokens = [value for value in REPLACEMENTS if value in utf8_values]
    required_new = {REPLACEMENTS[value] for value in REQUIRED_OLD}
    new_tokens = [value for value in required_new if value in utf8_values]
    if old_tokens:
        raise ValueError(f"old cockpit constants remain: {old_tokens}")
    if len(new_tokens) != len(required_new):
        raise ValueError(f"incomplete Silverplate cockpit constants: {new_tokens}")
    if not changed and all(value in utf8_values for value in required_new):
        return data, []
    if len(changed) < len(REQUIRED_OLD):
        raise ValueError(f"expected at least {len(REQUIRED_OLD)} replacements, got {len(changed)}")
    return patched, changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()

    source = args.input.read_bytes()
    patched, changed = patch_constant_pool(source)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(patched)
    payload = {
        "schema": "open-sturmovik-b29sp-cockpit-patch-v1",
        "class": "com.maddox.il2.objects.air.B_29SP",
        "loose_name": "7BCE3C02C280ED18",
        "java_major": struct.unpack_from(">H", patched, 6)[0],
        "input_sha256": sha256(source),
        "output_sha256": sha256(patched),
        "replacements": changed,
        "pilot_cockpit": "com.maddox.il2.objects.air.CockpitB29SP",
        "pilot_mesh": "3DO/Cockpit/B-29-SP/CockpitB29SP.him",
    }
    if payload["java_major"] != 47:
        raise ValueError(f"unexpected Java major: {payload['java_major']}")
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
