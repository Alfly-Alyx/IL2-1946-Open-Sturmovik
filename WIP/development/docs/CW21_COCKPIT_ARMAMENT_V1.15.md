# CW-21 : cockpit et choix d'armement pour 4.09m

6 septembre 2026. Installation hors jeu ; validation visuelle et en vol encore
requise. Demande d'Alexis : proposer les deux armements dans le meme avion.

## Actualisation du 12 septembre 2026 : retrait de MDS

L'override global `Aircraft` fusionne avec MDS a ete retire. Le chargeur effectif
vient maintenant du `files.SFS` du profil ; son SHA-256 est
`079760CADF85DA3CB26856C0D5B541EBC51E017A450F1648B27426D8E00D7BE3`, identique
dans les trois profils 4.08m, 4.09b et 4.09m. Les six classes du correctif CW-21
et les 165 ressources de cockpit conservent leurs empreintes.

Le contrat `TestCW21Loadouts` a ete execute avec le CW-21 et son helper actifs,
puis l'Aircraft stock extrait de chacun des trois SFS : trois PASS, choix
uniques, quatre emplacements, armes/munitions exactes et imports tardifs repetes.
Ce resultat porte sur le chargeur et utilise des doubles d'API/entrees ; il
ne prouve pas la disponibilite de tout le cockpit dans les anciens profils.
L'audit complet de l'installateur pour **4.09m** donne aussi PASS : six classes,
165 ressources, aucune dependance manquante, aucune ecriture dans le jeu.

`Install-CW21Cockpit.py` resout desormais les classes absentes de `Files`
dans le SFS 4.09m dont l'empreinte est imposee, avant le dump complementaire.
L'Aircraft extraite pour le contrat reste dans `build`, jamais dans `Files`.
Le manifeste cockpit indique sa nouvelle origine SFS. Reproduction et recus :
`docs/research/zuti-family-reconstruction-20260912/test-cw21-stock.py`,
`cw21-stock-contract.json` et `RECONSTRUCTION_MOTEUR_SANS_MDS_V1.15_20260912.md`.
Les paragraphes suivants conservent les observations historiques precedant ce retrait.

## Source et compatibilite

Source prioritaire : `D:\Projets\GITHUB\#res\IL2 1946\Mods\Utilisés\Cockpit_CW-21_for409.zip`,
identique au fichier fourni dans Telechargements. SHA-256 :
`CB6FC40E2ACEFC8F479B00AC5E07FCFAF400633B3882B155AFE7736C6C451DB3`.

