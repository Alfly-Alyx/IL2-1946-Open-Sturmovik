# Audit de lisibilite, modifiabilite et performances du moteur IL-2 1946

Derniere mise a jour : 1er septembre 2026.

## Objet et methode

Cet audit determine quels composants du moteur IL-2 1946 4.09m peuvent etre
ouverts, analyses et modifies, puis classe les pistes d'optimisation par gain
probable et par risque.

Deux emplacements ont ete examines :

- le depot Open Sturmovik 1.15 ;
- l'installation de test
  `C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`.

L'examen a ete strictement statique : lecture des en-tetes, empreintes,
interfaces PE, archives SFS, classes Java, configuration et journaux existants.
Le jeu n'a pas ete lance. Aucun EXE, DLL, SFS, classe Java, fichier de contenu ou
fichier de l'installation de test n'a ete modifie. Aucun cache de wrapper n'a
ete cree.

## Conclusion

Le moteur est modifiable par couches, mais il n'existe pas de code source
complet du moteur natif dans le depot.

1. La configuration et les ressources texte sont directement editables.
2. La logique Java est extractible, decomposable en classes et surchargeable
   sans reconstruire `files.SFS`.
3. Le chargeur de mods dispose d'une nouvelle implementation en C modifiable et
   reproductible.
4. Les DLL et l'EXE natifs sont analysables et techniquement patchables, mais
   leur modification exige du desassemblage, des empreintes strictes et des
   essais de non-regression.
5. Le remplacement de la JVM ou la reecriture du coeur natif ne doivent pas etre
   les premieres pistes de performance.

La priorite recommandee est : options JVM, chargement des textures et classes
Java mesurees en mission. Le cache du wrapper apporte un gain reel, mais trop
faible pour expliquer seul la duree totale du demarrage.

## Profil actif observe

L'installation de test utilise actuellement le profil 4.09m modifie :

| Element | Observation |
|---|---|
| `il2fb.exe` | PE32 i386, 274 432 octets, Large Address Aware ; variante 6DOF finale SHA-256 `7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21` |
| `wrapper.dll` | Wrapper historique sans cache, 233 472 octets, SHA-256 `8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78` |
| `files.SFS` | Profil modifie 4.09m, 23 010 398 octets, SHA-256 `5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71` |
| JVM | HotSpot 1.3.1 x86 sous `bin\hotspot\jvm.dll` |
| Rendu | OpenGL natif, pilote Intel UHD Graphics 620 OpenGL 4.6 |
| Fenetre | 1024 x 768, mode fenetre |
| Affinite | `ProcessAffinityMask=85`, soit `0x55`, un fil logique sur chacun des quatre coeurs physiques |
| Profil graphique | `HardwareShaders=0`, `Forest=2`, `LandGeom=2`, `Water=2` |
| Diagnostics | `LOG=1`, `LOGDEBUG=1`, journal d'evenements conserve |

Le profil `4.09m stock` conserve le contenu de jeu original, avec la seule
normalisation du fond de demarrage `gui\background0.tga`. Son `files.SFS` fait
23 998 523 octets et porte l'empreinte
`FCFCE245EC23FF314C6CD86E9A51D563D091CFF74DDD0B46B704B670C0340C6A`.
L'archive officielle avant cette adaptation faisait 25 111 885 octets et
portait l'empreinte
`9F7D136C586EB3FCD258C5C000F34951D410A0236934F22ABA2516637874B095`.

## Composants natifs

Tous les composants examines sont des PE32 i386 lisibles. Leurs tables
d'importation et d'exportation ont ete parcourues sans charger les DLL.

