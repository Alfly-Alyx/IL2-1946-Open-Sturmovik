# Resultats des demarrages moddes du 31 aout 2026

## Verdict

Le profil 9 d'Open Sturmovik 1.15, soit la base 4.09m moddee avec le choix
historique 6DOF, a atteint le menu principal. Alexis a ensuite ferme le jeu
volontairement. Il ne s'agit donc ni d'un crash, ni d'un blocage a 5 ou 60 %.

Le dossier original
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946` est reste en lecture seule.
L'essai a utilise uniquement
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`.

Les artefacts complets sont conserves dans :

`test-results/startup/20260831-105746Z-profile9-cold-windowed1024-startup`

## Profil mesure

- IL-2 1946 4.09m modde ;
- EXE PE32 Large Address Aware ;
- wrapper historique de chargement des mods ;
- OpenGL natif ;
- Intel UHD Graphics 620, pilote OpenGL 4.6.0 build 31.0.101.2141 ;
- fenetre 1024 x 768 ;
- affinite `85`, soit un processeur logique de chacun des quatre coeurs
  physiques du Core i5-8350U ;
- introduction automatique desactivee ;
- journaux IL-2, compteurs processus/systeme, Process Monitor et capture a dix
  images par seconde armes.

Les binaires disponibles pour les choix 6DOF et sans 6DOF restent identiques.
Le libelle du profil est historique ; cet essai ne prouve pas un comportement
6DOF distinct.

## Chronologie observee

| Etape | Heure UTC | Temps depuis le processus | Observation |
|---|---:|---:|---|
| Processus detecte | 10:58:59,520 | environ 0 s | PID 20284 |
| Debut de `log.lst` et OpenGL | 10:59:43 | environ 44 s | principal cout initial attribue a l'indexation du contenu libre par le wrapper |
| Presets moteur precharges | 11:00:16 a 11:00:18 | environ 77 a 79 s | six presets refuses |
| Initialisation DirectSound | 11:01:06 | environ 127 s | repli logiciel reussi, 16 canaux |
| Premier menu non masque, image 777 | 11:01:10,173 | environ 130,7 s | menu principal utilisable |
| Fermeture volontaire | 11:01:19,901 | environ 140,4 s | aucun crash |

La capture de fenetre a commence tardivement, a environ 42,8 secondes, lorsque
la fenetre OpenGL est devenue detectable. Codex et le Gestionnaire des taches
ont masque le jeu sur une grande partie des images. L'image 777 prouve le menu,
mais cette session ne permet pas d'associer fiablement chaque pourcentage
visuel aux acces fichiers. Lors du prochain essai, aucune fenetre ne devra
repasser devant IL-2 apres son lancement.

## Memoire, CPU et ressources

Sur 1 016 mesures :

| Mesure | Moyenne | Maximum |
|---|---:|---:|
| Working set | 265,49 Mio | 470,42 Mio |
| Memoire privee | 285,82 Mio | 488,99 Mio |
| Espace virtuel | 1 554,19 Mio | 1 786,76 Mio |
| Threads | 18,60 | 26 |
| Handles | 566,65 | 738 |

Au premier menu visible, le processus utilisait 466,62 Mio de working set,
484,70 Mio prives et 1 786,76 Mio d'espace virtuel. Il avait consomme 86,06
secondes CPU sur environ 139,58 secondes mesurees, soit 61,7 % d'un coeur en
equivalent moyen. Cette mesure confirme une marge avant la limite x86, mais ne
couvre pas encore une mission ni les textures 2K/4K en vol.

La trace Process Monitor pese 3 577 185 581 octets. WPR n'a pas pu activer son
profil noyau a cause de la politique Windows (`0xc5585011`) ; les compteurs
locaux ont pris le relais. Une exportation filtree de la trace PML sera
necessaire avant de l'utiliser pour les acces detailles.

## Resultats du journal IL-2

Le GPU est correctement identifie. Le moteur voit une texture maximale de
16 384 et l'anisotropie 16x. Les extensions NVIDIA historiques
`GL_NV_texture_shader`, `GL_NV_texture_env_combine4` et `GL_NV_depth_clamp` ne
sont pas exposees sur l'Intel, ce qui est normal.

