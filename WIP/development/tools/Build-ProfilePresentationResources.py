#!/usr/bin/env python3
"""Build the stock/modded menu presentation resources kept inside every switcher profile."""
from __future__ import annotations
import argparse
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

PROFILES={
    "4.08 Mods OFF (Original)":"stock",
    "4.08 Mods ON (NO 6DOF)":"modded",
    "4.08 Mods ON 6DOF":"modded",
    "4.09b Mods OFF (Original)":"stock",
    "4.09b Mods ON (NO 6DOF)":"modded",
    "4.09b Mods ON 6DOF":"modded",
    "4.09m Mods OFF (Original)":"stock",
    "4.09m Mods ON (NO 6DOF)":"modded",
    "4.09m Mods ON 6DOF":"modded",
}
STOCK_BACKGROUND_SHA256="07F94BD46D063CCA7363F6C5D62676ABC749C875FBE88277FD0CB4EE732E7591"
MODDED_BACKGROUND_SHA256="88C63E7A103AEA84076E710500255F21D5536B3ECAEB40149615E40A83A2B3B8"
STOCK_NAMES=("de.wav","du.wav","fi.wav","fr.wav","gb.wav","hu.wav","ja.wav","pl.wav","ro.wav","ru.wav","sk.wav","us.wav")
MODDED_NAMES=("Cz.wav","de.wav","du.wav","fr.wav","gb.wav","hu.wav","it.wav","ja.wav","pl.wav","ro.wav","ru.wav","sk.wav","Um.wav","us.wav")

def sha(path:Path)->str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()

def copy_exact(source:Path,target:Path)->None:
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source,target)
    if sha(source)!=sha(target):
        raise RuntimeError(f"Copy verification failed: {target}")

def main()->int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stock-game",type=Path)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[3]
    stock_game=(args.stock_game or (root.parent/"#res/IL2 1946/0 - ORIGINAL GAMES DO NOT MODIFIED/Il-2 Sturmovik 1946 _4.09m")).resolve()
    if not stock_game.is_dir():
        fallback=(root.parent/"#res/IL2 1946/0 - ORIGINAL GAMES DO NOT MODIFIED/Il-2 Sturmovik 1946 _4.09m").resolve()
        stock_game=fallback
    stock_background=stock_game/"Missions/background.tga"
    modded_background=root/"Missions/Background.tga"
    stock_music=stock_game/"samples/Music/Menu"
    modded_music=root/"samples/Music/Menu"
    if sha(stock_background)!=STOCK_BACKGROUND_SHA256:
        raise ValueError(f"Unexpected stock background: {stock_background}")
    if sha(modded_background)!=MODDED_BACKGROUND_SHA256:
        raise ValueError(f"Unexpected Open Sturmovik background: {modded_background}")
    if sorted(p.name for p in stock_music.glob("*.wav"))!=sorted(STOCK_NAMES):
        raise ValueError(f"Unexpected stock music set: {stock_music}")
    if sorted(p.name for p in modded_music.glob("*.wav"))!=sorted(MODDED_NAMES):
        raise ValueError(f"Unexpected Open Sturmovik music set: {modded_music}")

    rows=[]
    for profile,kind in PROFILES.items():
        profile_root=root/"_Game Switcher"/profile/"Profiles"
        target_missions=profile_root/"Missions"
        target_music=profile_root/"samples/Music/Menu"
        for target in (target_missions,target_music):
            if target.exists():
                shutil.rmtree(target)
        if kind=="stock":
            copy_exact(stock_background,target_missions/"Background.tga")
            names=list(STOCK_NAMES)
            for name in names:
                copy_exact(stock_music/name,target_music/name)
            # IL-2 uses the historical Czech filename Cz.wav; the stock packs have
            # no dedicated track, so use their standard continental menu music.
            copy_exact(stock_music/"de.wav",target_music/"Cz.wav")
            names.append("Cz.wav")
        else:
            copy_exact(modded_background,target_missions/"Background.tga")
            names=list(MODDED_NAMES)
            for name in names:
                copy_exact(modded_music/name,target_music/name)
        rows.append({
            "profile":profile,
            "kind":kind,
            "background":{
                "path":(target_missions/"Background.tga").relative_to(root).as_posix(),
                "size":(target_missions/"Background.tga").stat().st_size,
                "sha256":sha(target_missions/"Background.tga"),
            },
            "music":[{
                "path":(target_music/name).relative_to(root).as_posix(),
                "size":(target_music/name).stat().st_size,
                "sha256":sha(target_music/name),
            } for name in sorted(names)],
        })
    report={
        "schemaVersion":1,
        "generatedUtc":datetime.now(timezone.utc).isoformat(),
        "stockSource":str(stock_game),
        "rules":{
            "stock":"official IL-2 1946 background and menu music",
            "modded":"Open Sturmovik background and menu music",
            "czechStockFallback":"Cz.wav is a byte-identical copy of the official stock de.wav track",
        },
        "profiles":rows,
    }
    target=root/"WIP/development/manifests/profile-presentation-resources-v1.15.json"
    target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"PASS: presentation resources built for {len(rows)} profiles; report={target}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
