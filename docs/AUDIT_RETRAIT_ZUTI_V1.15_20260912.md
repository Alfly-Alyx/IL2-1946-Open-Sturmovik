# Préparation du retrait de Zuti MDS 1.13 — 12 septembre 2026

## État et périmètre

**Le retrait du moteur Zuti n'est pas effectué et sa compatibilité n'est pas
démontrée.** Cette analyse prépare la demande de retrait d'Alexis. Elle ne
constitue ni un manifeste de suppression approuvé ni une preuve que les autres
mods sont préservés. Aucun fichier de moteur, mission ou ressource de jeu n'a
été modifié par cet audit. Aucun jeu, décompilateur complet ou compilateur n'a
été lancé.

La branche partagée contrôlée est `v1.15`, HEAD
`ae93f1669bc85e7d34e9116a27977ce4f9227be7`. L'analyse porte sur les classes
libres présentes au moment du relevé et les archives des profils **4.09m**.
Elle ne qualifie pas les profils 4.08m et 4.09b également proposés par le
switcher. Les fichiers de travail de l'audit ont été créés sous `.codex` ;
seules cette documentation et ses données de reproduction ont été ajoutées
au dépôt.

Les preuves complètes sont dans
[inventory.json](research/zuti-removal-20260912/inventory.json) ; le programme
[analyze.py](research/zuti-removal-20260912/analyze.py) les reproduit. Ces deux
fichiers sont des documents d'analyse, pas des composants chargés par le jeu.

## Faits vérifiés dans les fichiers — confiance élevée

### Base 4.09m et stockage des classes

Les archives contrôlées sont :

| Archive | SHA-256 |
| --- | --- |
| `_Game Switcher/4.09 final Mods ON (NO 6DOF)/files.SFS` | `5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71` |
| `_Game Switcher/4.09 final Mods OFF (Original)/files.SFS` | `FCFCE245EC23FF314C6CD86E9A51D563D091CFF74DDD0B46B704B670C0340C6A` |

Ces empreintes correspondent au manifeste du switcher actuel. Le programme
refuse de continuer si elles changent. Il utilise `SfsArchive.extract_class`
de `tools/Analyze-Sfs.py`, en lecture seule et en mémoire.

Les douze classes structurantes suivies par `Test-ZutiMDS113.ps1`, les trois
classes de modèle de vol AOC et `Explosions` existent dans les deux SFS. Leurs
octets sont identiques entre ces deux archives et ne contiennent pas la chaîne
`Zuti`. Les trente classes nommées dans le manifeste historique
`manifests/mods/zuti-mds-1.13-static.json` sont absentes de ces deux archives.
Les surcharges Zuti observées dans le paquet sont donc des fichiers libres,
en majorité à noms hexadécimaux. Cela ne constitue pas une recherche exhaustive
de toutes les classes de toutes les archives SFS du jeu.

Parmi les 253 classes libres contenant une chaîne Zuti, 64 ont une contrepartie
dans le SFS du profil moddé examiné. Ces 64 contreparties sont sans chaîne
Zuti. 63 sont identiques entre les archives ON/OFF ; la seule différence
observée est `com/maddox/il2/engine/Config`. Ne pas remplacer cette classe par
une variante choisie au hasard.

Le dossier de ressources nommé
`D:\Projets\GITHUB\#res\IL2 1946\0 - ORIGINAL GAMES DO NOT USE\Il-2 Sturmovik 1946 _4.09m`
**n'est pas une source stock fiable par son seul nom**. Un examen mémoire
ciblé de son `files.SFS` a trouvé des références Zuti dans les classes
structurantes et 16 des 30 classes nommées du manifeste historique. Ces classes
diffèrent des profils 4.09m contrôlés ci-dessus. Cette observation rejoint la
limite déjà documentée dans `ARCHITECTURE_MOTEUR.md` : l'installation de
référence contient des composants plus récents. Rien n'a été copié depuis
cette installation.

