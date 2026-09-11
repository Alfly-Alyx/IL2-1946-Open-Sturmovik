# Correction du switcher v1.15 — 7 septembre 2026

Suite de `VERIFICATION_SWITCHER_TEST_V1.15.md` (etat avant correction).
Branche conservee : v1.15. Aucun jeu, interface ni outil de capture lance ; aucun
EXE, SFS, DLL ou parametre physique modifie dans le depot.

Resultat mesure sur le switcher BAT unique : 18/18 commutations normales avec
les payloads exacts 4.08m, 4.09b et 4.09m. Un controle separe provoque un echec
reel de la derniere ecriture et confirme la restauration octet pour octet des
14 fichiers actifs. Rapports :
`WIP/test-installations/switcher-matrix-20260907-210358/` et
`WIP/test-installations/switcher-rollback-20260907-213307/result.json`.
Retour confirme au profil 8, 4.09m modifie sans 6DOF, HUD standard.
Ce resultat qualifie les remplacements hors jeu, pas encore le lancement des
neuf profils.

## Registres et interface corriges

Les profils 4/5/6 selectionnent desormais un registre **4.09b distinct**,
`_Game Switcher/409b air.ini/Air.ini/air.ini` : 516 entrees, 42 851 octets,
SHA-256 `9A7ED6510B2569F20EBFC57AB47B06645C39E3766361B5A5C31C0C6A55337B39`.
Ses cles sont exactement celles du registre historique 4.08/4.09b ; son ordre
et ses lignes techniques viennent de la presentation 4.09m actuelle.
Les trois listes existantes restent strictement inchangees (535/516/535).
Les 19 entrees propres a 4.09m, dont le CW-21, restent disponibles en finale.
Aucun fichier d'avion ou de mod n'est supprime du paquet.

L'audit utilise les 2 465 classes libres, les 48 SFS communs du test, le SFS
de chaque profil et ses archives de version. Il trouve maintenant les
516/516/535 classes d'avions declarees. Aucun dump 4.09m n'est utilise pour
certifier les versions precedentes. Le manifeste declare les trois registres,
leurs empreintes et leurs nombres d'entrees ; Git preserve les octets testes.

L'interface et le controle de fichiers sont maintenant integres dans
`Open_Sturmovik_Switcher.bat` : les anciens fichiers HTA et BAT auxiliaire sont
retires. A l'execution, le BAT extrait temporairement sa propre interface puis
la supprime apres son chargement ; la distribution ne contient donc qu'un seul
BAT. Le BAT rend la main aussitot l'interface ouverte : un double-clic direct
ne garde plus de console derriere la fenetre. Windows doit toutefois amorcer
`cmd.exe` pour lire un vrai `.bat`, ce qui peut produire un eclair tres bref.
Le raccourci Bureau evite meme cet eclair : il appelle le meme BAT par
`mshta.exe`, avec `WScript.Shell.Run` en style de fenetre 0. Aucun second script
runtime n'est ajoute.
La presentation reprend le menu principal d'IL-2 : fond d'avion, barre haute,
panneau metallique rivete separe en deux colonnes, lignes de choix avec voyants,
bouton Quitter rouge et action verte. Elle restaure les boutons version/mode
depuis l'etat actif et signale les etats invalides. Les modes sont nommes jeu
stock, modde sans 6DOF et modde avec 6DOF.
Le choix keep detecte le fichier HUD reel : standard, immersion, custom ou
stock. L'etat contient ce resultat et modhud, pas simplement le mot keep.
Une exception ActiveX lors de l'appel du BAT est presentee comme une erreur.

## Transaction et restauration

`active-profile.txt` est maintenant le quatorzieme fichier sauvegarde.
Le nouvel etat est prepare avant modification, puis publie et compare apres
les copies et suppressions. Une erreur de cette derniere ecriture declenche
la restauration complete. Un fichier deja identique a sa sauvegarde n'est pas
reecrit inutilement, notamment si son ecriture est verrouillee.
Une transaction ancienne non terminee bloque les nouvelles commutations ;
aucune sauvegarde residuelle n'est supprimee automatiquement.

