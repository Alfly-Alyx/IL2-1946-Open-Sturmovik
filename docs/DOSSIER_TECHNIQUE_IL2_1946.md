# Dossier technique vivant — IL-2 1946 / Open Sturmovik 1.15

## Objet du document

Ce fichier est la reference centrale de ce qui est decouvert sur le jeu original, le moteur, le format de l'add-on et les conditions necessaires a son fonctionnement. Il doit etre mis a jour a chaque nouvelle analyse statique ou session de test.

Chaque information appartient a l'un de ces niveaux :

- **verifie statiquement** : prouve par les fichiers, les empreintes, le desassemblage ou le code source consulte ;
- **confirme en execution** : observe dans une copie de test avec une mesure reproductible ;
- **hypothese** : explication plausible qui exige encore un essai ;
- **regle 1.15** : decision de construction ou de securite du projet.

Au 29 aout 2026, l'analyse est essentiellement statique. Aucun executable IL-2 ou utilitaire de `_OS_Programs` n'a encore ete lance.

## Perimetre et sources protegees

- Add-on modifiable : depot Open Sturmovik.
- Jeu de reference, lecture seule : `C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946`.
- Archives de patch, lecture seule : `D:\Documents\##Documents\Informatique\Retro-gaming\Jeux Retro-gaming\Patchs\Patches IL2`.
- Cible gelee pour Open Sturmovik 1.15 : **IL-2 1946 4.09m**.
- La version originale et les archives de patch ne doivent jamais etre modifiees. Tout essai futur doit utiliser une copie distincte.

L'add-on n'est pas un jeu complet. Il attend qu'une installation IL-2 fournisse notamment le runtime Java, les bibliotheques natives, le moteur graphique, le moteur audio et les archives officielles. L'installateur final devra reconnaitre la version de depart, appliquer la chaine officielle requise jusqu'a 4.09m, puis poser les fichiers Open Sturmovik.

