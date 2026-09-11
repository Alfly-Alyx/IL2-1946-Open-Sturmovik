# Rotation des fonds de chargement Open Sturmovik

Ã‰tat du 11 septembre 2026 â€” Open Sturmovik v1.15, profils moddÃ©s 4.08m, 4.09b et 4.09m, avec ou sans 6DOF. DÃ©veloppement isolÃ© sur `codex/rotation-fonds`. La logique est testÃ©e hors jeu. Le premier lancement natif a atteint le helper, mais refusÃ© la texture 1586 Ã— 992. Les copies ont ensuite Ã©tÃ© rÃ©duites sous 4,20 Mo. Deux lancements directs successifs ont changÃ© de fond ; Alexis a confirmÃ© visuellement que le changement fonctionne parfaitement.

## Utilisation et principe

AprÃ¨s installation et activation, le choix du fond intervient **dans le dÃ©marrage du jeu**. On continue donc Ã  ouvrir `il2fb.exe` ou son raccourci habituel. La fenÃªtre `Open_Sturmovik_Fonds.vbs`, Ã©galement accessible par `Open_Sturmovik_Fonds.bat`, sert seulement Ã  installer et rÃ©gler la fonctionnalitÃ©. Son interface est portÃ©e par `tools/Manage-LoadingRotation.ps1`.

L'installation laisse la rotation **dÃ©sactivÃ©e**. Dans la fenÃªtre, choisir de deux Ã  quatre images, puis le mode ordonnÃ© ou mÃ©langÃ©. On peut dÃ©signer un fond Â« officiel Â» : il apparaÃ®tra deux fois par cycle, les autres une fois. Cette prÃ©fÃ©rence exige au moins trois images ; avec seulement deux images, des frÃ©quences 2:1 rendraient inÃ©vitable une rÃ©pÃ©tition consÃ©cutive.

Avec quatre images dont une officielle, cinq passages peuvent donner : **Officiel â†’ A â†’ Officiel â†’ B â†’ C**. Le cycle suivant respecte aussi la diffÃ©rence avec le dernier fond prÃ©cÃ©dent. En mode mÃ©langÃ©, l'ordre varie tout en conservant ces frÃ©quences exactes. Sans fond officiel, chaque image apparaÃ®t une fois par cycle.

Alexis a retenu les quatre fichiers suivants le 11 septembre 2026. Les originaux PNG restent intacts dans le paquet du jeu, sous `_Game Switcher/Resources/Loading Rotation/Sources`. Leurs copies TGA destinÃ©es au moteur sont installÃ©es dans **`Files/gui/backgrounds`**, Ã  cÃ´tÃ© de leurs matÃ©riaux. Aucune dÃ©pendance au dossier externe de ressources n'est nÃ©cessaire pour jouer.

| Fichier source sÃ©lectionnÃ© | Fichier utilisÃ© dans le jeu | Passages par cycle |
| --- | --- | ---: |
| Forgotten Battles - jaquette remaster 1586x992 - logo gauche.png | `forgotten-battles-box.tga` | 1 |
| IL-2 Sturmovik 2001 Retail - remaster 1586x992.png | `il2-2001.tga` | **2** |
| 3.png | `background-3.tga` | 1 |
| IL-2 Sturmovik 2001 - jaquette remaster 1586x992.png | `il2-2001-box.tga` | 1 |

Les noms internes courts servent Ã  Ã©viter les espaces et accents dans les chemins du moteur. Le catalogue conserve les noms source exacts et leurs empreintes. Le champ `weight` dÃ©crit la prÃ©fÃ©rence choisie ; la configuration enregistrÃ©e (`official=il2-2001`) applique le double passage.

Le mÃ©canisme choisit un matÃ©riau dÃ©jÃ  installÃ©. Il ne recopie pas les images Ã  chaque lancement et ne remplace jamais `Files/gui/Background.tga`, les matÃ©riaux `background0*.mat` existants ou les fonds Ã  la racine de `Files`. Les profils Originaux du switcher retirent le wrapper : leurs classes d'origine restent utilisÃ©es et la rotation intÃ©grÃ©e aux classes libres du mod ne s'exÃ©cute pas.

## Implantation vÃ©rifiÃ©e et fichiers

Le correctif ajoute un appel Ã  `OpenSturmovikLoadingRotation.choose(String)` au dÃ©but de `ConsoleGL0.exclusiveDraw(String)`. Il ne traite que la demande `gui/background0.mat`. Une premiÃ¨re dÃ©cision est conservÃ©e pendant tout le processus : plusieurs appels de chargement ne consomment pas plusieurs images. Si le helper manque ou Ã©choue, le bloc ajoutÃ© laisse continuer la mÃ©thode d'origine avec son fond initial.

