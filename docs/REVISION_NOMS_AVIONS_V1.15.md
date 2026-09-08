# Revision finale des noms d'avions — v1.15

Revision du 7 septembre 2026. Cette passe termine la revue de presentation
des 535 entrees actives ; elle ne certifie pas historiquement la physique de
chaque mod. Aucun avion, moteur, profil joueur ou armement n'est modifie ici.

## Regle demandee par Alexis

Concepteur d'origine, designation du modele et variante, puis surnom si utile.
Les abreviations deja choisies restent : N.A, V.S, Me, FW, DH, Yak, MiG.
Pas de fabricant sous licence ajoute dans les noms, faute de place.
Les noms nationaux complets restent valables : Mustang Mk.III/Mk.IV,
Tomahawk, Martlet et Corsair avec leur Mark ne sont pas arbitrairement
transformes en designations americaines.

FM-2, TBM et Avenger III restent sous Grumman ; Corsair IV sous Vought.
La meme convention de classement rattache Li-2 et L2D a Douglas, P.24E a
PZL et Go-229 a Horten. Ce prefixe editorial indique la filiation de
conception, pas l'entreprise qui a fabrique chaque exemplaire.
Les designations nationales Li-2/L2D ne sont pas remplacees par C-47.
Macchi remplace l'abreviation anachronique/incomplete AerMacchi.

Les seuls deplacements de familles sont Li-2 apres les C-47, L2D sous Douglas
dans le groupe Axe, et Macchi apres Letov (apres Kawasaki en 4.08 qui n'a
pas S-328). Les sequences d'evolution des autres familles restent identiques.
Allies, Axe puis les 15 avions des as sont conserves. Pour les as : prenom,
nom, modele ; leurs valeurs et leur ordre ne changent pas.

## Resultat et sauvegarde

- 188 libelles corriges, 535 entrees actives revues ; un libelle Tu-4 hors
  air.ini reste conserve sans integration d'avion.
- Comptes avant/apres : actif 535/535, 4.08 516/516, 4.09 535/535.
- Chaque ligne technique complete est identique avant/apres, seul son
  emplacement peut changer. Aucun identifiant, classe, pays ou drapeau change.
- Les dates presentes, meme discutables historiquement, restent identiques.
  Cette passe ne redate pas les mods.
- Fins de lignes CRLF et encodage historique ASCII/echappements Unicode
  conserves ; aucune nouvelle cle de traduction ni doublon.
- Le switcher ne change que ses deux empreintes d'integrite des air.ini.

Sauvegarde verifiee avant modification :
`D:\Projets\GITHUB\#res\IL2 1946\Sauvegarde_avant_revision_noms_v1.15_20260907`.
Elle contient les trois air.ini, les noms affiches, le switcher et le manifeste
de presentation. Les empreintes avant/apres et les 535 comparaisons sont dans
`manifests/aircraft/name-review-v1.15.json`. Le manifeste courant faisant
autorite reste `manifests/aircraft/presentation-v1.15.json`.
Les anciens rapports de tri et de correction BI restent des traces historiques.

Exemples : `N.A P-51D-20-NA Mustang`, `Curtiss Model 75A-3 Hawk`,
`Brewster F2A-2 Buffalo`, `DH.98 Mosquito B.Mk.XVI`, `Grumman Martlet Mk.II`,
`Morane-Saulnier MS.406`. Le surnom Warhawk n'est pas applique au Bell P-400.
Les suffixes mod non elucides sont conserves, et non maquilles en blocs officiels.

## Verification Early / Late : 27 cas

`Early`/`Late` est un descripteur de configuration dans ces listes, pas une
designation officielle universelle. Le guide exact du jeu peut confirmer
une serie tout en imposant de conserver Early/Late pour distinguer ses deux
configurations. Aucune conversion automatique Early -> premiere serie ou
Late -> nouveau bloc n'est appliquee.

