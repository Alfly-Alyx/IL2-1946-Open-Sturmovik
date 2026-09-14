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

Cette conclusion est renforcee par l'objectif du projet : les textures 2K/4K et
les autres ameliorations communautaires sont destinees a remplacer le contenu
stock. Le nettoyage des SFS post-4.08 effectue dans la copie de test ne concerne
donc pas le dossier `Files` de l'add-on. Il sert uniquement a produire une base
stock de comparaison ; voir [la matrice des versions](MATRICE_VERSIONS_SFS.md).

La verification complementaire des 46 copies provenant de `files.SFS` montre qu'elles sont identiques dans les neuf profils 4.08/4.09 conserves par le selecteur. Elles pourraient techniquement etre omises dans un profil donne, mais le gain serait insignifiant et leur absence compliquerait la reproductibilite des profils historiques. **Decision 1.15 : les 179 copies exactes, soit 1 504 582 octets, sont volontairement conservees.** Elles ne doivent pas etre confondues avec les 2 028 remplacements fonctionnels.

## Archives restaurees

Le commit orphelin `7e93f90794ae85f0ea92f88f1935eb490855600b` a ete preserve par la branche `codex/recovered-sfs-2024`. Les trois fichiers de travail correspondent exactement a ce commit :

| Fichier | Taille | SHA-256 |
| --- | ---: | --- |
| `fb_3do.SFS` | 154 030 389 | `E95D1E3659B04F1638CC644B292846F94C1823CD5B63419F71FC26DEFF0C057B` |
| `fb_3do19.SFS` | 187 104 836 | `4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670` |
| `fb_maps15.SFS` | 343 180 796 | `AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9` |

Ces archives ne doivent pas etre remplacees par les fichiers libres de `Files` : ces derniers sont charges comme surcharges et sont majoritairement differents.

## Verification des grosses archives et objectif 100 Mo

Le lecteur en lecture seule `tools/Analyze-Sfs.py` reproduit les algorithmes du
projet OpenIL2, revision
[`63031643`](https://github.com/DavidGregory084/OpenIL2/commit/63031643bd14c0f89255b97a9e954b552ed215f1).
Une correction importante a ete apportee pendant l'audit : pour une archive SFS
v201, la table des contenus et la table des blocs utilisent comme cle l'empreinte
des 256 octets de l'en-tete. Une cle nulle donnait auparavant des metadonnees
apparemment plausibles, mais aucun chemin valide. Les controles anterieurs a
cette correction qui annoncaient zero nom resolu pour les v201 sont invalides.

Avec `SFSExtract.lst` du 31 octobre 2025 (1 866 924 lignes, SHA-256
`82B8CCA246A8188AB3132890F4F7414623D85E383C504CD7948718F384E21F03`),
les huit archives de la copie de test qui depassent 100 Mio donnent :

| Archive | Taille | Entrees | Noms resolus | Couverture |
|---|---:|---:|---:|---:|
| `fb_3do.SFS` | 154 030 389 | 20 159 | 17 528 | 86,95 % |
| `fb_3do01.SFS` | 475 859 205 | 33 080 | 31 645 | 95,66 % |
| `fb_3do06.SFS` | 189 237 786 | 14 826 | 14 029 | 94,62 % |
| `fb_3do08p.SFS` | 538 161 306 | 44 970 | 41 435 | 92,14 % |
| `fb_3do17.SFS` | 162 078 246 | 9 844 | 8 978 | 91,20 % |
| `fb_3do19.SFS` | 187 104 836 | 9 834 | 8 972 | 91,23 % |
| `fb_maps.SFS` | 143 206 944 | 755 | 633 | 83,84 % |
| `fb_maps15.SFS` | 343 180 796 | 496 | 462 | 93,15 % |

Cette lecture a aussi confirme que `fb_3do08p.SFS` contient :

- `3DO\Plane\TBF-1(Multi1)\hier.him`, 24 417 octets, SHA-256
  `3628DDD4A170218799C3B0BCB1463A6ACE1AD53AEEA11E08646C6BCC22C7AAA9` ;
- `3do\plane\TBF-1(USA)\hier.him`, strictement identique ;
- aucun des deux chemins `TBM1.him` demandes par l'ancienne classe TBM-1 parmi
  les 41 435 noms resolus.

### Peut-on imposer moins de 100 Mo ?

La communaute a deja utilise SFS Manager pour decouper des paquets en volumes de
60 a 90 Mo, et l'ordre de montage dans `.rc` permet de repartir les ressources.
Cela prouve la faisabilite du format, pas la securite d'une transformation
automatique de ces archives officielles et communautaires. Une regression de
carte a notamment ete signalee apres un repaquetage et corrigee manuellement :
[discussion SFS Manager](https://www.sas1946.com/main/index.php?topic=63325.12),
[exemple de volumes 60-90 Mo](https://www.sas1946.com/main/index.php?topic=55051.36),
[ordre de priorite `.rc`](https://www.sas1946.com/main/index.php?topic=15030.0).

**Decision v1.15 actuelle : ne decouper et ne repaqueter aucune SFS.** La limite
de 100 Mo n'est pas un besoin du moteur IL-2 et n'apporte pas a elle seule un
gain de chargement. Une experience ulterieure devra obligatoirement :

1. extraire dans un laboratoire et conserver archive, taille, empreinte, index et
   ordre de chaque ressource ;
2. obtenir 100 % de noms resolus, ou documenter et conserver sans alteration
   chaque entree encore numerique ;
3. produire des volumes deterministes de moins de 100 Mo et un `.rc` explicite ;
4. detecter toute collision de chemin et verifier la priorite avec `Files` ;
5. rouvrir chaque volume, comparer chaque contenu puis tester demarrage, cartes,
   avions, sons, missions et multijoueur ;
6. conserver un retour arriere transactionnel vers les SFS d'origine.

Tant que ces conditions ne sont pas remplies, modifier les SFS ferait courir un
risque disproportionne pour un objectif essentiellement cosmetique de taille de
fichier.
