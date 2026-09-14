# Sources complémentaires des crédits — dossier Packs

> **Perimetre historique avant le retrait du 12 septembre 2026.** Les constats,
> empreintes, listes de fichiers et commandes lies a MDS, DCG, San FOV ou Malta
> ci-dessous decrivent l'etat observe a leur date, pas le contenu cible actuel.
> MDS est desormais retire localement ; voir [le suivi courant](RETRAIT_COMPOSANTS_V1.15.md)
> et [la reconstruction AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md).
> Les anciens constructeurs et pieces retires sont conserves dans les archives
> externes identifiees par ce suivi ; ne pas reinstaller leur contenu.

Relevé du 11 septembre 2026, cible Open Sturmovik v1.15. Les neuf dossiers de `D:\Projets\GITHUB\#res\IL2 1946\Packs` ont été examinés : le paquet AAA et huit dossiers supplémentaires. Les sources et les fichiers du jeu sont lus seulement ; aucun installateur ni jeu n’a été exécuté. Les extractions ciblées ont été faites dans le dossier de la tâche sous `C:\Users\Alexis\.codex`.

## Couverture et résultats

| Source locale | Examen réalisé | Correspondances établies avec le jeu |
| --- | --- | --- |
| AAA Community Installer 1.1 | Comparaison de tous les fichiers des 130 modules libres. | 43 modules de contenu non documentaire identique, 70 partiels ; [rapport complet](SCAN_MODS_V1.15.md). |
| VPmodpack | Deux archives logiques : base en 16 volumes et correctif ; index intégral des chemins, tailles et groupes de modules. | Deux fichiers contrôlés par SHA-256 : un identique, un différent. |
| SAS ModAct 6.40 | Archive SFX lue sans l’exécuter ; le commentaire indique une cible 4.13.4m. | Un fichier contrôlé par SHA-256, différent. |
| TFM-412 Level 38 | 42 archives/prérequis listés ; niveaux 01 à 38 et correctif Heavies présents. Prérequis explicitement 4.12.2m. | 69 fichiers contrôlés : 58 identiques, 11 différents. |
| HSFX 7.0.3 | Correctif 700→703 ZIP lisible, 409 entrées. Les trois EXE multiparties ne sont pas lisibles par 7-Zip ; leur contenu n’est pas présumé. | Deux candidats de même taille dans le correctif : un identique, un différent. |
| Ultrapack 3.4 Cassie | Superpack de 31 volumes, Patch 2 de six volumes et Hotfix 23 inventoriés ; notices lues. | Échantillon du Superpack : sept fichiers identiques, un différent. |
| B.A.T | 34 archives/programmes listés, versions 4.0, 4.1, 4.2 et 4.3. Comparaison des modules libres accessibles en ZIP. | 226 fichiers cibles distincts identiques retrouvés dans les ressources libres 4.0/4.1/4.2. |
| Canvas Knights Full Game | Notices, version et contenus du jeu autonome examinés. | Aucune intégration Open Sturmovik établie. |
| Canvas Knights WWI Assets et WIP | Inventaire local : 29 archives d’addons et sources de développement. | Aucune intégration Open Sturmovik établie. |

Ces identités ne doivent pas être additionnées pour compter des mods : plusieurs packs peuvent contenir le même fichier officiel ou hérité. Un fichier identique établit une ressource commune ; il ne prouve ni l’installation du pack complet ni l’ordre historique de son intégration. Les versions récentes restent des sources de comparaison, sans être rejetées sur leur seul numéro de version.

## VPmodpack, SAS ModAct et TFM : détail de la couverture

Les 45 archives logiques ont été listées sans erreur. 72 fichiers ont été comparés par SHA-256 et 33 notices ont été extraites. Les extractions ciblées ont représenté environ 20,56 Mo ; les paquets complets n’ont pas été décompressés.

| Source | Chemins communs après correspondance des racines | Tailles différentes | Même taille restant sans SHA-256 | Notices lues |
| --- | ---: | ---: | ---: | ---: |
| VPmodpack | 24808 | 7384 | 17422 | 2 |
| SAS_Modact_6.40 | 85 | 63 | 21 | 0 |
| TFM-412_Level_38 | 22600 | 4585 | 17946 | 31 |

Le hachage des trois paquets ci-dessus est un échantillonnage ciblé, explicitement distinct de l’inventaire de leurs archives. Les autres fichiers de même taille ne sont pas déclarés identiques. Les groupes de modules, chemins internes, règles de correspondance et notices sont conservés dans [le relevé VP/SAS/TFM](../manifests/mods/credits-v1.15/packs-vp-sas-tfm.json). La version précise de la base VPmodpack et de son correctif n’est pas établie par les preuves locales consultées.

