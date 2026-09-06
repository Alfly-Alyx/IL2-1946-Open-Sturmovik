# Suivi differe - anomalies appareils v1.15

Derniere mise a jour : 6 septembre 2026.

## Regles communes

Ces controles doivent reprendre apres la session V1.15 active et uniquement
sur une copie de test liberee. Ils restent separes des bombes lourdes, du cycle
nucleaire et des essais de chargement des textures.

## Su-2

### Resultat runtime du 3 septembre

Le Su-2 reste non pilotable et la touche F1 ne permet pas d'entrer dans son
cockpit. Le journal reproduit deux fois l'erreur suivante :

`3DO/Cockpit/Il-10-TGun/TGunnerSU2.him` est absent, puis l'initialisation du
poste se termine par une `RuntimeException`.

La session initiale est conservee sous :

`WIP/captures/startup/20260902-180643Z-profile9-warm-windowed1024-startup`

### Recuperation du paquet source

Le paquet historique complet a ete retrouve dans la source AAA locale conservee
en lecture seule :

`C:\Users\Alexis\Downloads\AAA_Community_Installer_ver_1_1\MODS\SU_2`

Cette provenance est corroborree par la discussion SAS « Su-2 flyable mod ? » :
le Su-2 est un appareil IA du jeu et ce paquet ajoute les cockpits qui le rendent
pilotable, sans nouvelle ligne `air.ini` :
<https://www.sas1946.com/main/index.php?topic=56027.0>.

Le paquet contient huit classes Java et quatre ressources. Les huit classes sont
deja presentes dans Open-Sturmovik avec des empreintes strictement identiques.
`CockpitSU2.him` et `BombardierSU2.him` etaient egalement identiques au paquet.
Seuls les deux fichiers du poste arriere avaient ete omis et ont ete restaures :

| Ressource | Octets | SHA-256 |
| --- | ---: | --- |
| `Files/3do/Cockpit/Il-10-TGun/TGunnerSU2.him` | 1 430 | `01AB4D134F3542DA4D4E90763CFFC12C6F3CBE81FA0EEB1EC8A3ED8F3A1D452C` |
| `Files/3do/Cockpit/Il-10-TGun/skin1o.tga` | 3 145 772 | `28EEDA2E4DBEE0AB976CC8F5C426517A2706AD86E772CFA68469E20AEADC98E2` |

Le nom exact du HIM est aussi connu du dictionnaire SFS Extractor 3.1 sous
l'adresse `DA7BC7F91490F7BD`. Il n'est present dans aucun SFS officiel local :
il appartient donc bien au cockpit communautaire. La texture AAA est un TGA
non compresse de 1 024 x 1 024 en 24 bits. La ressource homonyme officielle
retrouvee dans `fb_3do16.SFS` ne fait que 21 octets (image 1 x 1) et ne remplace
pas la texture fournie par le mod.

### Suite attendue

La cause immediate n'est plus a chercher dans `air.ini`. Le prochain essai doit :

- resynchroniser transactionnellement les deux ressources restaurees ;
- placer le Su-2 comme appareil `Player` ;
- verifier F1, les commandes, le poste mitrailleur et l'armement ;
- confirmer l'absence de `RuntimeException` et de nouvelle ressource manquante
  dans le journal.

## KB-29P

### Correction hors jeu du 6 septembre 2026

La ligne `air.ini` reste unique. La surcharge est maintenant placee a
l'adresse canonique `Files/2083079EF880398E`. L'ancien fichier concurrent
`Files/com/maddox/il2/objects/air/KB_29P.class` est retire de la copie de test
avec sauvegarde recuperable. La classe ajoute la propriete requise pour
l'exposition comme appareil pilote :
`cockpitClass=com.maddox.il2.objects.air.CockpitB29`.

Ce choix n'est pas un cockpit arbitraire : le KB-29P et le B-29 demandent deja
le meme `FlightModels/B-29.fmd`, le maillage du ravitailleur derive du B-29 et
le cockpit pilote ainsi que son maillage sont presents dans le payload 4.09m.
Les six postes bombardier/mitrailleurs du B-29 ne sont volontairement pas
greffes au ravitailleur, dont l'armement et le role sont differents.

### Resultat runtime

Alexis signale l'absence du KB-29P dans la liste d'avions de l'editeur. Les
anciennes consignes melangeaient Mission simple, constructeur rapide et
editeur complet : ne pas transformer cette confusion en fait observe. Le
nouveau candidat reste a tester dans la liste effectivement utilisee.