| Entrees examinees | Decision et niveau de preuve |
| --- | --- |
| G-55 et G-55-Late | Guide_409m p.12 : tous deux Serie I. Le Late leve une limitation du moteur, sans changer de serie. Ajout de Serie I et maintien Early/Late. Fait documentaire explicite, confiance elevee. |
| DXXI_SARJA3_EARLY / LATE | Guide_409m pp.13-14 : tous deux Sarja 3 ; le Late recoit reservoir auto-obturant et siege mieux blinde. Ne pas le transformer en Sarja 4. Fait documentaire explicite. |
| Il-2_1940_Early / Late, Il-2_1941_Early | Les libelles AAA locaux distinguent deja Series 1/2/3. Conservation de ce classement du jeu ; pas de nouvelle certification des lots sovietiques. |
| Il-2_1941_Late | Les ressources le nomment modification de terrain. Description conservee, pas de Series 4 inventee. |
| Il-2M_Early / Late | First/later series dans les ressources et Aircraft Guide. Pas de numero de serie supplementaire etabli. |
| F6F-3 | AAA et Aircraft Guide pp.36-37 donnent F6F-3 Late ; aucun bloc numerote etabli. Ce n'est pas une justification pour le renommer F6F-5. |
| P-38L_Late | Aircraft Guide pp.127-130 distingue deux puissances annoncees sous P-38L. Aucun lien exact etabli vers L-1 ou L-5. Late conserve. |
| P-47D | Libelle AAA D-27-Late et reference locale P-47D-27_late.fmd ; distinct du D-27 standard. Conserver D-27 Late, sans inventer un D-30. |
| HurricaneMkIearly / HurricaneMkILate | Les sources locales restent Mk.I. La campagne M4T decrit la premiere configuration a ailes entoilees/helice bipale, mais pas un nouveau Mark pour ces classes. Distinction conservee. |
| TyphoonMkIBLate | Le fil M4T de 2009 et la ressource locale utilisent Mk.IB Late. Pas d'autre Mark etabli pour ce mod ; normalisation en Mk.Ib Late seulement. |
| Fw-190D-9_Late / Late_DZZMod | Les libelles 1944/1945 distinguent deja les versions sous D-9, avec conservation du suffixe d'armement. Aucun D-10 invente. |
| Bf-109G-6_Late | Aircraft Guide pp.318-320 distingue explicitement G-6 Late et G-6AS. Late conserve, pas de substitution /AS ou G-14. |
| Il-4_Late, La-5F_Early, Yak-1B_Early, Yak-7B_late, Yak-9M_Early, Yak-9U_Early | Classes et references locales examinees ; inventaires communautaires recherches. Aucun numero officiel correspondant exactement aux mods etabli. Early/Late conserve. |
| IAR80early | Contradiction partielle : classe IAR_80A/FMD IAR-80A, mais mesh IAR80early et libelles OS1.1/SAS Early. L'ancien dump declare quatre points d'armes. Pas de renommage en 80A sur le seul nom de classe. |
| Bf-109E-1_Late | Conflit non resolu : cle/libelle local Late, classe BF_109E1early et inventaire SAS Early, ressources E-4. Conservation du nom local en attendant identification certaine ; ce n'est pas une confirmation historique du Late. |

Les deux derniers conflits restent visibles dans le rapport, pas classes comme
resolus. Leur resolution demanderait l'origine exacte du mod ou un examen
plus poussé, pas le remplacement par un nom simplement plausible.

## Observations locales reproductibles — limites de retro-ingenierie

La table `resourceObservations` du rapport indique pour chaque fichier sa
classe, sa version Java, son SHA-256, ses references de modele 3D et de FMD,
et surtout son origine : fichier libre actuel `Files/<hash>` ou ancien dump
4.09m dans `WIP/labs/IL 2 Sturmovik 1946 Selector Dump/dump`.
Ce sont des lectures de constantes, pas des essais d'execution ou une
validation du modele de vol. Un ancien dump ne prouve pas le contenu SFS
actuellement charge ; une reference a un mesh ne prouve pas un bloc de serie.