Parmi les correspondances TFM se trouvent des ressources du KB-29, du cockpit Tempest, du Magister, du Tiger Moth et de DumpFuel. Cela identifie des composants à poursuivre fichier par fichier, sans attribuer TFM entier au pack.

## Attributions supplémentaires retrouvées

- **Magister — modèle extérieur : RAF_Magpie.** La notice de TFM06, `00_Magister/Readme.txt`, ligne 3, le crédite explicitement pour le modèle extérieur ; le fichier `CF_D1.msh` correspondant est identique dans le jeu et la source. Seul ce périmètre de modèle est confirmé par cette comparaison.
- **Typhoon / Tempest : Ranwers / Josse.** La notice de TFM05 les crédite pour les mods historiques. Elle n’attribue pas individuellement `Bodytyph.msh` ; cette limite est conservée.
- **KB-29P, Tiger Moth et DumpFuel :** les notices de l’échantillon ne permettent pas une attribution individuelle sûre.

Les archives, membres, lignes, citations locales et empreintes sont conservés dans [les preuves d’attributions complémentaires](../manifests/mods/credits-v1.15/additional-pack-authors.json).

### BombBayDoors Plus 2.5.3

Le manuel `BATDOCS/SAS Engine Mod Readme v27.pdf`, page PDF 6, dans `B.A.T/4.0 RED CORE/BAT-v4.0_13.zip`, attribue le travail de BombBayDoors Plus 2.5.3 à **Zuti et Fireball**. La compilation ultérieure de SAS~Anto concerne cette évolution moderne, sans preuve qu’elle corresponde aux classes historiques d’Open Sturmovik.

Empreinte SHA-256 du PDF extrait : `BD7E0BA03CCCD23D05050A9A5804AC0227C9FA735A346CD1A59FACF215364BF9`. Cette source résout l’attribution documentaire, mais pas la version précise du code fusionné dans v1.15. La notice 2.5.3 du jeu est rangée dans `_Documentations/Mods and Tools/BombBayDoors Plus 2.5.3`. Voir [la citation et sa provenance](../manifests/mods/credits-v1.15/packs-bat-ck.json).

## Limites HSFX, Ultrapack et BAT

- HSFX : le correctif est une source partielle ; certains noms JSGME n’y sont représentés que par une notice. Les EXE refusés par 7-Zip ne sont pas déclarés corrompus pour cette seule raison.
- Ultrapack : l’essentiel du contenu est stocké dans les SFS (95 dans le Superpack, 14 dans Patch 2, cinq dans Hotfix 23). Les sept identités échantillonnées comprennent cinq DLL communes, un régiment et une skin. Les 229 autres candidats de même taille du Superpack n’ont pas été hachés.
- BAT : les fichiers libres ont été comparés via leur chemin logique, taille puis SHA-256. Les SFS internes et les sons placés à la racine `samples` ne sont pas couverts par cette comparaison.
- Aucun contrôle d’intégrité complet de toutes les archives n’a été réalisé. La lisibilité d’un index n’est pas une garantie d’intégrité de chaque fichier compressé.

Les [détails HSFX/UP](../manifests/mods/credits-v1.15/packs-hsfx-up.json), [résultats BAT/Canvas Knights](../manifests/mods/credits-v1.15/packs-bat-ck.json), [226 fichiers BAT communs](../manifests/mods/credits-v1.15/bat-shared-files.json), [groupes de modules BAT](../manifests/mods/credits-v1.15/bat-modules.json) et [index des archives BAT, JSON gzip](../manifests/mods/credits-v1.15/bat-archive-entries.json.gz) conservent les preuves.

## Canvas Knights

Le dossier Full Game contient le jeu autonome Canvas Knights 0.1.2.0 et son outil Vehicle Simulator for CK 2.4.9.0. Les formats et notices observés ne constituent pas une preuve d’utilisation dans Open Sturmovik. Le dossier WWI/WIP contient des sources supplémentaires ; les auteurs ne sont pas ajoutés aux crédits Open Sturmovik sur la seule présence de ces archives. La notice locale de droits et les versions sont relevées dans le manifeste, sans portage ni restauration.

## Reproduction

Lister les archives avec `7z l -slt`, en passant le premier volume pour les archives multiparties. Relever les chemins et les tailles ; comparer au dossier du jeu en normalisant seulement les racines de modules documentées. Pour les fichiers retenus, lire uniquement le membre concerné (`7z x -so`) ou le flux ZIP, puis comparer les SHA-256. Lire les notices des mêmes composants et conserver archive, membre et ligne/page. Les sorties des installateurs sont lues comme archives, jamais exécutées. Les JSON distinguent listes intégrales, échantillons et éléments non lus.

Les notices originales dans le jeu ont été rangées ; les sources du dossier Packs ont gardé leurs emplacements. Tous les processus lancés pour les analyses et extractions sont terminés.
