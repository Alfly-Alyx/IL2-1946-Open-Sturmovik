"""Read-only comparison of the historical AAA modules with Open Sturmovik Files.

Writes reports to the explicitly supplied output directory. It never modifies either input tree.
Run from C:\\Users\\Alexis\\.codex with Python 3.
"""

from collections import Counter, defaultdict
from datetime import datetime, timezone
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, default=Path(r"D:\Projets\GITHUB\IL2-1946-Open-Sturmovik"))
parser.add_argument("--source", type=Path, default=Path(r"D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1\MODS"))
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--expected-branch", default="v1.15")
args = parser.parse_args()
REPO = args.root.resolve()
AAA = args.source.resolve()
TARGET = REPO / "Files"
OUTPUT = args.output.resolve()


def git(*args):
    return subprocess.check_output(["git", "-c", "safe.directory=" + REPO.as_posix(),
                                    "-C", str(REPO), *args], text=True).strip()


branch = git("branch", "--show-current")
if branch != args.expected_branch:
    raise SystemExit(f"Shared checkout branch is {branch!r}, expected {args.expected_branch!r}; stopped.")
git_root = git("rev-parse", "--show-toplevel")
head = git("rev-parse", "HEAD")
started = datetime.now(timezone.utc).isoformat()
hash_cache = {}
target_hash_reads = 0


def digest(path):
    global target_hash_reads
    before = path.stat()
    key = (str(path).casefold(), before.st_size, before.st_mtime_ns)
    if key in hash_cache:
        return hash_cache[key]
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    after = path.stat()
    if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
        raise RuntimeError(f"File changed during hashing: {path}")
    value = result.hexdigest().upper()
    hash_cache[key] = value
    if path.is_relative_to(TARGET):
        target_hash_reads += 1
    return value


def documentation(relative):
    low = relative.lower()
    basename = Path(relative).name.lower()
    return (Path(relative).suffix.lower() in {".md", ".pdf", ".doc", ".docx", ".htm", ".html", ".rtf"}
            or "readme" in basename or "lisez" in basename or "credit" in basename
            or "_docs_/" in low or basename in {"thumbs.db", "desktop.ini"})


def category(name):
    lower = name.lower().lstrip("-")
    if name == "_DOCS_":
        return "documentation"
    if lower == "mapmods":
        return "maps_and_map_registry"
    if lower in {"objectsmap", "static_aircraft"}:
        return "objects_and_registries"
    if lower in {"std", "aircraft"}:
        return "base_or_registry"
    if lower.startswith(("windconfig", "hudconfig", "bombbaydoors", "6dof")) or lower in {"collision_height", "fmb"}:
        return "technical"
    if any(word in lower for word in ("cockpit", "mirror", "gunsight", "reticle", "askania")):
        return "cockpit_or_sight"
    return "other_mod_content"


def local_document_evidence(module):
    paths = [p for p in module.rglob("*") if p.is_file() and documentation(str(p.relative_to(module)))
             and p.suffix.lower() in {".txt", ".md", ".htm", ".html"} and p.stat().st_size < 300_000]
    external_documents = {
        "BombBayDoors_Plus_v2_0": "BombBayDoors_Plus_v2_README.txt",
        "WindConfig_v3": "WindConfig_v3_README.txt",
    }
    if module.name in external_documents:
        candidate = AAA / "_DOCS_" / external_documents[module.name]
        if candidate.is_file() and candidate not in paths:
            paths.append(candidate)
    hints = []
    for path in paths:
        raw = path.read_bytes()
        try:
            content = raw.decode("utf-8-sig")
        except UnicodeDecodeError:
            content = raw.decode("cp1252", errors="replace")
        for line_number, line in enumerate(content.splitlines(), 1):
            if re.search(r"(?i)\b(author|auteur|credits?|created by|made by|mod by|thanks|thank|copyright)\b", line):
                hints.append({"path": str(path), "line": line_number, "text": line.strip()[:500]})
    result = {"authors": [], "status": "unknown_no_unambiguous_attribution_checked", "documents": [str(p) for p in paths],
              "unverified_credit_excerpts": hints}
    return result


modules = []
exact_claims = defaultdict(list)
all_claims = defaultdict(list)
errors = []
directories = sorted((p for p in AAA.iterdir() if p.is_dir()), key=lambda p: p.name.casefold())
for index, directory in enumerate(directories, 1):
    counts = Counter()
    entries = []
    for path in sorted((p for p in directory.rglob("*") if p.is_file()), key=lambda p: str(p).casefold()):
        relative = path.relative_to(directory).as_posix()
        target = TARGET / relative
        count_key = relative.casefold()
        doc = directory.name == "_DOCS_" or documentation(relative)
        entry = {"relative_path": relative, "source_path": str(path), "target_path": str(target),
                 "documentation_or_metadata": doc, "source_bytes": path.stat().st_size}
        counts["total_files"] += 1
        counts["source_bytes"] += entry["source_bytes"]
        counts["documentation_or_metadata_files" if doc else "payload_files"] += 1
        all_claims[count_key].append(directory.name)
        try:
            if not target.is_file():
                entry["comparison"] = "absent"
                counts["absent"] += 1
            else:
                counts["targets_present"] += 1
                entry["target_bytes"] = target.stat().st_size
                entry["target_mtime_ns"] = target.stat().st_mtime_ns
                if entry["source_bytes"] != entry["target_bytes"]:
                    entry["comparison"] = "different_size"
                    counts["different"] += 1
                    counts["different_size"] += 1
                else:
                    entry["source_sha256"] = digest(path)
                    entry["target_sha256"] = digest(target)
                    if entry["source_sha256"] == entry["target_sha256"]:
                        entry["comparison"] = "identical"
                        counts["identical"] += 1
                        counts["identical_documentation" if doc else "identical_payload"] += 1
                        exact_claims[(count_key, entry["source_sha256"])].append(directory.name)
                    else:
                        entry["comparison"] = "different_hash"
                        counts["different"] += 1
                        counts["different_hash"] += 1
        except (OSError, RuntimeError) as exc:
            entry["comparison"] = "error"
            entry["error"] = str(exc)
            counts["errors"] += 1
            errors.append({"module": directory.name, "path": str(path), "error": str(exc)})
        entries.append(entry)
    for key in ("targets_present", "identical", "different", "absent", "errors", "payload_files",
                "identical_payload", "identical_documentation", "different_size", "different_hash"):
        counts.setdefault(key, 0)
    modules.append({"module": directory.name, "source_directory": str(directory), "category": category(directory.name),
                    "disabled_by_name_in_source_package": directory.name.startswith("-"),
                    "counts": dict(counts), "attribution": local_document_evidence(directory), "files": entries})
    if index % 20 == 0 or index == len(directories):
        print(f"Compared {index}/{len(directories)} modules", flush=True)


