#!/usr/bin/env python3
"""Validate the development-only IL-2 nuclear particle-capacity A/B probe."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def read_effect(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="latin-1").splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line or line.startswith("["):
            continue
        parts = line.split(None, 1)
        if len(parts) == 2:
            values[parts[0]] = parts[1].strip()
    return values


def add(checks: list[dict[str, Any]], name: str, ok: bool, detail: str) -> None:
    checks.append({"name": name, "status": "PASS" if ok else "FAIL", "detail": detail})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()

    root = args.repository.resolve()
    fixture = root / "test-assets" / "nuclear-particle-ab"
    a_path = fixture / "NuclearParticleCapacity-A.eff"
    b_path = fixture / "NuclearParticleCapacity-B.eff"
    marker = fixture / "_OS_TEST_NUCLEAR_PARTICLE_AB.enabled"
    source_path = root / "tools" / "java" / "nuclear" / "com" / "maddox" / "il2" / "objects" / "effects" / "NuclearBlast.java"
    install_path = root / "tools" / "Install-NuclearParticleABProbe.ps1"
    class_path = args.build.resolve() / "semantic" / "NuclearBlast.class"

    checks: list[dict[str, Any]] = []
    required = [a_path, b_path, marker, source_path, install_path, class_path]
    missing = [str(path) for path in required if not path.is_file()]
    add(checks, "fichiers du banc A/B", not missing, "complets" if not missing else str(missing))
    if missing:
        payload = {"schema": "open-sturmovik-nuclear-particle-ab-v1", "status": "FAIL", "checks": checks}
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 2

    effect_a = read_effect(a_path)
    effect_b = read_effect(b_path)
    ignored_differences = {"Color0", "Color1", "nParticles"}
    physical_a = {key: value for key, value in effect_a.items() if key not in ignored_differences}
    physical_b = {key: value for key, value in effect_b.items() if key not in ignored_differences}
    add(
        checks,
        "variables physiques isolees",
        physical_a == physical_b,
        "seules la capacite et les couleurs d'identification different",
    )
    add(
        checks,
        "capacites A/B",
        effect_a.get("nParticles") == "64" and effect_b.get("nParticles") == "512",
        f"A={effect_a.get('nParticles')}, B={effect_b.get('nParticles')}",
    )
    add(
        checks,
        "fenetre d'observation",
        effect_a.get("FinishTime") == effect_b.get("FinishTime") == "180.0"
        and effect_a.get("LiveTime") == effect_b.get("LiveTime") == "128.0"
        and effect_a.get("EmitFrq") == effect_b.get("EmitFrq") == "100.0",
        "emission 180 s, vie 128 s, observation 310 s",
    )

    runtime_effect_parent = root / "Files" / "3do" / "Effects" / "OpenSturmovikTest"
    material_paths = []
    material_failures = []
    for label, effect in (("A", effect_a), ("B", effect_b)):
        material_name = effect.get("MatName", "")
        material_path = (runtime_effect_parent / material_name).resolve()
        material_paths.append(f"{label}={material_path}")
        try:
            material_path.relative_to(root)
        except ValueError:
            material_failures.append(f"{label}: hors depot ({material_path})")
            continue
        if not material_path.is_file():
            material_failures.append(f"{label}: absent ({material_path})")
    add(
        checks,
        "materiaux resolus dans l'arborescence du jeu",
        not material_failures,
        "; ".join(material_paths) if not material_failures else "; ".join(material_failures),
    )

    source = source_path.read_text(encoding="utf-8")
    required_source_tokens = {
        "marker": "_OS_TEST_NUCLEAR_PARTICLE_AB.enabled",
        "probe A": "NuclearParticleCapacity-A.eff",
        "probe B": "NuclearParticleCapacity-B.eff",
        "suppression des visuels normaux": "currentVisualState.particleCapacityProbe",
        "arret borne": "PARTICLE_PROBE_COMPLETE_MILLISECONDS = 310000L",
        "journal 300 s": "300000L",
    }
    absent_source = [name for name, token in required_source_tokens.items() if token not in source]
    add(
        checks,
        "activation et nettoyage bornes",
        not absent_source,
        "marqueur local, deux effets et checkpoints jusqu'a 300 s" if not absent_source else str(absent_source),
    )

    class_data = class_path.read_bytes()
    class_text = class_data.decode("latin-1", errors="ignore")
    class_ok = (
        class_data[:4] == b"\xca\xfe\xba\xbe"
        and int.from_bytes(class_data[6:8], "big") == 47
        and "java/io/File" in class_text
        and "isFile" in class_text
        and "NuclearParticleCapacity-A.eff" in class_text
        and "NuclearParticleCapacity-B.eff" in class_text
    )
    add(checks, "classe Java 1.3 du banc", class_ok, "major 47 et activation par File.isFile")

    installer = install_path.read_text(encoding="utf-8-sig")
    installer_ok = (
        "Le jeu original est strictement interdit comme cible" in installer
        and "*test*" in installer
        and "[switch]$Disable" in installer
    )
    add(checks, "installation reversible et cible protegee", installer_ok, "stock interdit, cible test exigee, desactivation disponible")

    failed = [check for check in checks if check["status"] == "FAIL"]
    payload = {
        "schema": "open-sturmovik-nuclear-particle-ab-v1",
        "status": "PASS" if not failed else "FAIL",
        "summary": {"checks": len(checks), "pass": len(checks) - len(failed), "fail": len(failed)},
        "checks": checks,
        "protocol": {
            "A": {"color": "red", "nParticles": 64, "offset_x_m": -750},
            "B": {"color": "blue", "nParticles": 512, "offset_x_m": 750},
            "finish_s": 180,
            "particle_life_s": 128,
            "cleanup_s": 310,
            "checkpoints_s": [10, 60, 120, 130, 150, 180, 240, 300],
        },
    }
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"status={payload['status']} checks={len(checks)} pass={len(checks) - len(failed)} fail={len(failed)}")
    for check in checks:
        print(f"{check['status']}: {check['name']} - {check['detail']}")
    return 0 if not failed else 2


if __name__ == "__main__":
    raise SystemExit(main())
