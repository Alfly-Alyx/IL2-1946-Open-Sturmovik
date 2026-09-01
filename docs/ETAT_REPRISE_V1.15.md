# Etat de reprise technique de la version 1.15

Derniere mise a jour : 1er septembre 2026, apres la campagne multicartes.

Ce document est le point d'entree d'une nouvelle session de travail. Il separe
les faits observes, les causes demontrees, les corrections appliquees et les
hypotheses encore a verifier. Il doit etre mis a jour apres chaque correction ou
test important.

## Etat le plus recent : nuages bloques, charge IA stable, sons a corriger

La campagne complete est documentee dans
`RESULTATS_CAMPAGNE_MULTICARTES_2026-09-01.md`. Les traces sont dans
`test-results/startup/20260901-131015Z-profile9-warm-windowed1024-startup`.

Le nouveau bloquant principal est le moteur de nuages meteo : Slovakia et
Smolensk produisent des triangles/pics blancs, des volumes traversant le sol et
21 `RuntimeException` dans `EffClouds.PreRender`. Le `conf.ini` teste utilise
`TypeClouds=1`. La prochaine action sure est un A/B strict sur Smolensk avec
`TypeClouds=1`, puis `0`, puis un profil 4.09m stock. Ne pas confondre ce defaut
avec les panaches nucleaires : il apparait aussi sans bombe.

Le Su-2 de Berlin n'a pas ete affecte comme appareil joueur : `F2/F3`
fonctionnaient, mais pas `F1` ni les commandes. Trois `NullPointerException` de
`AircraftHotKeys$14.begin` ont ete declenchees sans appareil joueur valide.
L'audit statique montre pourtant un `SPAWN`, `FlightModels/Su-2.fmd` et trois
cockpits presents ; le profil `Su-2_AOC_1a.txt` a ete genere en vol. Le diagnostic
IA-only est donc abandonne au profit d'un retest de selection/affectation joueur.
Le meme symptome a ete observe sur un B-29 : tester separement B-29, B-29SP et
KB-29P, car leurs classes, FMD et cockpits ne sont pas identiques.

L'audit automatise couvre maintenant les 535 lignes uniques de `air.ini` : 535
classes d'appareil presentes, aucune classe de cockpit referencee absente et
aucune classe Java au-dessus de 47. Il trouve 516 declarations pilotables
directes, un candidat herite et 18 appareils probablement IA-only. Le doublon
exact `CW-21` a ete retire. Les deux anciennes variantes Sea Hurricane ont des
cles `Legacy` distinctes et leurs libelles i18n existent. Les ensembles AAA
authentiques TBF-1C, TBM-3 et MiG-3 Pokryshkin ont ete restaures dans `Files`,
sans encore declarer leurs FMD verifies dans `Buttons`. Les rapports sont
`AUDIT_APPAREILS_AIR_INI.md`, `AUDIT_AAA_COCKPITS_V1.15.md` et
`AUDIT_BUTTONS_MODELES_DE_VOL.md`.

Le stress Smolensk nuageux avec 16 B-29/Fat Man et 16 P-39D a produit plusieurs
largages et impacts sans ralentissement perceptible. Pendant le combat, zero des
898 echantillons processus etait non repondant. Pics : 852,3 Mio physiques,
720 Mio prives, 0,97 coeur CPU equivalent, environ 56,6 % du moteur GPU 3D et
178,6 Mio de memoire GPU validee. Ce resultat ne qualifie ni 1080p60, ni les
quatre coeurs, ni Windows x86.

Le meme stress a revele un preset `motor.Allison_V1700_series` invalide, 32
sample pools Allison de demarrage absents et 33 `FileNotFoundException`. Les
anciens presets sonores ne sont donc pas encore propres pour les P-39D en grand
nombre.

## Bombes nucleaires : chaine statique saine, rendu encore bloque

La session instrumentee
`test-results/startup/20260901-060621Z-profile9-warm-windowed1024-startup`
atteint la mission B-29 + Little Boy, reproduit deux fois le rattrapage visuel
apres pause et se termine volontairement sans exception Java nouvelle. Le
panache developpe a `06:12:28.621Z` est reduit a une petite sphere sur la
premiere image de reprise a `06:12:31.298Z`, puis retrouve un volume comparable
vers `06:12:36.785Z`. CPU, disque et memoire restent stables.

Le code du menu gele correctement `Time`, mais ne transmet pas cet etat a la
methode protegee `Eff3D.pause(boolean)` du moteur natif. Un premier candidat a
enregistre uniquement les emetteurs nucleaires, surveille la transition toutes
les 25 ms et propage la pause native par reflexion.

