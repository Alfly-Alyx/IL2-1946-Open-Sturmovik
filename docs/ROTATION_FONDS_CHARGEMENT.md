# Rotation des fonds de chargement Open Sturmovik

État du 11 septembre 2026 — Open Sturmovik v1.15, profils moddés 4.08m, 4.09b et 4.09m, avec ou sans 6DOF. Développement isolé sur `codex/rotation-fonds`. La logique est testée hors jeu. Le premier lancement natif a atteint le helper, mais refusé la texture 1586 × 992. Les copies ont ensuite été réduites sous 4,20 Mo. Deux lancements directs successifs ont changé de fond ; Alexis a confirmé visuellement que le changement fonctionne parfaitement.

## Utilisation et principe

Après installation et activation, le choix du fond intervient **dans le démarrage du jeu**. On continue donc à ouvrir `il2fb.exe` ou son raccourci habituel. La fenêtre `Open_Sturmovik_Fonds.vbs`, également accessible par `Open_Sturmovik_Fonds.bat`, sert seulement à installer et régler la fonctionnalité. Son interface est portée par `tools/Manage-LoadingRotation.ps1`.

L'installation laisse la rotation **désactivée**. Dans la fenêtre, choisir de deux à quatre images, puis le mode ordonné ou mélangé. On peut désigner un fond « officiel » : il apparaîtra deux fois par cycle, les autres une fois. Cette préférence exige au moins trois images ; avec seulement deux images, des fréquences 2:1 rendraient inévitable une répétition consécutive.

Avec quatre images dont une officielle, cinq passages peuvent donner : **Officiel → A → Officiel → B → C**. Le cycle suivant respecte aussi la différence avec le dernier fond précédent. En mode mélangé, l'ordre varie tout en conservant ces fréquences exactes. Sans fond officiel, chaque image apparaît une fois par cycle.

Alexis a retenu les quatre fichiers suivants le 11 septembre 2026. Les originaux PNG restent intacts dans le paquet du jeu, sous `_Game Switcher/Resources/Loading Rotation/Sources`. Leurs copies TGA destinées au moteur sont installées dans **`Files/gui/backgrounds`**, à côté de leurs matériaux. Aucune dépendance au dossier externe de ressources n'est nécessaire pour jouer.

| Fichier source sélectionné | Fichier utilisé dans le jeu | Passages par cycle |
| --- | --- | ---: |
| Forgotten Battles - jaquette remaster 1586x992 - logo gauche.png | `forgotten-battles-box.tga` | 1 |
| IL-2 Sturmovik 2001 Retail - remaster 1586x992.png | `il2-2001.tga` | **2** |
| 3.png | `background-3.tga` | 1 |
| IL-2 Sturmovik 2001 - jaquette remaster 1586x992.png | `il2-2001-box.tga` | 1 |

Les noms internes courts servent à éviter les espaces et accents dans les chemins du moteur. Le catalogue conserve les noms source exacts et leurs empreintes. Le champ `weight` décrit la préférence choisie ; la configuration enregistrée (`official=il2-2001`) applique le double passage.

Le mécanisme choisit un matériau déjà installé. Il ne recopie pas les images à chaque lancement et ne remplace jamais `Files/gui/Background.tga`, les matériaux `background0*.mat` existants ou les fonds à la racine de `Files`. Les profils Originaux du switcher retirent le wrapper : leurs classes d'origine restent utilisées et la rotation intégrée aux classes libres du mod ne s'exécute pas.

## Implantation vérifiée et fichiers

Le correctif ajoute un appel à `OpenSturmovikLoadingRotation.choose(String)` au début de `ConsoleGL0.exclusiveDraw(String)`. Il ne traite que la demande `gui/background0.mat`. Une première décision est conservée pendant tout le processus : plusieurs appels de chargement ne consomment pas plusieurs images. Si le helper manque ou échoue, le bloc ajouté laisse continuer la méthode d'origine avec son fond initial.

