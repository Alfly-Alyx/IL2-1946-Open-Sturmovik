# Rotation des fonds de chargement Open Sturmovik

État du 11 septembre 2026 — Open Sturmovik v1.15, profils moddés 4.08m, 4.09b et 4.09m, avec ou sans 6DOF. Développement isolé sur `codex/rotation-fonds`. La logique est testée hors jeu ; la validation dans le moteur natif reste à effectuer.

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

La JVM 1.3 embarquée et le rendu natif n'ont pas été exécutés. La copie de base disponible pour cette étape ne contient pas les bibliothèques embarquées `bin/java.dll` et `bin/hotspot/jvm.dll` (dépendances décrites dans `docs/DOSSIER_TECHNIQUE_IL2_1946.md`) ni tous les fichiers du jeu de base ; elle ne permet donc pas un essai complet du jeu. Les tests ne prouvent donc pas l'affichage effectif, le bon cadrage des images 1586 × 992 ni le comportement du wrapper sur les six profils. Ces essais restent nécessaires, ainsi qu'un retour au profil Original pour confirmer visuellement son fond habituel. La fenêtre de gestion a été rendue et contrôlée visuellement sous Windows PowerShell 5.1 ; cela ne valide pas le rendu des textures par le jeu. Avec `UseStartLog` actif, le démarrage observé utilise la console et ne demande pas ce fond.

Un arrêt forcé pendant la sélection peut laisser `selection.lock`. Les démarrages suivants gardent alors le fond initial ; une désactivation ou réactivation par l'outil, jeu fermé, retire ce verrou résiduel. Un arrêt après validation de l'état peut consommer un passage même si l'image n'a pas été vue : l'état enregistre une sélection préchargée, pas une preuve d'affichage. Ces limites sont distinctes de la réversibilité des fichiers installés.
