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
- Le registre `stationary.ini` est maintenant bascule avec le profil : 4.08/4.09b ou 4.09m.
- Les HUD sont installes dans `Files\i18n`, le dossier reel charge par cet add-on.
- Les choix 11 et 12 activent le nouveau wrapper de cache 4.09m experimental ; les choix 8 et 9 conservent le wrapper historique stable.

Le selecteur fusionne ensuite `_Game Switchers\conf.max.ini` dans le `conf.ini` existant. La resolution, le son, le reseau et les commandes du joueur sont conserves. Une sauvegarde `conf.ini.open-sturmovik.bak` est creee.

## Memoire, processeurs et qualite

- Les executables modifies sont `Large Address Aware` : jusqu'a 4 Go d'espace d'adressage sous Windows 64 bits, ou jusqu'a 3 Go sous un Windows 32 bits configure avec 4GT.
- Le tas Java reste volontairement a 1 Go pour laisser de la place aux bibliotheques et donnees natives de cet ancien moteur.
- Le selecteur calcule `ProcessAffinityMask` pour autoriser au maximum quatre coeurs physiques ; `15` reste le repli si la topologie ne peut pas etre lue.
- Le profil OpenGL active les shaders materiels, l'eau 4, les ombres/lumieres, la geometrie, la foret et la distance de visibilite maximales connues.
- Les extensions NVIDIA sont activees seulement lorsqu'un GPU NVIDIA actif est detecte ; Intel, AMD et les cartes inconnues utilisent le profil ARB generique.

## Audits 1.15

- [Dossier technique vivant : fonctionnement, attentes et regles de l'add-on](docs/DOSSIER_TECHNIQUE_IL2_1946.md)
- [Redondance entre SFS et fichiers libres](docs/AUDIT_SFS.md)
- [Etat des quatorze groupes d'utilitaires de `_OS_Programs`](docs/AUDIT_OS_PROGRAMS.md)
- [Compatibilite des versions 4.07m a 4.15.1m](docs/VERSION_COMPATIBILITY.md)
- [Comparaison des neuf profils 4.08/4.09](docs/AUDIT_PROFILES.md)
- [Architecture statique du jeu et du mod](docs/ARCHITECTURE_MOTEUR.md)
- [Analyse approfondie du chargeur `wrapper.dll`](docs/ANALYSE_WRAPPER_DLL.md)
- [Audit et traitement des classes Java libres](docs/AUDIT_CLASSES_JAVA.md)
- [Chargements, execution et wrappers graphiques](docs/PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md)

Les utilitaires de `_OS_Programs` n'ont pas ete modifies ni lances pendant l'audit. Aucun n'est active automatiquement dans la version 1.15.

## Developpement ulterieur

- Tester le profil 4.09m dans une copie complete du jeu.
- Evaluer un portage separe vers 4.12.2m ou 4.15.1m sans ecraser la version stable.
- Revalider ou mettre a jour JoyControl, Mission Mate et Lowengrin DCG avant toute integration.
- Consolider les fichiers libres en SFS seulement apres une comparaison fonctionnelle ; l'audit montre que la grande majorite des chemins communs sont des remplacements volontaires, pas des doublons.
- Mesurer dans le jeu le wrapper de cache 4.09m deja valide sur banc isole, puis le promouvoir seulement en l'absence de regression.
- Creer des profils graphiques x86 transactionnels ; OpenGL natif restera le repli garanti et le chargeur de mods `wrapper.dll` ne sera jamais remplace par un backend graphique.

---

Open Sturmovik is an unofficial community add-on compiled by Alfly. Version 1.15 keeps the modded runtime on IL-2 1946 4.09m, adds a transactional switcher, safe Original profiles, corrected `air.ini` and HUD paths, maximum visual settings, four-logical-processor affinity, and Large Address Aware modded executables. See the linked audit documents for the compatibility boundaries.