| Élément | Emplacement ou rôle |
| --- | --- |
| Classe `ConsoleGL0` adaptée | `Files/B96FAC8E2C4DDBE0` |
| Helper Java 47 / Java 1.3 | `Files/F35AD7F42DE76ABC` |
| Images et matériaux ajoutés | `Files/gui/backgrounds/<id>.tga` et `<id>.mat` |
| Variantes linguistiques ajoutées | `<id>_cs.mat`, `_de.mat`, `_fr.mat`, `_ru.mat`, vers la même texture |
| Choix utilisateur | `Files/gui/backgrounds/rotation.properties` |
| Suivi des passages | `.open-sturmovik-loading-rotation/state.properties` |
| Inventaire et sauvegardes | `.open-sturmovik-loading-rotation/installation.json` et `backups/<SHA256>.bin` |

La configuration utilise les propriétés `enabled`, `images` (identifiants séparés par des virgules), `official` (identifiant ou vide) et `mode` (`shuffle` ou `ordered`). Le helper contrôle l'existence des matériaux, les TGA RGB 24 bits non compressés et la différence des empreintes des images. Il précharge le matériau avec `Mat.New` avant de valider le passage suivant.

L'état contient `schema=1`, une signature SHA-1 de la sélection, des empreintes des images et du mode, le `cycle` complet, sa `position` et le dernier identifiant `last`. Le cycle demeure ainsi cohérent entre les démarrages. Un changement de sélection produit une nouvelle signature et reconstruit le cycle en tenant compte du dernier identifiant.

`selection.lock`, créé exclusivement par `File.createNewFile`, empêche deux sélections simultanées. L'écriture utilise `state.next`, puis conserve temporairement l'ancien état dans `state.previous`. Une interruption peut être récupérée au démarrage suivant. Un état incohérent, un fichier manquant, un matériau impossible à charger ou une écriture impossible entraîne le retour au fond initial. Les dossiers rencontrés à la place des fichiers d'état sont préservés.

## Désactivation et retour à l'état antérieur

Toutes les opérations de gestion s'effectuent jeu fermé. `Install` vérifie le profil par les empreintes de l'EXE, de `files.SFS` et du wrapper, installe les deux classes et les ressources, puis laisse `enabled=false`. Une autre surcharge inconnue de `ConsoleGL0` fait refuser l'installation.

`Disable` remet `enabled=false` et conserve les ressources pour une réactivation. `Remove` retire les fichiers ajoutés ou restitue leurs octets précédents lorsque ces fichiers existaient déjà. L'inventaire mémorise aussi leur absence initiale. Les sauvegardes sont vérifiées par SHA-256 ; un journal permet de rétablir les fichiers si une opération de gestion échoue.

Une image ou un matériau modifié manuellement après installation est conservé lors du retrait ; sa texture associée peut également être conservée. Une modification manuelle d'une des classes installées bloque le retrait automatique plutôt que d'effacer une modification étrangère. Les sauvegardes, l'inventaire et l'historique des passages restent disponibles dans le dossier de suivi ; le retrait n'est pas un nettoyage récursif de ce dossier. Aucun EXE ni SFS n'est modifié par cette installation.

## Aide-mémoire PowerShell

Dans Windows PowerShell 5.1, depuis le dossier du paquet, définir `$jeu` sur **la copie de jeu à équiper**. Les identifiants ci-dessous reprennent la sélection finale d'Alexis.

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

Omettre `-OfficialId` donne des fréquences égales ; `-Mode ordered` choisit l'ordre déterministe. La fenêtre de réglage évite de saisir ces commandes. Pour jouer ensuite, utiliser normalement l'exécutable ou son raccourci, avec le dossier du jeu comme répertoire de travail.

## Sources, reproduction et niveau de preuve

