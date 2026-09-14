# Audit statique des appareils declares dans air.ini

Ce rapport est genere par `tools/Audit-AirIniAircraft.py`. Il croise la
configuration active, les classes libres prioritaires et les classes recuperees
par Selector Dump. Il ne modifie aucun fichier du jeu.

## Perimetre et limites

- `air.ini` : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\Files\com\maddox\il2\objects\air.ini` ;
- dump SFS : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\analyses\labs\IL 2 Sturmovik 1946 Selector Dump\dump` ;
- entrees : **535** ;
- classes d'appareils distinctes : **535** ;
- fichier Buttons : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\Files\gui\GAME\buttons`, 1789137 octets ;
- une reference `FlightModels/*.fmd` prouve ce que la classe demande, pas que
  l'entree correspondante existe dans Buttons ; cette derniere preuve attend une
  extraction 4.09m sure et une reconstruction sans perte.

## Synthese

- statut statique : REVIEW=535 ;
- classification cockpit : player-capable-inherited-candidate=1, player-capable-static=516, probable-ai-only=18 ;
- modeles de vol : reference-only-buttons-not-extracted=535 ;
- classes d'appareil absentes : **0** ;
- entrees avec classe de cockpit absente : **0**.

`REVIEW` n'est pas synonyme de panne : il couvre notamment les appareils IA sans
cockpit et tous les modeles encore invérifiables dans Buttons. `FAIL` signale une
incoherence statique concrete ou l'absence d'une reference essentielle.

## Cas prioritaires

| Ligne | Entree | Classe | Cockpit | Modele de vol | Statut |
| ---: | --- | --- | --- | --- | --- |
| 20 | `B-29` | `air.B_29` | CockpitB29, CockpitB29_AGunner, CockpitB29_Bombardier, CockpitB29_FGunner, CockpitB29_RGunner, CockpitB29_T2Gunner, CockpitB29_TGunner | `FlightModels/B-29.fmd` | REVIEW |
| 21 | `B-29-SP` | `air.B_29SP` | CockpitB29SP, CockpitB29SP_AGunner, CockpitB29SP_Bombardier | `FlightModels/B-29SP.fmd` | REVIEW |
| 22 | `KB_29P` | `air.KB_29P` | aucun | `FlightModels/B-29.fmd` | REVIEW |
| 218 | `Su-2` | `air.SU_2` | CockpitSU_2, CockpitSU_2_Bombardier, CockpitSU_2_TGunner | `FlightModels/Su-2.fmd` | REVIEW |

## Cles air.ini dupliquees

| Ligne | Cle | Classe | Diagnostic |
| ---: | --- | --- | --- |

## Appareils sans cockpit direct

Ces appareils ne doivent pas etre proposes comme choix joueur sans preuve runtime.
Un cockpit herite est signale comme candidat, pas comme validation definitive.

| Ligne | Entree | Classe | Classification |
| ---: | --- | --- | --- |
| 22 | `KB_29P` | `air.KB_29P` | probable-ai-only |
| 33 | `CW-21` | `air.CW_21` | probable-ai-only |
| 58 | `DXXI_DK` | `air.DXXI_DK` | probable-ai-only |
| 59 | `DXXI_DU` | `air.DXXI_DU` | probable-ai-only |
| 61 | `AvengerMkIII` | `air.TBM3AVENGER3` | probable-ai-only |
| 69 | `TBF-1` | `air.TBF1` | probable-ai-only |
| 183 | `I-153P` | `air.I_153P` | player-capable-inherited-candidate |
| 184 | `I-15bis` | `air.I_15BIS` | probable-ai-only |
| 185 | `I-15bis_Skis` | `air.I_15BIS_SKIS` | probable-ai-only |
| 341 | `G-55` | `air.G_55` | probable-ai-only |
| 342 | `G-55-Late` | `air.G_55_Late` | probable-ai-only |
| 345 | `DXXI_SARJA4` | `air.DXXI_SARJA4` | probable-ai-only |
| 346 | `Sarvanto_DXXI` | `air.DXXI_SARJA3_SARVANTO` | probable-ai-only |
| 378 | `He-111Z` | `air.HE_111Z` | probable-ai-only |
| 395 | `Ju-88Mistel` | `air.JU_88MSTL` | probable-ai-only |
| 420 | `S-328` | `air.LetovS_328` | probable-ai-only |
| 425 | `MS406` | `air.MS406` | probable-ai-only |
| 426 | `MS410` | `air.MS410` | probable-ai-only |
| 516 | `RE-2000` | `air.RE_2000` | probable-ai-only |

Le detail exhaustif des 536 lignes est conserve dans :

- `manifests/aircraft/air-ini-static-v1.15.json` ;
- `manifests/aircraft/air-ini-static-v1.15.csv`.

## Utilisation pour les essais

1. tester d'abord les `FAIL` qui sont proposes au joueur ;
2. tester ensuite les appareils sans cockpit mais visibles dans les menus joueur ;
3. traiter les trois B-29 comme trois variantes distinctes ;
4. ne conclure sur les modeles de vol qu'apres inventaire de Buttons ;
5. conserver les essais runtime pour prouver F1, commandes, cockpit, armements et
   chargement effectif du modele de vol.

Sources : [role de air.ini dans l'installation d'un avion](https://www.sas1946.com/main/index.php?topic=46778.0),
[role de Buttons et panne vers 60 %](https://www.sas1946.com/main/index.php?topic=21.0),
[discussion sur les doublons et la limite de classes](https://www.sas1946.com/main/index.php?topic=67329.0).