### Inventaire et dépendances

| Mesure | Résultat |
| --- | ---: |
| Fichiers ClassFile examinés | 2 469 |
| Noms internes de classes distincts | 2 467 |
| Erreurs de lecture du ClassFile | 0 |
| Classes contenant une chaîne `Zuti` dans leur pool de constantes | 253 |
| Classes dont le nom interne contient `Zuti` | 59 |
| Contreparties présentes dans le SFS 4.09m moddé | 64 |
| Références de membres devenant introuvables après retrait/repli brut des 253 | 317 |
| Classes appelantes concernées | 82 |
| Autres classes de leurs familles, sans chaîne Zuti | 308 |

Le nombre historique de trente classes était celui d'un dump de classes
chargées lors d'un scénario donné ; il ne décrivait pas tous les fichiers du
mod. Il ne peut pas servir de liste de suppression.

Deux doublons de nom interne existent dans le corpus : `StringComparator` et
`ZutiTimer_ExtendPlanesWings`. Pour le minuteur, il faut considérer à la fois
`Files/636FF1388721B648` et
`Files/com/maddox/il2/game/ZutiTimer_ExtendPlanesWings.class`. Retirer seulement
le correctif nommé laisserait la classe historique. L'inventaire n'affirme pas
quel doublon gagne la résolution à l'exécution.

Les familles touchées dépassent les helpers nommés Zuti : mission et commandes,
HUD, réseau, écran de briefing et d'armement, carte de vol, éditeur de missions,
IA, aérodromes, contrôles, trains, chars, artillerie, navires, cockpit et
explosions. La liste exacte avec chemins, empreintes, chaînes et membres
absents de la base est dans `candidates` du JSON.

### Autres fonctions que le retrait brut casserait

| Classe à préserver ou reconstruire | Dépendance constatée |
| --- | --- |
| `Controls` — `Files/34B2D47E9F860052` | Les champs `bMoveSideDoor`, `bHasBayDoors` et la méthode `setActiveDoor(int)` n'existent pas dans la contrepartie SFS. `AircraftState`, plusieurs Spitfire et leurs cockpits les référencent. Un retour stock introduirait des membres introuvables. |
| `Explosions` — `Files/72DCDDF4D2AD25E8` | `Bomb` référence la surcharge `generate(Actor, Point3d, float, int, float, int)`, absente du SFS stock. La classe est fusionnée avec le correctif Silverplate/nucléaire. |
| `Motor` — `Files/AF5F8A326C3FA53C` | La classe contient simultanément les consommateurs AOC 1a et les méthodes de sauvegarde/restauration Zuti. Un retour stock ferait perdre AOC même en l'absence d'erreur de liaison immédiate. |
| Classes internes, par exemple `PlMission$31`, `HouseManager$HouseNet`, `BigshipGeneric$SPAWN` | Elles appellent des accesseurs synthétiques `access$...` des classes parentes modifiées. Garder ces enfants avec une autre version de la parente produit des membres absents, ou potentiellement des appels de même signature mais d'autre comportement. |

Le constructeur `tools/Build-OpenSturmovikNuclearPatch.ps1` utilise explicitement
une entrée `Explosions-Zuti`. Celui d'AOC
`tools/Build-OpenSturmovikAocZutiPatch.ps1` part de `base-zuti` et impose
`Motor.zutiMakeEngineBackup()` et `Motor.zutiRestoreMotor(Motor)`. Les supprimer
sans adapter les constructeurs rendrait la reconstruction incohérente.

Les trois donneurs `test-assets/aoc-v1.15/donor-hsfx4` sont présents, leurs
empreintes correspondent au manifeste AOC et aucune de leurs constantes ne
contient `Zuti`. Ils proviennent, selon la provenance déjà archivée, d'AOC 1a
dans HSFX 4.0 pour IL-2 4.09m. Ils constituent une source de comparaison, **pas
une autorisation ni une preuve de compatibilité suffisante pour remplacer les
classes actuelles**. Leur chargeur lit notamment `Files/maps/aoc`, alors que
le paquet actuel utilise `_Game_Enhancements/Mod_AOC_Public`.

