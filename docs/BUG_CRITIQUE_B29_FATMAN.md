# Gel critique au largage de la Fat Man depuis le B-29 Silverplate

Derniere mise a jour : 1er septembre 2026.

## Etat du diagnostic

Le defaut a ete **reproduit deux fois, explique et neutralise par un essai A/B**.
Le correctif candidat v1.15 est maintenant integre au depot et au dossier de
test. Il fusionne l'API nucleaire Silverplate avec les ajouts Zuti au lieu de
conserver la famille Silverplate utilisee temporairement pendant le diagnostic.

L'essai A/B avec la classe `BombGun` officielle 4.09m reproduit le gel : la
surcharge `semi-realDropBomb v2.0` n'est donc pas la cause primaire. L'analyse du
bytecode a revele une incompatibilite binaire certaine entre la classe `Bomb`
livree par Silverplate et la classe globale `Explosions` livree par Open
Sturmovik. Le premier appel a l'explosion de la Fat Man ne peut pas etre resolu
et produit un `NoSuchMethodError`. Le second A/B reversible avec la famille
`Explosions` coherente a permis le largage, l'impact, plusieurs minutes de vol,
le retour au menu et l'arret normal. Cette validation confirme la cause. Le
correctif final doit maintenant fusionner l'API nucleaire avec les ajouts Zuti.

## Scenario reproductible

| Parametre | Valeur observee |
| --- | --- |
| Profil | 9, 4.09m modde, libelle historique 6DOF |
| Avion | Boeing B-29 Silverplate, 1944 |
| Emport | `FatMan` |
| Carte | Smolensk |
| Altitude QMB | 10 000 m |
| Commande | `Weapon3`, `Ctrl+B` |
| Mode video | OpenGL natif, fenetre 1024 x 768 |
| Affinite | masque `85`, un fil sur chacun des quatre coeurs physiques |

Artefacts :

`test-results/startup/20260831-152135Z-profile9-warm-windowed1024-startup`

La derniere image encore animee precede 15:25:43,257 UTC. A partir de cette
image, 56 captures successives restent identiques pendant environ six secondes.
Le titre `Ne repond pas` apparait ensuite, puis la boite Windows proposant de
fermer le programme ou d'attendre. L'evenement Windows 1002 identifie un
`AppHangB1` ; ce n'est donc pas un simple ralentissement d'affichage.

Le dump complet produit par ProcDump mesure 862 461 129 octets :

`process-dumps/il2fb.exe_260831_172548.dmp`

SHA-256 :

`58F49621939843B7F0A5EFF704F68C1DDE477F5E3073F3CE793DACE1935AB4CC`

Le controle A/B avec `BombGun` officielle 4.09m est conserve dans :

`test-results/startup/20260831-164731Z-profile9-warm-windowed1024-startup`

Son dump complet mesure 857 177 177 octets :

`process-dumps/il2fb.exe_260831_194117.dmp`

SHA-256 :

`5961FD46E6B46499659A60140D1BD19D5B9EC7F28CC38DCACE505B770D8DE825`

Le processus reste continuellement `Responding=False` de
17:41:16,197 UTC jusqu'a sa fermeture, pendant 138,81 secondes. Il ne consomme
que 796,88 ms de CPU supplementaire et sa memoire privee reste stable a environ
681,48 Mio : il attend, il ne calcule pas et n'epuise aucune ressource.

## Ce que le dump prouve

La pile native du fil principal termine dans `DestroyJavaVM` :

`ntdll!ZwWaitForSingleObject -> KERNELBASE!WaitForSingleObject -> jvm.dll -> il2fb.exe`

Dans **les deux dumps**, la JVM HotSpot 1.3.1 attend un evenement sans limite
parce qu'il reste deux fils
Java non daemon : `main` et un `java/util/TimerThread`. Le minuteur contient une
seule tache active :

`com/maddox/il2/game/ZutiTimer_RadarsCountRefresh`

Sa periode vaut `-2000` ms, representation interne d'une execution repetee a
delai fixe. Cette tache Zuti explique pourquoi le processus ne termine pas apres
la sortie anormale de la boucle principale ; elle n'explique pas, a elle seule,
pourquoi le largage a fait sortir cette boucle. Le correctif devra donc traiter
separement le declencheur de largage et le cycle de vie du minuteur Zuti.

