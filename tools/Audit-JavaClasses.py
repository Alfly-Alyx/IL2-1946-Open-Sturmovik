#!/usr/bin/env python3
"""Audit IL-2 loose Java classes against the bundled Java 1.3 runtime.

The script is deliberately read-only unless --stage-dir is supplied. Staging
changes only the class-file major version in copies; it never overwrites Files.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
import zipfile
import zlib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


RUNTIME_PREFIXES = ("java/", "javax/", "sun/", "com/sun/", "org/omg/", "org/w3c/")
DESCRIPTOR_CLASS = re.compile(r"L([^;]+);")


class ClassFormatError(ValueError):
    pass


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.offset = 0

    def take(self, length: int) -> bytes:
        end = self.offset + length
        if length < 0 or end > len(self.data):
            raise ClassFormatError(f"lecture hors limites a 0x{self.offset:X}")
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
class Member:
    name: str
    descriptor: str
    access: int
    attributes: list[str] = field(default_factory=list)
    code_blocks: list[bytes] = field(default_factory=list)


@dataclass
class ParsedClass:
    minor: int
    major: int
    access: int
    name: str
    super_name: str | None
    interfaces: list[str]
    fields: list[Member]
    methods: list[Member]
    attributes: list[str]
    class_refs: set[str]
    field_refs: list[tuple[str, str, str]]
    method_refs: list[tuple[str, str, str]]
    descriptor_refs: set[str]
    constant_tags: set[int]


def utf8(cp: list[object | None], index: int) -> str:
    try:
        entry = cp[index]
    except IndexError as exc:
        raise ClassFormatError(f"index constant pool invalide: {index}") from exc
    if not entry or entry[0] != 1:
        raise ClassFormatError(f"constante UTF-8 attendue a l'index {index}")
    return entry[1]


def class_name(cp: list[object | None], index: int) -> str:
    if index == 0:
        return ""
    try:
        entry = cp[index]
    except IndexError as exc:
        raise ClassFormatError(f"index de classe invalide: {index}") from exc
    if not entry or entry[0] != 7:
        raise ClassFormatError(f"constante Class attendue a l'index {index}")
    return utf8(cp, entry[1])


def parse_attributes(reader: Reader, cp: list[object | None], keep_code: bool) -> tuple[list[str], list[bytes]]:
    names: list[str] = []
    codes: list[bytes] = []
    for _ in range(reader.u2()):
        name = utf8(cp, reader.u2())
        length = reader.u4()
        payload = reader.take(length)
        names.append(name)
        if keep_code and name == "Code":
            code_reader = Reader(payload)
            code_reader.u2()  # max_stack
            code_reader.u2()  # max_locals
            code = code_reader.take(code_reader.u4())
            codes.append(code)
            exception_count = code_reader.u2()
            code_reader.take(exception_count * 8)
            parse_attributes(code_reader, cp, False)
            if code_reader.offset != len(payload):
                raise ClassFormatError("attribut Code mal forme")
    return names, codes


def parse_members(reader: Reader, cp: list[object | None], keep_code: bool) -> list[Member]:
    result: list[Member] = []
    for _ in range(reader.u2()):
        access = reader.u2()
        name = utf8(cp, reader.u2())
        descriptor = utf8(cp, reader.u2())
        attributes, codes = parse_attributes(reader, cp, keep_code)
        result.append(Member(name, descriptor, access, attributes, codes))
    return result


def parse_class(data: bytes, keep_code: bool = True) -> ParsedClass:
    reader = Reader(data)
    if reader.u4() != 0xCAFEBABE:
        raise ClassFormatError("magic CAFEBABE absent")
    minor = reader.u2()
    major = reader.u2()
    cp_count = reader.u2()
    cp: list[object | None] = [None]
    tags: set[int] = set()
    index = 1
    while index < cp_count:
        tag = reader.u1()
        tags.add(tag)
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
            raise ClassFormatError(f"tag constant pool non compatible: {tag}")
        index += 1

    access = reader.u2()
    this_class = reader.u2()
    super_class = reader.u2()
    interfaces = [class_name(cp, reader.u2()) for _ in range(reader.u2())]
    fields = parse_members(reader, cp, keep_code)
    methods = parse_members(reader, cp, keep_code)
    attributes, _ = parse_attributes(reader, cp, False)
    if reader.offset != len(data):
        raise ClassFormatError(f"{len(data) - reader.offset} octets residuels")

    classes: set[str] = set()
    field_refs: list[tuple[str, str, str]] = []
    method_refs: list[tuple[str, str, str]] = []
    descriptor_refs: set[str] = set()

    for entry in cp[1:]:
        if not entry:
            continue
        tag = entry[0]
        if tag == 7:
            classes.add(utf8(cp, entry[1]))
        elif tag in (9, 10, 11):
            owner = class_name(cp, entry[1])
            nat = cp[entry[2]]
            if not nat or nat[0] != 12:
                raise ClassFormatError("NameAndType attendu")
            name = utf8(cp, nat[1])
            descriptor = utf8(cp, nat[2])
            target = field_refs if tag == 9 else method_refs
            target.append((owner, name, descriptor))
            descriptor_refs.update(DESCRIPTOR_CLASS.findall(descriptor))

    for member in fields + methods:
        descriptor_refs.update(DESCRIPTOR_CLASS.findall(member.descriptor))

    return ParsedClass(
        minor=minor,
        major=major,
        access=access,
        name=class_name(cp, this_class),
        super_name=class_name(cp, super_class) or None,
        interfaces=interfaces,
        fields=fields,
        methods=methods,
        attributes=attributes,
        class_refs=classes,
        field_refs=field_refs,
        method_refs=method_refs,
        descriptor_refs=descriptor_refs,
        constant_tags=tags,
    )


FIXED_OPERANDS = {
    0x10: 1, 0x11: 2, 0x12: 1, 0x13: 2, 0x14: 2,
    **{opcode: 1 for opcode in range(0x15, 0x1A)},
    **{opcode: 1 for opcode in range(0x36, 0x3B)},
    0x84: 2,
    **{opcode: 2 for opcode in range(0x99, 0xA9)},
    0xA9: 1,
    **{opcode: 2 for opcode in range(0xB2, 0xB9)},
    0xB9: 4, 0xBA: 4, 0xBB: 2, 0xBC: 1, 0xBD: 2,
    0xC0: 2, 0xC1: 2, 0xC5: 3, 0xC6: 2, 0xC7: 2,
    0xC8: 4, 0xC9: 4,
}


def inspect_bytecode(code: bytes) -> list[str]:
    problems: list[str] = []
    pc = 0
    while pc < len(code):
        start = pc
        opcode = code[pc]
        pc += 1
        if opcode == 0xAA:  # tableswitch
            padding = (4 - (pc % 4)) % 4
            pc += padding
            if pc + 12 > len(code):
                problems.append(f"tableswitch tronque a {start}")
                break
            _, low, high = struct.unpack(">iii", code[pc:pc + 12])
            pc += 12
            entries = high - low + 1
            if entries < 0 or pc + entries * 4 > len(code):
                problems.append(f"tableswitch invalide a {start}")
                break
            pc += entries * 4
        elif opcode == 0xAB:  # lookupswitch
            padding = (4 - (pc % 4)) % 4
            pc += padding
            if pc + 8 > len(code):
                problems.append(f"lookupswitch tronque a {start}")
                break
            _, pairs = struct.unpack(">ii", code[pc:pc + 8])
            pc += 8
            if pairs < 0 or pc + pairs * 8 > len(code):
                problems.append(f"lookupswitch invalide a {start}")
                break
            pc += pairs * 8
        elif opcode == 0xC4:  # wide
            if pc >= len(code):
                problems.append(f"wide tronque a {start}")
                break
            modified = code[pc]
            length = 5 if modified == 0x84 else 3
            if modified not in set(range(0x15, 0x1A)) | set(range(0x36, 0x3B)) | {0x84, 0xA9}:
                problems.append(f"wide invalide 0x{modified:02X} a {start}")
            pc += length
        else:
            if opcode == 0xBA:
                problems.append(f"invokedynamic a {start}")
            if opcode >= 0xCA:
                problems.append(f"opcode reserve 0x{opcode:02X} a {start}")
            pc += FIXED_OPERANDS.get(opcode, 0)
        if pc > len(code):
            problems.append(f"instruction 0x{opcode:02X} tronquee a {start}")
            break
    return problems


@dataclass
class ApiClass:
    super_name: str | None
    interfaces: list[str]
    fields: set[tuple[str, str]]
    methods: set[tuple[str, str]]


def read_zip_entry_without_crc(archive: zipfile.ZipFile, info: zipfile.ZipInfo) -> tuple[bytes, bool]:
    """Read old IL-2 JRE entries while reporting, but not trusting, ZIP CRC metadata."""
    with archive.open(info) as stream:
        # Some files in the shipped Java 1.3 rt.jar carry inconsistent central
        # directory CRC values. The JVM consumes the decompressed class bytes;
        # the audit must inspect those bytes and report the packaging anomaly.
        stream._expected_crc = None  # type: ignore[attr-defined]
        data = stream.read()
    return data, (zlib.crc32(data) & 0xFFFFFFFF) != info.CRC


def load_runtime_api(rt_jar: Path) -> tuple[dict[str, ApiClass], list[str]]:
    api: dict[str, ApiClass] = {}
    bad_crc: list[str] = []
    with zipfile.ZipFile(rt_jar) as archive:
        for info in sorted(archive.infolist(), key=lambda item: item.filename):
            if not info.filename.endswith(".class"):
                continue
            data, crc_mismatch = read_zip_entry_without_crc(archive, info)
            if crc_mismatch:
                bad_crc.append(info.filename)
            parsed = parse_class(data, keep_code=False)
            api[parsed.name] = ApiClass(
                parsed.super_name,
                parsed.interfaces,
                {(item.name, item.descriptor) for item in parsed.fields},
                {(item.name, item.descriptor) for item in parsed.methods},
            )
    return api, bad_crc


def runtime_name(name: str) -> bool:
    while name.startswith("["):
        name = name[1:]
    if name.startswith("L") and name.endswith(";"):
        name = name[1:-1]
    return name.startswith(RUNTIME_PREFIXES)


def member_exists(
    api: dict[str, ApiClass], owner: str, name: str, descriptor: str, method: bool,
    visited: set[str] | None = None,
) -> bool:
    if owner.startswith("["):
        owner = "java/lang/Object"
    current = api.get(owner)
    if current is None:
        return False
    members = current.methods if method else current.fields
    if (name, descriptor) in members:
        return True
    if name == "<init>":
        return False
    if visited is None:
        visited = set()
    if owner in visited:
        return False
    visited.add(owner)
    parents = ([current.super_name] if current.super_name else []) + current.interfaces
    if method and "java/lang/Object" not in parents:
        parents.append("java/lang/Object")
    return any(
        parent and member_exists(api, parent, name, descriptor, method, visited)
        for parent in parents
    )


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def compatibility_issues(parsed: ParsedClass, api: dict[str, ApiClass]) -> tuple[list[str], list[str], list[str], list[str]]:
    missing_classes = sorted({
        name for name in parsed.class_refs | parsed.descriptor_refs
        if runtime_name(name) and name.lstrip("[").removeprefix("L").removesuffix(";") not in api
    })
    missing_members: list[str] = []
    for owner, name, descriptor in parsed.field_refs:
        if runtime_name(owner) and not member_exists(api, owner, name, descriptor, False):
            missing_members.append(f"FIELD {owner}.{name}:{descriptor}")
    for owner, name, descriptor in parsed.method_refs:
        if runtime_name(owner) and not member_exists(api, owner, name, descriptor, True):
            missing_members.append(f"METHOD {owner}.{name}{descriptor}")

    bytecode_problems = sorted({
        problem
        for method in parsed.methods
        for code in method.code_blocks
        for problem in inspect_bytecode(code)
    })
    risks: list[str] = []
    if parsed.major > 50:
        risks.append(f"version {parsed.major} posterieure a Java 6")
    if parsed.access & 0x2000:
        risks.append("classe annotation")
    if parsed.access & 0x4000:
        risks.append("classe enum")
    if missing_classes:
        risks.append("classes runtime absentes")
    if missing_members:
        risks.append("API runtime absente")
    if bytecode_problems:
        risks.append("bytecode non compatible")
    return missing_classes, sorted(set(missing_members)), bytecode_problems, risks


def rewrite_utf8_constants(data: bytes, replacements: dict[bytes, bytes]) -> bytes:
    """Rewrite ASCII fragments in CONSTANT_Utf8 entries and preserve all other bytes."""
    reader = Reader(data)
    prefix = reader.take(8)
    cp_count_raw = reader.take(2)
    cp_count = struct.unpack(">H", cp_count_raw)[0]
    output = bytearray(prefix + cp_count_raw)
    index = 1
    while index < cp_count:
        tag = reader.u1()
        output.append(tag)
        if tag == 1:
            raw = reader.take(reader.u2())
            for old, new in replacements.items():
                raw = raw.replace(old, new)
            output.extend(struct.pack(">H", len(raw)))
            output.extend(raw)
        elif tag in (3, 4):
            output.extend(reader.take(4))
        elif tag in (5, 6):
            output.extend(reader.take(8))
            index += 1
        elif tag in (7, 8):
            output.extend(reader.take(2))
        elif tag in (9, 10, 11, 12):
            output.extend(reader.take(4))
        else:
            raise ClassFormatError(f"tag constant pool non compatible: {tag}")
        index += 1
    output.extend(reader.take(len(data) - reader.offset))
    return bytes(output)


def audit(
    files_root: Path, rt_jar: Path, max_supported: int,
) -> tuple[list[dict[str, object]], dict[str, int], list[str], list[str]]:
    api, runtime_bad_crc = load_runtime_api(rt_jar)
    results: list[dict[str, object]] = []
    versions: dict[str, int] = {}
    parse_errors: list[str] = []
    candidates = sorted(
        path for path in files_root.iterdir()
        if path.is_file() and re.fullmatch(r"[0-9A-Fa-f]{16}", path.name)
    )
    for path in candidates:
        data = path.read_bytes()
        try:
            parsed = parse_class(data)
        except ClassFormatError as exc:
            parse_errors.append(f"{path.name}: {exc}")
            continue
        versions[str(parsed.major)] = versions.get(str(parsed.major), 0) + 1
        if parsed.major <= max_supported:
            continue

        missing_classes, missing_members, bytecode_problems, risks = compatibility_issues(parsed, api)
        compat_replacements: dict[str, str] = {}
        safe_to_transform = not risks
        if (
            missing_classes == ["java/lang/StringBuilder"]
            and missing_members
            and all(" java/lang/StringBuilder." in item for item in missing_members)
            and set(risks) <= {"classes runtime absentes", "API runtime absente"}
        ):
            replacements = {b"java/lang/StringBuilder": b"java/lang/StringBuffer"}
            rewritten = rewrite_utf8_constants(data, replacements)
            rewritten_parsed = parse_class(rewritten)
            _, _, _, rewritten_risks = compatibility_issues(rewritten_parsed, api)
            if not rewritten_risks:
                compat_replacements = {"java/lang/StringBuilder": "java/lang/StringBuffer"}
                safe_to_transform = True

        results.append({
            "file": path.name,
            "bytes": len(data),
            "sha256": sha256(data),
            "class": parsed.name,
            "major": parsed.major,
            "minor": parsed.minor,
            "super": parsed.super_name,
            "interfaces": parsed.interfaces,
            "constant_tags": sorted(parsed.constant_tags),
            "attributes": sorted(set(parsed.attributes)),
            "missing_runtime_classes": missing_classes,
            "missing_runtime_members": sorted(set(missing_members)),
            "bytecode_problems": bytecode_problems,
            "risks": risks,
            "safe_to_downlevel": not risks,
            "safe_to_transform": safe_to_transform,
            "compat_replacements": compat_replacements,
        })
    return results, versions, runtime_bad_crc, parse_errors


def stage_classes(files_root: Path, stage_dir: Path, results: list[dict[str, object]], target_major: int) -> None:
    stage_dir.mkdir(parents=True, exist_ok=True)
    manifest: list[dict[str, object]] = []
    for result in results:
        if not result["safe_to_transform"]:
            continue
        source = files_root / str(result["file"])
        source_data = source.read_bytes()
        replacements = {
            old.encode("ascii"): new.encode("ascii")
            for old, new in dict(result["compat_replacements"]).items()
        }
        transformed = rewrite_utf8_constants(source_data, replacements) if replacements else source_data
        data = bytearray(transformed)
        original_major = struct.unpack(">H", data[6:8])[0]
        data[6:8] = struct.pack(">H", target_major)
        destination = stage_dir / source.name
        destination.write_bytes(data)
        manifest.append({
            "file": source.name,
            "class": result["class"],
            "original_major": original_major,
            "target_major": target_major,
            "source_sha256": result["sha256"],
            "staged_sha256": sha256(data),
            "compat_replacements": result["compat_replacements"],
        })
    (stage_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def markdown_report(
    results: list[dict[str, object]], versions: dict[str, int], max_supported: int,
    runtime_bad_crc: list[str], parse_errors: list[str],
) -> str:
    safe = sum(bool(item["safe_to_transform"]) for item in results)
    lines = [
        "# Audit des classes Java libres",
        "",
        "Ce rapport est produit par `tools/Audit-JavaClasses.py`. Il compare les references",
        "des classes libres avec le `rt.jar` Java 1.3.1 livre par le jeu. Il inspecte aussi",
        "le constant pool, les descripteurs et le flux d'opcodes de chaque methode.",
        "",
        f"- classes au-dessus de la version {max_supported} : **{len(results)}** ;",
        f"- admissibles a une mise a niveau descendante statique : **{safe}** ;",
        f"- necessitant une correction/recompilation : **{len(results) - safe}** ;",
        f"- entrees de `rt.jar` dont le CRC ZIP est incoherent : **{len(runtime_bad_crc)}** ;",
        f"- classes libres non analysees a cause d'une erreur de format : **{len(parse_errors)}** ;",
        "- repartition des classes libres analysables : " + ", ".join(
            f"version {key} = {versions[key]}" for key in sorted(versions, key=int)
        ) + ".",
        "",
        "Une decision `admissible` signifie qu'aucune API absente, structure recente ou",
        "instruction interdite n'a ete trouvee. Elle ne remplace pas le futur essai avec la",
        "JVM du jeu et une mission qui instancie effectivement la classe.",
        "",
        "| Fichier | Classe interne | Taille | Decision |",
        "| --- | --- | ---: | --- |",
    ]
    for item in results:
        if item["safe_to_downlevel"]:
            decision = "version 47 admissible"
        elif item["safe_to_transform"]:
            decision = "StringBuilder -> StringBuffer, puis version 47"
        else:
            decision = "; ".join(item["risks"])
        lines.append(f"| `{item['file']}` | `{item['class']}` | {item['bytes']} | {decision} |")
    unsafe = [item for item in results if not item["safe_to_transform"]]
    if unsafe:
        lines.extend(["", "## Incompatibilites detaillees", ""])
        for item in unsafe:
            lines.append(f"### `{item['class']}`")
            for key in ("missing_runtime_classes", "missing_runtime_members", "bytecode_problems"):
                for value in item[key]:
                    lines.append(f"- {value}")
            lines.append("")
    lines.extend([
        "## Regle de conversion",
        "",
        "Pour 55 classes, la conversion stagee ne modifie que les octets 6 et 7 de",
        "l'en-tete `ClassFile`. Pour `BF_109F4`, elle remplace aussi la constante",
        "`java/lang/StringBuilder` par `java/lang/StringBuffer`, API equivalente disponible",
        "dans Java 1.3.1. Les originaux ne sont jamais ecrases par cet outil. Le format est decrit par la",
        "[specification JVM Oracle](https://docs.oracle.com/javase/specs/jvms/se6/html/ClassFile.doc.html).",
        "",
    ])
    if runtime_bad_crc:
        lines.extend([
            "## Anomalies de conditionnement du runtime",
            "",
            "Les donnees de ces classes sont decompressables, mais leur CRC central ne correspond pas :",
            "",
        ])
        lines.extend(f"- `{name}`" for name in runtime_bad_crc[:20])
        if len(runtime_bad_crc) > 20:
            lines.append(f"- ... et {len(runtime_bad_crc) - 20} autres entrees.")
        lines.append("")
    if parse_errors:
        lines.extend(["## Erreurs de lecture des classes libres", ""])
        lines.extend(f"- `{value}`" for value in parse_errors)
        lines.append("")
    return "\n".join(lines)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--files-root", type=Path, default=Path("Files"))
    parser.add_argument("--rt-jar", type=Path, required=True)
    parser.add_argument("--max-supported", type=int, default=47)
    parser.add_argument("--target-major", type=int, default=47)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--stage-dir", type=Path)
    parser.add_argument("--require-all-safe", action="store_true")
    args = parser.parse_args(argv)

    results, versions, runtime_bad_crc, parse_errors = audit(
        args.files_root, args.rt_jar, args.max_supported
    )
    payload = {
        "versions": versions,
        "runtime_bad_crc": runtime_bad_crc,
        "parse_errors": parse_errors,
        "classes": results,
    }
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            markdown_report(results, versions, args.max_supported, runtime_bad_crc, parse_errors),
            encoding="utf-8",
        )
    if args.stage_dir:
        stage_classes(args.files_root, args.stage_dir, results, args.target_major)

    safe = sum(bool(item["safe_to_transform"]) for item in results)
    print(f"classes_a_traiter={len(results)} admissibles={safe} incompatibles={len(results) - safe}")
    if args.require_all_safe and safe != len(results):
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
