# Audit Zuti MDS 1.13 et Mod AOC Public

Derniere mise a jour : 6 septembre 2026.

Ce document distingue la presence des fichiers, leur chargement reel et les
fonctions qui restent a tester. La cible est Open Sturmovik v1.15 sur IL-2 1946
4.09m. Aucun resultat concernant une version plus recente du jeu ne doit etre
transpose sans nouvel audit.

## Conclusion courte

- Le coeur de **Zuti MDS v1.13 STD** est installe et charge par le jeu. Cette
  version est bien destinee a IL-2 4.08/4.09.
- Les textes d'interface, exemples de missions et deux outils Zuti sont presents.
- La classe `ZutiTimer_ExtendPlanesWings` livree provoquait une
  `ClassCastException`. Une surcharge libre minimale et reversible la corrige ;
  l'essai MDS du 2 septembre n'a produit aucune nouvelle exception Zuti pendant
  plus de dix minutes.
- L'essai runtime valide les bases capturables, les unites mobiles, le retour au
  menu et l'arret du minuteur radar. Le radar joue, les limites d'appareils, le
  R/R/R et la parite serveur/client restent a tester.
- Le chargeur du **Mod AOC Public 1a** s'execute, mais cela ne prouve pas que le
  mod agit sur le modele de vol. L'analyse du bytecode montre au contraire que
  neuf parametres sur dix ne possedent aucun consommateur Java ou natif trouve.
  AOC 1a doit donc etre qualifie avant d'etre conserve.
- Les six navires et les 17 appareils statiques sont maintenant couverts par les
  registres fusionnes. `air.ini` et `stationary.ini` correspondent au profil
  4.09m. Ces corrections sont validees statiquement, mais doivent encore etre
  confirmees par un lancement puis une mission MDS.

## Zuti MDS v1.13

### Version et compatibilite

`_Documentations/Mods and Tools/Zuti MDS 1.13/Lisez-moi - Zuti MDS 1.13.txt`
declare exactement `Version: v1.13`. Il demande :

1. d'extraire le mod dans `MODS` ;
2. de supprimer toutes les anciennes versions MDS ;
3. de fusionner les entrees de `i18n.rar` dans `MODS/STD/i18n` ;
4. d'utiliser le revelateur de conflits en cas d'anomalie.

Ce readme demande aussi explicitement de contacter l'auteur avant d'inclure MDS
dans un pack. Cette mention est conservee dans les notices tierces, mais ne fait
pas partie de la qualification fonctionnelle v1.15 et ne bloque aucun des essais
techniques de ce document.

