#!/usr/bin/env python3
"""Replace one entry in an IL-2 SFS archive and rebuild it.

The reader, fingerprint, metadata encryption, and decompression primitives come
from the repository's Analyze-Sfs.py tool.  The output is rebuilt in the source
TOC order, then reopened and compared entry by entry before success is reported.
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import importlib.util
import json
import math
import struct
import sys
import zlib
from pathlib import Path


CHUNK_SIZE = 32768
DEFLATE_PREFIX = b"\x02\x08\x00"


def load_analyzer(path: Path):
    spec = importlib.util.spec_from_file_location("open_sturmovik_analyze_sfs", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load the SFS analyzer: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def raw_deflate(data: bytes, level: int) -> bytes:
    compressor = zlib.compressobj(level, zlib.DEFLATED, -zlib.MAX_WBITS)
    return compressor.compress(data) + compressor.flush()


def clear_toc_items(analyzer, archive) -> list:
    encrypted_toc = archive._mmap[archive.header.header_end : archive.header.toc_end]
    clear_toc = analyzer.sfs_decrypt(archive.header_hash, encrypted_toc)
    return [
        analyzer.SfsTocItem(*struct.unpack_from("<qIIIIII", clear_toc, index * 32))
        for index in range(archive.header.toc_count)
    ]


def rebuild(
    analyzer,
    source: Path,
    destination: Path,
    relative_path: str,
    replacement: Path,
    compression_level: int,
) -> dict[str, object]:
    if destination.exists():
        raise FileExistsError(f"Destination already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    replacement_data = replacement.read_bytes()

    with analyzer.SfsArchive(source) as archive:
        if archive.header.version not in (201, 0xCA):
            raise ValueError(f"Unsupported SFS version: {archive.header.version}")

        raw_header = bytes(archive._mmap[:256])
        clear_header = bytearray(raw_header)
        if archive.header.version == 0xCA:
            clear_header[8:32] = analyzer.sfs_decrypt(archive.header_hash, raw_header[8:32])

        items = clear_toc_items(analyzer, archive)
        target_fingerprint = analyzer.finger_string(0, relative_path)
        matches = [item for item in items if item.fingerprint == target_fingerprint]
        if len(matches) != 1:
            raise ValueError(f"Expected one {relative_path!r} entry, found {len(matches)}")
        target = matches[0]
        old_end = target.offset + target.size

        occupied = [
            item
            for item in items
            if item.fingerprint != target_fingerprint
            and target.offset <= item.offset < old_end
        ]
        overlapping = [
            item
            for item in items
            if item.size
            and item.fingerprint != target_fingerprint
            and item.offset < old_end
            and item.offset + item.size > target.offset
        ]
        if occupied or overlapping:
            raise ValueError("The target data range is shared or overlaps another TOC entry")

        original_data = archive.decompress()
        rebuilt_data = original_data[: target.offset] + replacement_data + original_data[old_end:]
        delta = len(replacement_data) - target.size

        updated_items = []
        for item in items:
            if item.fingerprint == target_fingerprint:
                item = dataclasses.replace(
                    item,
                    size=len(replacement_data),
                    unknown_2=sum(replacement_data) & 0xFFFFFFFF,
                )
            elif item.offset >= old_end:
                item = dataclasses.replace(item, offset=item.offset + delta)
            updated_items.append(item)

        chunk_count = math.ceil(len(rebuilt_data) / CHUNK_SIZE)
        toc_end = archive.header.header_end + archive.header.toc_count * 32
        data_start = toc_end + (chunk_count + 1) * 4
        chunks: list[bytes] = []
        chunk_offsets = [data_start]
        cursor = data_start
        for start in range(0, len(rebuilt_data), CHUNK_SIZE):
            raw_chunk = rebuilt_data[start : start + CHUNK_SIZE]
            compressed = DEFLATE_PREFIX + raw_deflate(raw_chunk, compression_level)
            if len(raw_chunk) == CHUNK_SIZE and len(compressed) >= CHUNK_SIZE:
                compressed = raw_chunk
            chunks.append(compressed)
            cursor += len(compressed)
            chunk_offsets.append(cursor)

        clear_toc = b"".join(
            struct.pack(
                "<qIIIIII",
                item.fingerprint,
                item.index,
                item.offset,
                item.size,
                item.unknown_1,
                item.attributes,
                item.unknown_2,
            )
            for item in updated_items
        )

        struct.pack_into("<I", clear_header, 20, toc_end)
        struct.pack_into("<I", clear_header, 24, data_start)
        struct.pack_into("<I", clear_header, 28, len(rebuilt_data))
        struct.pack_into("<I", clear_header, 8, 0)
        checksum = sum(
            clear_header[:8]
            + b"\0\0\0\0"
            + clear_header[12 : archive.header.header_end]
        )
        struct.pack_into("<I", clear_header, 8, checksum)

        if archive.header.version == 0xCA:
            header_hash = analyzer.finger_bytes(0, destination.name.lower().encode("ascii"))
            output_header = (
                bytes(clear_header[:8])
                + analyzer.sfs_decrypt(header_hash, clear_header[8:32])
                + bytes(clear_header[32:])
            )
        else:
            output_header = bytes(clear_header)
            header_hash = analyzer.finger_bytes(0, output_header)

        encrypted_toc = analyzer.sfs_decrypt(header_hash, clear_toc)
        clear_chunk_table = struct.pack(f"<{len(chunk_offsets)}I", *chunk_offsets)
        encrypted_chunk_table = analyzer.sfs_decrypt2(header_hash, clear_chunk_table)

        with destination.open("xb") as handle:
            handle.write(output_header)
            handle.write(encrypted_toc)
            handle.write(encrypted_chunk_table)
            for chunk in chunks:
                handle.write(chunk)

        source_entries = {item.fingerprint: item for item in archive.toc}
        source_payloads = {
            fingerprint: archive.extract_item(item)
            for fingerprint, item in source_entries.items()
        }

    with analyzer.SfsArchive(destination) as rebuilt:
        rebuilt_entries = {item.fingerprint: item for item in rebuilt.toc}
        if rebuilt_entries.keys() != source_entries.keys():
            raise ValueError("The rebuilt SFS entry set differs from the source")
        changed = []
        for fingerprint, source_item in source_entries.items():
            rebuilt_item = rebuilt_entries[fingerprint]
            rebuilt_payload = rebuilt.extract_item(rebuilt_item)
            if fingerprint == target_fingerprint:
                if rebuilt_payload != replacement_data:
                    raise ValueError("The rebuilt target entry differs from the replacement")
                changed.append(fingerprint)
                continue
            if rebuilt_payload != source_payloads[fingerprint]:
                raise ValueError(f"Unexpected content change for fingerprint {fingerprint & 0xFFFFFFFFFFFFFFFF:016X}")
            if (
                rebuilt_item.size != source_item.size
                or rebuilt_item.unknown_1 != source_item.unknown_1
                or rebuilt_item.attributes != source_item.attributes
                or rebuilt_item.unknown_2 != source_item.unknown_2
            ):
                raise ValueError(f"Unexpected metadata change for fingerprint {fingerprint & 0xFFFFFFFFFFFFFFFF:016X}")
        if changed != [target_fingerprint]:
            raise ValueError(f"Expected one changed entry, found {len(changed)}")
        summary = rebuilt.summary()

    summary.update(
        {
            "replaced_path": relative_path,
            "replaced_fingerprint": f"{target_fingerprint & 0xFFFFFFFFFFFFFFFF:016X}",
            "replacement_size": len(replacement_data),
            "replacement_sha256": hashlib.sha256(replacement_data).hexdigest().upper(),
            "verified_unchanged_entries": len(source_entries) - 1,
        }
    )
    return summary


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--path", required=True, dest="relative_path")
    parser.add_argument("--replacement", required=True, type=Path)
    parser.add_argument("--compression-level", type=int, choices=range(0, 10), default=9)
    parser.add_argument(
        "--analyzer",
        type=Path,
        default=Path(__file__).with_name("Analyze-Sfs.py"),
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    analyzer = load_analyzer(args.analyzer.resolve())
    try:
        result = rebuild(
            analyzer,
            args.source.resolve(),
            args.destination.resolve(),
            args.relative_path,
            args.replacement.resolve(),
            args.compression_level,
        )
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