**Faits vérifiés dans les fichiers locaux, confiance élevée.** La priorité de recherche a été donnée à `D:\Projets\GITHUB\#res\IL2 1946`, notamment aux collections `background`, puis aux archives de profils du paquet. La classe source `ConsoleGL0`, extraite en lecture seule par `tools/Analyze-Sfs.py` / `SfsArchive.extract_class`, est identique dans les six profils moddés. Les détails et empreintes de chaque archive sont conservés dans `test-assets/loading-rotation/ConsoleGL0.provenance.json`. Sa taille est de 4 402 octets, son format Java est 47 et son SHA-256 est :

`1C36806AA965835949125E09518425DD45D6E927EB1E055B3E701A5647215D9C`.

Le désassemblage local de cette classe montre la tentative de matériau suffixé par la langue avant le matériau générique. C'est pourquoi l'installation ajoute les variantes linguistiques. Le fichier d'analyse préexistant `WIP/sdk/nuclear-real-api/pause-engine-decompiled/com/maddox/il2/game/Main3D.java`, ligne 703 dans le checkout de référence, appelle `exclusiveDraw("gui/background0.mat")` lorsque `UseStartLog` est désactivé. Ce dernier fichier est une observation de décompilation 4.09m ; il ne constitue pas à lui seul une preuve d'identité avec toute classe active future.

Reproduction depuis la copie de développement :

```powershell
javap -c -p .\test-assets\loading-rotation\ConsoleGL0.class
.\tools\Build-LoadingRotationPatch.ps1 `
    -PackageRoot '_Game Switcher\Loading Rotation Patch'
.\tools\Test-LoadingRotation.ps1
```

La construction vérifie l'empreinte source, l'unicité du point d'appel, le gestionnaire de repli et les autres méthodes inchangées. ASM analyse le bytecode produit ; les deux classes distribuées sont de version 47. La conversion du helper remplace notamment les références `StringBuilder` par `StringBuffer` et refuse les instructions modernes incompatibles détectées.

**Résultats reproductibles hors jeu.** Le 11 septembre, 18 scénarios ont réussi sur le helper source puis sur le helper Java 47 exact du paquet : **5 949 assertions par variante**, soit 11 898 au total, avec Java 17 et `-Xverify:all`. Ils couvrent fréquences, frontières de cycles, persistance, absence d'écriture désactivée, corruption, images identiques ou absentes, verrou occupé, échec de `Mat.New`, reprise et panne d'écriture après préchargement. Le moteur graphique est remplacé par un stub réservé aux tests. Rapport : `build/loading-rotation-test-run-985d7a54ff174f959e8f98a749875a4f/result.json`.


Les PNG sources de la sélection finale ont été copiés sans modification depuis `D:\Projets\GITHUB\#res\IL2 1946\background\OS backgrounds\Remasterized Backgrounds`. Après conversion sous Windows PowerShell 5.1, un décodage indépendant avec Pillow a comparé les **1 573 312 pixels RGB de chacune des quatre images** : dimensions, contenu et empreintes concordent. Les TGA finaux sont non compressés, RGB 24 bits, origine en bas à gauche (descripteur 0), comme le fond existant de référence 2880 × 2160. Le générateur inverse uniquement l'ordre de stockage des lignes du PNG ; les pixels décodés et l'orientation visible sont inchangés. Les dimensions 1586 × 992 restent à qualifier dans le moteur natif.

`Mat.New` appelle `FObj.Get`, dont `GetFObj(String)` est natif ; `Mat.tgaInfo` et `Mat.LoadTextureAsArrayFromTga` sont également natifs dans les classes extraites du `files.SFS` 4.09m. Le stub Java ne constitue donc aucune preuve des dimensions acceptées, de l'affichage natif ni des limites graphiques.


