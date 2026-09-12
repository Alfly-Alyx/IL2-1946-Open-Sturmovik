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

Les choix 4.08m, 4.09b et 4.09m sont maintenant presentes par le switcher sous
forme de neuf profils : Original, Open Sturmovik sans 6DOF et Open Sturmovik
avec 6DOF pour chaque version. La cible stable et le profil recommande restent
Open Sturmovik 4.09m sans 6DOF. Les profils modifies annonces 4.08m reproduisent
l'architecture hybride historique AAA et doivent etre testes seulement avec
des cartes et contenus compatibles avec cette configuration.

## Selecteur securise

Lancer `Open_Sturmovik_Switcher.bat` depuis la racine du jeu. Il ouvre une
interface graphique et confie les remplacements au moteur batch natif.

- Les sources de chaque profil sont verifiees par SHA-256 avant le premier
  remplacement.
- L'EXE, `files.SFS`, le wrapper, les SFS de version, les DLL, `air.ini` et
  `stationary.ini` sont traites dans une seule transaction avec sauvegarde et
  retour arriere.
- Les profils Original retirent `wrapper.dll`; le profil Original 4.08m retire
  aussi les trois archives propres a la 4.09.
- Les profils modifies restaurent le wrapper et l'EXE avec ou sans 6DOF choisi.
- Le HUD peut etre conserve, remis en version standard ou passe en mode
  immersion.
- Le jeu doit etre ferme pendant le changement de profil.

Les six EXE modifies portent des metadonnees Windows `Open Sturmovik`, sans
modifier leur code 6DOF. En mode fenetre, une surcharge moteur fixe aussi le
titre a `Open Sturmovik`. Les trois EXE Original restent identiques au fichier
stock et le wrapper qui chargerait cette surcharge est retire.

## Fonds de chargement variables (option validee)

La rotation facultative propose les quatre fonds choisis par Alexis, avec trois
passages par cycle pour le fond officiel de 2001. Les images sont installees
sous `Files/gui/backgrounds`. Le choix du fond intervient au demarrage
modde, y compris lors d'un lancement direct de `il2fb.exe`.

Ouvrir `Open_Sturmovik_Fonds.vbs` pour installer, activer, desactiver ou retirer
la modification. L'installation seule reste desactivee ; la selection se
regle dans cette fenetre. Les fichiers d'origine sont preserves. La logique et
le retour arriere sont testes ; un lancement direct avec le fond officiel triple
a ete valide en 4.09m avec 6DOF.
Voir [le fonctionnement et la procedure de retour arriere](docs/ROTATION_FONDS_CHARGEMENT.md).

## Diagnostic automatique

La mise a jour installe un moniteur discret qui observe chaque execution de
`il2fb.exe`, meme lorsque le jeu est lance directement. Il conserve les nouveaux
messages de `log.lst`, `eventlog.lst`, `sound.log` et des autres journaux racine,
detecte les erreurs de fichiers, textures, materiaux, sons, classes, exceptions,
sorties anormales et gels prolonges, puis cree ou complete un ticket dans le
depot GitHub Open Sturmovik. Le profil actif, les empreintes des composants, la
configuration graphique utile, le materiel et les evenements Windows associes
sont joints au diagnostic.

Aucun compte GitHub ni jeton n'est requis sur le PC utilisateur. Les rapports sont expurges avant envoi et restent en file locale lorsque le
reseau ou le service de rapports est indisponible. Windows Error Reporting
conserve jusqu'a cinq dumps complets localement ; seuls leur nom, leur taille et
leur SHA-256 sont publies, car un dump memoire brut peut contenir des donnees
privees. Voir [le fonctionnement et les limites du collecteur](docs/DIAGNOSTIC_AUTOMATIQUE_GITHUB.md).

## Memoire, processeurs et qualite

- Les executables modifies sont `Large Address Aware` : jusqu'a 4 Go d'espace d'adressage sous Windows 64 bits, ou jusqu'a 3 Go sous un Windows 32 bits configure avec 4GT.
- Le tas Java reste volontairement a 1 Go pour laisser de la place aux bibliotheques et donnees natives de cet ancien moteur.
- Le selecteur calcule `ProcessAffinityMask` pour autoriser au maximum quatre coeurs physiques ; `15` reste le repli si la topologie ne peut pas etre lue.
- Pendant la stabilisation, le profil OpenGL utilise la haute qualite securisee x86 : textures S3TC, effets moderes et eau 2 generique, tout en conservant les ombres/lumieres, la geometrie, la foret et la distance de visibilite elevees.
- Les extensions NVIDIA sont activees seulement lorsqu'un GPU NVIDIA actif est detecte ; Intel, AMD et les cartes inconnues utilisent le profil ARB generique.

## Audits 1.15