Huit avertissements utiles sont apparus :

- deux avertissements de refus du mode `Perfect` ;
- six `Invalid preset format` pour les couples `start.begin`/`start.end` de
  DB-600, Rolls-Royce Merlin et Sabre.

Les anciens defauts suivants ne sont pas reapparus pendant ce parcours jusqu'au
menu :

- aucune `FileNotFoundException` ;
- aucun `No spawner` ;
- aucun `Wrong chief's type` ;
- aucune exception `ZutiTimer_ExtendPlanesWings` ;
- aucun `Str2FloatClamp` ;
- aucune erreur de materiau ou de maillage TBM-1.

Cette absence vaut pour le demarrage et le menu seulement. Une mission devra
encore exercer les appareils, les modeles de vol, les navires, Zuti et les sons
moteur en situation.

## Corrections appliquees apres l'essai

Les petits presets generiques provenant du paquet de compatibilite SAS ont ete
remplaces par dix presets mixeur complets extraits de Tiger33 Ultimate Sound
Mod V3, source connue pour la branche 4.09m. Dix-huit WAV necessaires ont ete
ajoutes ; les deux WAV Sabre historiques deja choisis dans Open Sturmovik ont
ete conserves. La provenance et les empreintes sont dans
`manifests/audio/tiger33-startup-sounds.json`. Le validateur controle maintenant
la structure du mixeur, chaque reference WAV et le manifeste ; une simple
empreinte d'un preset incomplet ne peut plus produire un faux PASS.

Le premier correctif graphique avait place `HardwareShaders=0` et `Forest=2`,
mais conservait encore `LandGeom=3`. Le second test ci-dessous a prouve que ce
dernier parametre demandait toujours une fonction reservee au mode Perfect.

La mise a jour du dossier de test a cree la sauvegarde recuperable :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-132504`

La normalisation finale des fins de lignes des presets a cree une sauvegarde
supplementaire :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-133554`

Apres activation du profil 9 :

- validation de contenu : 15 PASS, 1 WARN attendu, 0 FAIL ;
- disponibilite avant lancement : 44 controles reussis sur 44 ;
- configuration Intel active : `HardwareShaders=0`, `Forest=2`, `Water=2` ;
- affinite active : `85` ;
- aucun processus IL-2 actif.

## Second essai : charge systeme elevee, cache chaud

Le second lancement a lui aussi atteint le menu, puis Alexis a ferme le jeu
volontairement. Les artefacts sont conserves dans :

`test-results/startup/20260831-121920Z-profile9-warm-windowed1024-startup`

Le PC n'avait pas ete redemarre et compilait d'autres projets. Process Monitor
a donc ete volontairement omis pour ne pas alourdir davantage la machine ; les
images, journaux, modules, compteurs du processus et compteurs systeme ont ete
conserves. Ce parcours est une validation fonctionnelle, pas une reference de
performance a froid.

| Etape | Heure UTC | Temps depuis le processus | Observation |
|---|---:|---:|---|
| Processus detecte | 12:21:27,732 | 0 s | PID 15088 |
| Fenetre et debut OpenGL | 12:22:07,594 | environ 39,9 s | etape initiale environ 4 s plus courte que le premier essai |
| Initialisation DirectSound | 12:24:19 | environ 171,3 s | 16 canaux, repli logiciel normal |
| Premier menu, image 1153 | 12:24:19,276 | environ 171,5 s | menu complet et utilisable |
| Fermeture volontaire | 12:24:28,632 | environ 180,9 s | aucun crash |

Le temps total au menu est environ 40,8 secondes plus long que la premiere
reference de 130,7 secondes. Cela ne montre pas une regression propre a
Open Sturmovik : le processeur systeme etait utilise en moyenne a 78,05 %, avec
un pic a 100 %, contre 56,37 % en moyenne lors du premier essai. La capture
montre notamment les compilations et autres processus en concurrence. Aucune
conclusion d'acceleration ne doit etre tiree avant deux mesures legeres dans des
conditions comparables.

