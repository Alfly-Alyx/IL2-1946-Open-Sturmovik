# Suivi differe - anomalies appareils v1.15

Derniere mise a jour : 3 septembre 2026.

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

Aucun fichier de licence ou readme n'accompagne le paquet AAA local. La page SAS
publique fournit encore le paquet original, mais ne formule pas de licence de
redistribution explicite ; ce point doit rester mentionne dans l'inventaire de
provenance.

### Suite attendue

La cause immediate n'est plus a chercher dans `air.ini`. Le prochain essai doit :

- resynchroniser transactionnellement les deux ressources restaurees ;
- placer le Su-2 comme appareil `Player` ;
- verifier F1, les commandes, le poste mitrailleur et l'armement ;
- confirmer l'absence de `RuntimeException` et de nouvelle ressource manquante
  dans le journal.

## KB-29P

### Resultat runtime

Le KB-29P est absent de la liste de Mission rapide (QMB). Cette observation est
distincte de celle du CW-21, effectuee dans l'Editeur de mission complet (FMB).

### Elements deja prouves

- `air.ini` contient deja la ligne
  `KB_29P air.KB_29P 1 NOINFO usa01 SUMMER` : ne pas ajouter de doublon ;
- `Buttons` contient `FlightModels/B-29.fmd`, partage avec le B-29 ;
- l'audit statique de `air.KB_29P` trouve zero cockpit enregistre.

L'absence de cockpit constitue donc la piste prioritaire pour l'exposition QMB,
mais elle ne dispense pas de verifier separement la presence du KB-29P dans le
FMB avant de conclure sur l'ensemble de son enregistrement.

### Piste de correction

Verifier la propriete `cockpitClass` et la compatibilite exacte entre le KB-29P
et le cockpit B-29. Une reutilisation n'est acceptable qu'apres verification
des postes, du modele 3D, des instruments, des tourelles et des descripteurs JVM.

Si une surcharge Java est necessaire :

- compiler en Java major 47 ;
- conserver l'API de la classe 4.09m ;
- controler les conflits avec les classes B-29 et Silverplate ;
- valider l'apparition et le pilotage dans Mission rapide puis dans le Full
  Mission Builder ;
- ne modifier la copie de test qu'apres la fin de la session V1.15 active.

## Curtiss-Wright CW-21

### Resultat runtime

Le CW-21 est absent de la liste de l'Editeur de mission complet. Le defaut se
situe donc en amont d'un simple choix de cockpit dans la Mission rapide.

### Elements deja prouves

- `air.ini` contient deja
  `CW-21 air.CW_21 1 NOINFO du01 SUMMER` : ne pas ajouter de doublon ;
- aucune entree CW-21 ou Curtiss-Wright n'a ete trouvee dans les fichiers
  `Files/i18n/plane*.properties` audites ;
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
