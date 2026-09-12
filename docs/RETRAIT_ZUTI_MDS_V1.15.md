# Retrait de Zuti MDS 1.13 — v1.15, 12 septembre 2026

## Etat et perimetre

Le composant **Zuti Moving Dogfight Server 1.13** a ete retire du contenu
local de la branche v1.15, sur demande explicite d'Alexis. Le retrait moteur
a ete demande apres presentation des dependances partagees. Les fonctions
MDS incorporees, ses outils, ses exemples et ses reglages de mission sont
retires ; les fonctions independantes identifiees restent preservees.

Le controle du contenu actif constate **648 fichiers retires et 51 fichiers
nettoyes**. Le manifeste exact est
[`retired-zuti-mds-v1.15.json`](../manifests/mods/retired-zuti-mds-v1.15.json).

| Traitement | Resultat verifie |
| --- | --- |
| Familles moteur MDS | 544 fichiers retires, correspondant a 543 noms de classes ; les classes standard sont chargees depuis le SFS du profil choisi lorsqu'elles existent |
| Classes mixtes conservees | Config, Controls, Motor et Explosions nettoyees ; AOC, titre Open Sturmovik, portes et effets Silverplate preserves |
| Missions dediees | 43 missions MDS et leurs descriptions associees retirees, dont les exemples de capture/radar et leurs copies |
| Missions ordinaires | 43 missions conservees ; seules les sections et cles MDS sont retirees |
| Traductions | Quatre fichiers i18n nettoyes des entrees MDS ; autres libelles preserves |
| Outils et notices | Deux outils Java, leurs lanceurs, les notices MDS et les anciens outils/tests specifiques retires du pack |
| Credits | Ligne MDS et mentions des deux mods incorpores a MDS retirees ; 40 contributions dans la page generee |

Les mentions historiques restent dans les rapports et outils de reconstruction.
La carte `Zuti_Slovenia` est une ressource distincte de MDS. L'attribution
BombBayDoors Plus aux auteurs Zuti et Fireball reste documentee pour le code
independant conserve ; sa version exacte reste a preciser. Le retrait de MDS
ne constitue donc pas une suppression de toutes les autres creations de
l'auteur, ni une validation de leurs conditions de redistribution.

## Sauvegarde

Avant modification, **699 fichiers** ont ete copies et controles par SHA-256
dans :

`D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence\Zuti MDS 1.13\retrait_complet_pack_20260912`.

`INVENTAIRE_SHA256.json` et `PERIMETRE_SAUVEGARDE.txt` accompagnent cette copie.
La sauvegarde partielle precedente de 689 fichiers et les preuves AOC sont
egalement conservees. Ces corpus reproduisent les fichiers du pack avant
nettoyage, avec des classes mixtes ; ils ne constituent pas une archive
originale complete du mod. Les configurations et profils utilisateur restent
conserves. Aucun compte de forum n'a ete cree et aucun email n'a ete envoye.

## Methode et preuves

Une suppression des seuls fichiers portant un nom Zuti aurait laisse des
appels vers des classes absentes. Les familles de classes internes sont donc
retirees ensemble, apres comparaison avec les archives des profils 4.08m,
4.09b et 4.09m. Les SFS de chacun des neuf profils restent inchanges.

- [Comparaison et reconstruction des familles](RECONSTRUCTION_MOTEUR_SANS_MDS_V1.15_20260912.md) : audit dans les deux sens des appels entre classes conservees et classes SFS exposees, y compris les acces internes et le caractere statique des membres.
- [AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md) : quatre methodes MDS retirees de Motor ; les 142 autres methodes et 237 champs sont preserves. FlightModelMain et RealFlightModel sont inchanges.
- [Commandes et explosions](RECONSTRUCTION_CONTROLS_EXPLOSIONS_SANS_MDS.md) : retrait des fonctions cargo MDS et des multiplicateurs de duree des crateres ; commandes des portes et effets independants conserves.
- [Configuration sans MDS](RECONSTRUCTION_CONFIG_SANS_MDS.md) : retrait de l'historique des serveurs MDS ; titre Open Sturmovik et comportement reseau standard conserves.

Le lecteur stock de missions lit les cinq premieres valeurs de `[BornPlace]`
et ignore les valeurs supplementaires. Les sections `[BornPlace0]`, etc.
sont standard et leurs noms d'avions restent utilises : elles sont conservees
avec leur contenu. Cette lecture est identique dans les trois versions.

Les anciens constructeurs AOC, branding et nucleaire ne peuvent plus produire
les sorties MDS historiques comme contenu actif valide. Leurs empreintes
intermediaires restent documentees pour reproduire et verifier le nettoyage.

## Verifications et limites

- Trois versions : aucune nouvelle reference introuvable, aucune classe retiree encore appelee, aucun nouveau defaut d'acces ou de membre statique/instance dans la simulation qualifiee.
- Contenu reel : 1 929 classes libres examinees sans constante Zuti, 648 chemins retires absents, 51 fichiers nettoyes controles et neuf SFS conformes.
- Tests JVM cibles : comportement des portes, configuration reseau dans quatre scenarios, armements CW-21 et reconstruction des fichiers verifies ; les doubles de test ne remplacent pas un essai dans le jeu.
- AOC : trois classes et 266 profils conformes ; douze classes nucleaires independantes inchanges.
- Switcher : neuf profils et 18 combinaisons profil/HUD verifies pour la logique de l'interface ; credits synchronises avec leur source Markdown.
- Validation du switcher reel en mode verification : neuf profils et deux variantes HUD PASS ; preparation hors jeu : sept controles PASS.
- Controle de contenu complet : **26 PASS, 1 WARN, 0 FAIL**. L'avertissement concerne l'absence de nouveau dump d'execution du jeu.

La comparaison constate aussi des anomalies anterieures au retrait : vingt
classes hors du perimetre ont des attributs terminaux malformes, et certains
noms de classes ne sont pas resolus par le seul couple `Files`/`files.SFS`.
Le rapport de familles les distingue des regressions : elles ne sont pas
introduites par ce retrait et ne sont pas corrigees ici.

**La validation en jeu et celle de l'installateur restent a faire.** Ces
controles ne permettent pas de declarer toute la version finale fonctionnelle,
ni de certifier les droits de redistribution de tous les autres composants.
Le jeu n'a pas ete lance pour cette operation.

Reproduction du controle de retrait :

```powershell
python -B tools/Test-NoMds.py
./tools/Test-OpenSturmovikAoc.ps1
./tools/Test-OpenSturmovikContent.ps1
python -B tools/Build-SwitcherCredits.py --check
```

Les outils detailles dans les quatre rapports permettent de reconstruire
les classes a partir des copies archivees, avec verification des empreintes.
