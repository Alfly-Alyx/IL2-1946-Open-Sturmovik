#!/usr/bin/env python3
"""Inspecte statiquement un il2setup.exe sans charger ni executer son code.

Le script utilise uniquement la bibliotheque standard Python. Il lit les tables
PE, les imports, les ressources RT_STRING et les boites de dialogue Windows.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any


RT_DIALOG = 5
RT_STRING = 6


class PeFormatError(ValueError):
    pass


class PeFile:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data = path.read_bytes()
        if self.data[:2] != b"MZ":
            raise PeFormatError("Signature DOS MZ absente")
        self.pe_offset = self.u32(0x3C)
        if self.data[self.pe_offset : self.pe_offset + 4] != b"PE\0\0":
            raise PeFormatError("Signature PE absente")

        coff = self.pe_offset + 4
        self.machine = self.u16(coff)
        self.section_count = self.u16(coff + 2)
        optional_size = self.u16(coff + 16)
        optional = coff + 20
        magic = self.u16(optional)
        if magic == 0x10B:
            self.pointer_size = 4
            data_directories = optional + 96
        elif magic == 0x20B:
            self.pointer_size = 8
            data_directories = optional + 112
        else:
            raise PeFormatError(f"Format optionnel PE inconnu: 0x{magic:04X}")

        self.directories = [
            (self.u32(data_directories + index * 8), self.u32(data_directories + index * 8 + 4))
            for index in range(16)
        ]
        self.sections: list[dict[str, int | str]] = []
        section_offset = optional + optional_size
        for index in range(self.section_count):
            offset = section_offset + index * 40
            name = self.data[offset : offset + 8].split(b"\0", 1)[0].decode("ascii", "replace")
            self.sections.append(
                {
                    "name": name,
                    "virtual_size": self.u32(offset + 8),
                    "virtual_address": self.u32(offset + 12),
                    "raw_size": self.u32(offset + 16),
                    "raw_offset": self.u32(offset + 20),
                }
            )

    def require(self, offset: int, size: int) -> None:
        if offset < 0 or size < 0 or offset + size > len(self.data):
            raise PeFormatError(f"Lecture hors fichier a 0x{offset:X} ({size} octets)")

    def u8(self, offset: int) -> int:
        self.require(offset, 1)
        return self.data[offset]

    def u16(self, offset: int) -> int:
        self.require(offset, 2)
        return struct.unpack_from("<H", self.data, offset)[0]

    def i16(self, offset: int) -> int:
        self.require(offset, 2)
        return struct.unpack_from("<h", self.data, offset)[0]

    def u32(self, offset: int) -> int:
        self.require(offset, 4)
        return struct.unpack_from("<I", self.data, offset)[0]

    def u64(self, offset: int) -> int:
        self.require(offset, 8)
        return struct.unpack_from("<Q", self.data, offset)[0]

    def rva_to_offset(self, rva: int) -> int:
        for section in self.sections:
            start = int(section["virtual_address"])
            span = max(int(section["virtual_size"]), int(section["raw_size"]))
            if start <= rva < start + span:
                return int(section["raw_offset"]) + (rva - start)
        if 0 <= rva < len(self.data):
            return rva
        raise PeFormatError(f"RVA non mappee: 0x{rva:X}")

    def c_string_at_rva(self, rva: int) -> str:
        offset = self.rva_to_offset(rva)
        end = self.data.find(b"\0", offset)
        if end < 0:
            raise PeFormatError(f"Chaine non terminee a RVA 0x{rva:X}")
        return self.data[offset:end].decode("ascii", "replace")

    def imports(self) -> list[dict[str, Any]]:
        import_rva, import_size = self.directories[1]
        if not import_rva or not import_size:
            return []
        offset = self.rva_to_offset(import_rva)
        result: list[dict[str, Any]] = []
        while True:
            original_thunk = self.u32(offset)
            timestamp = self.u32(offset + 4)
            forwarder = self.u32(offset + 8)
            name_rva = self.u32(offset + 12)
            first_thunk = self.u32(offset + 16)
            if not any((original_thunk, timestamp, forwarder, name_rva, first_thunk)):
                break
            dll = self.c_string_at_rva(name_rva)
            thunk_rva = original_thunk or first_thunk
            thunk_offset = self.rva_to_offset(thunk_rva)
            names: list[str] = []
            ordinal_mask = 1 << (self.pointer_size * 8 - 1)
            while True:
                value = self.u64(thunk_offset) if self.pointer_size == 8 else self.u32(thunk_offset)
                if value == 0:
                    break
                if value & ordinal_mask:
                    names.append(f"ordinal:{value & 0xFFFF}")
                else:
                    name_offset = self.rva_to_offset(value)
                    end = self.data.find(b"\0", name_offset + 2)
                    names.append(self.data[name_offset + 2 : end].decode("ascii", "replace"))
                thunk_offset += self.pointer_size
            result.append({"dll": dll, "functions": names})
            offset += 20
        return result

    def resources(self) -> list[dict[str, Any]]:
        resource_rva, resource_size = self.directories[2]
        if not resource_rva or not resource_size:
            return []
        root_offset = self.rva_to_offset(resource_rva)
        result: list[dict[str, Any]] = []

        def resource_name(raw: int) -> int | str:
            if not raw & 0x80000000:
                return raw
            offset = root_offset + (raw & 0x7FFFFFFF)
            length = self.u16(offset)
            start = offset + 2
            self.require(start, length * 2)
            return self.data[start : start + length * 2].decode("utf-16le", "replace")

        def visit(relative: int, path: list[int | str]) -> None:
            directory = root_offset + relative
            named = self.u16(directory + 12)
            identified = self.u16(directory + 14)
            entry = directory + 16
            for index in range(named + identified):
                raw_name = self.u32(entry + index * 8)
                raw_target = self.u32(entry + index * 8 + 4)
                name = resource_name(raw_name)
                if raw_target & 0x80000000:
                    visit(raw_target & 0x7FFFFFFF, path + [name])
                else:
                    data_entry = root_offset + raw_target
                    data_rva = self.u32(data_entry)
                    size = self.u32(data_entry + 4)
                    codepage = self.u32(data_entry + 8)
                    data_offset = self.rva_to_offset(data_rva)
                    self.require(data_offset, size)
                    result.append(
                        {
                            "path": path + [name],
                            "offset": data_offset,
                            "size": size,
                            "codepage": codepage,
                            "data": self.data[data_offset : data_offset + size],
                        }
                    )

        visit(0, [])
        return result


def align(value: int, alignment: int = 4) -> int:
    return (value + alignment - 1) & ~(alignment - 1)


def read_utf16_field(data: bytes, offset: int) -> tuple[int | str | None, int]:
    if offset + 2 > len(data):
        raise PeFormatError("Champ de ressource tronque")
    first = struct.unpack_from("<H", data, offset)[0]
    offset += 2
    if first == 0:
        return None, offset
    if first == 0xFFFF:
        if offset + 2 > len(data):
            raise PeFormatError("Ordinal de ressource tronque")
        return struct.unpack_from("<H", data, offset)[0], offset + 2
    chars = [first]
    while True:
        if offset + 2 > len(data):
            raise PeFormatError("Chaine UTF-16 de ressource non terminee")
        value = struct.unpack_from("<H", data, offset)[0]
        offset += 2
        if value == 0:
            break
        chars.append(value)
    return bytes(struct.pack("<" + "H" * len(chars), *chars)).decode("utf-16le", "replace"), offset


def parse_dialog(data: bytes) -> dict[str, Any]:
    if len(data) < 18:
        raise PeFormatError("Dialogue trop court")
    extended = struct.unpack_from("<HH", data, 0) == (1, 0xFFFF)
    if extended:
        _, _, help_id, ex_style, style, count, x, y, cx, cy = struct.unpack_from(
            "<HHIIIHhhhh", data, 0
        )
        offset = 26
    else:
        style, ex_style, count, x, y, cx, cy = struct.unpack_from("<IIHhhhh", data, 0)
        help_id = 0
        offset = 18

    menu, offset = read_utf16_field(data, offset)
    window_class, offset = read_utf16_field(data, offset)
    title, offset = read_utf16_field(data, offset)
    font: dict[str, Any] | None = None
    if style & 0x40:
        if extended:
            point_size, weight = struct.unpack_from("<HH", data, offset)
            italic = data[offset + 4]
            charset = data[offset + 5]
            offset += 6
            face, offset = read_utf16_field(data, offset)
            font = {
                "pointSize": point_size,
                "weight": weight,
                "italic": italic,
                "charset": charset,
                "face": face,
            }
        else:
            point_size = struct.unpack_from("<H", data, offset)[0]
            offset += 2
            face, offset = read_utf16_field(data, offset)
            font = {"pointSize": point_size, "face": face}

    controls: list[dict[str, Any]] = []
    for _ in range(count):
        offset = align(offset)
        if extended:
            help_item, ex_item, style_item, ix, iy, icx, icy, control_id = struct.unpack_from(
                "<IIIhhhhI", data, offset
            )
            offset += 24
        else:
            style_item, ex_item, ix, iy, icx, icy, control_id = struct.unpack_from(
                "<IIhhhhH", data, offset
            )
            help_item = 0
            offset += 18
        item_class, offset = read_utf16_field(data, offset)
        item_title, offset = read_utf16_field(data, offset)
        extra_size = struct.unpack_from("<H", data, offset)[0]
        offset += 2 + extra_size
        controls.append(
            {
                "id": control_id,
                "class": item_class,
                "title": item_title,
                "position": [ix, iy, icx, icy],
                "style": f"0x{style_item:08X}",
                "extendedStyle": f"0x{ex_item:08X}",
                "helpId": help_item,
            }
        )

    return {
        "extended": extended,
        "title": title,
        "position": [x, y, cx, cy],
        "style": f"0x{style:08X}",
        "extendedStyle": f"0x{ex_style:08X}",
        "helpId": help_id,
        "menu": menu,
        "class": window_class,
        "font": font,
        "controls": controls,
    }


def decode_strings(resources: list[dict[str, Any]]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for resource in resources:
        path = resource["path"]
        if len(path) < 2 or path[0] != RT_STRING or not isinstance(path[1], int):
            continue
        block_id = path[1]
        data = resource["data"]
        offset = 0
        for index in range(16):
            if offset + 2 > len(data):
                break
            length = struct.unpack_from("<H", data, offset)[0]
            offset += 2
            raw = data[offset : offset + length * 2]
            offset += length * 2
            if length:
                result.append(
                    {
                        "id": (block_id - 1) * 16 + index,
                        "language": path[2] if len(path) > 2 else None,
                        "text": raw.decode("utf-16le", "replace"),
                    }
                )
    return result


def decode_dialogs(resources: list[dict[str, Any]]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for resource in resources:
        path = resource["path"]
        if len(path) < 2 or path[0] != RT_DIALOG:
            continue
        try:
            dialog = parse_dialog(resource["data"])
            dialog["id"] = path[1]
            dialog["language"] = path[2] if len(path) > 2 else None
            result.append(dialog)
        except (PeFormatError, struct.error) as error:
            result.append(
                {
                    "id": path[1],
                    "language": path[2] if len(path) > 2 else None,
                    "error": str(error),
                }
            )
    return result


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser()
    parser.add_argument("executable", type=Path)
    parser.add_argument(
        "--section",
        choices=("all", "summary", "imports", "strings", "dialogs"),
        default="all",
    )
    args = parser.parse_args()

    pe = PeFile(args.executable.resolve())
    resources = pe.resources()
    output: dict[str, Any] = {
        "file": str(pe.path.resolve()),
        "size": len(pe.data),
        "machine": f"0x{pe.machine:04X}",
        "sections": pe.sections,
        "resourceCount": len(resources),
    }
    if args.section in ("all", "imports"):
        output["imports"] = pe.imports()
    if args.section in ("all", "strings"):
        output["strings"] = decode_strings(resources)
    if args.section in ("all", "dialogs"):
        output["dialogs"] = decode_dialogs(resources)

    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
