# Resultats des premiers demarrages instrumentes

Date des mesures : 30 aout 2026. La copie de test est issue de la base DVD
4.07m reconstruite, completee par les fichiers officiels jusqu'a 4.09m et par
le contenu de l'add-on. Les essais utilisent OpenGL natif, une fenetre
1024 x 768 et le profil graphique x86 securise.

> Ce document conserve les observations du test telles qu'elles ont ete faites.
> Depuis, les correctifs statiques WheelTire, Zuti, registres Plane/chief, sons,
> introduction et TBM-1 ont ete prepares. Leur etat courant est suivi dans
> [ETAT_REPRISE_V1.15.md](ETAT_REPRISE_V1.15.md) et doit etre confirme par une
> nouvelle capture avant que les anomalies ci-dessous soient declarees fermees.

## Conclusion principale

La base officielle 4.09m atteint le menu normalement. Les erreurs et la majeure
partie du temps de demarrage supplementaire sont introduites par le profil
modifie : EXE modifie, `files.SFS` modifie, `wrapper.dll` et fichiers libres.
Une reinstallation du jeu n'est donc pas justifiee par ces resultats.

## Comparaison directe a chaud

| Mesure | Profil 9 modifie | Profil 7 stock |
|---|---:|---:|
| Detection du processus | 18:21:36 | 18:27:56 |
| Debut du journal moteur | 18:21:52 | 18:28:00 |
| Debut de `Records/Intro 04 Ed.trk` | 18:22:47 | 18:28:07 |
| Marqueur de fin de l'introduction | 18:23:55 | 18:28:20 |
| Processus conserve pour la mesure | 169,4 s | 37,5 s |
| Memoire physique maximale | 548,7 Mio | 335,7 Mio |
| Memoire privee maximale | 563,7 Mio | 350,2 Mio |
| Lignes du journal moteur | 997 | 67 |

Les durees totales comprennent les secondes laissees au menu avant la fermeture.
Les horodatages internes donnent une comparaison plus precise du demarrage :

- processus vers introduction : environ 71 secondes avec le mod contre
  11 secondes en stock, soit 60 secondes supplementaires avant la mission de
  demonstration ;
- introduction vers son marqueur final : environ 68 secondes avec le mod contre
  13 secondes en stock, soit 55 secondes supplementaires dans la demonstration ;
- processus vers marqueur de menu : environ 139 secondes avec le mod contre
  24 secondes en stock.

Le surcout se partage donc entre l'initialisation du chargeur/contenu modifie et
le chargement de la mission de demonstration avec l'ensemble etendu des objets.

## Erreurs reproductibles du profil modifie

| Famille | Profil 9 modifie | Profil 7 stock |
|---|---:|---:|
| Valeurs de configuration plafonnees | 63 | 0 journalisee |
| Classes d'appareils sans spawner | 17 | 0 |
| `FileNotFoundException` | 28 | 0 |
| Presets ou pools sonores invalides | 32 | 0 |
| Erreurs `NetAircraft` | 13 | 0 |
| Types de navires incorrects | 6 | 0 |
| Echec de prechargement de ressource | 1 | 0 |
| `ClassCastException` Zuti | periodique | 0 |

Le nombre de `ClassCastException` depend du temps passe au menu :
`ZutiTimer_ExtendPlanesWings` la relance environ toutes les deux a trois
secondes. Ce defaut doit etre corrige avant un essai de mission.

Les autres defauts confirmes comprennent :

- `3DO/Plane/Bf-109G-2/WheelTire.mat` invalide ou absent ;
- `samples/Allison_XX_Starter.wav`, `samples/mg__ffe.wav` et
  `samples/mg__ffi.wav` introuvables ;
- plusieurs presets de demarrage DB-600, Merlin, Sabre et Sakae invalides ;
- des appareils D.XXI, I-15, I-16, G.55, RE.2000, Letov S-328, SM.79 et autres
  declares sans spawner disponible ;
- plusieurs navires utilises par la demonstration sont bien declares dans
  `ships.ini` et `stationary.ini`, et leurs classes Java version 47 existent,
  mais le moteur ne les reconnait pas comme types de chief au moment de creer
  la mission.

