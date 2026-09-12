# Dossier technique vivant — IL-2 1946 / Open Sturmovik 1.15

## Objet du document

Ce fichier est la reference centrale de ce qui est decouvert sur le jeu original, le moteur, le format de l'add-on et les conditions necessaires a son fonctionnement. Il doit etre mis a jour a chaque nouvelle analyse statique ou session de test.

Chaque information appartient a l'un de ces niveaux :

- **verifie statiquement** : prouve par les fichiers, les empreintes, le desassemblage ou le code source consulte ;
- **confirme en execution** : observe dans une copie de test avec une mesure reproductible ;
- **hypothese** : explication plausible qui exige encore un essai ;
- **regle 1.15** : decision de construction ou de securite du projet.

**Devise du projet : REALISME MAX.** Une valeur historique doit etre preferee a
une approximation arbitraire, puis adaptee explicitement aux limites mesurees
du moteur 4.09m. Une fidelite affichee mais silencieusement tronquee, instable ou
non reproductible n'est pas consideree comme realiste.

Au 1er septembre 2026, l'analyse combine des audits statiques, plusieurs
lancements instrumentes jusqu'au menu et des essais en vol, dont Little Boy et
Fat Man. Les affirmations d'execution restent rattachees a leurs artefacts de
capture ; les outils externes de `_Utilities` et `_Game_Enhancements` demeurent inventories sans activation automatique.

## Perimetre et sources protegees

