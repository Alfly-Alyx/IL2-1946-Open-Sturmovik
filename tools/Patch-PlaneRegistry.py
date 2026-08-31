#!/usr/bin/env python3
"""Add missing static-plane SPAWN registrations to a Java 1.3 Plane.class.

The historical Open Sturmovik Plane.class contains the community aircraft but
omits 17 stock 4.09m registrations.  This patcher adds direct SPAWN calls to
the existing static initializer without recompiling the class or changing its
Java class-file version.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import tempfile
from dataclasses import dataclass
from pathlib import Path


CLASS_MAGIC = b"\xCA\xFE\xBA\xBE"
DEFAULT_TARGETS = (
    "AVIA_B534",
    "CW_21",
    "DXXI_DK",
    "DXXI_DU",
    "DXXI_SARJA3_EARLY",
    "DXXI_SARJA3_LATE",
    "DXXI_SARJA4",
    "G_55",
    "I_15BIS",
    "I_15BIS_SKIS",
    "I_16TYPE5",
    "I_16TYPE5_SKIS",
    "I_16TYPE6",
    "I_16TYPE6_SKIS",
    "LetovS_328",
    "RE_2000",
    "SM79i",
)
PLANE_INTERNAL_NAME = "com/maddox/il2/objects/vehicles/planes/Plane"
SPAWN_INTERNAL_NAME = "com/maddox/il2/objects/vehicles/planes/PlaneGeneric$SPAWN"
REGISTRATION_PREFIX = "com.maddox.il2.objects.vehicles.planes.Plane$"


def u2(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from(">H", data, offset)[0]


def u4(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


@dataclass(frozen=True)
class Constant:
    tag: int
    values: tuple[int | str, ...]


@dataclass(frozen=True)
class ConstantPool:
    count: int
    end: int
    constants: tuple[Constant | None, ...]

    def utf8(self, index: int) -> str:
        entry = self.constants[index]
        if entry is None or entry.tag != 1:
            raise ValueError(f"Constant #{index} is not UTF-8")
        return str(entry.values[0])

    def class_name(self, index: int) -> str:
        entry = self.constants[index]
        if entry is None or entry.tag != 7:
            raise ValueError(f"Constant #{index} is not a class")
        return self.utf8(int(entry.values[0]))


def parse_constant_pool(data: bytes | bytearray) -> ConstantPool:
    if not data.startswith(CLASS_MAGIC):
        raise ValueError("Input is not a Java class file")
    count = u2(data, 8)
    constants: list[Constant | None] = [None] * count
    offset = 10
    index = 1
    while index < count:
        tag = data[offset]
        offset += 1
        if tag == 1:
            length = u2(data, offset)
            offset += 2
            value = bytes(data[offset : offset + length]).decode("utf-8")
            offset += length
            constants[index] = Constant(tag, (value,))
        elif tag in (3, 4):
            constants[index] = Constant(tag, (u4(data, offset),))
            offset += 4
        elif tag in (5, 6):
            constants[index] = Constant(tag, (u4(data, offset), u4(data, offset + 4)))
            offset += 8
            index += 1
        elif tag in (7, 8):
            constants[index] = Constant(tag, (u2(data, offset),))
            offset += 2
        elif tag in (9, 10, 11, 12):
            constants[index] = Constant(tag, (u2(data, offset), u2(data, offset + 2)))
            offset += 4
        else:
            raise ValueError(f"Unsupported constant-pool tag {tag} at index {index}")
        index += 1
    return ConstantPool(count, offset, tuple(constants))


def find_class_index(pool: ConstantPool, internal_name: str) -> int:
    for index, entry in enumerate(pool.constants):
        if entry is not None and entry.tag == 7 and pool.utf8(int(entry.values[0])) == internal_name:
            return index
    raise ValueError(f"Class constant not found: {internal_name}")


def find_methodref(
    pool: ConstantPool, class_index: int, method_name: str, descriptor: str
) -> int:
    for index, entry in enumerate(pool.constants):
        if entry is None or entry.tag != 10 or int(entry.values[0]) != class_index:
            continue
        name_and_type = pool.constants[int(entry.values[1])]
        if name_and_type is None or name_and_type.tag != 12:
            continue
        name = pool.utf8(int(name_and_type.values[0]))
        desc = pool.utf8(int(name_and_type.values[1]))
        if name == method_name and desc == descriptor:
            return index
    raise ValueError(f"Method reference not found: {method_name}{descriptor}")


def skip_attributes(data: bytes | bytearray, offset: int, count: int) -> int:
    for _ in range(count):
        length = u4(data, offset + 2)
        offset += 6 + length
    return offset


def skip_member(data: bytes | bytearray, offset: int) -> int:
    attribute_count = u2(data, offset + 6)
    return skip_attributes(data, offset + 8, attribute_count)


def find_code_attribute(data: bytes | bytearray, pool: ConstantPool, method_name: str) -> int:
    offset = pool.end + 6
    interface_count = u2(data, offset)
    offset += 2 + interface_count * 2
    field_count = u2(data, offset)
    offset += 2
    for _ in range(field_count):
        offset = skip_member(data, offset)
    method_count = u2(data, offset)
    offset += 2
    for _ in range(method_count):
        name_index = u2(data, offset + 2)
        attribute_count = u2(data, offset + 6)
        attribute_offset = offset + 8
        for _ in range(attribute_count):
            attribute_name = pool.utf8(u2(data, attribute_offset))
            if pool.utf8(name_index) == method_name and attribute_name == "Code":
                return attribute_offset
            attribute_offset += 6 + u4(data, attribute_offset + 2)
        offset = attribute_offset
    raise ValueError(f"Code attribute not found for {method_name}")


def add_string_constants(
    data: bytes, pool: ConstantPool, values: tuple[str, ...]
) -> tuple[bytes, dict[str, int]]:
    utf8_indices: dict[str, int] = {}
    string_indices: dict[str, int] = {}
    for index, entry in enumerate(pool.constants):
        if entry is not None and entry.tag == 1:
            utf8_indices[str(entry.values[0])] = index
    for index, entry in enumerate(pool.constants):
        if entry is not None and entry.tag == 8:
            value = pool.utf8(int(entry.values[0]))
            string_indices[value] = index

    additions = bytearray()
    next_index = pool.count
    result: dict[str, int] = {}
    for value in values:
        if value in string_indices:
            result[value] = string_indices[value]
            continue
        utf8_index = utf8_indices.get(value)
        if utf8_index is None:
            encoded = value.encode("utf-8")
            if len(encoded) > 0xFFFF:
                raise ValueError("UTF-8 constant is too long")
            utf8_index = next_index
            next_index += 1
            additions.extend(b"\x01" + struct.pack(">H", len(encoded)) + encoded)
            utf8_indices[value] = utf8_index
        string_index = next_index
        next_index += 1
        additions.extend(b"\x08" + struct.pack(">H", utf8_index))
        string_indices[value] = string_index
        result[value] = string_index

    if next_index > 0xFFFF:
        raise ValueError("Constant pool would exceed 65535 entries")
    rebuilt = data[:8] + struct.pack(">H", next_index) + data[10 : pool.end] + bytes(additions) + data[pool.end :]
    return rebuilt, result


def patch_class(data: bytes, targets: tuple[str, ...]) -> tuple[bytes, tuple[str, ...]]:
    initial_pool = parse_constant_pool(data)
    registration_names = tuple(REGISTRATION_PREFIX + target for target in targets)
    missing_names = tuple(name for name in registration_names if name.encode("ascii") not in data)
    if not missing_names:
        return data, ()

    this_class_offset = initial_pool.end + 2
    this_class_index = u2(data, this_class_offset)
    if initial_pool.class_name(this_class_index) != PLANE_INTERNAL_NAME:
        raise ValueError(f"Unexpected class: {initial_pool.class_name(this_class_index)}")
    spawn_class_index = find_class_index(initial_pool, SPAWN_INTERNAL_NAME)
    class_helper_index = find_methodref(
        initial_pool,
        this_class_index,
        "class$",
        "(Ljava/lang/String;)Ljava/lang/Class;",
    )
    spawn_constructor_index = find_methodref(
        initial_pool,
        spawn_class_index,
        "<init>",
        "(Ljava/lang/Class;)V",
    )

    rebuilt, string_indices = add_string_constants(data, initial_pool, missing_names)
    rebuilt_pool = parse_constant_pool(rebuilt)
    code_attribute = find_code_attribute(rebuilt, rebuilt_pool, "<clinit>")
    attribute_length_offset = code_attribute + 2
    code_info = code_attribute + 6
    max_stack = u2(rebuilt, code_info)
    code_length_offset = code_info + 4
    code_length = u4(rebuilt, code_length_offset)
    code_start = code_info + 8
    code_end = code_start + code_length
    if max_stack < 4:
        raise ValueError(f"Unexpected <clinit> max_stack: {max_stack}")
    if rebuilt[code_end - 1] != 0xB1:
        raise ValueError("<clinit> does not end with return")
    exception_count = u2(rebuilt, code_end)
    if exception_count != 0:
        raise ValueError("<clinit> unexpectedly contains an exception table")

    instructions = bytearray()
    for name in missing_names:
        instructions.extend(b"\xBB" + struct.pack(">H", spawn_class_index))
        instructions.extend(b"\x59")
        instructions.extend(b"\x13" + struct.pack(">H", string_indices[name]))
        instructions.extend(b"\xB8" + struct.pack(">H", class_helper_index))
        instructions.extend(b"\xB7" + struct.pack(">H", spawn_constructor_index))
        instructions.extend(b"\x57")

    new_code_length = code_length + len(instructions)
    if new_code_length > 0xFFFF:
        raise ValueError("Patched method would exceed the JVM method-size limit")
    buffer = bytearray(rebuilt)
    struct.pack_into(">I", buffer, attribute_length_offset, u4(buffer, attribute_length_offset) + len(instructions))
    struct.pack_into(">I", buffer, code_length_offset, new_code_length)
    insert_at = code_end - 1
    patched = bytes(buffer[:insert_at]) + bytes(instructions) + bytes(buffer[insert_at:])

    for name in missing_names:
        if name.encode("ascii") not in patched:
            raise AssertionError(f"Registration was not written: {name}")
    if patched[6:8] != data[6:8]:
        raise AssertionError("Java class-file version changed")
    return patched, tuple(name.removeprefix(REGISTRATION_PREFIX) for name in missing_names)


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name + ".", suffix=".tmp", delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(data)
    try:
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--expected-sha256")
    parser.add_argument("--target", action="append", dest="targets")
    args = parser.parse_args()

    source = args.input.resolve()
    original = source.read_bytes()
    original_sha = hashlib.sha256(original).hexdigest().upper()
    if args.expected_sha256 and original_sha != args.expected_sha256.upper():
        raise SystemExit(f"Unexpected input SHA-256: {original_sha}")
    targets = tuple(args.targets) if args.targets else DEFAULT_TARGETS
    patched, added = patch_class(original, targets)
    destination = args.output.resolve()
    atomic_write(destination, patched)
    result = {
        "input": str(source),
        "output": str(destination),
        "input_sha256": original_sha,
        "output_sha256": hashlib.sha256(patched).hexdigest().upper(),
        "java_major": int.from_bytes(patched[6:8], "big"),
        "added_registrations": list(added),
        "size_before": len(original),
        "size_after": len(patched),
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