- [Retrait des composants soumis a permission et etat restant de Zuti](docs/RETRAIT_COMPOSANTS_V1.15.md)
- [Etat courant faisant autorite pour reprendre le travail](docs/ETAT_COURANT_V1.15.md)
- [Journal central des essais, erreurs de protocole et enseignements a ne pas repeter](docs/JOURNAL_DIAGNOSTIC_V1.15.md)
- [Collecte automatique des anomalies et envoi vers GitHub](docs/DIAGNOSTIC_AUTOMATIQUE_GITHUB.md)
- [Reference de retro-ingenierie du moteur et etude exploratoire x64](docs/REFERENCE_RETROINGENIERIE_MOTEUR.md)
- [Regles de stockage des captures et sauvegardes locales](docs/STOCKAGE_ARTIFACTS_LOCAUX.md)
- [Dossier technique vivant : fonctionnement, attentes et regles de l'add-on](docs/DOSSIER_TECHNIQUE_IL2_1946.md)
- [Redondance entre SFS et fichiers libres](docs/AUDIT_SFS.md)
- [Audit, tri et classement des outils externes](docs/AUDIT_OS_PROGRAMS.md)
- [Compatibilite des versions 4.07m a 4.15.1m](docs/VERSION_COMPATIBILITY.md)
- [Preparation du prochain test v1.15](docs/PREPARATION_PROCHAIN_TEST_V1.15.md)
- [Comparaison des neuf profils 4.08/4.09](docs/AUDIT_PROFILES.md)
- [Matrice des versions, SFS et reconstruction des bases](docs/MATRICE_VERSIONS_SFS.md)
- [Cahier des charges du futur lanceur et de ses raccourcis](docs/CAHIER_DES_CHARGES_LANCEUR.md)
- [Architecture statique du jeu et du mod](docs/ARCHITECTURE_MOTEUR.md)
- [Lisibilite, modifiabilite et pistes de performance du moteur](docs/AUDIT_MODIFIABILITE_MOTEUR.md)
- [Analyse approfondie du chargeur `wrapper.dll`](docs/ANALYSE_WRAPPER_DLL.md)
- [Audit des executables, DLL, limites memoire x86 et affinite CPU](docs/AUDIT_BINAIRES_X86.md)
- [Marquage des executables et origine du titre de fenetre](docs/BRANDING_EXECUTABLES_V1.15.md)
- [Audit et traitement des classes Java libres](docs/AUDIT_CLASSES_JAVA.md)
- [Audit des effets et limites du moteur 4.09m](docs/AUDIT_EFFETS_409M.md)
- [Chargements, execution et wrappers graphiques](docs/PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md)
- [Audit du `conf.ini` historique de la version 1.2](docs/AUDIT_CONF_INI_HISTORIQUE.md)
- [Audit des musiques nationales et des fonds d'ecran](docs/AUDIT_MUSIQUES_ET_FONDS.md)
- [Resultats compares des premiers demarrages 4.09m stock et modifies](docs/RESULTATS_TESTS_DEMARRAGE_2026-08-30.md)
- [Resultat du demarrage profile 9 et correctifs du 31 aout 2026](docs/RESULTATS_TESTS_DEMARRAGE_2026-08-31.md)
- [Outils de modding, SFS, Buttons et diagnostic du chargement](docs/OUTILS_MODDING_IL2_1946.md)
- [Audit statique exhaustif des 536 appareils de air.ini](docs/AUDIT_APPAREILS_AIR_INI.md)
- [Lecture sure de l'index Buttons et audit des references de modeles de vol](docs/AUDIT_BUTTONS_MODELES_DE_VOL.md)
- [Feuille de route de stabilisation et criteres de sortie 1.15](docs/FEUILLE_DE_ROUTE_V1.15.md)
- [Configurations materielles candidates et protocole 1080p60](docs/CONFIGURATIONS_MATERIELLES_V1.15.md)
- [Protocole de l'essai multicartes du 1er septembre 2026](docs/PROTOCOLE_ESSAI_MULTICARTES_2026-09-01.md)
- [Resultats de la campagne multicartes et du stress 32 appareils du 1er septembre 2026](docs/RESULTATS_CAMPAGNE_MULTICARTES_2026-09-01.md)
- [Catalogue des mods historiques et sources All Aircraft Arcade](docs/CATALOGUE_MODS_HISTORIQUES.md)
- [Etat de reprise technique de la v1.15 pour continuer dans une nouvelle session](docs/ETAT_REPRISE_V1.15.md)

Des lancements controles ont ete effectues uniquement dans une copie de travail. IL2 Connect et VoiceOverlay ont ensuite ete retires faute d'usage recent identifiable. Les programmes conserves sont repartis entre `_Utilities` et le dossier commun `_Game_Enhancements` ; les programmes externes de ce dernier ne sont pas actives automatiquement dans la version 1.15.

## Developpement ulterieur

- Tester le profil 4.09m dans une copie complete du jeu.
- Evaluer un portage separe vers 4.12.2m ou 4.15.1m sans ecraser la version stable.
- Revalider JoyControl et Mission Mate avant la sortie finale. Lowengrin DCG est retire du pack.
- Consolider les fichiers libres en SFS seulement apres une comparaison fonctionnelle ; l'audit montre que la grande majorite des chemins communs sont des remplacements volontaires, pas des doublons.
- Mesurer dans le jeu le wrapper de cache 4.09m deja valide sur banc isole, puis le promouvoir seulement en l'absence de regression.
- Creer des profils graphiques x86 transactionnels ; OpenGL natif restera le repli garanti et le chargeur de mods `wrapper.dll` ne sera jamais remplace par un backend graphique.
- Le futur lanceur complet pourra ajouter un raccourci de lancement direct ;
  la mise a jour v1.15 installe le raccourci du switcher et ceux des sept
  utilitaires retenus.
- Exploiter le clone Selector/Dump 4.09m sans 6DOF pour associer les ressources
  SFS aux paliers visibles du chargement, sans remplacer le wrapper stable.

---

Open Sturmovik is an unofficial community add-on compiled by Alfly. Version 1.15 keeps the stable modded runtime on IL-2 1946 4.09m, adds a graphical transactional switcher for 4.08m/4.09b/4.09m, safe Original profiles, corrected `air.ini` and HUD paths, maximum visual settings, affinity for up to four physical cores, branded windowed-mode titles, and Large Address Aware modded executables. See the linked audit documents for the compatibility boundaries.
