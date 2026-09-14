#!/usr/bin/env python3
"""Build verified loose language resources for every language offered by the switcher."""
from __future__ import annotations
import hashlib, importlib.util, json, shutil, sys
from datetime import datetime, timezone
from pathlib import Path

WESTERN=("cs","de","hu","pl")
OFFERED=("fr","us","ru",*WESTERN)
VERSIONS={
 "4.08m":("4.08 Mods OFF (Original)","4.08 Mods ON (NO 6DOF)"),
 "4.09b":("4.09b Mods OFF (Original)","4.09b Mods ON (NO 6DOF)"),
 "4.09m":("4.09m Mods OFF (Original)","4.09m Mods ON (NO 6DOF)"),
}
EXPECTED={"cs":33,"de":23,"hu":20,"pl":29}
def sha(data:bytes)->str:return hashlib.sha256(data).hexdigest().upper()
def load_archive(path:Path):
 spec=importlib.util.spec_from_file_location("analyze_sfs_game_languages",path)
 if spec is None or spec.loader is None: raise RuntimeError(path)
 module=importlib.util.module_from_spec(spec);sys.modules[spec.name]=module;spec.loader.exec_module(module)
 return module.SfsArchive

def main()->int:
 root=Path(__file__).resolve().parents[3]
 if not (root/"Open_Sturmovik_Switcher.bat").is_file(): raise RuntimeError(f"Unexpected repository root: {root}")
 Archive=load_archive(root/"WIP/development/tools/Analyze-Sfs.py")
 names=sorted(p.name[:-len("_fr.properties")] for p in (root/"Files/i18n").glob("*_fr.properties"))
 if len(names)!=36: raise ValueError(f"Expected 36 French catalogue names, got {len(names)}")
 french={name:(root/"Files/i18n"/f"{name}_fr.properties").read_bytes() for name in names}
 stock:dict[str,dict[str,dict[str,bytes]]]={}
 russian:dict[str,dict[str,bytes]]={}
 for version,(stock_folder,mod_folder) in VERSIONS.items():
  stock[version]={}
  with Archive(root/"_Game Switcher"/stock_folder/"files.SFS") as archive:
   base={name:archive.extract_path(f"i18n/{name}.properties") for name in names}
   if len(base)!=len(names): raise ValueError(f"{version}/us: expected {len(names)}, got {len(base)}")
   stock[version]["us"]=base
   for locale in WESTERN:
    found={}
    for name in names:
     rel=f"i18n/{name}_{locale}.properties"
     try: found[name]=archive.extract_path(rel)
     except KeyError: pass
    if len(found)!=EXPECTED[locale]: raise ValueError(f"{version}/{locale}: expected {EXPECTED[locale]}, got {len(found)}")
    stock[version][locale]=found
  with Archive(root/"_Game Switcher"/mod_folder/"files.SFS") as archive:
   found={}
   for name in names:
    rel=f"i18n/{name}_ru.properties"
    try: found[name]=archive.extract_path(rel)
    except KeyError: pass
   if len(found)!=len(names): raise ValueError(f"{version}/ru: expected {len(names)}, got {len(found)}")
   russian[version]=found
 active=root/"Files/i18n"
 for name in names: (active/f"{name}_ru.properties").write_bytes(russian["4.09m"][name])
 for locale in WESTERN:
  for name,data in stock["4.09m"][locale].items(): (active/f"{name}_{locale}.properties").write_bytes(data)
 generated=root/"_Game Switcher/Languages"
 if generated.exists():
  if generated.resolve().parent != (root/"_Game Switcher").resolve(): raise RuntimeError(generated)
  shutil.rmtree(generated)
 resources={version:{locale:stock[version][locale] for locale in WESTERN} for version in VERSIONS}
 for version in VERSIONS: resources[version]["ru"]=russian[version]
 differing=[]
 for locale in (*WESTERN,"ru"):
  common_names=set.intersection(*(set(resources[v][locale]) for v in VERSIONS))
  for name in sorted(common_names):
   hashes={sha(resources[v][locale][name]) for v in VERSIONS}
   if len(hashes)>1:
    differing.append(f"{name}_{locale}.properties")
    for version in VERSIONS:
     target=generated/version/"i18n"/f"{name}_{locale}.properties"
     target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(resources[version][locale][name])
 for version in VERSIONS:
  for locale in OFFERED:
   if locale=="fr": resolved=french
   elif locale=="us": resolved=stock[version]["us"]
   elif locale=="ru": resolved=russian[version]
   else: resolved={name:stock[version][locale].get(name,stock[version]["us"][name]) for name in names}
   if len(resolved)!=len(names): raise ValueError(f"{version}/{locale}: incomplete modded alias set")
   for name,data in resolved.items():
    target=generated/version/"Modded Aliases"/locale/"i18n"/f"{name}_ru.properties"
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
 report={
  "schemaVersion":1,"generatedUtc":datetime.now(timezone.utc).isoformat(),
  "offeredLanguages":["fr","us","ru","de","cs","hu","pl"],
  "catalogueNames":len(names),
  "westernCounts":EXPECTED,
  "russianCount":len(names),
  "russianSource":"modded files.SFS for each engine",
  "versionSpecificFiles":sorted(differing),
  "versionSpecificCount":len(differing),
  "moddedAliasRule":"Modded executables load the _ru suffix; each selected language is therefore materialized as a complete 36-file _ru catalogue set, with stock English fallback for untranslated catalogues.",
  "moddedAliasFilesPerVersionAndLanguage":len(names),
  "activeOutputs":{},"versionOutputs":[],"moddedAliasOutputs":[]}
 for locale in (*WESTERN,"ru"):
  files=sorted(active.glob(f"*_{locale}.properties"))
  report["activeOutputs"][locale]={"count":len(files),"bytes":sum(p.stat().st_size for p in files)}
 for path in sorted(generated.glob("*/i18n/*.properties")):
  report["versionOutputs"].append({"path":path.relative_to(root).as_posix(),"size":path.stat().st_size,"sha256":sha(path.read_bytes())})
 for path in sorted(generated.glob("*/Modded Aliases/*/i18n/*.properties")):
  report["moddedAliasOutputs"].append({"path":path.relative_to(root).as_posix(),"size":path.stat().st_size,"sha256":sha(path.read_bytes())})
 target=root/"WIP/development/manifests/game-language-resources-v1.15.json"
 target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
 print(f"PASS: 7 languages prepared; {len(differing)} version-specific files x 3 engines; {len(report['moddedAliasOutputs'])} modded aliases; report={target}")
 return 0
if __name__=="__main__":raise SystemExit(main())