| Composant | Interfaces observees | Sources disponibles | Modification |
|---|---|---|---|
| `il2fb.exe` | 145 exports, dont SFS, allocation RTS, entrees, empreintes et nombreuses interfaces JNI | Non | Patch ou interception possible, risque eleve |
| `wrapper.dll` historique | 3 exports : `ReadDump`, `__SFS_openf`, `___CPPdebugHook` | Non | Remplacable seulement par une implementation ABI-compatible |
| `native/wrapper-cache-409m` | Meme ABI 4.09m, cache avec manifeste et repli automatique | Oui, C | Modifiable et recompilable |
| `jgl.dll` | 1 439 exports OpenGL/JNI ; charge dynamiquement le fournisseur graphique | Non | Remplacement complet tres risque |
| `dx8Wrap.dll` | 359 exports de type OpenGL ; importe `d3d8.dll` | Non | Peut etre isole dans un profil graphique experimental |
| `il2_core.dll` / `il2_corep4.dll` | 396 exports JNI de rendu, camera, paysages, maillages et textures ; importent `jgl.dll` | Non | Patch binaire cible seulement apres profilage |
| `mg_snd.dll` / `mg_snd_sse.dll` | 115 exports JNI audio ; importent WinMM | Non | Patchable, mais non prioritaire |
| `bin\java.dll` | 238 exports JNI/runtime | Non dans le depot | Ne pas remplacer independamment de la JVM |
| `bin\hotspot\jvm.dll` | 182 exports, HotSpot 1.3.1 | Non dans le depot | Remplacement de JVM fortement deconseille |

L'EXE modifie contient statiquement les options suivantes :

```text
-Xcomp -Xverify:none -Xmx1G -Xincgc
```

Il contient aussi les chemins `bin\java.dll`, `bin\hotspot\jvm.dll` et le nom
`wrapper.dll`. Ces chaines rendent possible la construction d'un profil JVM
experimental, mais ne justifient pas une modification directe du seul EXE
stable.

Le coeur natif complet n'est pas reconstructible depuis les sources presentes.
Le depot contient des outils d'analyse, des stubs Java et des correctifs cibles,
mais pas les sources originales de `il2fb.exe`, `jgl.dll`, `il2_core*.dll` ou
`mg_snd*.dll`.

## Classes Java et archives SFS

### Archive active

Le lecteur en lecture seule `tools/Analyze-Sfs.py` ouvre correctement le
`files.SFS` actif :

| Propriete | Valeur |
|---|---:|
| Version SFS | 202 |
| Entrees de table | 10 441 |
| Taille decompressee annoncee | 69 304 320 octets |
| Blocs compresses | 2 115 |

Trois classes centrales ont ete extraites en memoire avec succes :

| Classe | Taille | Version Java |
|---|---:|---:|
| `com.maddox.il2.engine.Engine` | 6 854 octets | 47 |
| `com.maddox.il2.game.Main` | 14 956 octets | 47 |
| `com.maddox.rts.RTS` | 1 631 octets | 47 |

Cette verification prouve que le code Java central peut etre extrait et analyse.
Elle ne signifie pas que toutes les classes peuvent etre recompilees sans
dependances ou sans adaptation.

### Classes libres

Le dossier `Files` de l'installation de test contient actuellement :

| Mesure | Valeur |
|---|---:|
| Fichiers | 89 741 |
| Dossiers sous `Files` | 4 893 |
| Taille | 16 884 284 065 octets |
| Classes a nom hexadecimal a la racine | 2 440 |
| Classes portant l'extension `.class` | 2 |

Les 2 440 fichiers hexadecimaux ont tous la signature `CAFEBABE` d'une classe
Java. Leur repartition actuelle est :

| Major Java | Classes |
|---:|---:|
| 45 | 705 |
| 46 | 150 |
| 47 | 1 585 |

Aucune classe libre actuelle ne depasse la version 47 acceptee par la JVM 1.3.1.
Ces classes sont donc lisibles par les outils existants et peuvent etre
decompilees, corrigees puis replacees comme surcharges. Toute recompilation doit
rester compatible avec l'API Java 1.3.1, la version de classe 47 au maximum et
les signatures JNI attendues.

### Strategie de modification recommandee

Il n'est pas necessaire de repaqueter `files.SFS` pour la plupart des changements
Java. Le wrapper peut servir une classe libre avant la classe archivee. Cette
voie est plus facile a auditer, a annuler et a comparer par empreinte.

La reconstruction d'un SFS reste techniquement possible avec les outils
communautaires, mais elle exige un test aller-retour, la conservation des entrees
non resolues et un lancement complet dans un clone. Elle n'est pas la premiere
voie recommandee pour optimiser le moteur.