Ces deux classes sont identiques entre les archives 4.08m, 4.09b et 4.09m examinées ; les paires avec/sans 6DOF partagent déjà leurs archives SFS. SHA-256 de `Mat` : `0FFB304164E37CEB2007D199BF0FD9BD7593BEAD04B02CBBFB6DF667154D779E` ; de `FObj` : `9A7C5B22CAC402B61DD4DD8FA03973FC892AC647D70EF4230ED207DE481F8A53`. Reproduction en lecture seule : extraire ces classes avec `SfsArchive.extract_class`, puis utiliser `javap -c -p` pour voir l'appel `Mat.New(String)` et les déclarations `native`. Confiance élevée pour cette identité et cette signature Java ; comportement natif non mesuré.


**Gestion et installation.** Les 78 contrôles Windows PowerShell 5.1 ont réussi avec la sélection finale : installation désactivée, activation, restauration octet pour octet, conservation des modifications manuelles, conflits, sauvegarde corrompue et interruption réelle par verrouillage de fichiers. Rapport : `build/loading-rotation-install-tests/run-680e8e53ff94445fa631b80ef689f44f/report.json`. Ces contrôles couvrent le chemin final `Files/gui/backgrounds` et les TGA définitifs d'origine bas-gauche. Les 27 fichiers installés ont aussi été vérifiés individuellement contre leurs empreintes après activation.

Dans **`C:\Users\Alexis\.codex\rotation-fonds`**, la configuration finale est maintenant **activée**, avec les quatre images et `official=il2-2001`, `mode=shuffle`. Le dossier partagé reste sur `v1.15` et n'a reçu aucun de ces fichiers. Le paquet suivi par Git contient les sources, classes et outils ; les fichiers actifs générés et les sauvegardes sont ignorés par Git. Après récupération du paquet dans une autre copie complète du jeu, utiliser la fenêtre ou la procédure d'installation ci-dessus pour produire ces fichiers actifs.

Le manifeste léger `manifests/loading-rotation-verification.json` conserve les résultats et empreintes finaux. Une copie du module, de ses outils et de ses sources est classée dans `D:\Projets\GITHUB\#res\IL2 1946\Mods\Reserve\Open Sturmovik - rotation fonds v1.15 - 2026-09-11`. Ce classement correspond à l'attente de validation native : le module est préparé dans la copie de développement, pas intégré au dossier partagé. L'archive contient le module de rotation complet, pas une installation complète d'IL-2.