| Ã‰lÃ©ment | Emplacement ou rÃ´le |
| --- | --- |
| Classe `ConsoleGL0` adaptÃ©e | `Files/B96FAC8E2C4DDBE0` |
| Helper Java 47 / Java 1.3 | `Files/F35AD7F42DE76ABC` |
| Images et matÃ©riaux ajoutÃ©s | `Files/gui/backgrounds/<id>.tga` et `<id>.mat` |
| Variantes linguistiques ajoutÃ©es | `<id>_cs.mat`, `_de.mat`, `_fr.mat`, `_ru.mat`, vers la mÃªme texture |
| Choix utilisateur | `Files/gui/backgrounds/rotation.properties` |
| Suivi des passages | `.open-sturmovik-loading-rotation/state.properties` |
| Inventaire et sauvegardes | `.open-sturmovik-loading-rotation/installation.json` et `backups/<SHA256>.bin` |

La configuration utilise les propriÃ©tÃ©s `enabled`, `images` (identifiants sÃ©parÃ©s par des virgules), `official` (identifiant ou vide) et `mode` (`shuffle` ou `ordered`). Le helper contrÃ´le l'existence des matÃ©riaux, les TGA RGB 24 bits non compressÃ©s et la diffÃ©rence des empreintes des images. Il prÃ©charge le matÃ©riau avec `Mat.New` avant de valider le passage suivant.

L'Ã©tat contient `schema=1`, une signature SHA-1 de la sÃ©lection, des empreintes des images et du mode, le `cycle` complet, sa `position` et le dernier identifiant `last`. Le cycle demeure ainsi cohÃ©rent entre les dÃ©marrages. Un changement de sÃ©lection produit une nouvelle signature et reconstruit le cycle en tenant compte du dernier identifiant.

`selection.lock`, crÃ©Ã© exclusivement par `File.createNewFile`, empÃªche deux sÃ©lections simultanÃ©es. L'Ã©criture utilise `state.next`, puis conserve temporairement l'ancien Ã©tat dans `state.previous`. Une interruption peut Ãªtre rÃ©cupÃ©rÃ©e au dÃ©marrage suivant. Un Ã©tat incohÃ©rent, un fichier manquant, un matÃ©riau impossible Ã  charger ou une Ã©criture impossible entraÃ®ne le retour au fond initial. Les dossiers rencontrÃ©s Ã  la place des fichiers d'Ã©tat sont prÃ©servÃ©s.

## DÃ©sactivation et retour Ã  l'Ã©tat antÃ©rieur

Toutes les opÃ©rations de gestion s'effectuent jeu fermÃ©. `Install` vÃ©rifie le profil par les empreintes de l'EXE, de `files.SFS` et du wrapper, installe les deux classes et les ressources, puis laisse `enabled=false`. Une autre surcharge inconnue de `ConsoleGL0` fait refuser l'installation.

`Disable` remet `enabled=false` et conserve les ressources pour une rÃ©activation. `Remove` retire les fichiers ajoutÃ©s ou restitue leurs octets prÃ©cÃ©dents lorsque ces fichiers existaient dÃ©jÃ . L'inventaire mÃ©morise aussi leur absence initiale. Les sauvegardes sont vÃ©rifiÃ©es par SHA-256 ; un journal permet de rÃ©tablir les fichiers si une opÃ©ration de gestion Ã©choue.

Une image ou un matÃ©riau modifiÃ© manuellement aprÃ¨s installation est conservÃ© lors du retrait ; sa texture associÃ©e peut Ã©galement Ãªtre conservÃ©e. Une modification manuelle d'une des classes installÃ©es bloque le retrait automatique plutÃ´t que d'effacer une modification Ã©trangÃ¨re. Les sauvegardes, l'inventaire et l'historique des passages restent disponibles dans le dossier de suivi ; le retrait n'est pas un nettoyage rÃ©cursif de ce dossier. Aucun EXE ni SFS n'est modifiÃ© par cette installation.

## Aide-mÃ©moire PowerShell

Dans Windows PowerShell 5.1, depuis le dossier du paquet, dÃ©finir `$jeu` sur **la copie de jeu Ã  Ã©quiper**. Les identifiants ci-dessous reprennent la sÃ©lection finale d'Alexis.

```powershell
$jeu = 'C:\Chemin\Vers\Open Sturmovik'
.\tools\Set-LoadingRotation.ps1 -GameRoot $jeu -Action Status
.\tools\Set-LoadingRotation.ps1 -GameRoot $jeu -Action Install
.\tools\Set-LoadingRotation.ps1 -GameRoot $jeu -Action Enable `
    -ImageIds @('forgotten-battles-box','il2-2001','background-3','il2-2001-box') `
    -OfficialId 'il2-2001' -Mode shuffle
.\tools\Set-LoadingRotation.ps1 -GameRoot $jeu -Action Disable
.\tools\Set-LoadingRotation.ps1 -GameRoot $jeu -Action Remove
```

Omettre `-OfficialId` donne des frÃ©quences Ã©gales ; `-Mode ordered` choisit l'ordre dÃ©terministe. La fenÃªtre de rÃ©glage Ã©vite de saisir ces commandes. Pour jouer ensuite, utiliser normalement l'exÃ©cutable ou son raccourci, avec le dossier du jeu comme rÃ©pertoire de travail.

## Sources, reproduction et niveau de preuve

