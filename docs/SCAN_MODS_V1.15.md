# Scan des mods fournis — Open Sturmovik v1.15

Scan du 11 septembre 2026, effectué sur les dossiers du jeu, avant rangement des notices. Branche `v1.15`, commit de départ `13cbd09bdeaefc27d91e6c80cf7eaba92777fb5c`. Les documents déplacés sont reliés à leurs anciens chemins dans le journal de classement.

## Résultat du scan des dossiers

| Dossier | Fichiers inventoriés |
| --- | ---: |
| `Files` | 89943 |
| `Missions` | 26045 |
| `DGen` | 1405 |
| `NGen` | 130 |
| `PaintSchemes` | 7034 |
| `samples` | 3177 |
| `i18n` | 2 |
| `Intros` | 8 |
| `_Game Switcher` | 57 |
| `_Game_Enhancements` | 275 |
| `_Utilities` | 1243 |

**129319 fichiers** inventoriés sans erreur de lecture. Les fichiers à la racine, dont les conteneurs SFS, sont aussi recensés. Les dossiers de développement, caches et tests sont exclus : `.codex`, `.git`, `build`, `docs`, `installer`, `manifests`, `native`, `test-assets`, `tmp`, `tools`, `WIP`, `_Documentations`.

Le scan détermine les composants **fournis ou présents dans le pack**. Il ne mesure pas leur activation pendant une partie. Les empreintes de `il2fb.exe` et de `files.SFS` à la racine correspondent au profil 4.09m Original ; `wrapper.dll` et `conf.ini` y sont absents au moment du contrôle. Les options modifiées restent fournies par le switcher.

## Comparaison avec les sources AAA locales

Les 130 dossiers de modules du paquet AAA Community Installer 1.1 ont été comparés fichier par fichier à `Files`, au même chemin relatif. La taille est vérifiée avant le SHA-256 ; le résultat conserve les preuves et les collisions entre modules.

- 43 modules : tous les fichiers non documentaires correspondent à la source locale ;
- 70 modules : correspondance partielle ;
- 16 modules : aucun fichier non documentaire identique retrouvé ;
- 1 dossier de documentation, sans qualification de mod.

Sur 20 972 fichiers sources comparés : **17 605 identiques, 1 343 différents, 2 024 absents à ce chemin**, zéro erreur. Ces nombres comptent les occurrences dans les modules : 502 couples chemin/empreinte sont partagés entre plusieurs modules. Ils ne représentent pas autant de créations indépendantes.

Une identité de fichiers établit une correspondance de contenu, pas à elle seule son auteur ou le chargement du mod complet. Le contenu officiel des SFS n’a pas été réextrait dans cette passe : des fichiers identiques peuvent être communs au jeu et au mod ; des fichiers absents de `Files` peuvent provenir des SFS. Les différences peuvent être des versions plus récentes ou des fusions. Aucun retrait n’est déduit d’une absence de correspondance.

Les 23 fichiers `Samples` de cinq modules ont aussi été cherchés à la racine : ils sont tous présents sous `Files` et absents à la racine ; 11 sont identiques, 12 différents.

### Liste complète des modules comparés

« Complet » qualifie uniquement la correspondance du contenu non documentaire au même chemin. Les noms avec un tiret initial sont ceux de la source AAA ; ce tiret ne décrit pas leur état dans le dossier aplati `Files`.