La campagne `20260901-131015Z-profile9-warm-windowed1024-startup` a maintenant
invalide ce candidat : Little Boy repart encore de zero apres pause/reprise. Le
meme redemarrage visuel survient apres un demi-tour qui retire puis remet le
panache dans le champ. Le probleme est donc lie au cycle rendu/culling des
particules, pas seulement a l'horloge de pause. Aucun message d'echec de la
reflexion n'est journalise : l'appel natif ne suffit simplement pas.

Les trois classes modifiees ont ete deployees dans le dossier de test, sans
lancer le jeu. Leur sauvegarde est :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260901-083925`

L'audit nucleaire dedie retourne 33 PASS et zero echec statique. Les douze
classes Java major 47, les deux `BombGun`, les deux emports du B-29SP, les huit
effets et tous leurs materiaux sont coherents. La sortie reste toutefois bloquee
par le rendu : le surveillant 25 ms n'a aucun benefice visuel prouve, les
`Eff3DActor` initiaux n'ont pas encore une duree de retention explicitement
bornee, et le nuage stabilise est place trop bas par rapport aux 40 000-50 000
pieds documentes. Voir `AUDIT_BOMBES_NUCLEAIRES_V1.15.md` et
`manifests/effects/nuclear-static-audit-v1.15.json`.

Fat Man a termine sa mission sans gel pendant la meme campagne. Le stress de
16 B-29/Fat Man a egalement termine sans ralentissement en vol perceptible, mais
il ne mesure pas encore le nombre d'acteurs d'effets retenus. Les airbursts sur
l'eau, l'eclair image par image et l'autorite multijoueur restent a tester.
Toujours prevenir Alexis avant capture et lancement.

Une anomalie distincte de cette mission est maintenant corrigee statiquement.
La surcharge libre `Files/Maps/Slovakia/load.ini` demandait l'ancien nom
`actors.static`, absent de la base 4.09m. La lecture directe de `fb_maps15.SFS`
a retrouve la ressource officielle `maps/slovakia/actors_summer.static`,
5 824 549 octets, SHA-256
`AB5980161F5B517A371B75E1F6721283826615A732A6043AD21CD7A7AED70A47`.
Le `load.ini` officiel 4.09m la demande aussi sous ce nom. Seule cette ligne a
donc ete corrigee ; le gros fichier reste dans le SFS et n'est pas duplique.
La version precedente du `load.ini` du dossier de test est sauvegardee dans
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260901-085130`.
Le prochain test doit confirmer zero `DAMAGED`, `FAILED` et
`FileNotFoundException` pour la carte Slovakia.

Decisions confirmees par Alexis : Little Boy et Fat Man ne sont que le premier
banc du correctif de pause. A terme, toute explosion de bombe, tout incendie et
toute fumee reproduisant le defaut devra etre prise en charge. La qualification
sur un Windows 32 bits reel est imperative pour l'objectif v1.15 ; le plafond
theorique x86 ne remplacera pas une campagne CPU/GPU/pilote/4GT mesuree.

## Perimetre et regles de securite

