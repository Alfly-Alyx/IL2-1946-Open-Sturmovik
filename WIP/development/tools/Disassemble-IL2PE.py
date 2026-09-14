#!/usr/bin/env python3
"""Desassemble quelques adresses x86 d'un module IL-2 avec contexte."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def number(value: str) -> int:
    return int(value, 0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("module", type=Path)
    parser.add_argument("--packages", type=Path, required=True)
    parser.add_argument("--base", type=number, required=True)
    parser.add_argument("--address", type=number, action="append", required=True)
    parser.add_argument("--back", type=number, default=0x800)
    parser.add_argument("--forward", type=number, default=0x100)
    args = parser.parse_args()

    sys.path.insert(0, str(args.packages.resolve()))
    import pefile  # type: ignore
    from capstone import CS_ARCH_X86, CS_MODE_32, Cs  # type: ignore

    pe = pefile.PE(str(args.module.resolve()), fast_load=False)
    engine = Cs(CS_ARCH_X86, CS_MODE_32)
    engine.detail = False
    for address in args.address:
        rva = address - args.base if address >= args.base else address
        search_start = max(0, rva - args.back)
        prefix = pe.get_data(search_start, rva - search_start)
        prologues = [match.start() for match in re.finditer(b"\x55\x8b\xec", prefix)]
        start_rva = search_start + prologues[-1] if prologues else max(0, rva - 0x40)
        code = pe.get_data(start_rva, (rva - start_rva) + args.forward)
        print(f"\nADDRESS 0x{address:08X} RVA 0x{rva:X} START_RVA 0x{start_rva:X}")
        for instruction in engine.disasm(code, args.base + start_rva):
            marker = "=>" if instruction.address == address else "  "
            print(
                f"{marker} {instruction.address:08X} "
                f"{instruction.mnemonic:<8} {instruction.op_str}"
            )
            if instruction.address > address + args.forward:
                break
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
