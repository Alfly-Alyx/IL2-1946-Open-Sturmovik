#!/usr/bin/env python3
"""Compare historical AAA flyable-aircraft overrides with Open Sturmovik.

The AAA Community Installer is treated as a read-only provenance source.  The
script never copies game data.  It identifies JVM classes by their internal
name (not by their obfuscated on-disk filename), then reports whether a
historical override and all of its directly referenced cockpit classes are
already present in the v1.15 loose-file layer.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


def load_air_audit_module(project: Path):
    source = project / "tools" / "Audit-AirIniAircraft.py"
    spec = importlib.util.spec_from_file_location("air_ini_audit", source)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {source}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def class_candidates(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.suffix.casefold() != ".class" and not re.fullmatch(
            r"[0-9a-fA-F]{16}", path.name
        ):
            continue
        if not path.is_file():
            continue
        try:
            if path.stat().st_size < 10 or path.stat().st_size > 8 * 1024 * 1024:
                continue
            with path.open("rb") as stream:
                if stream.read(4) == b"\xCA\xFE\xBA\xBE":
                    yield path
        except OSError:
            continue


def package_name(mods_root: Path, path: Path) -> str:
    try:
        relative = path.relative_to(mods_root)
    except ValueError:
        return ""
    return relative.parts[0] if relative.parts else ""


def index_classes(module, root: Path, source_kind: str):
    result = defaultdict(list)
    errors: list[str] = []
    for path in class_candidates(root):
        try:
            item = module.parse_class(path, source_kind)
        except (OSError, module.ClassFormatError) as exc:
            errors.append(f"{path}: {exc}")
            continue
        result[item.name].append(item)
    return dict(result), errors


def direct_cockpits(module, item) -> list[str]:
    return module.cockpit_names(item)


def normalize_asset(value: str) -> str | None:
    value = value.replace("\\", "/")
    lower = value.lower()
    if lower.startswith(("3do/", "paintschemes/", "samples/", "presets/")):
        return value
    return None


def asset_exists_case_insensitive(root: Path, relative: str) -> bool:
    current = root
    for component in Path(relative).parts:
        if not current.is_dir():
            return False
        target = component.casefold()
        match = next((p for p in current.iterdir() if p.name.casefold() == target), None)
        if match is None:
            return False
        current = match
    return current.exists()


def current_class_index(module, project: Path, dump_root: Path):
    resolver = module.ClassResolver(project / "Files", dump_root)
    resolver.index_loose()
    return resolver


def build_record(module, aircraft: dict, aaa_index: dict, current_resolver,
                 aaa_mods: Path, project: Path) -> dict:
    internal = aircraft["internal_class"]
    candidates = aaa_index.get(internal, [])
    current = current_resolver.get(internal)
    definitions = []
    for candidate in sorted(candidates, key=lambda item: item.source.casefold()):
        cockpits = direct_cockpits(module, candidate)
        assets = sorted({
            normalized
            for value in candidate.strings
            if (normalized := normalize_asset(value)) is not None
        })
        cockpit_dependencies = []
        for cockpit in cockpits:
            aaa_versions = aaa_index.get(cockpit, [])
            cockpit_dependencies.append({
                "internal_class": cockpit,
                "present_in_aaa": bool(aaa_versions),
                "aaa_sources": [item.source for item in aaa_versions],
                "present_in_open_sturmovik": current_resolver.get(cockpit) is not None,
            })
        definitions.append({
            "source": candidate.source,
            "aaa_package": package_name(aaa_mods, Path(candidate.source)),
            "sha256": candidate.sha256,
            "java_major": candidate.major,
            "super_class": candidate.super_name,
            "direct_cockpit_classes": cockpits,
            "cockpit_dependencies": cockpit_dependencies,
            "assets_referenced": [
                {
                    "path": asset,
                    "present_in_open_sturmovik_loose_files": asset_exists_case_insensitive(
                        project / "Files", asset
                    ),
                }
                for asset in assets
            ],
            "same_binary_as_open_sturmovik": bool(current and current.sha256 == candidate.sha256),
        })
    flyable = [item for item in definitions if item["direct_cockpit_classes"]]
    complete = [
        item for item in flyable
        if all(dep["present_in_aaa"] or dep["present_in_open_sturmovik"]
               for dep in item["cockpit_dependencies"])
    ]
    return {
        "line": aircraft["line"],
        "air_key": aircraft["air_key"],
        "internal_class": internal,
        "current_sha256": current.sha256 if current else None,
        "current_java_major": current.major if current else None,
        "current_player_classification": aircraft["player_classification"],
        "aaa_definitions": definitions,
        "aaa_direct_flyable_override_found": bool(flyable),
        "aaa_direct_flyable_override_dependency_complete": bool(complete),
        "decision": (
            "historical-flyable-set-restored"
            if any(item["same_binary_as_open_sturmovik"] for item in complete) else
            "historical-flyable-set-candidate"
            if complete else
            "aaa-definition-without-direct-cockpit"
            if definitions else
            "not-found-in-aaa-community-installer-1.1"
        ),
    }


def render_markdown(payload: dict) -> str:
    lines = [
        "# Audit des cockpits historiques AAA Community Installer 1.1",
        "",
        "Ce rapport est genere par `tools/Audit-AAACommunityCockpits.py`. La source",
        "AAA est analysee en lecture seule : aucun fichier n'est copie automatiquement.",
        "Une ligne `air.ini` ne suffit pas a rendre un avion pilotable ; il faut une",
        "surcharge de classe coherente, ses classes cockpit, ses modeles 3D et un modele",
        "de vol compatible avec Buttons.",
        "",
        "## Source et methode",
        "",
        f"- source AAA : `{payload['aaa_root']}` ;",
        f"- classes JVM AAA inventoriees : **{payload['summary']['aaa_class_files']}** ;",
        f"- noms de classes distincts : **{payload['summary']['aaa_internal_classes']}** ;",
        "- comparaison faite par nom interne JVM et SHA-256, jamais par le seul nom",
        "  obfusque du fichier ;",
        "- la presence d'un ensemble ne valide pas encore le modele de vol dans Buttons",
        "  ni le comportement en mission.",
        "",
        "## Resultat sur les appareils initialement sans cockpit direct",
        "",
        "| Ligne | Cle | Classe | Paquet AAA | Cockpit AAA | Decision |",
        "| ---: | --- | --- | --- | --- | --- |",
    ]
    for record in payload["aircraft"]:
        flyable_defs = [
            item for item in record["aaa_definitions"] if item["direct_cockpit_classes"]
        ]
        packages = ", ".join(sorted({item["aaa_package"] for item in flyable_defs})) or "—"
        cockpits = ", ".join(sorted({
            cockpit.rsplit("/", 1)[-1]
            for item in flyable_defs for cockpit in item["direct_cockpit_classes"]
        })) or "—"
        lines.append(
            f"| {record['line']} | `{record['air_key']}` | "
            f"`{record['internal_class'].rsplit('/', 1)[-1]}` | {packages} | "
            f"{cockpits} | {record['decision']} |"
        )
    lines.extend([
        "",
        "## Paquets historiques candidats",
        "",
    ])
    for package, details in payload["candidate_packages"].items():
        lines.extend([
            f"### {package}",
            "",
            f"- classes Java : **{len(details['classes'])}** ;",
            f"- ressources non Java : **{len(details['resources'])}** ;",
            f"- references directes de classes non resolues : "
            f"**{len(details['unresolved_direct_class_references'])}** ;",
            "- toutes les classes du paquet ciblent Java major "
            + ", ".join(str(value) for value in sorted({c['java_major'] for c in details['classes']}))
            + ".",
            "",
            "| Classe interne | Deja dans Open Sturmovik | Binaire identique |",
            "| --- | --- | --- |",
        ])
        for item in details["classes"]:
            lines.append(
                f"| `{item['internal_class'].rsplit('/', 1)[-1]}` | "
                f"{'oui' if item['present_in_open_sturmovik'] else 'non'} | "
                f"{'oui' if item['same_binary_as_open_sturmovik'] else 'non'} |"
            )
    lines.extend([
        "",
        "## Regle de restauration",
        "",
        "Un ensemble AAA ne peut etre restaure dans `Files` qu'apres controle de toutes",
        "ses classes cockpit et ressources, verification Java 1.3 (major <= 47), controle",
        "de la correspondance Buttons/FMD et essai runtime F1/commandes/armements. Les",
        "appareils absents de cette source restent IA tant qu'un paquet communautaire",
        "authentique et complet n'a pas ete retrouve ; aucun cockpit ne sera invente.",
        "",
        "Le detail avec chemins, empreintes et dependances est conserve dans",
        "`manifests/aircraft/aaa-community-cockpits-v1.15.json`.",
        "",
    ])
    return "\n".join(lines)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path.cwd())
    parser.add_argument("--aaa-root", type=Path, required=True)
    parser.add_argument("--air-audit", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(argv)

    project = args.project_root.resolve()
    aaa_root = args.aaa_root.resolve()
    aaa_mods = aaa_root / "MODS"
    if not aaa_mods.is_dir():
        parser.error(f"AAA MODS directory not found: {aaa_mods}")
    air_audit_path = args.air_audit or project / "manifests/aircraft/air-ini-static-v1.15.json"
    air_audit = json.loads(air_audit_path.read_text(encoding="utf-8"))
    dump_root = Path(air_audit["selector_dump_root"])
    module = load_air_audit_module(project)

    aaa_index, parse_errors = index_classes(module, aaa_mods, "aaa-community-1.1")
    current_resolver = current_class_index(module, project, dump_root)
    probable_ai = [
        item for item in air_audit["aircraft"]
        if item["player_classification"] == "probable-ai-only"
    ]
    restored_targets = {'TBF-1C', 'TBM-3', 'Pokryshkins_MiG-3', 'Su-2'}
    suspects = probable_ai + [
        item for item in air_audit["aircraft"]
        if item["air_key"] in restored_targets and item not in probable_ai
    ]
    records = [
        build_record(module, item, aaa_index, current_resolver, aaa_mods, project)
        for item in suspects
    ]
    candidate_package_names = sorted({
        definition["aaa_package"]
        for record in records
        for definition in record["aaa_definitions"]
        if definition["direct_cockpit_classes"]
    })
    candidate_packages = {}
    for name in candidate_package_names:
        package_root = aaa_mods / name
        classes = []
        package_internal_names = {
            internal
            for internal, definitions in aaa_index.items()
            if any(package_name(aaa_mods, Path(item.source)) == name for item in definitions)
        }
        missing_class_dependencies: set[str] = set()
        for internal, definitions in aaa_index.items():
            for definition in definitions:
                if package_name(aaa_mods, Path(definition.source)) != name:
                    continue
                current = current_resolver.get(internal)
                unresolved_refs = []
                for reference in definition.class_refs:
                    if reference.startswith(("java/", "[")):
                        continue
                    if reference in package_internal_names or current_resolver.get(reference) is not None:
                        continue
                    unresolved_refs.append(reference)
                    missing_class_dependencies.add(reference)
                classes.append({
                    "internal_class": internal,
                    "source": definition.source,
                    "sha256": definition.sha256,
                    "java_major": definition.major,
                    "super_class": definition.super_name,
                    "direct_cockpit_classes": direct_cockpits(module, definition),
                    "present_in_open_sturmovik": current is not None,
                    "same_binary_as_open_sturmovik": bool(
                        current and current.sha256 == definition.sha256
                    ),
                    "unresolved_direct_class_references": sorted(unresolved_refs),
                })
        resources = []
        class_paths = {
            Path(item["source"]).resolve() for item in classes
        }
        for path in package_root.rglob("*"):
            if not path.is_file() or path.resolve() in class_paths:
                continue
            resources.append({
                "relative_path": str(path.relative_to(package_root)).replace("\\", "/"),
                "bytes": path.stat().st_size,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest().upper(),
            })
        candidate_packages[name] = {
            "root": str(package_root),
            "classes": sorted(classes, key=lambda item: item["internal_class"]),
            "resources": sorted(resources, key=lambda item: item["relative_path"].casefold()),
            "unresolved_direct_class_references": sorted(missing_class_dependencies),
        }
    payload = {
        "schema": 1,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "project_root": str(project),
        "aaa_root": str(aaa_root),
        "aaa_root_read_only_source": True,
        "summary": {
            "air_ini_probable_ai_rows": len(probable_ai),
            "air_ini_probable_ai_unique_classes": len({r["internal_class"] for r in probable_ai}),
            "aircraft_rows_audited": len(records),
            "aaa_class_files": sum(len(items) for items in aaa_index.values()),
            "aaa_internal_classes": len(aaa_index),
            "aaa_direct_flyable_candidates": sum(
                r["decision"] == "historical-flyable-set-candidate" for r in records
            ),
            "aaa_historical_flyable_sets_restored": sum(
                r["decision"] == "historical-flyable-set-restored" for r in records
            ),
            "aaa_parse_errors": parse_errors,
        },
        "aircraft": records,
        "candidate_packages": candidate_packages,
    }
    json_path = args.json or project / "manifests/aircraft/aaa-community-cockpits-v1.15.json"
    report_path = args.report or project / "docs/AUDIT_AAA_COCKPITS_V1.15.md"
    json_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    report_path.write_text(render_markdown(payload), encoding="utf-8")
    print(json.dumps(payload["summary"], indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
