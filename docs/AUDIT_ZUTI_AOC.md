# Audit Zuti MDS 1.13 et Mod AOC Public

Derniere mise a jour : 31 aout 2026.

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
  elle doit encore etre validee pendant au moins dix minutes au menu puis dans
  une mission MDS.
- Le **Mod AOC Public 1a** est actif. Le code qui lit ses fichiers est present
  dans `FlightModelMain` et un lancement a deja cree automatiquement le fichier
  AOC du F4F-3 dans le jeu de test.
- Les six navires et les 17 appareils statiques sont maintenant couverts par les
  registres fusionnes. `air.ini` et `stationary.ini` correspondent au profil
  4.09m. Ces corrections sont validees statiquement, mais doivent encore etre
  confirmees par un lancement puis une mission MDS.

## Zuti MDS v1.13

### Version et compatibilite

`Files/$ReadMe$.txt` declare exactement `Version: v1.13`. Il demande :

1. d'extraire le mod dans `MODS` ;
2. de supprimer toutes les anciennes versions MDS ;
3. de fusionner les entrees de `i18n.rar` dans `MODS/STD/i18n` ;
4. d'utiliser le revelateur de conflits en cas d'anomalie.

Open Sturmovik aplatit les ressources dans `Files`, mais le Selector les charge
effectivement : le Dump Mode a restitue les classes Zuti lors du lancement
jusqu'au menu. Le manuel local et sa [copie francaise en ligne](https://manualzilla.com/doc/6503128/zuti-mds-v.1.13--fran%C3%A7ais-)
indiquent explicitement que MDS 1.13 vise IL-2 4.08/4.09. MDS apporte notamment
les unites IA mobiles en dogfight, les bases capturables, les radars, les limites
d'appareils et le rearmement/ravitaillement/reparation. La fonction a ensuite
ete integree au jeu officiel 4.10 ; la [presentation MDS de Mission4Today](https://www.mission4today.com/index.php?kid=715&name=Knowledge_Base&op=show)
decrit cette filiation.

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

1. Demarrer sans introduction et rester au menu au moins dix minutes : aucune
   nouvelle exception du minuteur.
2. Charger une mission MDS fournie et verifier les unites IA mobiles.
3. Tester une base capturable, un radar, une limite d'appareils et une action R/R/R.
4. Tester Essex et Akagi : le manuel MDS les annonce compatibles, alors que
   l'introduction actuelle refuse ces types de navires.
5. Tester un serveur et un client construits depuis le meme manifeste de fichiers.
6. Lancer le revelateur de conflits dans le laboratoire et archiver son rapport.

## Mod AOC Public 1a

### Fonctionnement prouve

`Mod_AOC_Public/Defaut.txt` definit les valeurs de repli. Le fichier
`Bf-109G-6Early_AOC_1a.txt` surcharge notamment le couple, le regime minimal
d'huile et la duree toleree en G negatifs.

Le fichier sans extension `Files/294ABC86A89FAEB4` est la classe
`com/maddox/il2/fm/FlightModelMain`, taille 40 760 octets, SHA-256
`E3A0842D8A8BAFA37AC32F5AED5F6AAA72A97A4D54C3628964692504B4F647AD`.
Sa methode `load_modData()` :

1. derive le nom `<modele-de-vol>_AOC_1a.txt` ;
2. le cherche dans `Mod_AOC_Public` ;
3. copie `Defaut.txt` vers ce nouveau nom si aucun reglage specifique n'existe ;
4. charge ensuite les parametres AOC.

Le lancement de test du 30 aout 2026 a effectivement cree
`Mod_AOC_Public/F4F-3_AOC_1a.txt` dans la copie de test, a 20:11:38. Cette
creation constitue la preuve d'activation du code AOC. Le fichier genere n'est
pas recopie automatiquement dans le depot : il s'agit d'un artefact runtime a
examiner, puis a conserver seulement si une configuration specifique est voulue.

### Risques et decisions v1.15

- La creation au premier acces ajoute une ecriture disque, faible mais a mesurer.
- Les fichiers specifiques generes peuvent diverger entre installations et entre
  client et serveur. Le lanceur devra proposer une politique reproductible.
- Les valeurs AOC modifient le comportement moteur ; elles doivent faire partie du
  manifeste de gameplay et non d'un simple profil graphique.
- Pour la v1.15, le mod reste actif. On conserve `Defaut.txt` et le reglage
  historique du Bf-109G-6 Early, puis on teste au moins un appareil avec repli et
  un avec surcharge specifique.

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