## Autres formats

| Famille | Etat | Usage conseille |
|---|---|---|
| `.ini`, `.properties`, `.eff`, `.mat`, `.mis`, `.txt` | Texte directement lisible | Reglages, effets, registres et missions ; changements faciles a rendre reversibles |
| `.msh`, `.him`, `.sim` | Formats binaires proprietaires | Inspection avec outils communautaires ; ne pas convertir en masse |
| Textures `.tga`, `.tgb`, `.dds` | Lisibles avec outils adaptes | Chercher les conversions et chargements redondants avant de reduire la qualite |
| `Files\gui\GAME\buttons` | Conteneur protege de modeles de vol | Ne pas reconstruire avec un outil destine a 4.10 ou une version ulterieure |
| `.preload` | Texte, 417 directives dont 412 uniques | Modifier seulement apres trace des ressources et comparaison des saccades |

## Observations de performance

### Demarrage

Les mesures deja conservees dans le projet donnent environ 94 a 131 secondes
jusqu'au menu dans les parcours exploitables. Une execution sous forte charge
systeme a atteint 171,5 secondes et ne doit pas servir de reference.

Le banc isole du nouveau wrapper mesure :

| Phase | Temps |
|---|---:|
| Enumeration froide de 89 738 fichiers et creation du cache | 1 890,2 ms |
| Validation du manifeste et chargement du cache | 473,4 ms |
| Gain isole | 1 416,8 ms |

Le cache est donc utile, mais il ne peut pas expliquer a lui seul les 32 a 44
secondes observees avant l'apparition de la fenetre OpenGL, ni les 94 a 131
secondes du demarrage complet. L'attribution historique de tout le premier palier
au wrapper doit etre revalidee avec une trace plus precise.

Dans le journal du 1er septembre, OpenGL est initialise a 05:04:46 et DirectSound
a 05:05:53, soit environ 67 secondes plus tard. Ce palier se situe apres
l'ouverture de la fenetre graphique. Les candidats principaux sont
l'initialisation Java, `-Xcomp`, les classes, les registres et les ressources
prechargees.

### Chargement d'une mission

Le meme journal montre :

| Chargement | Debut | Mission jouable | Duree approximative |
|---|---:|---:|---:|
| Premier | 05:08:29 | 05:08:55 | 26 s |
| Second | 05:11:49 | 05:11:55 | 6 s |

L'ecart d'environ 20 secondes montre un effet important du cache disque, des
ressources deja decodees et/ou des textures deja chargees.

Le journal signale plusieurs rechargements de `skin1o.tga` et `256-1.tga` du
cockpit B-29 avec des ensembles de drapeaux differents. Un dump anterieur a aussi
place le thread principal dans le pilote Intel, sous `opengl32!glTexImage2D`, avec
`il2_corep4!BmpUtils_BMP8PalTo4TGA4` dans la pile. Les conversions de textures et
leur envoi au pilote sur le thread principal sont donc une piste de saccades et
de chargements longs confirmee.

### CPU et memoire

Lors du premier demarrage mesure jusqu'au menu, IL-2 a consomme 86,06 secondes
CPU sur environ 139,58 secondes, soit 61,7 % d'un seul coeur en equivalent
moyen. L'affinite sur quatre coeurs laisse de la place au son et aux services,
mais ne rend pas paralleles les chemins sequentiels de la simulation et du rendu.

Les maxima mesures au menu sont proches de 489 Mio de memoire privee et 1 787
Mio d'espace virtuel. Une capture plus lourde a deja atteint environ 1 598,8 Mio
de memoire privee. Large Address Aware augmente la marge d'adressage sous Windows
64 bits, mais n'accelere pas le processeur. Augmenter `-Xmx1G` sans mesurer
simultanement le tas Java et les allocations natives peut affamer les textures,
les DLL ou le pilote graphique.

## Pistes classees

