# Audit des profils 4.08 / 4.09

## Couples binaires

Les neuf dossiers du selecteur ont ete compares par SHA-256 et par contenu SFS.

| Groupe | Resultat |
| --- | --- |
| Six profils modifies | Meme `il2fb.exe` de 348 160 octets et meme `wrapper.dll` de 233 472 octets |
| Trois profils Original | Meme `il2fb.exe` de 4 548 608 octets ; aucun `wrapper.dll` requis |
| 4.08 modifie avec/sans 6DOF | `files.SFS`, EXE et wrapper identiques |
| 4.09b modifie avec/sans 6DOF | `files.SFS`, EXE et wrapper identiques |
| 4.09m modifie avec/sans 6DOF | `files.SFS`, EXE et wrapper identiques |

Le menu 6DOF reste donc historique : aucun des trois couples ne peut produire une difference 6DOF avec les fichiers actuellement disponibles.

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
| 4.09m | 53 246 | `9A34044D6A3233614E5CEA80EC2AFCA59A28CA3DDA3D6B007A9D596A7B9D576E` |

Le selecteur 1.15 inclut maintenant `stationary.ini` dans la meme transaction verifiee que l'EXE, `files.SFS` et `air.ini`. Les choix 1 a 6 installent le registre 4.08/4.09b ; les choix 7 a 9 installent le registre 4.09m.

## Fichiers actifs avant le premier essai

La racine du depot n'est pas consideree comme une installation de jeu complete ni comme la preuve d'un profil correctement active. Le premier test devra partir d'une copie du jeu de reference et selectionner explicitement le choix 8, `4.09m modifie (sans 6DOF)`, afin que tous les fichiers geres soient coherents.
