#!/usr/bin/env python3
"""Build language-correct standard and immersion HUD resources."""
from __future__ import annotations
import hashlib,json,re
from datetime import datetime,timezone
from pathlib import Path

LOCALES=("fr","ru","de","cs","hu","pl")
def sha(data:bytes)->str:return hashlib.sha256(data).hexdigest().upper()
def values(data:bytes)->dict[bytes,bytes]:
 result={}
 for line in data.splitlines():
  match=re.match(rb"^([^#!\s][^\s:=]*)(?:\s+|\s*[:=]\s*)(.*)$",line)
  if match:result[match.group(1)]=match.group(2)
 return result
def localize_mask(template:bytes,translated:bytes)->tuple[bytes,list[str]]:
 translated_values=values(translated);output=[];missing=[]
 for line in template.splitlines(keepends=True):
  body=line.rstrip(b"\r\n");ending=line[len(body):]
  match=re.match(rb"^([^#!\s][^\s:=]*)(\s+|\s*[:=]\s*)(.*)$",body)
  if not match or not match.group(3).strip():output.append(line);continue
  value=translated_values.get(match.group(1))
  if value is None:
   missing.append(match.group(1).decode("ascii","replace"));output.append(line)
  else:output.append(match.group(1)+match.group(2)+value+ending)
 return b"".join(output),missing

def main()->int:
 root=Path(__file__).resolve().parents[3]
 stock=root/"_Game Switcher/HudLogStock/MODS/STD/i18n"
 immersion=root/"_Game Switcher/HudLogImmersion/MODS/STD/i18n"
 active=root/"Files/i18n"
 french=(stock/"hud_log_fr.properties").read_bytes()
 template=(immersion/"hud_log_us.properties").read_bytes()
 translations={"fr":french}
 for locale in LOCALES[1:]:translations[locale]=(active/f"hud_log_{locale}.properties").read_bytes()
 outputs=[];missing_by_locale={}
 for locale,data in translations.items():
  standard=stock/f"hud_log_{locale}.properties";standard.write_bytes(data)
  localized,missing=localize_mask(template,data)
  target=immersion/f"hud_log_{locale}.properties";target.write_bytes(localized)
  missing_by_locale[locale]=missing
 (immersion/"hud_log_us.properties").write_bytes(template)
 for path in sorted((*stock.glob("hud_log_*.properties"),*immersion.glob("hud_log_*.properties"))):
  outputs.append({"path":path.relative_to(root).as_posix(),"size":path.stat().st_size,"sha256":sha(path.read_bytes())})
 report={"schemaVersion":2,"generatedUtc":datetime.now(timezone.utc).isoformat(),"languages":["fr","us","ru","de","cs","hu","pl"],"immersionTemplate":"historical English immersion mask","missingTranslatedKeys":missing_by_locale,"outputs":outputs}
 target=root/"WIP/development/manifests/hud-language-variants-v1.15.json"
 target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
 print(f"PASS: seven HUD language variants built; report={target}")
 for item in outputs:print(item["sha256"],item["path"])
 return 0
if __name__=="__main__":raise SystemExit(main())