La documentation communautaire de reference indique que le DVD retail part de 4.07m, puis passe par 4.08m et 4.09m : [guide d'installation et de patch Mission4Today](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1). La fiche du [patch officiel 4.09m](https://www.mission4today.com/index.php?file=details&id=3764&name=Downloads) confirme qu'il exige une base 4.08m. Les archives locales restent la source des fichiers a integrer ; ces liens servent a verifier l'ordre et lire les instructions historiques.

## Ce que le jeu attend a la racine

| Element | Attente et role |
| --- | --- |
| `il2fb.exe` | Executable x86 correspondant exactement au profil Original ou modifie choisi |
| `conf.ini` | Configuration utilisateur et moteur ; doit etre fusionnee, jamais remplacee aveuglement |
| `files.SFS` | Archive de classes/ressources correspondant a la version 4.08, 4.09b ou 4.09m |
| `wrapper.dll` | Chargeur de fichiers libres requis seulement par l'EXE modifie historique |
| `Files\` | Surcharges libres du mod : classes, modeles, textures, cartes, sons et registres |
| `bin\java.dll`, `bin\hotspot\jvm.dll` | JVM fournie par le jeu de base |
| `jgl.dll`, `il2_core*.dll` | Pont graphique/JNI et coeur natif fournis par le jeu de base |
| `dx8Wrap.dll` | Chemin de rendu historique Direct3D 8, distinct du chargeur de mod |
| `mg_snd*.dll` | Moteur audio natif et variantes optimisees |

**Regle 1.15 :** un profil Original supprime proprement `wrapper.dll`, car le jeu original n'en utilise pas. Un profil modifie restaure le wrapper associe a son EXE. Un wrapper graphique ne doit jamais etre nomme `wrapper.dll` ni remplacer ce chargeur.

## Chaine de demarrage connue

1. `il2fb.exe` cree le processus 32 bits.
2. Il charge `bin\java.dll`, puis la JVM HotSpot par `bin\hotspot\jvm.dll`.
3. Dans le profil modifie, l'EXE et `wrapper.dll` forment un couple d'interface binaire pour intercepter l'ouverture des ressources SFS.
4. Le wrapper construit une table d'empreintes des ressources libres sous `mods` et `files`.
5. Une ressource libre trouvee est ouverte a la place de la ressource archivee ; sinon la demande repart vers le systeme SFS natif.
6. Les classes Java pilotent une grande partie du jeu, de l'IA et des objets. Les DLL natives assurent le rendu, le son, les entrees et l'acces aux ressources.
7. `jgl.dll` charge le fournisseur configure. OpenGL utilise normalement `Opengl32.dll`; le mode DirectX passe par `dx8Wrap.dll`, puis `d3d8.dll`.

L'ordre exact de resolution de l'ancien wrapper de 2008 doit encore etre trace
en execution. Le source public du wrapper SAS 3.3 traite `MODS`, puis `FILES`,
puis le SFS. Le port 1.15 conserve explicitement cet ordre, mais le binaire amont
non corrige reste non interchangeable a cause de sa convention d'appel.

## Interface et comportement de `wrapper.dll`

Les six copies modifiees sont identiques : PE32 x86, 233 472 octets, SHA-256 `8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78`.

Exports observes :

- `ReadDump` ;
- `__SFS_openf` ;
- `___CPPdebugHook`.

Le DLL de 2008 importe en retour les fonctions SFS de l'EXE par les ordinaux 7
et 8. Le source du Selector 3.3 cherche d'abord les symboles nommes, disponibles
dans notre EXE, puis seulement les ordinaux `0x87`/`0x88`. Son incompatibilite
directe vient surtout de ses exports `__cdecl`, alors que l'EXE 4.09m attend
`__stdcall`. La variante `native/wrapper-cache-409m` corrige cette ABI et
n'utilise pas le lanceur `dinput`.

Le cache amont `~wrapper.cache` evite le parcours complet des dossiers, mais ne
controle aucun changement. La variante 1.15 utilise plutot
`.open-sturmovik-cache` avec en-tetes, fins, compteurs, chemins controles et un
manifeste d'horodatage pour les 4 892 sous-dossiers et la racine `Files`. La moindre creation,
suppression ou renommage invalide le dossier parent ; un cache illisible ou
incoherent provoque une enumeration complete. La publication des paires cache /
manifeste est atomique et durable.

Le banc hors jeu sur le vrai `Files` mesure 1 890,2 ms pour construire les
89 738 entrees et 473,4 ms pour valider 4 893 dossiers (racine comprise), charger
le cache et resoudre une entree. Le gain isole est 1 416,8 ms ; le gain sur le
demarrage complet reste a mesurer dans IL-2.

Pour reprendre ou auditer ce travail : [archives et code source IL-2 Selector sur SourceForge](https://sourceforge.net/projects/il2selector/files/), [manuel communautaire du Selector](https://www.sas1946.com/downloads/essentialsas/selector/IL-2_Selector_Manual.pdf) et [composition historique du SAS Mod Activator](https://www.sas1946.com/main/index.php?topic=5310.0).

## Ressources libres, SFS et priorites

Le dossier `Files` contient actuellement 89 738 fichiers, 4 892 dossiers et 16 879 362 273 octets. Les zones principales sont :

- `Files\3do` : 83 619 fichiers, environ 12,35 Go ;
- `Files\Maps` : 1 975 fichiers, environ 4,14 Go ;
- `Files\Samples` : 603 fichiers, environ 334 Mo.

43 346 fichiers font au plus 4 Kio et 71 887 au plus 64 Kio. Le nombre d'entrees et de dossiers est donc plus important pour le lancement que le debit brut du SSD.

L'audit SFS a trouve 2 245 chemins communs entre `Files` et les archives :

- 179 copies strictement identiques, soit 1 504 582 octets ;
- 2 028 remplacements fonctionnels differents ;
- le reste n'est pas extractible ou comparable automatiquement.

**Regle 1.15 :** les 179 copies exactes sont conservees. Leur suppression compliquerait la reproductibilite pour un gain insignifiant. Les 2 028 ressources differentes ne doivent jamais etre supprimees en bloc.

Les principaux registres libres sont :

- `Files\com\maddox\il2\objects\air.ini` ;
- `Files\com\maddox\il2\objects\stationary.ini` ;
- `Files\com\maddox\il2\objects\ships.ini` ;
- `Files\com\maddox\il2\objects\technics.ini` ;
- `Files\Maps\all.ini`.

Le selecteur bascule maintenant `air.ini` et `stationary.ini` avec le profil. Les choix 7 a 9 utilisent les registres 4.09m. Toute future activation modulaire devra verifier le graphe classe-modele-texture-arme-cockpit-son-carte avant de masquer un contenu.

## Profils historiques

- Les six EXE modifies sont identiques entre les profils fournis.
- Les six `wrapper.dll` sont identiques.
- Les trois EXE Original sont identiques.
- Les variantes avec/sans 6DOF ont actuellement le meme EXE, le meme wrapper et le meme `files.SFS` dans chaque version ; elles ne peuvent donc pas produire deux comportements differents avec les fichiers disponibles.
- Le `files.SFS` 4.09m ajoute des centaines de ressources et modifie des dizaines de contenus par rapport a 4.09b. Le dossier `4.09final...` est bien la cible reelle.

## Java, classes et compatibilite

Le runtime de reference est Java HotSpot **1.3.1-b24**. L'EXE modifie contient les arguments `-Xcomp -Xverify:none -Xmx1G -Xincgc`.

Les 2 435 fichiers hexadecimaux sans extension situes a la racine de `Files` ont
un en-tete de classe Java et appartiennent a l'espace `com/maddox`. L'analyseur
structurel lit completement 2 415 d'entre eux ; 20 conditionnements atypiques
restent listes dans l'audit dedie.

Une JVM 1.3 accepte au plus la version 47. Un test isole a confirme qu'une classe version 50 provoque `UnsupportedClassVersionError`. L'EXE sait reconstruire en version 47 l'en-tete de certaines classes encodees, mais laisse intacte une classe qui commence deja par `CAFEBABE`. Plusieurs classes version 50 sont inscrites dans `air.ini`.

La [specification Oracle du format ClassFile](https://docs.oracle.com/javase/specs/jvms/se6/html/ClassFile.doc.html) decrit le magic `CAFEBABE`, les champs `minor_version`/`major_version` et les structures a respecter. Elle explique pourquoi modifier uniquement le numero de version ne garantit pas la compatibilite des instructions, attributs et references.

**Traitement 1.15 :** les 56 classes version 50 ont ete analysees instruction par
instruction et comparees aux classes/membres du `rt.jar` Java 1.3.1 du jeu. Pour
55, aucun opcode, attribut ou appel d'API recent n'a ete trouve : seul le major a
ete abaisse de 50 a 47. `BF_109F4` utilisait `java/lang/StringBuilder`, absent de
Java 1.3.1 ; sa reference a ete remplacee par l'API compatible
`java/lang/StringBuffer`, dont les signatures utilisees existent dans ce
runtime, puis son major a ete abaisse. Les 56 fichiers passent le parseur interne
et `javap -verbose`, et aucun major 50 ne subsiste. Les empreintes avant/apres
sont conservees dans `manifests/java47-1.15.json`. Ce resultat statique ne
dispense pas de faire apparaitre chaque appareil concerne dans une mission de
test.

## Memoire et processeur

- Le processus reste x86 32 bits.
- Les EXE modifies sont Large Address Aware. Sous Windows 64 bits, l'espace d'adressage utilisateur peut atteindre 4 Go ; cela ne signifie pas qu'un tas Java de 3 Go est stable.
- Le profil stable conserve provisoirement `-Xmx1G` afin de laisser de l'espace aux textures, DLL, cartes, sons et autres allocations natives.
- Le selecteur calcule un masque pour au plus quatre coeurs physiques avec un processeur logique par coeur. Il interroge les masques de topologie Windows et ne suppose pas l'ordre des fils SMT. `15` reste le repli.
- Le son possede au moins un thread natif. Le degre de parallelisme du rendu, de la simulation, du chargement et de l'IA reste a mesurer.
- `-Xcomp` est une piste de lenteur au lancement : il force la compilation des methodes. Son retrait ne sera compare que dans un profil experimental.

References systeme : [limites d'adressage des versions de Windows](https://learn.microsoft.com/en-us/windows/win32/memory/memory-limits-for-windows-releases) et [API Windows GetLogicalProcessorInformation](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformation) utilisee pour distinguer les coeurs physiques des fils logiques.

## Configuration graphique

Le modele `conf.max.ini` active le niveau maximal connu pour le chemin OpenGL historique : shaders materiels, eau 4, ombres, lumieres, geometrie, foret et distance elevees. Le selecteur fusionne seulement les sections gerees afin de conserver resolution, son, reseau et commandes du joueur.

Les extensions `TexEnvCombine4NV`, `DepthClampNV` et `TextureShaderNV` sont activees uniquement lorsque la carte active est NVIDIA. Intel, AMD et les cartes non identifiees restent sur les options generiques ARB. Cette detection par fournisseur est une securite initiale ; un futur assistant graphique devra tester la creation du contexte et les extensions reelles.

Profils prevus :

1. OpenGL natif, repli stable obligatoire ;
2. Direct3D 8 historique ;
3. dgVoodoo2 x86, candidat Windows D3D8 vers D3D11/12 ;
4. DXVK x86, experimental et selectionne selon les fonctions Vulkan ;
5. Mesa OpenGL sur D3D12, depannage ;
6. IL2GE, profil visuel distinct exigeant notamment OpenGL 4.5 et des reglages incompatibles avec le profil maximal actuel.

Tous les changements graphiques devront etre transactionnels : sources separees, empreintes SHA-256, sauvegarde, verification apres copie et restauration d'OpenGL natif en cas d'echec.

Documentation des candidats : [dgVoodoo2](https://dgvoodoo2.dege.freeweb.hu/dgVoodoo2/ReadmeGeneral/), [versions DXVK](https://github.com/doitsujin/dxvk/releases), [fonctions Vulkan requises par DXVK](https://github.com/doitsujin/dxvk/wiki/Driver-support), [limites de DXVK sous Windows](https://github.com/doitsujin/dxvk/wiki/Windows), [pilote OpenGL sur D3D12 de Mesa](https://docs.mesa3d.org/drivers/d3d12.html) et [projet IL2GE](https://gitlab.com/vrresto/il2ge).

## Chargements et execution : ordre de travail

1. Mesurer dans IL-2 le wrapper historique a froid et a chaud.
2. Mesurer le wrapper cache deja porte, puis le promouvoir seulement sans regression.
3. Comparer `-Xcomp` au mode mixte dans des executables de test separes.
4. Mesurer les fichiers reellement demandes au menu et dans des missions temoins.
5. Faire instancier les appareils dont les 56 classes ont ete traitees.
6. Construire des profils de contenu actif uniquement apres obtention du graphe de dependances.
7. Evaluer ensuite un SFS propre au mod, reproductible et optionnel.
8. Ajuster `.preload` seulement a partir des traces ; retirer une precharge peut deplacer la pause vers la mission.
9. Ajuster le tas Java et l'affinite seulement avec mesures de memoire native, tas, frametime et stabilite.

`Files\.preload` contient 417 directives, 412 uniques. Seules 114 correspondent actuellement a une surcharge libre ; les autres peuvent provenir des SFS. Les cinq repetitions ne justifient pas une modification.

## Programmes communautaires

Les quatorze groupes de `_OS_Programs` ont ete inventories statiquement. Aucun n'est active automatiquement. Les programmes incompatibles restent presents et inchanges, conformement a la decision du mainteneur. Une integration future devra documenter pour chaque outil : version, source, licence, fichiers ecrits, droits requis, version IL-2 compatible, conflit potentiel avec `conf.ini` et procedure de retour arriere.

Le forum [SAS 1946](https://www.sas1946.com/main/index.php) demeure une source communautaire majeure. Son [guide d'introduction au modding](https://www.sas1946.com/main/index.php?topic=50904.0) rappelle notamment le role de `air.ini`, `stationary.ini`, `technics.ini` et des fichiers de traduction. Ces informations communautaires doivent toujours etre recoupees avec les binaires et le profil 4.09m reellement livres.

## Exigences du selecteur et de l'installateur 1.15

- reconnaitre ou demander explicitement la racine cible ;
- refuser une installation incoherente ou une source manquante ;
- appliquer les patchs officiels necessaires jusqu'a 4.09m sur la cible, jamais dans les archives sources ;
- verifier version, taille ou SHA-256 des fichiers critiques ;
- copier EXE, `files.SFS`, `air.ini`, `stationary.ini` et wrapper dans une seule transaction ;
- retirer le wrapper sans erreur dans un profil Original ;
- installer les HUD dans `Files\i18n` ;
- ne jamais annoncer la reussite si une copie ou une verification echoue ;
- restaurer tous les fichiers geres en cas d'erreur ;
- invalider les futurs caches apres toute modification de contenu ;
- journaliser le profil final et les empreintes installees.

## Protocole de confirmation en execution

Le premier essai utilisera une copie complete et le choix 8, `4.09m modifie (sans 6DOF)`. Il devra relever :

- temps processus-vers-menu a froid et a chaud ;
- temps de chargement d'une petite mission et d'une grande carte ;
- ordre et temps d'acces aux SFS et fichiers libres ;
- exceptions Java et chargement des classes converties en version 47 ;
- memoire privee, virtuelle, tas Java et marge d'adressage ;
- usage et frametime par coeur/thread ;
- DLL de coeur, audio et rendu effectivement chargees ;
- fournisseur OpenGL/D3D/Vulkan reel ;
- erreurs de ressources, textures, sons, cartes et avions ;
- fermeture propre, second lancement et comportement du cache.

Une mesure de reference doit etre conservee avant chaque variante. Aucun resultat d'une session unique ne sera generalise sans repetition.

## Questions encore ouvertes

- ordre exact `mods`/`files` dans l'ancien wrapper de 2008 ;
- role complet de `ReadDump` et de l'absent `runtimedump.bin` ;
- comportement en jeu de l'ABI SFS 4.09m maintenant verifiee statiquement ;
- comportement en jeu des 56 classes Java traitees et origine de leurs sources ;
- bibliotheques natives reellement choisies par le moteur ;
- seuil de memoire stable avec le contenu maximal ;
- gain du cache sur le demarrage complet (le gain isole du wrapper est deja mesure), puis gain eventuel d'un SFS de mod et de profils de contenu ;
- backend graphique le plus fiable selon GPU et pilote ;
- dependances exactes de chaque avion, carte et utilitaire.

## Audits et preuves detaillees

- [Compatibilite des versions](VERSION_COMPATIBILITY.md)
- [Comparaison des profils](AUDIT_PROFILES.md)
- [Architecture du moteur](ARCHITECTURE_MOTEUR.md)
- [Analyse de wrapper.dll](ANALYSE_WRAPPER_DLL.md)
- [Audit et conversion des classes Java](AUDIT_CLASSES_JAVA.md)
- [Redondance SFS](AUDIT_SFS.md)
- [Programmes communautaires](AUDIT_OS_PROGRAMS.md)
- [Performances et wrappers graphiques](PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md)

## Bibliographie externe commentee

| Sujet | Lien | Utilite pour le developpeur |
| --- | --- | --- |
| Installation historique | [Guide Mission4Today](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1) | Ordre des patchs depuis le DVD 4.07m |
| Cible 4.09m | [Fiche du patch 4.09m](https://www.mission4today.com/index.php?file=details&id=3764&name=Downloads) | Precondition 4.08m et instructions d'origine |
| Versions ulterieures | [Annonce officielle communautaire 4.15m](https://forum.il2sturmovik.com/topic/79551-the-415m-patch-for-il-2-1946-has-been-released/) | Comprendre pourquoi un futur portage est separe |
| Chargeur de mods | [Source IL-2 Selector 3.3.0](https://sourceforge.net/p/il2selector/code/HEAD/tree/trunk/3.3.0/) | Auditer wrapper, cache, lanceur et options memoire |
| Compilation Windows x86 | [LLVM-MinGW](https://github.com/mstorsjo/llvm-mingw) | Chaine portable reproductible utilisee pour le wrapper cache |
| Utilisation du Selector | [Manuel IL-2 Selector](https://www.sas1946.com/downloads/essentialsas/selector/IL-2_Selector_Manual.pdf) | Parametres, cache et modes de diagnostic |
| Registres du mod | [Aide SAS aux nouveaux moddeurs](https://www.sas1946.com/main/index.php?topic=50904.0) | Emplacements communautaires de `air.ini`, `stationary.ini`, traductions |
| Format Java | [JVM Specification — ClassFile](https://docs.oracle.com/javase/specs/jvms/se6/html/ClassFile.doc.html) | Lire correctement en-tetes, versions et constant pool |
| Memoire x86 | [Microsoft — Memory Limits](https://learn.microsoft.com/en-us/windows/win32/memory/memory-limits-for-windows-releases) | Interpreter Large Address Aware sans confondre espace virtuel et RAM |
| Topologie CPU | [Microsoft — GetLogicalProcessorInformation](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformation) | Construire un masque par coeur physique |
| Traduction D3D8 | [dgVoodoo2](https://dgvoodoo2.dege.freeweb.hu/dgVoodoo2/ReadmeGeneral/) | Fonctionnalites, deploiement et limites du candidat Windows |
| Traduction Vulkan | [DXVK](https://github.com/doitsujin/dxvk) | Code, versions, pilotes requis et avertissements Windows |
| OpenGL de secours | [Mesa D3D12](https://docs.mesa3d.org/drivers/d3d12.html) | Comprendre le chemin OpenGL sur Direct3D 12 |
| Extension graphique IL-2 | [IL2GE](https://gitlab.com/vrresto/il2ge) | Prerequis OpenGL et reglages propres au profil visuel |
| Modernisation experimentale | [OpenIL2](https://github.com/DavidGregory084/OpenIL2) | Etudier une JVM et un chargeur modernes ; cible 4.14.1, donc non reutilisable directement en 1.15 |

Les liens communautaires peuvent disparaitre ou etre deplaces. Quand une ressource externe devient indispensable a la construction, sa version, sa licence, son SHA-256 et une copie autorisee doivent etre archives avec le projet.
