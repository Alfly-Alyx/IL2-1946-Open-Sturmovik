# Compatibilite jeu de la version 1.15

## Decision

Open Sturmovik 1.15 cible IL-2 Sturmovik 1946 **4.09m** pour son profil modifie. C'est la derniere base dont les executables, le wrapper, les classes libres, `air.ini` et les utilitaires historiques forment ici un ensemble coherent.

La derniere version officielle disponible est 4.15.1m. Elle n'est pas adoptee comme base du mod 1.15 : le patch 4.15 demande explicitement une installation 4.14.1m officielle et non modifiee. Un portage demanderait de revalider les classes Java, les registres d'avions/cartes, le `files.SFS`, le wrapper et chaque utilitaire. Il devra etre developpe comme profil separe.

Les couples historiques « sans 6DOF » / « 6DOF » ont actuellement des executables, wrappers et `files.SFS` strictement identiques pour chaque version. Le menu conserve leur numerotation, mais avertit qu'il ne peut pas produire deux comportements differents tant que les vrais fichiers 6DOF n'ont pas ete retrouves.

| Version du jeu | Donnees locales | Profil Open Sturmovik 1.15 |
| --- | --- | --- |
| 4.07m (DVD original) | Base attendue pour l'installation | Supportee comme point de depart |
| 4.08m | Donnees officielles presentes et profil Original/modifie disponible | Support historique |
| 4.09b | Profils historiques presents | Support historique, non recommande |
| 4.09m | Donnees officielles et profil modifie complets | **Cible recommandee** |
| 4.10m a 4.12.2m | Installateurs disponibles dans les archives externes | Non supporte par le wrapper 1.15 |
| 4.13m a 4.14.1m | Installateurs disponibles dans les archives externes | Non supporte par le wrapper 1.15 |
| 4.15m / 4.15.1m | Installateurs disponibles dans les archives externes | Stock separe seulement ; portage futur |

## Installation depuis 4.07m

La comparaison avec les installateurs officiels locaux donne :

- patch 4.08m : 107 fichiers deja identiques, `files.SFS` gere par le selecteur et une texture volontairement remplacee par le mod ; les trois notices sont conservees sous `_Guides_&_Manuals\Official Patches` ;
- patch 4.09m : 99 fichiers deja identiques ; les trois notices sont egalement conservees sous `_Guides_&_Manuals\Official Patches` ;
- les SFS et DLL de coeur 4.08/4.09 correspondent octet par octet aux patchs locaux ;
- `fb_3do.SFS`, requis depuis la base DVD, est restaure avec les deux autres SFS du commit orphelin.

L'add-on peut donc etre pose sur une installation 4.07m propre et selectionner le profil 4.09m sans modifier les archives de patch sources.

## Memoire et processeurs

Les six executables **modifies** ont le drapeau PE `Large Address Aware`. Sous Windows 64 bits, un processus 32 bits ainsi marque peut disposer d'un espace d'adressage virtuel allant jusqu'a 4 Go ; sous Windows 32 bits avec 4GT, la limite peut atteindre 3 Go. Cela n'oblige pas le jeu a consommer cette memoire et ne transforme pas le moteur en application 64 bits.

Le tas Java historique reste fixe a `-Xmx1G`. Le pousser directement a 2 ou 3 Go empecherait vraisemblablement le moteur ancien de reserver l'espace natif necessaire. Le gain de la v1.15 est donc l'espace disponible pour l'ensemble du processus, sans rendre le tas Java instable.

Le profil `conf.max.ini` applique `ProcessAffinityMask=15`, soit les quatre premiers processeurs logiques. C'est une limite d'affinite, pas une promesse que le moteur ancien parallellisera toute sa charge sur quatre coeurs.

Documentation Microsoft : [limites memoire des processus 32 bits](https://learn.microsoft.com/en-us/Windows/win32/memory/memory-limits-for-Windows-releases) et [masque d'affinite](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setprocessaffinitymask).

## Sources de version

- [Annonce communautaire du patch 4.15m et exigence d'une base 4.14.1m stock](https://forum.il2sturmovik.com/topic/79551-the-415m-patch-for-il-2-1946-has-been-released/)
- [Patch 4.15.1m](https://www.mission4today.com/index.php?file=details&id=5685&name=Downloads)
- [Ordre des patchs IL-2 1946](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1)