| Module source | Identiques / fichiers non documentaires | Différents | Absents | Constat |
| --- | ---: | ---: | ---: | --- |
| `-BritishReticlesMod` | 34 / 34 | 0 | 0 | Complet |
| `-Cockpits_BF_109F_Default` | 0 / 1 | 1 | 0 | Aucune identité |
| `-Flushys_cloudmod_v1` | 0 / 3 | 2 | 1 | Aucune identité |
| `-FMB` | 0 / 53 | 35 | 18 | Aucune identité |
| `-PropTex` | 0 / 5 | 5 | 0 | Aucune identité |
| `6DOF_Tracker_2_0_sHr` | 5 / 5 | 0 | 0 | Complet |
| `_DOCS_` | 0 / 0 | 0 | 0 | Documentation |
| `A5M4` | 6 / 6 | 0 | 0 | Complet |
| `ACES` | 66 / 66 | 0 | 0 | Complet |
| `Aircraft` | 0 / 6 | 6 | 0 | Aucune identité |
| `AR-196A3` | 16 / 16 | 0 | 0 | Complet |
| `Askania_EZ-421-A1_For_Ta-183` | 0 / 21 | 0 | 21 | Aucune identité |
| `Askania_EZ-42_For_Fw190-D9` | 29 / 37 | 7 | 1 | Partiel |
| `B17D` | 10 / 22 | 0 | 12 | Partiel |
| `B17E` | 12 / 16 | 4 | 0 | Partiel |
| `B17F` | 13 / 19 | 6 | 0 | Partiel |
| `B17G` | 18 / 25 | 7 | 0 | Partiel |
| `B24J-100-CF` | 19 / 19 | 0 | 0 | Complet |
| `B25C25` | 13 / 13 | 0 | 0 | Complet |
| `B25G1` | 8 / 8 | 0 | 0 | Complet |
| `B25H1` | 10 / 10 | 0 | 0 | Complet |
| `B29` | 407 / 407 | 0 | 0 | Complet |
| `B29_Silver_Plate` | 915 / 951 | 36 | 0 | Partiel |
| `B5N2_KATE` | 14 / 14 | 0 | 0 | Complet |
| `B6N2_JILL` | 16 / 16 | 0 | 0 | Complet |
| `BeaufighterMkX` | 399 / 404 | 5 | 0 | Partiel |
| `BF-109-F1` | 1 / 1 | 0 | 0 | Complet |
| `BF-109-K14` | 154 / 159 | 5 | 0 | Partiel |
| `BF-109F_Jabo` | 454 / 465 | 11 | 0 | Partiel |
| `BF-109F_Kanonenboot` | 152 / 156 | 4 | 0 | Partiel |
| `BF-109F_Trop` | 310 / 321 | 11 | 0 | Partiel |
| `BF-110-C4` | 155 / 155 | 0 | 0 | Complet |
| `BF-110-C4B` | 155 / 155 | 0 | 0 | Complet |
| `BF-110-G4` | 197 / 202 | 5 | 0 | Partiel |
| `Bf109-E_Mirror_v1_1` | 21 / 26 | 5 | 0 | Partiel |
| `BLENHEIM-1` | 83 / 392 | 1 | 308 | Partiel |
| `BLENHEIM-1F` | 171 / 174 | 3 | 0 | Partiel |
| `BLENHEIM-4` | 83 / 364 | 1 | 280 | Partiel |
| `BombBayDoors_Plus_v2_0` | 13 / 123 | 108 | 2 | Partiel |
| `C47` | 2 / 6 | 4 | 0 | Partiel |
| `ChaikaBS` | 2 / 2 | 0 | 0 | Complet |
| `ChaikaFIN` | 3 / 3 | 0 | 0 | Complet |
| `Cockpit_F6F_0_1` | 115 / 119 | 0 | 4 | Partiel |
| `Cockpit_FW-190A-4` | 36 / 41 | 2 | 3 | Partiel |
| `Cockpit_FW-190A-5_A-6` | 35 / 40 | 1 | 4 | Partiel |
| `Cockpit_FW-190A-8_A-9` | 26 / 39 | 6 | 7 | Partiel |
| `Cockpit_FW-190D-9` | 29 / 35 | 2 | 4 | Partiel |
| `Cockpit_I-16` | 0 / 43 | 0 | 43 | Aucune identité |
| `Cockpit_Mosquito` | 53 / 58 | 0 | 5 | Partiel |
| `Cockpit_P40_0_1` | 26 / 56 | 25 | 5 | Partiel |
| `Cockpit_Spitfire_0_1` | 325 / 335 | 1 | 9 | Partiel |
| `Cockpit_Yak-1_0_1` | 35 / 96 | 61 | 0 | Partiel |
| `Cockpits_BF_109_Mod` | 470 / 832 | 226 | 136 | Partiel |
| `Cockpits_HurriFulNW` | 68 / 90 | 2 | 20 | Partiel |
| `Collision_height` | 0 / 1 | 1 | 0 | Aucune identité |
| `Crater_F_IV` | 1 / 1 | 0 | 0 | Complet |
| `DB_3B` | 77 / 77 | 0 | 0 | Complet |
| `DB_3F` | 79 / 79 | 0 | 0 | Complet |
| `DB_3M` | 79 / 79 | 0 | 0 | Complet |
| `DB_3T` | 79 / 79 | 0 | 0 | Complet |
| `EngineFlame` | 4 / 6 | 2 | 0 | Partiel |
| `F6F_MIRROR_MOD` | 12 / 14 | 2 | 0 | Partiel |
| `Flare_Distance` | 7 / 10 | 3 | 0 | Partiel |
| `FW-189_A-2` | 2 / 8 | 6 | 0 | Partiel |
| `FW-190_A-3` | 314 / 352 | 38 | 0 | Partiel |
| `FW-190_D-11` | 335 / 343 | 8 | 0 | Partiel |
| `FW-190_D-13` | 154 / 159 | 5 | 0 | Partiel |
| `FW-190A5u14` | 2 / 3 | 1 | 0 | Partiel |
| `FW-200_C3U4` | 14 / 16 | 0 | 2 | Partiel |
| `Fw190_Bar_Out` | 2 / 31 | 28 | 1 | Partiel |
| `Fw190_Update` | 0 / 77 | 0 | 77 | Aucune identité |
| `G11` | 6 / 6 | 0 | 0 | Complet |
| `G4M2E_and_MXY-7` | 77 / 77 | 0 | 0 | Complet |
| `German_Torpedoes` | 22 / 25 | 3 | 0 | Partiel |
| `Gladiator_Mk1` | 4 / 5 | 1 | 0 | Partiel |
| `Gladiator_MkII` | 5 / 5 | 0 | 0 | Complet |
| `Gray_curving_Smoketrail` | 0 / 2 | 1 | 1 | Aucune identité |
| `GroundDust` | 0 / 2 | 2 | 0 | Aucune identité |
| `H8K1` | 89 / 89 | 0 | 0 | Complet |
| `HUDConfig_v1` | 0 / 6 | 4 | 2 | Aucune identité |
| `HurricaneMkIId` | 164 / 164 | 0 | 0 | Complet |
| `IL4` | 78 / 79 | 1 | 0 | Partiel |
| `Ju-52-3mg` | 6 / 16 | 10 | 0 | Partiel |
| `Ju-88A4_Torpedo_Bomber` | 163 / 329 | 91 | 75 | Partiel |
| `KI-21-I-Sally` | 13 / 13 | 0 | 0 | Complet |
| `KI-21-II-Sally` | 15 / 15 | 0 | 0 | Complet |
| `Ki-46-Otsu` | 9 / 9 | 0 | 0 | Complet |
| `Ki-46-OtsuHei` | 10 / 10 | 0 | 0 | Complet |
| `Ki-46-Recce` | 6 / 6 | 0 | 0 | Complet |
| `L2D` | 6 / 6 | 0 | 0 | Complet |
| `LI2` | 68 / 69 | 1 | 0 | Partiel |
| `MACCHI_200_1` | 5 / 5 | 0 | 0 | Complet |
| `MACCHI_200_7_AND_7FB` | 10 / 10 | 0 | 0 | Complet |
| `MACCHI_202` | 7 / 7 | 0 | 0 | Complet |
| `MapMods` | 293 / 545 | 89 | 163 | Partiel |
| `MBR-2AM34` | 82 / 82 | 0 | 0 | Complet |
| `ME-321` | 14 / 14 | 0 | 0 | Complet |
| `ME-323` | 20 / 20 | 0 | 0 | Complet |
| `ME-410_A` | 335 / 357 | 8 | 14 | Partiel |
| `ME-410_B` | 332 / 354 | 8 | 14 | Partiel |
| `ME-410_D` | 319 / 340 | 7 | 14 | Partiel |
| `Mosquito_Mk_BXVI` | 490 / 499 | 9 | 0 | Partiel |
| `Mosquito_MkIV` | 9 / 9 | 0 | 0 | Complet |
| `Mosquito_Update` | 30 / 32 | 0 | 2 | Partiel |
| `Nacht234` | 188 / 202 | 1 | 13 | Partiel |
| `Neman_R-10` | 16 / 17 | 0 | 1 | Partiel |
| `ObjectsMap` | 5184 / 5937 | 133 | 620 | Partiel |
| `P51D_MIRROR_MOD` | 11 / 14 | 3 | 0 | Partiel |
| `P_47DGunsights_v1_3` | 86 / 175 | 66 | 23 | Partiel |
| `PBN-1` | 72 / 76 | 4 | 0 | Partiel |
| `PE8` | 16 / 19 | 0 | 3 | Partiel |
| `RWD-8` | 385 / 419 | 33 | 1 | Partiel |
| `SB_2M-100A` | 74 / 75 | 1 | 0 | Partiel |
| `SB_2M-103` | 75 / 76 | 1 | 0 | Partiel |
| `Seafire_MKII` | 582 / 590 | 8 | 0 | Partiel |
| `SKINMOD` | 11 / 72 | 9 | 52 | Partiel |
| `Spitfire_MKVC` | 807 / 849 | 42 | 0 | Partiel |
| `Spitfire_MKVIII` | 542 / 570 | 28 | 0 | Partiel |
| `SpitMk1` | 451 / 492 | 41 | 0 | Partiel |
| `SplashScreen` | 1 / 2 | 1 | 0 | Partiel |
| `Static_Aircraft` | 0 / 28 | 28 | 0 | Aucune identité |
| `STD` | 0 / 6 | 6 | 0 | Aucune identité |
| `SU_2` | 12 / 12 | 0 | 0 | Complet |
| `TBF-1C` | 12 / 12 | 0 | 0 | Complet |
| `TBM-3` | 12 / 12 | 0 | 0 | Complet |
| `Tempest5_11LBS` | 0 / 1 | 1 | 0 | Aucune identité |
| `Tempest5_13LBS` | 0 / 1 | 1 | 0 | Aucune identité |
| `TU_2S` | 30 / 33 | 3 | 0 | Partiel |
| `U2VS` | 3 / 8 | 5 | 0 | Partiel |
| `WindConfig_v3` | 2 / 3 | 1 | 0 | Partiel |

