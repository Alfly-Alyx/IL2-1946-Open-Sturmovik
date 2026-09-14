# Marquage des executables et du titre de fenetre v1.15

Derniere mise a jour : 12 septembre 2026.

## Resultat vise

Les profils modifies doivent etre identifies comme `Open Sturmovik` dans le
Gestionnaire des taches et dans la barre de titre du jeu en mode fenetre. Les
profils `Original` doivent conserver integralement l'executable et le titre du
jeu d'origine.

## Faits verifies statiquement

- Les six executables modifies sont des PE32 i386 de 274 432 octets et sont
  repartis entre une variante avec 6DOF et une variante sans 6DOF.
- Aucun des deux executables sources ne contenait de ressource Windows
  `VERSIONINFO` exploitable.
- L'ajout de cette ressource donne `FileDescription=Open Sturmovik` et
  `ProductName=Open Sturmovik`. Windows relit ces valeurs sans lancer le jeu.
- Le groupe nomme `IL2ICON` et le groupe numerique `0x7F00` contiennent les six
  tailles Windows de l'icone `avion-ciel` : 16, 32, 48, 64, 128 et 256 pixels.
  Cette icone est reservee aux executables modifies ; les trois executables
  `Original` restent strictement identiques.
- La machine PE, le point d'entree et la taille de la section `.text` restent
  identiques. Deux octets de `.text` sont modifies pour que la classe de
  fenetre charge le groupe d'icone de l'executable.
- Les trois executables `Original` conservent tous le SHA-256
  `9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C`
  et ne portent pas la marque `Open Sturmovik`.

Empreintes finales des executables modifies :

| Variante | SHA-256 |
| --- | --- |
| Sans 6DOF | `BA1C702C1FC0DCC3D760FAEE46F74AD8BDF3D8CB5CE44B2CA40DAA3F75343C80` |
| Avec 6DOF | `7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21` |

Le volet **Processus** du Gestionnaire des taches utilise normalement la
description du fichier et doit donc afficher `Open Sturmovik`. Le volet
**Details** conserve le nom technique `il2fb.exe`, puisque le fichier n'est pas
renomme.

## Origine exacte de l'icone generique

La presence de `IL2ICON` suffisait a Explorer pour afficher l'icone du fichier,
mais pas a la fenetre du jeu. La decomposition de l'executable montre que ses
deux chemins d'enregistrement de classe appelaient
`LoadIconA(NULL, IDI_APPLICATION)`. Windows chargeait donc son icone
d'application generique pour la barre de titre et la barre des taches.

Le correctif conserve la structure de l'executable et change uniquement
l'argument de module passe a ces deux appels :

| Chemin | RVA | Avant | Apres | Effet |
| --- | ---: | --- | --- | --- |
| `RegisterClassW` | `0x0000D820` | `68 00 7F 00 00 56` | `68 00 7F 00 00 50` | `LoadIconA(hInstance, 0x7F00)` |
| `RegisterClassA` | `0x0000D88E` | `68 00 7F 00 00 56` | `68 00 7F 00 00 52` | `LoadIconA(hInstance, 0x7F00)` |

Le groupe numerique `0x7F00` est ajoute avec les memes six images que
`IL2ICON`. Les sequences sont acceptees seulement si elles correspondent
exactement a l'etat source ou a l'etat corrige ; toute autre variante est
refusee. Le differentiel 6DOF demeure distinct et les trois profils Original ne
sont pas modifies.

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
Son SHA-256 final, apres retrait des dependances Zuti MDS, est
`FE230776544C329C68E658EC6E293936F31116508D42F7BE43FF5EC68EDCBB5B`.
La variante intermediaire avec MDS avait l'empreinte
`8CEF8D5EC9EAAAC27D2797462E33B9FC5EED4506C3B8B273B4553292CBA20A94`.
L'ancien candidat constructeur-seul avait l'empreinte
`113E72DC1429DA8BBE33DF1FA7A659C584CA2124A01A3834B10309737280BC15`.
Les profils `Original` retirent le wrapper et utilisent donc leur classe SFS
d'origine avec leur titre d'origine.

## Reproduction et controles

- `tools/Build-OpenSturmovikBranding.ps1` reconstruit les six EXE et la classe
  de titre a partir d'empreintes sources imposees. Une seconde execution
  reconnait les sorties finales, les revalide et ne change aucune empreinte.
- `tools/Set-OpenSturmovikExeBranding.ps1` ajoute la ressource `VERSIONINFO`,
  remplace `IL2ICON`, ajoute le groupe `0x7F00`, controle les deux sequences de
  chargement et applique les deux changements d'un octet.
- `tools/java/OpenSturmovikWindowTitlePatcher.java` remplace uniquement
  les deux affectations de `windowTitle`, avec un controle distinct de chacune.
- `tools/Test-OpenSturmovikSwitcher.ps1` controle les empreintes, les
  metadonnees des six EXE modifies et l'absence de marquage des trois originaux.

## Validation runtime

Niveau de confiance : eleve. La reconstruction des six profils et le controle
d'integrite des trois profils Original passent. Le profil 9 a ensuite ete
installe dans la copie de test et lance en mode fenetre le 12 septembre 2026.
La fenetre native portait le titre `Open Sturmovik` et son icone de classe
32 x 32 etait identique pixel par pixel a
`_Game Switcher/Resources/Icons/Open_Sturmovik_Game.ico` : aucun pixel
different. Cette icone de classe alimente la barre de titre et la barre des
taches. Alexis a confirme visuellement le resultat avant le commit. Le resultat
reproductible est consigne dans
`manifests/test/window-icon-runtime-v1.15.json`.

## Affichage de la version au chargement — 13 septembre 2026

La classe `com.maddox.il2.engine.ConsoleGL0Render` contient les libellés stock `V 4.08m`, `V 4.09b1m` et `V 4.09m`. Les profils Open Sturmovik installent une surcharge propre qui ajoute `mod no 6DOF` ou `mod 6DOF`. Le profil stock 4.09b affiche volontairement `V 4.09b` ; le texte historique et l’interprétation prudente de `b1m` restent consignés dans `WIP/analyses/affichage-version-chargement/README.md`. Ces chaînes d’affichage sont indépendantes de la compatibilité réseau.