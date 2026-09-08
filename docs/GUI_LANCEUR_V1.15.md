# GUI du lanceur v1.15 — 8 septembre 2026

Le lanceur conserve le format BAT unique. La refonte remplace son CSS et
réorganise les blocs HTML existants : panneau translucide riveté, barre haute
étroite, séparations fines, police Arial de poids normal, boutons ronds à
cerclage métallique avec lentilles ambrées/vertes, bouton Quitter rouge.
Les cinq SVG décoratifs sont incorporés au CSS, sans dépendance distribuée.
Le fond et les icônes existants sont conservés. Les SVG sont redessinés à partir
du menu de référence, sans prétendre être des sprites extraits du jeu.

La comparaison à la version locale reçue avant refonte confirme que le préfixe
de commandes BAT et tout le JavaScript sont identiques octet pour octet.
Les contrôles gardent leurs noms, valeurs, états initiaux et gestionnaires.
Les corrections antérieures du lanceur sont décrites dans
[CORRECTION_SWITCHER_V1.15.md](CORRECTION_SWITCHER_V1.15.md) ; elles préexistaient
à cette refonte et sont incluses dans le commit à la demande d'Alexis.

## Vérifications

- node tools/Test-SwitcherGui.cjs : neuf correspondances de profils,
  dix-huit appels profil/HUD, dix-huit restaurations d'état, garde HUD stock,
  cohérence du raccourci et de l'installateur. Seules trois attentes de dimensions
  de ce test ont changé pour la refonte.
- Aperçu inerte Edge/Chromium : aucun chevauchement, aucune erreur JavaScript,
  écran d'erreur et retour vérifiés. Aucun accès au jeu dans cet aperçu.
- Test HTA indépendant : mode IE9, cinq SVG chargés sans erreur, résumé et
  configuration active sans débordement, action visible dans la fenêtre.
- Rapport : [switcher-gui-style-v1.15.json](../manifests/test/switcher-gui-style-v1.15.json).

Les captures de vérification sont issues de l'aperçu Chromium. La capture native
Windows a échoué ; le rapport HTA vérifie les chargements et dimensions mais
n'est pas une capture. Aucun jeu ni transaction de profil n'a été lancé pour
cette refonte. Les anciens rapports de transactions gardent leur date et portée.

## Sources

Priorité aux ressources locales sous D:\Projets\GITHUB\#res\IL2 1946 et
au fond déjà livré sous _Game Switcher/Resources.

- [Menu IL-2 1946 de référence](https://aiss.stars.ne.jp/il2-1946/index.html)
  et [capture inspectée](https://aiss.stars.ne.jp/pf/main.jpg).
- [Mission4Today : fonds IL-2 1946](https://www.mission4today.com/index.php?c=65&name=Downloads).
- [SAS : IMF Converter](https://www.sas1946.com/main/index.php?topic=71961.36).
- [AAA via Wayback](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/) :
  inaccessible, aucun contenu supposé.