## Cartes, campagnes et options

- Le registre des cartes contient 406 paires textuelles et 198 chemins INI distincts, dont 163 présents en fichiers libres. Les alias, variantes et cartes officielles empêchent d’assimiler ces nombres à un nombre de mods. Voir [les attributions des cartes](<SCAN_CARTES_CREDITS_V1.15.md>).
- Dix campagnes ont été reliées à leurs notices signées, à leur `campaign.ini` et à leurs missions présentes. Leur inventaire est conservé dans [campagnes](<../manifests/mods/credits-v1.15/campaigns.json>).
- Les options et outils sont distingués des modifications du jeu dans [le relevé des options](<SCAN_OPTIONS_CREDITS_V1.15.md>).

## Preuves et reproduction

- [Synthèse et attributions AAA](<../manifests/mods/credits-v1.15/aaa-modules-summary.json>) ; [preuves complètes par fichier, JSON gzip](<../manifests/mods/credits-v1.15/aaa-file-comparison.json.gz>).
- [Inventaire des dossiers avant rangement](<../manifests/mods/credits-v1.15/game-inventory-before-cleanup.json>) ; [journal du rangement](<CLASSEMENT_DOCUMENTATIONS_V1.15.md>).
- [Outil de comparaison](<../tools/Scan-ModCredits.py>) : exécuter depuis le dossier de tâche sous `C:\Users\Alexis\.codex`, avec les options `--root`, `--source`, `--output` et `--expected-branch v1.15`. `--source` désigne le dossier `Packs/AAA_Community_Installer_ver_1_1/MODS`, et `--output` un dossier de résultats dans celui de la tâche. Les sources et le jeu sont lus seulement.
- Pour les cartes : lire `Files/Maps/all.ini`, relever chaque chemin INI et contrôler les références `[static]` et textures ; les observations détaillées et leurs limites sont conservées dans le relevé des cartes.

## Sources complémentaires

L’examen des autres dossiers de `D:\Projets\GITHUB\#res\IL2 1946\Packs` est consigné dans [le relevé des packs complémentaires](<SCAN_PACKS_CREDITS_V1.15.md>). Une archive présente constitue une source à comparer, pas la preuve de son intégration. Aucun contenu de pack n’a été installé dans le jeu par ce scan.

Les ressources locales sont prioritaires. La consultation communautaire a commencé par AAA/Wayback (capture inaccessible pendant cette passe), puis Mission4Today et SAS. Les sources utilisées et les pages qui n’ont pu être rouvertes sont consignées dans [l’inventaire des crédits](<CREDITS_MODS.md>).
