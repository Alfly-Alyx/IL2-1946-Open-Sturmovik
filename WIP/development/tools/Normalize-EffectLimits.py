#!/usr/bin/env python3
"""Audit and optionally normalize IL-2 4.09 particle-effect limits.

The limits in this tool come from the ranges printed by the 4.09m engine's
Str2FloatClamp diagnostics.  Replacing an out-of-range literal with the value
the engine already uses at runtime is behavior-preserving for that engine.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path


SUPPORTED_CLASSES = {"tparticlessystemparams", "tsmokespiralparams"}
FIELD_PATTERN = re.compile(
    rb"^(?P<prefix>[ \t]*)(?P<key>nParticles|FinishTime|MaxR|PhiN|PsiN|LiveTime|"
    rb"TranspTransitionTime|Wind|Rnd)(?P<separator>[ \t]+)"
    rb"(?P<number>[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?)"
    rb"(?P<suffix>f?)(?P<trailing>[ \t]*(?://[^\r\n]*)?(?:\r\n|\n|\r)?)$",
    re.IGNORECASE,
)
CLASS_PATTERN = re.compile(rb"^[ \t]*ClassName[ \t]+([^ \t\r\n/]+)", re.IGNORECASE | re.MULTILINE)


@dataclass
class Change:
    path: str
    line: int
    effect_class: str
    field: str
    original: str
    normalized: str
    minimum: float
    maximum: float
    before_sha256: str
    after_sha256: str


def clamp(value: float, minimum: float, maximum: float) -> float:
    return min(maximum, max(minimum, value))


def field_bounds(key: str, explicit_values: dict[str, float]) -> tuple[float, float] | None:
    static = {
        "nparticles": (1.0, 512.0),
        "finishtime": (-1.0, 10000.0),
        "maxr": (0.0, 32.0),
        "phin": (0.0, 32.0),
        "psin": (0.0, 32.0),
        "livetime": (0.01, 128.0),
        "wind": (0.0, 100.0),
        "rnd": (0.0, 0.95),
    }
    lowered = key.lower()
    if lowered in static:
        return static[lowered]
    if lowered == "transptransitiontime":
        live_time = explicit_values.get("livetime")
        if live_time is None:
            return None
        return 0.0, clamp(live_time, 0.01, 128.0)
    return None


def format_value(key: str, value: float) -> str:
    if key.lower() == "nparticles":
        return str(int(value))
    if math.isclose(value, round(value)):
        return f"{int(round(value))}.0"
    return f"{value:.8f}".rstrip("0").rstrip(".")


def normalize_trailing(trailing: bytes) -> bytes:
    """Retire les blancs terminaux d'une ligne modifiee sans toucher au commentaire."""
    newline = b""
    body = trailing
    for ending in (b"\r\n", b"\n", b"\r"):
        if trailing.endswith(ending):
            newline = ending
            body = trailing[: -len(ending)]
            break
    return body.rstrip(b" \t") + newline


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def audit_file(path: Path, root: Path) -> tuple[bytes, list[Change]]:
    original_data = path.read_bytes()
    class_match = CLASS_PATTERN.search(original_data)
    if class_match is None:
        return original_data, []
    effect_class = class_match.group(1).decode("ascii", errors="replace")
    if effect_class.lower() not in SUPPORTED_CLASSES:
        return original_data, []

    lines = original_data.splitlines(keepends=True)
    parsed: list[tuple[int, re.Match[bytes], str, float]] = []
    explicit_values: dict[str, float] = {}
    for index, line in enumerate(lines):
        match = FIELD_PATTERN.match(line)
        if match is None:
            continue
        key = match.group("key").decode("ascii")
        value = float(match.group("number").decode("ascii"))
        parsed.append((index, match, key, value))
        explicit_values[key.lower()] = value

    pending: list[tuple[int, re.Match[bytes], str, float, float, float]] = []
    for index, match, key, value in parsed:
        bounds = field_bounds(key, explicit_values)
        if bounds is None:
            continue
        minimum, maximum = bounds
        normalized = clamp(value, minimum, maximum)
        if not math.isclose(value, normalized, rel_tol=0.0, abs_tol=1e-12):
            pending.append((index, match, key, value, normalized, minimum, maximum))

    if not pending:
        return original_data, []

    for index, match, key, _value, normalized, _minimum, _maximum in pending:
        replacement = format_value(key, normalized).encode("ascii")
        lines[index] = b"".join(
            (
                match.group("prefix"),
                match.group("key"),
                match.group("separator"),
                replacement,
                match.group("suffix"),
                normalize_trailing(match.group("trailing")),
            )
        )
    normalized_data = b"".join(lines)
    before_hash = sha256(original_data)
    after_hash = sha256(normalized_data)
    relative = path.relative_to(root).as_posix()
    changes = [
        Change(
            path=relative,
            line=index + 1,
            effect_class=effect_class,
            field=key,
            original=format(value, ".15g"),
            normalized=format_value(key, normalized),
            minimum=minimum,
            maximum=maximum,
            before_sha256=before_hash,
            after_sha256=after_hash,
        )
        for index, _match, key, value, normalized, minimum, maximum in pending
    ]
    return normalized_data, changes


def atomic_write(path: Path, data: bytes) -> None:
    descriptor, temporary_name = tempfile.mkstemp(prefix=f"{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, path)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--apply", action="store_true", help="Atomically write normalized values")
    parser.add_argument("--report", type=Path, help="Write the JSON audit report")
    parser.add_argument("--overwrite-report", action="store_true", help="Explicitly replace an existing report")
    args = parser.parse_args()

    root = args.root.resolve()
    files_root = root / "Files"
    all_changes: list[Change] = []
    normalized_files: dict[Path, bytes] = {}
    scanned = 0
    for path in sorted(files_root.rglob("*.eff"), key=lambda item: str(item).lower()):
        scanned += 1
        normalized_data, changes = audit_file(path, root)
        if changes:
            all_changes.extend(changes)
            normalized_files[path] = normalized_data

    if args.apply:
        for path, data in normalized_files.items():
            atomic_write(path, data)

    result = {
        "schema": 1,
        "engine": "IL-2 1946 4.09m",
        "mode": "apply" if args.apply else "audit",
        "scanned_effect_files": scanned,
        "changed_files": len(normalized_files),
        "normalized_values": len(all_changes),
        "limits_source": "Str2FloatClamp ranges observed in the 2026-08-30 Selector Dump startup log",
        "changes": [asdict(change) for change in all_changes],
    }
    output = json.dumps(result, indent=2, ensure_ascii=False)
    print(output)
    if args.report:
        report_path = args.report if args.report.is_absolute() else root / args.report
        if report_path.exists() and not args.overwrite_report:
            if args.apply and not all_changes:
                print(f"Existing report preserved because the tree is already normalized: {report_path}")
            else:
                raise FileExistsError(
                    f"Report already exists: {report_path}. Use --overwrite-report only after reviewing the new audit."
                )
        else:
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
