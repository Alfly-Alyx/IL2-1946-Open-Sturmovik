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

## Prochain essai

Un demarrage leger, machine au repos, reste necessaire. Il devra :

1. laisser IL-2 au premier plan pendant toute la capture ;
2. archiver la classification graphique produite automatiquement avec la trace ;
3. comparer le temps au menu a la reference d'environ 130,7 secondes ;
4. verifier que le moteur ne reecrit plus aucune valeur du profil Intel ;
5. conserver les journaux et une trace de fichiers exploitable.

Le test du bug critique en vol sera ensuite un scenario separe, instrumente
avec collecte de dump si le jeu plante ou se bloque.
