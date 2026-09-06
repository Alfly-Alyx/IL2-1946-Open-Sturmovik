# Audit des profils 4.08 / 4.09

Derniere mise a jour : 6 septembre 2026.

## Couples binaires

Les neuf dossiers du selecteur ont ete compares par SHA-256 et par contenu SFS.
La source locale AAA Community Installer 1.1 a ensuite permis de retrouver le
vrai differentiel binaire entre les executables avec et sans 6DOF.

| Groupe | Resultat |
| --- | --- |
| Six profils modifies | Meme format d'`il2fb.exe` de 348 160 octets et meme `wrapper.dll` de 233 472 octets ; deux empreintes d'EXE existent maintenant selon le choix 6DOF |
| Trois profils Original | Meme `il2fb.exe` de 4 548 608 octets ; aucun `wrapper.dll` requis |
| 4.08 modifie avec/sans 6DOF | `files.SFS` et wrapper identiques ; EXE distincts |
| 4.09b modifie avec/sans 6DOF | `files.SFS` et wrapper identiques ; EXE distincts |
| 4.09m modifie avec/sans 6DOF | `files.SFS` et wrapper identiques ; EXE distincts |

L'EXE v1.15 commun etait la variante 6DOF. Les trois profils sans 6DOF ont ete
restaures a partir du differentiel exact des deux EXE AAA historiques, sans
remplacer les ressources PE ni l'ajustement Large Address Aware courant :

- avec 6DOF : SHA-256
  `F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E` ;
- sans 6DOF : SHA-256
  `70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3`.

Ces empreintes finales incluent la ressource Windows v1.15 qui declare
`Open Sturmovik` comme description et nom de produit. Les empreintes
intermediaires, avant ce marquage mais apres la restauration du differentiel
6DOF, restent consignees dans `manifests/profiles-6dof-v1.15.json`.

Les cinq classes de `6DOF_Tracker_2_0_sHr` sont deja presentes dans `Files` et
identiques a la source locale. Elles fournissent six valeurs TrackIR et leur
consommation par `HookPilot`. Le manifeste reproductible est
`manifests/profiles-6dof-v1.15.json` et l'outil de reconstruction est
`tools/Patch-IL2No6DofProfiles.ps1`.

## Evolution des `files.SFS`

| Transition | Ajouts | Retraits | Contenus modifies | Identiques |
| --- | ---: | ---: | ---: | ---: |
| 4.08 modifie -> 4.09b modifie | 0 | 0 | 16 | 9 955 |
| 4.08 Original -> 4.09b Original | 0 | 0 | 16 | 10 059 |
| 4.09b modifie -> 4.09m modifie | 470 | 0 | 62 | 9 909 |
| 4.09b Original -> 4.09m Original | 468 | 0 | 86 | 9 989 |

Le profil 4.09m n'est donc pas un simple renommage de 4.09b. Parmi les ajouts identifiables figurent des classes d'avions, cockpits, armes, vehicules et decals. Les changements connus touchent notamment `SFSInputStream`, le rendu, le reseau, le moteur, l'interface, les registres et les traductions. La version 1.15 doit continuer a utiliser les dossiers `4.09final...` pour sa cible stable.

## Registres libres

Le selecteur basculait deja `air.ini`, mais les deux fichiers historiques `stationary.ini` n'etaient jamais copies. Le fichier actif du depot correspondait encore au profil commun 4.08/4.09b :

| Registre | Taille | SHA-256 |
| --- | ---: | --- |
| 4.08/4.09b | 52 177 | `C9E5A7E59941945D0434B58CB6F0097EBFC4E31236D0FFF49907830B13E11DD4` |
| 4.09m | 53 246 | `9A446C92C5D88986EDADC280689C9F4A1799EEFE1E646017A79E2B7544A18882` |

Le selecteur 1.15 inclut maintenant `stationary.ini` dans la meme transaction verifiee que l'EXE, `files.SFS` et `air.ini`. Les choix 1 a 6 installent le registre 4.08/4.09b ; les choix 7 a 9 installent le registre 4.09m.

## Transaction hors jeu exercee

Le 6 septembre 2026, le switcher corrige a ete execute dans la copie isolee,
sans lancer IL-2 :

| Etape | Resultat verifie |
| --- | --- |
| Profil 1, 4.08m Original, HUD standard | EXE et `files.SFS` originaux ; wrapper et trois archives 4.09 retires ; HUD standard exact |
| Profil 2, 4.08m modifie sans 6DOF, HUD immersion | EXE marque, wrapper, `files.SFS` et charge utile historique 4.09b exacts ; HUD immersion exact |
| Profil 8, 4.09m modifie sans 6DOF, HUD standard | EXE marque, wrapper, `files.SFS`, charge utile, `air.ini`, `stationary.ini` et HUD 4.09m exacts |

Les trois appels ont retourne zero, sans chemin introuvable ni message duplique.
Aucun dossier `_transaction-*` n'est reste. La copie de test est donc revenue
au profil 8 dans un etat mesure, pas seulement declare.

## Fichiers actifs avant le premier essai runtime

La racine du depot n'est pas consideree comme une installation de jeu complete
ni comme la preuve d'un profil correctement active. La campagne finale devra
partir de la copie actuellement validee au choix 8, `4.09m modifie (sans
6DOF)`, puis comparer le choix 9, `4.09m modifie avec 6DOF`, et enfin revenir au
choix 8 pour prouver le comportement TrackIR et la restauration en conditions
runtime.
