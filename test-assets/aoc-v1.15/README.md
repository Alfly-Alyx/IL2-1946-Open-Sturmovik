# Sources de reconstruction AOC 1a pour IL-2 4.09m

Ce dossier contient les six classes d'entree du constructeur
`tools/Build-OpenSturmovikAocPatch.ps1`.

- `base-409m` conserve la base personnalisee Open Sturmovik compatible 4.09m.
  Il ne s'agit pas d'un jeu de classes stock. Les quatre methodes de sauvegarde,
  restauration et copie de tableaux propres a l'extension MDS retiree ont ete
  enlevees de `Motor`. Les autres methodes et champs sont conserves a l'identique.
- `donor-hsfx4` conserve les trois classes originales `Advanced Engine Management`
  extraites de HSFX 4.0 Part 2, prevu pour IL-2 4.09m. Les consommateurs moteur
  AOC manquants dans la base proviennent de ce donneur identifie.

Les 267 profils originaux ont ete recuperes. La v1.15 en livre toujours 266 dans
`_Game_Enhancements/Mod_AOC_Public`, sans modification. Le profil
`Bf-109G-6Early_AOC_1a.txt` reste omis sur demande du mainteneur pour utiliser
`Defaut.txt`. Les empreintes des volumes HSFX et des classes sont consignees dans
`manifests/aoc-v1.15.json`.

Le constructeur refuse toute source dont l'empreinte differe, preserve
l'interface de cette base expurgee, raccorde les dix reglages AOC et verifie le
bytecode Java 1.3 ainsi que l'absence de l'extension retiree. Il produit les trois
classes hors du jeu par defaut. `tools/Test-OpenSturmovikAoc.ps1` controle leurs
empreintes et l'inventaire des profils ; ces controles ne remplacent pas un vol.

Origines exactes, preservation des methodes, limites et reproduction :
`docs/AUDIT_AOC_SANS_MDS_20260912.md`. Les anciennes sources MDS sont archivees
 dans le dossier de ressources externe indique par ce rapport.
