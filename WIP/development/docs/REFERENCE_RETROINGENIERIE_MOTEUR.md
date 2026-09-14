# Reference de retro-ingenierie du moteur IL-2 1946 4.09m

> Etat du 12 septembre 2026 : MDS est retire du contenu local ;
> [le suivi des retraits](RETRAIT_COMPOSANTS_V1.15.md) fait autorite. Les exemples
> Zuti tires des captures d'aout/septembre restent des observations historiques
> du moteur et ne decrivent pas les fonctions attendues apres retrait. AOC est
> reconstruit sans MDS : [preuve](AUDIT_AOC_SANS_MDS_20260912.md).

Derniere mise a jour : 11 septembre 2026.

Découverte du 11 septembre : le chargeur natif de textures du profil 4.09m testé rapporte un tampon de **4 202 496 octets**. Voir la preuve runtime, les empreintes des DLL et les inconnues dans [l’audit des textures](AUDIT_CHARGEMENT_TEXTURES_4.09M.md#limite-du-tampon-natif-de-texture--11-septembre-2026).

## Finalite

Cette reference rassemble les donnees necessaires pour comprendre, ameliorer
ou, a long terme, reimplementer le moteur utilise par Open Sturmovik. Elle ne
pretend pas que le code source original a ete retrouve. Elle separe les
interfaces observables, les formats de donnees, le comportement mesure et les
zones natives encore opaques.

Deux voies peuvent etre etudiees, sans leur donner le meme statut :

1. la voie active pour la v1.15 consiste a prolonger le moteur x86 4.09m par
   des surcharges, correctifs et wrappers reversibles ;
2. un runtime x64 capable de relire les donnees et de reproduire le
   comportement est seulement une **piste de recherche ulterieure**.

Le projet n'a pas decide de realiser ce portage x64 et celui-ci ne fait pas
partie du perimetre de sortie 1.15. La section correspondante sert uniquement a
ne pas perdre les contraintes deja identifiees. Si cette piste etait un jour
retenue, elle constituerait un portage ou une reimplementation : basculer le
drapeau PE de l'executable ne peut pas convertir le jeu en x64.

## Niveaux de preuve

Toute nouvelle fiche, limite ou fonction doit utiliser un de ces niveaux :

| Code | Signification | Preuve minimale |
| --- | --- | --- |
| `S` | confirme statiquement | octets, en-tete, import/export, bytecode, configuration ou source disponible |
| `R` | confirme en execution | journal et capture reproductible, version et empreintes conservees |
| `I` | inference | plusieurs indices concordants, mais test A/B manquant |
| `U` | inconnu | question ouverte ; ne pas en faire une promesse produit |

Une conclusion `R` doit donner le scenario, l'heure de l'evenement et le chemin
du resultat brut. Une conclusion `S` doit donner le fichier, la version et son
empreinte. Une source communautaire seule explique une piste, mais ne transforme
pas une hypothese en fait propre a notre assemblage 4.09m.

## Instantane reproductible

Lancer :

```powershell
.\tools\Export-IL2ReverseEngineeringSnapshot.ps1
```

Le resultat machine est
[`manifests/engine/reverse-engineering-snapshot-v1.15.json`](../manifests/engine/reverse-engineering-snapshot-v1.15.json).
Il conserve les empreintes des binaires et SFS de racine, la distribution du
contenu libre, les versions des classes Java, les signatures IMF rencontrees,
les classes/champs des effets et les tailles des principaux registres. Ce
manifeste doit etre regenere apres toute modification structurelle du contenu.

Attention : l'instantane de la racine du depot ne designe pas automatiquement
le profil actif dans le dossier de test. Le selecteur peut installer un autre
couple EXE / `files.SFS` / `wrapper.dll`. Toute capture runtime doit donc
conserver ses propres empreintes apres selection du profil.

## Architecture reconstituee

### Couche native Windows

Etat `S` :

- `il2fb.exe` est un programme PE32 i386. Il cree le processus, initialise les
  bibliotheques natives, charge Java et expose des fonctions SFS/JNI ;
- `bin\java.dll` et `bin\hotspot\jvm.dll` constituent le runtime HotSpot 1.3.1 ;
- `il2_core.dll` et `il2_corep4.dll` exportent le pont JNI du rendu, des cameras,
  paysages, maillages et textures ;
- `mg_snd.dll` et `mg_snd_sse.dll` portent le moteur audio natif ;
- `jgl.dll` est la couche de dispatch graphique ;
- en OpenGL, elle appelle normalement `Opengl32.dll` ;
- le chemin historique DirectX passe par `dx8Wrap.dll`, puis `d3d8.dll` ;
- le `wrapper.dll` d'Open Sturmovik est un chargeur de ressources/mods et non un
  wrapper graphique.

Interfaces deja inventoriees : `il2fb.exe` expose environ 145 symboles,
`il2_core*.dll` environ 396 interfaces JNI, `mg_snd*.dll` environ 115 interfaces
JNI et `jgl.dll` environ 1 439 fonctions de dispatch. Les listes et empreintes
sont dans [`AUDIT_MODIFIABILITE_MOTEUR.md`](AUDIT_MODIFIABILITE_MOTEUR.md) et
[`manifests/binaries/pe-audit.json`](../manifests/binaries/pe-audit.json).

### Machine virtuelle et logique Java

Etat `S` :

- l'EXE modifie contient `-Xcomp -Xverify:none -Xmx1G -Xincgc` ;
- la JVM 1.3.1 accepte au plus les fichiers de classe major 47 ;
- une grande partie des objets, appareils, IA, effets et regles de mission est
  implementee en Java ;
- les classes libres dont le nom est une empreinte hexadecimale portent un
  `ClassFile` Java et resolvent principalement vers `com/maddox` ;
- une classe libre remplace entierement la classe de meme nom issue du SFS : il
  n'existe aucune fusion automatique de methodes ou de champs.

Cette derniere regle explique le conflit Silverplate/Zuti sur
`Explosions.generate(...)`. La variante Silverplate appelait un descripteur a
six parametres absent de la classe Zuti active. Une classe globale fusionnee
doit conserver l'union explicite des descripteurs, champs, interfaces et classes
internes requis par tous les appelants.

Pour chaque classe surchargee, archiver :

- nom interne JVM et empreinte du nom de fichier ;
- major/minor, constant pool, interfaces, champs et methodes ;
- descripteurs complets, visibilite et exceptions ;
- classes internes et relations d'heritage ;
- appels vers Java standard et vers `com.maddox` ;
- symboles natifs JNI touches ;
- empreintes avant/apres et script de reconstruction ;
- test minimal qui execute le chemin modifie.

Les 56 anciennes classes major 50 ont ete ramenees a 47 apres audit d'opcodes,
d'attributs et d'API. `BF_109F4` exigeait aussi `StringBuilder` vers
`StringBuffer`. La compatibilite structurelle est prouvee ; le comportement de
chaque avion concerne ne l'est pas encore.

### Systeme de fichiers virtuel

Etat `S`, sauf mention contraire :

1. le jeu demande une ressource par le mecanisme SFS ;
2. l'EXE modifie delegue l'ouverture a `wrapper.dll` via `__SFS_openf` ;
3. le wrapper associe le chemin logique a une empreinte IL-2 ;
4. une surcharge libre est renvoyee si elle existe ;
5. sinon l'ouverture retombe sur le SFS natif.

Le source communautaire du Selector 3.3 et le nouveau port indiquent l'ordre
`MODS`, puis `FILES`, puis SFS. L'ordre exact du vieux wrapper 2008 reste `I`
tant qu'une trace d'acces ne l'a pas confirme. Les doublons exacts ne sont pas
necessairement inutiles : leur presence peut figer une dependance et proteger
la reproductibilite d'un profil.

`wrapper.dll` historique exporte `ReadDump`, `__SFS_openf` et
`___CPPdebugHook`. Il importe les fonctions SFS de l'EXE par ordinaux. Le couple
EXE/wrapper constitue donc une ABI indivisible. Le port cache 4.09m corrige la
convention d'appel attendue et ajoute une invalidation par manifeste. Un cache
`~wrapper.cache` amont est dangereux parce qu'il ne compare ni dates, ni tailles
ni contenu.

Les archives SFS sont des conteneurs proprietaires. Le lecteur local sait lire
notamment la version 202 et extraire des classes centrales en memoire. Ne pas
reconstruire une archive de production avant un aller-retour binaire, un audit
des entrees non resolues et un demarrage complet. Pour les corrections 1.15,
preferer une surcharge libre reversible.

### Chaine de demarrage observable

Etat `R/S` :

1. creation du processus x86 ;
2. chargement du wrapper de mods pour un EXE modifie ;
3. chargement de `java.dll` puis de HotSpot ;
4. montage/indexation des ressources libres et SFS ;
5. initialisation Java, classes et registres ;
6. creation du contexte graphique par `jgl.dll` ;
7. initialisation audio ;
8. chargement du menu ou de la piste d'introduction ;
9. chargement de mission : carte, ponts, objets statiques, appareils, cockpits,
   modeles de vol, armes, effets, sons et scripts.

Les pourcentages graphiques ne sont pas encore une API documentee. Les arrets a
5 % ont ete observes pendant les configurations et ressources initiales, mais
ont aussi ete contamines par une base de versions melangees. Le palier proche
de 60 % est fortement associe aux appareils/modeles de vol. Toute cartographie
definitive devra correlier image, `log.lst`, trace de fichiers et piles de
threads, sans recopier une table trouvee sur Internet comme fait moteur.

## Formats et donnees a preserver

| Format ou registre | Nature connue | Fonction | Regle de retro-ingenierie |
| --- | --- | --- | --- |
| `conf.ini` | texte INI | rendu, fenetre, son, reseau, entrees et options moteur | conserver avant/apres ; identifier les valeurs ignorees ou bridees |
| `air.ini` | registre texte | identifiant affiche, classe Java, camp, pays/saison et drapeaux | croiser classe, `SPAWN`, cockpit, FMD, armes et localisation |
| `stationary.ini`, `ships.ini`, `technics.ini` | registres texte | objets statiques et mobiles | verifier classe et type exacts pour la version |
| `Maps/all.ini` | registre texte | noms et `load.ini` des cartes | detecter alias et doublons avant toute normalisation |
| `.mis` | texte sectionne | mission, wings, waypoints, cibles, objets et cameras | conserver coordonnees, unites et variantes testees |
| `.properties` | texte/localisation | titres et descriptions | associer a la mission ou ressource exacte |
| `.eff` | texte parametrique | particules, fumee, feu, lumiere et propagation | respecter les bornes parsees par 4.09m |
| `.mat` | texte ou conteneur | materiau et reference de texture | ne jamais accepter un fichier nul comme valide |
| `.tga` | standard ou faux ami IMF | texture/atlas | inspecter la signature, pas seulement l'extension |
| `.tgb`, `.msh`, `.him`, `.sim` | binaire proprietaire | textures, maillages, hierarchies et donnees de vol | conserver original, outil, version et aller-retour |
| `Files/gui/GAME/buttons` | conteneur protege | modeles de vol et donnees liees | outil strictement compatible 4.09m obligatoire |
| `.ntrk` | piste reseau/rejeu | enregistrement reproductible d'une mission | verifier creation, taille, empreinte et version avant relecture |
| SFS | archive/index proprietaire | classes et ressources officielles | lecture seule par defaut ; surcharge libre preferee |

### Images IMF sous extension TGA

Les atlas GUI et certains fonds nommes `.tga` commencent par
`IMF 1A 31 30` (`IMF\x1A10`). Un visualiseur TGA standard ne les valide pas.
La documentation doit conserver signature, dimensions decodees, palette,
compression eventuelle, orientation et chemin logique. Toute conversion doit
etre testee par un aller-retour et dans le moteur.

### Effets de particules

Les classes observees incluent notamment `TParticlesSystemParams` et
`TSmokeSpiralParams`. Les champs rencontres comprennent `MatName`, `Color0`,
`Color1`, `nParticles`, `FinishTime`, `MaxR`, `PhiN`, `PsiN`, `LiveTime`,
`EmitFrq`, `EmitVelocity`, `EmitTheta`, `GasResist`, `VertAccel`, `Wind`, `Size`
et `Rnd`.

Bornes annoncees par le parseur 4.09m pendant le Dump :

| Champ | Minimum | Maximum |
| --- | ---: | ---: |
| `nParticles` | 1 | 512 |
| `FinishTime` | -1 | 10 000 |
| `MaxR` | 0 | 32 |
| `PhiN`, `PsiN` | 0 | 32 |
| `LiveTime` | 0,01 | 128 |
| `TranspTransitionTime` | 0 | `LiveTime` apres bridage |
| `Wind` | 0 | 100 |
| `Rnd` | 0 | 0,95 |

`nParticles` est un plafond simultane et non un nombre total de particules a
emettre. `FinishTime` regle la periode d'emission et `LiveTime` la vie de chaque
particule. Deplacer un `Eff3DActor` ne translate pas les particules deja emises.
Une pause peut vider ou repeupler le tampon visible sans faire avancer
`Time.current()`. Ces comportements ont un impact sur toutes les fumees,
incendies et explosions, pas seulement les bombes atomiques.

### Temps, actions et cycle de vie Java

Le correctif nucleaire confirme les primitives suivantes :

- `Time.current()` fournit le temps de simulation utilise pour l'age logique ;
- une pause fige ce temps ;
- `MsgAction` permet de programmer des transitions ;
- `Eff3DActor.New(...)` cree un effet ;
- `postDestroy(Time.current())` programme sa destruction ;
- `Engine.land().HQ(x, y)` fournit l'altitude du terrain local ;
- `Engine.collideEnv().getSphere(...)` recupere les acteurs dans un volume.

Une reimplementation devra distinguer le temps de simulation, le temps reel,
le temps du rendu et le temps reseau. L'etat logique ne doit jamais dependre de
la presence de l'objet dans le champ de la camera.

### Missions et cameras

Les missions observees utilisent notamment `[MAIN]`, `[Wing]`, une section par
escadrille, `<wing>_Way`, `[NStationary]`, `[StaticCamera]`, `[Buildings]`,
`[Bridge]` et `[House]`. Les waypoints portent type, X, Y, altitude, vitesse et
eventuellement cible/indice.

Dans le format 4.09m teste, une camera statique conserve position et hauteur,
mais pas un point `look-at` fiable. Son orientation initiale depend de l'etat de
vue. Une piste NTRK doit donc servir a rejouer l'evenement et regler les vues
sans repeter le largage.

### Audio

Le moteur charge des presets texte et des WAV, avec un backend natif WinMM et
des variantes standard/SSE. Deux definitions du meme preset sous `MODS` et
`Files` peuvent entrer en conflit. Un son doit etre documente par nom logique,
preset resolu, WAV demandes, priorite, canal, boucle, distances et journal en
execution. L'absence de `music/inflight` est actuellement un avertissement reel
et confirme que le profil ne fournit pas de musique en vol.

### Entrees et 6DOF

Les commandes resident dans le profil `Users`. Certaines actions ne sont lues
que dans un environnement de touches particulier : `quickSaveNetTrack` exige
`[HotKey $$$misc]`, et non `[HotKey misc]`. Les variantes avec et sans 6DOF
partagent toujours le wrapper et le `files.SFS` de leur version, mais leurs EXE
sont maintenant distincts. Le differentiel natif historique et les cinq classes
TrackIR/HookPilot sont decrits dans `manifests/profiles-6dof-v1.15.json` ; la
difference de mouvement reste a confirmer avec le peripherique reel.

Le futur lanceur devra inventorier DirectInput, joysticks, axes, zones mortes,
TrackIR/6DOF et conflits de touches sans remplacer silencieusement le profil du
joueur.

## Rendu et chargement des textures

Un dump place le thread principal dans `opengl32!glTexImage2D`, avec
`il2_corep4!BmpUtils_BMP8PalTo4TGA4` dans la pile. Des textures de cockpit B-29
ont ete rechargees avec plusieurs ensembles de drapeaux. L'inference actuelle
est que conversion et transfert GPU se produisent au moins en partie sur le
thread principal et contribuent aux saccades proches du joueur.

Une instrumentation future doit enregistrer pour chaque texture :

- chemin logique et source effective (`MODS`, `Files` ou SFS) ;
- signature/format, dimensions, mipmaps et taille decompressee ;
- options de conversion et empreinte du resultat ;
- premier demandeur Java/natif ;
- heure de demande, conversion, envoi GPU et premiere utilisation ;
- nombre de reconversions et de reenvois ;
- budget RAM/VRAM avant et apres ;
- temps passe dans `BmpUtils` et `glTexImage2D` ;
- comportement apres changement de vue, pause et retour de culling.

Le prechargement doit etre pilote par une distance, un budget et une priorite,
pas par le chargement aveugle de toutes les textures 2K/4K. Les profils devront
separer qualite maximale et haute qualite securisee x86.

## Memoire, CPU et limites structurelles

### Limites x86 actuelles

Le processus, la JVM, les DLL, le code natif, les classes, les textures et les
sons partagent l'espace virtuel x86. Large Address Aware autorise jusqu'a 4 Gio
sur Windows 64 bits, ou environ 3 Gio sur un Windows 32 bits configure 4GT. Le
tas Java de 1 Gio laisse volontairement une marge aux allocations natives.

Avant tout ajustement, mesurer separement : committed/private bytes, working
set, espace virtuel reserve/engage, tas Java utilise, heaps natifs, allocations
du pilote, nombre de classes, handles et threads. Une hausse de `-Xmx` peut
reduire la marge disponible pour les textures et accelerer un manque d'espace
virtuel.

### Parallelisme

L'affinite quatre coeurs autorise le placement ; elle ne parallelise pas un
algorithme sequentiel. Les mesures courantes montrent souvent environ un coeur
de charge pour le processus. Il faut identifier les threads par pile et role :
simulation, rendu, son, chargeur, garbage collector, timers Zuti et reseau.
Chaque proposition de parallelisme doit definir les donnees partagees, l'ordre
deterministe, les verrous, l'autorite reseau et le risque de course.

### Arret JVM

Apres la boucle Java, l'EXE appelle `DestroyJavaVM`. HotSpot 1.3.1 attend les
threads Java non daemon. Un `java.util.Timer` Zuti encore vivant peut donc
maintenir le processus apres une exception precedente. La boite Windows
« laisser le programme repondre » peut etre un symptome secondaire : rechercher
d'abord pourquoi la boucle principale est sortie, puis quel thread interdit
l'arret.

## Piste exploratoire : ce qu'exigerait un portage x64

Statut : `U/I`, hors perimetre v1.15, aucune decision de realisation.

### Impossible par simple patch

Ajouter Large Address Aware, modifier un octet PE ou injecter une DLL x64 ne
convertit pas le programme. Un processus x64 ne peut pas charger les DLL x86
existantes, et inversement. Le runtime actuel assemble des conventions d'appel,
structures et pointeurs 32 bits entre EXE, HotSpot, JNI, SFS, rendu, son et
entrees.

### Sous-systemes a remplacer ou recompiler ensemble

1. hote executable et boucle principale ;
2. JVM x64 ou machine d'execution Java compatible ;
3. toutes les interfaces JNI et leurs structures partagees ;
4. SFS, empreintes, wrapper de surcharge et cache ;
5. rendu, textures, maillages, terrain, cameras et fenetrage ;
6. audio, entrees, joysticks et suivi de tete ;
7. simulation native eventuelle et synchronisation des threads ;
8. reseau, serialisation et lecture/ecriture des pistes ;
9. installateur/lanceur, profils et compatibilite des sauvegardes.

Les classes Java major 47 peuvent devenir une specification et, selon leurs
dependances, fonctionner sur une JVM moderne. Mais les appels JNI, les API
internes et les comportements de HotSpot 1.3.1 doivent etre inventories avant
toute migration. Les conteneurs SFS, `Buttons`, maillages et textures restent
des formats a decoder independamment de l'architecture CPU.

### Strategie possible si la piste etait validee plus tard

1. figer un corpus 4.09m de reference par empreintes ;
2. construire des lecteurs en lecture seule pour chaque format ;
3. extraire le graphe classes/ressources et les interfaces JNI ;
4. enregistrer des traces deterministes de missions courtes ;
5. reimplementer d'abord le montage de ressources et les formats ;
6. creer un visualiseur x64 de cartes/maillages/textures sans simulation ;
7. reimplementer boucle temporelle, acteurs, messages et rendu d'effets ;
8. ajouter physique, IA, armes, degats et modeles de vol par tests differentiels ;
9. ajouter audio, entrees et reseau ;
10. ne viser la compatibilite complete qu'apres reproduction des missions et
    pistes de reference.

Une transition moins risquee peut conserver le jeu x86 comme oracle et placer
des outils x64 autour de lui : lanceur, indexeur, convertisseur, analyseur,
serveur de cache et capture. Cela n'elargit pas l'espace virtuel du jeu, mais
permet de developper les composants modernes avant la reimplementation du coeur.

## Corpus de tests differentiels a constituer

Chaque test doit posseder une mission minimale, une piste si possible, des
empreintes d'entree, le journal attendu et des tolerances numeriques :

- demarrage froid/chaud, avec et sans introduction ;
- resolution d'une meme ressource depuis SFS, `Files` et `MODS` ;
- une carte vide, puis objets, ponts, eau, meteo et nuages ;
- un avion stock, un modde, un cockpit multi-postes et un appareil non pilotable ;
- modele de vol, commandes, train, armement et dommages ;
- Little Boy/Fat Man, effets courts/longs, pause, culling et acceleration ;
- 32 appareils, puis paliers croissants jusqu'a la premiere limite ;
- son unique, preset en collision, son manquant et musique ;
- joystick, souris, clavier, TrackIR et 6DOF ;
- piste NTRK, sauvegarde de mission et hote/client reseau ;
- sortie normale, exception Java, hang natif et thread non daemon restant.

Les bombes atomiques ne sont qu'un premier banc des acteurs et particules. Une
architecture remplacee devra ensuite generaliser le cycle de vie a chaque bombe,
incendie, fumee, trainee, poussiere, nuage et effet meteo.

## Fiche obligatoire pour chaque limite du moteur

```text
Identifiant :
Version et profil :
Niveau de preuve : S / R / I / U
Composant :
Valeur ou seuil :
Scenario minimal :
Symptome :
Journal / dump / capture :
Empreintes des entrees :
Cause racine :
Marge stable connue :
Correctifs candidats :
Risques et regressions :
Retour arriere :
Etat de validation :
```

## Donnees brutes a ne jamais jeter

- executables, DLL, SFS et `Buttons` de chaque version, avec SHA-256 ;
- configurations avant/apres et profils `Users` ;
- listes d'imports, exports, sections PE, relocations et chaines ;
- bytecode original, desassemblage et graphe d'appels des classes modifiees ;
- journaux complets, evenements Windows, dumps et piles de threads ;
- mesures processus/systeme et horodatages de phases ;
- images de capture et parametres exacts de la camera ;
- pistes NTRK, missions et proprietes ;
- index SFS, chemins logiques, sources effectives et collisions ;
- ressources communautaires, version, auteur, page d'origine, licence et hash ;
- scripts ayant produit chaque correctif et manifeste de sortie.

Les captures volumineuses peuvent rester hors Git, mais leur manifeste,
emplacement, taille, empreinte et conclusion doivent etre versionnes. Une preuve
sans moyen d'identifier son binaire ou sa configuration n'est pas reproductible.

## Cartographie documentaire

- [`JOURNAL_DIAGNOSTIC_V1.15.md`](JOURNAL_DIAGNOSTIC_V1.15.md) : chronologie et erreurs a ne pas repeter ;
- [`DOSSIER_TECHNIQUE_IL2_1946.md`](DOSSIER_TECHNIQUE_IL2_1946.md) : fonctionnement general et liens externes ;
- [`ARCHITECTURE_MOTEUR.md`](ARCHITECTURE_MOTEUR.md) : architecture statique courte ;
- [`AUDIT_MODIFIABILITE_MOTEUR.md`](AUDIT_MODIFIABILITE_MOTEUR.md) : surfaces modifiables et priorites ;
- [`ANALYSE_WRAPPER_DLL.md`](ANALYSE_WRAPPER_DLL.md) : ABI et chargement des mods ;
- [`AUDIT_SFS.md`](AUDIT_SFS.md) : archives et redondances ;
- [`WIP/analyses/langues-il2/README.md`](../../analyses/langues-il2/README.md) : catalogues de langue, versions et replis ;
- [`AUDIT_CLASSES_JAVA.md`](AUDIT_CLASSES_JAVA.md) : format et compatibilite Java ;
- [`AUDIT_BUTTONS_MODELES_DE_VOL.md`](AUDIT_BUTTONS_MODELES_DE_VOL.md) : modeles de vol ;
- [`AUDIT_EFFETS_409M.md`](AUDIT_EFFETS_409M.md) : parametres/limites des effets ;
- [`AUDIT_CHARGEMENT_TEXTURES_4.09M.md`](AUDIT_CHARGEMENT_TEXTURES_4.09M.md) : textures et saccades ;
- [`AUDIT_BINAIRES_X86.md`](AUDIT_BINAIRES_X86.md) : PE, memoire et CPU ;
- [`OUTILS_MODDING_IL2_1946.md`](OUTILS_MODDING_IL2_1946.md) : outils et compatibilites ;
- [`RESULTATS_TEST_NUCLEAIRE_2026-09-03.md`](RESULTATS_TEST_NUCLEAIRE_2026-09-03.md) : preuves runtime recentes.

## Limites actuelles de la connaissance

Restent `U` ou `I` : code source du coeur natif, structures completes JNI,
algorithme exact de toutes les empreintes SFS, ordre du wrapper 2008, format
complet de `Buttons`, semantique complete de `.msh/.him/.sim/.tgb`, ordonnanceur
des acteurs, physique et IA natives eventuelles, protocole reseau, format NTRK,
budget VRAM, limites d'objets/cartes/joueurs et selection exacte des variantes
P4/SSE. Ces inconnues doivent devenir des tickets de recherche avec un test
minimal ; elles ne doivent pas etre comblees par supposition.

## Localisation et choix de langue — 13 septembre 2026

Les archives locales confirment sept langues exploitables par l’assemblage : français, anglais, allemand, russe, tchèque, hongrois et polonais. Le choix actif vient de `[rts] locale` dans `conf.ini`. Les six familles `gui`, `maps`, `plane`, `regInfo`, `regShort` et `weapons` possèdent des variantes dépendantes du moteur ; elles sont donc archivées séparément pour 4.08m, 4.09b et 4.09m. Les faits, empreintes, traductions partielles, règles de repli et commandes de reproduction sont détaillés dans [`WIP/analyses/langues-il2/README.md`](../../analyses/langues-il2/README.md).

Niveau `S` pour l’inventaire et les transactions de fichiers ; niveau `I` pour le rendu complet de chaque écran tant que les sept langues n’ont pas été parcourues visuellement dans le jeu.

## Affichage de la version au chargement — 13 septembre 2026

La classe `com.maddox.il2.engine.ConsoleGL0Render` contient les libellés stock `V 4.08m`, `V 4.09b1m` et `V 4.09m`. Les profils Open Sturmovik installent une surcharge propre qui ajoute `mod no 6DOF` ou `mod 6DOF`. Le profil stock 4.09b affiche volontairement `V 4.09b` ; le texte historique et l’interprétation prudente de `b1m` restent consignés dans `WIP/analyses/affichage-version-chargement/README.md`. Ces chaînes d’affichage sont indépendantes de la compatibilité réseau.

## Corrections de profils validées le 13 septembre 2026

Les essais en jeu ont montré que les exécutables moddés 4.08m, 4.09b et
4.09m consultent les catalogues portant le suffixe _ru même lorsque la valeur
locale=fr est écrite dans la section rts de conf.ini. Cette contrainte explique
pourquoi une ancienne installation pouvait contenir des textes français dans
des fichiers nommés _ru.

Le switcheur conserve maintenant la langue choisie dans conf.ini et, pour un
profil moddé, installe en plus 36 catalogues complets portant le suffixe _ru.
Le contenu de ces fichiers correspond à la langue sélectionnée. Les traductions
absentes en allemand, tchèque, hongrois ou polonais utilisent le catalogue
anglais du même moteur. Le HUD sélectionné est écrit en dernier dans
hud_log_ru.properties. Les profils stock continuent à employer le suffixe
normal déterminé par locale.

Missions/Background.tga et samples/Music/Menu participent à l’identité du
profil. Leur absence dans l’ancienne transaction faisait conserver les
ressources Open Sturmovik après un passage en stock. Chaque dossier de profil
contient maintenant son fond et son jeu musical sous Profiles. Un profil stock
installe le fond officiel IL-2 1946, empreinte
07F94BD46D063CCA7363F6C5D62676ABC749C875FBE88277FD0CB4EE732E7591,
et 13 pistes stock. Un profil moddé installe le fond Open Sturmovik, empreinte
88C63E7A103AEA84076E710500255F21D5536B3ECAEB40149615E40A83A2B3B8,
et 14 pistes Open Sturmovik. Ces fichiers font partie de la sauvegarde et de la
restauration transactionnelles.

Le profil stock 4.09b ne charge pas une classe libre placée dans Files sans le
wrapper moddé. Pour supprimer réellement l’affichage historique V 4.09b1m, la
classe ConsoleGL0Render a donc été remplacée dans le files.SFS propre au profil.
L’archive finale affiche V 4.09b. Sa reconstruction a aussi établi que le
chiffrement SFS v202 dépend du nom files.SFS : construire l’archive sous un
autre nom puis la renommer invalide sa somme de contrôle. Repack-SfsEntry.py
refuse maintenant un nom de destination différent du nom source.

Les dossiers de profils portent désormais les préfixes 4.09b et 4.09m. Leurs
anciens préfixes 4.09 et 4.09 final ne sont plus utilisés sous _Game Switcher.