- Depot de travail reel :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik`.
- `D:\Projets\GITHUB\IL2-1946-Open-Sturmovik` est un lien vers ce depot.
- Jeu original de reference :
  `C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946`. Ne jamais le modifier.
- Jeu de test : `C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`.
- Laboratoire Selector Dump :
  `C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 Selector Dump`.
- Ressources en lecture seule sauf accord explicite :
  `D:\Projets\GITHUB\res\IL2 1946`.
- Les mods historiques retrouves doivent aller dans
  `D:\Projets\GITHUB\res\IL2 1946\Mods`.
- Toujours prevenir Alexis avant de lancer le jeu ou une capture.
- La cible de la v1.15 reste IL-2 1946 4.09m modde. Le portage 4.15.1m est un
  chantier separe.

## Dernier test de reference

Le dernier lancement complet est conserve dans :

`test-results/startup/20260830-201020Z-selector-dump-cold-windowed1024-startup`

Le jeu a atteint le menu principal. Le Selector a extrait 10 201 ressources,
soit environ 604,2 Mio. Le temps mesure, fortement ralenti par l'instrumentation
et le Dump Mode, est de 209,9 secondes ; le menu est apparu vers 178,9 secondes.
Le pic de memoire est d'environ 907,2 Mio en working set et 1 598,8 Mio en
memoire privee. Le fichier a lire en premier est `logs/log.lst`.

L'introduction etait encore active (`Intro=1`). Les pourcentages observes
pendant ce test appartiennent donc en partie au chargement de la mission
d'introduction et ne constituent pas encore une cartographie pure du demarrage.

## Priorites immediates et etat prouve

| Priorite | Etat | Fait etabli ou prochaine action sure |
| --- | --- | --- |
| `Bf-109G-2/WheelTire.mat` | Corrige statiquement | Le fichier nul a ete remplace par un materiau texte coherent utilisant `../TEXTURES/wheels.tga`. Empreinte active `BA1D8713D743CBE4FA75E0702837B36B46988EA98BFECFBD7C3D41D419179EEB`. Le prochain lancement doit confirmer le prechargement du `hier.him`. |
| `ZutiTimer_ExtendPlanesWings` | Corrige statiquement | Le `checkcast Actor` premature a ete neutralise sans changer la taille ni la version Java 45. Empreinte active `70E039E839F092346CF8E4F06BA8431C3FF550237C6888D1BAE7B057E22D12C5`. Il reste le test de dix minutes et le test en mission MDS. |
| 17 appareils sans spawner | Corrige statiquement | `Plane.class` a ete reconstruit par union bytecode reproductible : 343 enregistrements `SPAWN`, Java major 47, empreinte `FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059`. Le Dump puis une mission doivent confirmer zero `No spawner`. |
| Six navires refuses | Corrige statiquement | Le `chief.ini` actif fusionne 426 sections 4.09m et 78 extensions communautaires, sans doublon, dont les six types refuses. Empreinte `14E9D0CE1C3B991FF3C43D9643F4744439126F690B3E294BA27EF1B18786AD8D`. Validation runtime encore requise. |
| Presets sonores | Valides au second demarrage | Les 26 collisions de noms ont ete supprimees. Les petits presets SAS refuses ont ete remplaces par dix mixeurs complets Tiger33 4.09m et leurs WAV, avec manifeste d'empreintes. Le second lancement a confirme zero `Invalid preset format` jusqu'au menu ; l'ecoute en vol reste a faire. |
| Trois WAV absents | References corrigees | Les anciens noms introuvables ne sont plus demandes : Allison utilise `Allison_tb_XX_Starter.wav`, MG FF exterieur `MG_FFx.wav` et cockpit `MG_FF.wav`. Les deux MG FF sont actuellement identiques au niveau binaire, ce qui rend la substitution conservative. |
| 28 `FileNotFoundException` | 28 attribuees et corrections preparees | 26 venaient des presets Sakae/P&W ; une de l'introduction defectueuse ; la derniere de `AirportCarrier.clsBigArrestorPlane` quand `TBM1.class` demandait deux maillages inexistants. La classe TBM-1 pointe maintenant vers les `hier.him` Multi1 et USA confirmes dans `fb_3do08p.SFS`, empreinte `BFAC0C3D60CB49DB6D857362196B79305E9D4AE5665E06146E8C30D374374C6B`. |
| Introduction | Desactivee pour la v1.15 | `Intro=0` dans le profil de test evite la piste defectueuse, ses erreurs reseau et sa `NumberFormatException`. La piste est conservee pour analyse/reparation ulterieure, mais ne bloque plus le demarrage normal. |
| 63 `Str2FloatClamp` au demarrage | Corrige statiquement | Les neuf bornes affichees par le moteur ont ete appliquees a tout le contenu libre : 179 valeurs dans 168 effets. Une surcharge corrige l'effet restant dans `files.SFS` sans repaqueter l'archive. Le rendu runtime est conserve puisque le moteur utilisait deja ces valeurs bridees. |
| `air.ini` / `stationary.ini` / `Buttons` | Ensemble statique coherent | `air.ini` et `stationary.ini` actifs correspondent aux references 4.09m du selecteur ; `Buttons` est present et le registre `Plane.class` couvre les classes dumppees. Une mission representative reste obligatoire pour prouver la correspondance des modeles de vol. |

### Les 17 classes d'appareils non enregistrees

`CW_21`, `DXXI_DK`, `DXXI_DU`, `I_15BIS`, `I_15BIS_SKIS`, `I_16TYPE5`,
`I_16TYPE5_SKIS`, `I_16TYPE6`, `I_16TYPE6_SKIS`, `AVIA_B534`,
`DXXI_SARJA3_EARLY`, `DXXI_SARJA3_LATE`, `DXXI_SARJA4`, `G_55`, `RE_2000`,
`LetovS_328`, `SM79i`.

### Les six navires refuses par l'introduction

`USSEssexCV9`, `IJNAkagiCV`, `IJNKageroDD41`, `IJNAkizukiDD42`,
`USSIndianapolisCA35`, `USSFletcherDD445`.

## Ressources et outils deja retrouves

Le dossier `D:\Projets\GITHUB\res\IL2 1946\Outils` contient notamment :

- SFS Extractor V3.1 ;
- SFS Manager V4.1 ;
- SFS Packer/SFSA V1.1.0.1 ;
- NTRK Wizard pour Buttons 4.10 ;
- IL-2 Extractor de SAS~Storebror, compatible avec les SFS dits `benito` ;
- Universal `static.ini` Checker V1.3 ;
- Actors Tool V1.5.

Ne pas executer aveuglement ces anciens binaires dans le jeu original. Les
extraire et lire leurs instructions dans un laboratoire ou un dossier temporaire
avant usage.

Pages historiques deja recuperees :

- [AAA Unified Installer v1.0, archive du 7 janvier 2009](https://web.archive.org/web/20090107030230/http://allaircraftarcade.com/forum/viewtopic.php?t=7688)
- [AAA 4.09b1m mod patch/switcher, archive du 1er janvier 2008](https://web.archive.org/web/20080101055533/http://allaircraftarcade.com/forum/viewtopic.php?t=1932)

Le fichier de collection
`C:\Users\Alexis\Downloads\32372-IL-2-Complete-Edition.zip` n'est pas le jeu
complet. Il fait 57 397 462 octets, contient 1 068 entrees (environ 120,8 Mio
decompressees) et a pour SHA-256
`9A0717E9AA721A25DA14DC88BF3D2A6A04BDB9DD79ABC862FF0C5D518293DCA9`.
Il fournit des presets sonores historiques de compatibilite SAS Buttons, mais
pas les trois WAV absents, le materiau du Bf-109G-2 ni la classe Zuti corrigee.

## Ordre de reprise recommande

1. Conserver le resultat courant : 15 `PASS`, zero `FAIL`; le seul `WARN` exige
   un Dump runtime. Les 45 controles de disponibilite passent dans la copie.
2. Trois passages corriges ont atteint le menu : environ 130,7 secondes lors de
   la reference, 171,5 secondes avec 78 % de charge CPU systeme moyenne, puis
   94,4 secondes avec 34 % de charge moyenne et un cache chaud.
   Utiliser `RESULTATS_TESTS_DEMARRAGE_2026-08-31.md` comme reference.
3. Prevenir Alexis, armer la capture, puis lancer le jeu seulement apres
   l'affichage `CAPTURE_ARMEE`.
4. La correction `LandGeom=2` confirme zero reecriture de `conf.ini`. Les deux
   lignes Perfect sont l'avis attendu du detecteur 4.09m lorsque l'ancienne
   extension `GL_NV_texture_shader` manque ; utiliser le rapport graphique
   automatique plutot qu'une nouvelle matrice de profils.
5. Comparer automatiquement `log.lst`, `sound.log`, le Dump et les acces fichiers
   au test de reference.
6. Si le demarrage est propre, preparer le scenario de bug critique en vol, puis
   charger une mission minimale avec TBM-1, les 17
   appareils statiques et les six navires, puis valider `Buttons`/modeles de vol.

## Definition de termine pour cette passe

- zero erreur de materiau Bf-109G-2 ;
- zero exception Zuti durant au moins dix minutes puis en mission ;
- zero `No spawner` ;
- zero `Wrong chief's type` dans une introduction reparee ou une mission de test ;
- zero collision effective de preset son ;
- chaque fichier audio demande existe ;
- chaque `FileNotFoundException` est supprimee ou documentee comme repli
  volontaire prouve ;