Le test d'echec a aussi mis en evidence une contrainte reproductible de
`cmd.exe` : avec ce gros fichier auto-contenu en fins de ligne Unix, le retour
de sous-routine finissait par tronquer des commandes pendant la restauration.
Le BAT et son attribut Git sont desormais forces en CRLF Windows. Le meme test,
rejoue apres synchronisation, retourne le code 6 attendu, restaure les 14
fichiers et ne laisse aucune transaction. Confiance elevee pour ce comportement
hors jeu.

## Retour visuel du 7 septembre

Alexis a fourni une capture du premier affichage du BAT unique. Fait observe :
l'interface, les voyants et les choix apparaissent, mais aucun fond d'avion
n'est affiche ; seul le fond bleu de secours est visible. Cause reproduite :
le BAT cherchait `installer/assets/OpenSturmovik-Wizard.jpg`, present dans le
depot mais absent de la copie de test.

Correction historique du 7 septembre : le JPEG 1600 x 740 avait ete ajoute sous
`_Game Switcher/Resources/Open_Sturmovik_Switcher_Background.jpg`. Alexis l'a
finalement refuse le 8 septembre : le fichier et sa dependance ont ete retires.
En attendant le choix d'un nouveau fond, l'interface utilise son fond uni de
secours. La presentation a ensuite ete rapprochee du menu principal du jeu :
gris metallique plus brut, reliefs et bordures moins lisses, typographie plus
proche et contraste attenue. La disposition, les emplacements des boutons et
leurs intitules sont inchanges. La fenetre passe a 1000 x 760, le
panneau a 900 x 590, les zones de texte n'empietent plus sur les actions, le
panneau est plus transparent et huit rivets reprennent le cadre du menu IL-2.
Une seconde capture fournie par Alexis confirme ensuite que le fond est bien
charge. Les separateurs de tableau ont ete retires et le bouton Quitter a pris
un traitement rouge plus proche du langage visuel du menu, sans le reproduire
a l'identique. Aucun fond de remplacement du switcher n'est encore choisi.
Aucune interface ou capture n'a ete lancee pour ce retrait.

Le dossier technique porte desormais le nom singulier `_Game Switcher`. Ses
ressources graphiques sont rangees dans le sous-dossier court `Resources`, sans
prefixe `_`. L'ancienne reference `Icones\1.ico` citee par les scripts Inno de
la v1.1 n'existe plus a son emplacement historique. Le fichier local
`Icones\HD\1.ico` produit toutefois exactement le meme rendu d'icone que
l'executable compile `Patch 1.1\Output\IL2_Open_Sturmovik_Patch_1.1.exe` ; ce
controle reproductible confirme la ressource retrouvee. Cette ancienne
variante et les deux references devenues inutiles ont ete retirees du dossier
actif le 11 septembre 2026. `Open_Sturmovik_Switcher.ico` contient le dessin
`logo-IL2-B` et devient l'icone active de la fenetre et du raccourci.
`Open_Sturmovik_Game.ico` contient le dessin `avion-ciel`, reserve aux
executables de jeu modifies. Le BAT copie temporairement l'icone et le fond
Pacific Fighters Retail a cote de son HTA extrait, puis supprime les trois
fichiers temporaires apres chargement.

Test d'echec reel : garder active-profile.txt ouvert en lecture partagee,
permettre sa sauvegarde mais interdire son ecriture, tenter le profil 1 depuis
le profil 8, puis comparer les quatorze empreintes. Aucun faux retour d'erreur
n'est injecte dans le BAT. Le test exige le retour 6 (restauration terminee),
l'etat initial exact et zero transaction abandonnee.

## Politique HUD retenue

Chaque version propose trois modes : jeu stock, Open Sturmovik sans 6DOF et
Open Sturmovik avec 6DOF. Le mode stock force le HUD d'origine, car il retire le
chargeur de mods. Les deux modes Open Sturmovik permettent le choix HUD standard
ou immersion. La GUI grise donc immersion en stock et le BAT enregistre le HUD
effectif `stock`, tout en memorisant le dernier HUD de mod dans `modhud`.

## Sources et limites techniques