**Faits vÃ©rifiÃ©s dans les fichiers locaux, confiance Ã©levÃ©e.** La prioritÃ© de recherche a Ã©tÃ© donnÃ©e Ã  `D:\Projets\GITHUB\#res\IL2 1946`, notamment aux collections `background`, puis aux archives de profils du paquet. La classe source `ConsoleGL0`, extraite en lecture seule par `tools/Analyze-Sfs.py` / `SfsArchive.extract_class`, est identique dans les six profils moddÃ©s. Les dÃ©tails et empreintes de chaque archive sont conservÃ©s dans `test-assets/loading-rotation/ConsoleGL0.provenance.json`. Sa taille est de 4 402 octets, son format Java est 47 et son SHA-256 est :

`1C36806AA965835949125E09518425DD45D6E927EB1E055B3E701A5647215D9C`.

Le dÃ©sassemblage local de cette classe montre la tentative de matÃ©riau suffixÃ© par la langue avant le matÃ©riau gÃ©nÃ©rique. C'est pourquoi l'installation ajoute les variantes linguistiques. Le fichier d'analyse prÃ©existant `WIP/sdk/nuclear-real-api/pause-engine-decompiled/com/maddox/il2/game/Main3D.java`, ligne 703 dans le checkout de rÃ©fÃ©rence, appelle `exclusiveDraw("gui/background0.mat")` lorsque `UseStartLog` est dÃ©sactivÃ©. Ce dernier fichier est une observation de dÃ©compilation 4.09m ; il ne constitue pas Ã  lui seul une preuve d'identitÃ© avec toute classe active future.

Reproduction depuis la copie de dÃ©veloppement :

```powershell
javap -c -p .\test-assets\loading-rotation\ConsoleGL0.class
.\tools\Build-LoadingRotationPatch.ps1 `
    -PackageRoot '_Game Switcher\Loading Rotation Patch'
.\tools\Test-LoadingRotation.ps1
```

La construction vÃ©rifie l'empreinte source, l'unicitÃ© du point d'appel, le gestionnaire de repli et les autres mÃ©thodes inchangÃ©es. ASM analyse le bytecode produit ; les deux classes distribuÃ©es sont de version 47. La conversion du helper remplace notamment les rÃ©fÃ©rences `StringBuilder` par `StringBuffer` et refuse les instructions modernes incompatibles dÃ©tectÃ©es.

**RÃ©sultats reproductibles hors jeu.** Le 11 septembre, 18 scÃ©narios ont rÃ©ussi sur le helper source puis sur le helper Java 47 exact du paquet : **5 949 assertions par variante**, soit 11 898 au total, avec Java 17 et `-Xverify:all`. Ils couvrent frÃ©quences, frontiÃ¨res de cycles, persistance, absence d'Ã©criture dÃ©sactivÃ©e, corruption, images identiques ou absentes, verrou occupÃ©, Ã©chec de `Mat.New`, reprise et panne d'Ã©criture aprÃ¨s prÃ©chargement. Le moteur graphique est remplacÃ© par un stub rÃ©servÃ© aux tests. Rapport : `build/loading-rotation-test-run-985d7a54ff174f959e8f98a749875a4f/result.json`.


Les PNG sources de la sÃ©lection finale ont Ã©tÃ© copiÃ©s sans modification depuis `D:\Projets\GITHUB\#res\IL2 1946\background\OS backgrounds\Remasterized Backgrounds`. AprÃ¨s conversion sous Windows PowerShell 5.1, un dÃ©codage indÃ©pendant avec Pillow a comparÃ© les **1 573 312 pixels RGB de chacune des quatre images** : dimensions, contenu et empreintes concordent. Les TGA finaux sont non compressÃ©s, RGB 24 bits, origine en bas Ã  gauche (descripteur 0), comme le fond existant de rÃ©fÃ©rence 2880 Ã— 2160. Le gÃ©nÃ©rateur inverse uniquement l'ordre de stockage des lignes du PNG ; les pixels dÃ©codÃ©s et l'orientation visible sont inchangÃ©s. Les dimensions 1586 Ã— 992 restent Ã  qualifier dans le moteur natif.

`Mat.New` appelle `FObj.Get`, dont `GetFObj(String)` est natif ; `Mat.tgaInfo` et `Mat.LoadTextureAsArrayFromTga` sont Ã©galement natifs dans les classes extraites du `files.SFS` 4.09m. Le stub Java ne constitue donc aucune preuve des dimensions acceptÃ©es, de l'affichage natif ni des limites graphiques.


Ces deux classes sont identiques entre les archives 4.08m, 4.09b et 4.09m examinÃ©es ; les paires avec/sans 6DOF partagent dÃ©jÃ  leurs archives SFS. SHA-256 de `Mat` : `0FFB304164E37CEB2007D199BF0FD9BD7593BEAD04B02CBBFB6DF667154D779E` ; de `FObj` : `9A7C5B22CAC402B61DD4DD8FA03973FC892AC647D70EF4230ED207DE481F8A53`. Reproduction en lecture seule : extraire ces classes avec `SfsArchive.extract_class`, puis utiliser `javap -c -p` pour voir l'appel `Mat.New(String)` et les dÃ©clarations `native`. Confiance Ã©levÃ©e pour cette identitÃ© et cette signature Java ; comportement natif non mesurÃ©.


