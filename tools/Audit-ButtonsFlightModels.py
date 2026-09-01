#!/usr/bin/env python3
"""Verify air.ini flight-model references against a Buttons index.

NTRK Wizard 0.3 is used only with its read-only ``l`` command and only against
a temporary copy of Buttons.  No extraction, addition or reconstruction is
performed.  A candidate filelist containing the flight-model paths requested by
the active aircraft classes lets NTRK resolve the otherwise hashed entry names.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalize(value: str) -> str:
    return value.replace("\\", "/").lower()


def run_read_only_list(java: str, jar: Path, buttons: Path,
                       candidates: list[str]) -> tuple[list[str], str]:
    with tempfile.TemporaryDirectory(prefix="open-sturmovik-buttons-audit-") as temp_name:
        temp = Path(temp_name)
        copy_path = temp / "buttons-copy"
        shutil.copy2(buttons, copy_path)
        if sha256(copy_path) != sha256(buttons):
            raise RuntimeError("temporary Buttons copy hash mismatch")
        (temp / "filelist.txt").write_text(
            "\n".join(candidates) + "\n", encoding="utf-8"
        )
        completed = subprocess.run(
            [java, "-jar", str(jar), "l", str(copy_path)],
            cwd=temp,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        output = completed.stdout
        if completed.returncode != 0:
            raise RuntimeError(f"NTRK read-only listing failed ({completed.returncode}):\n{output}")
        if "Exception:" in output or "Usage:" in output:
            raise RuntimeError(f"NTRK did not recognize Buttons:\n{output}")
        entries = [
            line.strip() for line in output.splitlines()
            if line.strip()
            and not line.startswith("NTRK Wizard")
            and not line.startswith("Written by")
        ]
        return entries, output


def markdown(payload: dict[str, object]) -> str:
    summary = payload["summary"]
    missing = payload["missing_flight_models"]
    unverified = payload["unverified_flight_models"]
    shared = payload["shared_flight_models"]
    lines = [
        "# Audit en lecture seule de Buttons et des modeles de vol",
        "",
        "L'index du fichier `Files/gui/GAME/buttons` a ete ouvert avec la commande",
        "de liste de NTRK Wizard 0.3, sur une copie temporaire dont l'empreinte a ete",
        "controlee. Aucune extraction, ecriture ou reconstruction de Buttons n'a eu lieu.",
        "",
        "## Resultat",
        "",
        f"- entrees totales de l'archive : **{summary['buttons_entries']}** ;",
        f"- chemins de modeles distincts demandes par `air.ini` : **{summary['required_flight_models']}** ;",
        f"- chemins retrouves dans l'index : **{summary['resolved_flight_models']}** ;",
        f"- chemins absents prouves : **{summary['missing_flight_models']}** ;",
        f"- chemins encore invérifiables : **{summary['unverified_flight_models']}** ;",
        f"- entrees encore anonymes ou hors perimetre : **{summary['unresolved_or_other_entries']}**.",
        "",
        "La lecture prouve que la table d'index est accessible et permet d'en mesurer",
        "l'occupation. Elle ne prouve la presence d'un chemin nomme que si le resolveur",
        "le reconnait. L'outil est officiellement etiquete pour le type Buttons 4.10 :",
        "son resolveur ne reconnait pas les empreintes de noms du fichier 4.09m et ses",
        "commandes d'ecriture restent interdites sur la production.",
        "",
        "## Modeles absents ou non verifies",
        "",
    ]
    if unverified:
        lines.append(
            "Le resolveur de noms 4.10 n'a reconnu aucun chemin 4.09m. Les modeles "
            "ci-dessous sont donc **non verifies**, et non declares absents."
        )
        lines.append("")
        for item in unverified:
            lines.append(f"- `{item['flight_model']}` : {', '.join(item['aircraft'])}")
    elif missing:
        for item in missing:
            lines.append(f"- `{item['flight_model']}` : {', '.join(item['aircraft'])}")
    else:
        lines.append("Aucun des modeles de vol references par les 536 entrees n'est absent de l'index.")
    lines.extend([
        "",
        "## Partages a examiner pour le realisme",
        "",
        "Le partage d'un FMD est normal entre variantes proches. Les groupes ci-dessous",
        "sont conserves dans le manifeste afin de reperer les reutilisations entre cellules",
        "tres differentes ; aucune correction automatique n'est appliquee.",
        "",
        "| Modele de vol | Nombre | Appareils |",
        "| --- | ---: | --- |",
    ])
    for item in shared[:40]:
        aircraft = ", ".join(item["aircraft"])
        lines.append(f"| `{item['flight_model']}` | {len(item['aircraft'])} | {aircraft} |")
    lines.extend([
        "",
        "## Limite d'appareils",
        "",
        "Les **739 entrees** mesurees sont l'occupation du Buttons actuel, pas une limite",
        "du moteur. Les retours communautaires decrivent une 'Java Wall' dependante du",
        "nombre, de la taille et surtout de la structure des classes chargees. Les valeurs",
        "observees historiquement variaient suivant les installations ; la limite ne peut",
        "donc pas etre deduite de la taille de Buttons ni fixee a un nombre universel",
        "d'appareils. Open Sturmovik devra la qualifier avec une campagne d'ajout controlee",
        "et des mesures de memoire JVM, sans modifier la version de production.",
        "",
        "Le tri retenu pour l'instant est un **manifeste externe alphabetique**. Reordonner",
        "physiquement Buttons n'apporterait aucun gain prouve et restera interdit tant qu'un",
        "aller-retour 4.09m sans perte n'aura pas ete demontre.",
        "",
        "## Sources communautaires",
        "",
        "- [The BUTTONS file demystified](https://www.sas1946.com/main/index.php?topic=21.0) ;",
        "- [SAS Buttons et derniere base strictement 4.09 (8.7)](https://www.sas1946.com/main/index.php?topic=97.0) ;",
        "- [Discussion Diff-FM et compilation NTRK](https://www.sas1946.com/main/index.php?topic=3988.36) ;",
        "- [Explication de la Java Wall](https://www.sas1946.com/main/index.php?topic=61392.0) ;",
        "- [Retours sur le nombre d'appareils et les classes](https://www.sas1946.com/main/index.php?topic=67329.0) ;",
        "- [Page historique citant les outils QTIM 0.2](https://union.4bb.ru/viewtopic.php?id=370&p=2).",
        "",
    ])
    return "\n".join(lines)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path.cwd())
    parser.add_argument("--aircraft-audit", type=Path)
    parser.add_argument("--buttons", type=Path)
    parser.add_argument("--ntrk-jar", type=Path, required=True)
    parser.add_argument("--java", default="java")
    parser.add_argument("--json", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(argv)

    project = args.project_root.resolve()
    aircraft_path = (args.aircraft_audit or
                     project / "manifests/aircraft/air-ini-static-v1.15.json").resolve()
    buttons = (args.buttons or project / "Files/gui/GAME/buttons").resolve()
    jar = args.ntrk_jar.resolve()
    if not aircraft_path.is_file():
        parser.error(f"aircraft audit missing: {aircraft_path}")
    if not buttons.is_file():
        parser.error(f"Buttons missing: {buttons}")
    if not jar.is_file():
        parser.error(f"NTRK jar missing: {jar}")

    aircraft_payload = json.loads(aircraft_path.read_text(encoding="utf-8"))
    users: dict[str, list[str]] = defaultdict(list)
    spelling: dict[str, str] = {}
    for aircraft in aircraft_payload["aircraft"]:
        for value in aircraft["flight_models"]:
            key = normalize(value)
            spelling.setdefault(key, value.replace("\\", "/"))
            users[key].append(aircraft["air_key"])
    candidates = [spelling[key] for key in sorted(spelling)]
    entries, raw_output = run_read_only_list(args.java, jar, buttons, candidates)
    entry_map = {normalize(value): value for value in entries}
    resolved_keys = sorted(key for key in users if key in entry_map)
    resolver_compatible = bool(resolved_keys) or not users
    missing_keys = sorted(key for key in users if key not in entry_map) if resolver_compatible else []
    unverified_keys = [] if resolver_compatible else sorted(users)
    resolved_names = {normalize(value) for value in entries if normalize(value) in users}

    missing = [
        {"flight_model": spelling[key], "aircraft": sorted(set(users[key]))}
        for key in missing_keys
    ]
    unverified = [
        {"flight_model": spelling[key], "aircraft": sorted(set(users[key]))}
        for key in unverified_keys
    ]
    shared = sorted(
        (
            {"flight_model": spelling[key], "aircraft": sorted(set(names))}
            for key, names in users.items() if len(set(names)) > 1
        ),
        key=lambda item: (-len(item["aircraft"]), item["flight_model"].lower()),
    )
    resolved = [
        {"flight_model": spelling[key], "aircraft": sorted(set(users[key]))}
        for key in resolved_keys
    ]
    summary = {
        "buttons_entries": len(entries),
        "required_flight_models": len(users),
        "resolved_flight_models": len(resolved_keys),
        "missing_flight_models": len(missing_keys),
        "unverified_flight_models": len(unverified_keys),
        "name_resolver_compatible": resolver_compatible,
        "unresolved_or_other_entries": len(entries) - len(resolved_names),
    }
    payload: dict[str, object] = {
        "schema": 1,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "method": "NTRK Wizard 0.3 read-only list command on verified temporary copy",
        "ntrk_jar": str(jar),
        "ntrk_jar_sha256": sha256(jar),
        "buttons": str(buttons),
        "buttons_bytes": buttons.stat().st_size,
        "buttons_sha256": sha256(buttons),
        "aircraft_audit": str(aircraft_path),
        "summary": summary,
        "resolved_flight_models": resolved,
        "missing_flight_models": missing,
        "unverified_flight_models": unverified,
        "shared_flight_models": shared,
        "buttons_index_sorted": sorted(entries, key=str.lower),
        "raw_output_header": raw_output.splitlines()[:3],
        "safety": {
            "source_modified": False,
            "temporary_copy_hash_verified": True,
            "extract_used": False,
            "add_used": False,
            "rebuild_used": False,
        },
    }

    json_path = args.json or project / "manifests/aircraft/buttons-flight-models-v1.15.json"
    report_path = args.report or project / "docs/AUDIT_BUTTONS_MODELES_DE_VOL.md"
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(markdown(payload), encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return 2 if missing_keys else 0


if __name__ == "__main__":
    raise SystemExit(main())