Six fichiers sauvegardes et verifies avant modification dans
`D:\Projets\GITHUB\#res\IL2 1946\Sauvegarde_switcher_v1.15_20260907`.
Sources prioritaires : AAA Community Installer 1.1 local et SFS propres aux
profils. Les anciens BAT AAA ne copient que les dossiers du profil au-dessus
du pack et dependent donc de l'etat prealable de l'installation. Le switcher
v1.15 ne conserve pas cette ambiguite : les profils 1/2/3 posent les DLL coeur
et son 4.08m et retirent les trois archives 4.09 ; les profils 4/5/6 posent le
payload 4.09b ; les profils 7/8/9 posent le payload 4.09m.

L'audit etendu signale des references non resolues communes aux versions :
Controls vers P_51Mustang ; X_86 vers MIG_15SV ; CockpitSea2 vers SEAFIRE2 et
SEAFIRE2L ; CockpitYAK_3P vers ses classes internes $1, $Interpolater et
$Variables. Ce sont des observations statiques, pas des erreurs reproduites
en jeu. Aucun de ces composants moteur n'est change dans ce correctif.

Le HUD a aussi ete examine directement dans le SFS **Original 4.09m** :

| Classe | SHA-256 |
| --- | --- |
| SFSInputStream | 1FF7811DB15530C838B9CE86F191AF3CFE3FA732B7A1B490AD52055E5D293B51 |
| LDRres | D77FFFAE17CF4F0F45357EC605AC71033E2F68275A681F8AD1F755FED17952C0 |
| LDR | 48A8C2ECFB947CEA3E00762443326ADC1C66D17590F6E0091589A875BAA1B344 |
| HUD | 2C50780D1B364C1DBC8941450E786E4E9CDD961F616AFC47EC1DAA2FD2F127F1 |

Faits verifies par javap : HUD demande ResourceBundle i18n/hud_log avec
RTSConf.locale et LDRres.loader. LDRres choisit d'abord LDR.resLoader ;
LDR delegue a LDRCallBack.open avant son repli ClassLoader. Dans SFSInputStream,
le constructeur String utilise FileInputStream pour les noms non ASCII ;
openn tente d'abord l'ouverture par empreinte SFS. La presence de FileInputStream
ne demontre donc pas une priorite generale des ressources libres.
Le callback natif stock reste a qualifier. Le chemin SFS brut
i18n/hud_log_ru.properties n'a pas ete trouve dans ce SFS, sans prouver
l'absence d'un bundle encode. Ne pas en deduire une impossibilite universelle.

Reproduction : `Analyze-Sfs.py inspect` sur le files.SFS Original 4.09m,
options --class pour ces quatre noms qualifies, puis `javap -c -p` sur les
sorties sous `build/switcher-hud-proof-409m`. La methode d'empreintes existante
est documentee dans AUDIT_SFS.md ; Finger de i18n vaut 5274058547514128462,
celui de gui 20078495372105033. Le premier ne correspond pas aux prefixes
interdits compares dans openn ; cela ne qualifie pas le callback de ressources.

[AAA/Wayback 2010](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/)
reste inaccessible. La discussion d'origine
[Mission4Today, Hack your HUD, janvier 2008](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=2595)
rectifie son hypothese initiale d'une edition equivalente en stock, sans
fournir de solution stock verifiee. Les recherches SAS sur hud_log et
air.ini 4.09b n'ont apporte aucune preuve nouvelle exploitable.
Aucun telechargement ni integration d'un nouveau mod pendant cette correction.

## Controles et copie de test

- Test-AircraftNameReview.py : 12 tests, dont l'identite exacte de la liste beta
  avec le sous-ensemble historique de la presentation courante.
- Test-SwitcherGui.cjs : interface integree detectee dans le BAT, neuf profils,
  18 transmissions profil/HUD et 18 restaurations d'etat, garde HUD stock,
  resumes et etat invalide, sans ActiveX ni fenetre. Il verifie aussi que le
  manifeste et Inno Setup produisent le meme lancement CMD masque.
- Audit-SwitcherClassAvailability.py --all-loose : rapport
  `WIP/test-plans/switcher-class-availability-fixed-20260907.json`.