**Gestion et installation.** Les 78 contrÃ´les Windows PowerShell 5.1 ont rÃ©ussi avec la sÃ©lection finale : installation dÃ©sactivÃ©e, activation, restauration octet pour octet, conservation des modifications manuelles, conflits, sauvegarde corrompue et interruption rÃ©elle par verrouillage de fichiers. Rapport : `build/loading-rotation-install-tests/run-680e8e53ff94445fa631b80ef689f44f/report.json`. Ces contrÃ´les couvrent le chemin final `Files/gui/backgrounds` et les TGA dÃ©finitifs d'origine bas-gauche. Les 27 fichiers installÃ©s ont aussi Ã©tÃ© vÃ©rifiÃ©s individuellement contre leurs empreintes aprÃ¨s activation.

Dans **`C:\Users\Alexis\.codex\rotation-fonds`**, la configuration finale est maintenant **activÃ©e**, avec les quatre images et `official=il2-2001`, `mode=shuffle`. Le dossier partagÃ© reste sur `v1.15` et n'a reÃ§u aucun de ces fichiers. Le paquet suivi par Git contient les sources, classes et outils ; les fichiers actifs gÃ©nÃ©rÃ©s et les sauvegardes sont ignorÃ©s par Git. AprÃ¨s rÃ©cupÃ©ration du paquet dans une autre copie complÃ¨te du jeu, utiliser la fenÃªtre ou la procÃ©dure d'installation ci-dessus pour produire ces fichiers actifs.

Le manifeste lÃ©ger `manifests/loading-rotation-verification.json` conserve les rÃ©sultats et empreintes finaux. Une copie du module, de ses outils et de ses sources est classÃ©e dans `D:\Projets\GITHUB\#res\IL2 1946\Mods\Reserve\Open Sturmovik - rotation fonds v1.15 - 2026-09-11`. Ce classement correspond Ã  l'attente de validation native : le module est prÃ©parÃ© dans la copie de dÃ©veloppement, pas intÃ©grÃ© au dossier partagÃ©. L'archive contient le module de rotation complet, pas une installation complÃ¨te d'IL-2.

