# Audit SFS de la version 1.15

L'analyse est en lecture seule. Elle s'appuie sur le format SFS documente par le projet libre [OpenIL2](https://github.com/DavidGregory084/OpenIL2) et sur sa base de chemins connus.

## Resultat

Le dossier `Files` contient 89 738 fichiers, soit 16 879 362 273 octets.

| Comparaison avec les SFS | Fichiers | Taille |
| --- | ---: | ---: |
| Meme chemin dans `Files` et dans un SFS | 2 245 | 1 401 168 712 octets |
| Contenu strictement identique | 179 | 1 504 582 octets |
| Contenu different, donc remplacement du mod | 2 028 | 1 398 031 285 octets |
| Non comparable automatiquement | 38 | 1 632 845 octets |

Les 179 copies exactes se repartissent ainsi :

| Archive | Fichiers identiques | Taille |
| --- | ---: | ---: |
| `fb_3do.SFS` | 129 | 1 206 453 octets |
| `fb_3do19.SFS` | 4 | 1 655 octets |
| `files.SFS` | 46 | 296 474 octets |

Conclusion : la redondance exacte ne represente qu'environ 1,5 Mo. Supprimer en bloc les 2 245 chemins communs detruirait environ 1,398 Go de remplacements reels du mod. Aucun nettoyage automatique n'est donc justifie pour la version 1.15.

## Archives restaurees

Le commit orphelin `7e93f90794ae85f0ea92f88f1935eb490855600b` a ete preserve par la branche `codex/recovered-sfs-2024`. Les trois fichiers de travail correspondent exactement a ce commit :

| Fichier | Taille | SHA-256 |
| --- | ---: | --- |
| `fb_3do.SFS` | 154 030 389 | `E95D1E3659B04F1638CC644B292846F94C1823CD5B63419F71FC26DEFF0C057B` |
| `fb_3do19.SFS` | 187 104 836 | `4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670` |
| `fb_maps15.SFS` | 343 180 796 | `AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9` |

Ces archives ne doivent pas etre remplacees par les fichiers libres de `Files` : ces derniers sont charges comme surcharges et sont majoritairement differents.