### Elements deja prouves

- `air.ini` contient deja la ligne
  `KB_29P air.KB_29P 1 NOINFO usa01 SUMMER` : ne pas ajouter de doublon ;
- `Buttons` contient `FlightModels/B-29.fmd`, partage avec le B-29 ;
- la classe source `air.KB_29P` ne declarait aucun cockpit ; la surcharge
  conserve Java major 47 et n'ajoute que le cockpit pilote B-29 ;
- le constructeur reproductible et les empreintes sont fixes dans
  `manifests/aircraft/kb29p-qmb-v1.15.json`.

L'absence de cockpit constitue donc la piste prioritaire pour l'exposition QMB,
mais elle ne dispense pas de verifier separement la presence du KB-29P dans le
FMB avant de conclure sur l'ensemble de son enregistrement.

### Validation differee

La campagne finale doit confirmer l'apparition dans Mission rapide, l'entree au
poste pilote, les quatre moteurs et instruments, les commandes, le ravitaillement
et la sortie de mission. Elle doit aussi verifier que les B-29 standard et
Silverplate conservent leurs propres listes de postes.

## Curtiss-Wright CW-21

### Candidat integre le 6 septembre 2026

Le cockpit authentique du port 4.09 fourni par Alexis est integre apres audit
des dependances : quatre classes du cockpit, 165 ressources et la classe
CW_21 d'origine adaptee. Deux armements sont proposes dans le meme avion :
4 x .303 (par defaut) ou 2 x .303 + 2 x .50. Le choix sans armement reste
disponible. Modele de vol, classe mere et marquages initiaux sont conserves.
Voir `CW21_COCKPIT_ARMAMENT_V1.15.md` pour les sources, les limites et le
protocole. Les points ci-dessous decrivent le diagnostic anterieur ; aucune
apparition dans l'editeur ni aucun vol de ce candidat n'est encore confirme.

### Etat du 5 septembre 2026

Le registre `Plane.class` corrige contient deja le `SPAWN` statique du CW-21 et
`air.ini` ne contient plus qu'une seule entree. Le libelle
`Curtiss-Wright CW-21` a ete ajoute a `Files/i18n/plane_ru.properties` puis
synchronise dans la copie de test. L'apparition dans le FMB doit maintenant
etre confirmee en jeu avant toute autre modification de la classe.

### Resultat runtime

Alexis signale le CW-21 absent de la liste d'avions de l'editeur. Le type exact
de liste doit etre constate lors du prochain essai, sans deduire que le defaut
est forcement independant du cockpit.

### Elements deja prouves

- `air.ini` contient deja
  `CW-21 air.CW_21 1 NOINFO du01 SUMMER` : ne pas ajouter de doublon ;
- le libelle est maintenant present dans `Files/i18n/plane_ru.properties` ;
- la nationalite declaree par le registre est `du01` et doit etre documentee.

### Correction attendue

1. Verifier que l'entree `air.ini` est effectivement lue, resolue vers
   `air.CW_21` et conservee dans le registre actif.
2. Auditer l'initialisation statique de la classe, son enregistrement `SPAWN`
   et toute exception pouvant interrompre son chargement.
3. Verifier la localisation et les filtres de nation ou d'armee utilises pour
   construire la liste du Full Mission Builder.
4. Auditer les proprietes statiques de `air.CW_21` pour determiner si un
   cockpit est enregistre.
5. Identifier un cockpit CW-21 authentique ou un cockpit historiquement et
   techniquement compatible pouvant etre restaure. Ne pas reutiliser un
   cockpit seulement parce qu'il permet a la classe de demarrer.
6. Corriger l'exposition comme appareil pilotable uniquement apres validation
   des instruments, angles de vue, armes et modele 3D.
7. Ajouter les libelles localises avec le constructeur en premier et le nom
   cible `Curtiss-Wright CW-21`.
8. Valider d'abord l'apparition et le placement dans le Full Mission Builder,
   puis `Player` et l'entree en cockpit. Terminer par la Mission rapide, les commandes,
   armement, vue externe et absence d'erreur de ressource.

Le controle de nomenclature `constructeur + modele` devra ensuite etre applique
a tous les appareils corriges afin d'eviter les libelles techniques ou
incoherents dans les listes du jeu.

## Ensembles historiques AAA : TBF-1C, TBM-3 et MiG-3 Pokryshkin

### Resultat runtime initial

