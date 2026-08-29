# Open Sturmovik 1.15

Open Sturmovik est une extension non officielle pour IL-2 Sturmovik 1946, composee de creations de la communaute et reunie par Alfly.

## Version du jeu

La version 1.15 stabilise le profil modifie **4.09m**. Elle est concue pour etre copiee sur une installation propre du DVD IL-2 1946 4.07m : les donnees fonctionnelles des patchs 4.08m et 4.09m necessaires au jeu sont incluses.

La version officielle 4.15.1m ne doit pas etre installee par-dessus ce profil modifie. Elle exige une base officielle 4.14.1m non modifiee et fera l'objet d'un profil separe si le chargeur de mods peut etre porte sans regression. Voir [la matrice de compatibilite](docs/VERSION_COMPATIBILITY.md).

## Selecteur securise

Lancer `Open_Sturmovik_Switcher.bat` depuis la racine du jeu.

- Le choix `10 - Quiet` quitte sans modifier le moindre fichier.
- Toutes les sources sont verifiees avant le premier remplacement.
- Chaque copie est controlee par taille et SHA-256.
- Une erreur provoque le retour a l'etat precedent et interdit le message de succes.
- Les profils Original n'utilisent pas `wrapper.dll` ; les profils modifies le restaurent.
- Les chemins 4.08m/4.09m de `air.ini` tiennent compte du sous-dossier `Air.ini`.
- Les HUD sont installes dans `Files\i18n`, le dossier reel charge par cet add-on.

Le selecteur fusionne ensuite `_Game Switchers\conf.max.ini` dans le `conf.ini` existant. La resolution, le son, le reseau et les commandes du joueur sont conserves. Une sauvegarde `conf.ini.open-sturmovik.bak` est creee.

## Memoire, processeurs et qualite

- Les executables modifies sont `Large Address Aware` : jusqu'a 4 Go d'espace d'adressage sous Windows 64 bits, ou jusqu'a 3 Go sous un Windows 32 bits configure avec 4GT.
- Le tas Java reste volontairement a 1 Go pour laisser de la place aux bibliotheques et donnees natives de cet ancien moteur.
- `ProcessAffinityMask=15` autorise au maximum les quatre premiers processeurs logiques.
- Le profil OpenGL active les shaders materiels, l'eau 4, les ombres/lumieres, la geometrie, la foret et la distance de visibilite maximales connues.

## Audits 1.15

- [Redondance entre SFS et fichiers libres](docs/AUDIT_SFS.md)
- [Etat des quatorze groupes d'utilitaires de `_OS_Programs`](docs/AUDIT_OS_PROGRAMS.md)
- [Compatibilite des versions 4.07m a 4.15.1m](docs/VERSION_COMPATIBILITY.md)

Les utilitaires de `_OS_Programs` n'ont pas ete modifies ni lances pendant l'audit. Aucun n'est active automatiquement dans la version 1.15.

## Developpement ulterieur

- Tester le profil 4.09m dans une copie complete du jeu.
- Evaluer un portage separe vers 4.12.2m ou 4.15.1m sans ecraser la version stable.
- Revalider ou mettre a jour JoyControl, Mission Mate et Lowengrin DCG avant toute integration.
- Consolider les fichiers libres en SFS seulement apres une comparaison fonctionnelle ; l'audit montre que la grande majorite des chemins communs sont des remplacements volontaires, pas des doublons.

---

Open Sturmovik is an unofficial community add-on compiled by Alfly. Version 1.15 keeps the modded runtime on IL-2 1946 4.09m, adds a transactional switcher, safe Original profiles, corrected `air.ini` and HUD paths, maximum visual settings, four-logical-processor affinity, and Large Address Aware modded executables. See the linked audit documents for the compatibility boundaries.
