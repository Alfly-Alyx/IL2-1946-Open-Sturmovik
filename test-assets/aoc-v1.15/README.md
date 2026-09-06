# Sources de reconstruction AOC 1a + Zuti 1.13

Ce dossier contient les six classes d'entree du constructeur
`tools/Build-OpenSturmovikAocZutiPatch.ps1`.

- `base-zuti` conserve les trois classes qui etaient actives dans Open
  Sturmovik avant la correction. Elles chargent le profil AOC mais seul le
  reglage des magnetos etait raccorde ; `Motor` conserve en revanche les
  methodes de sauvegarde et de restauration exigees par Zuti MDS 1.13.
- `donor-hsfx4` est l'ensemble original `Advanced Engine Management` extrait
  de HSFX 4.0 Part 2. HSFX 4.0 exige IL-2 4.09m. Cet ensemble contient les
  consommateurs moteur AOC absents de la base Open Sturmovik.

Les 267 profils originaux associes ont ete recuperes. La v1.15 en livre 266
sans modification dans `_Game_Enhancements/Mod_AOC_Public` : sur demande du mainteneur, le profil
`Bf-109G-6Early_AOC_1a.txt` est omis afin que cet appareil utilise
`Defaut.txt`. L'original reste identifiable dans le manifeste. Les gros volumes
HSFX ne sont pas conserves dans le depot ;
leurs tailles et empreintes ainsi que celles des six classes sont consignees
dans `manifests/aoc-v1.15.json`.

Le constructeur refuse toute classe source dont l'empreinte differe, preserve
l'interface publique des trois classes de base, conserve
`zutiMakeEngineBackup()` et `zutiRestoreMotor()`, puis verifie le bytecode avant
de produire les trois surcharges finales.
