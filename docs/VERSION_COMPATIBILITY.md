# Compatibilite jeu de la version 1.15

## Decision

Open Sturmovik 1.15 cible IL-2 Sturmovik 1946 **4.09m** pour son profil modifie. C'est la derniere base dont les executables, le wrapper, les classes libres, `air.ini` et les utilitaires historiques forment ici un ensemble coherent.

Le profil normal de l'add-on est un profil complet : les mods communautaires
retenus, les ameliorations de realisme et les textures haute definition doivent
y etre actifs ensemble. Les profils Original servent de references et de modes
de diagnostic. La compatibilite entre composants est une condition d'activation
par defaut, pas une hypothese.

Cette cible est maintenant gelee pour la stabilisation de la version 1.15. Les programmes communautaires incompatibles restent archives et desactives. Les etudes d'un portage 4.12.2m ou 4.15.1m ne doivent modifier ni les profils 4.09m ni leur chargeur.

La derniere version officielle disponible est 4.15.1m. Elle n'est pas adoptee comme base du mod 1.15 : le patch 4.15 demande explicitement une installation 4.14.1m officielle et non modifiee. Un portage demanderait de revalider les classes Java, les registres d'avions/cartes, le `files.SFS`, le wrapper et chaque utilitaire. Il devra etre developpe comme profil separe.

Les couples historiques « sans 6DOF » / « 6DOF » partagent le wrapper et le
`files.SFS` de leur version, mais utilisent maintenant deux executables
distincts. Le differentiel exact a ete retrouve dans la source locale AAA
Community Installer 1.1 puis reporte sur les EXE v1.15 de 348 160 octets sans
retirer leur drapeau Large Address Aware. Les cinq classes du module 6DOF sont
egalement presentes et identiques a cette source. Les empreintes et offsets
sont fixes dans `manifests/profiles-6dof-v1.15.json`.

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

- patch 4.08m : 107 fichiers deja identiques, `files.SFS` gere par le selecteur et une texture volontairement remplacee par le mod ; les trois notices sont conservees sous `_Documentations\Game and Patches\4.08m` ;
- patch 4.09m : 99 fichiers deja identiques ; les trois notices sont conservees sous `_Documentations\Game and Patches\4.09m` ;
- les SFS et DLL de coeur 4.08/4.09 correspondent octet par octet aux patchs locaux ;
- `fb_3do.SFS`, requis depuis la base DVD, est restaure avec les deux autres SFS du commit orphelin.

La reconstruction locale du test a egalement montre qu'une installation
4.14.1m ne constitue pas une base 4.07m equivalente : huit anciennes archives
SFS y manquaient, deux avaient ete consolidees ou remplacees, et 28 SFS
posterieurs restaient presents. La liste, les tailles et les empreintes sont
consignees dans [la matrice SFS](MATRICE_VERSIONS_SFS.md).

L'add-on peut donc etre pose sur une installation 4.07m propre et selectionner le profil 4.09m sans modifier les archives de patch sources.

## Memoire et processeurs

Les six executables **modifies** ont le drapeau PE `Large Address Aware`. Sous Windows 64 bits, un processus 32 bits ainsi marque peut disposer d'un espace d'adressage virtuel allant jusqu'a 4 Go ; sous Windows 32 bits avec 4GT, la limite peut atteindre 3 Go. Cela n'oblige pas le jeu a consommer cette memoire et ne transforme pas le moteur en application 64 bits.

Le tas Java historique reste fixe a `-Xmx1G`. Le pousser directement a 2 ou 3 Go empecherait vraisemblablement le moteur ancien de reserver l'espace natif necessaire. Le gain de la v1.15 est donc l'espace disponible pour l'ensemble du processus, sans rendre le tas Java instable.

Le fichier modele contient `ProcessAffinityMask=15`, mais le selecteur 1.15 remplace cette valeur d'apres la topologie declaree par Windows : jusqu'a quatre coeurs physiques, avec un seul processeur logique appartenant a chacun. Il interroge les masques de coeur du systeme au lieu de supposer que les fils Hyper-Threading sont numerotes dans un ordre particulier. La valeur 15 reste le repli si Windows ne fournit pas une topologie exploitable. Cette affinite ne promet pas que le moteur ancien parallellisera toute sa charge.

Documentation Microsoft : [limites memoire des processus 32 bits](https://learn.microsoft.com/en-us/Windows/win32/memory/memory-limits-for-Windows-releases) et [masque d'affinite](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setprocessaffinitymask).

## Sources de version

- [Annonce communautaire du patch 4.15m et exigence d'une base 4.14.1m stock](https://forum.il2sturmovik.com/topic/79551-the-415m-patch-for-il-2-1946-has-been-released/)
- [Patch 4.15.1m](https://www.mission4today.com/index.php?file=details&id=5685&name=Downloads)
- [Ordre des patchs IL-2 1946](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1)
