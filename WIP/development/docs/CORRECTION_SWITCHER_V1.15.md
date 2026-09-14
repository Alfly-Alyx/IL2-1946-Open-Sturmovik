# Correction du switcher v1.15 — 7 septembre 2026

Suite de `VERIFICATION_SWITCHER_TEST_V1.15.md` (etat avant correction).
Branche conservee : v1.15. Aucun jeu, interface ni outil de capture lance ; aucun
EXE, SFS, DLL ou parametre physique modifie dans le depot.

Resultat mesure sur le switcher BAT unique : 18/18 commutations normales avec
les payloads exacts 4.08m, 4.09b et 4.09m. Un controle separe provoque un echec
reel de la derniere ecriture et confirme la restauration octet pour octet des
14 fichiers actifs. Rapports :
`WIP/tests/installations/switcher-matrix-20260907-210358/` et
`WIP/tests/installations/switcher-rollback-20260907-213307/result.json`.
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
BAT. Un double-clic sur le BAT ouvre directement cette interface. Le raccourci
Bureau appelle `_Game Switcher\Open_Sturmovik_Switcher.vbs`, qui calcule la
racine du jeu depuis son propre dossier et execute le BAT par une console
masquee. Le BAT ouvre `mshta.exe` avec `START /NORMAL` : la console reste
invisible, mais l'interface demeure visible. Tous les chemins du jeu restent
relatifs a l'emplacement des scripts.
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
  `WIP/tests/plans/switcher-class-availability-fixed-20260907.json`.
- Test-SwitcherTransactions.ps1 -Apply : 18 commutations normales reelles dans
  la seule copie WIP avec les trois payloads exacts.
- Test-SwitcherRollback.ps1 -Apply : panne de derniere ecriture reelle, 14/14
  fichiers restaures et retour au profil 8/HUD standard.
- Test-V115OfflineReadiness.ps1 : six controles du depot, sans jeu.

Synchronisation ciblee : `manifests/test/switcher-fix-v1.15.json`, quatre
copies, aucun retrait ; sauvegarde `WIP/tests/installations/sync-20260907-104207`.
Le bilan du manifeste a ensuite ete synchronise seul, sans retrait, suivant
`manifests/test/switcher-report-sync-v1.15.json` ; sauvegarde recuperable
`WIP/tests/installations/sync-20260907-110220`.
Le controle final du profil 8 compte 42/42 controles reussis dans
`WIP/tests/plans/switcher-fix-final-ready-20260907.json`, avec la seule exception
de contenu AOC ci-dessous explicitement autorisee. Il ne lance ni jeu ni capture.
Les cinq profils AOC de test et les profils joueur sont preserves. L'ecart
AOC connu ne devient pas une validation de l'inventaire de distribution.
La synchronisation CRLF finale suit
`manifests/test/switcher-crlf-rollback-v1.15.json` ; sauvegarde recuperable
`WIP/tests/installations/sync-20260907-213247`.
Le bilan final a ete recopie seul suivant
`manifests/test/switcher-final-report-v1.15.json` ; sauvegarde recuperable
`WIP/tests/installations/sync-20260907-213909`.
Le lancement masque et la derniere presentation suivent
`manifests/test/switcher-hidden-launch-v1.15.json` ; les quatre fichiers ont ete
synchronises avec une sauvegarde recuperable sous
`WIP/tests/installations/sync-20260907-222332`. Le raccourci Windows genere dans
`WIP/tests/desktop/switcher-hidden-20260907` cible `mshta.exe`, passe le style de
fenetre 0 a `WScript.Shell.Run` et conserve le dossier du jeu comme dossier de
travail. Il a ete relu sans etre lance. Le controle statique final repasse ses
42 controles dans
`WIP/tests/plans/switcher-hidden-launch-ready-20260907.json`.
La migration au nom singulier, les corrections de geometrie et les ressources
graphiques suivent `manifests/test/switcher-singular-resources-v1.15.json` ; la
copie de test a ete sauvegardee sous
`WIP/tests/installations/sync-20260907-225356`. Son controle final repasse 42/42
dans `WIP/tests/plans/switcher-singular-resources-ready-20260907.json`.
L'ajustement final limite le dossier aux seules ressources citees et conserve
sa sauvegarde recuperable sous `WIP/tests/installations/sync-20260907-230312`.
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
`_Game Switcher\Resources\Backgrounds\Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.jpg`.
La source du fond Missions et une variante Corsair/Zero restent dans le meme
dossier sous des noms descriptifs.
Les deux icones actives sont isolees sous
`_Game Switcher\Resources\Icons` : `Open_Sturmovik_Switcher.ico` pour le
lanceur et `Open_Sturmovik_Game.ico` pour les executables modifies.