**Sources communautaires, portÃ©e limitÃ©e.** Le [retour Mission4Today sur le premier Ã©cran de chargement](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=14751&view=next), relu le 11 septembre, confirme un remplacement par TGA et matÃ©riaux GUI en 4.09m ; il ne dÃ©montre pas cette rotation Java. Le prÃ©cÃ©dent [SAS Modact 5.3 / IL-2 4.12.2m](https://www.sas1946.com/main/index.php?topic=37662.0) mentionne `RandomSplash` dans les Ã©lÃ©ments indexÃ©s de l'Ã©tude initiale. Sa page directe renvoie 403 : aucune compatibilitÃ© avec ce pack n'est Ã©tablie et aucun composant SAS de cette version n'est repris. [AAA via Wayback](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/), consultÃ© en prioritÃ©, reste inaccessible ; aucun contenu supposÃ© n'est utilisÃ©.

## Limites restant Ã  valider

La JVM 1.3 embarquÃ©e a Ã©tÃ© exÃ©cutÃ©e lors du premier essai. Le helper est atteint, mais le moteur natif refuse la taille de texture prÃ©parÃ©e. La copie initiale ne possÃ©dait pas les dÃ©pendances du jeu de base ; la prÃ©paration dÃ©crite ci-dessous les a ajoutÃ©es avant cet essai. Les tests ne prouvent donc pas l'affichage effectif, le bon cadrage des images 1586 Ã— 992 ni le comportement du wrapper sur les six profils. Ces essais restent nÃ©cessaires, ainsi qu'un retour au profil Original pour confirmer visuellement son fond habituel. La fenÃªtre de gestion a Ã©tÃ© rendue et contrÃ´lÃ©e visuellement sous Windows PowerShell 5.1 ; cela ne valide pas le rendu des textures par le jeu. Avec `UseStartLog` actif, le dÃ©marrage observÃ© utilise la console et ne demande pas ce fond.

Un arrÃªt forcÃ© pendant la sÃ©lection peut laisser `selection.lock`. Les dÃ©marrages suivants gardent alors le fond initial ; une dÃ©sactivation ou rÃ©activation par l'outil, jeu fermÃ©, retire ce verrou rÃ©siduel. Un arrÃªt aprÃ¨s validation de l'Ã©tat peut consommer un passage mÃªme si l'image n'a pas Ã©tÃ© vue : l'Ã©tat enregistre une sÃ©lection prÃ©chargÃ©e, pas une preuve d'affichage. Ces limites sont distinctes de la rÃ©versibilitÃ© des fichiers installÃ©s.

## PrÃ©paration au lancement â€” 11 septembre 2026

Ã‰tat historique avant le premier essai : la copie `C:\Users\Alexis\.codex\rotation-fonds` Ã©tait prÃ©parÃ©e sans avoir Ã©tÃ© lancÃ©e. Le lancement dÃ©crit ci-dessous a ensuite Ã©tÃ© demandÃ© explicitement par Alexis. Le profil 8 est sÃ©lectionnÃ© : Open Sturmovik 4.09m sans 6DOF, wrapper historique, DirectX et fenÃªtre 1024 Ã— 768. Ces rÃ©glages proviennent de la copie de test historique ; la rotation reste activÃ©e avec les quatre images finales et le fond officiel doublÃ©. `UseStartLog` est absent de `[Console]` : la valeur initiale `false` observÃ©e dans `Main3D` conserve le chemin du fond graphique.

Les **49 contrÃ´les de prÃ©paration passent**, ainsi que les 25 contrÃ´les de contenu. Le seul avertissement de contenu concerne l'absence normale de vÃ©rification par dump d'une exÃ©cution, puisque le jeu reste fermÃ©. Les 27 fichiers de rotation correspondent toujours Ã  leurs empreintes. Le manifeste `manifests/loading-rotation-preparation.json` conserve les rÃ©sultats, les provenances et les empreintes. Cette prÃ©paration ne valide ni l'affichage natif ni toutes les fonctions du jeu.

**Provenance vÃ©rifiÃ©e.** Les 134 fichiers absents ajoutÃ©s reprÃ©sentent 2 307 720 642 octets : 45 SFS historiques, `bin` et `lib`, trois DLL de base et les paramÃ¨tres nÃ©cessaires au test. Ils proviennent exclusivement de la copie historique `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test`, restÃ©e en lecture seule. Sa reconstruction DVD 4.07m puis correctifs 4.09m est dÃ©crite dans `PROTOCOLE_PREMIER_LANCEMENT.md` et ses dÃ©marrages dans `RESULTATS_TESTS_DEMARRAGE_2026-08-30.md`. Le dÃ©placement de cette copie est tracÃ© dans `manifests/test/local-layout-v1.15.json`. Les 52 archives prÃ©sentes et 17 empreintes de rÃ©fÃ©rence ont Ã©tÃ© contrÃ´lÃ©es avant copie. Chaque fichier ajoutÃ© a ensuite Ã©tÃ© comparÃ© par SHA-256 Ã  sa source.

La recherche prioritaire dans `#res/IL2 1946` a Ã©galement retrouvÃ© l'ISO DVD authentique, vÃ©rifiÃ© contre son `SOURCE.txt` : SHA-256 `7BA9629BD21B7D4A44AB022FB7AD28E328543F84412113A67C1E03E7747FED78`, taille 3 609 690 112 octets, volume DISK1 du 14 novembre 2006. L'ISO n'a pas Ã©tÃ© extrait pour cette prÃ©paration. Les dossiers intitulÃ©s `_4.09m` et l'ancienne rÃ©fÃ©rence `WIP/resources/IL2/IL 2 Sturmovik 1946` contiennent dÃ©sormais des fichiers postÃ©rieurs Ã  4.09m : ils n'ont pas servi de donneurs. Un nom de dossier ne suffit pas Ã  Ã©tablir une version.

**CompatibilitÃ© Java statique.** Le `rt.jar` du donneur annonce Java 1.3.1. La comparaison des rÃ©fÃ©rences des deux classes du correctif avec ses 5 251 classes, mÃ©thodes et champs ne rÃ©vÃ¨le aucune API manquante. Le contrÃ´le s'appuie sur le parseur `tools/Audit-JavaClasses.py`, sans exÃ©cuter la JVM. Les CRC centraux incohÃ©rents du JAR correspondent Ã  l'anomalie historique dÃ©crite dans `docs/AUDIT_CLASSES_JAVA.md` ; aucune rÃ©paration du JAR n'a Ã©tÃ© faite. Le comportement graphique demeure natif et non testÃ©.

**Ã‰carts de copie corrigÃ©s.** Git avait converti des fins de ligne mixtes. Le matÃ©riau de rÃ©fÃ©rence du switcher manquait aussi de son dossier de ressources. `stationary.ini` et sept fichiers texte ont Ã©tÃ© restituÃ©s aux octets de rÃ©fÃ©rence uniquement aprÃ¨s preuve que CRLF/LF constituait toute la diffÃ©rence, puis les contrÃ´les ont Ã©tÃ© repassÃ©s sans exception autorisÃ©e. Le fond Maddox 4:3 requis par le switcher a Ã©tÃ© copiÃ© depuis `Files/background0.tga`, dont le SHA-256 correspond exactement Ã  l'empreinte attendue `E1C0BFB53AE7E5891BF7A4F8333D33F119B177E373DBE8B6BBEC3014EC7CB898` ; aucun visuel n'a Ã©tÃ© fabriquÃ© ou adaptÃ©.

Les sauvegardes et rapports de prÃ©paration restent dans `WIP/loading-rotation-preparation-20260911`. Les fichiers du jeu de base sont exclus localement du suivi Git et ne sont pas ajoutÃ©s au paquet distribuÃ©. Les remplacements du profil ont Ã©tÃ© prÃ©cÃ©dÃ©s d'une sauvegarde. Le dossier partagÃ© est toujours sur `v1.15` et n'a pas Ã©tÃ© modifiÃ© par cette prÃ©paration.
## Premier lancement natif â€” Ã©chec du chargement de la nouvelle texture

Essai du 11 septembre 2026, dÃ©marrÃ© Ã  18:18:16 UTC : exÃ©cutable de la copie isolÃ©e, profil 8 (4.09m moddÃ© sans 6DOF), DirectX, fenÃªtre 1024 Ã— 768. La capture fournie par Alexis montre le fond russe historique. La mention Windows Â« Ne rÃ©pond pas Â» n'est pas le problÃ¨me Ã©tudiÃ©, conformÃ©ment Ã  sa prÃ©cision. Aucun rÃ©glage rÃ©seau ou de dÃ©marrage n'a Ã©tÃ© changÃ© pour ce diagnostic.

**Faits vÃ©rifiÃ©s, confiance Ã©levÃ©e.** Le journal conservÃ© dans `WIP/loading-rotation-launches/20260911-181816Z/log.lst` donne Ã  18:18:31 :

```text
INTERNAL ERROR: Texture Buffer (limit 4202496 Bytes)is to small to fit 4719936 Bytes!
WARNING: object 'gui/backgrounds/forgotten-battles-box.tga' of class 'TTexture2D' not loaded
INTERNAL ERROR: Texture required
WARNING: object 'gui/backgrounds/forgotten-battles-box.mat' of class 'TMaterial' not loaded
```

4 719 936 = 1586 Ã— 992 Ã— 3 : la texture RGB24 prÃ©parÃ©e dÃ©passe le tampon indiquÃ©. Le nom prÃ©cis du nouveau matÃ©riau dans le journal prouve que l'appel ajoutÃ© a Ã©tÃ© exÃ©cutÃ© et que le moteur a tentÃ© ce chargement. Ce dÃ©faut ne peut donc pas Ãªtre expliquÃ© uniquement par un nom de fichier erronÃ©. L'absence de `state.properties` est cohÃ©rente avec le retour sans validation lorsque `Mat.New` Ã©choue. Le journal ne contient pas de message d'erreur Java du helper.

Le repli vers `gui/background0_ru.mat` tente ensuite `gui/background.tga`, Ã©galement refusÃ© : 18 662 400 octets pour la mÃªme limite. La capture montre alors le fond russe ; l'identitÃ© exacte de la ressource finalement affichÃ©e doit Ãªtre recoupÃ©e avec l'analyse du SFS. Les 8192 pixels maximum annoncÃ©s par le pilote ne prouvent pas que le chargeur du moteur accepte une texture de cette taille.

SHA-256 du journal : `E1546123324F15E3BB9C7B95D7AE31B769A0280E46287C9A8B39F4812299DAE8`. La capture utilisateur est `C:/Users/Alexis/Desktop/1.png`. La session du journal se termine Ã  18:20:06 UTC ; le processus lancÃ© n'Ã©tait plus prÃ©sent lors du contrÃ´le suivant. Ce constat ne permet pas d'attribuer la fermeture Ã  une cause prÃ©cise.

**Ã€ dÃ©terminer.** Dimensions et format acceptÃ©s par le chargeur natif pour les quatre images ; rendu et cadrage aprÃ¨s correction ; comportement des autres profils. Les tests hors jeu prÃ©cÃ©dents restent des preuves de logique et de restauration des fichiers, pas des preuves de compatibilitÃ© graphique des textures 1586 Ã— 992.
### Recoupement des noms et des formats

L'extraction en lecture seule de `files.SFS` **de cette copie**, SHA-256 `18F3C5471D93642916394DE53B482051106E024DDAC8124C7B0D700D1796B05A`, confirme que `gui/background0.mat` et `gui/background0_ru.mat` pointent tous deux sur `background0.tga`. Les deux matÃ©riaux ont le SHA-256 `776C9605A9432485B6E67D0F0A69684615362C59F6B6E969CE040F011BB821BC`. La texture interne est un IMF10 1024 Ã— 1024, SHA-256 `AC3314AC8A8A1D3F5AC1B44BA34E3CCCE500ABB7EED342D1CFD710A437F6AA0B`. Les variantes libres du paquet pointent, elles, sur `background.tga`. Il existe donc rÃ©ellement deux noms dans la chaÃ®ne de repli ; cela n'annule pas l'erreur de taille de notre texture, dont le chemin a Ã©tÃ© trouvÃ© et tentÃ©.

Reproduction : `python tools/Analyze-Sfs.py inspect files.SFS --path gui/background0.tga --path gui/background0_ru.mat --path gui/background0.mat --output WIP/loading-rotation-launches/20260911-181816Z/sfs-backgrounds`. Cette commande produit des copies de diagnostic et n'Ã©crit pas dans l'archive.

La chaÃ®ne d'erreur du tampon se trouve dans les DLL natives officielles du cÅ“ur 4.09m : offset fichier `0x1253E0` dans `il2_core.dll` et `0x1393E8` dans `il2_corep4.dll` (recherche binaire en lecture seule). L'annonce de 8192 pixels par le pilote n'augmente donc pas nÃ©cessairement cette limite du chargeur.

La ressource locale `#res/IL2 1946/Packs/AAA_Community_Installer_ver_1_1/MODS/SplashScreen/GUI/background.tga` est un TGA RGB24 1024 Ã— 768, origine basse, avec les mÃªmes paramÃ¨tres de matÃ©riau. Les textures officielles extraites donnent Ã©galement des exemples 512 Ã— 512. Une copie plus petite est donc une piste Ã©tayÃ©e ; les dimensions particuliÃ¨res choisies restent Ã  essayer dans ce pack. Compresser le fichier sur disque (RLE, IMF ou autre) ne constitue pas une preuve de rÃ©duction du tampon RGB demandÃ© aprÃ¨s dÃ©codage.

Une autre piste communautaire est le mod [High Resolution / True Color Textures](https://www.sas1946.com/main/index.php?topic=33239.0), dont l'annonce indexÃ©e mentionne une prise en charge depuis 4.09m. [Mission4Today](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=23378) dÃ©crit une correction de cette erreur avec des DLL HD sur 4.12.2. La page SAS directe reste inaccessible (403). La compatibilitÃ© des DLL et classes de ce mod avec notre pack exact n'est pas Ã©tablie : aucun fichier de ce mod n'a Ã©tÃ© installÃ©. Un choix entre l'adaptation des copies d'images et l'Ã©tude du correctif HD a Ã©tÃ© prÃ©sentÃ© Ã  Alexis avant tout changement de ce type.

## Correction des copies sous 4,20 Mo â€” 11 septembre 2026

Alexis a demandÃ© de rÃ©duire les fichiers aprÃ¨s le constat natif. Les quatre TGA du paquet et leurs copies actives dans `Files/gui/backgrounds` sont dÃ©sormais en **1495 Ã— 935**, **4 193 493 octets chacune**. RÃ©duction bicubique de qualitÃ©, sans recadrage, ratio conservÃ© Ã  l'arrondi prÃ¨s (Ã©cart de 0,00877 %). Les PNG 1586 Ã— 992 restent intacts ; leurs SHA-256 sont identiques au catalogue prÃ©cÃ©dent. Les TGA demeurent RGB24 non compressÃ©s, origine en bas Ã  gauche.

`Build-LoadingRotationAssets.ps1` ajuste les dimensions au budget de 4 200 000 octets, en-tÃªte compris, puis vÃ©rifie le dÃ©codage. Le lecteur du catalogue refuse aussi les fichiers dÃ©passant ce plafond. Les quatre fichiers ont Ã©tÃ© dÃ©codÃ©s indÃ©pendamment avec Pillow et contrÃ´lÃ©s visuellement. La rÃ©installation suit `Remove â†’ Install â†’ Enable` pour mettre Ã  jour l'inventaire de restauration et conserver la sÃ©lection, le mode mÃ©langÃ© et le double passage officiel. La dÃ©tection d'un jeu ouvert porte sur l'installation ciblÃ©e ; un chemin de processus inconnu bloque toujours la modification.

Les **78 contrÃ´les d'installation/restauration rÃ©ussissent** avec ces nouvelles images, ainsi que neuf cas simulÃ©s de dÃ©tection des processus sous PowerShell 5.1. Les jeux de donnÃ©es de test conservent dÃ©sormais le wrapper lorsqu'ils reproduisent un profil moddÃ©. Le jeu n'a pas Ã©tÃ© relancÃ© pour cette correction : le respect du plafond est vÃ©rifiÃ©, le rendu natif des nouvelles dimensions reste Ã  confirmer.

Rapports : `WIP/loading-rotation-resize-20260911/images-verification.json`, `installation-verification.json` dans le mÃªme dossier, et `build/loading-rotation-install-tests/resize-20260911/report.json`. Les TGA prÃ©cÃ©dents, scripts, catalogue et inventaire sont sauvegardÃ©s sous `WIP/loading-rotation-resize-20260911/before`. La limite exacte du moteur et ses preuves sont aussi conservÃ©es dans [`AUDIT_CHARGEMENT_TEXTURES_4.09M.md`](AUDIT_CHARGEMENT_TEXTURES_4.09M.md) et indexÃ©es dans la rÃ©fÃ©rence de rÃ©tro-ingÃ©nierie.


## Validation du changement au relancement â€” 11 septembre 2026

AprÃ¨s le lancement direct de 19:52:59 UTC, le fond choisi Ã©tait `il2-2001-box` (IL-2 Sturmovik 2001 â€” jaquette), position 1. Le relancement demandÃ© Ã  19:56:58 UTC a crÃ©Ã© Ã  19:57:11 UTC un Ã©tat `last=background-3`, position 2, avec la mÃªme signature et le mÃªme cycle. Aucun Ã©tat n'a Ã©tÃ© modifiÃ© ou remis Ã  zÃ©ro par l'outil entre les deux processus. La crÃ©ation du nouvel Ã©tat suit l'acceptation native du matÃ©riau.

Alexis a ensuite confirmÃ© : Â« le changement fonctionne parfaitement Â». **Le changement visible entre ces deux lancements directs est validÃ© par l'utilisateur.** Le rapport [`loading-rotation-runtime-validation.json`](../manifests/loading-rotation-runtime-validation.json) conserve les deux Ã©tats, les heures, les identifiants de processus et la portÃ©e exacte du test. Les preuves brutes sont sous `WIP/loading-rotation-launches/20260911-195658Z`.

Cette confirmation couvre le changement observÃ© sur le profil 8 4.09m, avec les copies rÃ©duites. Elle ne constitue pas un essai de chacun des six profils ou d'un cycle complet de cinq passages. Les frÃ©quences et l'absence de rÃ©pÃ©tition sont par ailleurs couvertes par les tests de logique. La rotation est toujours activÃ©e avec les quatre images, le mode mÃ©langÃ© et le fond officiel doublÃ© ; les options de dÃ©sactivation et retrait sont conservÃ©es.


## Essai du profil 4.09m mods 6DOF â€” 11 septembre 2026

Ã€ la demande d'Alexis de lancer un autre profil, la copie isolÃ©e est passÃ©e du profil 8 au **profil 9 (4.09m mods 6DOF)**. Le switcher a validÃ© toutes ses sources sans modification. Douze ressources actives communes ont ensuite Ã©tÃ© comparÃ©es par SHA-256 Ã  celles du profil 9 : elles Ã©taient dÃ©jÃ  identiques. Seuls l'EXE diffÃ©rent et le fichier d'Ã©tat du profil ont Ã©tÃ© actualisÃ©s, aprÃ¨s sauvegarde et vÃ©rification de fermeture de cette installation. EXE 6DOF actif : `F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E`. Les classes de rotation sont inchangÃ©es.

Lancement direct Ã  20:04:55 UTC, PID 11640. Ã€ 20:05:10 UTC, le moteur a acceptÃ© le matÃ©riau **`il2-2001` (fond officiel IL-2 Sturmovik 2001 Retail)** et la rotation est passÃ©e de la position 2 Ã  la position 3, avec la mÃªme signature et le mÃªme cycle. L'acceptation et la continuitÃ© de sÃ©lection sont vÃ©rifiÃ©es. Alexis a ensuite confirmÃ© visuellement ce lancement : Â« ca marche Â». La rotation observÃ©e est donc Ã©galement validÃ©e sur le profil 4.09m mods 6DOF.

Preuves et sauvegardes du profil prÃ©cÃ©dent : `WIP/loading-rotation-launches/20260911-200455Z-profile9`. Le manifeste `manifests/loading-rotation-runtime-validation.json` conserve aussi cet essai, sÃ©parÃ© de la confirmation visuelle du profil 8. Le changement reste limitÃ© Ã  cette copie et n'affecte pas le checkout partagÃ©.


## Validation par Alexis et arrÃªt des essais

Le 11 septembre 2026, Alexis a demandÃ© l'arrÃªt des essais et validÃ© la modification : Â« on s'arrete lÃ . On valide Â». La validation en jeu couvre les profils **4.09m mods NO 6DOF** et **4.09m mods 6DOF**. La fonctionnalitÃ© reste dÃ©sactivable et rÃ©versible. Aucun essai des autres profils n'est prÃ©sentÃ© comme rÃ©alisÃ©.


## Mise Ã  jour depuis GitHub v1.15 â€” 11 septembre 2026

Ã€ la demande dâ€™Alexis, la branche isolÃ©e `codex/rotation-fonds` a intÃ©grÃ© `v1.15` depuis GitHub, commit `b3ed8a505ece716a0c5ec1764f4d37c2bfff2f11`. La fusion `3fe2d3bad` sâ€™est terminÃ©e sans conflit. Le code et les ressources de rotation sont inchangÃ©s. Le checkout partagÃ© reste sur `v1.15` et nâ€™a pas Ã©tÃ© modifiÃ©.

La copie de test conserve le profil 9, 4.09m mods 6DOF, avec les nouveaux EXE et SFS du manifeste. Les onze autres fichiers que le switcher aurait copiÃ©s correspondent dÃ©jÃ  aux sources du profil. Les fichiers de configuration, les quatre fonds actifs et les sauvegardes de rÃ©versibilitÃ© sont conservÃ©s Ã  lâ€™octet prÃ¨s ; lâ€™Ã©tat reste en position 3, dernier fond `il2-2001`. Les 1 116 suppressions antÃ©rieures de `PaintSchemes/Cache` sont maintenues. Les suppressions et renommages apportÃ©s par GitHub sont conservÃ©s.

Le switcher valide le profil 9, le module le reconnaÃ®t comme moddÃ©, les empreintes EXE/SFS des neuf profils correspondent au manifeste et les **78 contrÃ´les dâ€™installation, dÃ©sactivation et retrait passent sous PowerShell 5.1**. Aucun jeu nâ€™a Ã©tÃ© lancÃ© pour cette mise Ã  jour. Les essais visuels prÃ©cÃ©dents restent des preuves historiques portant sur leurs anciens EXE/SFS. RÃ©sultats : [`loading-rotation-v115-update.json`](../manifests/loading-rotation-v115-update.json). La sauvegarde exacte et la mise en rÃ©serve Git restent dans la copie isolÃ©e ; leur inventaire figure dans ce rapport.

La réextraction de `ConsoleGL0` depuis les six nouvelles archives moddées confirme son identité complète avec la source du correctif : 4 402 octets, Java 47, SHA-256 `1C36806AA965835949125E09518425DD45D6E927EB1E055B3E701A5647215D9C`. Les nouveaux chemins et empreintes figurent dans la provenance de la classe ; les anciennes sources restent dans son historique.
