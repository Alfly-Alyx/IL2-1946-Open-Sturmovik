#!/usr/bin/env python3
"""Audit every aircraft declared by IL-2 1946's active air.ini.

The audit is deliberately read-only with respect to game content.  It combines
the active loose classes (which take priority) with a Selector Dump directory
containing classes recovered from SFS archives.  It does not attempt to unpack
or rebuild the protected Buttons flight-model container.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import struct
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


HEX_NAME = re.compile(r"[0-9A-Fa-f]{16}")
FLIGHT_MODEL = re.compile(r"(?i)^FlightModels[/\\].+\.fmd(?::.*)?$")
MESH_NAME = re.compile(r"(?i)^3do[/\\]Plane[/\\].+[/\\]hier\.him$")
COCKPIT_NAME = re.compile(r"^com[./]maddox[./]il2[./]objects[./]air[./](Cockpit[^;\[]+)$")
GENERIC_COCKPIT_OWNERS = {
    "com/maddox/il2/objects/air/Aircraft",
    "com/maddox/il2/objects/air/NetAircraft",
}


class ClassFormatError(ValueError):
    pass


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.offset = 0

    def take(self, length: int) -> bytes:
        end = self.offset + length
        if length < 0 or end > len(self.data):
            raise ClassFormatError(f"read beyond end at 0x{self.offset:X}")
        value = self.data[self.offset:end]
        self.offset = end
        return value

    def u1(self) -> int:
        return self.take(1)[0]

    def u2(self) -> int:
        return struct.unpack(">H", self.take(2))[0]

    def u4(self) -> int:
        return struct.unpack(">I", self.take(4))[0]


@dataclass
class ClassSummary:
    name: str
    super_name: str | None
    major: int
    strings: list[str]
    class_refs: list[str]
    method_owners: list[str]
    source: str
    source_kind: str
    sha256: str


@dataclass
class AirEntry:
    line: int
    key: str
    class_token: str
    tokens: list[str]


@dataclass
class AircraftAudit:
    line: int
    air_key: str
    class_token: str
    internal_class: str
    flags: list[str]
    class_source: str | None
    class_source_kind: str | None
    class_sha256: str | None
    java_major: int | None
    super_class: str | None
    spawn_declared_here: bool | None
    flight_models: list[str]
    flight_model_property_class: str | None
    flight_model_verification: str
    cockpit_classes: list[str]
    cockpit_property_class: str | None
    missing_cockpit_classes: list[str]
    player_classification: str
    mesh_names: list[str]
    status: str
    findings: list[str]


def cp_utf8(cp: list[object | None], index: int) -> str:
    try:
        entry = cp[index]
    except IndexError as exc:
        raise ClassFormatError(f"invalid constant-pool index {index}") from exc
    if not entry or entry[0] != 1:
        raise ClassFormatError(f"UTF-8 constant expected at index {index}")
    return str(entry[1])


def cp_class(cp: list[object | None], index: int) -> str:
    if index == 0:
        return ""
    try:
        entry = cp[index]
    except IndexError as exc:
        raise ClassFormatError(f"invalid class index {index}") from exc
    if not entry or entry[0] != 7:
        raise ClassFormatError(f"Class constant expected at index {index}")
    return cp_utf8(cp, int(entry[1]))


def parse_class(path: Path, source_kind: str) -> ClassSummary:
    data = path.read_bytes()
    reader = Reader(data)
    if reader.u4() != 0xCAFEBABE:
        raise ClassFormatError("CAFEBABE magic absent")
    reader.u2()  # minor
    major = reader.u2()
    cp_count = reader.u2()
    cp: list[object | None] = [None]
    index = 1
    while index < cp_count:
        tag = reader.u1()
        if tag == 1:
            raw = reader.take(reader.u2())
            cp.append((tag, raw.decode("utf-8", errors="replace")))
        elif tag in (3, 4):
            cp.append((tag, reader.take(4)))
        elif tag in (5, 6):
            cp.append((tag, reader.take(8)))
            cp.append(None)
            index += 1
        elif tag in (7, 8):
            cp.append((tag, reader.u2()))
        elif tag in (9, 10, 11, 12):
            cp.append((tag, reader.u2(), reader.u2()))
        else:
            raise ClassFormatError(f"unsupported constant-pool tag {tag}")
        index += 1

    reader.u2()  # access flags
    this_class = reader.u2()
    super_class = reader.u2()

    strings: set[str] = set()
    classes: set[str] = set()
    method_owners: set[str] = set()
    for entry in cp[1:]:
        if not entry:
            continue
        tag = int(entry[0])
        if tag == 7:
            classes.add(cp_utf8(cp, int(entry[1])))
        elif tag == 8:
            strings.add(cp_utf8(cp, int(entry[1])))
        elif tag in (10, 11):
            method_owners.add(cp_class(cp, int(entry[1])))

    return ClassSummary(
        name=cp_class(cp, this_class),
        super_name=cp_class(cp, super_class) or None,
        major=major,
        strings=sorted(strings),
        class_refs=sorted(classes),
        method_owners=sorted(method_owners),
        source=str(path.resolve()),
        source_kind=source_kind,
        sha256=hashlib.sha256(data).hexdigest().upper(),
    )


def parse_air_ini(path: Path) -> list[AirEntry]:
    entries: list[AirEntry] = []
    for line_number, raw in enumerate(path.read_text(encoding="latin-1").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("["):
            continue
        tokens = line.split()
        if len(tokens) < 2:
            continue
        entries.append(AirEntry(line_number, tokens[0], tokens[1], tokens[2:]))
    return entries


def internal_name(class_token: str) -> str:
    if class_token.startswith("air."):
        return "com/maddox/il2/objects/air/" + class_token[4:].replace(".", "/")
    return class_token.replace(".", "/")


def cockpit_names(summary: ClassSummary) -> list[str]:
    if "cockpitClass" not in summary.strings:
        return []
    result: set[str] = set()
    for value in summary.strings + summary.class_refs:
        normalized = value.replace(".", "/")
        match = COCKPIT_NAME.match(normalized)
        if match:
            result.add("com/maddox/il2/objects/air/" + match.group(1))
    return sorted(result)


def property_values(summary: ClassSummary, pattern: re.Pattern[str]) -> list[str]:
    return sorted(value.replace("\\", "/") for value in summary.strings if pattern.match(value))


class ClassResolver:
    def __init__(self, files_root: Path, dump_root: Path):
        self.files_root = files_root
        self.dump_root = dump_root
        self.loose: dict[str, list[ClassSummary]] = {}
        self.cache: dict[str, ClassSummary | None] = {}
        self.parse_errors: list[str] = []

    def index_loose(self) -> None:
        candidates = [
            path for path in self.files_root.iterdir()
            if path.is_file() and HEX_NAME.fullmatch(path.name)
        ]
        candidates.extend(self.files_root.rglob("*.class"))
        for path in sorted(set(candidates)):
            try:
                summary = parse_class(path, "loose")
            except (OSError, ClassFormatError) as exc:
                self.parse_errors.append(f"{path}: {exc}")
                continue
            self.loose.setdefault(summary.name, []).append(summary)

    def get(self, name: str) -> ClassSummary | None:
        if name in self.cache:
            return self.cache[name]
        loose = self.loose.get(name, [])
        if loose:
            # Multiple loose definitions are retained as a separate anomaly, but
            # the lexical choice makes reports reproducible without changing data.
            self.cache[name] = sorted(loose, key=lambda item: item.source)[0]
            return self.cache[name]
        dump_path = self.dump_root / Path(name + ".class")
        if dump_path.is_file():
            try:
                self.cache[name] = parse_class(dump_path, "selector-dump")
            except (OSError, ClassFormatError) as exc:
                self.parse_errors.append(f"{dump_path}: {exc}")
                self.cache[name] = None
        else:
            self.cache[name] = None
        return self.cache[name]

    def hierarchy(self, name: str, limit: int = 32) -> list[ClassSummary]:
        result: list[ClassSummary] = []
        visited: set[str] = set()
        current = name
        while current and current not in visited and len(result) < limit:
            visited.add(current)
            summary = self.get(current)
            if summary is None:
                break
            result.append(summary)
            current = summary.super_name or ""
        return result


def loose_flight_model(files_root: Path, reference: str) -> bool:
    clean = reference.split(":", 1)[0].replace("/", "\\")
    return (files_root / Path(clean)).is_file()


def audit_entry(entry: AirEntry, resolver: ClassResolver, files_root: Path) -> AircraftAudit:
    name = internal_name(entry.class_token)
    hierarchy = resolver.hierarchy(name)
    current = hierarchy[0] if hierarchy else None
    findings: list[str] = []
    flags = [token for token in entry.tokens if token.upper() in {"NOQUICK", "NOINFO", "NOREGIMENT"}]

    if current is None:
        findings.append("aircraft class absent from loose files and Selector Dump")
        return AircraftAudit(
            entry.line, entry.key, entry.class_token, name, flags,
            None, None, None, None, None, None, [], None,
            "unverifiable", [], None, [], "unknown", [], "FAIL", findings,
        )

    spawn_here = (
        "com/maddox/il2/objects/air/NetAircraft$SPAWN" in current.class_refs
        or "com/maddox/il2/objects/air/NetAircraft$SPAWN" in current.method_owners
    )

    flight_models: list[str] = []
    flight_owner: str | None = None
    cockpits: list[str] = []
    cockpit_owner: str | None = None
    meshes: list[str] = []
    for summary in hierarchy:
        if not flight_models:
            values = property_values(summary, FLIGHT_MODEL)
            if values:
                flight_models = values
                flight_owner = summary.name
        if not cockpits:
            values = cockpit_names(summary)
            if values:
                cockpits = values
                cockpit_owner = summary.name
        if not meshes:
            values = property_values(summary, MESH_NAME)
            if values:
                meshes = values

    # NetAircraft contains generic cockpit lookup code and references to the
    # CockpitPilot/CockpitGunner base classes.  Those are not an aircraft's
    # Property.set("cockpitClass", ...) declaration and must not turn AI-only
    # aircraft into false player-capable positives.
    if cockpit_owner in GENERIC_COCKPIT_OWNERS:
        cockpits = []
        cockpit_owner = None

    missing_cockpits = [cockpit for cockpit in cockpits if resolver.get(cockpit) is None]
    has_direct_cockpit_property = "cockpitClass" in current.strings
    if cockpits:
        player_classification = "player-capable-static" if cockpit_owner == name else "player-capable-inherited-candidate"
    elif has_direct_cockpit_property:
        player_classification = "cockpit-property-unresolved"
    else:
        player_classification = "probable-ai-only"

    if not flight_models:
        fm_verification = "no-flight-model-reference"
        findings.append("no FlightModels/*.fmd reference found in class hierarchy")
    elif all(loose_flight_model(files_root, value) for value in flight_models):
        fm_verification = "loose-file-present"
    else:
        fm_verification = "reference-only-buttons-not-extracted"
        findings.append("flight-model reference found; internal Buttons entry not yet verified")

    if current.major > 47:
        findings.append(f"Java class major {current.major} exceeds the Java 1.3 target (47)")
    if not spawn_here:
        findings.append("no direct NetAircraft.SPAWN registration found in this class")
    if missing_cockpits:
        findings.append("missing cockpit class(es): " + ", ".join(missing_cockpits))
    if not cockpits:
        findings.append("no usable cockpitClass declaration found; treat as AI-only until runtime proof")

    if current.major > 47 or missing_cockpits or not flight_models:
        status = "FAIL"
    elif not cockpits or not spawn_here or fm_verification.endswith("not-extracted"):
        status = "REVIEW"
    else:
        status = "STATIC_OK"

    return AircraftAudit(
        line=entry.line,
        air_key=entry.key,
        class_token=entry.class_token,
        internal_class=name,
        flags=flags,
        class_source=current.source,
        class_source_kind=current.source_kind,
        class_sha256=current.sha256,
        java_major=current.major,
        super_class=current.super_name,
        spawn_declared_here=spawn_here,
        flight_models=flight_models,
        flight_model_property_class=flight_owner,
        flight_model_verification=fm_verification,
        cockpit_classes=cockpits,
        cockpit_property_class=cockpit_owner,
        missing_cockpit_classes=missing_cockpits,
        player_classification=player_classification,
        mesh_names=meshes,
        status=status,
        findings=findings,
    )


def mark_air_key_collisions(records: list[AircraftAudit]) -> None:
    groups: dict[str, list[AircraftAudit]] = {}
    for record in records:
        groups.setdefault(record.air_key.lower(), []).append(record)
    for group in groups.values():
        if len(group) < 2:
            continue
        classes = {item.internal_class for item in group}
        lines = ", ".join(str(item.line) for item in group)
        if len(classes) == 1:
            message = f"duplicate air.ini key and class at lines {lines}"
            for item in group:
                item.findings.append(message)
                if item.status == "STATIC_OK":
                    item.status = "REVIEW"
        else:
            message = f"ambiguous air.ini key maps to different classes at lines {lines}"
            for item in group:
                item.findings.append(message)
                item.status = "FAIL"


def write_csv(path: Path, records: list[AircraftAudit]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = list(asdict(records[0]).keys()) if records else []
    with path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for record in records:
            row = asdict(record)
            for key, value in row.items():
                if isinstance(value, list):
                    row[key] = " | ".join(str(item) for item in value)
            writer.writerow(row)


def summarize(records: list[AircraftAudit], resolver: ClassResolver) -> dict[str, object]:
    def count(attribute: str) -> dict[str, int]:
        result: dict[str, int] = {}
        for item in records:
            key = str(getattr(item, attribute))
            result[key] = result.get(key, 0) + 1
        return dict(sorted(result.items()))

    duplicate_classes = {
        name: [item.source for item in values]
        for name, values in sorted(resolver.loose.items()) if len(values) > 1
    }
    duplicate_air_keys = {
        group[0].air_key: [
            {"line": item.line, "class": item.internal_class} for item in group
        ]
        for group in (
            [item for item in records if item.air_key.lower() == key]
            for key in sorted({item.air_key.lower() for item in records})
        )
        if len(group) > 1
    }
    return {
        "air_ini_entries": len(records),
        "unique_air_keys": len({item.air_key for item in records}),
        "unique_aircraft_classes": len({item.internal_class for item in records}),
        "status": count("status"),
        "player_classification": count("player_classification"),
        "flight_model_verification": count("flight_model_verification"),
        "direct_spawn_true": sum(item.spawn_declared_here is True for item in records),
        "missing_aircraft_classes": sum(item.class_source is None for item in records),
        "entries_with_missing_cockpit_classes": sum(bool(item.missing_cockpit_classes) for item in records),
        "duplicate_air_keys": duplicate_air_keys,
        "loose_class_parse_errors": resolver.parse_errors,
        "duplicate_loose_classes": duplicate_classes,
    }


def markdown(summary: dict[str, object], records: list[AircraftAudit], air_ini: Path,
             dump_root: Path, buttons: Path) -> str:
    status = summary["status"]
    players = summary["player_classification"]
    fm = summary["flight_model_verification"]
    lines = [
        "# Audit statique des appareils declares dans air.ini",
        "",
        "Ce rapport est genere par `tools/Audit-AirIniAircraft.py`. Il croise la",
        "configuration active, les classes libres prioritaires et les classes recuperees",
        "par Selector Dump. Il ne modifie aucun fichier du jeu.",
        "",
        "## Perimetre et limites",
        "",
        f"- `air.ini` : `{air_ini}` ;",
        f"- dump SFS : `{dump_root}` ;",
        f"- entrees : **{summary['air_ini_entries']}** ;",
        f"- classes d'appareils distinctes : **{summary['unique_aircraft_classes']}** ;",
        f"- fichier Buttons : `{buttons}`, {buttons.stat().st_size if buttons.is_file() else 0} octets ;",
        "- une reference `FlightModels/*.fmd` prouve ce que la classe demande, pas que",
        "  l'entree correspondante existe dans Buttons ; cette derniere preuve attend une",
        "  extraction 4.09m sure et une reconstruction sans perte.",
        "",
        "## Synthese",
        "",
        f"- statut statique : {', '.join(f'{key}={value}' for key, value in status.items())} ;",
        f"- classification cockpit : {', '.join(f'{key}={value}' for key, value in players.items())} ;",
        f"- modeles de vol : {', '.join(f'{key}={value}' for key, value in fm.items())} ;",
        f"- classes d'appareil absentes : **{summary['missing_aircraft_classes']}** ;",
        f"- entrees avec classe de cockpit absente : **{summary['entries_with_missing_cockpit_classes']}**.",
        "",
        "`REVIEW` n'est pas synonyme de panne : il couvre notamment les appareils IA sans",
        "cockpit et tous les modeles encore invérifiables dans Buttons. `FAIL` signale une",
        "incoherence statique concrete ou l'absence d'une reference essentielle.",
        "",
        "## Cas prioritaires",
        "",
        "| Ligne | Entree | Classe | Cockpit | Modele de vol | Statut |",
        "| ---: | --- | --- | --- | --- | --- |",
    ]
    priority_names = {"B-29", "B-29-SP", "KB_29P", "Su-2"}
    priorities = [item for item in records if item.air_key in priority_names]
    for item in priorities:
        cockpit = ", ".join(name.rsplit("/", 1)[-1] for name in item.cockpit_classes) or "aucun"
        models = ", ".join(item.flight_models) or "aucun"
        lines.append(f"| {item.line} | `{item.air_key}` | `{item.class_token}` | {cockpit} | `{models}` | {item.status} |")
    collisions = [
        item for item in records
        if any("air.ini key" in finding for finding in item.findings)
    ]
    lines.extend([
        "",
        "## Cles air.ini dupliquees",
        "",
        "| Ligne | Cle | Classe | Diagnostic |",
        "| ---: | --- | --- | --- |",
    ])
    for item in collisions:
        diagnostic = "; ".join(
            finding for finding in item.findings if "air.ini key" in finding
        )
        lines.append(f"| {item.line} | `{item.air_key}` | `{item.class_token}` | {diagnostic} |")
    no_direct_cockpit = [
        item for item in records
        if item.player_classification != "player-capable-static"
    ]
    lines.extend([
        "",
        "## Appareils sans cockpit direct",
        "",
        "Ces appareils ne doivent pas etre proposes comme choix joueur sans preuve runtime.",
        "Un cockpit herite est signale comme candidat, pas comme validation definitive.",
        "",
        "| Ligne | Entree | Classe | Classification |",
        "| ---: | --- | --- | --- |",
    ])
    for item in no_direct_cockpit:
        lines.append(
            f"| {item.line} | `{item.air_key}` | `{item.class_token}` | "
            f"{item.player_classification} |"
        )
    lines.extend([
        "",
        "Le detail exhaustif des 536 lignes est conserve dans :",
        "",
        "- `manifests/aircraft/air-ini-static-v1.15.json` ;",
        "- `manifests/aircraft/air-ini-static-v1.15.csv`.",
        "",
        "## Utilisation pour les essais",
        "",
        "1. tester d'abord les `FAIL` qui sont proposes au joueur ;",
        "2. tester ensuite les appareils sans cockpit mais visibles dans les menus joueur ;",
        "3. traiter les trois B-29 comme trois variantes distinctes ;",
        "4. ne conclure sur les modeles de vol qu'apres inventaire de Buttons ;",
        "5. conserver les essais runtime pour prouver F1, commandes, cockpit, armements et",
        "   chargement effectif du modele de vol.",
        "",
        "Sources : [role de air.ini dans l'installation d'un avion](https://www.sas1946.com/main/index.php?topic=46778.0),",
        "[role de Buttons et panne vers 60 %](https://www.sas1946.com/main/index.php?topic=21.0),",
        "[discussion sur les doublons et la limite de classes](https://www.sas1946.com/main/index.php?topic=67329.0).",
        "",
    ])
    return "\n".join(lines)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path.cwd())
    parser.add_argument("--dump-root", type=Path, required=True)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--csv", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(argv)

    project = args.project_root.resolve()
    files_root = project / "Files"
    air_ini = files_root / "com/maddox/il2/objects/air.ini"
    buttons = files_root / "gui/GAME/buttons"
    dump_root = args.dump_root.resolve()
    if not air_ini.is_file():
        parser.error(f"air.ini not found: {air_ini}")
    if not dump_root.is_dir():
        parser.error(f"Selector Dump directory not found: {dump_root}")

    resolver = ClassResolver(files_root, dump_root)
    resolver.index_loose()
    records = [audit_entry(entry, resolver, files_root) for entry in parse_air_ini(air_ini)]
    mark_air_key_collisions(records)
    report_summary = summarize(records, resolver)
    payload = {
        "schema": 1,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "project_root": str(project),
        "air_ini": str(air_ini),
        "air_ini_sha256": hashlib.sha256(air_ini.read_bytes()).hexdigest().upper(),
        "selector_dump_root": str(dump_root),
        "buttons": {
            "path": str(buttons),
            "bytes": buttons.stat().st_size if buttons.is_file() else None,
            "sha256": hashlib.sha256(buttons.read_bytes()).hexdigest().upper() if buttons.is_file() else None,
            "content_verified": False,
        },
        "summary": report_summary,
        "aircraft": [asdict(item) for item in records],
    }

    json_path = args.json or project / "manifests/aircraft/air-ini-static-v1.15.json"
    csv_path = args.csv or project / "manifests/aircraft/air-ini-static-v1.15.csv"
    report_path = args.report or project / "docs/AUDIT_APPAREILS_AIR_INI.md"
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_csv(csv_path, records)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        markdown(report_summary, records, air_ini, dump_root, buttons), encoding="utf-8"
    )
    print(json.dumps(report_summary, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