Methode : cle air.ini -> nom de classe qualifie ; adresse libre calculee par
`Finger.Int('sdw' + classe + 'cwc2w9e')`, puis `Finger.Long('cod/' + adresse)`
(fonctions deja documentees dans les outils d'analyse). Priorite au fichier
libre, repli explicite sur l'ancien dump. Lecture CAFEBABE/constant pool avec
`Audit-AirIniAircraft.py`, sans decompression ni reecriture de Buttons.

Constats utiles, confiance elevee sur les octets lus, pas sur leur historicite :

- P_51D et P_51D2 libres pointent vers des meshes D-20NA et D-5NT mais le meme
  P-51D.fmd. Les noms des deux mods restent explicites : pas de faux bloc D-2.
- F84G1 et F84F1 libres referencent He-162C.fmd, tandis que F84G3 reference
  F84G.fmd. Les identifiants G1/G3 restent identifies comme mods, pas blocs.
  Aucun fichier physique ou effet d'arme n'est modifie par cette revue.
- MARTLETMKII libre reference MartletMkII.fmd et un mesh F4F-4 : l'ancien
  prefixe F4F-3A du libelle n'est pas conserve comme une equivalence certaine.
- MOSQUITO16 et SEAGLADIATOR2 libres identifient B.Mk.XVI et Sea Gladiator Mk.II.
- HE_162B dans l'ancien dump reference He-162B, pas He-162D ; JU_52_3MG4E
  libre reference g4e, pas g7e. Corrections d'identite locale, pas de datation.
- KI_46_OTSU et KI_46_OTSUHEI libres partagent un FMD IIIKai mais pointent vers
  des meshes Otsu / Otsu-Hei distincts : les suffixes ne doivent pas etre omis.
- XF9F6 libre identifie un mesh XF9F6 mais emploie F9F2.fmd. La designation
  historique XF9F-6 existe ; sa fidelite dans ce mod n'est pas certifiee.
  `javap` sur l'ancien dump XF9F6 echoue avec fin de fichier inattendue.
  Cette erreur ne doit pas etre generalisee au fichier libre actuel.
- P_80A du dump reference P-80A.fmd. Le guide et SAS emploient aussi YP-80
  pour ce slot, contrairement a l'ancien libelle local F-80. La nouvelle
  presentation P-80A indique l'identite locale ; l'attribution exacte
  prototype/serie reste explicitement incertaine, distincte du slot F-80A.
- Les observations Early/Late incluent des reemplois : Yak-7B_late -> Yak-9.fmd,
  HurricaneMkILate -> HurricaneMkIaT.fmd ; BF_109E1early -> Bf-109E-4.fmd.
  Ces exemples interdisent de deduire automatiquement une designation du FMD.

Pour reproduire la revue sans appliquer de changements :

```powershell
python tools/Review-AircraftNames.py --backup-root 'D:/Projets/GITHUB/#res/IL2 1946/Sauvegarde_avant_revision_noms_v1.15_20260907'
```

Le script exige racine/branche v1.15 et empreintes de sauvegarde exactes.
Il refuse un changement concurrent des fichiers. `--apply` applique uniquement
les produits annonces et actualise les deux manifestes de presentation.
Ne pas rejouer les anciens builders de tri pour appliquer cette nouvelle passe.

Les lectures ponctuelles du dump sont reproductibles avec :

```powershell
javap -classpath 'WIP/labs/IL 2 Sturmovik 1946 Selector Dump/dump' -c com.maddox.il2.objects.air.IAR_80A
javap -classpath 'WIP/labs/IL 2 Sturmovik 1946 Selector Dump/dump' -c com.maddox.il2.objects.air.BF_109E1early
```

Leurs observations sur quatre points d'armes (IAR) et references E-4/armes
MG17/MGFFk (Bf-109) concernent ce dump seulement. Aucun armement charge en jeu
n'est deduit de ces seules instructions, notamment depuis le diagnostic
du chargement tardif des armes CW-21.

## Sources effectivement consultees

Priorite aux ressources locales sous `D:\Projets\GITHUB\#res\IL2 1946` :

- `0 - ORIGINAL GAMES DO NOT USE/IL2-1946-Open-Sturmovik _1.1/Files/i18n/plane_ru.properties` ;
- `Packs/AAA_Community_Installer_ver_1_1/MODS/STD/i18n/plane_ru.properties`
  et la copie `files/i18n/plane_ru.properties` du meme paquet ;
- `0 - ORIGINAL GAMES DO NOT USE/Il-2 Sturmovik 1946 _4.09m/Guide_409m.pdf`,
  pp.9, 12-15 : series Avia, Fiat et Fokker ; pages Fiat/Fokker aussi rendues
  et inspectees visuellement suivant la competence PDF ;
- `Aircraft Guide.pdf` du meme dossier, pages precisees dans le tableau :
  nomenclature du guide et valeurs annoncees, pas nouvelle mesure physique ;
- recherche dans les documentations des paquets et sources de mods : aucun
  document retrouve etablissant un numero de bloc precis pour les cas reserves ;
- `objects408.pdf` inspecte puis ecarte : catalogue d'objets, pas une source
  de designation des variantes d'avions.

AAA/Wayback a ete tente en premier :
[capture demandee autour de 2010](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/).
Acces en echec ; aucun contenu de la page n'est suppose. Le paquet AAA local
reste utilisable independamment de l'accessibilite de son ancien forum.

Recoupement communautaire, sans telecharger ni remplacer un air.ini :
[inventaire SAS](https://www.sas1946.com/main/index.php?topic=12281.60),
[fil SAS d'origine de l'inventaire](https://www.sas1946.com/main/index.php?topic=12281.0),
[portage Mustang UI1.2 de 2009](https://www.sas1946.com/main/index.php?topic=2728.0),
[M4T, integration Typhoon en 2009](https://www.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&printertopic=1&start=60&t=7876),
[M4T, configurations du Hurricane](https://www.mission4today.com/index.php?file=details&id=1520&name=Downloads3).
Les inventaires confirment des noms/cles de mods, pas leur certification
historique. La campagne Hurricane a ete mise a jour pour BAT : aucune de ses
ressources n'est importee ou presumee compatible 4.09m.

Recoupement des noms historiques et filiations :

- [Variantes du P-51](https://en.wikipedia.org/wiki/North_American_P-51_Mustang_variants) : noms RAF et blocs US distincts.
- [Military Aviation Museum, Hawk 75](https://www.militaryaviationmuseum.org/aircraft/curtiss-hawk-75a-6/) : famille Model 75 ; [fonds Curtiss du Smithsonian](https://sirismm.si.edu/EADpdfs/NASM.XXXX.0067.pdf), extraits indexes : Model 81A-2, sans equivalence P-40C inventee.
- [US Navy, FM-2](https://www.history.navy.mil/content/history/museums/nnam/explore/collections/aircraft/f/fm-2-wildcat--quarterdeck-.html) : filiation Grumman et construction General Motors, prefixe retenu selon le choix d'Alexis.
- [Corsair](https://en.wikipedia.org/wiki/Vought_F4U_Corsair) : Mark IV britannique et construction Goodyear ; maintien Vought comme concepteur.
- [DC-3](https://en.wikipedia.org/wiki/Douglas_DC-3) et [musee de Szolnok, Li-2](https://www.repulomuzeum.hu/Leltar/Leltarfotok/Li-2.htm) : filiation des versions sous licence Li-2/L2D.
- [Smithsonian, Horten](https://airandspace.si.edu/collection-objects/horten-ho-229-v3/nasm_A19600324000) : conception Horten, contrat industriel Gotha.
- [Smithsonian, Macchi C.202](https://airandspace.si.edu/collection-objects/aeronautica-macchi-c202-folgore/nasm_A19600332000) et [Aeronautica Militare](https://www.aeronautica.difesa.it/en/2023/05/26/mc-202/) : Macchi et C.202/MC.202 ; harmonisation C.200/C.202/C.205.
- [US Navy, F9F](https://www.history.navy.mil/content/history/museums/nmusn/explore/photography/aircraft-us/aircraft-usn-f/f9f-panther.html) et [registre naval](https://www.history.navy.mil/content/dam/nhhc/research/histories/naval-aviation/pdf/APP09.PDF), extraits indexes : Panther/Cougar et existence XF9F-6.

Limites d'acces complementaires : page Museum of Flight du manuel Avenger III
refusee (403), ancien lien direct US Navy P-40B inaccessible ; leurs titres
indexes seuls ne servent pas a prouver une variante du mod. Aucune source
inaccessible n'est declaree lue integralement.

## Validation restant a faire en jeu

Controles executes apres application :

- `tools/Test-AircraftNameReview.py` : 11 tests PASS, comprenant les comptes,
  les lignes techniques, dates, descripteurs, as, encodage, families et empreintes.
  La 4.08 conserve ses 14 as, la 4.09 ses 15 (Sarvanto/D.XXI en plus).
- `tools/Test-V115OfflineReadiness.ps1 -RepositoryRoot <racine>` : 6 PASS,
  0 WARN, 0 FAIL. Cela inclut neuf profils du switcher, deux HUD et dix
  raccourcis sur Bureau temporaire, pas sur le Bureau d'Alexis.
- Contenu du depot : 25 PASS, 1 WARN (nouveau dump absent), 0 FAIL.
- Synchronisation transactionnelle des cinq fichiers runtime vers
  `WIP/test-installations/IL 2 Sturmovik 1946 test`, plan
  `manifests/test/aircraft-name-review-v1.15.json`, empreintes toutes conformes.
  Sauvegarde recuperable : `WIP/test-installations/sync-20260907-063226`.
- Contenu de test : 24 PASS, 1 WARN, 1 FAIL connu conserve explicitement :
  cinq profils AOC dans la copie de test contre 266 dans le paquet. Aucun
  profil AOC ou joueur n'est copie, supprime ou modifie par cette passe.

Le premier appel du controle global sans argument a echoue sur son chemin
par defaut vide dans cet environnement PowerShell ; il a ete relance avec
la racine explicite et a passe. Le premier test nouveau supposait a tort
15 as en 4.08 aussi ; corrige en 14/15 apres comparaison de la sauvegarde,
sans ajout ou suppression d'entree pour satisfaire le test.

La revue de fichiers ne valide pas la largeur visible des noms ni la liste
affichee dans chaque menu. Lors de la prochaine session demandee par Alexis :
verifier les familles et leurs variantes, les designations RAF/US, les deux
G.55 Serie I, les Fokker Sarja 3 Early/Late, les as en dernier et les noms
de mods restes distincts. Ne pas tester de nouveau les nuages/titre deja
valides, sauf regression. Aucun jeu n'est lance par cette passe.

## Retour visuel du 8 septembre : largeur de la liste QMBPlus

**Observation reproductible, confiance elevee :** la capture d'Alexis montre
que les libelles longs sont affiches au-dela du bord droit du champ `Avion`.
Les valeurs completes existent toujours dans `plane_ru.properties` ; il ne
s'agit donc pas d'une troncature des donnees a 26 caracteres.

La classe active `GUIQuick$DialogClient`, fichier libre
`Files/92B0367AF05311B4`, est identique octet pour octet a la copie du dump et
porte le SHA-256
`D3357FB21D130AF754F659AEB92DE7063805FE4F883AF9D5D3B7E05E38D28514`.
Sa methode `setPosSize()` fixe les huit listes d'avions a `x=318`, largeur
`274`, dans le repere 1024 du jeu. Les listes d'armement commencent a `x=609`
et ont une largeur de `332`. Ces constantes expliquent le rendu observe.

**Deduction, confiance elevee :** la zone des avions peut etre elargie, mais
cela exige de modifier la classe d'interface et de redistribuer l'espace avec
la colonne d'armement ; un changement de traduction seul ne peut pas corriger
le probleme. Aucun bytecode n'est modifie par cette constatation. Il reste a
choisir et tester des dimensions qui conservent le bouton d'armement et les
autres commandes visibles dans toutes les resolutions prises en charge.

Reproduction :

```powershell
Get-FileHash -Algorithm SHA256 Files/92B0367AF05311B4
javap -classpath 'WIP/labs/IL 2 Sturmovik 1946 Selector Dump/dump' -c 'com.maddox.il2.gui.GUIQuick$DialogClient'
```