Au menu, IL-2 utilisait 467,80 Mio de working set, 481,53 Mio prives et
1 773,36 Mio d'espace virtuel. Les maxima ont ete de 470,74 Mio, 486,35 Mio et
1 782,77 Mio. Ces valeurs restent proches du premier essai et gardent une marge
x86 importante au menu.

### Resultat des correctifs

Les six `Invalid preset format` ont disparu. Il n'y a toujours aucune
`FileNotFoundException`, aucun `No spawner`, aucun `Wrong chief's type`, aucune
exception Zuti, aucun `Str2FloatClamp` et aucune erreur de materiau ou de
maillage TBM-1. Les presets Tiger33 et leurs WAV sont donc valides pour le
parcours de demarrage ; leurs sons doivent encore etre ecoutes en mission.

Deux avertissements Perfect restent presents. La comparaison binaire de
`conf.ini` avant et apres le jeu a isole une seule reecriture :
`Render_OpenGL/LandGeom=3` est devenu `LandGeom=2`. Restaurer uniquement cette
ligne reproduit exactement l'empreinte SHA-256 d'avant lancement. Les notes du
patch 4.09m confirment que `LandGeom=3` double la portee de 36 a 72 km et n'est
disponible qu'en mode Perfect :
[notes 4.09m](https://www.com-central.net/index.php/pouk/seznam-ucbenikov-in-solskih-potrebscin/index.php?file=details&id=384&name=Downloads),
[configuration maximale communautaire SAS](https://www.sas1946.com/main/index.php?topic=9756.0).

Le profil generique est donc corrige une seconde fois : Intel, AMD et GPU
inconnu utilisent `HardwareShaders=0`, `Forest=2` et `LandGeom=2`. Le selecteur
ne demande `HardwareShaders=1`, `Forest=3`, `LandGeom=3` et les extensions NV
que sur le profil NVIDIA. Le controle de disponibilite verifie maintenant
explicitement `LandGeom` selon le fournisseur.

La correction a ete synchronisee dans le dossier de test avec la sauvegarde
recuperable
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-144614`.
Le controle final passe 45 verifications sur 45 ; le validateur de contenu reste
a 15 PASS, un WARN attendu faute de Dump runtime recent et zero FAIL.

## Troisieme essai : profil corrige et charge plus faible

Le troisieme lancement a atteint le menu puis Alexis a ferme volontairement le
jeu. Les artefacts sont conserves dans :

`test-results/startup/20260831-132416Z-profile9-warm-windowed1024-startup`

| Etape | Heure UTC | Temps depuis le processus | Observation |
|---|---:|---:|---|
| Processus detecte | 13:25:25,991 | 0 s | PID 18000 |
| Fenetre OpenGL | 13:25:58,163 | environ 32,2 s | meilleur temps initial mesure |
| Initialisation DirectSound | 13:27:00 | environ 94,0 s | initialisation normale, 16 canaux |
| Premier menu, image 562 | 13:27:00,364 | environ 94,4 s | menu complet et utilisable |
| Fermeture volontaire | 13:27:14,261 | environ 108,3 s | aucun crash |

Le processeur systeme etait utilise en moyenne a 34,16 %, avec un maximum de
88,38 %. Ce contexte est bien plus favorable que les 78,05 % du second essai.
Le temps au menu gagne environ 36,3 secondes sur la premiere reference de
130,7 secondes et 77,1 secondes sur l'essai surcharge. Le cache et la baisse de
concurrence ont probablement tous deux contribue ; une paire froid/chaud dans
les memes conditions reste necessaire pour les separer.

Les maxima du processus sont de 473,39 Mio de working set, 489,36 Mio prives et
1 787 Mio d'espace virtuel. Aucun preset invalide ni aucune des erreurs de
contenu surveillees n'est reapparu.

Les deux avertissements Perfect sont encore imprimes. En revanche, l'empreinte
SHA-256 de `conf.ini` est strictement identique avant et apres le lancement :
`HardwareShaders=0`, `Forest=2`, `LandGeom=2` et `Water=2` sont tous conserves.
La correction `LandGeom=2` a donc supprime la reecriture prouvee au second
essai.

L'analyse hors jeu de `il2_core.dll` a ensuite ferme ce diagnostic. Le moteur
emet ces avis pendant l'inventaire de ses capacites Perfect et exige notamment
`GL_NV_texture_shader`. Le pilote Intel annonce les programmes de shaders ARB
modernes, mais pas cette extension NVIDIA historique. Aucun autre parametre du
profil n'est en cause : sur Intel avec le profil securise, les deux lignes sont
des avis de capacite attendus. `tools/Test-IL2GraphicsCompatibility.ps1` produit
desormais cette classification de facon reproductible et conserve le niveau
erreur si un profil demande reellement Perfect sans chemin compatible.

## Plan etabli apres le troisieme demarrage

Un demarrage leger, machine au repos, reste necessaire. Il devra :

1. laisser IL-2 au premier plan pendant toute la capture ;
2. archiver la classification graphique produite automatiquement avec la trace ;
3. comparer le temps au menu a la reference d'environ 130,7 secondes ;
4. verifier que le moteur ne reecrit plus aucune valeur du profil Intel ;
5. conserver les journaux et une trace de fichiers exploitable.

Le test du bug critique en vol a ensuite ete execute dans des captures separees,
decrites ci-dessous.

## Premier essai en vol : B-29, sans largage confirme

Artefacts :

`test-results/startup/20260831-145400Z-profile9-warm-windowed1024-startup`

Le profil 9 a atteint le menu puis une mission rapide en B-29. Le passage du
profil fenetre a `rts/mouseUse=1` a retabli un curseur visible et utilisable. Le
joystick n'etait toutefois pas reconnu et aucune commande de largage n'a ete
confirmee pendant ce parcours ; cet essai ne reproduit donc pas le bug critique.
Alexis a quitte le jeu volontairement apres plusieurs minutes en vol.

Les maxima du processus sont 622,88 Mio de working set, 639,66 Mio de memoire
privee et 1 933,04 Mio d'espace virtuel. L'utilisation CPU totale du PC est de
44,14 % en moyenne et 94,93 % au maximum ; le disque reste a 0,71 % en moyenne.
Cette session constitue une premiere borne de vol sur le Core i5-8350U, mais pas
encore une charge recommandee de reference.

Le journal apporte quatre defauts de contenu distincts :

- `music/menu/ab.wav` est absent ;
- `maps/slovakia/actors.static` est declare endommage, puis sa lecture termine
  par `FileNotFoundException`, meme si la mission finit par demarrer ;
- le cockpit B-29 demande les chunks `zOilFlap1`, `zOilFlap2`, `zCompressor1` et
  `zCompressor2`, absents du maillage effectivement charge ;
- aucun fichier n'est disponible sous `music/inflight`, conformement au choix
  historique de ne jamais jouer de musique en vol ; cet avertissement est
  attendu et ne doit pas etre corrige.

Les deux exceptions « Annule par l'utilisateur » correspondent aux deux
chargements interrompus depuis l'interface et ne sont pas classees comme crash.
Ces constats restent a traiter ; ils ne doivent pas etre confondus avec le gel
au largage.

## Second essai en vol : gel critique reproduit

Artefacts :

`test-results/startup/20260831-152135Z-profile9-warm-windowed1024-startup`

La commande `Ctrl+B` a d'abord ete ajoutee comme seconde liaison de `Weapon3`,
sans supprimer `Alt+Espace`. Le scenario observe sur la capture est : Boeing
B-29 Silverplate 1944, emport `FatMan`, Smolensk, altitude QMB 10 000 m. Le
largage a gele l'image vers 15:25:43,257 UTC. Six secondes plus tard, Windows a
affiche `Ne repond pas`, puis la boite proposant d'attendre ou de fermer le
programme. L'evenement Application Hang 1002 classe le cas en `AppHangB1`.

ProcDump a conserve un dump complet de 862 461 129 octets, SHA-256
`58F49621939843B7F0A5EFF704F68C1DDE477F5E3073F3CE793DACE1935AB4CC`.
Au gel, IL-2 utilise environ 665,83 Mio de working set, 682,55 Mio de memoire
privee et 1 968,37 Mio d'espace virtuel. Le maximum prive reste 708,17 Mio. Le
GPU 3D atteint 78,39 % au maximum, le disque 1,31 % en moyenne et environ 19 Gio
de RAM physique restent disponibles. La panne n'est donc pas un manque de RAM,
de VRAM, de CPU ou de debit disque.

Le dump montre que la boucle Java principale a deja rendu la main, puis que
`DestroyJavaVM` attend indefiniment un minuteur Zuti non daemon. Sa seule tache
est `ZutiTimer_RadarsCountRefresh`, repetee toutes les deux secondes. Ce minuteur
explique l'impossibilite d'arreter proprement la JVM, mais la cause qui fait
sortir la boucle au largage est distincte.

La comparaison avec le paquet Silverplate v1.2 d'origine a d'abord isole
`semi-realDropBomb v2.0` comme candidat. Ce candidat a ete controle lors de
l'essai suivant et elimine comme cause primaire. Le dossier technique complet
est [BUG_CRITIQUE_B29_FATMAN.md](BUG_CRITIQUE_B29_FATMAN.md).

Une correction du collecteur graphique a aussi ete faite : une seule ligne
Perfect dans un journal pouvait devenir un scalaire PowerShell et rendre
`.Count` invalide. La liste est maintenant forcee en tableau, y compris avec
zero ou un avertissement.

## Troisieme essai en vol : `BombGun` officielle, gel reproduit

Artefacts :

`test-results/startup/20260831-164731Z-profile9-warm-windowed1024-startup`

Le meme scenario B-29 Silverplate + Fat Man a ete rejoue avec la classe
`BombGun` officielle 4.09m. Le gel est identique. Le processus reste
continuellement `Responding=False` de 17:41:16,197 UTC jusqu'a sa fermeture,
pendant 138,81 secondes. Il n'avance que de 796,88 ms de CPU et sa memoire reste
stable : l'hypothese d'une saturation est de nouveau exclue.

Le dump complet `process-dumps/il2fb.exe_260831_194117.dmp` mesure
857 177 177 octets, SHA-256
`5961FD46E6B46499659A60140D1BD19D5B9EC7F28CC38DCACE505B770D8DE825`.
Son etat terminal est identique au premier : la boucle Java principale est deja
sortie et `DestroyJavaVM` attend le minuteur Zuti non daemon.

L'inventaire bytecode a alors identifie l'incompatibilite exacte. La classe
`Bomb` de Silverplate appelle `Explosions.generate` avec six parametres, dont le
type d'effet nucleaire. La classe `Explosions` active, modifiee pour Zuti, ne
fournit plus que la variante a cinq parametres. La resolution de cet appel ne
peut produire qu'un `NoSuchMethodError`. La sortie de la boucle principale est
donc coherente avec les deux dumps ; le minuteur Zuti masque ensuite l'exception
en maintenant le processus vivant.

## Quatrieme essai en vol : famille `Explosions` Silverplate, succes

Artefacts :

`test-results/startup/20260831-184314Z-profile9-warm-windowed1024-startup`

`semi-realDropBomb v2.0` a ete restaure et la famille complete de 15 classes
`Explosions` du paquet Silverplate a ete activee temporairement dans le seul
dossier de test. Le depot v1.15 n'a pas recu ce remplacement diagnostique.

Le B-29 Silverplate avec Fat Man a demarre la mission Smolensk, largue la bombe,
survecu a l'impact et continue a voler plusieurs minutes. `eventlog.lst`
enregistre trois objets statiques detruits a `12:00:54`. La capture montre le
message en jeu confirmant un coup direct et une cible detruite. La mission se
termine normalement a `12:04:14`.

Aucun echantillon `Responding=False` n'apparait apres l'armement du largage,
aucune exception non geree et aucun dump ne sont produits. Le journal contient
`Radars count refreshing stopped!` avant sa fermeture normale : le minuteur Zuti
s'arrete donc correctement lorsque la boucle de jeu ne subit pas l'erreur de
liaison.

Autour de l'impact observe vers 18:50:33 UTC, le processus reste entre 663 et
667 Mio de working set, 680 et 684 Mio de memoire privee et 1 967 Mio d'espace
virtuel. Sur cette fenetre, le GPU 3D IL-2 atteint 50,67 %, la memoire graphique
partagee 172,56 Mio et le disque 3,63 %. Le CPU systeme atteint presque 100 % car
la machine execute aussi les collecteurs et d'autres projets, mais IL-2 reste
repondant. Le maximum de la session est 689,07 Mio de working set, 706,47 Mio de
memoire privee et 1 971,07 Mio d'espace virtuel.

Ce resultat confirme l'incompatibilite ABI entre `Bomb` Silverplate et
`Explosions` Open Sturmovik/Zuti comme cause du gel. Il ne valide pas encore le
correctif final : celui-ci doit fusionner la surcharge nucleaire a six
parametres avec les multiplicateurs de crateres Zuti. La capture confirme les
destructions, mais ne montre pas clairement le panache nucleaire complet ; son
aspect sera controle dans un essai dedie.

## Cinquieme essai en vol : deux bombes atomiques et Hawker

Artefacts :

`test-results/startup/20260831-192529Z-profile9-warm-windowed1024-startup`

Le lancement a reuni deux missions B-29 Silverplate et trois missions courtes
avec des appareils Hawker. Les deux seules bombes atomiques du paquet ont
fonctionne sans reproduire le gel : Little Boy detruit trois objets statiques a
`12:00:40`, puis Fat Man en detruit trois a `12:01:13` dans la mission suivante.

Leur rendu reste incorrect lorsque le jeu est mis en pause pendant l'effet.
Apres reprise, le panache devient un ensemble de particules ressemblant a des
nuages, puis une petite explosion conventionnelle demeure visible. Le bytecode
confirme que les deux bombes partagent la routine `bombFatMan_*` et que la
branche nucleaire peut appeler ensuite `bomb50_land(..., 10.0f)`. Les fichiers
d'effet melangent aussi des durees de 1 a 99 999 secondes. Un essai sans pause
est necessaire pour separer l'effet historique normal du vieillissement des
particules pendant la pause.

A 5 000 m, le B-29 n'a subi aucun souffle ni dommage. Les deux bombes declarent
un rayon fixe de 3 200 m ; l'appareil est donc hors de la sphere de degats avant
meme d'ajouter sa distance horizontale. Un modele progressif et retarde de
flash, surpression, souffle et dommages 3D est desormais une exigence acceptee
de la v1.15. Ce cas a 5 000 m servira de validation.

Les trois missions Hawker enregistrees se terminent apres 28, 7 et 3 secondes.
Les captures exterieures montrent les textures du dessus, du dessous et des
cotes sans zone absente. Le defaut historique n'est donc **pas reproduit** dans
l'installation de test actuelle ; il n'est pas encore prouve qu'une correction
precise l'a supprime.

ProcDump a classe comme gel une fenetre non repondante entre 21:41:17 et
21:41:25, juste avant le debut de la premiere mission Hawker. Le dump complet,
SHA-256 `CACA2268002E79B2DA797E0F14893F29BDFB11A2AA69C0975ED0BBBDD6AC8ADD`,
ne contient pas de flux d'exception. Son thread principal se trouve dans
`ig9icd32.dll`, sous `opengl32!glTexImage2D`, appele par
`il2_corep4!BmpUtils_BMP8PalTo4TGA4`. Il s'agit d'une conversion et d'un envoi
de texture Intel pendant le chargement, et non d'un crash Hawker. Ce point
explique une partie des pauses de chargement observees.

La session culmine a 840,88 Mio de working set, 705,01 Mio de memoire privee et
2 000,21 Mio d'espace virtuel. La fermeture produit toutefois un `APPCRASH`
Windows distinct, code `0xc0000005`, dans un module inconnu a 21:44:43. Aucun
dump de cette sortie n'est disponible, car ProcDump avait deja atteint son
quota sur le faux gel de chargement. Cette violation d'acces de fermeture reste
a reproduire et a diagnostiquer separement.

## Suite de la campagne

1. **Fait statiquement :** construire la famille `Explosions` fusionnee
   Silverplate + Zuti en Java major 47.
2. **Fait dans le candidat :** retirer la petite explosion conventionnelle du
   chemin nucleaire, declencher les airbursts historiques et programmer les
   degats sur l'horloge de simulation.
3. **Fait dans le candidat :** souffle progressif, retarde et borne a une
   recherche spatiale, avec impulsion exterieure reservee aux avions.
4. **Pret a tester :** le candidat et la famille interne Zuti coherente ont ete
   copies dans le dossier de test apres sauvegarde de 19 fichiers ; les 24
   copies et les 46 controles de preparation sont valides.
5. Refaire Little Boy et Fat Man sans pause, puis avec pause, a plusieurs
   altitudes et distances.
6. Reproduire la violation d'acces a la fermeture avec un dump reserve a cette
   phase.
7. Conserver les Hawker comme controles visuels, le defaut n'etant plus
   reproductible dans l'etat actuel.

Aucun lancement ne sera effectue sans avertir Alexis juste avant.

## Essai Little Boy du 1er septembre 2026

Artefacts :

`test-results/startup/20260831-222423Z-profile9-warm-windowed1024-startup`

Little Boy a ete largue depuis le B-29 Silverplate. Le panache apparait vers
22:31:22 UTC. La fenetre passe definitivement a `Responding=False` a 22:31:34,
soit environ douze a treize secondes plus tard. ProcDump a conserve deux dumps
complets de 855 082 239 et 854 971 651 octets. La JVM a quitte sa boucle
principale, puis le minuteur Zuti non daemon a maintenu le processus en vie.

La cause est une incompatibilite de signature dans le nouveau chemin de
secousse : le stub declarait `Vector3d.add(Vector3d)`, mais IL-2 4.09m expose
`Tuple3d.add(Tuple3d)`. L'appel n'etait execute qu'a l'arrivee differee de l'onde
sur l'avion, ce qui explique le decalage. Le stub et le garde-fou du constructeur
ont ete corriges. La pause/reprise continue par ailleurs a reduire le panache,
mais moins fortement qu'avant ; ce probleme de particules demeure independant.

### Validation du correctif et comparaison pause/sans pause

Artefacts :

`test-results/startup/20260901-050213Z-profile9-warm-windowed1024-startup`

La meme session contient deux chargements de
`Quick/SmolenskRedNone00.mis` et deux largages de Little Boy. Le processus
`il2fb.exe` PID 17432 se termine volontairement avec le code `0x00000000`.
ProcDump n'a declenche aucun dump et le journal Windows ne contient aucun
evenement d'application. Le journal IL-2 ne contient ni `NoSuchMethodError`, ni
`FileNotFoundException`, ni exception Java. Le correctif de l'ABI de
`ShockAction` est donc valide dans le moteur 4.09m reel pour Little Boy.

Chronologie visuelle extraite des 5 870 captures :

- premier largage : le nuage entre dans l'image vers 05:10:10 UTC ; le menu de
  pause est visible vers 05:10:13-05:10:14 ; a la reprise vers 05:10:15, le
  nuage a disparu malgre un point de vue comparable ;
- second largage sans pause : flash vers 05:12:40-05:12:41, formation du nuage
  vers 05:12:42, puis panache encore visible vers 05:13:50, soit plus d'une
  minute apres le flash ;
- la traversee de la colonne n'a produit ni vent, ni turbulence, ni secousse
  perceptible selon le pilote. Le code ne maintient actuellement aucune zone
  atmospherique apres l'impulsion unique de `ShockAction`.

Entre 05:12:10 et 05:13:55, toutes les mesures de reponse de la fenetre sont
positives. La memoire privee atteint au plus 681,5 Mio, l'ensemble de travail
665,1 Mio et l'espace virtuel 2 016,1 Mio. La consommation CPU du processus
equivaut a 98,7 % d'un coeur logique en moyenne : l'affinite quatre coeurs est
disponible, mais la boucle de vol reste essentiellement monothread. Le moteur
3D Intel UHD 620 utilise en moyenne 59,9 % du GPU et atteint 74,5 % ; la memoire
GPU engagee du processus culmine a environ 176,8 Mio. Le disque reste sous 2 %
d'activite pendant le panache. L'explosion ne produit donc aucun pic CPU,
memoire, GPU ou disque susceptible d'expliquer l'ancien gel.

Le premier chargement de la mission dure environ 26 secondes, de 05:08:29 a
05:08:55, contre environ six secondes pour le second chargement chaud, de
05:11:49 a 05:11:55. Huit rechargements inattendus des textures du cockpit B-29
ne sont journalises que pendant le premier chargement. Ce resultat confirme le
benefice important des caches en memoire, sans encore resoudre le cout d'un
premier chargement a froid.

Problemes non bloquants mais reproductibles :

- le cockpit B-29 demande a chaque mission les chunks absents `zOilFlap1`,
  `zOilFlap2`, `zCompressor1` et `zCompressor2` ;
- `music/inflight` ne contient aucun fichier : c'est une absence intentionnelle
  et un avertissement attendu, pas un defaut de contenu ;
- ProcDump observe quatre exceptions C++ traitees `E06D7363.PAD` a 05:11:55,
  exactement lorsque les quatre erreurs de chunks sont emises. Il s'agit d'une
  correlation a verifier, pas encore d'une preuve de causalite ;
- les avertissements `Perfect` sont la notification attendue du profil OpenGL
  natif securise sur Intel et ne constituent pas un echec.

Verdict : le gel Little Boy cause par l'ABI est corrige. Le defaut de
pause/reprise du panache est confirme. Fat Man, l'eau, les distances variables
et la future atmosphere persistante restent a valider.

### Candidat temporel realiste et compatible avec la pause

L'analyse des classes 4.09m `Eff3D`, `Eff3DActor`, `Time`, `Renders` et
`GUIWindowManager` distingue deux horloges natives. Le menu suspend l'horloge
de simulation Java, tandis que chaque systeme de particules peut etre cree en
temps de simulation ou en temps reel. La fabrique generique
`Eff3DActor.New(...)` ne selectionne pas explicitement ce mode. Le candidat
v1.15 appelle donc `Eff3D.initSetTypeTimer(false)` avant chacun des douze
emetteurs nucleaires terre/eau. Une pause ne doit plus consommer leur formation
ni leur vie.

Les durees visuelles ont aussi ete remplacees par un modele historique borne :
maximum de la boule de feu vers une seconde, formation et montee du nuage sur
600 secondes de simulation, puis nuage stabilise jusqu'a 3 600 secondes. IL-2
4.09m plafonne chaque emetteur a 512 particules et chaque particule a 128 s :
le candidat respecte ces limites et renouvelle un pool stabilise de 512
particules entre la dixieme minute et la premiere heure. Le maximum theorique
est de 1 544 particules au depart sur terre, 1 288 sur l'eau et, pendant le
bref recouvrement a dix minutes, 2 056/1 800. La duree reelle n'est donc pas
simulee par une valeur que le moteur aurait silencieusement tronquee. La source de
reference decrit un nuage stabilise apres environ dix minutes et encore visible
pendant environ une heure ou davantage :
[The Effects of Nuclear Weapons, chapitre II](https://www.atomicarchive.com/resources/documents/effects/glasstone-dolan/chapter2.html).
La chronologie du
[National Park Service](https://home.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm)
situe le maximum de la boule de feu de Little Boy et le debut du champignon une
seconde apres la detonation.

Le bytecode major 47 est valide et sa reconstruction est deterministe. Un
premier candidat a ete sauvegarde puis remplace avant tout lancement lorsqu'a
ete confirmee la limite `512/128` du moteur. La variante finale par emetteur
phase a ete synchronisee dans le dossier de test avec sauvegarde recuperable
dans
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260901-080125`.
Le controle obtient 16 PASS, un WARN runtime attendu et zero FAIL ; les 46
controles de preparation passent. Little Boy avec pause, Little Boy sans pause,
puis Fat Man avec et sans pause restent les controles runtime obligatoires.