Les outils reproductibles sont :

- `tools/Analyze-IL2Minidump.py` pour le dump, les modules et les piles x86 ;
- `tools/Analyze-IL2HotSpot131.py` pour les fils et minuteurs HotSpot 1.3.1 ;
- `tools/Inspect-IL2HotSpotObject.py` pour l'inspection ciblee d'un objet du tas.

## Ce que les ressources excluent

Au dernier instant anime, IL-2 utilise environ 665,83 Mio de working set,
682,55 Mio de memoire privee et 1 968,37 Mio d'espace virtuel. Le maximum de
memoire privee observe sur tout l'essai est 708,17 Mio. La hausse du working set
jusqu'a 824,17 Mio intervient pendant la prise du dump. Le PC conserve environ
19 Gio de RAM disponible ; le disque n'est occupe en moyenne qu'a 1,31 % et le
GPU 3D atteint au plus 78,39 %.

L'essai n'a donc atteint ni le plafond x86, ni la RAM physique, ni le disque, ni
le GPU. Le processeur du jeu cesse presque totalement d'avancer lorsque la
boucle Java principale sort. Augmenter la memoire ou changer de wrapper
graphique ne corrigera pas ce defaut logique.

## Comparaison avec le paquet communautaire d'origine

Le paquet **Boeing B-29 Silverplate Atomic Bomber v1.2** a ete telecharge depuis
le lien conserve par son [fil SAS d'origine](https://www.sas1946.com/main/index.php?topic=7894.0).
Une copie de reference est archivee hors du jeu dans :

`D:\Projets\GITHUB\res\IL2 1946\Mods\B29 Silverplate v1.2\silverplate.7z`

Taille : 13 196 771 octets. SHA-256 :

`18CC06BEE46804B481A2072E9B70B3152E09E0B40AE8788384739E8F41A0527A`

Les trois classes directement liees a la Fat Man dans Open Sturmovik sont
identiques octet pour octet a ce paquet :

| Classe | Fichier libre | Taille | SHA-256 |
| --- | --- | ---: | --- |
| `BombFatMan` | `830E5C5AC3A1C77A` | 2 127 | `515DCE7B2FE6B555F9F56FC7EA1DFB96C33EBE6F370CCD8FD149FD6FB1C3CA6C` |
| `BombGunFatMan` | `46168B5EEE532404` | 1 376 | `8B5AC1B92495BF01811628796E1899F326ABC613B5E3243004A4BF492ED40868` |
| `Bomb` | `1E8A600CBE71D698` | 12 475 | `43420376EE821F297435087DC8032F9936D8AC6A7AEAAC290C968A737AE2C8B6` |

Le paquet Silverplate ne surcharge toutefois **pas** la classe de base
`com.maddox.il2.objects.weapons.BombGun`. Open Sturmovik la remplace globalement
par `Files/ED31205CA2346688`, taille 9 931 octets, SHA-256
`08F959473BF6649E49685D4FF4C7C7D132FABBCC4B5AF94BF5C338A0F4C02FC9`.
Le bytecode affiche explicitement la signature de
`ZloyPetrushkO's and SJack's semi-realDropBomb mod v2.0`.

Cette surcharge fait passer `interpolateStep()` de 195 a 892 octets et ajoute,
pour chaque largage du joueur, la recherche du parent du crochet dans le
`HierMesh`, des casts et controles propres a plusieurs familles d'avions, ainsi
que des dommages moteur en fonction de l'assiette. Ce chemin supplementaire est
execute avant et apres `Bomb.start()` et constituait le premier candidat a
controler par rapport au chemin 4.09m officiel.

La classe officielle a ete extraite en lecture seule du `files.SFS` du patch
4.09m fourni par Alexis :

| Element | SHA-256 |
| --- | --- |
| `client-4.09.exe` | `1ECC6661B132B38974044CEB13EA64436CCEC3C3D67F85843F02F8E48F3AE45F` |
| `files.SFS` 4.09m | `9F7D136C586EB3FCD258C5C000F34951D410A0236934F22ABA2516637874B095` |
| `BombGun.class` officielle | `2C0007C200CE7F721AC236124E24E3D073CEE465951BC8CD2F31BCDB2AD0E626` |

Le meme gel avec cette classe officielle elimine `BombGun` comme cause primaire.
La version semi-realDropBomb a donc ete restauree dans le dossier de test, avec
son empreinte originale verifiee.

## Incompatibilite binaire Silverplate/Zuti prouvee

La classe `Bomb` de Silverplate appelle dans `doExplosion()` la methode statique
suivante :

`Explosions.generate(Actor, Point3d, float, int, float, int)`

Son descripteur JVM exact est :

`(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V`

La classe active `Files/72DCDDF4D2AD25E8` ne fournit que la variante a cinq
parametres `(Actor, Point3d, float, int, float)`. Elle contient les ajouts Zuti
de multiplicateur de visibilite des crateres, mais elle a perdu la surcharge a
six parametres dont Silverplate se sert pour transmettre le type d'explosion
nucleaire. La JVM ne peut pas fusionner les API de deux versions d'une meme
classe : au premier appel, la resolution symbolique echoue par
`NoSuchMethodError`.

| Variante `Explosions` | Taille | SHA-256 | Surcharge nucleaire |
| --- | ---: | --- | --- |
| Active Open Sturmovik/Zuti | 25 836 | `2F66A5AA35C0DF6D29D44DA27FC71DDEF1198F05B9974D92DE11B22F14926F91` | absente |
| Silverplate v1.2 | 25 703 | `4749790F3DD6CA95E6FC81930B866A83531F735F4DC6161D6C99921A8811B1A9` | presente |

L'inventaire des 35 classes Java du paquet Silverplate montre aussi que sa
classe `B_29X` n'est pas presente dans `Files` : le jeu charge donc la version
officielle 4.09m depuis SFS. Ce decalage doit etre audite, mais il n'est pas
necessaire pour expliquer l'appel impossible ci-dessus.

Le [fil SAS, page 9](https://www.sas1946.com/main/index.php?topic=7894.96)
contient un signalement independant : le jeu s'arrete uniquement avec Fat Man
ou Little Boy, alors que `default` et `empty` fonctionnent. Le fil ne fournit
pas de correction confirmee, mais il etablit que la famille de panne est
ancienne et specifique aux emports atomiques. Une autre discussion SAS signale
aussi une [incompatibilite entre le B-29 Silverplate et un autre mod d'explosion](https://www.sas1946.com/main/index.php?topic=9213.0),
ce qui renforce l'obligation d'auditer les surcharges globales plutot que de
remplacer aveuglement les classes de la bombe.

## Validation A/B reussie

Artefacts :

`test-results/startup/20260831-184314Z-profile9-warm-windowed1024-startup`

La famille complete de 15 classes `Explosions` du paquet Silverplate a ete
activee dans le seul dossier de test, avec `semi-realDropBomb v2.0` restaure. Le
meme B-29, le meme emport `FatMan` et la meme mission Smolensk ont alors produit :

- largage sans gel ;
- impact confirme par le message en jeu et trois objets statiques detruits dans
  `eventlog.lst` a `12:00:54` ;
- aucun echantillon `Responding=False` apres l'armement du largage ;
- aucun dump, aucune exception non geree et plusieurs minutes de vol stable ;
- `Radars count refreshing stopped!` avant la fin normale du journal, ce qui
  confirme aussi l'arret propre du minuteur Zuti lorsque la boucle principale
  se termine normalement.

Autour de l'impact observe vers 18:50:33 UTC, le processus reste stable entre
663 et 667 Mio de working set, 680 et 684 Mio de memoire privee et 1 967 Mio
d'espace virtuel. Le GPU 3D IL-2 atteint 50,67 %, sa memoire partagee 172,56 Mio
et le disque 3,63 % au maximum sur la fenetre de 17 secondes. Le PC est charge
(CPU systeme moyen 91,20 %), mais la panne ne reapparait pas.

La capture montre le message russe « coup direct, cible detruite » et le journal
confirme les destructions. Elle ne montre toutefois pas clairement un panache
nucleaire complet : la validation visuelle des effets reste donc un essai
distinct de la correction de liaison Java.

## Validation croisee Little Boy/Fat Man et anomalie de pause

Artefacts :

`test-results/startup/20260831-192529Z-profile9-warm-windowed1024-startup`

Les deux emports atomiques declares par `B_29SP` ont ete controles dans le meme
lancement instrumente. Alexis a confirme qu'il n'existe pas de troisieme bombe
atomique dans ce paquet.

- `LittleBoy` atteint le sol sans gel et detruit trois objets statiques a
  `12:00:40` ;
- `FatMan` atteint le sol sans gel et detruit trois objets statiques a
  `12:01:13` ;
- le processus reste repondant apres les deux impacts ;
- mettre le jeu en pause pendant la sequence, puis reprendre, laisse des masses
  ressemblant a des nuages et une petite explosion conventionnelle au lieu d'un
  panache nucleaire complet ;
- le meme comportement avec les deux bombes designe leur chemin commun
  `Bomb`/`Explosions`, et non leur maillage individuel.

Le bytecode explique une partie visible du resultat. `BombLittleBoy` et
`BombFatMan` declarent tous deux `newEffect=1`, `nuke=1` et `radius=3200`. Leur
puissance vaut respectivement `8 000 000` et `13 000 000`. `Bomb.doExplosion()`
transmet `nuke` a `MsgExplosion.send`, mais transmet `newEffect` comme sixieme
argument de `Explosions.generate`. Pour `newEffect=1`, la famille Silverplate
appelle la meme routine `bombFatMan_land` ou `bombFatMan_water` pour les deux
bombes. Dans la branche ou la cible n'est pas `ActorLand`, elle appelle ensuite
explicitement `bomb50_land(point3d, -1.0f, 10.0f)`. La petite explosion n'est
donc pas necessairement un repli provoque par un fichier absent : elle existe
dans le code historique.

La routine nucleaire cree six `Eff3DActor` : `shock`, `buff`, `circle` ou
`circleL`, `column`, `flare` et `ring`. Les fichiers `.eff` combinent des
`FinishTime` de 1 a 30 secondes avec des `LiveTime` de 1, 200, 400 ou 99 999
secondes, tandis que cinq acteurs sont crees avec une duree `-1`. Ces valeurs
heterogenes rendent plausible une desynchronisation entre temps de simulation
et temps des particules lors de la pause. Cette causalite devra etre confirmee
par un controle identique sans aucune pause avant de modifier les effets.

### Exigence de souffle nucleaire realiste

Alexis a valide l'integration d'un modele plus realiste. Le test a 5 000 m
d'altitude n'a produit ni souffle, ni secousse, ni degat sur le B-29. Le rayon
actuel de 3 200 m exclut deja l'appareil sur la seule distance verticale et le
moteur applique les destructions immediatement, sans onde retardee.

Le correctif candidat conserve des puissances distinctes pour les deux bombes
et applique des zones progressives calculees sur la distance 3D : surpression,
souffle, secousse et dommages adaptes au type d'acteur. L'onde arrive apres un
delai coherent avec sa propagation ; a 5 km, le cas de reference doit produire
environ quinze secondes plus tard un effet perceptible sans detruire
automatiquement un bombardier lourd. Le calcul regroupe les acteurs touches et
borne son cout pour ne pas transformer une explosion en gel du moteur 32 bits.
Le flash thermique, les brulures et le rayonnement restent un chantier separe.

### Correctif v1.15 construit, validation en jeu encore requise

Le constructeur reproductible `tools/Build-OpenSturmovikNuclearPatch.ps1`
produit maintenant douze classes Java en version majeure 47. Il fusionne la
surcharge nucleaire Silverplate dans la classe externe Zuti, sans remplacer les
classes internes Zuti. Il retire uniquement l'appel `bomb50_land(..., 10.0f)`
de la branche nucleaire et conserve les appels conventionnels de meme forme
dans les autres branches.

Les proprietes sont desormais distinctes et historiquement ancrees : Little Boy
utilise 15 kt, 4 400 kg et une explosion a 600 m au-dessus du terrain ; Fat Man
utilise 21 kt, 4 670 kg et 503 m. Ces valeurs suivent la chronologie du
[National Park Service](https://home.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm)
et l'histoire du projet Manhattan publiee par le
[Department of Energy](https://www.energy.gov/sites/default/files/maprod/documents/DE99001330.pdf).
Little Boy emploie une echelle visuelle `0,894`, racine cubique de `15/21`, par
rapport a Fat Man. Aucun cratere n'est cree pour ces explosions aeriennes.

La table de planification HHS pour une explosion de 10 kt fournit les rayons
de 20, 10, 5 et 2 psi : 480, 710, 970 et 1 800 m. Le modele les adapte au
rendement par la loi en racine cubique decrite dans la litterature d'airblast
et utilise la geometrie de l'explosion aerienne. Les rayons de degats IL-2
deviennent donc 2 150 m pour Little Boy et 2 360 m pour Fat Man, ce qui place
leur intersection avec le sol a environ 2 065 et 2 306 m. Sources :
[HHS REMM Planning Guidance](https://remm.hhs.gov/PlanningGuidanceNuclearDetonation.pdf)
et [rapport de mise a l'echelle OSTI](https://www.osti.gov/servlets/purl/4114321-vb7jLn/).

`MsgExplosion` ne distribue plus le dommage nucleaire immediatement. Une seule
recherche spatiale couvre la zone utile, puis chaque acteur recoit le message de
degat apres `distance / 343` secondes sur l'horloge de simulation. Une pause
suspend donc aussi l'arrivee de l'onde. La fonction IL-2 normale en inverse du
carre est restauree ; l'ancien test `bNuke`, qui accordait la puissance totale a
tout acteur situe dans les 3 200 m, est supprime.

La distance est echantillonnee au moment de la detonation. La direction de
l'impulsion est recalculee a son arrivee depuis la position courante de l'avion,
mais le temps d'interception n'est pas corrige en continu pour le deplacement de
la cible. Ce compromis reste acceptable pour le candidat stable ; une future
onde mobile pourra recalculer l'intersection avion/front si les essais montrent
un ecart perceptible, avec un cout CPU mesure et borne.

Les avions situes au-dela du rayon de degats, mais dans la zone exterieure
modelee jusqu'a 0,5 psi, recoivent seulement une impulsion radiale bornee. Pour
le cas vertical Little Boy, un B-29 a 5 000 m se trouve a environ 4 400 m du
point d'explosion : le modele prevoit environ 0,68 psi, une impulsion de
1,73 m/s et une arrivee apres 12,83 s, sans dommage automatique. Les noeuds 1 et
0,5 psi et la conversion de pression en impulsion d'avion sont des
approximations de simulation explicitement documentees ; ils ne sont pas
presentes comme des mesures historiques.

Ce correctif ne simule pas encore les brulures thermiques ni le rayonnement
ionisant. Le flash reste visuel. La fidelite de la sequence de particules,
notamment apres pause, doit encore etre jugee en jeu. Le manifeste complet,
les empreintes et les limites sont conserves dans
`manifests/effects/nuclear-blast-v1.15.json`.

## Etat du dossier de test

Le candidat fusionne est present dans le depot et dans le seul dossier de test.
La classe externe `Explosions`, ses classes internes Zuti, `Explosion`,
`MsgExplosion`, les deux bombes et les cinq nouvelles classes `NuclearBlast`
forment maintenant un ensemble coherent. La classe semi-realDropBomb reste
active dans `Files/ED31205CA2346688`, SHA-256
`08F959473BF6649E49685D4FF4C7C7D132FABBCC4B5AF94BF5C338A0F4C02FC9`.

Les 19 fichiers de test remplaces ont ete sauvegardes avant de copier les 24
fichiers de la famille complete dans :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test\Open-Sturmovik-backups\nuclear-v1.15-before-20260831-210614Z`

Les 24 copies ont ete verifiees par SHA-256. Le controle de contenu obtient
16 PASS, un WARN attendu faute de dump runtime recent et zero FAIL. Les 46
controles de preparation du profil 9 sont valides. Aucun essai en jeu n'a encore
ete effectue avec ce candidat.

### Premier essai du candidat : erreur d'ABI de la secousse identifiee

L'essai `20260831-222423Z-profile9-warm-windowed1024-startup` a declenche Little
Boy depuis le B-29. La chute reste stable. Le panache est visible vers
22:31:22 UTC, puis le processus passe definitivement a `Responding=False` a
22:31:34, environ douze a treize secondes apres le debut de l'explosion. Le
dump automatique et le dump manuel montrent la boucle Java principale sortie,
la JVM en attente de terminaison et le minuteur non daemon
`ZutiTimer_RadarsCountRefresh` encore actif. La memoire reste stable a environ
680 Mio prives et 1,97 Gio virtuels : ce n'est pas un epuisement x86.

Le delai correspond exactement a l'arrivee programmee de la secousse sur le
B-29. L'audit des references binaires a trouve la cause : le stub de compilation
declarait `Vector3d.add(Vector3d)`, alors que l'API reelle 4.09m declare la
methode heritee `Tuple3d.add(Tuple3d)`. L'appel differe produisait donc un
`NoSuchMethodError` au moment de la secousse. Les stubs reproduisent desormais
l'heritage reel `Point3d/Vector3d -> Tuple3d`, et le constructeur refuse toute
regression vers l'ancien descripteur. Un nouvel essai sans pause reste requis.

La pause/reprise reduit toujours le panache, mais moins fortement que dans le
paquet Silverplate non fusionne. Ce defaut visuel est distinct de l'erreur ABI
et reste a traiter apres la validation de la secousse corrigee.

### Validation en jeu de l'ABI corrigee

La session instrumentee
`20260901-050213Z-profile9-warm-windowed1024-startup` valide le nouvel appel
`Tuple3d.add(Tuple3d)` dans la JVM 4.09m reelle. Little Boy a ete largue deux
fois depuis le B-29 Silverplate. Le second largage, realise sans aucune pause,
produit le flash vers 05:12:40 UTC, le nuage a partir de 05:12:42 et un panache
encore visible au moins jusqu'a 05:13:50. Le processus reste repondant pendant
toute cette sequence et se termine ensuite volontairement avec le code zero.
ProcDump ne produit aucun dump et le journal ne contient ni `NoSuchMethodError`
ni autre exception Java. Le gel differe d'environ treize secondes est donc
corrige pour ce scenario.

Le premier largage fournit en parallele une reproduction propre du defaut de
pause : le bord du nuage apparait vers 05:10:10, le menu de pause est affiche
vers 05:10:13-05:10:14, puis le nuage a disparu des la reprise vers 05:10:15,
alors que le point de vue est reste comparable. Sans pause, le panache persiste
plus d'une minute. Le cycle de vie visuel est donc bien sensible a la
pause/reprise et doit etre repare separement de la physique du souffle.

La traversée ulterieure de la colonne ne produit, d'apres l'observation du
pilote, ni vent perceptible, ni secousse, ni turbulence. C'est conforme au code
actuel : `ShockAction` applique une seule impulsion au passage de l'onde, mais
le panache n'est pas un volume atmospherique persistant. Une evolution future
devra maintenir une zone bornee avec vent radial, ascendance, couronne
descendante et turbulence decroissante, sur l'horloge de simulation et avec un
cout CPU plafonne.

Les mesures excluent de nouveau un epuisement x86. Sur la fenetre couvrant le
second largage et le panache, la memoire privee culmine a 681,5 Mio, l'ensemble
de travail a 665,1 Mio et l'espace virtuel a 2 016,1 Mio. Le jeu consomme en
moyenne environ 98,7 % d'un coeur logique ; autoriser quatre coeurs ne rend donc
pas cette boucle historique multithread. Le moteur 3D de l'iGPU Intel se situe
en moyenne a 59,9 %, avec un maximum de 74,5 %, sans pic disque significatif.

Quatre erreurs `HierMesh` restent reproductibles a chaque chargement du B-29 :
`zOilFlap1`, `zOilFlap2`, `zCompressor1` et `zCompressor2`. La ressource
`music/inflight` est absente par choix : Open Sturmovik ne joue jamais de
musique en vol et cet avertissement est attendu. Lors du second chargement, ProcDump
observe quatre exceptions C++ traitees `E06D7363.PAD` a la meme seconde que les
quatre chunks manquants. La correlation est forte mais ne prouve pas encore la
causalite ; ces erreurs feront l'objet d'un diagnostic distinct.

## Matrice de validation

1. **Valide :** B-29 Silverplate + Fat Man avec la famille `Explosions`
   Silverplate coherente, jusqu'a l'impact et l'arret normal.
2. **Valide en jeu :** B-29 Silverplate + Little Boy, impact sans gel, trois
   objets statiques detruits et souffle ABI corrige teste plus d'une minute
   sans pause.
3. **Correctif construit, test requis :** les douze emetteurs terre/eau sont
   forces sur le temps de simulation ; leur formation dure 600 s, puis un
   emetteur stabilise borne renouvelle son pool jusqu'a 3 600 s. Le candidat
   final est deploye dans le seul dossier de test avec 46 controles valides.
   La branche historique
   `bomb50_land` a ete retiree uniquement du chemin nucleaire.
4. Tester `default` et `none` pour obtenir les controles negatifs.
5. **Construit, deploye et valide dans la JVM 4.09m pour Little Boy :** famille
   `Explosions` fusionnee Silverplate + Zuti, douze classes major 47,
   construction deterministe et ABI `Tuple3d.add(Tuple3d)` executee sans gel.
6. Valider encore Fat Man, les impacts sur l'eau, plusieurs distances et les
   scenarios avec pause apres correction du cycle de vie visuel.
7. Corriger separement le cycle de vie du `ZutiTimer_RadarsCountRefresh`, afin
   qu'une future exception ne soit plus transformee en faux gel Windows.
8. Valider le souffle a plusieurs distances et altitudes, dont le cas de
   reference du B-29 a 5 000 m.
9. Ajouter puis mesurer une zone atmospherique persistante dans le panache ; le
   modele actuel ne produit aucune turbulence continue lorsqu'un avion le
   traverse.
10. Auditer separement les nuages meteorologiques et verifier si tout defaut
    d'horloge ou de particules touche aussi les bombes conventionnelles,
    incendies, fumees, trainees et poussieres avant toute correction globale.

Une campagne visuelle distincte verifiera ensuite les appareils signales par
Alexis : `TempestMkV`, `TyphoonMkIB` et les variantes Hurricane actives dans
`air.ini`. Elle comparera maillage, textures externes, niveaux de degats,
cockpit et avertissements du journal afin d'identifier exactement l'appareil et
la texture manquante.

Les fichiers visuels `FatMan(...).eff` n'ont pas besoin d'etre ouverts pour que
la liaison Java echoue : la JVM doit d'abord resoudre la methode
`Explosions.generate` absente. L'A/B a valide la liaison Java et les destructions
a l'impact ; l'apparence complete des effets reste a valider separement.

## Capture pause/reprise du 1er septembre 2026

La session instrumentee
`test-results/startup/20260901-060621Z-profile9-warm-windowed1024-startup`
confirme le defaut sans ambiguite. La capture contient 2 854 images et les
compteurs du processus. La mission B-29 + Little Boy se termine volontairement,
sans gel ni exception Java nouvelle.

La premiere pause est encadree image par image :

- image 2255, `06:12:28.621Z` : le nuage est pleinement developpe ;
- images 2260 a 2276, a partir de `06:12:29.297Z` : menu de pause ;
- image 2277, `06:12:31.298Z` : premiere image de reprise, le grand nuage est
  redevenu une petite sphere ;
- images 2280 a 2325 : la sphere grossit anormalement vite et retrouve un volume
  proche de l'etat anterieur vers `06:12:36.785Z`, soit environ 5,5 secondes
  apres la reprise.

Une seconde pause courte reproduit le meme depart de rattrapage. Le moteur ne
supprime donc plus definitivement l'effet avec le candidat a horloge de
simulation : il reconstruit visiblement l'age de l'emetteur lorsque le rendu 3D
reprend. Ce phenomene est distinct du temps de simulation, qui reste bien gele
par `Time.setPause(true)`.

Les decompilations 4.09m expliquent le chemin moteur. `GUI.activate()` met le
temps du jeu en pause puis donne le focus de rendu a `renderGUI`.
`GUI.unActivate()` restaure le temps et rend le focus au monde 3D. Les acteurs
`Eff3DActor` choisissent correctement `Time.current()` pour un effet non reel,
mais leur objet natif `Eff3D` possede en plus ses propres methodes protegees
`pause(boolean)` et `isPaused()`. Le menu ne les appelle pas. Le rattrapage est
donc attribue au cycle natif de l'emetteur lors de cette interruption de rendu,
et non a une consommation de RAM ou a l'onde de choc Java.

Pendant les deux reprises, le processus reste `Responding=True`. La memoire
privee reste voisine de 627 Mio et l'ensemble de travail de 611 Mio. La charge
oscille principalement entre 62 et 88 % d'un coeur logique, avec des pointes
brèves proches d'un coeur ; aucun pic memoire, disque ou CPU ne correspond au
rattrapage visuel.

### Correctif natif borne prepare pour le prochain essai

Le correctif ne modifie ni `GUIMission`, ni toutes les particules du jeu. Les
douze creations terre/eau de Little Boy et Fat Man, puis l'emetteur stabilise,
s'enregistrent aupres de `NuclearBlast`. Un unique `MsgAction` en temps reel
controle l'etat de pause toutes les 25 ms tant qu'au moins un de ces acteurs est
valide. Lors d'une transition, il appelle la methode native protegee
`Eff3D.pause(boolean)` par une reflexion mise en cache. L'objectif est de figer
l'etat interne de l'emetteur avant le premier rendu 3D de reprise, au lieu de le
laisser reconstruire son age.

La reflexion est volontairement confinee et tolere l'echec : une indisponibilite
produit un seul message dans `log.lst`, laisse le jeu continuer et ne touche pas
aux explosions conventionnelles. Une seule surveillance est partagee entre
tous les emetteurs nucleaires, afin d'eviter un minuteur par particule.

Le constructeur a produit deux fois les memes 12 classes, toutes en version
majeure Java 47. Il verifie desormais les 12 appels d'enregistrement, le
constructeur `MsgAction` en temps reel, l'appel reflechi et l'idempotence. Le
controle complet du depot obtient 16 PASS, un avertissement de dump attendu et
zero echec. Le prochain essai doit encore prouver que le pilote voit le meme
panache immediatement avant et apres la pause.

Le 1er septembre 2026, seules les trois classes modifiees par ce correctif ont
ete synchronisees dans le dossier de test. Dix-sept autres fichiers du plan
etaient deja identiques et aucun retrait n'a ete effectue. Les versions
precedentes restent recuperables dans :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260901-083925`

Apres cette operation, le validateur de contenu retourne 16 PASS, un WARN de
dump attendu et zero FAIL. Les 46 controles du profil 9 fenetre 1 024 x 768
retournent `Ready=True`. Le jeu n'a pas ete lance : ce resultat prouve la
coherence et la reversibilite du candidat, pas encore son comportement visuel.

## Verdict apres la campagne multicartes du 1er septembre

Le candidat de pause native a finalement ete execute dans
`test-results/startup/20260901-131015Z-profile9-warm-windowed1024-startup`.
Il **n'a pas corrige le panache** : Little Boy repart de zero apres une
pause/reprise. Le meme redemarrage apparait apres un demi-tour qui retire puis
remet l'effet dans le champ. L'absence du message
`native nuclear effect pause unavailable` montre que la reflexion n'a pas
signale d'echec ; appeler `Eff3D.pause` ne suffit pas lorsque le moteur coupe ou
reconstruit un emetteur en fonction du rendu.

La chaine fonctionnelle reste saine sur les autres points controles :

- Little Boy et Fat Man sont chacun relies a leur `BombGun` et a un crochet
  distinct du B-29SP ;
- les douze classes generees sont en Java major 47, sans definition libre
  concurrente ;
- l'ABI Silverplate a six arguments et les ajouts Zuti coexistent ;
- les maillages et textures des deux bombes sont identiques au paquet
  Silverplate v1.2 ;
- les huit effets resolvent tous leur materiau et respectent les plafonds
  `nParticles <= 512` et `LiveTime <= 128` ;
- Fat Man a termine une nouvelle mission sans gel ; le stress de seize B-29
  avec Fat Man n'a produit aucun ralentissement en vol perceptible.

Trois nouvelles limites statiques sont maintenant explicites. Les acteurs
d'effets initiaux sont crees avec un temps de traitement `-1` et restent
enregistres par la surveillance tant qu'ils sont valides : une session longue
ou de nombreux largages peuvent donc retenir des acteurs apres la fin visuelle.
Le controle toutes les 25 ms n'a aucun benefice visuel demontre. Enfin, le nuage
stabilise est place a 5 000 m pour 10 kt avant mise a l'echelle, alors que le
[rapport historique OSTI](https://www.osti.gov/opennet/servlets/purl/16009191-5O5srR/16009191.pdf)
situe le maximum du nuage vers dix minutes et 40 000 a 50 000 pieds.

Le rapport reproductible est `AUDIT_BOMBES_NUCLEAIRES_V1.15.md`, produit par
`tools/Audit-NuclearWeaponsV115.py`. La publication reste bloquee jusqu'au
remplacement du candidat de rendu, au bornage de la retention, puis aux essais
Little Boy/Fat Man terre/eau, pause, demi-tour, flash image par image et
autorite multijoueur.