Le readme MDS 1.13 déclare aussi incorporer Certificates AI 3.0 et Fireballs
carrier takeoff 5.3.x. Une suppression de l'ensemble peut donc retirer ces
fonctions incorporées. L'identité fonctionnelle de chaque surcharge avec ces
mods séparés n'a pas été reconstruite dans cet audit.

## Déductions et plan technique proposé — non appliqué

Le mécanisme de repli vers les SFS existe déjà et est documenté dans
`ANALYSE_WRAPPER_DLL.md`. Il offre une base possible pour retrouver les classes
4.09m d'origine après retrait des surcharges. **Il ne garantit pas la
préservation des autres modifications apportées dans les mêmes classes.**

Une simulation affine le problème : garder provisoirement `Controls`, `Motor`
et `Explosions`, puis compléter les seules dépendances internes dont un membre
devient introuvable, élargit 250 candidats à **322 classes**. Il reste
14 références non résolues, toutes dans `Controls` ou `Explosions`, vers les
fonctions de largage/capture, les aérodromes et les multiplicateurs de durée
des cratères Zuti. Voir `provisional_family_closure` dans le JSON.

Ce résultat est un diagnostic ; **322 n'est pas une liste minimale validée de
suppression**. Il ne compare pas la sémantique des accesseurs de même signature,
ne vérifie pas exhaustivement les appels des classes SFS nouvellement exposées
vers toutes les surcharges restantes et ne couvre pas les accès natifs ou par
réflexion. Les 308 compagnons de famille doivent être comparés comme ensembles
cohérents, même quand la liaison par nom et signature semble possible.

La démarche compatible proposée est :

1. Retrouver une source complète MDS 1.13 avec inventaire d'origine et comparer
   chaque classe candidate aux surcharges du paquet, pour distinguer MDS des
   autres apports. Ne pas étiqueter l'ensemble de 253 ou 322 classes comme un
   paquet MDS original complet.
2. Préparer des familles cohérentes sans MDS à partir des SFS contrôlés, en
   conservant les modifications indépendantes qui ont été identifiées.
3. Reconstruire les trois classes mixtes sans perdre leurs autres fonctions.
   Pour `Motor`, les seules chaînes Zuti identifiées sont les quatre noms
   `zutiMakeEngineBackup`, `zutiCopyBooleanArray`, `zutiCopyFloatArray`,
   `zutiRestoreMotor` ; leur retrait ciblé avec nettoyage du pool de constantes
   est une piste à vérifier. Pour `Controls`, retirer le traitement MDS du
   largage de fret et ses appels tout en conservant portes, soutes et fonctions
   des appareils. Pour `Explosions`, rétablir les durées de cratères d'origine
   sans supprimer les surcharges nécessaires au correctif nucléaire.
4. Adapter les constructeurs, sources de reconstruction, manifestes, tests et
   interfaces avant toute intégration. Un constructeur AOC exigeant encore les
   méthodes Zuti ne peut pas reconstruire une version sans Zuti.
5. Contrôler en mémoire les références de classes/champs/méthodes de l'ensemble
   effectif, les interfaces publiques nécessaires aux mods conservés et le
   format Java 1.3.1. Tester ensuite une copie isolée : démarrage, mission solo,
   IA, FMB, Spitfire/portes, AOC, armes/nucléaire, navires et réseau. Répéter sur
   chaque profil encore distribué ; l'analyse actuelle est limitée à 4.09m.

Ce travail touche la partie Java du moteur. Il nécessite une reconstruction
et une qualification dédiées ; une suppression de dossiers ne suffit pas.

## Missions, textes et éléments à archiver