Open Sturmovik aplatit les ressources dans `Files`, mais le Selector les charge
effectivement : le Dump Mode a restitue les classes Zuti lors du lancement
jusqu'au menu. Le manuel local et sa [copie francaise en ligne](https://manualzilla.com/doc/6503128/zuti-mds-v.1.13--fran%C3%A7ais-)
indiquent explicitement que MDS 1.13 vise IL-2 4.08/4.09. MDS apporte notamment
les unites IA mobiles en dogfight, les bases capturables, les radars, les limites
d'appareils et le rearmement/ravitaillement/reparation. La fonction a ensuite
ete integree au jeu officiel 4.10 ; la [presentation MDS de Mission4Today](https://www.mission4today.com/index.php?kid=715&name=Knowledge_Base&op=show)
decrit cette filiation.

### Activation dans les missions

Zuti est une modification globale du moteur : ses classes sont disponibles tant
que le mod est installe. Il ne convertit cependant pas automatiquement toutes
les missions en missions MDS. Les bases capturables, stocks, limites d'appareils,
radars, objectifs et actions de rearmement/ravitaillement/reparation demandent
des sections et objets MDS dans le fichier de mission.

Une partie de l'initialisation reste globale. La mission rapide standard
`Quick/SlovakiaRedNone00.mis` du 2 septembre a demarre puis arrete
`ZutiTimer_RadarsCountRefresh`, alors qu'elle n'etait pas une mission MDS de
demonstration. Zuti impose donc un petit cout et une surface de compatibilite a
toutes les missions du profil actif, meme lorsque ses fonctions visibles ne sont
pas utilisees. Aucun ralentissement perceptible ni effet de gameplay parasite
n'a cependant ete demontre dans cette mission standard.

En solo, l'interet est reel seulement pour les missions preparees pour MDS :
champ de bataille mobile, bases changeant de camp, radar, ressources et R/R/R.
Une campagne ou mission classique ne devient ni dynamique ni persistante par la
seule presence de Zuti. Le conditionnement recommande est donc de le conserver
dans le profil principal si une campagne de missions classiques confirme sa
neutralite. Une option de desactivation doit rester disponible pour le diagnostic,
les conflits de classes et un profil strictement d'origine ; elle n'a pas besoin
d'etre le choix solo par defaut.

### Composants charges

Le dernier dump contient 30 classes nommees Zuti :

- interface FMB : `PlMission$WZutiMDS`, `Zuti_WManageAircrafts` et ses classes
  internes ;
- jeu : `ZutiAirfieldPoint`, `ZutiTimer_ExtendPlanesWings`,
  `ZutiTimer_RadarsCountRefresh`, `ZutiWeaponsManagement` ;
- ordres : demarrage, cales, changement d'armement, rearmement, ravitaillement,
  reparation moteur/avion et vecteur vers la base la plus proche.

Le Dump Mode prouve le chargement par le moteur ; la simple presence dans le
depot n'aurait pas suffi.

Les fichiers d'interface contiennent aussi les entrees MDS :

| Fichier | Correspondances `Zuti` ou `MDS` |
| --- | ---: |
| `Files/i18n/bld_ru.properties` | 169 |
| `Files/i18n/hud_log_ru.properties` | 36 |
| `Files/i18n/hud_order_ru.properties` | 12 |

Les exemples fournis couvrent la capture rouge/bleu/vert, les radars et les
missions solo, coop et dogfight. Les missions historiques `0_ZutiMDS` sont aussi
presentes. Il faudra ouvrir puis sauvegarder un echantillon dans le FMB et verifier
qu'aucune cle de texte n'apparait brute.

Le validateur `tools/Test-ZutiMDS113.ps1` controle cette structure de facon
reproductible. Son rapport historique du 1er septembre 2026 obtenait **7 PASS,
2 WARN et 0 FAIL** : 30 classes Zuti chargees, 12 points d'accrochage
structurants, textes, missions, outils et correctif `ExtendPlanesWings`
coherents. Le controle v1.15 est maintenant strictement fonctionnel ; il ne
conserve que l'avertissement demandant les essais runtime restants. Le rapport
machine historique est `manifests/mods/zuti-mds-1.13-static.json` et sera
regenere pendant la future validation hors jeu.

L'avertissement runtime de ce rapport statique est maintenant partiellement
leve par l'essai du 2 septembre ci-dessous. Le manifeste n'est pas reecrit a la
main : le validateur devra etre etendu pour integrer une preuve runtime separee.

### Outils presents

| Outil | Taille | SHA-256 | Usage |
| --- | ---: | --- | --- |
| `Files/Tools/AirportsExtractor/ZutiAirportsExtractor.jar` | 42 403 | `792CB85DE0974A9F0480B468C191DD8D847E4E1B96692EAEFF18F1AB676E5C07` | Extraction/controle des terrains |
| `Files/Tools/Mods_Conflicts_Revealer/IL2_ModsConflictsRevealer.jar` | 33 026 | `8DF69D26BF02491155685F6EC958C3C20407CCEA3E4DF18F56EB28F1725D2F90` | Recherche de conflits entre mods |

Ces JAR anciens ne sont pas lances automatiquement. Ils seront testes dans une
copie de laboratoire et non dans le jeu original.

### Correctif du minuteur d'ailes

La classe originale, SHA-256
`7C01D9322D3C9FF2EE8C55399D08B544E006F1C6269012674E28A2F5FFB3D530`,
castait chaque element de `Mission.actors` en `Actor` avant de verifier
`instanceof Aircraft`. Or cette liste contient aussi des `Integer`, ce qui
declenchait periodiquement une `ClassCastException`.

`tools/Patch-ZutiTimerClass.ps1` produit la surcharge :

`Files/com/maddox/il2/game/ZutiTimer_ExtendPlanesWings.class`

Le correctif remplace uniquement le `checkcast Actor` premature par trois `nop`.
Le test `instanceof Aircraft` puis le cast vers `Aircraft` restent en place. La
taille, les offsets et la version Java 45 sont conserves. Empreinte corrigee :

`70E039E839F092346CF8E4F06BA8431C3FF550237C6888D1BAE7B057E22D12C5`

### Minuteurs Zuti et arret de la JVM

Le dump complet du gel au largage de la Fat Man apporte une seconde preuve sur
Zuti. Apres la sortie anormale de la boucle Java principale, HotSpot 1.3.1 reste
bloque dans `DestroyJavaVM` car un `java/util/TimerThread` non daemon est encore
vivant. Sa file contient exactement une tache :

`com/maddox/il2/game/ZutiTimer_RadarsCountRefresh`

Sa periode interne est `-2000` ms, soit une repetition a delai fixe toutes les
deux secondes. Ce minuteur ne constitue pas le declencheur demontre du gel : le
largage fait d'abord sortir la boucle principale, puis le minuteur empeche le
processus de terminer et produit l'`AppHangB1` Windows. Le detail des preuves est
dans [le dossier du bug B-29/Fat Man](BUG_CRITIQUE_B29_FATMAN.md).

La correction Zuti devra garantir un cycle de vie explicite : conserver une
reference sur le `Timer`, annuler la tache lors de la fin de mission et appeler
`cancel()`/`purge()` quand le moteur revient au menu ou se ferme. Transformer
simplement le fil en daemon masquerait l'attente finale, mais ne reparerait ni
une tache qui fuit entre deux missions, ni le declencheur du largage. Aucun
patch de cette classe n'est livre avant validation du scenario A/B.

L'essai du 2 septembre 2026 montre le cycle normal attendu : le minuteur radar
s'est arrete a 18:43:17, le journal Java s'est termine a 18:44:41 et le processus
n'est pas reste bloque dans `DestroyJavaVM`. Windows a toutefois enregistre a
18:44:44 un `APPCRASH` `0xc0000005` dans `combase.dll`. Ce plantage de sortie
existait deja dans plusieurs captures sans cette mission ; il demeure une
anomalie distincte et ne doit pas etre attribue au minuteur Zuti.

### Essai runtime du 2 septembre 2026

La mission de controle est :

`Missions/Single/US/A-20C/Zuti MDS 1.13 - test 10 minutes.mis`

La capture complete est conservee dans :

`WIP/captures/startup/20260902-161718Z-profile9-warm-windowed1024-startup`

Resultats observes et journalises :

- plus de dix minutes de fonctionnement reel, jeu repondant ;
- deux changements de camp de base enregistres et visibles en jeu ;
- navires et unites IA mobiles engages, avec 1 332 evenements de dommages ;
- zero `ClassCastException`, exception Zuti ou erreur `ZutiTimer` pendant la
  mission ;
- echec de l'objectif de bombardement attendu, sans rapport avec la sante de
  Zuti ;
- retour au menu, arret explicite du minuteur radar et liberation d'environ
  140 Mio de memoire de travail ;
- fermeture sans fuite de minuteur, mais avec l'`APPCRASH` de sortie distinct
  decrit ci-dessus.

Verdict : **fonctionnel pour les bases capturables, les unites mobiles et le
cycle de vie teste**. Ce verdict n'etend pas la validation aux fonctions non
exercees.

### Elements absents ou optionnels

- `ZUTI_Friction.pdf` mentionne par la documentation n'a pas ete retrouve.
- Le gestionnaire/moniteur MDS de changement de mission n'a pas ete retrouve.
  Il est optionnel pour le coeur MDS, mais utile au futur profil serveur.
- `$ChangeLog$.doc`, mentionne par le readme, n'a pas ete retrouve.
- Les versions Zuti plus recentes ne sont pas des mises a jour interchangeables.
  La beta 1.2 publiee pour UltraPack 2.01 exige des fichiers serveur/client
  strictement identiques et avertit d'utiliser uniquement UP 2.01 : voir
  [l'annonce Zuti 1.2](https://forum.europeanaf.net/t/zuti-1-2/18249).

### Tests Zuti restant obligatoires

1. Tester le radar en situation de jeu, une limite d'appareils et une action
   R/R/R complete.
2. Tester Essex et Akagi : le manuel MDS les annonce compatibles, alors que
   l'introduction actuelle refuse ces types de navires.
3. Tester un serveur et un client construits depuis le meme manifeste de fichiers.
4. Lancer le revelateur de conflits dans le laboratoire et archiver son rapport.
5. Isoler l'`APPCRASH` de fermeture dans `combase.dll` par un essai A/B sans
   Zuti, puis avec Zuti, sans confondre ce crash natif avec une fuite de minuteur.

## Mod AOC 1a

### Decision v1.15 du 6 septembre 2026

L'ensemble **AOC 1a complet** a ete retrouve dans HSFX 4.0 Part 2. Le paquet
HSFX 4.0 exige explicitement IL-2 4.09m et son option `Advanced Engine
Management` contient les trois classes `FlightModelMain`, `Motor` et
`RealFlightModel`. Son arbre principal fournit 267 profils associes, dont 266
profils d'appareils et `Defaut.txt`.

Cette decouverte corrige la conclusion tiree du petit ensemble local. Celui-ci
contenait bien le chargeur AOC dans `FlightModelMain`, mais les classes `Motor`
et `RealFlightModel` actives etaient celles de Zuti et ne consommaient plus neuf
des dix reglages. AOC 1a n'etait donc pas intrinsèquement incomplet :
l'installation locale avait perdu deux des trois parties du module.

La v1.15 selectionne AOC **V1/1a**, car c'est le premier ensemble complet dont
la compatibilite 4.09m et le contenu ont pu etre verifies. V2a reste documente
mais son paquet n'a pas ete retrouve ; V3a reste un developpement/documentation
sans publication complete recuperee. Le numero de version ne prime pas sur la
compatibilite et la disponibilite reelles.

### Etat initial : chargeur present, effet physique non prouve

`_Game_Enhancements/Mod_AOC_Public/Defaut.txt` definit les valeurs de repli. Le profil specifique
historique `Bf-109G-6Early_AOC_1a.txt`, qui surchargeait notamment le couple,
le regime minimal d'huile et la duree toleree en G negatifs, a ete retire de
nouveau le 6 septembre 2026 apres recuperation du paquet complet, sur decision
du mainteneur. La v1.15 ne livre donc
plus de surcharge AOC propre au Bf-109G-6 Early.

Le fichier sans extension `Files/294ABC86A89FAEB4` est la classe
`com/maddox/il2/fm/FlightModelMain`, taille 40 760 octets, SHA-256
`E3A0842D8A8BAFA37AC32F5AED5F6AAA72A97A4D54C3628964692504B4F647AD`.
Sa methode `load_modData()` :

1. derive le nom `<modele-de-vol>_AOC_1a.txt` ;
2. le cherche dans `Mod_AOC_Public` ;
3. si le fichier existe, lit ses parametres dans un ordre de lignes strict ;
4. sinon, copie `Defaut.txt` puis termine sans appliquer ce profil pendant cette
   construction du modele de vol.

Le lancement de test du 30 aout 2026 a effectivement cree
`Mod_AOC_Public/F4F-3_AOC_1a.txt` dans la copie de test, a 20:11:38. Cette
creation constitue la preuve d'execution du chargeur AOC, pas la preuve d'un
effet sur la physique. Le fichier genere n'est
pas recopie automatiquement dans le depot : il s'agit d'un artefact runtime a
examiner, puis a conserver seulement si une configuration specifique est voulue.

Le 2 septembre 2026, un essai en Bell P-39 Airacobra a cree
`P-39Q-10_AOC_1a.txt`. Son contenu et son empreinte sont identiques a
`Defaut.txt`. Cela confirme une nouvelle fois le chargeur et identifie exactement
le modele de vol P-39Q-10, sans apporter de preuve d'un effet physique. Le meme
chargement a revele une anomalie distincte : les pools
`motor.Allison.start.begin`, `motor.Allison.start.end` et le preset
`motor.Allison_V1700_series` ne se chargent pas. Ce defaut sonore doit etre
corrige avant de prendre le P-39 comme reference A/B pour AOC.

### Parametres effectivement raccordes

La decompilation complete de `FlightModelMain` retrouve les dix champs suivants :

- `coefTorque`, `tempOilMin`, `wOilMin`, `timeMinToStart` ;
- `bInfoTemp`, `timeMaxNegatG`, `bShowAccel`, `coefQualFuel`, `bInfoMotor` ;
- `bSwitchMagnetoOn`.

Les neuf premiers apparaissent seulement dans leur declaration, leur valeur
initiale et `load_modData()`. Aucun autre code de `FlightModelMain` ne les lit.
Une recherche binaire dans toutes les classes libres, le Selector Dump et les
EXE/DLL du projet ne retrouve ces identifiants que dans
`Files/294ABC86A89FAEB4`. Il n'existe donc aucun consommateur Java externe ni
acces natif par nom identifie. En l'etat des preuves, ces neuf reglages sont des
donnees mortes ou une integration incomplete.

`bSwitchMagnetoOn` est le seul reglage dont un effet soit directement visible
dans le bytecode : lorsque sa valeur vaut zero, le chargeur appelle immediatement
`CT.setMagnetoControl(0)` puis `setControlMagneto(0)` sur chaque moteur. Le champ
lui-meme n'est plus lu ensuite.

Cette conclusion corrige la formulation historique « AOC actif ». Le generateur
de profils est actif ; la simulation AOC 1a n'est pas fonctionnellement demontree.

### Profils generes pendant la campagne multicartes

Le dossier reel est directement a la racine du jeu de test :

`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test\Mod_AOC_Public`

Pendant la campagne, il a contenu 13 fichiers, 3 587 octets. Le depot n'en livre
desormais qu'un seul : `Defaut.txt`. Le profil specifique
`Bf-109G-6Early_AOC_1a.txt` a ete retire le 4 septembre 2026. Les onze profils
suivants ont ete crees dans l'ordre des essais entre le 30 aout et le
1er septembre 2026 :

- `F4F-3_AOC_1a.txt` ;
- `B-29SP_AOC_1a.txt` ;
- `HurricaneMkI_AOC_1a.txt` ;
- `TempestMkV_AOC_1a.txt` ;
- `Typhoon1B_AOC_1a.txt` ;
- `SeafireIII_AOC_1a.txt` ;
- `DC-3_AOC_1a.txt` ;
- `BattleMkII_AOC_1a.txt` ;
- `MagM14A_AOC_1a.txt` ;
- `Su-2_AOC_1a.txt` ;
- `Fi-156B-2_AOC_1a.txt`.

Ces onze fichiers ont tous l'empreinte du profil par defaut
`D167FCF83539D299A701359C0CE29C5A0982DC6C0C667B0BCB11B94A12A244CB`.
Ils prouvent que chaque modele de vol concerne est alle jusqu'a
`FlightModelMain.load_modData()`. Ils ne prouvent ni couple accru, ni temperature
d'huile, ni resistance aux G negatifs, puisque les champs correspondants n'ont
pas de consommateur trouve. Le probleme F1/commandes du Su-2 et du B-29 ne peut
pas etre explique par l'absence du chargeur AOC.

Le nom du profil AOC est derive du nom du FMD et non de la cle `air.ini`. Les
classes B-29 et KB-29P demandent toutes deux `FlightModels/B-29.fmd` : elles
partageront donc le futur `B-29_AOC_1a.txt`. Le B-29 Silverplate demande
`FlightModels/B-29SP.fmd` et utilise deja son profil separe
`B-29SP_AOC_1a.txt`. Cette difference devra etre conservee dans la matrice de
retest des trois variantes.

### Choix entre AOC v1, v2 et v3 pour IL-2 4.09m

La version ne sera pas choisie d'apres son numero seul. La cible imposee est
IL-2 **4.09m** et le candidat doit etre complet, reproductible et compatible avec
les classes Zuti deja chargees.

| Ligne AOC | Preuve de compatibilite 4.09m | Etat retrouve | Decision v1.15 |
| --- | --- | --- | --- |
| v1 (`1a`) | HSFX 4.0 exige 4.09m et livre l'option AOC de Lutz ; les trois classes et les profils correspondants ont ete extraits | ensemble complet retrouve : 3 classes et 267 profils | **selectionne**, fusion statique AOC + Zuti terminee ; essai en jeu restant |
| v2 (`2a`) | l'auteur indique en avril 2010 que les effets des G sur le pilote humain fonctionnent deja depuis plusieurs mois dans `2a` ; la documentation communautaire de 55 pages decrit cette ligne 4.09m | documentation identifiee, paquet original pas retrouve | non selectionne faute de paquet complet |
| v3 (`3a`) | le developpement part explicitement de 4.09m et l'export annonce en 2011 est decrit comme reserve a 4.09m, avec certains apports 4.10 retroportes | version interne et demos documentees, mais aucune publication complete recuperee | non selectionne faute de paquet final complet |

Les sources principales sont la
[capture Wayback de l'annonce AOC 1a d'octobre 2008](https://web.archive.org/web/20090217073751id_/http://www.checksix-forums.com/showthread.php?t=147704),
la [publication HSFX 4.0 exigeant IL-2 4.09m et listant Advanced Engine Management](https://mail.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&start=0&t=7663),
le [fil AOC v3A de l'auteur sur CheckSix](https://ts.checksix-fr.com/viewtopic.php?f=322&t=158460),
sa [page 2 consacree aux fonctions v2a/v3a](https://ts.checksix-fr.com/viewtopic.php?f=322&t=158460&start=25)
et la [discussion SAS 4.09 sur l'export AOC 3](https://www.sas1946.com/main/index.php?topic=36.60).
Cette derniere identifie aussi le manuel original AOC v2a de 55 pages a
`http://hist-simu.2jg51.org/Mods/AOCv2a.pdf`. Le site et le PDF ne repondent
plus directement. Une discussion SAS de janvier 2012 renvoie encore vers le
site de Lutz pour la publication promise, sans fournir de lien vers un paquet
complet aujourd'hui recuperable :
`https://www.sas1946.com/main/index.php?topic=20982.0`.
Le document `gunner_EN.pdf`, recupere dans l'archive Common Crawl 2012 du site
Histoire & Simulation, confirme que le module mitrailleurs de v3 est une
extension de mission parametrable ; il ne constitue pas le paquet AOC 3 complet.

Le choix courant est donc **V1/1a issu de HSFX 4.0**. Il ne s'agit pas d'un
melange arbitraire V1/V2/V3 : les donnees et les comportements physiques
proviennent tous du meme paquet AOC 1a. La seule fusion concerne la coexistence
technique avec Zuti MDS 1.13.

L'archive publique `Command_and_Control_409_v3.01m.7z` a aussi ete examinee a
cause de son nom et de sa cible 4.09. Sa documentation l'identifie comme
**Command & Control 4.09 (v3)** par Checkyersix : elle combine des objets de
mission, radars, controle IA et Mission Randomizer, et exige notamment L-5,
Artillery-Mortars et des sous-marins. Ce n'est ni AOC V3 ni un remplacement de
son modele de vol. Ses 729 fichiers sont donc exclus du candidat AOC.

La recherche locale du 6 septembre 2026 a egalement parcouru les noms de
fichiers, les documents et les index d'archives des ensembles AAA Community
Installer 1.1, HSFX 7.0.3, SAS ModAct 6.40, TFM 4.12 et Ultrapack 3.4 Cassie.
L'index des 31 volumes Ultrapack, celui de son Patch 2 et celui de SAS ModAct ne
contiennent ni `Mod_AOC`, ni paquet AOC V2/V3, ni les signatures de configuration
du chargeur 1a. Les seules donnees locales retrouvees restent `Defaut.txt` et
l'ancien profil Bf-109G-6 Early 1a dans l'installation source. Cette absence
n'est pas une incompatibilite prouvee : elle signifie seulement qu'aucun contenu
complet V2/V3 n'est disponible pour une integration reproductible.

Quel que soit le candidat retrouve, l'audit doit :

1. identifier exactement sa version IL-2/ModAct et tous ses fichiers prioritaires ;
2. comparer chaque classe modifiee avec Zuti MDS 1.13 et Open Sturmovik ;
3. separer les fonctions complementaires des doublons (mission, IA, meteo,
   physiologie et modele de vol) ;
4. faire un essai A/B quantifie sur vitesse, couple, chauffe, G negatifs et IA ;
5. ne remplacer le 1a qu'avec un ensemble reproductible et compatible 4.09m.

### Integration AOC 1a + Zuti 1.13

- `FlightModelMain` conserve le chargeur 1a mais lit maintenant
  `_Game_Enhancements/Mod_AOC_Public`. Les donnees restent celles retrouvees
  sous `Files/maps/aoc` dans le paquet HSFX original.
- `Motor` conserve les methodes Zuti `zutiMakeEngineBackup()` et
  `zutiRestoreMotor()`. Les etats de chauffe et de G negatifs ainsi que les
  consommateurs des reglages AOC sont greffes depuis le moteur HSFX.
- `RealFlightModel` conserve le comportement Open Sturmovik et applique
  `coefTorque` aux deux calculs de souffle lateral de l'helice.
- Les interfaces publiques des trois classes sont identiques a celles de la base
  Zuti ; les classes restent en major 45 ou 47.
- Le paquet source contenait 267 profils. La v1.15 en livre 266 tels quels : le
  profil specifique du Bf-109G-6 Early est volontairement exclu afin que le
  chargeur utilise `Defaut.txt`. Aucun profil physique n'est invente.
- Le bytecode et les empreintes passent les controles statiques. Les effets en
  jeu, le multijoueur et le cycle R/R/R restent a valider dans la campagne
  finale.

### Regroupement des ressources AOC termine

Le dossier historique racine `Mod_AOC_Public` et l'ancien emplacement de
travail `Files/maps/aoc` sont retires. Le chargeur lit et cree desormais les
profils sous `_Game_Enhancements/Mod_AOC_Public`, dossier commun impose pour
les composants qui agissent sur le jeu ou en parallele. Les classes actives
restent sous `Files`, emplacement requis par le chargeur de classes libres
d'IL-2 ; elles ne sont pas dupliquees dans le dossier de profils.
Le constructeur reproductible est
`tools/Build-OpenSturmovikAocZutiPatch.ps1`; ses six classes sources controlees
sont sous `test-assets/aoc-v1.15`. Les empreintes, le digest des profils et les
preuves historiques sont dans `manifests/aoc-v1.15.json`.

Cette organisation est un fait de construction propre a Open Sturmovik 1.15,
pas une exigence du format AOC original. Elle est reproductible par le
constructeur, qui remplace les deux constantes de chemin du chargeur puis
verifie leur unicite. Confiance : elevee pour le chemin lu par le bytecode ;
validation en jeu encore requise pour la creation du profil de repli.

## Rapport avec les erreurs actuelles

Le correctif Zuti traite une cause demontree, mais il ne repare pas les donnees de
version melangees. Au moment de cet audit, `air.ini` etait deja celui de 4.09m
alors que le `stationary.ini` actif etait encore celui de 4.08/4.09b. Ce dernier
a ete remplace dans le depot par le profil 4.09m ; le validateur
`tools/Test-OpenSturmovikContent.ps1` empeche desormais ce melange de passer
silencieusement.

Les six navires et les 17 classes statiques etaient des erreurs distinctes de
Zuti. Elles sont desormais traitees par deux operations reproductibles : fusion
des 78 extensions communautaires dans le `chief.ini` officiel 4.09m, et union
des enregistrements `SPAWN` dans `Plane.class` sans changer Java major 47. Le
validateur controle les empreintes et les compteurs. Seul le prochain test peut
encore prouver que les classes effectives chargees et `Buttons` forment bien le
meme ensemble runtime.