[Publication SAS par Epervier, 25 novembre 2015](https://www.sas1946.com/main/index.php?topic=49201.0) :
conversion de cockpit pour « Rebels 409 », credits Team Daidalos.
L'archive contient un dossier nomme `04__Cockpit_CW-21_4.101`, mais le fichier
publie est bien `for409`. Ce nom seul n'est pas une preuve de compatibilite :
l'audit compare les classes et leurs dependances a la base effective 4.09m.
AAA/Wayback n'a pas ete accessible pendant la recherche. Les paquets AAA
locaux ne fournissaient pas ce cockpit complet ; les notes officielles 4.09
de Mission4Today listent encore le CW-21 parmi les appareils IA.

## Integration exacte (faits verifies, confiance elevee)

- Quatre classes du cockpit et 165 ressources sont copiees a l'identique de
  l'archive. Aucun maillage ni aucune texture n'est invente.
- La classe CW_21 4.09m d'origine, SHA-256
  `AB31568D9645B8F665B24262162920B3B01FD8057A024DF9A0230513D9210C65`,
  recoit la propriete `cockpitClass` et l'armement alternatif demande.
- Les classes CW_21 et CW21xyz de l'archive ne sont pas recopiees en bloc :
  la classe mere, le modele de vol `FlightModels/CW-21.fmd`, les marquages
  neerlandais, les degats et l'armement initial du jeu sont conserves.
- Les classes du candidat sont en major Java 45/47. Les references de classes,
  champs et methodes sont resolues dans les surcharges libres effectives,
  les classes 4.09m du dump et le Java 1.3 livre. Aucun membre manquant ni
  doublon incompatible n'a ete trouve. Les textures referencees sont presentes.
- Les classes anciennes sans rapport avec le cockpit ne sont indexees que
  par leur identite ; leurs attributs non standards ne sont pas qualifies par
  cet audit. Chaque dependance reellement utilisee est analysee completement.

## Armements proposes

| Choix dans le menu | Configuration interne | Origine |
| --- | --- | --- |
| 4 x .303 (7,7 mm) | 4 MGunBrowning303ki, 300 coups chacune | Configuration initiale 4.09m conservee |
| 2 x .303 + 2 x .50 (12,7 mm) | 2 MGunBrowning303ki, 300 coups ; 2 MGunBrowning50si, 230 coups | Variante du port 4.09 ; mitrailleuses legeres alignees sur celles deja utilisees par le jeu |
| Sans armement | Aucun | Choix initial conserve |

Le [guide officiel IL-2 4.10, page 15](https://simhq.net/_air/PDF/IL-2_guide_v410.pdf)
mentionne les deux combinaisons pour le CW-21B. Cette source justifie les
options du simulateur ; elle ne prouve ni leur equipement sur chaque avion
historique, ni les dotations exactes en cartouches. Les sources historiques
consultees divergent sur les livraisons neerlandaises et sur .30/.303. Les
quantites utilisees ici proviennent du jeu/port source, pas d'une invention.
Le guide 4.10 n'est pas utilise comme preuve de compatibilite binaire 4.09m.

## Reproduction et test restant

`tools/Install-CW21Cockpit.py` construit la classe a partir du dump 4.09m,
verifie le contenu de l'archive et toutes les dependances, puis n'installe
qu'avec `--apply`. Le resultat et les empreintes sont dans
`manifests/aircraft/cw21-cockpit-v1.15.json`.

Dans l'editeur, selectionner `Curtiss-Wright CW-21`, verifier les deux
libelles d'armement, charger chaque option et tirer une courte rafale.
Verifier vue cockpit, instruments, visibilite, train, verriere et retour au
menu. L'option sans armement doit rester disponible. Aucun essai n'est
considere reussi avant le retour utilisateur et l'examen du nouveau journal.

## Diagnostic apres le premier vol : option absente (6 septembre 2026)

**Retour utilisateur :** cockpit fonctionnel, mais seul l'armement 4 x .303
apparait. Le moteur est audible, moins fort que ceux des autres avions.

**Cause verifiee de l'armement, confiance elevee :** la methode
`Aircraft.weaponsRegister(Class, String, String[])` du fichier effectif
`Files/4B598398AD1D180C` ne contient que l'instruction Java `return` (`B1`).
Le precedent correctif CW-21 (`8B97C4067A78619DD19023806AF8A6CE7F736CBE3ED756922DE6071688F4FF2B`)
appelait cette methode vide. Le controle des signatures avait passe, mais ne
verifiait pas son effet. C'etait une insuffisance de notre premier correctif.
La [documentation SAS AircraftTools](https://www.sas1946.com/downloads/essentialsas/common_utils/doc/com/maddox/sas1946/il2/util/AircraftTools.html)
confirme cette particularite ; aucune bibliotheque SAS recente n'est ajoutee.

Le code effectif lit les choix dans `weaponsList` et les tableaux de slots
dans `weaponsMap`, indexes par `Finger.Int(nom)`. Le port local for409 construit
directement ces deux proprietes. La nouvelle adaptation applique ce contrat
au seul CW-21, avec trois choix ordonnes : `default`, `2x303_2x50`, `none`.
Chaque tableau contient quatre slots, comme les quatre points d'armes du
CW-21 d'origine. Les mitrailleuses legeres et les dotations sont inchangees.
Le moteur global `Aircraft`, le fichier Buttons et le modele de vol ne sont
pas modifies. L'ancien correctif est sauvegarde dans
`build/preservation/cw21-before-direct-registration/F00C363EBB3865E8`.

**Controle reproductible hors jeu :** `tools/java/TestCW21Loadouts.java`
execute la methode emise dans la classe candidate avec des doubles minimaux
de Property, Finger, HashMapInt et WeaponSlot. Il controle ordre, nombre,
coherence liste/table, calibres, munitions, absence d'armes pour `none`, puis
repete l'enregistrement. Ce test ne simule ni le chargeur natif, ni les tirs.
Le constructeur `tools/Install-CW21Cockpit.py` verifie separement les vraies
signatures de l'API effective 4.09m, la classe Java 47 et la methode vide
responsable de l'ancien echec. Les essais en jeu restent distincts.

## Diagnostic du volume : observation instrumentee, pas de gain arbitraire

Le constructeur du cockpit fourni ne contient pas de reglage du volume moteur.
Dans la classe MotorSound du dump 4.09m, les noms des presets proviennent de
`Motor.soundName`, `startStopName` et `propName`. Le Motor effectif
`Files/AF5F8A326C3FA53C` lit ces valeurs dans les sections Generic puis le
sous-modele moteur. La simple presence d'un preset Wright dans Files ne prouve
donc pas son utilisation par le CW-21.

Les anciens `sound.log` et `log.lst` ne journalisent pas ces trois valeurs.
Le nouvel `onAircraftLoaded` du CW-21 appelle d'abord le traitement herite,
puis ecrit une seule ligne `[OS CW-21] soundName=... startStopName=... propName=...`.
Ce releve ne change aucun preset, volume, WAV, parametre de vol ou reglage AOC.
Il permettra de remonter au preset reel avant toute correction sonore.
L'audibilite et la cause exacte du faible volume ne sont pas encore validees.

Pour reproduire l'audit : decompiler avec CFR 0.152 les trois fichiers
effectifs cites et la classe MotorSound du dump 4.09m ; comparer aux classes
de l'archive locale for409. Relancer le constructeur avec ses chemins
`--donor-root`, `--dump-root`, `--rt-jar` pour l'audit seul ; l'installation
necessite `--apply --replace-previous-cw21` et refuse toute autre ancienne
empreinte. Les empreintes de sortie sont dans le manifeste cockpit.

Sources complementaires consultees :
[contenu officiel 4.09 sur Mission4Today](https://www.mission4today.com/index.php?file=details&id=3764&name=Downloads),
publication du cockpit SAS citee plus haut (acces direct actuellement en echec,
archive locale conservee), AAA/Wayback (nouvel essai inaccessible, aucun contenu
suppose). Le guide 4.10 justifie les options, pas leur compatibilite 4.09m.

### Historique : copie de test du 6 septembre apres installation

Le correctif actif et celui du jeu de test ont la meme empreinte :
`2BF3C9625781A7116423BDD18764CAA3AA156C6C76DE20EB24F4A447DB87EE27`.
La synchronisation ciblee du correctif et du classement est conservee dans
`manifests/test/cw21-and-aircraft-presentation-v1.15.json` ; sauvegarde et recu
dans `WIP/tests/installations/sync-20260906-215041`. Le controle de contenu donne
24 PASS, 1 WARN, 1 FAIL connu pour les cinq profils AOC de cette copie de test,
sans modification de ces profils pendant cette intervention.

Une tentative de controle des menus a lance le jeu de test (PID 27088).
L'outil de capture Windows a echoue deux fois avec
`SetIsBorderRequired failed: Cette interface n'est pas prise en charge (0x80004002)`.
Aucune liste ni mission n'a pu etre observee ; cela ne constitue pas une
validation visuelle. Le processus lance pour cet essai est referme afin de ne
pas le laisser consommer du CPU. Aucun gain sonore n'a ete modifie.

## Correctif suivant : doublons signales le 7 septembre

Le candidat `2BF3C962...` ci-dessus est remplace apres le retour utilisateur
sur les choix doubles. Voir `CW21_DUPLICATE_LOADOUTS_V1.15.md` : cause dans
l'import tardif des choix d'origine, test negatif reproductible, correctif
de liste limite au CW-21 et nouvelles empreintes. L'affichage et les tirs
restent a valider en jeu ; le son n'a pas ete modifie.