Une recherche de `[MDS]`, `ZutiRadar_` ou `ZutiReload_` dans les fichiers `.mis`
de `Missions` et `Files/Sample Missions` relève **86 missions**. Certaines
sections peuvent seulement contenir des réglages inactifs : ce nombre ne
prouve pas que 86 missions seraient impossibles sans MDS. Le tri doit examiner
leurs fonctions, et pas uniquement leur nom. Les cartes `Zuti_Slovenia` et les
mentions de leur auteur ne sont pas, à elles seules, une preuve de dépendance
à MDS 1.13.

Les catalogues d'interface concernés sont notamment
`Files/i18n/bld_ru.properties`, `hud_log_ru.properties` et
`hud_order_ru.properties`. Le HUD a également deux variantes dans le switcher ;
leur contenu et leurs empreintes doivent être adaptés ensemble si leurs
entrées MDS sont retirées. Ne pas supprimer des catalogues entiers qui
contiennent aussi les textes des autres composants.

Voici les chemins non chargés comme classes moteur à **sauvegarder dans
l'archive de retrait**, sans les présenter comme un mod complet. La liste a
été préparée sans suppression. La copie de sauvegarde ensuite autorisée et
effectuée est détaillée à la fin du présent document :

| Chemin exact | Traitement à préparer |
| --- | --- |
| `_Documentations/Mods and Tools/Zuti MDS 1.13/Lisez-moi - Zuti MDS 1.13.txt` | Notice source à conserver avec l'archive. |
| `_Documentations/Mods and Tools/Zuti MDS 1.13/Manuel - Zuti MDS 1.13.pdf` | Manuel source à conserver avec l'archive. |
| `Files/Tools/AirportsExtractor/ZutiAirportsExtractor.jar` | Outil autonome ; archiver avec son lanceur. |
| `Files/Tools/AirportsExtractor/run.bat` | Lanceur de l'outil précédent. |
| `Files/Tools/Mods_Conflicts_Revealer/IL2_ModsConflictsRevealer.jar` | Outil autonome ; archiver avec son lanceur. |
| `Files/Tools/Mods_Conflicts_Revealer/run.bat` | Lanceur de l'outil précédent. |
| `tools/Patch-ZutiTimerClass.ps1` | Correctif dédié devenu inutile après un retrait effectif. |
| `tools/Test-ZutiMDS113.ps1` | Ancien validateur à archiver ; le futur test doit contrôler l'absence effective de MDS. |
| `manifests/mods/zuti-mds-1.13-static.json` | Résultat historique, pas un inventaire de retrait complet. |
| `test-assets/aoc-v1.15/base-zuti/294ABC86A89FAEB4` | Source mixte `FlightModelMain` ; conserver pour provenance jusqu'au remplacement du constructeur. |
| `test-assets/aoc-v1.15/base-zuti/684916A0E86D1CC8` | Source mixte `RealFlightModel`, même réserve. |
| `test-assets/aoc-v1.15/base-zuti/AF5F8A326C3FA53C` | Source mixte `Motor`, même réserve. |
| `docs/AUDIT_ZUTI_AOC.md` | Document mixte : archiver son état historique, conserver/adopter séparément la documentation AOC utile. |
| `tools/Build-OpenSturmovikAocZutiPatch.ps1` | Constructeur mixte à adapter ; ne pas simplement le retirer si AOC reste distribué. |
| `tools/java/OpenSturmovikAocZutiPatcher.java` | Source mixte à adapter avec le constructeur. |

Les donneurs `donor-hsfx4`, `manifests/aoc-v1.15.json`, le constructeur nucléaire
et les journaux historiques ne sont pas exclusivement MDS. Les conserver ou
les adapter selon leur rôle, en gardant l'historique de la provenance. Les
missions de test dédiées et leurs textes doivent être inventoriés avec les
86 missions signalées ; ils ne sont pas assimilés à des fichiers source du
moteur.

## Sources consultées et ressources encore manquantes

