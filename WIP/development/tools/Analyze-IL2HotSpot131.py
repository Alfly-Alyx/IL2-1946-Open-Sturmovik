#!/usr/bin/env python3
"""Decode la liste de fils de la JVM HotSpot 1.3.1 livree avec IL-2 4.09m."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path


EXPECTED_JVM_SHA256 = "F177D01BA9A87648CD0EBD900197C5FA67BE7E665A5F98A5FFA30E290ADB6B4E"
THREAD_LIST_RVA = 0xC0EA0
THREAD_COUNT_RVA = 0xC0EA4
NON_DAEMON_COUNT_RVA = 0xC0EA8
THREAD_NEXT_OFFSET = 0x6C
THREAD_OOP_OFFSET = 0x70
THREAD_TERMINATED_OFFSET = 0xB8
JAVA_THREAD_NAME_WORD_OFFSET_RVA = 0xB5030
JAVA_THREAD_DAEMON_WORD_OFFSET_RVA = 0xB5044
KLASS_NAME_SYMBOL_OFFSET = 0x24
SYMBOL_LENGTH_OFFSET = 0x0C
SYMBOL_BODY_OFFSET = 0x0E
THREAD_BASE_INSTANCE_SIZE = 0x40


def u32(reader, address: int) -> int:
    return struct.unpack("<I", reader.read(address, 4))[0]


def u64(reader, address: int) -> int:
    return struct.unpack("<q", reader.read(address, 8))[0]


def read_klass_name(reader, object_oop: int) -> tuple[int, str | None]:
    if not object_oop:
        return 0, None
    try:
        klass = u32(reader, object_oop + 4)
        symbol = u32(reader, klass + KLASS_NAME_SYMBOL_OFFSET)
        length = struct.unpack("<H", reader.read(symbol + SYMBOL_LENGTH_OFFSET, 2))[0]
        if not 1 <= length <= 512:
            return klass, None
        raw = reader.read(symbol + SYMBOL_BODY_OFFSET, length)
        name = raw.decode("ascii", errors="replace")
        if sum(character.isprintable() for character in name) < len(name) * 0.9:
            return klass, None
        return klass, name
    except Exception:
        return 0, None


def decode_timer_thread(reader, thread_oop: int, klass_name: str | None) -> dict | None:
    if klass_name != "java/util/TimerThread":
        return None
    try:
        queue_oop = u32(reader, thread_oop + THREAD_BASE_INSTANCE_SIZE)
        accepts_new_tasks = bool(reader.read(thread_oop + THREAD_BASE_INSTANCE_SIZE + 4, 1)[0])
        task_array_oop = u32(reader, queue_oop + 8)
        queue_size = u32(reader, queue_oop + 12)
        tasks = []
        for queue_index in range(1, min(queue_size, 128) + 1):
            task_oop = u32(reader, task_array_oop + 12 + queue_index * 4)
            if not task_oop:
                continue
            task_klass, task_klass_name = read_klass_name(reader, task_oop)
            tasks.append(
                {
                    "queue_index": queue_index,
                    "task_oop": f"0x{task_oop:08X}",
                    "klass": f"0x{task_klass:08X}",
                    "klass_name": task_klass_name,
                    "state": u32(reader, task_oop + 12),
                    "next_execution_time_ms": u64(reader, task_oop + 16),
                    "period_ms": u64(reader, task_oop + 24),
                }
            )
        return {
            "queue_oop": f"0x{queue_oop:08X}",
            "queue_size": queue_size,
            "new_tasks_may_be_scheduled": accepts_new_tasks,
            "tasks": tasks,
        }
    except Exception as error:
        return {"decode_error": str(error)}


def read_java_chars(reader, array_oop: int) -> str | None:
    if not array_oop:
        return None
    for length_offset, data_offset in ((8, 12), (12, 16)):
        try:
            length = u32(reader, array_oop + length_offset)
            if 0 < length <= 512:
                raw = reader.read(array_oop + data_offset, length * 2)
                value = raw.decode("utf-16-le", errors="replace")
                if sum(character.isprintable() for character in value) >= len(value) * 0.8:
                    return value
        except Exception:
            pass
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("dump", type=Path)
    parser.add_argument("--packages", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.packages.resolve()))
    from minidump.minidumpfile import MinidumpFile  # type: ignore

    parsed = MinidumpFile.parse(str(args.dump.resolve()))
    reader = parsed.get_reader()
    jvm = next(
        module for module in parsed.modules.modules if Path(module.name).name.lower() == "jvm.dll"
    )
    jvm_path = Path(jvm.name)
    jvm_hash = hashlib.sha256(jvm_path.read_bytes()).hexdigest().upper()
    if jvm_hash != EXPECTED_JVM_SHA256:
        raise RuntimeError(f"jvm.dll non reconnue : {jvm_hash}")

    base = int(jvm.baseaddress)
    name_word_offset = u32(reader, base + JAVA_THREAD_NAME_WORD_OFFSET_RVA)
    daemon_word_offset = u32(reader, base + JAVA_THREAD_DAEMON_WORD_OFFSET_RVA)
    native_thread_ids = {int(thread.ThreadId) for thread in parsed.threads.threads}
    current = u32(reader, base + THREAD_LIST_RVA)
    declared_count = u32(reader, base + THREAD_COUNT_RVA)
    non_daemon_count = u32(reader, base + NON_DAEMON_COUNT_RVA)
    seen = set()
    threads = []

    while current and current not in seen and len(threads) < 128:
        seen.add(current)
        next_thread = u32(reader, current + THREAD_NEXT_OFFSET)
        thread_oop = u32(reader, current + THREAD_OOP_OFFSET)
        terminated = u32(reader, current + THREAD_TERMINATED_OFFSET)
        daemon = None
        name_pointer = 0
        name = None
        oop_klass = 0
        oop_klass_name = None
        timer_thread = None
        if thread_oop:
            try:
                daemon = bool(reader.read(thread_oop + daemon_word_offset * 4, 1)[0])
                name_pointer = u32(reader, thread_oop + name_word_offset * 4)
                name = read_java_chars(reader, name_pointer)
                oop_klass, oop_klass_name = read_klass_name(reader, thread_oop)
                timer_thread = decode_timer_thread(reader, thread_oop, oop_klass_name)
            except Exception:
                pass

        oop_words = []
        if thread_oop:
            try:
                oop_raw = reader.read(thread_oop, 0x60)
                oop_values = struct.unpack("<" + "I" * (len(oop_raw) // 4), oop_raw)
                oop_words = [
                    {"word": index, "offset": f"0x{index * 4:X}", "value": f"0x{value:08X}"}
                    for index, value in enumerate(oop_values)
                ]
            except Exception:
                pass

        direct_tid_hits = []
        nested_tid_hits = []
        try:
            raw = reader.read(current, 0x180)
            words = struct.unpack("<" + "I" * (len(raw) // 4), raw[: len(raw) // 4 * 4])
            for index, value in enumerate(words):
                if value in native_thread_ids:
                    direct_tid_hits.append({"offset": f"0x{index * 4:X}", "thread_id": value})
                if 0x10000 <= value <= 0x7FFFFFFF:
                    try:
                        nested = reader.read(value, 0x100)
                        nested_words = struct.unpack(
                            "<" + "I" * (len(nested) // 4), nested[: len(nested) // 4 * 4]
                        )
                        for nested_index, nested_value in enumerate(nested_words):
                            if nested_value in native_thread_ids:
                                hit = {
                                    "pointer_offset": f"0x{index * 4:X}",
                                    "pointer": f"0x{value:08X}",
                                    "nested_offset": f"0x{nested_index * 4:X}",
                                    "thread_id": nested_value,
                                }
                                if hit not in nested_tid_hits:
                                    nested_tid_hits.append(hit)
                    except Exception:
                        pass
        except Exception:
            pass

        threads.append(
            {
                "java_thread": f"0x{current:08X}",
                "next": f"0x{next_thread:08X}",
                "thread_oop": f"0x{thread_oop:08X}",
                "thread_oop_klass": f"0x{oop_klass:08X}",
                "thread_oop_klass_name": oop_klass_name,
                "name_pointer": f"0x{name_pointer:08X}",
                "name": name,
                "daemon": daemon,
                "terminated": terminated,
                "timer_thread": timer_thread,
                "thread_oop_words": oop_words,
                "direct_native_thread_id_hits": direct_tid_hits,
                "nested_native_thread_id_hits": nested_tid_hits[:32],
            }
        )
        current = next_thread

    report = {
        "dump": str(args.dump.resolve()),
        "jvm_path": str(jvm_path),
        "jvm_sha256": jvm_hash,
        "jvm_base": f"0x{base:08X}",
        "declared_thread_count": declared_count,
        "decoded_thread_count": len(threads),
        "non_daemon_thread_count": non_daemon_count,
        "java_thread_name_word_offset": name_word_offset,
        "java_thread_daemon_word_offset": daemon_word_offset,
        "threads": threads,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"ANALYSE_HOTSPOT : {args.output.resolve()}")
    print(
        f"THREADS : declares={declared_count} decodes={len(threads)} "
        f"non_daemon={non_daemon_count}"
    )
    for thread in threads:
        hits = thread["direct_native_thread_id_hits"] + thread["nested_native_thread_id_hits"]
        native_ids = sorted({hit["thread_id"] for hit in hits})
        print(
            f"{thread['java_thread']} daemon={thread['daemon']} "
            f"termine={thread['terminated']} nom={thread['name']!r} "
            f"classe={thread['thread_oop_klass_name']!r} tids={native_ids}"
        )
        if thread["timer_thread"]:
            for task in thread["timer_thread"].get("tasks", []):
                print(
                    f"  TIMER_TASK index={task['queue_index']} "
                    f"classe={task['klass_name']!r} periode_ms={task['period_ms']}"
                )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