- `air.ini`, `stationary.ini`, `Plane.class`, `Ship.class` et `Buttons` proviennent
  d'un ensemble de version coherent et reproductible.

## Controle statique reproductible

Lancer depuis la racine du depot :

```powershell
.\tools\Test-OpenSturmovikContent.ps1
```

Au 31 aout 2026, le resultat sans Dump est **15 PASS, 1 WARN, 0 FAIL**. Le WARN
ne signale pas une anomalie de contenu : il rappelle que les classes effectives
du jeu ne peuvent etre prouvees qu'avec `-DumpRoot` apres la prochaine capture.

La preparation exacte de cette prochaine capture et la synchronisation
transactionnelle sont consignees dans
[`PREPARATION_PROCHAIN_TEST_V1.15.md`](PREPARATION_PROCHAIN_TEST_V1.15.md).
Les synchronisations ont ete appliquees avec des sauvegardes recuperables. Les
trois demarrages ont atteint le menu sans crash ; les deux derniers ont valide
les presets Tiger33. Le troisieme a atteint le menu en 94,4 secondes et conserve
`conf.ini` octet pour octet. Les 45 controles de disponibilite passent. Les
deux lignes Perfect ont ete expliquees hors jeu par l'absence de
`GL_NV_texture_shader` sur Intel et sont desormais classees automatiquement.
