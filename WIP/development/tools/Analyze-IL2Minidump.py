#!/usr/bin/env python3
"""Analyse reproductible d'un dump x86 IL-2 sans installation systeme."""

from __future__ import annotations

import argparse
import bisect
import json
import os
import struct
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("dump", type=Path)
    parser.add_argument("--packages", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--stack-bytes", type=int, default=65536)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    sys.path.insert(0, str(args.packages.resolve()))
    import pefile  # type: ignore
    from minidump.minidumpfile import MinidumpFile  # type: ignore

    dump_path = args.dump.resolve()
    parsed = MinidumpFile.parse(str(dump_path))
    reader = parsed.get_reader()
    modules = sorted(parsed.modules.modules, key=lambda module: module.baseaddress)
    module_starts = [module.baseaddress for module in modules]
    exports_cache: dict[str, list[tuple[int, str]]] = {}

    def physical_module_path(module) -> Path:
        path = Path(module.name)
        if "INTEL" in str(parsed.sysinfo.ProcessorArchitecture):
            lowered = str(path).lower()
            system32_marker = "\\windows\\system32\\"
            if system32_marker in lowered:
                windows_root = Path(os.environ.get("SystemRoot", r"C:\Windows"))
                wow64_path = windows_root / "SysWOW64" / path.name
                if wow64_path.is_file():
                    return wow64_path
        return path

    def module_for(address: int):
        index = bisect.bisect_right(module_starts, address) - 1
        if index >= 0 and address < modules[index].endaddress:
            return modules[index]
        return None

    def exports_for(module) -> list[tuple[int, str]]:
        key = module.name.lower()
        if key in exports_cache:
            return exports_cache[key]
        exports: list[tuple[int, str]] = []
        try:
            path = physical_module_path(module)
            if path.is_file():
                pe = pefile.PE(str(path), fast_load=True)
                pe.parse_data_directories(
                    directories=[pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"]]
                )
                for symbol in getattr(pe, "DIRECTORY_ENTRY_EXPORT", ()).symbols:
                    name = (
                        symbol.name.decode("ascii", errors="replace")
                        if symbol.name
                        else f"ordinal_{symbol.ordinal}"
                    )
                    exports.append((module.baseaddress + int(symbol.address), name))
                exports.sort()
        except Exception:
            exports = []
        exports_cache[key] = exports
        return exports

    def describe_address(address: int) -> dict:
        module = module_for(address)
        if module is None:
            return {"address": f"0x{address:08X}", "module": None}
        result = {
            "address": f"0x{address:08X}",
            "module": os.path.basename(module.name),
            "module_path": module.name,
            "module_offset": f"0x{address - module.baseaddress:X}",
        }
        exports = exports_for(module)
        if exports:
            positions = [item[0] for item in exports]
            export_index = bisect.bisect_right(positions, address) - 1
            if export_index >= 0:
                export_address, export_name = exports[export_index]
                result["nearest_export"] = export_name
                result["export_offset"] = f"0x{address - export_address:X}"
        return result

    info_by_thread = {}
    if parsed.thread_info is not None:
        info_by_thread = {info.ThreadId: info for info in parsed.thread_info.infos}

    thread_reports = []
    for thread in parsed.threads.threads:
        context = thread.ContextObject
        stack_start = int(context.Esp)
        stack_descriptor_start = int(thread.Stack.StartOfMemoryRange)
        stack_descriptor_end = stack_descriptor_start + int(thread.Stack.DataSize)
        scan_size = max(0, min(args.stack_bytes, stack_descriptor_end - stack_start))
        try:
            stack_data = reader.read(stack_start, scan_size) if scan_size else b""
        except Exception:
            stack_data = b""

        candidates = []
        seen_candidates = set()
        stack_words = []
        for offset in range(0, min(len(stack_data), 256) - 3, 4):
            value = struct.unpack_from("<I", stack_data, offset)[0]
            word = {
                "stack_offset": f"0x{offset:X}",
                "value": f"0x{value:08X}",
            }
            if module_for(value) is not None:
                word["address"] = describe_address(value)
            stack_words.append(word)
        for offset in range(0, len(stack_data) - 3, 4):
            value = struct.unpack_from("<I", stack_data, offset)[0]
            module = module_for(value)
            key = (value, offset)
            if module is not None and key not in seen_candidates:
                seen_candidates.add(key)
                described = describe_address(value)
                described["stack_offset"] = f"0x{offset:X}"
                candidates.append(described)
                if len(candidates) >= 96:
                    break

        ebp_frames = []
        current_ebp = int(context.Ebp)
        visited_ebp = set()
        for _ in range(64):
            if current_ebp in visited_ebp or current_ebp < stack_start:
                break
            if current_ebp + 8 > stack_descriptor_end:
                break
            visited_ebp.add(current_ebp)
            try:
                frame_data = reader.read(current_ebp, 8)
                previous_ebp, return_address = struct.unpack("<II", frame_data)
            except Exception:
                break
            described = describe_address(return_address)
            described["ebp"] = f"0x{current_ebp:08X}"
            ebp_frames.append(described)
            if previous_ebp <= current_ebp:
                break
            current_ebp = previous_ebp

        info = info_by_thread.get(thread.ThreadId)
        thread_reports.append(
            {
                "thread_id": thread.ThreadId,
                "start_address": describe_address(int(info.StartAddress)) if info else None,
                "create_time": int(info.CreateTime) if info else None,
                "kernel_time_100ns": int(info.KernelTime) if info else None,
                "user_time_100ns": int(info.UserTime) if info else None,
                "affinity": int(info.Affinity) if info else None,
                "registers": {
                    "eip": f"0x{int(context.Eip):08X}",
                    "esp": f"0x{int(context.Esp):08X}",
                    "ebp": f"0x{int(context.Ebp):08X}",
                    "eax": f"0x{int(context.Eax):08X}",
                    "ebx": f"0x{int(context.Ebx):08X}",
                    "ecx": f"0x{int(context.Ecx):08X}",
                    "edx": f"0x{int(context.Edx):08X}",
                    "esi": f"0x{int(context.Esi):08X}",
                    "edi": f"0x{int(context.Edi):08X}",
                },
                "current": describe_address(int(context.Eip)),
                "stack_range": {
                    "start": f"0x{stack_descriptor_start:08X}",
                    "end": f"0x{stack_descriptor_end:08X}",
                    "captured_bytes_from_esp": len(stack_data),
                },
                "ebp_frames": ebp_frames,
                "stack_words": stack_words,
                "stack_candidates": candidates,
            }
        )

    earliest_thread = min(
        (report for report in thread_reports if report["create_time"] is not None),
        key=lambda report: report["create_time"],
        default=None,
    )
    report = {
        "dump": str(dump_path),
        "size": dump_path.stat().st_size,
        "architecture": str(parsed.sysinfo.ProcessorArchitecture),
        "processor_count": int(parsed.sysinfo.NumberOfProcessors),
        "process": parsed.misc_info.__dict__ if parsed.misc_info else None,
        "exception_stream_present": parsed.exception is not None,
        "thread_count": len(thread_reports),
        "module_count": len(modules),
        "probable_main_thread_id": earliest_thread["thread_id"] if earliest_thread else None,
        "modules": [
            {
                "name": os.path.basename(module.name),
                "path": module.name,
                "base": f"0x{module.baseaddress:08X}",
                "end": f"0x{module.endaddress:08X}",
                "size": int(module.size),
                "timestamp": int(module.timestamp),
            }
            for module in modules
        ],
        "threads": thread_reports,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"ANALYSE_DUMP : {args.output.resolve()}")
    print(f"THREADS : {len(thread_reports)}")
    print(f"MODULES : {len(modules)}")
    print(f"MAIN_THREAD : {report['probable_main_thread_id']}")
    for thread in thread_reports:
        current = thread["current"]
        symbol = current.get("nearest_export", "")
        offset = current.get("export_offset", "")
        print(
            f"TID {thread['thread_id']:5d} {current['address']} "
            f"{current.get('module') or '?'} {symbol}+{offset}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
