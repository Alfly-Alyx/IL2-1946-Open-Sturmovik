# Open Sturmovik 1.15

Open Sturmovik est une extension non officielle pour IL-2 Sturmovik 1946,
composee de creations de la communaute et reunie par Alfly. Son objectif est de
faire fonctionner ensemble les meilleurs mods de realisme, de fidelite
historique et d'amelioration visuelle, notamment les textures 2K et 4K, dans un
profil complet active par defaut.

Un composant n'entre dans ce profil par defaut qu'apres validation de sa
compatibilite avec l'ensemble. Les utilitaires historiques incompatibles restent
disponibles dans les archives du projet mais ne sont pas actives silencieusement.

## Version du jeu

La version 1.15 stabilise le profil modifie **4.09m**. Elle est concue pour etre copiee sur une installation propre du DVD IL-2 1946 4.07m : les donnees fonctionnelles des patchs 4.08m et 4.09m necessaires au jeu sont incluses.

La version officielle 4.15.1m ne doit pas etre installee par-dessus ce profil modifie. Elle exige une base officielle 4.14.1m non modifiee et fera l'objet d'un profil separe si le chargeur de mods peut etre porte sans regression. Voir [la matrice de compatibilite](docs/VERSION_COMPATIBILITY.md).

Les anciens choix 4.08m et 4.09b restent archives pour l'etude de la compatibilite serveur, mais sont temporairement verrouilles dans le selecteur. Ils ne seront reactives qu'avec un manifeste transactionnel couvrant aussi leurs SFS et DLL ; la cible de test et de distribution est la 4.09m.

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
- Pendant la stabilisation, le profil OpenGL utilise la haute qualite securisee x86 : textures S3TC, effets moderes et eau 2 generique, tout en conservant les ombres/lumieres, la geometrie, la foret et la distance de visibilite elevees.
- Les extensions NVIDIA sont activees seulement lorsqu'un GPU NVIDIA actif est detecte ; Intel, AMD et les cartes inconnues utilisent le profil ARB generique.

## Audits 1.15

- [Dossier technique vivant : fonctionnement, attentes et regles de l'add-on](docs/DOSSIER_TECHNIQUE_IL2_1946.md)
- [Redondance entre SFS et fichiers libres](docs/AUDIT_SFS.md)
- [Etat des quatorze groupes d'utilitaires de `_OS_Programs`](docs/AUDIT_OS_PROGRAMS.md)
- [Compatibilite des versions 4.07m a 4.15.1m](docs/VERSION_COMPATIBILITY.md)
- [Preparation du prochain test v1.15](docs/PREPARATION_PROCHAIN_TEST_V1.15.md)
- [Comparaison des neuf profils 4.08/4.09](docs/AUDIT_PROFILES.md)
- [Matrice des versions, SFS et reconstruction des bases](docs/MATRICE_VERSIONS_SFS.md)
- [Cahier des charges du futur lanceur et de ses raccourcis](docs/CAHIER_DES_CHARGES_LANCEUR.md)
- [Architecture statique du jeu et du mod](docs/ARCHITECTURE_MOTEUR.md)
- [Analyse approfondie du chargeur `wrapper.dll`](docs/ANALYSE_WRAPPER_DLL.md)
- [Audit des executables, DLL, limites memoire x86 et affinite CPU](docs/AUDIT_BINAIRES_X86.md)
- [Audit et traitement des classes Java libres](docs/AUDIT_CLASSES_JAVA.md)
- [Audit des effets et limites du moteur 4.09m](docs/AUDIT_EFFETS_409M.md)
- [Chargements, execution et wrappers graphiques](docs/PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md)
- [Audit du `conf.ini` historique de la version 1.2](docs/AUDIT_CONF_INI_HISTORIQUE.md)
- [Audit des musiques nationales et des fonds d'ecran](docs/AUDIT_MUSIQUES_ET_FONDS.md)
- [Resultats compares des premiers demarrages 4.09m stock et modifies](docs/RESULTATS_TESTS_DEMARRAGE_2026-08-30.md)
- [Resultat du demarrage profile 9 et correctifs du 31 aout 2026](docs/RESULTATS_TESTS_DEMARRAGE_2026-08-31.md)
- [Outils de modding, SFS, Buttons et diagnostic du chargement](docs/OUTILS_MODDING_IL2_1946.md)
- [Feuille de route de stabilisation et criteres de sortie 1.15](docs/FEUILLE_DE_ROUTE_V1.15.md)
- [Catalogue des mods historiques et sources All Aircraft Arcade](docs/CATALOGUE_MODS_HISTORIQUES.md)
- [Etat de reprise technique de la v1.15 pour continuer dans une nouvelle session](docs/ETAT_REPRISE_V1.15.md)

Les utilitaires de `_OS_Programs` n'ont pas ete modifies ni lances pendant l'audit. Aucun n'est active automatiquement dans la version 1.15.

## Developpement ulterieur

- Tester le profil 4.09m dans une copie complete du jeu.
- Evaluer un portage separe vers 4.12.2m ou 4.15.1m sans ecraser la version stable.
- Revalider ou mettre a jour JoyControl, Mission Mate et Lowengrin DCG avant toute integration.
- Consolider les fichiers libres en SFS seulement apres une comparaison fonctionnelle ; l'audit montre que la grande majorite des chemins communs sont des remplacements volontaires, pas des doublons.
- Mesurer dans le jeu le wrapper de cache 4.09m deja valide sur banc isole, puis le promouvoir seulement en l'absence de regression.
- Creer des profils graphiques x86 transactionnels ; OpenGL natif restera le repli garanti et le chargeur de mods `wrapper.dll` ne sera jamais remplace par un backend graphique.
- Creer deux raccourcis distincts : lancement direct d'Open Sturmovik sans
  interface, et ouverture a la demande du lanceur de configuration.
- Exploiter le clone Selector/Dump 4.09m sans 6DOF pour associer les ressources
  SFS aux paliers visibles du chargement, sans remplacer le wrapper stable.

---

Open Sturmovik is an unofficial community add-on compiled by Alfly. Version 1.15 keeps the modded runtime on IL-2 1946 4.09m, adds a transactional switcher, safe Original profiles, corrected `air.ini` and HUD paths, maximum visual settings, affinity for up to four physical cores, and Large Address Aware modded executables. See the linked audit documents for the compatibility boundaries.