## Rendu graphique

OpenGL natif fonctionne avec l'Intel UHD Graphics 620 et expose OpenGL 4.6, une
taille de texture maximale de 16 384 et un filtrage anisotrope 16x. Le detecteur
historique d'IL-2 refuse pourtant le mode `Perfect`, car il cherche notamment
les anciennes extensions NVIDIA `GL_NV_texture_shader`. Le jeu reecrit alors
`HardwareShaders=0` et `Forest=0` dans `conf.ini`. Le lanceur doit distinguer la
capacite reelle du GPU de la detection obsolete du moteur et ne pas restaurer
indefiniment des options que le moteur desactive.

## Limites de cette mesure

Process Monitor n'a pas pu etre utilise dans cette session et la politique
Windows a refuse le profil noyau WPR. Les mesures conservent les images, les
modules, le CPU, la memoire, les threads, les compteurs disque, les journaux IL-2
et les evenements Windows. Une trace precise des chemins ouverts devra etre
refaite apres resolution de l'armement Process Monitor.

## Prochain essai recommande

Revenir au profil 9 et desactiver uniquement la lecture automatique de
`Records/Intro 04 Ed.trk`. Ce test separera le cout permanent du wrapper et de
l'indexation des fichiers libres du cout de la mission de demonstration. Aucun
essai de mission jouable ne doit preceder la correction de l'exception Zuti et
des incoherences de registres mises en evidence ci-dessus.

## Passage Selector 5.1.2 avec Dump SFS

Le clone independant `IL 2 Sturmovik 1946 Selector Dump` a ete lance avec le
profil 8, 4.09m modifie sans 6DOF. Selector utilisait le mode Classic Mod Game,
un tas de 1 024 Mio, aucun cache de liste preexistant et `DumpMode=3` avec
`InstantDump=1`.

### Resultat fonctionnel

Le jeu a charge jusqu'au menu principal. L'utilisateur l'a ensuite ferme. Il
n'existe aucun evenement de plantage IL-2, Java ou Windows dans le journal
d'applications de cette session. La valeur de code de sortie absente dans le
resume provient de la disparition du processus avant la derniere actualisation
de l'objet de mesure ; elle ne constitue pas un plantage.

Le processus a vecu 209,9 secondes. Le menu apparait sur l'image horodatee a
178,9 secondes, puis reste affiche pendant environ 30 secondes. La description
du processus visible dans le Gestionnaire des taches mentionne 6DOF/TIR, mais
elle appartient a l'executable generique de Selector ; le profil selectionne
pour ce passage reste bien le profil 8 sans 6DOF.

### Chronologie observee

| Temps depuis le processus | Observation |
|---:|---|
| 1,1 s | chargement de `DINPUT.dll` de Selector |
| 1,2 s | chargement de la JVM |
| 1,7 s | chargement de `wrapper.dll` |
| 10,3 s | chargement de `jgl.dll` |
| 55,7 s | chargement d'OpenGL et apparition de la fenetre |
| 64,4 a 155,7 s | fenetre signalee sans reponse pendant le traitement intensif |
| 155,4 s | `Chargement de l'enregistrement` |
| 157,6 a 164,3 s | `0 % Chargement du paysage` |
| 166,5 s | `30 % Chargement des avions` |
| 168,8 a 171,0 s | `38 % Chargement des avions` |
| 173,3 s | `45 % Chargement des avions` |
| 175,5 s | debut visible de la scene d'introduction |
| 178,9 s | menu principal |

Les valeurs visibles ne decrivent pas uniquement le demarrage du moteur. Le
`conf.ini` contient `Intro=1` et `eventlog.lst` confirme la lecture automatique
de `Records/Intro 04 Ed.trk`. Les pourcentages paysage/avions correspondent donc
au chargement de cette mission de demonstration. Les paliers intermediaires ont
pu etre trop brefs pour etre presents dans l'echantillonnage d'images.

### Memoire et charge