## Correction du lancement visible — 13 septembre 2026

Symptome reproduit dans la copie de test : le double-clic sur le lanceur du
switcher pouvait ne montrer qu'une console vide, ou ne laisser aucune interface
visible lorsque le lancement passait par le VBS. La fenetre HTA existait bien,
mais elle heritait du mode masque utilise pour cacher `cmd.exe`.

Le BAT lance maintenant `%SystemRoot%\System32\mshta.exe` avec
`START "" /NORMAL`. `%SystemRoot%` designe le composant Windows ; ce n'est pas
un chemin vers une installation particuliere du jeu. Le BAT retrouve toujours
la racine avec `%~dp0`, et le VBS la deduit de son propre dossier parent. Aucun
chemin `D:\...` ou autre lettre de lecteur n'est inscrit dans les scripts
distribues.

Validation reelle dans la copie de test : le BAT direct et le VBS utilise par
le raccourci ont chacun affiche une fenetre `Open Sturmovik Switcher 1.15` de
1000 x 760. Les deux fenetres ont ensuite ete fermees sans appliquer de profil
et sans lancer le jeu.

## Compatibilite Plane par profil — 13 septembre 2026

### Faits verifies

Un clic sur `il2fb.exe` apres activation du profil 2 (4.08m modde) ou du profil 5 (4.09b modde) pouvait ne produire aucune fenetre. Le profil 5 quittait avec le code 1 pendant l'initialisation de `Ship`; le journal Java indiquait `RuntimeException: Can't set property`. Le profil 4.09b Original demarrait, ce qui a circonscrit le probleme au chargement des classes libres par `wrapper.dll`.

Les essais A/B dans `WIP/tests/installations/IL 2 Sturmovik 1946 test` ont isole `Files/2B9A89D62FA5D19A`, classe `com.maddox.il2.objects.vehicles.planes.Plane`. La variante v1.15 de 83 967 octets, SHA-256 `FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059`, est destinee a 4.09m. La variante historique Open Sturmovik de 82 699 octets, SHA-256 `CFCC074266A0EDFF44D439884D92667EAD6EAC84FE3B59E8BBA97B08244634BB`, permet aux moteurs 4.08m et 4.09b d'achever leur demarrage.

`Plane` appartient au registre des avions places comme objets statiques. Les avions pilotables restent declares par le `air.ini` propre a chaque version et par leurs classes. La correction ne retire ni les classes `Ship` libres ni les entrees d'avions de `air.ini`.

Chaque dossier de profil contient desormais `Profiles/Files/2B9A89D62FA5D19A`. Les profils 1 a 6 possedent la variante historique compatible; les profils 7 a 9 possedent la variante v1.15 pour 4.09m. Le BAT verifie son empreinte, le prepare, sauvegarde le fichier actif comme seizieme element transactionnel, le copie et le restaure en cas d'echec. Tous les chemins sont calcules depuis `%~dp0`.

Essais reels apres integration, chacun arrete volontairement apres 15 secondes : profils 2, 5 et 8 encore actifs, fenetre intitulee `Open Sturmovik`. Le passage au profil 8 a restaure exactement l'empreinte 4.09m.

### Deduction et limite

La difference de `Plane` provoquait l'echec d'initialisation observe avec les assemblages anciens. Les trois demarrages valident l'amorcage et l'arrivee de la fenetre; ils ne remplacent pas un essai en mission de chaque avion statique, avion pilotable et navire pour les neuf profils.

## Langues, progression et disposition — 13 septembre 2026

Le sélecteur propose sept langues dans une liste déroulante compacte : `Français`, `English`, `Deutsch`, `Русский`, `Čeština`, `Magyar` et `Polski`. Les codes écrits pour IL-2 sont respectivement `fr`, `us`, `de`, `ru`, `cs`, `hu` et `pl`. La valeur historique `en` est reconnue à la lecture comme un alias de l’anglais, puis normalisée en `us`.

Au clic sur `Appliquer`, `_Game Switcher/Set-OpenSturmovikLanguage.ps1` ne remplace que `locale=` dans la section `[rts]` du `conf.ini` actif. L’encodage, les fins de ligne et toutes les autres préférences sont conservés. La langue choisie est également mémorisée dans `active-profile.txt`, puis le jeu la charge à son prochain démarrage.

Les six catalogues dont le contenu varie selon le moteur (`gui`, `maps`, `plane`, `regInfo`, `regShort` et `weapons`) sont copiés depuis `_Game Switcher/Languages/<version>/i18n`. Les autres catalogues libres communs restent dans `Files/i18n`. Le HUD standard ou immersion est installé sous le nom correspondant à la langue active. Les clés HUD absentes d’une traduction locale gardent explicitement leur texte anglais vérifié.

L’application du profil est lancée en arrière-plan. Le BAT publie les étapes réelles de sa transaction dans un fichier temporaire : vérification 5–35 %, préparation 45–60 %, sauvegarde 72 %, copie 88 %, état 96 %, fin 100 %. La fenêtre affiche ces valeurs et le message courant, puis présente le journal complet.

Le fond Pacific Fighters Retail actif est un JPEG de qualité 92 de 627 063 octets, aux mêmes dimensions 1586 × 992 que la source PNG de 4 634 420 octets conservée. Il est lu directement depuis `_Game Switcher/Resources` sans copie temporaire. La capture `19.png` a révélé un chevauchement vertical entre la liste des langues et `Crédits`. Le bouton a été descendu de 12 pixels, reste centré dans la colonne gauche et conserve une marge avec les actions. La fenêtre reste haute de 760 pixels afin de tenir sur les écrans de 768 pixels.

Le fond de menu libre `Files/gui/Background.tga` est installé uniquement pour les six profils moddés. Les trois profils stock le retirent et laissent le `files.SFS` sélectionné fournir son menu d’origine. Les libellés du chargement initial sont propres à chaque profil ; la bêta stock affiche `V 4.09b` au lieu du texte historique `V 4.09b1m`.

La logique d’interface a validé 126 combinaisons profil/HUD/langue et 126 restaurations d’état. Les transactions réelles ont validé les neuf profils, les sept langues en HUD standard et les sept en HUD immersion. Ces essais vérifient les fichiers copiés et l’état final ; l’aspect de chaque traduction dans les menus reste à confirmer lors d’un lancement visuel par Alexis. L’analyse détaillée se trouve dans `WIP/analyses/langues-il2/README.md`.


### Temps d’ouverture du sélecteur

L’ancienne extraction temporaire du HTA prenait environ 38 ms à elle seule dans le jeu de test. Le raccourci VBS attendait en revanche le démarrage de PowerShell et la détection de résolution avant d’ouvrir le sélecteur, soit environ 483 ms mesurées à chaud et davantage lors d’un premier démarrage Windows. Cette étape a été retirée du raccourci du sélecteur. Elle reste présente dans `Open_Sturmovik_Game.vbs`, où elle est nécessaire juste avant le lancement d’IL-2. Le passage du fond actif de 4,63 Mo à 627 Ko réduit aussi la lecture et le décodage par `mshta`. Après le signalement d’un délai proche de dix secondes, le HTA intégré a été remplacé par `_Game Switcher/Open_Sturmovik_Switcher.hta`. Le VBS lance ce fichier directement, sans `cmd.exe`, sans extraction aléatoire sous `%TEMP%` et sans copie d’icône. Le BAT conserve une entrée `:openGui` qui ouvre le même fichier permanent. La fenêtre obtient un handle visible en 258 ms lors de la mesure locale à chaud ; le rendu complet reste à confirmer sur le poste d’Alexis.

## Correctifs de profils et cache d'icone — 13 septembre 2026

Les dossiers de la beta portent desormais le prefixe 4.09b et ceux de la version finale le prefixe 4.09m. Cette convention est identique dans la source, le payload et l'installation de test.

Chaque profil fournit aussi son Missions\Background.tga et son repertoire samples\Music\Menu. Une bascule stock restaure ainsi le fond et la musique officiels ; une bascule modee installe ceux d'Open Sturmovik. Les executables modes demandant les catalogues _ru independamment de locale, le switcheur installe 36 alias _ru dont le contenu correspond a la langue choisie.

Le HTA permanent commence directement par son doctype ; le code BAT qui apparaissait derriere l'interface a ete supprime. Apres une bascule, Refresh-OpenSturmovikIconCache.ps1 rattache le raccourci Bureau du jeu a l'icone du il2fb.exe actif et envoie une notification ciblee a Explorer.
## Boutons Retour distincts (13 septembre 2026)

Les deux boutons Retour, dans la page Credits et dans l'ecran de resultat, utilisent une teinte bleu acier (#315f79) avec un relief metallique. Ils restent ainsi clairement visibles sur le fond gris-vert et se distinguent des actions Appliquer (verte) et Quitter (rouge).

## Assemblage initial du profil 8 (13 septembre 2026)

L'installeur ne se contente plus de presenter 4.09m et Sans 6DOF comme choix
coches dans l'interface. La construction du Payload rend reellement actifs les
binaires, les archives, le wrapper, les donnees, la presentation et les
catalogues francais du profil 8. L'etat initial est enregistre dans
`_Game Switcher/active-profile.txt`. Le jeu de test conserve separement le
profil choisi par Alexis.