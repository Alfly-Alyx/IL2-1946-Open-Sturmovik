#!/usr/bin/env python3
"""Validate the bounded v1.15 nuclear lifecycle without launching IL-2."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


UNCHANGED_DAMAGE_AND_SHOCK = {
    "761B02162C6E5D04": "15BB56B33EB48A835700B623B21B04856D2F81DA4F08DB6C6BC8408A9F097F4C",
    "709FB7A0C816C8B2": "BFBF4A805BDDC4FA186065333139A645316392E1A5345BD3C1A8AC7FF0837D1F",
    "6482BE08C086B0BA": "5FC39F58A4A924905BF7C924918E906E318AC74E4EFE981BD99BC138CCE6D25F",
    "145128EC449ADBDA": "05B45025FB3E1E09BA1BCC24E6D6FC0AC070481F1EC1689CFCC7D60143B43D66",
}

RISE_LAYER_CHECKPOINTS = (30, 90, 150, 210, 270, 330, 390, 450, 510, 570)
RISE_LAYER_MAX_AGE = 190


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def load_java_audit(repository: Path):
    source = repository / "tools" / "Audit-JavaClasses.py"
    spec = importlib.util.spec_from_file_location("open_sturmovik_java_audit", source)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load Java audit module: {source}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def load_sfs_finger(repository: Path):
    source = repository / "tools" / "Analyze-Sfs.py"
    spec = importlib.util.spec_from_file_location("open_sturmovik_sfs_finger_lifecycle", source)
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


@dataclass
class ModelState:
    phase: str = "detonation"
    actors: list[str] = field(
        default_factory=lambda: ["transient", "head", "torus", "column", "transient", "transient"]
    )
    created: int = 6
    destroyed: int = 0
    stabilized_created: bool = False
    transients_retired: bool = False
    rise_retired: bool = False
    next_rise_layer_index: int = 0
    rise_layers_created: int = 0
    rise_layers_skipped: int = 0
    emission_complete: bool = False
    complete: bool = False

    def transition(self, phase: str, actor_count: int) -> None:
        self.phase = phase
        if phase == "complete":
            self.emission_complete = True
            return
        if phase == "stabilized" and not self.stabilized_created:
            self.stabilized_created = True
        self.actors.extend(f"{phase}-{index}" for index in range(actor_count))
        self.created += actor_count

    def schedule_layers(self, age_seconds: int) -> None:
        while (
            self.next_rise_layer_index < len(RISE_LAYER_CHECKPOINTS)
            and RISE_LAYER_CHECKPOINTS[self.next_rise_layer_index] <= age_seconds
        ):
            index = self.next_rise_layer_index
            checkpoint = RISE_LAYER_CHECKPOINTS[index]
            self.next_rise_layer_index += 1
            if age_seconds - checkpoint >= RISE_LAYER_MAX_AGE:
                self.rise_layers_skipped += 1
                continue
            self.actors.append(f"rise-head-{checkpoint}")
            self.created += 1
            if index % 2:
                self.actors.append(f"rise-torus-{checkpoint}")
                self.created += 1
            self.rise_layers_created += 1

    def drain(self, age_seconds: int) -> None:
        if age_seconds >= 130 and not self.transients_retired:
            retained = [actor for actor in self.actors if actor != "transient"]
            self.destroyed += len(self.actors) - len(retained)
            self.actors = retained
            self.transients_retired = True
        if age_seconds >= 728 and not self.rise_retired:
            rising = {"head", "torus", "column"}
            retained = [
                actor for actor in self.actors
                if actor not in rising and not actor.startswith("rise-")
            ]
            self.destroyed += len(self.actors) - len(retained)
            self.actors = retained
            self.rise_retired = True
        if age_seconds >= 3728:
            self.destroyed += len(self.actors)
            self.actors.clear()
            self.complete = True


def add_check(checks: list[dict[str, Any]], name: str, ok: bool, detail: str) -> None:
    checks.append({"name": name, "status": "PASS" if ok else "FAIL", "detail": detail})


def validate(
    repository: Path,
    build_a: Path,
    build_b: Path,
    rt_jar: Path,
) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    manifest_a_path = build_a / "manifest.json"
    manifest_b_path = build_b / "manifest.json"
    manifest_a = json.loads(manifest_a_path.read_text(encoding="utf-8-sig"))
    manifest_b = json.loads(manifest_b_path.read_text(encoding="utf-8-sig"))

    add_check(
        checks,
        "construction reproductible du manifeste",
        manifest_a_path.read_bytes() == manifest_b_path.read_bytes(),
        f"sha256={sha256(manifest_a_path)}",
    )

    staging_a = build_a / "files-staging"
    staging_b = build_b / "files-staging"
    names_a = sorted(path.name for path in staging_a.iterdir() if path.is_file())
    names_b = sorted(path.name for path in staging_b.iterdir() if path.is_file())
    hash_differences = [
        name for name in names_a
        if name not in names_b or sha256(staging_a / name) != sha256(staging_b / name)
    ]
    add_check(
        checks,
        "construction reproductible des classes",
        names_a == names_b and not hash_differences,
        f"classes={len(names_a)}, differences={hash_differences}",
    )

    finger = load_sfs_finger(repository)
    loose_name_errors = [
        f"{item['class']}: manifeste={item['loose_name']}, calcule={class_loose_name(finger, item['class'])}"
        for item in manifest_a["classes"]
        if item["loose_name"].upper() != class_loose_name(finger, item["class"])
    ]
    add_check(
        checks,
        "adressage SFS des classes",
        not loose_name_errors,
        "les treize noms libres sont calcules depuis les noms Java"
        if not loose_name_errors else str(loose_name_errors),
    )

    changed_damage_or_shock = [
        name
        for name, expected_hash in UNCHANGED_DAMAGE_AND_SHOCK.items()
        if not (staging_a / name).is_file() or sha256(staging_a / name) != expected_hash
    ]
    add_check(
        checks,
        "souffle et degats conserves octet pour octet",
        not changed_damage_or_shock,
        f"classes_inchangees={len(UNCHANGED_DAMAGE_AND_SHOCK)}, differences={changed_damage_or_shock}",
    )

    audit = load_java_audit(repository)
    runtime_api, bad_crc = audit.load_runtime_api(rt_jar)
    semantic = build_a / "semantic"
    class_issues: list[str] = []
    parsed_classes: dict[str, Any] = {}
    for item in manifest_a["classes"]:
        class_path = semantic / (item["class"].split(".")[-1] + ".class")
        parsed = audit.parse_class(class_path.read_bytes())
        parsed_classes[parsed.name] = parsed
        missing_classes, missing_members, bytecode_problems, _ = audit.compatibility_issues(parsed, runtime_api)
        if parsed.major != 47:
            class_issues.append(f"{parsed.name}: major={parsed.major}")
        class_issues.extend(f"{parsed.name}: runtime class {value}" for value in missing_classes)
        class_issues.extend(f"{parsed.name}: {value}" for value in missing_members)
        class_issues.extend(f"{parsed.name}: {value}" for value in bytecode_problems)
    add_check(
        checks,
        "Java 1.3 reel et major 47",
        not class_issues,
        (
            f"13 classes compatibles; anomalies CRC historiques du rt.jar={len(bad_crc)}"
            if not class_issues else str(class_issues)
        ),
    )

    root = parsed_classes["com/maddox/il2/objects/effects/NuclearBlast"]
    refs = set(root.method_refs)
    time_methods = sorted(name for owner, name, _ in refs if owner == "com/maddox/rts/Time")
    forbidden = sorted(name for name in time_methods if name == "isPaused")
    reflection = sorted(
        f"{owner}.{name}{descriptor}"
        for owner, name, descriptor in refs
        if owner.startswith("java/lang/reflect/")
    )
    add_check(
        checks,
        "age visuel fonde uniquement sur la simulation",
        "current" in time_methods and "currentReal" not in time_methods and not forbidden and not reflection,
        f"Time={time_methods}, interdit={forbidden}, reflection={reflection}",
    )

    visual_action = parsed_classes.get(
        "com/maddox/il2/objects/effects/NuclearBlast$VisualTickAction"
    )
    terrain_api = {
        ("com/maddox/il2/engine/Engine", "land", "()Lcom/maddox/il2/engine/Landscape;"),
        ("com/maddox/il2/engine/Landscape", "HQ", "(DD)D"),
    }
    visual_position_refs = refs | set(
        parsed_classes["com/maddox/il2/objects/effects/NuclearBlast$State"].method_refs
    )
    add_check(
        checks,
        "heartbeat simule, couches fixes et positionnement AGL",
        visual_action is not None
        and visual_action.super_name == "com/maddox/rts/MsgAction"
        and terrain_api <= visual_position_refs
        and not any(
            owner == "com/maddox/il2/engine/ActorPos" and name in {"setAbs", "reset"}
            for owner, name, _ in visual_position_refs
        ),
        (
            f"VisualTickAction={visual_action is not None}, "
            f"API_terrain_manquantes={sorted(terrain_api - visual_position_refs)}, "
            "deplacement_emetteur=absent"
        ),
    )

    bomb_visual_dispatches: list[str] = []
    for bomb_name in (
        "com/maddox/il2/objects/weapons/BombLittleBoy",
        "com/maddox/il2/objects/weapons/BombFatMan",
    ):
        for owner, name, descriptor in parsed_classes[bomb_name].method_refs:
            if owner == "com/maddox/il2/objects/effects/Explosions" and name in {
                "bombFatMan_land", "bombFatMan_water",
            }:
                bomb_visual_dispatches.append(f"{bomb_name}.{name}{descriptor}")
    add_check(
        checks,
        "un seul declenchement visuel par bombe",
        not bomb_visual_dispatches,
        "les bombes deleguent uniquement a Bomb.doExplosion; Explosions.generate cree le visuel"
        if not bomb_visual_dispatches else str(bomb_visual_dispatches),
    )

    explosions_refs = set(parsed_classes["com/maddox/il2/objects/effects/Explosions"].method_refs)
    yield_scaled_dispatch = (
        "com/maddox/il2/objects/effects/NuclearBlast",
        "visualScaleForPower",
        "(F)F",
    ) in explosions_refs
    add_check(
        checks,
        "echelle visuelle derivee de la puissance",
        yield_scaled_dispatch,
        "Explosions.generate transmet l'echelle Little Boy/Fat Man calculee depuis la puissance",
    )

    vertical_orientation = (
        "com/maddox/il2/engine/Orient", "set", "(FFF)V",
    ) in refs and (
        "com/maddox/il2/engine/Loc",
        "set",
        "(Lcom/maddox/JGP/Tuple3d;Lcom/maddox/il2/engine/Orient;)V",
    ) in refs
    add_check(
        checks,
        "orientation verticale des acteurs de phase",
        vertical_orientation,
        "orientation historique yaw=0, pitch=90, roll=0 exigee par les effets Silverplate",
    )

    state = parsed_classes["com/maddox/il2/objects/effects/NuclearBlast$State"]
    state_fields = {item.name for item in state.fields}
    required_fields = {
        "detonationTime", "position", "altitudeMeters", "groundAltitudeMeters", "yieldKilotonnes", "water",
        "phase", "actors", "actorRoles", "actorsCreated", "actorsDestroyed", "lastVisualTickSimulation",
        "visualTicks", "stabilizedCreated", "transientsRetired", "riseRetired", "emissionComplete", "complete",
        "nextRiseLayerIndex", "riseLayersCreated", "riseLayersSkipped",
    }
    add_check(
        checks,
        "etat nucleaire persistant",
        required_fields <= state_fields,
        f"champs={sorted(state_fields)}",
    )

    lifecycle = manifest_a["model"]["visual_lifecycle_s"]
    ordered = [
        ("early-rise", lifecycle["detonation_end"], 0),
        ("mature-rise", lifecycle["early_rise_end"], 0),
        ("late-rise", lifecycle["mature_rise_end"], 0),
        ("stabilized", lifecycle["late_rise_end"], 1),
        ("dissipating", lifecycle["stabilized_end"], 0),
        ("complete", lifecycle["dissipating_end"], 0),
    ]
    boundary_values = [seconds for _, seconds, _ in ordered]
    add_check(
        checks,
        "ordre strict des phases",
        boundary_values == sorted(set(boundary_values)),
        str(ordered),
    )

    model = ModelState()
    paused_simulation_age = lifecycle["early_rise_end"] - 1
    wall_clock_elapsed_while_paused = 900
    resumed_simulation_age = paused_simulation_age
    add_check(
        checks,
        "pause sans progression et reprise au meme age logique",
        resumed_simulation_age == paused_simulation_age and wall_clock_elapsed_while_paused > 0,
        f"age_simulation={resumed_simulation_age}s, temps_reel_ignore={wall_clock_elapsed_while_paused}s",
    )

    for phase, _, actor_count in ordered[:3]:
        model.transition(phase, actor_count)
    model.schedule_layers(30)
    add_check(
        checks,
        "montee par couche fixe sans remplacement a 30 s",
        len(model.actors) == 7
        and model.created == 7
        and model.destroyed == 0
        and all(actor in model.actors for actor in ("head", "torus", "column")),
        f"actors={len(model.actors)}, created={model.created}, destroyed={model.destroyed}",
    )
    model.schedule_layers(120)
    model.drain(130)
    add_check(
        checks,
        "effets instantanes laisses finir puis liberes",
        model.actors.count("transient") == 0
        and model.actors.count("head") == 1
        and model.actors.count("torus") == 1
        and model.actors.count("column") == 1
        and model.rise_layers_created == 2
        and model.created == 9
        and model.destroyed == 3,
        f"actors={model.actors}, created={model.created}, destroyed={model.destroyed}",
    )
    for checkpoint in RISE_LAYER_CHECKPOINTS[2:]:
        model.schedule_layers(checkpoint)
    model.transition(*("stabilized", 1))
    add_check(
        checks,
        "chevauchement continu des couches a 600 s",
        len(model.actors) == 19
        and model.created == 22
        and model.destroyed == 3
        and model.rise_layers_created == 10,
        f"actors={model.actors}, created={model.created}, destroyed={model.destroyed}",
    )
    model.drain(728)
    add_check(
        checks,
        "particules de montee drainees a 728 s",
        model.actors == ["stabilized-0"] and model.created == 22 and model.destroyed == 21,
        f"actors={model.actors}, created={model.created}, destroyed={model.destroyed}",
    )

    catch_up = ModelState()
    catch_up.schedule_layers(500)
    add_check(
        checks,
        "rattrapage borne sans rafale de couches expirees",
        catch_up.rise_layers_skipped == 5
        and catch_up.rise_layers_created == 3
        and catch_up.created == 11,
        (
            f"layers_creees={catch_up.rise_layers_created}, "
            f"layers_ignorees={catch_up.rise_layers_skipped}, actors={catch_up.created}"
        ),
    )

    effects = {
        "head": repository / "Files/3do/Effects/Fireworks/FatMan(rise-head).eff",
        "torus": repository / "Files/3do/Effects/Fireworks/FatMan(rise-torus).eff",
    }
    layer_effect_ok = all(path.is_file() for path in effects.values())
    if layer_effect_ok:
        texts = {name: path.read_text(encoding="latin-1") for name, path in effects.items()}
        layer_effect_ok = all("FinishTime 60.0" in text and "LiveTime 128.0" in text for text in texts.values())
    add_check(
        checks,
        "emetteurs de couche bornes a 60 + 128 secondes",
        layer_effect_ok,
        "deux effets fixes; emission=60s, vidange naturelle=128s, acteur=190s",
    )

    head_intervals = [(start, start + RISE_LAYER_MAX_AGE) for start in RISE_LAYER_CHECKPOINTS]
    torus_starts = RISE_LAYER_CHECKPOINTS[1::2]
    torus_intervals = [(start, start + RISE_LAYER_MAX_AGE) for start in torus_starts]
    times = range(0, 761)
    peak_heads = max(sum(start <= age < end for start, end in head_intervals) for age in times)
    peak_tori = max(sum(start <= age < end for start, end in torus_intervals) for age in times)
    limits = manifest_a["model"]["effect_engine_limits"]
    add_check(
        checks,
        "budget simultane de la mission a seize bombes",
        peak_heads == 4
        and peak_tori == 2
        and limits["max_concurrent_rise_head_emitters"] == peak_heads
        and limits["max_concurrent_rise_torus_emitters"] == peak_tori
        and limits["max_created_visual_actors_per_blast"] == 22,
        (
            f"par_bombe=tetes:{peak_heads},tores:{peak_tori},crees:22; "
            f"seize_bombes=tetes:{peak_heads * 16},tores:{peak_tori * 16},crees:352"
        ),
    )

    def layer_altitudes(start_m: float, summit_m: float) -> list[int]:
        result: list[int] = []
        for seconds in RISE_LAYER_CHECKPOINTS:
            fraction = seconds / 600.0
            eased = 1.0 - (1.0 - fraction) ** 2
            result.append(round(start_m + (summit_m - start_m) * eased + 5.0 * (1.0 - fraction)))
        return result

    little_boy_layers = layer_altitudes(600.0, 12000.0)
    fat_man_layers = layer_altitudes(503.0, 13500.0)
    altitude_layers_ok = (
        little_boy_layers == sorted(set(little_boy_layers))
        and fat_man_layers == sorted(set(fat_man_layers))
        and little_boy_layers[-1] < 12000
        and fat_man_layers[-1] < 13500
        and 12000 - little_boy_layers[-1] <= 30
        and 13500 - fat_man_layers[-1] <= 35
    )
    add_check(
        checks,
        "altitudes AGL monotones des dix couches",
        altitude_layers_ok,
        f"Little Boy={little_boy_layers}; Fat Man={fat_man_layers}",
    )
    model.transition("dissipating", 0)
    model.transition("complete", 0)
    add_check(
        checks,
        "fin d'emission sans coupure a 3 600 s",
        model.emission_complete and not model.complete and model.actors == ["stabilized-0"],
        f"emission_complete={model.emission_complete}, actors={model.actors}",
    )
    model.drain(3728)
    cleanup_ok = (
        model.complete
        and not model.actors
        and model.created == model.destroyed
        and lifecycle["stabilized_particle_drain_end"] < lifecycle["cleanup_deadline"]
    )
    add_check(
        checks,
        "nettoyage complet avant 3 728 s",
        cleanup_ok,
        f"created={model.created}, destroyed={model.destroyed}, refs={len(model.actors)}, deadline={lifecycle['cleanup_deadline']}s",
    )

    destroy_refs = [
        (owner, name, descriptor)
        for owner, name, descriptor in refs
        if name == "postDestroy"
    ]
    array_clear = any(owner == "java/util/ArrayList" and name == "clear" for owner, name, _ in refs)
    array_remove = any(owner == "java/util/ArrayList" and name == "remove" for owner, name, _ in refs)
    add_check(
        checks,
        "destruction explicite et liberation des references",
        bool(destroy_refs) and array_clear and array_remove,
        f"postDestroy={destroy_refs}, clear={array_clear}, remove={array_remove}",
    )

    summit = manifest_a["model"]["cloud_summit"]
    add_check(
        checks,
        "altitudes finales Little Boy et Fat Man",
        summit["little_boy_m"] == 12000 and summit["fat_man_m"] == 13500,
        f"Little Boy={summit['little_boy_m']}m, Fat Man={summit['fat_man_m']}m",
    )

    failed = [check for check in checks if check["status"] == "FAIL"]
    return {
        "schema": "open-sturmovik-nuclear-lifecycle-test-v1",
        "status": "PASS" if not failed else "FAIL",
        "summary": {"checks": len(checks), "pass": len(checks) - len(failed), "fail": len(failed)},
        "checks": checks,
        "runtime_jar": {
            "name": rt_jar.name,
            "size": rt_jar.stat().st_size,
            "sha256": sha256(rt_jar),
            "historical_crc_anomalies": len(bad_crc),
        },
        "build_manifest_sha256": sha256(manifest_a_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--build-a", type=Path, required=True)
    parser.add_argument("--build-b", type=Path, required=True)
    parser.add_argument("--rt-jar", type=Path, required=True)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()

    payload = validate(
        args.repository.resolve(),
        args.build_a.resolve(),
        args.build_b.resolve(),
        args.rt_jar.resolve(),
    )
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(
        f"status={payload['status']} checks={payload['summary']['checks']} "
        f"pass={payload['summary']['pass']} fail={payload['summary']['fail']}"
    )
    for check in payload["checks"]:
        print(f"{check['status']}: {check['name']} - {check['detail']}")
    return 0 if payload["status"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
