#!/usr/bin/env python3
"""Inspecte les metadonnees objet/Klass de la JVM HotSpot 1.3.1 d'IL-2."""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path


ASCII_TOKEN = re.compile(rb"[A-Za-z_$][A-Za-z0-9_/$;\[\].<>:-]{3,}")


def parse_address(value: str) -> int:
    return int(value, 0)


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def extract_ascii(data: bytes) -> list[str]:
    return sorted(
        {
            match.group(0).decode("ascii", errors="replace")
            for match in ASCII_TOKEN.finditer(data)
            if len(match.group(0)) <= 240
        }
    )


def extract_utf16(data: bytes) -> list[str]:
    values: set[str] = set()
    for parity in (0, 1):
        compact = data[parity::2]
        for match in ASCII_TOKEN.finditer(compact):
            token = match.group(0)
            if len(token) <= 240:
                values.add(token.decode("ascii", errors="replace"))
    return sorted(values)


def symbol_candidates(data: bytes) -> list[dict]:
    candidates = []
    for length_offset in range(0, min(64, len(data) - 8), 4):
        length = u32(data, length_offset)
        if not 4 <= length <= 240:
            continue
        for body_offset in range(length_offset + 4, min(length_offset + 20, len(data))):
            body = data[body_offset : body_offset + length]
            if len(body) != length or not ASCII_TOKEN.fullmatch(body):
                continue
            candidates.append(
                {
                    "length_offset": f"0x{length_offset:X}",
                    "body_offset": f"0x{body_offset:X}",
                    "value": body.decode("ascii", errors="replace"),
                }
            )
    return candidates


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("dump", type=Path)
    parser.add_argument("--packages", type=Path, required=True)
    parser.add_argument("--address", action="append", type=parse_address, required=True)
    parser.add_argument("--bytes", type=parse_address, default=0x400)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    sys.path.insert(0, str(args.packages.resolve()))
    from minidump.minidumpfile import MinidumpFile  # type: ignore

    parsed = MinidumpFile.parse(str(args.dump.resolve()))
    reader = parsed.get_reader()
    reports = []

    for address in args.address:
        raw = reader.read(address, args.bytes)
        references = []
        seen: set[int] = set()
        for offset in range(0, len(raw) - 3, 4):
            pointer = u32(raw, offset)
            if pointer in seen or not 0x10000 <= pointer <= 0x7FFFFFFF:
                continue
            seen.add(pointer)
            try:
                pointed = reader.read(pointer, 0x200)
            except Exception:
                continue
            ascii_values = extract_ascii(pointed)
            utf16_values = extract_utf16(pointed)
            symbols = symbol_candidates(pointed)
            if ascii_values or utf16_values or symbols:
                references.append(
                    {
                        "source_offset": f"0x{offset:X}",
                        "pointer": f"0x{pointer:08X}",
                        "ascii": ascii_values,
                        "utf16_ascii": utf16_values,
                        "symbol_candidates": symbols,
                    }
                )

        reports.append(
            {
                "address": f"0x{address:08X}",
                "bytes_scanned": len(raw),
                "hex_preview": raw[:0x100].hex(" "),
                "words": [
                    {
                        "offset": f"0x{offset:X}",
                        "value": f"0x{u32(raw, offset):08X}",
                    }
                    for offset in range(0, min(len(raw), 0x80) - 3, 4)
                ],
                "direct_ascii": extract_ascii(raw),
                "direct_utf16_ascii": extract_utf16(raw),
                "references": references,
            }
        )

    result = {"dump": str(args.dump.resolve()), "objects": reports}
    rendered = json.dumps(result, indent=2, ensure_ascii=False)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
        print(f"INSPECTION_HOTSPOT : {args.output.resolve()}")
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