Priorité donnée à `D:\Projets\GITHUB\#res\IL2 1946`, à ses dossiers `Mods`,
`Packs` et copies historiques. Aucun `.zip`, `.rar` ou `.7z` dont le nom
contienne MDS ou Zuti n'a été retrouvé dans cette arborescence. Cela n'exclut
pas un module enfoui dans un gros pack ; les volumes complets n'ont pas été
décompressés lors de cet audit. Aucune source standalone complète MDS 1.13
n'a donc été récupérée ou vérifiée ici.

Les documents locaux examinés sont `AUDIT_ZUTI_AOC.md`, le readme MDS 1.13,
`test-assets/aoc-v1.15/README.md`, les manifestes Zuti/AOC, les constructeurs et
validateurs concernés. Leurs affirmations historiques sont distinguées des
mesures nouvelles décrites ci-dessus.

La consultation prioritaire
[AAA via Wayback](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/)
n'a pas abouti : accès refusé par l'outil de consultation, aucun contenu
supposé. Le point d'entrée
[SAS](https://www.sas1946.com/main/index.php?topic=36.60) a également échoué lors
de l'ouverture. La recherche n'a pas retrouvé de paquet original récupérable.

Le [fil Mission4Today d'octobre 2010](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=11021)
mentionne un MDS 1.13 activable par JSGME dans UP2.01. C'est une **piste de
provenance**, pas la preuve que l'on peut désinstaller de la même manière
l'intégration aplatie et fusionnée d'Open Sturmovik. Aucun binaire n'a été
repris de cette source.

## Reproduction

Depuis un dossier de travail sous `C:\Users\Alexis\.codex`, avec Python 3 et
les deux archives dont les empreintes figurent plus haut :

```powershell
python -B 'D:\Projets\GITHUB\IL2-1946-Open-Sturmovik\docs\research\zuti-removal-20260912\analyze.py' `
  --repository-root 'D:\Projets\GITHUB\IL2-1946-Open-Sturmovik' `
  --output 'C:\Users\Alexis\.codex\zuti-removal-verification.json'
```

Seul le fichier `--output` est écrit. Le script n'extrait pas de classe sur
disque, ne réécrit pas de SFS et n'applique aucune suppression. Il lit la table
des constantes et les signatures du ClassFile puis simule la résolution des
membres, avec héritage. Les résultats sont des preuves statiques de présence
et de liaison possible ; ils n'établissent pas l'équivalence fonctionnelle,
la licéité d'une redistribution ni la qualification en jeu.

## Copie de sauvegarde ensuite effectuée

Sur autorisation explicite, **689 fichiers, 7 885 098 octets** ont été copiés
dans :

`D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence\Zuti MDS 1.13\sauvegarde_partielle_20260912`

La sélection comprend les classes de l'inventaire et leurs compagnons ou
appelants concernés, les notices, les sources de reconstruction, les textes
MDS et les 86 missions signalées. Chaque fichier a été sélectionné par son
chemin exact et chaque copie a été comparée à sa source par SHA-256. Aucun
dossier du jeu n'a été copié en bloc et aucun fichier du jeu n'a été retiré.
`INVENTAIRE_SHA256.json` donne les chemins, motifs de sélection, tailles et
empreintes ; `PERIMETRE_SAUVEGARDE.txt` indique explicitement qu'il s'agit d'une
**sauvegarde partielle de classes fusionnées et dépendances**, et que Zuti est
**toujours présent dans le runtime**. Le fichier de contact préparé séparément
par la tâche principale n'a pas été modifié par la copie.

Le rapport d'analyse reproduit depuis son script documenté a retrouvé les
mêmes classes, signatures et résultats. Seuls les chemins des deux archives
sont normalisés vers leur cible canonique `C:\Users\Alexis\DATA\Projets\GITHUB`.
La copie de ce rapport conservée dans la sauvegarde décrit l'état préalable
à cette opération ; le présent paragraphe documente l'opération ultérieure.