Pendant la session
`WIP/captures/startup/20260902-180643Z-profile9-warm-windowed1024-startup`, les
trois appareils annonces comme restaures restent absents de l'Editeur de
mission complet :

- `Grumman TBF-1C Avenger, 1943` ;
- `Grumman TBM-3 Avenger, 1943` ;
- `Pokryshkin MiG-3`.

Le TBM-1 visible dans la meme liste sert de temoin positif.

### Validation runtime du 3 septembre

Apres resynchronisation des fichiers restaures, les trois appareils sont
maintenant presents dans l'Editeur de mission complet et pilotables avec leur
cockpit :

- TBF-1C : valide ;
- TBM-3 : valide ;
- MiG-3 Pokryshkin : valide.

L'anomalie d'exposition est donc fermee. Les controles de comportement en vol,
d'armement et des postes mitrailleurs restent des validations fonctionnelles
distinctes si elles n'ont pas encore ete executees en detail.

### Cause etablie

La capture designe comme racine active
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`. Cette copie contient le bon
`air.ini`, mais elle n'a pas recu les 25 fichiers de la restauration AAA deja
presents et valides dans le depot :

- les quatorze classes TBF-1C/TBM-3 sont absentes de son dossier `Files` ;
- les dix ressources de cockpit et de maillage TBF-1C/TBM-3 sont absentes ;
- `Files/1E712A4C231E010A`, classe `MIG_3POKRYSHKIN`, y est encore l'ancienne
  version de 3 512 octets, SHA-256
  `F1C50CA4993D71FDFEB2033202DF31FF46A52DF70B03864FDF49263C031A5E05` ;
- le depot contient la version restauree de 4 654 octets, SHA-256
  `291CFFEED118604303165ACAD51DB33B32864E9140D73348CE82F4A0D20B5D9A`.

La classe MiG-3 encore chargeable dans la copie de test enregistre bien un
`SPAWN`, un maillage et un FMD, mais ne definit pas `cockpitClass`. La version
restauree ajoute explicitement `CockpitMIG_3`. Les classes TBF-1C et TBM-3 du
depot enregistrent leur `SPAWN`, leurs maillages, leur FMD et trois postes de
cockpit chacune, mais elles ne peuvent pas etre chargees puisqu'elles sont
absentes de la copie lancee.

Le journal actif de cette session est limite a 8 192 octets et ne contient
aucune exception nommant ces classes. Le `preexisting-logs/log.lst` conserve
dans la capture appartient a une session terminee plus tot et ne permet pas de
diagnostiquer cette absence. L'ecart de contenu suffit toutefois a expliquer le
resultat runtime sans modifier la copie pendant la capture.

### Remise en coherence appliquee

La copie de test a ete resynchronisee avec les fichiers restaures. La presence
dans le Full Mission Builder, le mode `Player` et l'entree dans le cockpit ont
ete verifies le 3 septembre. Le controle de preparation doit continuer a
verifier les quatorze classes, les dix ressources et l'empreinte de la classe
MiG-3, et ne pas se limiter a `air.ini` et `Plane.class`.

## Chaine sonore Allison des P-39

### Correction hors jeu du 6 septembre 2026

Le journal historique signalait trois echecs lies : les deux presets de
demarrage `motor.Allison`, puis le repli `motor.Allison_V1700_series` rejete
comme invalide. La chaine est maintenant completee a partir de la famille
Allison deja presente :

- les quatre presets de demarrage `motor.Allison` et `motor.Allison_tb` sont
  complets et utilisent les enregistrements Starter/Startup existants ;
- le mixeur `motor.Allison_V1700_series.prs` fournit le nom de repli demande par
  le moteur ;
- `xallison_1001.wav`, couche exterieure a bas regime absente du depot, a ete
  restauree depuis la source historique Open Sturmovik 1.1/AAA correspondante ;
- le libelle du bloc exterieur `xAllison_1001` etait errone dans le preset
  historique et dupliquait le bloc interieur `Allison_1001`. Il est corrige
  dans le mixeur de base et dans son alias runtime.

Les empreintes et l'origine technique sont consignees dans
`manifests/audio/allison-v1.15.json`. Aucun enregistrement moteur n'a ete
fabrique ou remplace par un son d'une autre famille.

### Validation differee

Le prochain essai P-39 doit couvrir le demarrage, le ralenti vu du cockpit et
de l'exterieur, la transition jusqu'au plein regime, la reduction et l'arret.
Le journal ne doit plus contenir `Cannot load sample pool` ni
`Invalid preset format` pour la famille Allison.
