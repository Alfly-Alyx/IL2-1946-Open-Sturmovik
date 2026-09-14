# Organisation des profils du switcher

État du 13 septembre 2026 — Open Sturmovik 1.15.

Le switcher conserve neuf choix : trois versions IL-2, chacune disponible en jeu original, Open Sturmovik sans 6DOF et Open Sturmovik avec 6DOF. Chaque choix possède désormais son propre dossier complet sous `_Game Switcher`. L'ancien dossier partagé `Version Payloads` a été supprimé.

| Choix | Dossier |
| ---: | --- |
| 1 | `4.08 Mods OFF (Original)` |
| 2 | `4.08 Mods ON (NO 6DOF)` |
| 3 | `4.08 Mods ON 6DOF` |
| 4 | `4.09b Mods OFF (Original)` |
| 5 | `4.09b Mods ON (NO 6DOF)` |
| 6 | `4.09b Mods ON 6DOF` |
| 7 | `4.09m Mods OFF (Original)` |
| 8 | `4.09m Mods ON (NO 6DOF)` |
| 9 | `4.09m Mods ON 6DOF` |

## Contenu d'un dossier

Chaque dossier contient directement :

- `il2fb.exe`, propre au mode original, moddé standard ou moddé 6DOF ;
- `files.SFS`, propre à la version et au mode original ou moddé ;
- `wrapper.dll` dans les profils Open Sturmovik ;
- `il2_core.dll`, `il2_corep4.dll`, `mg_snd.dll` et `mg_snd_sse.dll` pour la version choisie ;
- pour 4.09b et 4.09m, `fb_3do19.SFS`, `fb_3do20.SFS` et `fb_maps15.SFS`.
- sous Profiles, la classe Plane compatible, le fond Missions\Background.tga et le jeu exact de musiques samples\Music\Menu du profil.

Les profils 4.08m n'emploient pas les trois derniers SFS. Quand un profil 4.08m est activé, le switcher retire donc leurs éventuelles copies actives à la racine du jeu.

## Fonctionnement

Le double-clic sur `Open_Sturmovik_Switcher.bat` ouvre directement l'interface graphique. Le raccourci Bureau appelle `_Game Switcher\Open_Sturmovik_Switcher.vbs` : ce petit lanceur retrouve la racine du jeu depuis son propre dossier, masque la console puis exécute le même BAT. Le BAT force ensuite la fenêtre graphique en mode normal afin qu'elle reste visible. Aucun chemin absolu vers le jeu n'est enregistré dans ces scripts.

Le BAT associe chaque bouton à un seul dossier. Avant tout changement, il vérifie les empreintes SHA-256 de l'exécutable, de `files.SFS`, du wrapper éventuel et de tous les fichiers moteur présents dans ce dossier. Il prépare ensuite le changement dans un dossier de transaction, sauvegarde la configuration active, copie les fichiers et restaure l'état précédent si une opération échoue.

Cette organisation répète certains gros fichiers entre profils. Ce choix est volontaire : un dossier suffit pour comprendre, vérifier, déplacer ou reconstruire un profil complet. Les neuf profils et le même switcher sont reproduits à l'identique dans `installer/Payload`.

Le contrôle de référence est `tools/Test-OpenSturmovikSwitcher.ps1`. Il refuse le retour de `Version Payloads` ou du dossier `Profiles` abandonné, vérifie chaque composant et exécute la validation interne des neuf choix sans modifier le jeu.

## Noms et icone active

Les dossiers 4.09 utilisent le nom du moteur affiche par le selecteur : 4.09b pour la beta et 4.09m pour la version finale. Les anciens prefixes 4.09 et 4.09 final ne sont plus employes dans _Game Switcher.

Le raccourci Bureau du jeu garde pour cible _Game Switcher\Open_Sturmovik_Game.vbs, mais lit son icone dans il2fb.exe a la racine. Apres une bascule, Refresh-OpenSturmovikIconCache.ps1 met a jour ce raccourci et avertit Explorer que l'executable actif a change.
## Profil initial de l'installeur (13 septembre 2026)

`WIP/development/installer/Set-OpenSturmovikPayloadDefaultProfile.ps1` assemble
le profil 8 dans les emplacements actifs du Payload. La version livree demarre
donc en 4.09m Open Sturmovik sans 6DOF, avec le HUD standard et le francais.
Cette operation est executee a chaque reconstruction du Payload, ce qui rend le
resultat independant du profil actuellement actif dans le depot ou dans le jeu
de test.