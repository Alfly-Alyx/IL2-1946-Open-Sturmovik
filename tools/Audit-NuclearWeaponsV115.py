#!/usr/bin/env python3
"""Audit the complete Little Boy / Fat Man delivery and effect chain.

The game content is read-only.  The optional JSON and Markdown outputs are
ordinary audit artefacts in the repository; no file in ``Files`` is changed.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


HEX_NAME = re.compile(r"[0-9A-Fa-f]{16}")
EXPECTED_DELIVERY = {
    "com/maddox/il2/objects/air/B_29SP": {
        "file": "7BCE3C02C280ED18",
        "sha256": "0A83344F9617AECF9F2B0B50B06B265E7C41F2A733B226DA32656465AF994992",
    },
    "com/maddox/il2/objects/weapons/BombGunLittleBoy": {
        "file": "C40DA0A681C6554C",
        "sha256": "7A31D3B7E5B0EC4700A137EB84CEFE4DE50D086F9DEE8D32E8A9A1EC463BEDCF",
    },
    "com/maddox/il2/objects/weapons/BombGunFatMan": {
        "file": "46168B5EEE532404",
        "sha256": "8B5AC1B92495BF01811628796E1899F326ABC613B5E3243004A4BF492ED40868",
    },
}
EXPECTED_ASSETS = {
    "Files/3do/Arms/LittleBoy/LittleBoy.msh": "326ECB22BE1AA01BD3F905822DC811EFB0B5B55C7754F310F4D2202915B990DB",
    "Files/3do/Arms/LittleBoy/mono.sim": "21443B4C0B3FD1FFD7869C46667C13BC1CF5480A8594FA91DA7655FE607C74E6",
    "Files/3do/Arms/LittleBoy/skin.mat": "E2CDEFA9D5745668BAFD2FF388CF63792E5372292033735010FFCCFEB422BBBE",
    "Files/3do/Arms/LittleBoy/skin.tga": "BF506AE591A026A2658F799AFD1E79D109ED5362FD7A56EAB8980DD81601C7A0",
    "Files/3do/Arms/FatMan/FatMan.msh": "DD23D9EBAAFD4A6DE8B8C88E65E296F1CCD46079ED34653FF5BDE4C7B87173AA",
    "Files/3do/Arms/FatMan/mono.sim": "4A3D7B10BBEE7B4BFC2787D57C9F807BC52E62636FB54373B70802BA36DD953E",
    "Files/3do/Arms/FatMan/skin.mat": "E2CDEFA9D5745668BAFD2FF388CF63792E5372292033735010FFCCFEB422BBBE",
    "Files/3do/Arms/FatMan/skin.tga": "10F57A424DF5EAC9B2E7B59125371BB6B0E1950F86AD4BA4D6FB7DD89CAFE4FC",
}
REQUIRED_LOADOUT_TOKENS = {
    "LittleBoy",
    "FatMan",
    "BombGunLittleBoy",
    "BombGunFatMan",
    "_BombSpawn01",
    "_BombSpawn02",
    "com.maddox.il2.objects.air.CockpitB29SP",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def load_class_parser(repository: Path):
    source = repository / "tools" / "Audit-JavaClasses.py"
    spec = importlib.util.spec_from_file_location("open_sturmovik_java_audit", source)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load Java parser: {source}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def load_sfs_finger(repository: Path):
    source = repository / "tools" / "Analyze-Sfs.py"
    spec = importlib.util.spec_from_file_location("open_sturmovik_sfs_finger", source)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load SFS fingerprint implementation: {source}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def class_loose_name(finger: Any, dotted_class_name: str) -> str:
    obfuscated = f"sdw{dotted_class_name}cwc2w9e"
    class_hash = finger.finger_int(ord(character) for character in obfuscated)
    fingerprint = finger.finger_string(0, f"cod/{class_hash}")
    return f"{fingerprint & 0xFFFFFFFFFFFFFFFF:016X}"


def class_candidates(files_root: Path) -> list[Path]:
    result = [path for path in files_root.iterdir() if path.is_file() and HEX_NAME.fullmatch(path.name)]
    result.extend(files_root.rglob("*.class"))
    return sorted(set(result))


def index_classes(repository: Path) -> tuple[dict[str, list[dict[str, Any]]], list[str]]:
    parser = load_class_parser(repository)
    result: dict[str, list[dict[str, Any]]] = {}
    errors: list[str] = []
    for path in class_candidates(repository / "Files"):
        data = path.read_bytes()
        if not data.startswith(b"\xCA\xFE\xBA\xBE"):
            continue
        try:
            parsed = parser.parse_class(data)
        except Exception as exc:  # keep the audit useful in a partially recovered tree
            errors.append(f"{path.relative_to(repository)}: {exc}")
            continue
        raw_text = data.decode("latin-1", errors="ignore")
        item = {
            "file": path.relative_to(repository).as_posix(),
            "size": len(data),
            "sha256": hashlib.sha256(data).hexdigest().upper(),
            "java_major": parsed.major,
            "super": parsed.super_name,
            "fields": sorted((field.name, field.descriptor) for field in parsed.fields),
            "methods": sorted((method.name, method.descriptor) for method in parsed.methods),
            "class_refs": sorted(parsed.class_refs),
            "method_refs": sorted(parsed.method_refs),
            "raw_text": raw_text,
        }
        result.setdefault(parsed.name, []).append(item)
    return result, errors


def read_effect(path: Path) -> dict[str, Any]:
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="latin-1").splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line or line.startswith("["):
            continue
        parts = line.split(None, 1)
        if len(parts) == 2:
            values[parts[0]] = parts[1].strip()
    result: dict[str, Any] = {"file": path.as_posix(), "values": values}
    for key in ("nParticles", "FinishTime", "LiveTime", "EmitFrq"):
        if key in values:
            result[key] = float(values[key].rstrip("fF"))
    return result


def material_path(effect_path: Path, material: str) -> Path:
    normalized = material.replace("/", "\\")
    return (effect_path.parent / Path(normalized)).resolve()


def add_check(checks: list[dict[str, str]], name: str, ok: bool, detail: str) -> None:
    checks.append({"name": name, "status": "PASS" if ok else "FAIL", "detail": detail})


def audit(repository: Path, manifest_path: Path) -> dict[str, Any]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    classes, parse_errors = index_classes(repository)
    finger = load_sfs_finger(repository)
    checks: list[dict[str, str]] = []

    output_details: list[dict[str, Any]] = []
    loose_name_errors: list[str] = []
    for expected in manifest["outputs"]:
        internal = expected["class"].replace(".", "/")
        actual_loose_name = Path(expected["file"]).name.upper()
        calculated_loose_name = class_loose_name(finger, expected["class"])
        if actual_loose_name != calculated_loose_name:
            loose_name_errors.append(
                f"{expected['class']}: manifeste={actual_loose_name}, calcule={calculated_loose_name}"
            )
        definitions = classes.get(internal, [])
        matching = [item for item in definitions if item["file"] == expected["file"]]
        valid = (
            len(matching) == 1
            and matching[0]["sha256"] == expected["sha256"]
            and matching[0]["size"] == expected["size"]
            and matching[0]["java_major"] == 47
        )
        add_check(
            checks,
            f"classe generee {expected['class']}",
            valid,
            "empreinte, taille et Java 1.3 conformes" if valid else f"definitions={definitions}",
        )
        output_details.extend(matching)

    add_check(
        checks,
        "adressage SFS des classes generees",
        not loose_name_errors,
        "chaque nom libre correspond a l'empreinte de sa classe Java"
        if not loose_name_errors else "; ".join(loose_name_errors),
    )

    delivery_details: list[dict[str, Any]] = []
    for internal, expected in EXPECTED_DELIVERY.items():
        definitions = classes.get(internal, [])
        expected_path = "Files/" + expected["file"]
        matching = [item for item in definitions if item["file"] == expected_path]
        valid = len(matching) == 1 and matching[0]["sha256"] == expected["sha256"] and matching[0]["java_major"] == 47
        add_check(checks, f"integration {internal.replace('/', '.')}", valid, "classe attendue active" if valid else str(definitions))
        delivery_details.extend(matching)

    b29 = classes.get("com/maddox/il2/objects/air/B_29SP", [{}])[0]
    missing_tokens = sorted(token for token in REQUIRED_LOADOUT_TOKENS if token not in b29.get("raw_text", ""))
    add_check(
        checks,
        "emports B-29 Silverplate",
        not missing_tokens,
        "Little Boy et Fat Man utilisent deux crochets distincts" if not missing_tokens else "tokens absents: " + ", ".join(missing_tokens),
    )
    b29_raw = b29.get("raw_text", "")
    silverplate_pilot = "com.maddox.il2.objects.air.CockpitB29SP" in b29_raw
    stock_pilot = re.search(r"com\.maddox\.il2\.objects\.air\.CockpitB29(?!SP)", b29_raw) is not None
    add_check(
        checks,
        "cockpit pilote B-29 Silverplate",
        silverplate_pilot and not stock_pilot,
        (
            "CockpitB29SP et son maillage B-29-SP remplacent le cockpit B-29 standard incompatible"
            if silverplate_pilot and not stock_pilot
            else f"Silverplate={silverplate_pilot}, ancien_cockpit_standard={stock_pilot}"
        ),
    )

    for gun_name, bomb_name in (
        ("BombGunLittleBoy", "BombLittleBoy"),
        ("BombGunFatMan", "BombFatMan"),
    ):
        gun = classes.get(f"com/maddox/il2/objects/weapons/{gun_name}", [{}])[0]
        required_ref = f"com/maddox/il2/objects/weapons/{bomb_name}"
        dotted_ref = required_ref.replace("/", ".")
        ok = (
            gun.get("super") == "com/maddox/il2/objects/weapons/BombGun"
            and (required_ref in gun.get("class_refs", []) or dotted_ref in gun.get("raw_text", ""))
            and "bulletClass" in gun.get("raw_text", "")
            and "bullets" in gun.get("raw_text", "")
        )
        add_check(
            checks,
            f"liaison {gun_name} -> {bomb_name}",
            ok,
            "une munition, classe de bombe correcte" if ok else f"liaison absente dans {gun.get('file', 'classe absente')}",
        )

    explosions = classes.get("com/maddox/il2/objects/effects/Explosions", [{}])[0]
    explosion_methods = set(tuple(value) for value in explosions.get("methods", []))
    six_arg = (
        "generate",
        "(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V",
    ) in explosion_methods
    registered = any(
        owner == "com/maddox/il2/objects/effects/NuclearBlast" and name == "registerVisual"
        for owner, name, _ in explosions.get("method_refs", [])
    )
    lifecycle_calls = {
        name
        for owner, name, _ in explosions.get("method_refs", [])
        if owner == "com/maddox/il2/objects/effects/NuclearBlast"
    }
    lifecycle_injected = {"beginVisual", "registerVisual", "endVisual"} <= lifecycle_calls
    add_check(
        checks,
        "ABI Silverplate / Zuti",
        six_arg and registered and lifecycle_injected,
        "surcharge a six arguments et transactions visuelles terre/eau presentes",
    )

    msg = classes.get("com/maddox/il2/ai/MsgExplosion", [{}])[0]
    delayed = any(
        owner == "com/maddox/il2/objects/effects/NuclearBlast" and name == "schedule"
        for owner, name, _ in msg.get("method_refs", [])
    )
    add_check(checks, "distribution differee du souffle", delayed, "NuclearBlast.schedule remplace la distribution nucleaire immediate")

    nuclear = classes.get("com/maddox/il2/objects/effects/NuclearBlast", [{}])[0]
    nuclear_refs = nuclear.get("method_refs", [])
    time_methods = {
        name for owner, name, _ in nuclear_refs if owner == "com/maddox/rts/Time"
    }
    simulation_age_only = (
        "current" in time_methods and "currentReal" not in time_methods and "isPaused" not in time_methods
    )
    no_reflection = not any(owner.startswith("java/lang/reflect/") for owner, _, _ in nuclear_refs)
    add_check(
        checks,
        "age visuel fonde uniquement sur la simulation",
        simulation_age_only and no_reflection,
        f"Time={sorted(time_methods)}, reflection={not no_reflection}",
    )

    state = classes.get("com/maddox/il2/objects/effects/NuclearBlast$State", [{}])[0]
    state_fields = {name for name, _ in state.get("fields", [])}
    expected_state_fields = {
        "detonationTime", "position", "altitudeMeters", "groundAltitudeMeters", "yieldKilotonnes", "water",
        "phase", "actors", "actorRoles", "actorsCreated", "actorsDestroyed", "lastVisualTickSimulation",
        "visualTicks", "stabilizedCreated", "transientsRetired", "riseRetired", "emissionComplete", "complete",
        "nextRiseLayerIndex", "riseLayersCreated", "riseLayersSkipped",
    }
    add_check(
        checks,
        "etat nucleaire persistant",
        expected_state_fields <= state_fields,
        "temps, position, altitude, puissance, surface, phase et acteurs suivis",
    )

    destroys_actors = any(name == "postDestroy" for _, name, _ in nuclear_refs)
    clears_references = any(
        owner == "java/util/ArrayList" and name == "clear"
        for owner, name, _ in nuclear_refs
    ) and any(
        owner == "java/util/ArrayList" and name == "remove"
        for owner, name, _ in nuclear_refs
    )
    add_check(
        checks,
        "cycle de vie borne des acteurs",
        destroys_actors and clears_references,
        "postDestroy explicite, listes videes et etats termines retires",
    )

    moving_emitters = [
        f"{owner}.{name}{descriptor}"
        for owner, name, descriptor in nuclear_refs
        if owner == "com/maddox/il2/engine/ActorPos" and name in {"setAbs", "reset"}
    ]
    add_check(
        checks,
        "origines fixes des couches de particules",
        not moving_emitters,
        "aucun Eff3DActor actif n'est deplace apres sa creation"
        if not moving_emitters else str(moving_emitters),
    )

    lifecycle = manifest["model"]["visual_lifecycle"]
    boundaries = lifecycle.get("phase_boundaries_s", [])
    cleanup_deadline = lifecycle.get("cleanup_deadline_s", 0)
    add_check(
        checks,
        "ordre et delai de nettoyage",
        boundaries == sorted(set(boundaries)) and boundaries[-1] < cleanup_deadline <= 3728,
        f"phases={boundaries}, limite={cleanup_deadline}s",
    )

    summit = manifest["model"].get("cloud_summit", {})
    add_check(
        checks,
        "sommets des champignons",
        summit.get("little_boy_m") == 12000 and summit.get("fat_man_m") == 13500,
        f"Little Boy={summit.get('little_boy_m')}m, Fat Man={summit.get('fat_man_m')}m",
    )

    active_air = repository / "Files" / "com" / "maddox" / "il2" / "objects" / "air.ini"
    air_text = active_air.read_text(encoding="latin-1")
    air_rows = [line.split() for line in air_text.splitlines() if line.strip() and not line.lstrip().startswith((";", "["))]
    b29_rows = [row for row in air_rows if len(row) >= 2 and row[0] == "B-29-SP" and row[1] == "air.B_29SP"]
    add_check(checks, "declaration air.ini", len(b29_rows) == 1, f"occurrences valides={len(b29_rows)}")

    asset_details: list[dict[str, Any]] = []
    for relative, expected_hash in EXPECTED_ASSETS.items():
        path = repository / Path(relative)
        actual = sha256(path) if path.is_file() else None
        ok = actual == expected_hash
        add_check(checks, f"ressource {relative}", ok, "identique au paquet Silverplate v1.2" if ok else f"sha256={actual}")
        asset_details.append({"file": relative, "sha256": actual, "expected_sha256": expected_hash, "match": ok})

    visual_details: list[dict[str, Any]] = []
    expected_visuals = {item["file"]: item for item in manifest["visual_outputs"]}
    material_errors: list[str] = []
    for relative, expected in expected_visuals.items():
        path = repository / Path(relative)
        current_hash = sha256(path) if path.is_file() else None
        parsed = read_effect(path) if path.is_file() else {"file": relative}
        parsed["file"] = relative
        parsed["sha256"] = current_hash
        parsed["expected_sha256"] = expected["sha256"]
        parsed["match"] = current_hash == expected["sha256"] and path.stat().st_size == expected["size"] if path.is_file() else False
        if path.is_file() and "MatName" in parsed.get("values", {}):
            target = material_path(path, parsed["values"]["MatName"])
            parsed["material"] = target.relative_to(repository).as_posix() if repository in target.parents else str(target)
            parsed["material_exists"] = target.is_file()
            if not target.is_file():
                material_errors.append(f"{relative} -> {target}")
        visual_details.append(parsed)

    visuals_ok = all(item.get("match") for item in visual_details)
    limits_ok = all(item.get("nParticles", 0) <= 512 and item.get("LiveTime", 0) <= 128 for item in visual_details)
    add_check(checks, "empreintes des dix effets", visuals_ok, "effets visuels conformes au manifeste")
    add_check(checks, "limites du moteur d'effets", limits_ok, "nParticles <= 512 et LiveTime <= 128 pour chaque emetteur")
    add_check(checks, "materiaux des effets", not material_errors, "tous les MatName se resolvent" if not material_errors else "; ".join(material_errors))

    duplicate_required: dict[str, list[str]] = {}
    required_names = {item["class"].replace(".", "/") for item in manifest["outputs"]} | set(EXPECTED_DELIVERY)
    for name in sorted(required_names):
        if len(classes.get(name, [])) > 1:
            duplicate_required[name] = [item["file"] for item in classes[name]]
    add_check(checks, "unicite des classes nucleaires", not duplicate_required, "aucune definition libre concurrente" if not duplicate_required else str(duplicate_required))

    latest_capture = repository / "WIP" / "captures" / "startup" / "20260903-160537Z-profile9-warm-windowed1024-startup"
    observations: list[str] = []
    timeline = latest_capture / "timeline.csv"
    if timeline.is_file():
        with timeline.open(encoding="utf-8-sig", newline="") as stream:
            for row in csv.DictReader(stream):
                if row.get("event") in {"manual_observation", "critical_trigger_armed", "manual_test_marker"}:
                    observations.append(row.get("detail", ""))

    failed = sum(check["status"] == "FAIL" for check in checks)
    return {
        "schema_version": 1,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "repository": str(repository),
        "static_status": "PASS" if failed == 0 else "FAIL",
        "release_status": "BLOCKED_RUNTIME_AND_LICENSE",
        "summary": {
            "checks": len(checks),
            "pass": len(checks) - failed,
            "fail": failed,
            "parse_errors": len(parse_errors),
        },
        "checks": checks,
        "generated_classes": [{key: value for key, value in item.items() if key != "raw_text"} for item in output_details],
        "delivery_classes": [{key: value for key, value in item.items() if key != "raw_text"} for item in delivery_details],
        "weapon_assets": asset_details,
        "effects": visual_details,
        "duplicate_required_classes": duplicate_required,
        "class_parse_errors": parse_errors,
        "runtime_evidence": {
            "capture": latest_capture.relative_to(repository).as_posix(),
            "observations": observations,
            "conclusion": "the moving-emitter candidate remained responsive but split the rising origin from its world-fixed particle mass; the replacement uses bounded fixed layers and is pending runtime validation",
        },
        "known_release_blockers": [
            "Le nouveau rendu par couches fixes n'est pas encore valide dans IL-2 apres pause/reprise et sortie puis retour dans le champ de la camera.",
            "Le masquage camera peut encore relancer l'emetteur de la phase courante ; il ne doit cependant plus pouvoir rejouer la detonation complete apres une seconde.",
            "Les compteurs runtime doivent confirmer que tous les acteurs crees sont detruits et qu'aucun etat ne subsiste apres 3 600 secondes simulees.",
            "Les sommets cibles de 12 km et 13,5 km sont implantes mais leur placement visuel doit etre confirme en jeu.",
            "Fat Man avec/sans pause, les deux airbursts sur l'eau, la visibilite image par image du flash et l'autorite multijoueur exigent encore un essai dedie.",
            "Les blessures thermiques, le rayonnement ionisant, les retombees et la turbulence persistante du panache ne sont pas implementes.",
            "Silverplate v1.2 n'a pas de licence publiee et n'accorde aucune autorisation de redistribution ; une permission explicite, une installation externe ou un remplacement est requis avant publication.",
        ],
    }


def markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Audit complet Little Boy / Fat Man pour la v1.15",
        "",
        f"Derniere generation : {payload['generated_utc']}.",
        "",
        "## Verdict",
        "",
        f"- coherence statique : **{payload['static_status']}** ({payload['summary']['pass']} controles reussis, {payload['summary']['fail']} echec) ;",
        "- aptitude a publier : **BLOQUEE PAR LA VALIDATION EN JEU ET L'ABSENCE DE LICENCE SILVERPLATE** ;",
        "- l'ancien gel Silverplate/Zuti et l'erreur d'ABI de la secousse sont corriges ;",
        "- le prototype a emetteur mobile a ete rejete apres capture ; son remplacement par couches fixes bornees reussit les controles hors jeu, mais son comportement camera/pause reste a valider en vol.",
        "",
        "Le mot `PASS` ne couvre que les fichiers, les liaisons Java et les limites",
        "statiques. Il ne signifie pas que l'effet visuel final est valide.",
        "",
        "## Controles statiques",
        "",
        "| Controle | Etat | Detail |",
        "| --- | --- | --- |",
    ]
    for check in payload["checks"]:
        lines.append(f"| {check['name']} | **{check['status']}** | {check['detail']} |")
    lines.extend([
        "",
        "## Ce qui empeche encore la validation v1.15",
        "",
    ])
    lines.extend(f"- {item}" for item in payload["known_release_blockers"])
    lines.extend([
        "",
        "## Sources de realisme retenues",
        "",
        "- [Chronologie NPS des bombardements](https://www.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm) : Little Boy explose a environ 600 m et le diametre maximal de la boule de feu est atteint vers une seconde ;",
        "- [Histoire du projet Manhattan, Department of Energy](https://www.energy.gov/sites/default/files/maprod/documents/DE99001330.pdf) : Fat Man, 21 kt, explosion a 1 650 pieds ;",
        "- [Guide HHS/REMM](https://remm.hhs.gov/PlanningGuidanceNuclearDetonation.pdf) : pour 10 kt, rayons de reference 20/10/5/2 psi = 0,48/0,71/0,97/1,8 km ;",
        "- [Rapport OSTI sur Hiroshima et Nagasaki](https://www.osti.gov/opennet/servlets/purl/16009191-5O5srR/16009191.pdf) : maximum du nuage vers dix minutes et 40 000 a 50 000 pieds.",
        "- [The Effects of Nuclear Weapons, edition officielle GovInfo](https://www.govinfo.gov/content/pkg/GOVPUB-D-PURL-gpo106759/pdf/GOVPUB-D-PURL-gpo106759.pdf) : stabilisation vers dix minutes, visibilite possible pendant une heure ou davantage et, sous environ 20 kt, rayon de la tige voisin de la moitie du rayon du nuage.",
        "",
        "## Prochain essai cible",
        "",
        "Le prochain essai nucleaire ne doit pas etre un simple largage libre. Il devra",
        "capturer Little Boy puis Fat Man, sans pause et avec pause, un demi-tour complet,",
        "un passage hors champ, la visibilite image par image du flash, puis un airburst",
        "sur l'eau. La mission dense doit en plus mesurer le nombre d'acteurs d'effets",
        "encore vivants apres plusieurs explosions.",
        "",
        "Rapport machine : `manifests/effects/nuclear-static-audit-v1.15.json`.",
        "",
    ])
    return "\n".join(lines)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--require-static-pass", action="store_true")
    args = parser.parse_args(argv)

    repository = args.repository.resolve()
    manifest = (args.manifest or repository / "manifests" / "effects" / "nuclear-blast-v1.15.json").resolve()
    payload = audit(repository, manifest)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(markdown(payload), encoding="utf-8")
    print(
        f"static={payload['static_status']} pass={payload['summary']['pass']} "
        f"fail={payload['summary']['fail']} release={payload['release_status']}"
    )
    return 2 if args.require_static_pass and payload["static_status"] != "PASS" else 0


if __name__ == "__main__":
    raise SystemExit(main())