for module in modules:
    unique = shared = 0
    map_groups = defaultdict(Counter)
    for entry in module["files"]:
        path_key = entry["relative_path"].casefold()
        other = sorted(set(all_claims[path_key]) - {module["module"]})
        if other:
            entry["other_modules_with_same_relative_path"] = other
        if entry["comparison"] == "identical":
            others_exact = sorted(set(exact_claims[(path_key, entry["source_sha256"])]) - {module["module"]})
            entry["other_modules_with_same_path_and_hash"] = others_exact
            if not entry["documentation_or_metadata"]:
                if others_exact:
                    shared += 1
                else:
                    unique += 1
        if module["module"] == "MapMods":
            parts = entry["relative_path"].split("/")
            group = "/".join(parts[:2]) if len(parts) >= 3 else parts[0]
            map_groups[group]["total_files"] += 1
            map_groups[group][entry["comparison"]] += 1
    module["counts"].update(identical_payload_not_matched_by_other_aaa_modules=unique,
                            identical_payload_shared_with_other_aaa_modules=shared)
    if module["category"] == "documentation":
        status = "documentation_only"
    elif module["counts"]["identical_payload"] == 0:
        status = "no_identical_payload_found_in_target_files"
    elif unique == 0:
        status = "only_shared_payload_matches_origin_ambiguous"
    elif module["counts"]["identical_payload"] == module["counts"]["payload_files"]:
        status = "all_payload_paths_and_hashes_match_origin_and_runtime_unverified"
    else:
        status = "partial_payload_matches_origin_and_runtime_unverified"
    module["finding"] = status
    if map_groups:
        module["map_subgroups"] = {key: dict(value) for key, value in sorted(map_groups.items())}


overlaps = [{"relative_path_casefolded": path, "sha256": digest_value, "modules": sorted(set(names))}
            for (path, digest_value), names in exact_claims.items() if len(set(names)) > 1]
totals = Counter()
for module in modules:
    totals.update(module["counts"])

result = {
    "schema_version": 1,
    "started_utc": started,
    "finished_utc": datetime.now(timezone.utc).isoformat(),
    "git": {"root": git_root, "branch": branch, "head": head, "branch_at_end": git("branch", "--show-current")},
    "source_root": str(AAA), "target_root": str(TARGET),
    "scope": "Every regular file under every immediate AAA MODS directory compared at the same module-relative path below the current Files directory.",
    "method": "SHA-256 only when target exists and has equal byte length; target hashes cached by path, size and modification time. No source or game file modified.",
    "limits": [
        "Matching files establish identical local content, not authorship, historical installation order or runtime loading.",
        "No comparison against the official stock SFS contents: stock and inherited common resources may match; no module is automatically declared active.",
        "A path/hash exclusive among these AAA modules is not necessarily unique to the mod or different from stock.",
        "Shared path/hash matches are explicitly listed and cannot independently identify the originating module.",
        "Files absent from the loose Files directory may be supplied by mounted SFS archives or another path; absence here does not prove mod removal.",
        "Different files may be later versions, adaptations or merged contributions; this scan does not infer which.",
        "The historical MapMods and ObjectsMap folders are aggregates, not automatically individual authorable mods.",
        "Credit excerpts are unverified hints; thanks lines and cited incompatible mods are not treated as authors.",
        "The report reads the working tree, including any existing uncommitted content, and hashes a sequence rather than an atomic filesystem snapshot."
    ],
    "module_count": len(modules), "totals": dict(totals), "distinct_target_hash_reads": target_hash_reads,
    "findings_counts": dict(Counter(module["finding"] for module in modules)),
    "shared_exact_path_hash_count": len(overlaps), "shared_exact_path_hashes": overlaps,
    "errors": errors, "modules": modules,
}
OUTPUT.mkdir(parents=True, exist_ok=True)
report = OUTPUT / "aaa_modules_comparison.json"
report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
summary = {key: value for key, value in result.items() if key not in {"modules", "shared_exact_path_hashes"}}
summary["modules"] = [{key: value for key, value in module.items() if key != "files"} for module in modules]
(OUTPUT / "aaa_modules_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"report": str(report), "modules": len(modules), "totals": dict(totals),
                  "findings": result["findings_counts"], "errors": len(errors)}, ensure_ascii=False), flush=True)