| Priorite | Piste | Gain vise | Risque | Decision proposee |
|---:|---|---|---|---|
| 1 | Comparer `-Xcomp` au mode mixte | Demarrage | Moyen : compilation Java en mission et micro-saccades | Profil experimental separe, jamais patch unique du profil stable |
| 2 | Mesurer le wrapper cache 4.09m | Environ 1 a 2 s sur l'indexation | Faible a moyen | A/B historique/cache dans le meme environnement |
| 3 | Identifier les conversions et rechargements de textures | Premier chargement et pauses en vol | Moyen | Tracer nom, taille, drapeaux et temps autour de `glTexImage2D` |
| 4 | Profiler les classes Java en mission | IA, effets, recherches d'acteurs, simulation | Moyen | Modifier seulement les methodes mesurees, par surcharge libre |
| 5 | Construire des profils de contenu actif | Demarrage, nombre de fichiers, memoire | Eleve si le graphe est incomplet | Attendre le graphe de dependances avions/cartes/armes |
| 6 | Evaluer un SFS optionnel du mod | Metadonnees et petits fichiers | Eleve | Seulement apres extraction/reconstruction identique et tests |
| 7 | Comparer OpenGL, dgVoodoo2 et DXVK x86 | Compatibilite et eventuellement frametime | Moyen a eleve | OpenGL natif reste la reference |
| 8 | Ajuster `.preload` | Repartition du temps entre demarrage et mission | Moyen | Aucune suppression sans trace d'acces |
| 9 | Comparer quatre coeurs physiques et SMT | Services secondaires, chargement | Faible | Mesurer ; ne pas supposer un gain |
| 10 | Modifier `il2_corep4.dll` ou la JVM | Limites profondes | Tres eleve | Uniquement apres preuve qu'un point natif precis est responsable |

## Protocole propose

Chaque essai futur doit utiliser une copie distincte et ne changer qu'une seule
variable :

1. etablir deux references legeres, froide puis chaude, sans Process Monitor ni
   capture d'images intensive ;
2. conserver resolution, mission, profil graphique et charge systeme identiques ;
3. comparer wrapper historique et wrapper cache ;
4. comparer `-Xcomp` et mode mixte avec deux EXE ou deux profils separes ;
5. mesurer temps au menu, temps de mission, frametime moyen et percentiles,
   temps CPU, memoire privee, espace virtuel, lectures et ecritures ;
6. tracer les textures autour de `BmpUtils` et `glTexImage2D` ;
7. seulement ensuite profiler et modifier les classes Java couteuses ;
8. rejouer une campagne de non-regression apres tout changement Java, SFS,
   graphique ou natif.

Le profil de distribution devra conserver `LOGDEBUG=0` et une journalisation
minimale, tandis que le profil de diagnostic gardera les journaux detailles. Ce
changement devra lui aussi etre mesure : il est logique mais son gain n'est pas
encore quantifie.

## Limites de cette conclusion

- aucun profilage de methodes Java n'a encore identifie les fonctions les plus
  couteuses en vol ;
- la DLL de coeur et la DLL audio effectivement choisies doivent etre journalisees
  a chaque profil, meme si les captures existantes montrent `il2_corep4.dll` ;
- le gain du wrapper cache n'a pas encore ete mesure dans le jeu complet ;
- la memoire maximale doit encore etre mesuree avec grande carte, textures 4K,
  nombreux appareils et longue mission ;
- aucune conclusion de FPS ne peut etre tiree des parcours en 1024 x 768 fenetre ;
- le role complet de `il2_usgs.dll` et `il2_usgs2.dll` reste a etablir.

## Documents lies

- [Architecture statique du moteur](ARCHITECTURE_MOTEUR.md)
- [Performances et wrappers graphiques](PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md)
- [Analyse du wrapper](ANALYSE_WRAPPER_DLL.md)
- [Audit des classes Java](AUDIT_CLASSES_JAVA.md)
- [Audit des binaires x86](AUDIT_BINAIRES_X86.md)
- [Outils de modding et formats](OUTILS_MODDING_IL2_1946.md)
- [Resultats des demarrages du 31 aout 2026](RESULTATS_TESTS_DEMARRAGE_2026-08-31.md)