- Add-on modifiable : depot Open Sturmovik.
- Jeu de reference, lecture seule : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\resources\IL2\IL 2 Sturmovik 1946`.
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

Les extensions de fichiers ne decrivent pas toujours leur encodage reel. Les
atlas GUI `basicelements.tga` et `staticelements.tga` livres par l'add-on portent
la signature binaire `IMF\x1A10`, et non un en-tete TGA standard. Ils doivent etre
lus avec un outil IL-2 compatible IMF et conserves avec leurs fichiers `.mat` ;
un editeur TGA generique ne constitue pas un validateur. Les details et les
empreintes sont consignes dans [l'audit des musiques et fonds](AUDIT_MUSIQUES_ET_FONDS.md).

## Profils historiques

- Les six EXE modifies partagent le meme format, mais les trois profils sans
  6DOF utilisent maintenant une variante native distincte des trois profils
  avec 6DOF.
- Les six `wrapper.dll` sont identiques.
- Les trois EXE Original sont identiques.
- Les variantes avec/sans 6DOF partagent le wrapper et le `files.SFS` de chaque
  version. Leur differentiel EXE historique est restaure et les cinq classes
  6DOF sont presentes ; la distinction fonctionnelle doit encore etre validee
  avec TrackIR.
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
- Le profil stable 1.15 conserve cette selection de quatre coeurs physiques. Un profil experimental **HT/SMT** pourra autoriser tous les processeurs logiques disponibles (par exemple `0xFF` sur le Core i5-8350U), mais il ne deviendra un choix recommande qu'apres comparaison des temps de chargement, des frametimes, des micro-saccades et de la stabilite en mission avec le profil physique (actuellement `0x55` sur cette machine).
- Le son possede au moins un thread natif. Le degre de parallelisme du rendu, de la simulation, du chargement et de l'IA reste a mesurer.
- `-Xcomp` est une piste de lenteur au lancement : il force la compilation des methodes. Son retrait ne sera compare que dans un profil experimental.

Les EXE et DLL propres aux profils modifies peuvent etre corriges pour repousser les limites constatees : en-tete Large Address Aware, allocations internes, compteurs, index, files de chargement, synchronisation et parallelisme. Une modification binaire ne peut cependant pas transformer le processus en 64 bits : sous Windows 32 bits, l'espace utilisateur reste limite par la configuration du systeme (jusqu'a 3 Gio avec 4GT) et doit aussi contenir la JVM, les DLL et les allocations natives. Toute correction sera appliquee uniquement aux copies Open Sturmovik, sous forme de patch reproductible avec version source, offsets ou symboles, empreintes SHA-256 avant/apres, controles PE32, test de retour arriere et validation en jeu. Le jeu original de reference reste strictement intact.

### Arret de HotSpot 1.3.1 et fils non daemon

L'EXE natif appelle `DestroyJavaVM` apres le retour de la boucle Java principale.
HotSpot 1.3.1 attend alors que tous les fils Java non daemon, sauf le fil courant,
soient termines. Un `java.util.Timer` cree sans option daemon peut donc garder
`il2fb.exe` vivant indefiniment, meme si la panne initiale est deja terminee.

Les deux dumps du 31 aout 2026 ont montre ce cas exact : le fil principal attend
sur un evenement Windows et `ZutiTimer_RadarsCountRefresh` reste le seul travail
dans un `TimerThread` non daemon. Il faut distinguer les deux phases lors de chaque
diagnostic : **cause du retour anormal de la boucle de jeu**, puis **ressource
qui empeche l'arret**. Le second symptome produit la boite Windows « laisser le
programme repondre / mettre fin a la tache », mais ne designe pas necessairement
la premiere cause.

Les dumps x86 sont analyses hors jeu par `Analyze-IL2Minidump.py`, puis les
structures HotSpot 1.3.1 par `Analyze-IL2HotSpot131.py`. L'inspection ciblee du
tas est disponible dans `Inspect-IL2HotSpotObject.py`. Les conclusions et les
empreintes des deux cas sont dans
[le dossier B-29/Fat Man](BUG_CRITIQUE_B29_FATMAN.md).

### Compatibilite binaire des classes globales

La priorite `Files` sur les SFS remplace une classe Java complete ; elle ne
fusionne ni ses methodes, ni ses champs, ni ses classes internes avec une autre
version. Deux mods peuvent donc fonctionner separement et casser le jeu une fois
reunis, meme si chaque fichier existe et se charge correctement.

Le B-29 Silverplate fournit un cas prouve. Sa classe `Bomb` appelle
`Explosions.generate(Actor, Point3d, float, int, float, int)`. La variante
`Explosions` active dans Open Sturmovik contient les multiplicateurs de crateres
Zuti, mais seulement la methode a cinq parametres. Au premier passage sur cet
appel a six parametres, HotSpot doit lever `NoSuchMethodError`. Si un minuteur
non daemon reste vivant, cette erreur de liaison peut ensuite apparaitre sous la
forme trompeuse d'un processus Windows gele.

L'A/B du 31 aout 2026 confirme cette chaine : avec la famille `Explosions`
coherente, Fat Man atteint sa cible, detruit les objets, le jeu reste repondant
et le journal termine par `Radars count refreshing stopped!`. Le minuteur Zuti
n'est donc pas bloque lors du chemin normal ; il masque surtout la sortie
anormale provoquee par l'erreur de liaison.

**Regle 1.15 :** pour toute surcharge d'une classe globale du moteur, inventorier
les descripteurs JVM des methodes et champs publics/proteges, les interfaces et
la famille des classes internes. Comparer la variante active avec chaque mod qui
l'appelle. Une correction de compatibilite doit fusionner explicitement les API
et comportements utiles ; changer seulement l'ordre des dossiers ne suffit pas.
Le cas reproductible, les empreintes et la matrice d'essai sont documentes dans
[le dossier B-29/Fat Man](BUG_CRITIQUE_B29_FATMAN.md).

## Souris et curseur sur les Windows modernes

Dans `[rts]`, `mouseUse=2` confie au moteur IL-2 l'entree et le dessin de son
curseur 3D. Ce mode est utile en vol : le pointeur disparait quand aucune
interface n'est active et le libre regard n'est pas limite par les bords du
bureau. Sur les Windows modernes, le curseur historique peut toutefois devenir
invisible ou rester bloque, notamment en fenetre ; un changement de focus par
Alt+Tab peut parfois le retablir. `mouseUse=1` utilise le curseur Windows, plus
fiable dans les menus, mais moins adapte au regard souris continu.

**Regle 1.15 :** le profil de test fenetre 1024 x 768 impose `mouseUse=1`. Les
profils plein ecran conservent le choix du joueur et pourront utiliser
`mouseUse=2` apres validation du couple OS/backend graphique. Le futur lanceur
presentera ce choix clairement et proposera un retour au curseur Windows. Lors
d'une capture de vol, ProcDump surveille automatiquement les exceptions non
gerees ; la surveillance de fenetre bloquee doit etre armee manuellement apres
le chargement si le scenario l'exige, car l'absence de reponse normale du vieux
moteur pendant l'indexation produit sinon de faux dumps de blocage.

Sources communautaires et systeme : [explication des modes souris sur SAS
1946](https://www.sas1946.com/main/index.php?topic=50141.0), [cas du curseur
invisible et mise a l'echelle Windows](https://learn.microsoft.com/en-us/answers/questions/2689898/mouse-cursor-missing-while-playing-il2-1946-game).

References systeme : [limites d'adressage des versions de Windows](https://learn.microsoft.com/en-us/windows/win32/memory/memory-limits-for-windows-releases) et [API Windows GetLogicalProcessorInformation](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformation) utilisee pour distinguer les coeurs physiques des fils logiques.

## Configuration graphique

L'ancien modele `conf.max.ini` a ete retire du pack. Le candidat `_Game Switcher/conf.ini` reste conserve hors production et sans activation automatique ; il documente le niveau maximal connu pour le chemin OpenGL historique : shaders materiels, eau 4, ombres, lumieres, geometrie, foret et distance elevees.

Les extensions `TexEnvCombine4NV`, `DepthClampNV` et `TextureShaderNV` sont activees uniquement lorsque la carte active est NVIDIA. Intel, AMD et les cartes non identifiees restent sur les options generiques ARB. Cette detection par fournisseur est une securite initiale ; un futur assistant graphique devra tester la creation du contexte et les extensions reelles.

Le coeur 4.09m conserve un detecteur de capacites concu pour les GPU du debut
des annees 2000. Son chemin Perfect accepte notamment l'extension
`GL_NV_texture_shader`. Sur l'Intel UHD 620, le pilote 31.0.101.2141 expose
OpenGL 4.6 et les programmes de shaders ARB, mais pas cette extension NVIDIA ;
le moteur imprime donc deux avis Perfect meme avec un profil Excellent valide.
Ce cas ne doit pas etre masque dans le binaire. Le rapport produit par
`tools/Test-IL2GraphicsCompatibility.ps1` distingue l'avis historique attendu
d'une demande Perfect reellement incompatible. Les captures suivantes
ajouteront automatiquement `graphics-compatibility.json`.

Pour les OS et cartes modernes, la cible est une adaptation par couches : sonde
OpenGL x86 du contexte reel, selection d'un backend connu, configuration propre
a ce backend, essai graphique court, puis repli automatique vers OpenGL natif.
Les DLL x86 du jeu et le chargeur de mods `wrapper.dll` restent separes des
wrappers graphiques. Aucun profil ne doit deduire la compatibilite Perfect du
seul nom NVIDIA, AMD ou Intel.

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

### Pause de chargement graphique confirmee

Le dump du passage `20260831-192529Z-profile9-warm-windowed1024-startup`, pris
pendant une fenetre non repondante juste avant une mission Hawker, fournit une
premiere attribution native precise. Le thread principal est dans le pilote
Intel `ig9icd32.dll`, sous `opengl32!glTexImage2D`, avec
`il2_corep4!BmpUtils_BMP8PalTo4TGA4` dans sa pile. Le moteur convertit donc une
texture indexee IL-2 puis l'envoie au pilote OpenGL sur son thread principal.
Pendant cette operation, il ne traite plus les messages Windows et ProcDump
peut declarer un faux gel apres dix secondes.

Ce resultat ne prouve pas encore quelle texture est la plus couteuse. Les
prochains collecteurs devront conserver le nom logique demande juste avant
`BmpUtils`, la taille convertie, le temps de `glTexImage2D` et l'etat du cache.
La solution recherchera d'abord la suppression des reconversions et envois
redondants, puis une preconversion ou une precharge ciblee ; un thread OpenGL ne
sera pas deplace sans verifier les contraintes de contexte du pilote. Le
detecteur de gel devra aussi appliquer un delai plus long pendant les ecrans de
chargement qu'en vol.

### Architecture des explosions nucleaires

Les classes `BombLittleBoy` et `BombFatMan` du paquet Silverplate declarent
toutes deux `newEffect=1`, `nuke=1` et un rayon de 3 200 m. Leurs puissances
historiques dans le mod sont respectivement `8 000 000` et `13 000 000`.
`Bomb.doExplosion()` transmet `nuke` au calcul de degats `MsgExplosion`, mais
transmet `newEffect` a la surcharge a six arguments de `Explosions.generate`.
Les deux bombes suivent ainsi la meme routine visuelle `bombFatMan_land/water`.

La famille Silverplate cree six systemes de particules `Eff3DActor`. Dans les
ressources historiques, leurs emetteurs s'arretent entre 1 et 130 secondes et
les particules principales vivent seulement 30 a 128 secondes. Une pause suivie
d'une reprise faisait disparaitre le panache. Dans la branche non `ActorLand`,
la petite explosion restante etait aussi expliquee par un appel explicite a
`bomb50_land(..., 10.0f)`.

L'inspection du moteur 4.09m montre que `Eff3D` possede un mode temps reel et un
mode temps de simulation. `GUIWindowManager` suspend `Time`, mais la fabrique
`Eff3DActor.New(...)` ne force pas le type d'horloge. Le constructeur v1.15
insere desormais `Eff3D.initSetTypeTimer(false)` avant chacun des douze appels
terre/eau. Le choix devient deterministe et la pause ne consomme plus la duree
de simulation du nuage. La capture image par image montre toutefois une seconde
couche : quand `renderGUI` cede de nouveau le focus au monde 3D, l'emetteur natif
repart visuellement d'un etat jeune, puis rejoue son age en accelere.

La classe native `Eff3D` expose des methodes protegees `pause(boolean)` et
`isPaused()` qui ne sont pas appelees par le menu. Un candidat v1.15 a donc
enregistre les acteurs visuels de Little Boy et Fat Man et surveille toutes les
25 ms la transition de pause pour appeler `Eff3D.pause(boolean)`. L'essai
`20260901-131015Z-profile9-warm-windowed1024-startup` invalide ce candidat : le
panache repart encore apres pause/reprise et il se reinitialise aussi apres un
demi-tour qui le fait sortir puis rentrer dans le champ de la camera. L'absence
de message d'echec de reflexion montre que l'appel natif ne suffit pas. Le
defaut appartient donc au cycle rendu/culling/reconstruction, pas uniquement a
l'horloge de pause. Cette surveillance n'est pas une correction publiable et
doit etre retiree ou remplacee.

Le rayon fixe ne constitue pas un modele nucleaire realiste. La v1.15 devra
appliquer des zones progressives sur la distance tridimensionnelle, avec flash,
surpression, souffle, secousse et dommages propres aux acteurs. L'onde sera
retardee selon sa propagation et le calcul groupera les acteurs afin de borner
le cout CPU. Le B-29 place a 5 000 m au moment de l'impact est le premier cas de
reference : il doit percevoir l'eclair puis l'onde environ quinze secondes plus
tard, sans etre detruit automatiquement.

Le prototype v1.15 construit le 31 aout 2026 realise cette architecture sans
modifier la JVM. `Explosions` conserve les multiplicateurs Zuti et recoit les
deux surcharges Silverplate. `Explosion.receivedTNT_1meter` retrouve la
decroissance normale en inverse du carre au lieu d'accorder la puissance totale
a tous les acteurs de la sphere. `MsgExplosion` delegue les explosions
nucleaires a `NuclearBlast`, qui effectue une recherche spatiale unique et
programme le dommage de chaque acteur sur l'horloge de simulation avec un delai
`distance / 343` secondes. Les avions de la zone exterieure recoivent une
impulsion de vitesse bornee au meme instant.

Little Boy est configuree a 15 kt, 4 400 kg et 600 m AGL ; Fat Man a 21 kt,
4 670 kg et 503 m AGL. Les hauteurs et rendements sont recoupes avec le
[National Park Service](https://home.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm)
et le [Department of Energy](https://www.energy.gov/sites/default/files/maprod/documents/DE99001330.pdf).
Les rayons IL-2 de 2 150 et 2 360 m correspondent approximativement a la zone
2 psi apres application de la racine cubique du rendement et de la geometrie de
l'explosion aerienne. La table 10 kt utilisee est celle du
[guide HHS REMM](https://remm.hhs.gov/PlanningGuidanceNuclearDetonation.pdf) ;
la mise a l'echelle est documentee par
[OSTI](https://www.osti.gov/servlets/purl/4114321-vb7jLn/).

Les limites sont volontaires et doivent rester visibles : la zone 1 a 0,5 psi
et l'impulsion transmise a l'avion sont des approximations de jouabilite, le
flash n'inflige pas encore de brulure thermique et aucun rayonnement ionisant
n'est simule. Les airbursts ne creent pas de cratere. L'ensemble est construit
par `tools/Build-OpenSturmovikNuclearPatch.ps1`, verifie sans API Java recente,
force en major 47 et decrit par
`manifests/effects/nuclear-blast-v1.15.json`.

L'essai reel Little Boy sans pause du 1er septembre 2026 valide l'ABI corrigee
`Tuple3d.add(Tuple3d)` : le flash, le nuage et le panache s'executent sans gel,
le processus reste repondant et quitte avec le code zero. La pause/reprise fait
en revanche disparaitre le panache presque immediatement, alors qu'il persiste
plus d'une minute sans pause. La session
`20260901-060621Z-profile9-warm-windowed1024-startup` precise le symptome : une
grande masse visible avant le menu revient comme une petite sphere a la premiere
image de reprise, puis retrouve son volume en environ 5,5 secondes. Le processus
reste repondant, autour de 627 Mio prives, sans pic CPU ni erreur Java. Cette
anomalie concerne le cycle natif de rendu des particules et non l'arrivee
retardee de l'onde.

La campagne la plus recente confirme cette distinction. Little Boy reproduit
la remise a zero visuelle apres pause et apres sortie du champ ; Fat Man termine
un essai simple sans gel. Un stress de seize B-29 larguant Fat Man contre seize
chasseurs termine sans ralentissement en vol signale par le pilote. Apres
armement, le processus atteint environ 733 Mio prives et 2 034 Mio virtuels.
Ces resultats valident la compatibilite de base et la tenue de ce scenario, pas
la duree d'une mission dense ni la preservation du panache.

Le cycle visuel candidat suit trois reperes physiques. Pour Little Boy, le
[National Park Service](https://home.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm)
place le diametre maximal de la boule de feu et le debut du champignon environ
une seconde apres la detonation. Le chapitre II de
[The Effects of Nuclear Weapons](https://www.atomicarchive.com/resources/documents/effects/glasstone-dolan/chapter2.html)
decrit la montee, la circulation toroidale, les vents convergents, une
stabilisation vers dix minutes et une visibilite d'environ une heure ou plus.
Open Sturmovik represente donc la formation pendant 600 secondes de simulation
et la persistance du nuage stabilise jusqu'a 3 600 secondes. Le moteur 4.09m
plafonne cependant `nParticles` a 512 par emetteur et `LiveTime` a 128 s. Le
modele ne depasse jamais ces valeurs : les emetteurs de montee renouvellent
leurs pools pendant dix minutes, puis une action sur l'horloge de simulation
cree a haute altitude un emetteur stabilise de 512 particules, actif de la
dixieme minute a la premiere heure. Le maximum theorique vaut 1 544 particules
au depart sur terre et 1 288 sur l'eau, puis 2 056/1 800 durant le recouvrement
de transition. Le nombre instantane de particules est ainsi borne et les
valeurs ne sont pas silencieusement tronquees. Cela ne garantit cependant pas
la destruction des acteurs qui portent ces emetteurs. Il s'agit d'une
approximation macroscopique, pas d'une simulation de dynamique des fluides.

L'inspection de `Eff3DActor` ajoute une contrainte de duree de vie. Un acteur
cree avec une duree de processus negative ne programme pas sa propre fin. Cinq
des six acteurs initiaux de chaque detonation, puis l'acteur stabilise, utilisent
actuellement `-1`. La liste partagee de surveillance conserve en outre chaque
acteur encore valide et se reveille toutes les 25 ms. Une mission a seize
explosions peut donc conserver au moins quatre-vingts acteurs initiaux apres le
flash, avant meme les nuages stabilises. C'est un risque statique de retention
et de cout de surveillance, pas encore une fuite memoire prouvee : le prochain
test long devra compter les acteurs et verifier leur destruction.

Enfin, la reference d'altitude du nuage stabilise est actuellement de 5 000 m
pour 10 kt avant mise a l'echelle. Elle produit environ 5,7 km pour Little Boy
et 6,4 km pour Fat Man, tres en dessous des 40 000 a 50 000 pieds documentes
pour le maximum historique vers dix minutes. Le rendu stabilise doit donc etre
recalibre vers environ 12 a 15 km, puis valide visuellement sans creer une
transition brutale ni depasser les limites x86.

Le modele physique actuel s'arrete apres une impulsion radiale unique appliquee
par `ShockAction`. Le fichier d'effet du panache ne represente aucun volume
atmospherique : y entrer plus tard ne produit ni vent, ni ascendance, ni
turbulence. L'extension prevue devra enregistrer une zone temporaire par
explosion et l'actualiser a faible frequence sur l'horloge de simulation. Elle
combinera un vent radial decroissant, une colonne ascendante, une couronne
descendante et un bruit turbulent borne. La recherche des avions devra etre
spatiale, la force plafonnee et le cout independant du nombre de particules.
Ce modele restera une approximation macroscospique adaptee au moteur IL-2, pas
une simulation CFD.

### Audit transversal des effets et des nuages

Les mecanismes `Eff3D`, les horloges, les limites de particules, le vent et le
chargement des textures sont partages par de nombreuses ressources. Toute
anomalie decouverte pendant les essais nucleaires sera donc recherchee dans les
bombes conventionnelles, explosions, incendies, fumigenes, fumee des moteurs,
trainees, poussieres et effets navals. Une correction commune ne sera generalisee
qu'apres un controle negatif et une mesure CPU, GPU, memoire et temps d'image.

Deux contraintes sont deja confirmees comme globales pour les classes d'effet
`TParticlesSystemParams` et `TSmokeSpiralParams` de la 4.09m : `nParticles` est
borne a 512 par emetteur et `LiveTime` a 128 secondes par particule ; la
transition de transparence ne peut pas depasser la vie effective. Ces limites
s'appliquent donc aux bombes, explosions, fumees, incendies, trainees et nuages
qui utilisent ce moteur. Une duree superieure doit etre representee par un
emetteur borne qui renouvelle ses particules ou par des phases programmees, pas
par un nombre que le moteur tronque silencieusement.

Le scan de 5 171 classes de base trouve seulement deux references a
`Eff3D.initSetTypeTimer` : sa propre declaration et `SmokeGeneric`, qui demande
le temps reel uniquement dans l'etat de l'editeur. Aucun indice ne justifie donc
de modifier globalement la fabrique pour toutes les missions. Le correctif
nucleaire selectionne explicitement le temps de simulation a ses points de
creation ; l'audit general verifiera chaque famille representative avant toute
extension.

Un audit distinct couvrira les nuages meteorologiques : apparition a distance,
transition entre niveaux de detail, chargement progressif, comportement pendant
la pause et l'acceleration temporelle, interaction avec le vent, anticrenelage,
cout sur OpenGL natif et wrappers, et stabilite du moteur x86. Cet audit fait
partie de la comprehension complete du jeu ; seules les corrections prouvees et
maitrisables seront candidates a la v1.15.

## Programmes communautaires

Les quatorze groupes de l'ancien `_OS_Programs` ont ete inventories. IL2 Connect et VoiceOverlay ont ete retires faute d'usage recent identifiable. DCG et San FOV ont ensuite ete retires le 12 septembre 2026, faute de preuve de permission pour leur inclusion dans le pack ; voir `RETRAIT_COMPOSANTS_V1.15.md`. Les outils conserves sont repartis entre `_Utilities` pour la creation, la configuration, la consultation et les services communautaires, et `_Game_Enhancements` pour tout composant agissant sur le jeu ou en parallele pendant son execution. Ce dossier commun contient Gapa et les profils AOC 1a. Gapa n'est pas active automatiquement. Une integration future devra documenter pour chaque outil : version, source, licence, fichiers ecrits, droits requis, version IL-2 compatible, conflit potentiel avec `conf.ini` et procedure de retour arriere.

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

Les essais seront separes en phases. La phase 1 s'arrete au menu principal :
demarrage instrumente, quelques secondes d'observation sans lancer de mission,
puis fermeture propre. Les missions et le jeu reel ne commenceront qu'apres
analyse et correction des anomalies de cette premiere phase.

La procedure executable, les outils utilises, les donnees collectees et la regle
de redemarrage avant la mesure a froid sont decrits dans
[`PROTOCOLE_PREMIER_LANCEMENT.md`](PROTOCOLE_PREMIER_LANCEMENT.md).

Sous reserve de la verification de la future copie de test, le premier candidat
est le choix 8, `4.09m modifie (sans 6DOF)`, avec le wrapper historique stable et
OpenGL natif. Ce profil limite les variables experimentales tout en exercant le
coeur de l'add-on. Si l'etat de la copie le permet, une mesure originale 4.09m
sera conservee comme reference avant la mesure modifiee.

La phase 1 devra relever :

- temps processus-vers-menu a froid et a chaud ;
- ressources et SFS demandes avant l'apparition du menu ;
- exceptions Java, DLL chargees et erreurs de ressources ;
- memoire, CPU, entrees/sorties et threads jusqu'a la stabilisation du menu ;
- comportement pendant quelques secondes au menu, puis fermeture et relance.

Les phases ulterieures devront relever :

- temps de chargement d'une petite mission et d'une grande carte ;
- ordre et temps d'acces aux SFS et fichiers libres ;
- exceptions Java et chargement des classes converties en version 47 ;
- memoire privee, virtuelle, tas Java et marge d'adressage ;
- usage et frametime par coeur/thread ;
- DLL de coeur, audio et rendu effectivement chargees ;
- fournisseur OpenGL/D3D/Vulkan reel ;
- erreurs de ressources, textures, sons, cartes et avions ;
- comportement du cache et stabilite en jeu.

Une mesure de reference doit etre conservee avant chaque variante. Aucun resultat d'une session unique ne sera generalise sans repetition.

### Correspondance entre les pourcentages et le travail du moteur

Chaque ecran de chargement devra etre traite separement : demarrage du jeu,
chargement d'une mission rapide, petite mission temoin, grande carte et mission
avec beaucoup d'appareils. Le pourcentage affiche n'est pas suppose representer
un volume d'octets ni une duree lineaire tant que le code ou les traces ne l'ont
pas confirme.

Une capture video horodatee conservera chaque changement de valeur. En parallele,
une trace filtree sur `il2fb.exe` et ses processus descendants enregistrera les
ouvertures et lectures de fichiers, les chargements d'images/DLL, les creations de
threads, les acces au Registre et leurs codes de retour. Les compteurs CPU par
coeur, memoire privee et virtuelle, entrees/sorties et nombre de threads seront
echantillonnes regulierement. Process Monitor fournit la trace fonctionnelle ;
WPR/ETW sera utilise lorsque le detail CPU, disque ou les piles d'appels sont
necessaires : [Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon)
et [Windows Performance Recorder](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/windows-performance-recorder).

Le rapport associera a chaque palier `0, 5, 10, ... 100 %` :

- l'heure d'apparition, le temps passe depuis le palier precedent et le temps cumule ;
- les ressources demandees entre les deux paliers et les dernieres operations avant le changement ;
- la couche servante, lorsqu'elle est identifiable : `MODS`, `Files`, SFS officiel ou repli absent ;
- les DLL nouvellement chargees et les threads crees ;
- les variations de CPU, memoire et lectures disque ;
- toutes les erreurs, avec chemin, operation, code Windows, repetition et consequence visible.

Les resultats `NAME NOT FOUND`, `PATH NOT FOUND` et recherches de DLL ne seront
pas automatiquement classes comme pannes : un moteur peut sonder plusieurs noms
avant de choisir un repli valide. Une erreur sera classee **attendue**, **benigne**,
**degradation**, **bloquante** ou **a confirmer**, apres verification de l'etape
suivante et du resultat en jeu.

La trace Windows voit les lectures du conteneur SFS, mais pas toujours le nom
logique de la ressource interne. Pour completer cette limite, une variante de
diagnostic separee du wrapper cache devra journaliser les appels `__SFS_openf`,
leurs empreintes 64 bits, la resolution eventuelle vers un fichier libre et le
resultat du repli SFS. Cette variante ne remplacera jamais le wrapper stable et
son journal sera desactive dans la distribution normale. Les empreintes restantes
seront rapprochees des index SFS analyses afin d'identifier autant que possible
les textures, classes, sons, cartes et objets demandes a chaque palier.

Chaque scenario sera execute au moins trois fois a froid et trois fois a chaud.
Le livrable conservera la trace brute, une chronologie par tranche de 5 %, la
liste dedoublonnee des erreurs et une conclusion expliquant ce que le moteur fait
effectivement, sans deduire une phase a partir du seul dessin de la barre.

## Configurations minimale et recommandee

La version 1.15 devra publier deux configurations propres a Open Sturmovik, et
non recopier les exigences historiques d'IL-2 1946. Aucun chiffre ne sera annonce
comme definitive avant les essais en execution.

La **configuration minimale** sera le materiel le plus faible valide pour
installer l'add-on, demarrer de facon repetable, atteindre le menu, charger les
missions temoins retenues et jouer sans erreur bloquante avec un profil graphique
adapte. La **configuration recommandee** visera le profil visuel maximal retenu,
une marge memoire suffisante, des chargements courts et une fluidite stable sur
les missions representatives du contenu de l'add-on.

La fiche finale precisera au minimum :

- versions et architecture de Windows effectivement testees ;
- niveau de performances CPU par coeur, nombre de coeurs utiles et comportement
  avec l'affinite limitee a quatre coeurs physiques ;
- quantite de RAM systeme, pic de memoire privee/virtuelle du processus 32 bits et
  marge necessaire pour ne pas epuiser son espace d'adressage ;
- espace d'installation, espace temporaire et taille maximale des caches ;
- comportement sur disque dur et SSD, temps a froid et a chaud ;
- GPU, VRAM, pilote et capacites OpenGL/D3D/Vulkan exigees par chaque profil ;
- resolution, options graphiques et scenario utilises pour qualifier le resultat ;
- temps de chargement, images par seconde, percentiles de frametime, stabilite et
  erreurs observees sur plusieurs executions.

Les exigences seront separees pour OpenGL natif et pour chaque wrapper graphique
eventuellement distribue. Un wrapper moderne ne devra jamais rendre la
configuration minimale plus exigeante si OpenGL natif reste fonctionnel. Les
machines virtuelles pourront verifier l'installation et certaines versions de
Windows, mais elles ne serviront pas seules a qualifier les performances GPU.

Le premier test limite au menu fournira une borne basse pour CPU, RAM et disque.
Les valeurs minimales et recommandees ne seront finalisees qu'apres les essais de
petite mission, grande carte, nombreux appareils et session prolongee.
Les premieres classes materielles candidates, la distinction Windows x86/x64
et le protocole 1080p60 sont maintenant consignes dans
[`CONFIGURATIONS_MATERIELLES_V1.15.md`](CONFIGURATIONS_MATERIELLES_V1.15.md).

## Limites techniques du moteur et extension de ses capacites

Le projet devra maintenir un inventaire des limites du moteur 4.09m. Une valeur
ne sera presentee comme une limite confirmee que si elle est visible dans le code
ou les binaires, atteinte par un test reproductible, ou documentee par une source
communautaire recoupee. Les suppositions seront marquees comme telles.

L'etude couvrira notamment :

- l'espace d'adressage du processus 32 bits, la repartition entre tas Java et
  allocations natives, la fragmentation et le seuil reel de manque de memoire ;
- la JVM 1.3.1 : versions de classes, tas, pile, ramasse-miettes, JNI, nombre de
  classes et compatibilite des bibliotheques Java ;
- le parallelisme reel du rendu, de la simulation, de l'IA, du son et du chargeur,
  ainsi que les sections qui restent limitees par un seul coeur ;
- le systeme SFS : nombre de conteneurs et de fichiers libres, temps d'indexation,
  priorite des couches, empreintes 64 bits, collisions, caches et tailles limites ;
- les tables de contenu (`air.ini`, `stationary.ini`, objets, armes et appareils),
  leurs parseurs, compteurs, indices et eventuelles valeurs codees en dur ;
- les cartes et missions : dimensions, textures, objets, appareils, IA, effets,
  scripts et quantites maximales stables ;
- le rendu : API 32 bits, extensions OpenGL, Direct3D 8, shaders, formats de
  textures, VRAM, appels de dessin, resolution, eau, ombres et effets ;
- le son, les entrees, le reseau, le nombre de joueurs et les formats de mission ;
- les interfaces entre EXE, DLL, wrapper, Java et code natif, dont les conventions
  d'appel, exports, adresses et dependances propres a la version 4.09m.

Pour chaque limite, la documentation conservera : la valeur observee, le scenario
qui l'atteint, le symptome, le composant responsable, les preuves, la marge de
securite, les solutions candidates et leurs regressions possibles. Les essais de
frontiere augmenteront une seule variable a la fois et seront repetes autour du
dernier niveau stable.

Les solutions seront classees du moins invasif au plus invasif : configuration,
reduction du cout des donnees, cache ou profil de contenu, wrapper externe,
remplacement d'une DLL, modification Java, puis correctif binaire de l'EXE. Toute
extension devra rester reversible, specifique a 4.09m, controlee par empreinte et
accompagnee d'un profil stable de repli. Repousser un plafond ne sera retenu que
si le nouveau niveau reste stable et ne deplace pas simplement la panne vers la
memoire, le rendu, le reseau ou la sauvegarde des missions.

La preservation d'etat des particules suivra la meme regle. Little Boy et Fat
Man constituent le premier banc parce que leur defaut est capture image par
image. A terme, le mecanisme devra couvrir toute explosion de bombe, tout
incendie, fumee, trainee ou poussiere qui reproduit une perte d'etat apres
pause. La generalisation sera pilotee par un registre d'effets observes, avec
un seul controleur partage, et non par un correctif global non mesure du menu ou
du moteur natif.

Les premiers plafonds deja etablis ou fortement encadres sont l'architecture
32 bits, la version 47 maximale des classes chargeables par la JVM 1.3.1 et le
cout d'indexation des 89 738 fichiers libres. Le gain reel apporte par Large
Address Aware, le nombre de coeurs effectivement exploites et les limites de
contenu restent a quantifier en execution.

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
- [Audit des binaires, memoire x86 et affinite CPU](AUDIT_BINAIRES_X86.md)
- [Audit et conversion des classes Java](AUDIT_CLASSES_JAVA.md)
- [Audit des effets et limites 4.09m](AUDIT_EFFETS_409M.md)
- [Redondance SFS](AUDIT_SFS.md)
- [Programmes communautaires](AUDIT_OS_PROGRAMS.md)
- [Performances et wrappers graphiques](PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md)
- [Outils de modding, SFS, Buttons et Dump Mode](OUTILS_MODDING_IL2_1946.md)

## Bibliographie externe commentee

| Sujet | Lien | Utilite pour le developpeur |
| --- | --- | --- |
| Installation historique | [Guide Mission4Today](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1) | Ordre des patchs depuis le DVD 4.07m |
| Cible 4.09m | [Fiche du patch 4.09m](https://www.mission4today.com/index.php?file=details&id=3764&name=Downloads) | Precondition 4.08m et instructions d'origine |
| Versions ulterieures | [Annonce officielle communautaire 4.15m](https://forum.il2sturmovik.com/topic/79551-the-415m-patch-for-il-2-1946-has-been-released/) | Comprendre pourquoi un futur portage est separe |
| Chargeur de mods | [Source IL-2 Selector 3.3.0](https://sourceforge.net/p/il2selector/code/HEAD/tree/trunk/3.3.0/) | Auditer wrapper, cache, lanceur et options memoire |
| Compilation Windows x86 | [LLVM-MinGW](https://github.com/mstorsjo/llvm-mingw) | Chaine portable reproductible utilisee pour le wrapper cache |
| Utilisation du Selector | [Manuel IL-2 Selector](https://www.sas1946.com/downloads/essentialsas/selector/IL-2_Selector_Manual.pdf) | Parametres, cache et modes de diagnostic |
| Extraction ciblee | [IL-2 Selector, fil de publication](https://www.sas1946.com/main/index.php?topic=16403.0) | Dump Mode et journalisation SFS dans un clone de laboratoire |
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
