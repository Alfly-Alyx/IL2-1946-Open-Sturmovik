# Architecture statique du moteur IL-2 1946 / Open Sturmovik 1.15

## Perimetre

Cette analyse etait statique : aucun executable du jeu ou de l'ancien `_OS_Programs` n'avait alors ete lance. Ces programmes ont depuis ete audites, tries puis repartis entre `_Utilities` et le dossier commun `_Game_Enhancements`. L'installation de reference, maintenant rangee sous `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\resources\IL2\IL 2 Sturmovik 1946`, et les archives de patch de `D:\Documents\##Documents\Informatique\Retro-gaming\Jeux Retro-gaming\Patchs\Patches IL2` avaient seulement ete lues pour cette analyse du moteur.

La cible fonctionnelle de la version 1.15 reste **4.09m**. L'installation de reference contient des composants plus recents et un chargeur de mods ; elle est utile pour comprendre l'architecture, mais ne constitue pas une image stock 4.09m fiable.

## Chaine de demarrage observee

1. `il2fb.exe` cree le processus Windows 32 bits et charge le runtime du jeu sous `bin\java.dll` puis `bin\hotspot\jvm.dll`.
2. L'executable modifie charge `wrapper.dll` et lui delegue l'ouverture des ressources SFS par `__SFS_openf`.
3. Le wrapper indexe les surcharges libres de `mods\` et `files\`, puis renvoie une ressource libre lorsqu'une empreinte IL-2 correspond. En l'absence de surcharge, il rappelle la fonction SFS d'origine de l'executable.
4. Les classes Java pilotent une grande partie du jeu, de l'IA et des objets. Les DLL natives assurent notamment le rendu, le son, les entrees et l'acces aux ressources.
5. `jgl.dll`, fourni par le jeu de base, charge le fournisseur graphique choisi dans `conf.ini`.
6. En OpenGL, le fournisseur est normalement `Opengl32.dll`. En DirectX, `dx8Wrap.dll` traduit l'interface de rendu attendue par IL-2 vers Direct3D 8, puis appelle `d3d8.dll`.

Le nom historique `wrapper.dll` est donc trompeur : ce fichier est ici le **chargeur de mods/SFS**, pas un wrapper graphique. Un futur backend graphique ne devra jamais prendre ce nom.

## Composants natifs

| Composant | Role observe | Remarque 1.15 |
| --- | --- | --- |
| `il2fb.exe` | Demarrage, chargement de la JVM, SFS, JNI et parametrage du processus | Les six EXE modifies sont Large Address Aware, marques `Open Sturmovik`, et repartis en deux variantes de code avec/sans 6DOF |
| `wrapper.dll` | Resolution prioritaire des ressources libres, puis repli SFS | Identique dans les six profils modifies |
| `jgl.dll` | Couche de dispatch du fournisseur de rendu | Doit venir du jeu de base/patch officiel |
| `dx8Wrap.dll` | Traduction du rendu IL-2 vers Direct3D 8 | Ce n'est pas le chargeur de mods |
| `il2_core.dll` | Coeur natif du rendu et pont JNI | Charge les fonctions de `jgl.dll` |
| `il2_corep4.dll` | Variante native optimisee pour Pentium 4 | Le choix exact devra etre trace a l'execution |
| `mg_snd.dll` | Son, WinMM et thread audio | Confirme qu'une partie du moteur est multithreadee |
| `mg_snd_sse.dll` | Variante SSE du moteur audio | Selection a confirmer a l'execution |

## Classes et ressources libres

Le dossier `Files` contient 89 738 fichiers pour 16 879 362 273 octets :

| Zone | Fichiers | Taille |
| --- | ---: | ---: |
| `Files\3do` | 83 619 | 12 351 843 005 octets |
| `Files\Maps` | 1 975 | 4 144 441 806 octets |
| `Files\Samples` | 603 | 334 248 096 octets |
| Autres zones | 3 541 | 48 829 366 octets |

Les 2 435 noms hexadecimaux sans extension situes a la racine de `Files` portent
un en-tete `ClassFile`. Le parseur structurel resout le nom interne de 2 415
d'entre eux dans `com/maddox`, principalement `com/maddox/il2`, sans doublon. Les
20 erreurs de conditionnement restantes sont documentees separement. Avant le
traitement 1.15, les versions d'en-tete se repartissaient ainsi :

| Version de classe Java | Classes |
| ---: | ---: |
| 45 | 706 |
| 46 | 150 |
| 47 | 1 523 |
| 50 | 56 |

Cette coexistence refletait plusieurs generations d'outils de compilation et une
incompatibilite reelle. Le runtime lu dans l'installation de reference est
**Java HotSpot 1.3.1-b24**. Un test isole avec une classe minimale de version 50,
sans lancer IL-2, produit bien `UnsupportedClassVersionError`; cette JVM accepte
la version 47 au maximum.

Le code natif de l'EXE modifie sait dechiffrer certaines classes sans en-tete :
il leur reconstruit explicitement un en-tete `CAFEBABE 0000 002F`, donc une
version 47. En revanche, il transmettait telles quelles les 56 classes libres
ordinaires de version 50. L'audit d'opcodes, d'attributs et d'API Java 1.3.1 a
permis de convertir 55 en ne changeant que le major. `BF_109F4` a en plus recu
le remplacement compatible `StringBuilder` vers `StringBuffer`. Les 56 sont
maintenant en version 47 et passent les validations structurelles ; leur essai
fonctionnel dans une mission reste a faire.

Les registres principaux visibles sont `Files\com\maddox\il2\objects\air.ini`, `stationary.ini`, `ships.ini`, `technics.ini` et `Files\Maps\all.ini`. Ils determinent une part importante du contenu active et devront etre croises avec les classes, modeles, armes et cartes lors de la construction du graphe de dependances.

## Memoire et processeur

Le moteur reste un programme x86 32 bits. Le drapeau Large Address Aware augmente son espace d'adressage potentiel, mais ne le transforme ni en 64 bits ni en moteur parallele moderne. L'EXE modifie lance la JVM avec `-Xcomp`, `-Xverify:none`, `-Xmx1G` et `-Xincgc`. Le reste de l'espace virtuel doit rester disponible pour le code natif, les DLL, textures, sons et cartes.

Le code source d'un Selector communautaire plus recent montre qu'une couche
`dinput` peut reconstruire les arguments JVM au lancement. Cette architecture
permettrait d'essayer plusieurs budgets memoire sans modifier l'EXE stable. Elle
n'est pas necessaire au wrapper cache maintenant porte, mais restera necessaire
pour des profils JVM dynamiques et devra etre etudiee separement.

Le selecteur remplace maintenant le masque modele par une valeur calculee : au plus quatre coeurs physiques, un fil par coeur lorsque la topologie SMT est reguliere, et repli sur 15 lorsque la topologie n'est pas lisible. Le fonctionnement des threads de rendu, de simulation, de son et de chargement devra etre mesure pendant une future session de jeu avant de changer le tas ou les priorites.

## Points restant a confirmer a l'execution

- DLL de coeur et DLL audio reellement selectionnees ;
- ordre exact et temps de montage de chaque SFS ;
- gain reel du wrapper cache face a l'indexation des 89 738 fichiers libres ;
- classes et ressources chargees au demarrage, au menu et par mission ;
- comportement des 56 classes traitees en version 47 dans les appareils concernes ;
- occupation du tas Java, memoire native et espace d'adressage ;
- repartition des threads sur les coeurs physiques ;
- fournisseur graphique, version OpenGL/Vulkan et chemin de rendu reellement actifs ;
- erreurs de ressources, exceptions Java, recompilations de shaders et acces disque repetes.