**Sources communautaires, portée limitée.** Le [retour Mission4Today sur le premier écran de chargement](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=14751&view=next), relu le 11 septembre, confirme un remplacement par TGA et matériaux GUI en 4.09m ; il ne démontre pas cette rotation Java. Le précédent [SAS Modact 5.3 / IL-2 4.12.2m](https://www.sas1946.com/main/index.php?topic=37662.0) mentionne `RandomSplash` dans les éléments indexés de l'étude initiale. Sa page directe renvoie 403 : aucune compatibilité avec ce pack n'est établie et aucun composant SAS de cette version n'est repris. [AAA via Wayback](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/), consulté en priorité, reste inaccessible ; aucun contenu supposé n'est utilisé.

## Limites restant à valider

La JVM 1.3 embarquée a été exécutée lors du premier essai. Le helper est atteint, mais le moteur natif refuse la taille de texture préparée. La copie initiale ne possédait pas les dépendances du jeu de base ; la préparation décrite ci-dessous les a ajoutées avant cet essai. Les tests ne prouvent donc pas l'affichage effectif, le bon cadrage des images 1586 × 992 ni le comportement du wrapper sur les six profils. Ces essais restent nécessaires, ainsi qu'un retour au profil Original pour confirmer visuellement son fond habituel. La fenêtre de gestion a été rendue et contrôlée visuellement sous Windows PowerShell 5.1 ; cela ne valide pas le rendu des textures par le jeu. Avec `UseStartLog` actif, le démarrage observé utilise la console et ne demande pas ce fond.

Un arrêt forcé pendant la sélection peut laisser `selection.lock`. Les démarrages suivants gardent alors le fond initial ; une désactivation ou réactivation par l'outil, jeu fermé, retire ce verrou résiduel. Un arrêt après validation de l'état peut consommer un passage même si l'image n'a pas été vue : l'état enregistre une sélection préchargée, pas une preuve d'affichage. Ces limites sont distinctes de la réversibilité des fichiers installés.

## Préparation au lancement — 11 septembre 2026

État historique avant le premier essai : la copie `C:\Users\Alexis\.codex\rotation-fonds` était préparée sans avoir été lancée. Le lancement décrit ci-dessous a ensuite été demandé explicitement par Alexis. Le profil 8 est sélectionné : Open Sturmovik 4.09m sans 6DOF, wrapper historique, DirectX et fenêtre 1024 × 768. Ces réglages proviennent de la copie de test historique ; la rotation reste activée avec les quatre images finales et le fond officiel doublé. `UseStartLog` est absent de `[Console]` : la valeur initiale `false` observée dans `Main3D` conserve le chemin du fond graphique.

Les **49 contrôles de préparation passent**, ainsi que les 25 contrôles de contenu. Le seul avertissement de contenu concerne l'absence normale de vérification par dump d'une exécution, puisque le jeu reste fermé. Les 27 fichiers de rotation correspondent toujours à leurs empreintes. Le manifeste `manifests/loading-rotation-preparation.json` conserve les résultats, les provenances et les empreintes. Cette préparation ne valide ni l'affichage natif ni toutes les fonctions du jeu.

**Provenance vérifiée.** Les 134 fichiers absents ajoutés représentent 2 307 720 642 octets : 45 SFS historiques, `bin` et `lib`, trois DLL de base et les paramètres nécessaires au test. Ils proviennent exclusivement de la copie historique `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test`, restée en lecture seule. Sa reconstruction DVD 4.07m puis correctifs 4.09m est décrite dans `PROTOCOLE_PREMIER_LANCEMENT.md` et ses démarrages dans `RESULTATS_TESTS_DEMARRAGE_2026-08-30.md`. Le déplacement de cette copie est tracé dans `manifests/test/local-layout-v1.15.json`. Les 52 archives présentes et 17 empreintes de référence ont été contrôlées avant copie. Chaque fichier ajouté a ensuite été comparé par SHA-256 à sa source.

La recherche prioritaire dans `#res/IL2 1946` a également retrouvé l'ISO DVD authentique, vérifié contre son `SOURCE.txt` : SHA-256 `7BA9629BD21B7D4A44AB022FB7AD28E328543F84412113A67C1E03E7747FED78`, taille 3 609 690 112 octets, volume DISK1 du 14 novembre 2006. L'ISO n'a pas été extrait pour cette préparation. Les dossiers intitulés `_4.09m` et l'ancienne référence `WIP/resources/IL2/IL 2 Sturmovik 1946` contiennent désormais des fichiers postérieurs à 4.09m : ils n'ont pas servi de donneurs. Un nom de dossier ne suffit pas à établir une version.

**Compatibilité Java statique.** Le `rt.jar` du donneur annonce Java 1.3.1. La comparaison des références des deux classes du correctif avec ses 5 251 classes, méthodes et champs ne révèle aucune API manquante. Le contrôle s'appuie sur le parseur `tools/Audit-JavaClasses.py`, sans exécuter la JVM. Les CRC centraux incohérents du JAR correspondent à l'anomalie historique décrite dans `docs/AUDIT_CLASSES_JAVA.md` ; aucune réparation du JAR n'a été faite. Le comportement graphique demeure natif et non testé.

**Écarts de copie corrigés.** Git avait converti des fins de ligne mixtes. Le matériau de référence du switcher manquait aussi de son dossier de ressources. `stationary.ini` et sept fichiers texte ont été restitués aux octets de référence uniquement après preuve que CRLF/LF constituait toute la différence, puis les contrôles ont été repassés sans exception autorisée. Le fond Maddox 4:3 requis par le switcher a été copié depuis `Files/background0.tga`, dont le SHA-256 correspond exactement à l'empreinte attendue `E1C0BFB53AE7E5891BF7A4F8333D33F119B177E373DBE8B6BBEC3014EC7CB898` ; aucun visuel n'a été fabriqué ou adapté.

Les sauvegardes et rapports de préparation restent dans `WIP/loading-rotation-preparation-20260911`. Les fichiers du jeu de base sont exclus localement du suivi Git et ne sont pas ajoutés au paquet distribué. Les remplacements du profil ont été précédés d'une sauvegarde. Le dossier partagé est toujours sur `v1.15` et n'a pas été modifié par cette préparation.
## Premier lancement natif — échec du chargement de la nouvelle texture

Essai du 11 septembre 2026, démarré à 18:18:16 UTC : exécutable de la copie isolée, profil 8 (4.09m moddé sans 6DOF), DirectX, fenêtre 1024 × 768. La capture fournie par Alexis montre le fond russe historique. La mention Windows « Ne répond pas » n'est pas le problème étudié, conformément à sa précision. Aucun réglage réseau ou de démarrage n'a été changé pour ce diagnostic.

**Faits vérifiés, confiance élevée.** Le journal conservé dans `WIP/loading-rotation-launches/20260911-181816Z/log.lst` donne à 18:18:31 :

```text
INTERNAL ERROR: Texture Buffer (limit 4202496 Bytes)is to small to fit 4719936 Bytes!
WARNING: object 'gui/backgrounds/forgotten-battles-box.tga' of class 'TTexture2D' not loaded
INTERNAL ERROR: Texture required
WARNING: object 'gui/backgrounds/forgotten-battles-box.mat' of class 'TMaterial' not loaded
```

4 719 936 = 1586 × 992 × 3 : la texture RGB24 préparée dépasse le tampon indiqué. Le nom précis du nouveau matériau dans le journal prouve que l'appel ajouté a été exécuté et que le moteur a tenté ce chargement. Ce défaut ne peut donc pas être expliqué uniquement par un nom de fichier erroné. L'absence de `state.properties` est cohérente avec le retour sans validation lorsque `Mat.New` échoue. Le journal ne contient pas de message d'erreur Java du helper.

Le repli vers `gui/background0_ru.mat` tente ensuite `gui/background.tga`, également refusé : 18 662 400 octets pour la même limite. La capture montre alors le fond russe ; l'identité exacte de la ressource finalement affichée doit être recoupée avec l'analyse du SFS. Les 8192 pixels maximum annoncés par le pilote ne prouvent pas que le chargeur du moteur accepte une texture de cette taille.

SHA-256 du journal : `E1546123324F15E3BB9C7B95D7AE31B769A0280E46287C9A8B39F4812299DAE8`. La capture utilisateur est `C:/Users/Alexis/Desktop/1.png`. La session du journal se termine à 18:20:06 UTC ; le processus lancé n'était plus présent lors du contrôle suivant. Ce constat ne permet pas d'attribuer la fermeture à une cause précise.

**À déterminer.** Dimensions et format acceptés par le chargeur natif pour les quatre images ; rendu et cadrage après correction ; comportement des autres profils. Les tests hors jeu précédents restent des preuves de logique et de restauration des fichiers, pas des preuves de compatibilité graphique des textures 1586 × 992.
### Recoupement des noms et des formats

L'extraction en lecture seule de `files.SFS` **de cette copie**, SHA-256 `18F3C5471D93642916394DE53B482051106E024DDAC8124C7B0D700D1796B05A`, confirme que `gui/background0.mat` et `gui/background0_ru.mat` pointent tous deux sur `background0.tga`. Les deux matériaux ont le SHA-256 `776C9605A9432485B6E67D0F0A69684615362C59F6B6E969CE040F011BB821BC`. La texture interne est un IMF10 1024 × 1024, SHA-256 `AC3314AC8A8A1D3F5AC1B44BA34E3CCCE500ABB7EED342D1CFD710A437F6AA0B`. Les variantes libres du paquet pointent, elles, sur `background.tga`. Il existe donc réellement deux noms dans la chaîne de repli ; cela n'annule pas l'erreur de taille de notre texture, dont le chemin a été trouvé et tenté.

Reproduction : `python tools/Analyze-Sfs.py inspect files.SFS --path gui/background0.tga --path gui/background0_ru.mat --path gui/background0.mat --output WIP/loading-rotation-launches/20260911-181816Z/sfs-backgrounds`. Cette commande produit des copies de diagnostic et n'écrit pas dans l'archive.

La chaîne d'erreur du tampon se trouve dans les DLL natives officielles du cœur 4.09m : offset fichier `0x1253E0` dans `il2_core.dll` et `0x1393E8` dans `il2_corep4.dll` (recherche binaire en lecture seule). L'annonce de 8192 pixels par le pilote n'augmente donc pas nécessairement cette limite du chargeur.

La ressource locale `#res/IL2 1946/Packs/AAA_Community_Installer_ver_1_1/MODS/SplashScreen/GUI/background.tga` est un TGA RGB24 1024 × 768, origine basse, avec les mêmes paramètres de matériau. Les textures officielles extraites donnent également des exemples 512 × 512. Une copie plus petite est donc une piste étayée ; les dimensions particulières choisies restent à essayer dans ce pack. Compresser le fichier sur disque (RLE, IMF ou autre) ne constitue pas une preuve de réduction du tampon RGB demandé après décodage.

Une autre piste communautaire est le mod [High Resolution / True Color Textures](https://www.sas1946.com/main/index.php?topic=33239.0), dont l'annonce indexée mentionne une prise en charge depuis 4.09m. [Mission4Today](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=23378) décrit une correction de cette erreur avec des DLL HD sur 4.12.2. La page SAS directe reste inaccessible (403). La compatibilité des DLL et classes de ce mod avec notre pack exact n'est pas établie : aucun fichier de ce mod n'a été installé. Un choix entre l'adaptation des copies d'images et l'étude du correctif HD a été présenté à Alexis avant tout changement de ce type.

## Correction des copies sous 4,20 Mo — 11 septembre 2026

Alexis a demandé de réduire les fichiers après le constat natif. Les quatre TGA du paquet et leurs copies actives dans `Files/gui/backgrounds` sont désormais en **1495 × 935**, **4 193 493 octets chacune**. Réduction bicubique de qualité, sans recadrage, ratio conservé à l'arrondi près (écart de 0,00877 %). Les PNG 1586 × 992 restent intacts ; leurs SHA-256 sont identiques au catalogue précédent. Les TGA demeurent RGB24 non compressés, origine en bas à gauche.

`Build-LoadingRotationAssets.ps1` ajuste les dimensions au budget de 4 200 000 octets, en-tête compris, puis vérifie le décodage. Le lecteur du catalogue refuse aussi les fichiers dépassant ce plafond. Les quatre fichiers ont été décodés indépendamment avec Pillow et contrôlés visuellement. La réinstallation suit `Remove → Install → Enable` pour mettre à jour l'inventaire de restauration et conserver la sélection, le mode mélangé et le double passage officiel. La détection d'un jeu ouvert porte sur l'installation ciblée ; un chemin de processus inconnu bloque toujours la modification.

Les **78 contrôles d'installation/restauration réussissent** avec ces nouvelles images, ainsi que neuf cas simulés de détection des processus sous PowerShell 5.1. Les jeux de données de test conservent désormais le wrapper lorsqu'ils reproduisent un profil moddé. Le jeu n'a pas été relancé pour cette correction : le respect du plafond est vérifié, le rendu natif des nouvelles dimensions reste à confirmer.

Rapports : `WIP/loading-rotation-resize-20260911/images-verification.json`, `installation-verification.json` dans le même dossier, et `build/loading-rotation-install-tests/resize-20260911/report.json`. Les TGA précédents, scripts, catalogue et inventaire sont sauvegardés sous `WIP/loading-rotation-resize-20260911/before`. La limite exacte du moteur et ses preuves sont aussi conservées dans [`AUDIT_CHARGEMENT_TEXTURES_4.09M.md`](AUDIT_CHARGEMENT_TEXTURES_4.09M.md) et indexées dans la référence de rétro-ingénierie.


## Validation du changement au relancement — 11 septembre 2026

Après le lancement direct de 19:52:59 UTC, le fond choisi était `il2-2001-box` (IL-2 Sturmovik 2001 — jaquette), position 1. Le relancement demandé à 19:56:58 UTC a créé à 19:57:11 UTC un état `last=background-3`, position 2, avec la même signature et le même cycle. Aucun état n'a été modifié ou remis à zéro par l'outil entre les deux processus. La création du nouvel état suit l'acceptation native du matériau.

Alexis a ensuite confirmé : « le changement fonctionne parfaitement ». **Le changement visible entre ces deux lancements directs est validé par l'utilisateur.** Le rapport [`loading-rotation-runtime-validation.json`](../manifests/loading-rotation-runtime-validation.json) conserve les deux états, les heures, les identifiants de processus et la portée exacte du test. Les preuves brutes sont sous `WIP/loading-rotation-launches/20260911-195658Z`.

Cette confirmation couvre le changement observé sur le profil 8 4.09m, avec les copies réduites. Elle ne constitue pas un essai de chacun des six profils ou d'un cycle complet de cinq passages. Les fréquences et l'absence de répétition sont par ailleurs couvertes par les tests de logique. La rotation est toujours activée avec les quatre images, le mode mélangé et le fond officiel doublé ; les options de désactivation et retrait sont conservées.


## Essai du profil 4.09m mods 6DOF — 11 septembre 2026

À la demande d'Alexis de lancer un autre profil, la copie isolée est passée du profil 8 au **profil 9 (4.09m mods 6DOF)**. Le switcher a validé toutes ses sources sans modification. Douze ressources actives communes ont ensuite été comparées par SHA-256 à celles du profil 9 : elles étaient déjà identiques. Seuls l'EXE différent et le fichier d'état du profil ont été actualisés, après sauvegarde et vérification de fermeture de cette installation. EXE 6DOF actif : `F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E`. Les classes de rotation sont inchangées.

Lancement direct à 20:04:55 UTC, PID 11640. À 20:05:10 UTC, le moteur a accepté le matériau **`il2-2001` (fond officiel IL-2 Sturmovik 2001 Retail)** et la rotation est passée de la position 2 à la position 3, avec la même signature et le même cycle. L'acceptation et la continuité de sélection sont vérifiées. Alexis a ensuite confirmé visuellement ce lancement : « ca marche ». La rotation observée est donc également validée sur le profil 4.09m mods 6DOF.

Preuves et sauvegardes du profil précédent : `WIP/loading-rotation-launches/20260911-200455Z-profile9`. Le manifeste `manifests/loading-rotation-runtime-validation.json` conserve aussi cet essai, séparé de la confirmation visuelle du profil 8. Le changement reste limité à cette copie et n'affecte pas le checkout partagé.


## Validation par Alexis et arrêt des essais

Le 11 septembre 2026, Alexis a demandé l'arrêt des essais et validé la modification : « on s'arrete là. On valide ». La validation en jeu couvre les profils **4.09m mods NO 6DOF** et **4.09m mods 6DOF**. La fonctionnalité reste désactivable et réversible. Aucun essai des autres profils n'est présenté comme réalisé.
