#!/usr/bin/env python3
"""Preserve only non-redundant files from a verified backup report."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            value.update(block)
    return value.hexdigest().upper()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export the unmatched part of a SHA-256 redundancy report."
    )
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--destination", required=True, type=Path)
    args = parser.parse_args()

    report_path = args.report.resolve()
    destination = args.destination.resolve()
    report = json.loads(report_path.read_text(encoding="utf-8"))
    if report.get("mode") != "sha256":
        raise SystemExit("The input report is not a SHA-256 report.")

    backup = Path(report["backup"]).resolve()
    if not backup.is_dir():
        raise SystemExit("Backup directory is missing: " + str(backup))
    if destination.exists():
        raise SystemExit("Destination already exists: " + str(destination))

    files_root = destination / "files"
    exported = []
    for entry in report.get("unmatched", []):
        relative = Path(entry["relative_path"])
        source = backup / relative
        target = files_root / relative
        expected = str(entry["sha256"]).upper()
        if digest(source) != expected:
            raise SystemExit("Source changed since audit: " + str(source))
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        actual = digest(target)
        if actual != expected:
            raise SystemExit("Copy verification failed: " + str(target))
        exported.append(
            {
                "relative_path": relative.as_posix(),
                "size": target.stat().st_size,
                "sha256": actual,
            }
        )

    shutil.copy2(report_path, destination / "redundancy-report.json")
    manifest = {
        "schema": "open-sturmovik-backup-delta-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "source_backup": str(backup),
        "source_redundancy_report": str(report_path),
        "files": len(exported),
        "bytes": sum(int(item["size"]) for item in exported),
        "all_sha256_verified": True,
        "entries": exported,
    }
    (destination / "delta-manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    print(
        "exported-files={0} exported-bytes={1} destination={2}".format(
            len(exported), manifest["bytes"], destination
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
