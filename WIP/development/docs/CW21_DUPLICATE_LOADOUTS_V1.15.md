# CW-21 : doublons d'armement, 7 septembre 2026

## Observation et cause

Alexis signale `4 x .303` et `sans armement` deux fois dans l'editeur.
La session est fermee avant intervention. Les trois cles de
`weapons_ru.properties` sont pourtant uniques dans le depot et le test.

Fait verifie, confiance elevee : `Aircraft.weapons(Class)` importe les
configurations `cod` et appelle sans controle `ArrayList.add(nom)` sur la
propriete existante `weaponsList`, puis `HashMapInt.put(Finger.Int(nom), slots)`.
La table remplace sa valeur ; la liste accumule les noms.
`getWeaponsRegistered` retourne toute la liste, sans dedoublonnage.
Classe effective : `Files/4B598398AD1D180C`, SHA-256
`FB7195C376A0ACDD3E4A21A4DB220BB1A2EB1C52BFF166DC5BE022C4FD67DCA4`.
Cette classe globale n'est pas modifiee.

Le precedent test ne couvrait que l'initialiseur. Il manquait l'import tardif
des deux configurations d'origine, apres notre enregistrement des trois choix.

## Reproduction et limites du test

`tools/java/TestCW21Loadouts.java` execute maintenant aussi six methodes
extraites du vrai Aircraft : `weapons`, `getSwTbl`, `weaponsListProperty`,
`weaponsMapProperty`, `getWeaponsRegistered`, `getWeaponSlotsRegistered`.
Les noms de classes dependantes sont remappes vers des doubles minimaux.
L'entree SFS/Krypto est remplacee par une fixture des deux choix d'origine :
`default` (quatre Browning .303, 300 coups) et `none`. Finger utilise un hash
de substitution coherent, pas l'algorithme IL-2. Son champ kTable doit rester
un tableau de bytes (`[B`), comme la vraie signature.

Temoin negatif, ancienne classe active SHA-256
`2BF3C9625781A7116423BDD18764CAA3AA156C6C76DE20EB24F4A447DB87EE27` :
echec reproductible `late loader duplicated menu: [default, 2x303_2x50, none, default, none]`.
Cela reproduit exactement le symptome, sans constituer une trace du chargement
natif de la session. Causalite fortement etayee ; resolution visible en jeu
encore a confirmer.

Le test du candidat repete deux enregistrements, chacun suivi de deux imports
tardifs : exactement trois choix ordonnes, quatre slots et les calibres et
munitions attendus restent presents. Le nombre d'ecritures dans la table
prouve que l'import a fini ses deux lignes, meme si le chargeur absorbe les
exceptions. Le test ne valide ni dechiffrement SFS, ni affichage, ni tir.

## Correctif compatible, limite au CW-21

Une sous-classe Java 1.3 d'ArrayList,
`com.maddox.il2.objects.air.OpenSturmovikCW21LoadoutList`, refuse seulement
`add(Object)` si le meme nom existe deja. Le type attendu, le premier ordre
et les autres noms eventuels sont preserves. Seul le CW-21 utilise cette liste.
L'adresse canonique est calculee par `Analyze-Sfs.py` : Finger.Int de
`sdw<nom.qualifie>cwc2w9e`, puis Finger de `cod/<entier>`. L'adresse du CW_21
d'origine est verifiee comme temoin. Aucun chemin de classe n'est devine.

Sorties, SHA-256 :

- CW_21 `Files/F00C363EBB3865E8` :
  `6CB3045084C0B2337472FAD8C721941637D442391910AB05D731CAF3A41ED783`.
- Liste `Files/7F567DAABB958052` :
  `550EA60D46EFAA9F8D481A4D695109A99073C1BBC4040ED31F8B957A894FDC7B`.

Les classes de cockpit, les quatre points d'armes, les armes et munitions,
la physique, les marquages, le son et Buttons sont inchanges. Inventaire :
six classes au lieu de cinq, plus les memes 165 ressources de cockpit.
L'audit des signatures contre l'API effective 4.09m et le rt.jar Java 1.3 passe.

Sauvegarde externe verifiee avant modification :
`D:\Projets\GITHUB\#res\IL2 1946\Sauvegarde_avant_correctifs_BI_CW21_v1.15_20260907`.
Le constructeur preserve aussi l'ancien CW_21 dans
`build/preservation/cw21-before-unique-loadouts`, et refuse toute ancienne
empreinte autre que celles explicitement connues.

## Commande de reproduction et sources

Le constructeur `Install-CW21Cockpit.py` compile les outils, produit les deux
classes, execute le test puis l'audit reel des dependances. Ses chemins source
restent ceux de `CW21_COCKPIT_ARMAMENT_V1.15.md`. Apres compilation :

```powershell
java --add-exports java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-exports java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED -cp build/aircraft-patcher TestCW21Loadouts Files/F00C363EBB3865E8 Files/4B598398AD1D180C Files/7F567DAABB958052
```

Sources prioritaires : archive locale `Mods/Utilisés/Cockpit_CW-21_for409.zip`
et classes du pack citees ci-dessus. Nouvel essai
[AAA/Wayback 2010](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/)
inaccessible, aucun contenu suppose.
[Discussion Mission4Today sur les choix du CW-21](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&p=91347)
consultee pour le contexte, pas pour importer du code 4.10.
[Documentation SAS AircraftTools](https://www.sas1946.com/downloads/essentialsas/common_utils/doc/com/maddox/sas1946/il2/util/AircraftTools.html)
confirme la methode historique weaponsRegister vide ; le diagnostic des
doublons repose sur le bytecode local et le test reproductible, pas sur une
bibliotheque SAS moderne. Aucune bibliotheque supplementaire n'est importee.

Le faible volume reste ouvert. La session du 7 septembre (journal UTC
03:16-03:22, fermeture normale) ne contient pas de chargement en vol CW-21
ni de ligne `[OS CW-21]` ; aucune nouvelle conclusion sonore n'en est tiree.
Synchronisation effectuee : `manifests/test/bi-cw21-dedup-v1.15.json`, trois
fichiers, sauvegarde et recu `WIP/tests/installations/sync-20260907-054352`.
Depot et copie de test ont les memes empreintes pour ces trois fichiers.
Le controle de contenu du test donne 24 PASS, 1 WARN (dump non fourni) et
1 FAIL connu pour les cinq profils AOC de test contre les 266 distribues.
Ces profils et les profils joueur ne sont pas modifies pendant ce correctif.
Le controle global `Test-V115OfflineReadiness.ps1` donne 6 PASS, 0 WARN,
0 FAIL : contenu du depot 25 PASS/1 WARN/0 FAIL, dix raccourcis temporaires,
neuf profils du switcher et deux HUD, inventaire AOC et protocole verifies.
Il ne lance pas le jeu ; le WARN de contenu correspond au dump runtime non fourni.
Prochain controle : trois choix visibles une seule fois, puis essai des deux
armements et relevement de la trace moteur. Aucun jeu relance pendant ce fix.