| Mesure | Valeur |
|---|---:|
| CPU cumule du processus | 121,8 s |
| CPU moyen rapporte au temps reel | 0,58 coeur logique |
| Memoire physique maximale | 907,2 Mio |
| Memoire privee maximale | 1 598,8 Mio |
| Espace virtuel maximal | 1 902,6 Mio |
| Threads maximum | 27 |
| Handles maximum | 832 |

Ces valeurs incluent le surcout du Dump, l'ecriture de la trace Process Monitor
et une machine deja chargee. Elles ne doivent pas servir de configuration
minimale ni de temps de demarrage normal. Elles montrent cependant que ce
parcours reste sous la limite d'adressage x86, avec une marge encore a mesurer
sur une vraie mission utilisant les textures les plus lourdes.

Le fichier CSV des mesures a revele une erreur de notre capteur : la virgule
decimale francaise du temps CPU decalait les colonnes. Les valeurs ci-dessus ont
ete recalculees depuis les lignes brutes et le capteur ecrit desormais ce champ
avec la culture invariante.

### Ressources SFS observees

Selector a copie 10 201 fichiers, 604,2 Mio au total :

| Racine | Fichiers | Volume |
|---|---:|---:|
| `3DO` | 1 592 | 317,1 Mio |
| `samples` | 429 | 178,0 Mio |
| `maps` | 116 | 72,5 Mio |
| `com` | 6 163 | 23,0 Mio |
| `gui` | 69 | 5,9 Mio |
| `Effects` | 177 | 2,9 Mio |
| `missions` | 4 | 2,3 Mio |

La trace Process Monitor est disponible en deux segments totalisant environ
4,66 Go. Son export complet serait inutilement couteux ; il devra etre filtre
sur le PID 12844 et les operations de fichiers avant analyse.

### Anomalies confirmees par ce passage

- 63 valeurs de fichiers d'effets depassent les limites du moteur et sont
  bridees par `Str2FloatClamp` ; elles proviennent de ressources `.eff` et non
  du profil graphique ;
- `Files/3do/Plane/Bf-109G-2/WheelTire.mat` fait 216 octets tous nuls. La copie
  Dumpee est identique et provoque l'echec de prechargement du `hier.him` ;
- 17 appareils declares produisent `No spawner`. Leurs classes principales et
  leurs classes `Plane$...` version 47 existent, et les noms figurent dans
  `air.ini` et `stationary.ini` : le probleme est donc une incoherence de
  chargement/enregistrement, pas une simple absence de fichier ;
- six navires produisent `Wrong chief's type`. Leurs sections `ships.ini`,
  lignes `stationary.ini` et classes `Ship$...` version 47 existent egalement ;
- 28 `SectFile load failed` accompagnes de `FileNotFoundException` doivent etre
  rattaches au chemin nul demande par les caches de peinture, la demonstration
  et `GUIBWDemoPlay` ;
- six presets de demarrage DB-600, Merlin et Sabre sont declares dans un format
  refuse ; les pools Sakae et Pratt & Whitney R-2800 echouent egalement ;
- l'inventaire trouve 26 noms de presets `.prs` dupliques et 24 conflits de
  contenu entre `Files/presets` et `Files/presets/sounds`. Un ancien pack de
  compatibilite SAS Buttons avertit precisement contre ces definitions
  multiples ;
- `samples/Allison_XX_Starter.wav`, `samples/mg__ffe.wav` et
  `samples/mg__ffi.wav` sont references par des presets, mais absents de tous
  les dossiers libres et du Dump ;
- `ZutiTimer_ExtendPlanesWings` relance une `ClassCastException` environ toutes
  les trois secondes ;
- treize `NetAircraft error, ID_03: java.io.EOFException` apparaissent pendant
  l'introduction ;
- la piste d'introduction produit une `NumberFormatException` dans
  `Main3D.loadRecordedStates2` et demande six types de navires non instancies ;
- le profil demande un rendu que le detecteur historique refuse sur l'Intel UHD
  620 : OpenGL fonctionne, mais le mode `Perfect` NVIDIA ne doit pas etre force
  sur ce GPU.

Ces erreurs n'ont pas empeche l'acces au menu. Elles restent toutes incompatibles
avec le critere de sortie sans anomalie connue de la v1.15.
