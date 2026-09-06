# Marquage des executables et du titre de fenetre v1.15

Derniere mise a jour : 6 septembre 2026.

## Resultat vise

Les profils modifies doivent etre identifies comme `Open Sturmovik` dans le
Gestionnaire des taches et dans la barre de titre du jeu en mode fenetre. Les
profils `Original` doivent conserver integralement l'executable et le titre du
jeu d'origine.

## Faits verifies statiquement

- Les six executables modifies sont des PE32 i386 de 348 160 octets et sont
  repartis entre une variante avec 6DOF et une variante sans 6DOF.
- Aucun des deux executables sources ne contenait de ressource Windows
  `VERSIONINFO` exploitable.
- L'ajout de cette ressource donne `FileDescription=Open Sturmovik` et
  `ProductName=Open Sturmovik`. Windows relit ces valeurs sans lancer le jeu.
- L'empreinte de la section `.text`, la machine PE et le point d'entree restent
  identiques avant et apres l'ajout.
- Les trois executables `Original` conservent tous le SHA-256
  `9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C`
  et ne portent pas la marque `Open Sturmovik`.

Empreintes finales des executables modifies :

| Variante | SHA-256 |
| --- | --- |
| Sans 6DOF | `70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3` |
| Avec 6DOF | `F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E` |

Le volet **Processus** du Gestionnaire des taches utilise normalement la
description du fichier et doit donc afficher `Open Sturmovik`. Le volet
**Details** conserve le nom technique `il2fb.exe`, puisque le fichier n'est pas
renomme.

## Origine exacte du titre de fenetre

La decomposition 4.09m montre deux affectations successives : le constructeur
de `Config` initialise `windowTitle` a `Il2`, puis `Main3D.beginApp` lit la cle
`title` de la section principale du profil et appelle
`Config.createGlContext(String)`. Cette methode remplace `windowTitle` par
le titre recu avant l'appel a `MainWin32.create` et a la fenetre native.
Modifier seulement le constructeur ne corrige donc pas le titre observe.

Open Sturmovik possedait deja une surcharge libre de cette classe sous
`Files/5D18E55E5DF1D418`. Cette surcharge, chargee seulement par le
`wrapper.dll` des profils modifies, est conservee. Le correctif final impose
`Open Sturmovik` au constructeur **et** a l'affectation effective de
`createGlContext(String)`, sans modifier les autres reglages graphiques.
Son SHA-256 final est
`8CEF8D5EC9EAAAC27D2797462E33B9FC5EED4506C3B8B273B4553292CBA20A94`.
L'ancien candidat constructeur-seul avait l'empreinte
`113E72DC1429DA8BBE33DF1FA7A659C584CA2124A01A3834B10309737280BC15`.
Les profils `Original` retirent le wrapper et utilisent donc leur classe SFS
d'origine avec leur titre d'origine.

## Reproduction et controles

- `tools/Build-OpenSturmovikBranding.ps1` reconstruit les six EXE et la classe
  de titre a partir d'empreintes sources imposees. Une seconde execution
  reconnait les sorties finales, les revalide et ne change aucune empreinte.
- `tools/Set-OpenSturmovikExeBranding.ps1` ajoute uniquement la ressource
  `VERSIONINFO` et verifie l'identite du code PE.
- `tools/java/OpenSturmovikWindowTitlePatcher.java` remplace uniquement
  les deux affectations de `windowTitle`, avec un controle distinct de chacune.
- `tools/Test-OpenSturmovikSwitcher.ps1` controle les empreintes, les
  metadonnees des six EXE modifies et l'absence de marquage des trois originaux.

## Validation runtime encore requise

Niveau de confiance statique : eleve. Il reste toutefois a lancer un profil
modifie en mode fenetre pour verifier visuellement le titre et le nom affiche
par le Gestionnaire des taches, puis a lancer un profil Original pour confirmer
la separation. Aucun lancement de jeu n'a ete effectue pendant cette etape.
