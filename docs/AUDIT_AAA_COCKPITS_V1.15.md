# Audit des cockpits historiques AAA Community Installer 1.1

Ce rapport est genere par `tools/Audit-AAACommunityCockpits.py`. La source
AAA est analysee en lecture seule : aucun fichier n'est copie automatiquement.
Une ligne `air.ini` ne suffit pas a rendre un avion pilotable ; il faut une
surcharge de classe coherente, ses classes cockpit, ses modeles 3D et un modele
de vol compatible avec Buttons.

## Source et methode

- source AAA : `C:\Users\Alexis\Downloads\AAA_Community_Installer_ver_1_1` ;
- classes JVM AAA inventoriees : **966** ;
- noms de classes distincts : **947** ;
- comparaison faite par nom interne JVM et SHA-256, jamais par le seul nom
  obfusque du fichier ;
- la presence d'un ensemble ne valide pas encore le modele de vol dans Buttons
  ni le comportement en mission.

## Resultat sur les appareils initialement sans cockpit direct

| Ligne | Cle | Classe | Paquet AAA | Cockpit AAA | Decision |
| ---: | --- | --- | --- | --- | --- |
| 22 | `KB_29P` | `KB_29P` | — | — | not-found-in-aaa-community-installer-1.1 |
| 33 | `CW-21` | `CW_21` | — | — | not-found-in-aaa-community-installer-1.1 |
| 58 | `DXXI_DK` | `DXXI_DK` | — | — | not-found-in-aaa-community-installer-1.1 |
| 59 | `DXXI_DU` | `DXXI_DU` | — | — | not-found-in-aaa-community-installer-1.1 |
| 61 | `AvengerMkIII` | `TBM3AVENGER3` | — | — | not-found-in-aaa-community-installer-1.1 |
| 69 | `TBF-1` | `TBF1` | — | — | not-found-in-aaa-community-installer-1.1 |
| 184 | `I-15bis` | `I_15BIS` | — | — | not-found-in-aaa-community-installer-1.1 |
| 185 | `I-15bis_Skis` | `I_15BIS_SKIS` | — | — | not-found-in-aaa-community-installer-1.1 |
| 341 | `G-55` | `G_55` | — | — | not-found-in-aaa-community-installer-1.1 |
| 342 | `G-55-Late` | `G_55_Late` | — | — | not-found-in-aaa-community-installer-1.1 |
| 345 | `DXXI_SARJA4` | `DXXI_SARJA4` | — | — | not-found-in-aaa-community-installer-1.1 |
| 346 | `Sarvanto_DXXI` | `DXXI_SARJA3_SARVANTO` | — | — | not-found-in-aaa-community-installer-1.1 |
| 378 | `He-111Z` | `HE_111Z` | — | — | not-found-in-aaa-community-installer-1.1 |
| 395 | `Ju-88Mistel` | `JU_88MSTL` | — | — | not-found-in-aaa-community-installer-1.1 |
| 420 | `S-328` | `LetovS_328` | — | — | not-found-in-aaa-community-installer-1.1 |
| 425 | `MS406` | `MS406` | — | — | not-found-in-aaa-community-installer-1.1 |
| 426 | `MS410` | `MS410` | — | — | not-found-in-aaa-community-installer-1.1 |
| 516 | `RE-2000` | `RE_2000` | — | — | not-found-in-aaa-community-installer-1.1 |
| 70 | `TBF-1C` | `TBF1C` | TBF-1C | CockpitTBF1C, CockpitTBF1C_BGunner, CockpitTBF1C_TGunner | historical-flyable-set-restored |
| 72 | `TBM-3` | `TBM3` | TBM-3 | CockpitTBM3, CockpitTBM3_BGunner, CockpitTBM3_TGunner | historical-flyable-set-restored |
| 532 | `Pokryshkins_MiG-3` | `MIG_3POKRYSHKIN` | ACES | CockpitMIG_3 | historical-flyable-set-restored |

## Paquets historiques candidats

### ACES

- classes Java : **19** ;
- ressources non Java : **47** ;
- references directes de classes non resolues : **0** ;
- toutes les classes du paquet ciblent Java major 47.

| Classe interne | Deja dans Open Sturmovik | Binaire identique |
| --- | --- | --- |
| `BF_109G10FABIAN` | oui | oui |
| `BF_109G6GRAF` | oui | oui |
| `BF_109G6HARTMANN` | oui | oui |
| `BF_109G6HEPPES` | oui | oui |
| `BF_109G6KOVACS` | oui | oui |
| `BF_109G6MOLNAR` | oui | oui |
| `CockpitJU_87G2RUDEL` | oui | oui |
| `CockpitJU_87G2RUDEL$1` | oui | oui |
| `CockpitJU_87G2RUDEL$Interpolater` | oui | oui |
| `CockpitJU_87G2RUDEL$Variables` | oui | oui |
| `CockpitJU_87G2RUDEL_Gunner` | oui | oui |
| `I_16TYPE24SAFONOV` | oui | oui |
| `JU_87G2RUDEL` | oui | oui |
| `LA_7KOJEDUB` | oui | oui |
| `ME_262A1ANOWOTNY` | oui | oui |
| `MIG_3POKRYSHKIN` | oui | oui |
| `P_39NPOKRYSHKIN` | oui | oui |
| `P_39Q15RECHKALOV` | oui | oui |
| `YAK_9TALBERT` | oui | oui |
### TBF-1C

- classes Java : **7** ;
- ressources non Java : **5** ;
- references directes de classes non resolues : **0** ;
- toutes les classes du paquet ciblent Java major 47.

| Classe interne | Deja dans Open Sturmovik | Binaire identique |
| --- | --- | --- |
| `CockpitTBF1C` | oui | oui |
| `CockpitTBF1C$1` | oui | oui |
| `CockpitTBF1C$Interpolater` | oui | oui |
| `CockpitTBF1C$Variables` | oui | oui |
| `CockpitTBF1C_BGunner` | oui | oui |
| `CockpitTBF1C_TGunner` | oui | oui |
| `TBF1C` | oui | oui |
### TBM-3

- classes Java : **7** ;
- ressources non Java : **5** ;
- references directes de classes non resolues : **0** ;
- toutes les classes du paquet ciblent Java major 47.

| Classe interne | Deja dans Open Sturmovik | Binaire identique |
| --- | --- | --- |
| `CockpitTBM3` | oui | oui |
| `CockpitTBM3$1` | oui | oui |
| `CockpitTBM3$Interpolater` | oui | oui |
| `CockpitTBM3$Variables` | oui | oui |
| `CockpitTBM3_BGunner` | oui | oui |
| `CockpitTBM3_TGunner` | oui | oui |
| `TBM3` | oui | oui |

## Regle de restauration

Un ensemble AAA ne peut etre restaure dans `Files` qu'apres controle de toutes
ses classes cockpit et ressources, verification Java 1.3 (major <= 47), controle
de la correspondance Buttons/FMD et essai runtime F1/commandes/armements. Les
appareils absents de cette source restent IA tant qu'un paquet communautaire
authentique et complet n'a pas ete retrouve ; aucun cockpit ne sera invente.

Le detail avec chemins, empreintes et dependances est conserve dans
`manifests/aircraft/aaa-community-cockpits-v1.15.json`.