- Test-SwitcherTransactions.ps1 -Apply : 18 commutations normales reelles dans
  la seule copie WIP avec les trois payloads exacts.
- Test-SwitcherRollback.ps1 -Apply : panne de derniere ecriture reelle, 14/14
  fichiers restaures et retour au profil 8/HUD standard.
- Test-V115OfflineReadiness.ps1 : six controles du depot, sans jeu.

Synchronisation ciblee : `manifests/test/switcher-fix-v1.15.json`, quatre
copies, aucun retrait ; sauvegarde `WIP/test-installations/sync-20260907-104207`.
Le bilan du manifeste a ensuite ete synchronise seul, sans retrait, suivant
`manifests/test/switcher-report-sync-v1.15.json` ; sauvegarde recuperable
`WIP/test-installations/sync-20260907-110220`.
Le controle final du profil 8 compte 42/42 controles reussis dans
`WIP/test-plans/switcher-fix-final-ready-20260907.json`, avec la seule exception
de contenu AOC ci-dessous explicitement autorisee. Il ne lance ni jeu ni capture.
Les cinq profils AOC de test et les profils joueur sont preserves. L'ecart
AOC connu ne devient pas une validation de l'inventaire de distribution.
La synchronisation CRLF finale suit
`manifests/test/switcher-crlf-rollback-v1.15.json` ; sauvegarde recuperable
`WIP/test-installations/sync-20260907-213247`.
Le bilan final a ete recopie seul suivant
`manifests/test/switcher-final-report-v1.15.json` ; sauvegarde recuperable
`WIP/test-installations/sync-20260907-213909`.
Le lancement masque et la derniere presentation suivent
`manifests/test/switcher-hidden-launch-v1.15.json` ; les quatre fichiers ont ete
synchronises avec une sauvegarde recuperable sous
`WIP/test-installations/sync-20260907-222332`. Le raccourci Windows genere dans
`WIP/test-desktop/switcher-hidden-20260907` cible `mshta.exe`, passe le style de
fenetre 0 a `WScript.Shell.Run` et conserve le dossier du jeu comme dossier de
travail. Il a ete relu sans etre lance. Le controle statique final repasse ses
42 controles dans
`WIP/test-plans/switcher-hidden-launch-ready-20260907.json`.
La migration au nom singulier, les corrections de geometrie et les ressources
graphiques suivent `manifests/test/switcher-singular-resources-v1.15.json` ; la
copie de test a ete sauvegardee sous
`WIP/test-installations/sync-20260907-225356`. Son controle final repasse 42/42
dans `WIP/test-plans/switcher-singular-resources-ready-20260907.json`.
L'ajustement final limite le dossier aux seules ressources citees et conserve
sa sauvegarde recuperable sous `WIP/test-installations/sync-20260907-230312`.
Les lancements, le comportement TrackIR et les HUD visibles restent a tester
avec Alexis ; la verification de fichiers n'est pas leur qualification.

## Presentation comparee au menu du jeu

La copie affichee le 8 septembre 2026 confirme que le BAT du dossier de test
utilise bien la nouvelle interface : panneau metallique texture, cadre en
relief, vis, voyants ambre/verts et separateurs clairs sont visibles. La
disposition, les emplacements et les intitules demandes sont conserves. Aucune
fenetre de commande n'apparait a cote de l'interface.

Les fonds de chargement sont ranges sous
`_Game Switcher\Resources\Loading Backgrounds`. Le fond actif `Maddox` et
quatre familles visuelles sont disponibles en 4:3, 16:10, 16:9, 21:9 et 32:9
jusqu'a 4K, sans etirement. Le fond de l'interface retenu par Alexis est la
remasterisation `Pacific Fighters Retail`, chargee depuis
`_Game Switcher\Resources\Backgrounds\Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.png`.
La source du fond Missions et une variante Corsair/Zero restent dans le meme
dossier sous des noms descriptifs.
Les deux icones actives sont isolees sous
`_Game Switcher\Resources\Icons` : `Open_Sturmovik_Switcher.ico` pour le
lanceur et `Open_Sturmovik_Game.ico` pour les executables modifies.
