#!/usr/bin/env python3
"""Verify that every file in a backup exists in another protected tree.

The first pass compares relative paths and sizes.  With ``--hash``, every
candidate is then verified with SHA-256.  The script is deliberately read-only
apart from its JSON report.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import DefaultDict, Iterable


def iter_files(root: Path) -> Iterable[Path]:
    for directory, _, names in os.walk(root):
        base = Path(directory)
        for name in names:
            yield base / name


def relative_key(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix().casefold()


def sha256(path: Path, cache: dict[Path, str]) -> str:
    cached = cache.get(path)
    if cached is not None:
        return cached
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    value = digest.hexdigest().upper()
    cache[path] = value
    return value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prove that a local backup is redundant without modifying it."
    )
    parser.add_argument("--backup", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path, action="append")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--hash",
        action="store_true",
        help="Require an exact SHA-256 match instead of path and size only.",
    )
    parser.add_argument(
        "--allow-relocated",
        action="store_true",
        help="Also look for an identical file at another relative path.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    backup = args.backup.resolve()
    sources = [source.resolve() for source in args.source]
    output = args.output.resolve()

    missing = [str(path) for path in [backup, *sources] if not path.is_dir()]
    if missing:
        raise SystemExit("Missing directory: " + ", ".join(missing))

    by_relative: DefaultDict[tuple[str, int], list[Path]] = defaultdict(list)
    by_size: DefaultDict[int, list[Path]] = defaultdict(list)
    source_files = 0
    for source in sources:
        for path in iter_files(source):
            size = path.stat().st_size
            by_relative[(relative_key(path, source), size)].append(path)
            if args.allow_relocated:
                by_size[size].append(path)
            source_files += 1

    hash_cache: dict[Path, str] = {}
    unmatched: list[dict[str, object]] = []
    matched_examples: list[dict[str, object]] = []
    backup_files = 0
    backup_bytes = 0
    matched_files = 0
    matched_bytes = 0
    relocated_matches = 0

    for path in iter_files(backup):
        backup_files += 1
        size = path.stat().st_size
        backup_bytes += size
        rel = relative_key(path, backup)
        candidates = list(by_relative.get((rel, size), ()))
        match = None

        if args.hash:
            backup_hash = sha256(path, hash_cache)
            for candidate in candidates:
                if sha256(candidate, hash_cache) == backup_hash:
                    match = candidate
                    break
            if match is None and args.allow_relocated:
                for candidate in by_size.get(size, ()):
                    if candidate in candidates:
                        continue
                    if sha256(candidate, hash_cache) == backup_hash:
                        match = candidate
                        relocated_matches += 1
                        break
        elif candidates:
            match = candidates[0]

        if match is None:
            entry: dict[str, object] = {
                "relative_path": path.relative_to(backup).as_posix(),
                "size": size,
                "same_path_size_candidates": [str(candidate) for candidate in candidates],
            }
            if args.hash:
                entry["sha256"] = sha256(path, hash_cache)
            unmatched.append(entry)
        else:
            matched_files += 1
            matched_bytes += size
            if len(matched_examples) < 20:
                matched_examples.append(
                    {
                        "relative_path": path.relative_to(backup).as_posix(),
                        "size": size,
                        "source": str(match),
                    }
                )

    report = {
        "schema": "open-sturmovik-backup-redundancy-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "mode": "sha256" if args.hash else "path_and_size",
        "allow_relocated": args.allow_relocated,
        "backup": str(backup),
        "sources": [str(source) for source in sources],
        "source_files_indexed": source_files,
        "backup_files": backup_files,
        "backup_bytes": backup_bytes,
        "matched_files": matched_files,
        "matched_bytes": matched_bytes,
        "relocated_matches": relocated_matches,
        "unmatched_files": len(unmatched),
        "unmatched_bytes": sum(int(item["size"]) for item in unmatched),
        "fully_redundant": not unmatched,
        "matched_examples": matched_examples,
        "unmatched": unmatched,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(
        "backup-files={0} matched={1} unmatched={2} fully-redundant={3}".format(
            backup_files, matched_files, len(unmatched), not unmatched
        )
    )
    print("report=" + str(output))
    return 0 if not unmatched else 2


if __name__ == "__main__":
    raise SystemExit(main())
