# Credits des mods - inventaire documente

Etat mis a jour le 12 septembre 2026. Cible : Open Sturmovik v1.15 sur IL-2 1946 4.09m.

DCG 3.43, San FOV 1.0 et Malta de 6S.Maraz sont retires du pack et archives
dans `D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence`.
Les credits publics de DCG et San FOV ont ete retires ; Malta n'y figurait pas.
Les scans dates restent des preuves historiques, pas un inventaire du contenu
apres retrait. MDS est retire du contenu local et de la page de credits generee ; ses
contributions sont conservees ci-dessous uniquement comme provenance historique. Voir [le suivi](RETRAIT_COMPOSANTS_V1.15.md).

## Objet et regles

Ce document conserve les preuves et le perimetre des attributions de la page **Credits** du switcher.
La [presentation des credits du pack](<../_Documentations/Mods and Tools/Credits - Open Sturmovik.md>)
reprend les noms des mods, leurs auteurs ou collectifs et leurs contributions.
Il ne constitue pas encore la liste exhaustive des centaines de ressources
historiques du pack. Une entree n'est presentee comme utilisee que lorsque son
integration dans la v1.15 est etablie par les fichiers, un manifeste ou un audit
du depot.

Les noms d'auteur sont conserves sous la forme publiee. Une attribution
incertaine reste marquee comme telle. L'inclusion d'un nom dans les credits ne
vaut ni licence ni autorisation de redistribution.

## Scan des dossiers du jeu

Le [releve du scan](SCAN_MODS_V1.15.md) complete cet inventaire : 129 319 fichiers du jeu et de ses options ont ete recenses, puis les 130 modules AAA ont ete compares au contenu reel de `Files`. 43 modules ont tous leurs fichiers non documentaires identiques, 70 une correspondance partielle, 16 aucune identite et un dossier contient seulement des documents. Ces correspondances ne prouvent pas a elles seules le chargement d’un module complet ni son auteur.

Les attributions issues des [cartes](SCAN_CARTES_CREDITS_V1.15.md), des [outils](SCAN_OPTIONS_CREDITS_V1.15.md) et des notices de campagnes alimentent la page de credits du pack. Les autres sources du dossier `Packs` sont examinees dans le [releve complementaire](SCAN_PACKS_CREDITS_V1.15.md).

Le checkout au moment du scan correspond, pour son executable et `files.SFS`, au profil 4.09m Original. Le terme integre ci-dessous qualifie le contenu fourni par Open Sturmovik ; il ne signifie pas que tous les mods sont selectionnes dans ce profil.

## Socle historique

| Composant | Credits identifies | Utilisation dans Open Sturmovik v1.15 | Preuves et limites |
| --- | --- | --- | --- |
| AAA Community Installer 1.1 | AAA Team & Community | Socle historique local de nombreux appareils, cartes, objets, effets et mecanismes de chargement ; le `wrapper.dll` actif correspond exactement a celui de ce paquet. | Paquet conserve dans `D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1`. La correspondance fichier par fichier avec chacun de ses mods reste a etablir : le collectif ne doit pas remplacer les credits individuels. |
| 6DOF Tracker 2.0 | sHr | Variante 6DOF proposee par les profils modifies du switcher. Les cinq classes du module correspondent octet pour octet a la source AAA locale ; l'executable v1.15 conserve la distinction 6DOF historique avec les adaptations Open Sturmovik documentees. | `manifests/profiles-6dof-v1.15.json` et module local `MODS/6DOF_Tracker_2_0_sHr`. Validation complete avec materiel TrackIR encore requise. |

## Mods dont l'integration est confirmee

| Mod ou contribution | Auteur ou credits publies | Perimetre exact dans la v1.15 | Etat des droits / point restant |
| --- | --- | --- | --- |
| Advanced Engine Management - AOC 1a | II/JG51-Lutz | Trois classes AOC sans MDS reconstruites et verifiees hors jeu, avec 266 profils conserves sous `_Game_Enhancements/Mod_AOC_Public`. | Ensemble 1a complet retrouve dans HSFX 4.0. Audit statique passe ; la validation fonctionnelle en jeu reste partielle. |
| Tiger33 Ultimate Sound Mod V3 | Tiger33 | Integration ciblee de dix presets de demarrage et de dix-huit WAV absents. Les deux SFS complets ne sont pas montes et deux WAV Sabre anterieurs sont conserves. | Source et compatibilite 4.09m + UP 2.01 confirmees. Conditions de redistribution a consigner avant publication. |
| WxTech clouds Jan 2023 | WxTech | Huit ressources actives de nuages dans `Files/Effects/clouds`, toutes identiques aux empreintes de `manifests/effects/clouds-4.09m-v1.15.json` lors du controle du 11 septembre 2026. | Auteur confirme par sa publication SAS du 23 janvier 2023. Archive source non retrouvee dans les ressources locales lors de cette passe ; emplacement a retablir dans `Mods/Utilisés`. |
| Cockpit CW-21 pour 4.09 | Conversion publiee par Epervier pour Rebels 409 ; credits Team Daidalos | Quatre classes de cockpit et 165 ressources authentiques, avec adaptation locale de la classe CW-21 pour l'enregistrement des armements. | Integration statique confirmee ; validation complete en vol encore requise. Les droits de redistribution restent a consigner. |
| B-29 Silverplate v1.2, Little Boy et Fat Man | 1C/Maddox ; O_Magpie ; Fireball ; SAS~Cirx ; MrJolly ; Lt.Wolf ; Fat Duck ; VC-81_BOLTER ; O_Leigh ; Max_Thehitman ; Ranwers ; Wolfighter ; Twister. La publication cite aussi Santobr pour des effets additionnels. | Huit ressources de modeles de bombes identiques au paquet ; plusieurs classes sont adaptees au moteur 4.09m ; leurs interfaces et les fonctions conservees sont verifiees statiquement apres retrait MDS, avec essais en jeu restant a refaire. | Les credits sont retrouves, mais aucune licence publiee ni autorisation n'est conservee. La presence exacte des effets additionnels de Santobr reste a verifier. |

## Cartes conservees apres le reexamen du 12 septembre 2026

| Carte | Attribution | Presence et source |
| --- | --- | --- |
| Darwin Small (NTL_Darwin_Small) | Neil Lowe | Carte conservee. Le nom de l'auteur est explicite dans la notice 1.0, ligne 2 ; les notices 1.0 et 1.1 sont liees dans les credits publics. Le dossier `Mods/Besoin Licence/Darwin Small` contient seulement la fiche de contact demandee par Alexis, pas un retrait de la carte. La provenance exacte de la revision actuelle n'est pas certifiee par ces credits. |
| Slovenia, variantes ete et hiver | Zuti — carte ; may_bugs — textures hivernales | Six INI presents et declares. Attribution Zuti recoupee avec les notes HSFX v4 ; roles complementaires dans les notices AAA integralement lues. Les credits ne revendiquent pas une version 1.35 certifiee dans Open Sturmovik. Voir le [complement du scan cartes](SCAN_CARTES_CREDITS_V1.15.md). |

Ces deux cartes sont distinctes de Malta et de Zuti MDS retires. Leur credit
documente les auteurs ; il ne constitue pas une nouvelle autorisation.

## Contributions historiques du paquet MDS retire

Ce releve conserve la provenance historique ; il ne presente pas MDS comme
une fonction de la version cible. Les notices et anciennes classes sont dans
`Mods/Retirés/besoin_licence/Zuti MDS 1.13`. Le suivi des retraits precise l'etat
effectif ; la ligne MDS a ete retiree des credits publics et la page a ete regeneree.

| Contribution historique | Attribution publiee | Perimetre |
| --- | --- | --- |
| MDS v1.13 STD | Zuti | Code moteur MDS, textes, exemples et outils retires du contenu local ; provenance conservee hors du pack. |
| Certificates AI v3.0 | Certificates | Contribution incorporee par MDS selon sa notice ; aucune integration independante etablie ici. |
| Carrier Takeoff v5.3.x | Fireballs | Contribution incorporee par MDS selon sa notice ; aucune integration independante etablie ici. |

## Contributions documentees et limites d'attribution

| Contribution | Observation verifiee | Perimetre et limites |
| --- | --- | --- |
| BombBayDoors Plus | Notice 2.5.3 rangee ; source documentaire BAT, manuel SAS Engine Mod v27 p. 6, attribuant le travail a Zuti et Fireball. | Attribution complementaire affichee pour les commandes des portes conservees apres retrait MDS. La version exacte du code fusionne n'est pas etablie : le titre public ne le presente plus comme BombBayDoors 2.5.3. Le module AAA v2 ne correspond que pour 13 fichiers sur 123. Voir [le releve des packs](SCAN_PACKS_CREDITS_V1.15.md) et [les fonctions conservees](RECONSTRUCTION_CONTROLS_EXPLOSIONS_SANS_MDS.md). |
| Nations and Squadrons V2 | Deux notices identiques signees Gaston, rangees dans `_Documentations/Mods and Tools/Nations and Squadrons V2`. | La notice signe l’auteur du mod ; son perimetre actuel dans les registres et escadrilles doit encore etre compare aux sources. |
| RMP3 Atmosphere v4.3 / ZloyPetrushkO | Les anciens nuages RMP3 ont ete remplaces par WxTech. Deux classes actives correspondent exactement au `WindConfig_v3` du paquet AAA ; une autre classe historiquement associee a RMP3 appartient maintenant a la adaptation AOC 4.09m. | Le perimetre actif ne peut pas encore etre attribue proprement a RMP3. Il faut distinguer RMP3, WindConfig v3 et WxTech fichier par fichier. |
| WindConfig v3 / auteur a identifier | Les fichiers actifs `96F4C2FA0F2B0FD0` et `E9BD6E7219DE5998` correspondent aux sources AAA ; `684916A0E86D1CC8` differe, conformement a la adaptation AOC 4.09m documentee. | La notice locale `MODS/_DOCS_/WindConfig_v3_README.txt` n'est pas signee. `uf_josse` y designe un autre mod incompatible, pas l'auteur de WindConfig. Ne pas presenter le module complet comme integre sans adaptation. |
| Gamma Panel 1.0 (`Gapa`) | Tomasz Porosinski, copyright 2002-2003. | Outil fourni mais desactive par defaut ; il releve des credits des utilitaires optionnels, pas des mods actifs. |
| Appareils, cartes, objets, cockpits et effets herites du pack AAA | Le paquet local contient les modules et quelques lisez-moi, mais pas une table de credits exhaustive. | Une simple presence dans le paquet source ne prouve pas que chaque ressource est encore active dans la v1.15. |

## Sources recoupees pour cette premiere passe

### Ressources locales prioritaires

- `D:\Projets\GITHUB\#res\IL2 1946\Mods\Utilisés` et son classement ;
- `D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1` ;
- notices MDS historiques archivees sous `Mods/Retirés/besoin_licence/Zuti MDS 1.13` ;
- `manifests/aoc-v1.15.json`, `manifests/audio/tiger33-startup-sounds.json`,
  `manifests/aircraft/cw21-cockpit-v1.15.json`,
  `manifests/profiles-6dof-v1.15.json` ;
- `docs/AUDIT_AOC_SANS_MDS_20260912.md`, `docs/CW21_COCKPIT_ARMAMENT_V1.15.md`,
  `docs/RMP3_ATMOSPHERE_PRESERVATION.md` et `docs/THIRD_PARTY_NOTICES.md`.

### Sources communautaires

- AAA / All Aircraft Arcade, archive Wayback du Unified Installer 1.0 :
  https://web.archive.org/web/20090107030230/http://allaircraftarcade.com/forum/viewtopic.php?t=7688
- Mission4Today, Zuti MDS v1.13 utilise avec IL-2 4.09m + UP 2.01 :
  https://www.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&printertopic=1&start=0&t=11184
- Mission4Today, HSFX 4.0 et credit AOC `II/JG51-Lutz` :
  https://mail.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&start=0&t=7663
- SAS, Tiger33 Ultimate Sound Mod V3 :
  https://www.sas1946.com/main/index.php?topic=3258.0
- SAS, cockpit CW-21 publie par Epervier :
  https://www.sas1946.com/main/index.php?topic=49201.0
- SAS, B-29 Silverplate v1.2 et credits de l'equipe :
  https://www.sas1946.com/main/index.php?topic=7894.0
- SAS, publication de WxTech clouds Jan 2023 par WxTech :
  https://www.sas1946.com/main/index.php?topic=70195.0

La recherche AAA/Wayback n'a pas fourni de page individuelle exploitable pour
Zuti MDS, Tiger33, le cockpit CW-21 ou Silverplate pendant cette passe. Aucun
contenu inaccessible n'a ete suppose. Mission4Today et SAS confirment les
attributions indiquees, mais ne remplacent pas les autorisations de
redistribution.

### Complement et controles du 11 septembre 2026

- WxTech : publication SAS consultee ; auteur et nom du paquet confirmes.
  Les huit fichiers actifs ont ete controles avec `Get-FileHash -Algorithm
  SHA256` contre les champs `activeFiles[].sha256` de
  `manifests/effects/clouds-4.09m-v1.15.json` : huit correspondances sur huit.
  Il s'agit d'une verification de presence, pas d'un nouveau test en jeu.
  La recherche des noms contenant `WxTech` dans
  `D:\Projets\GITHUB\#res\IL2 1946`, fichiers caches compris, n'a retrouve
  aucune archive. L'empreinte attendue de `WxTech_clouds_Jan_2023.7z` reste
  `DFB436CD077332B1F7D25CE794D6572081E2D19EADDDBCE5A2A3B140ED414D63`.
- WindConfig : comparaison SHA-256 des trois noms cites plus haut entre
  `Files` et
  `D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1\MODS\WindConfig_v3`.
  Deux correspondances et une difference ; constat coherent avec
  [l'audit de preservation](RMP3_ATMOSPHERE_PRESERVATION.md). Attribution
  individuelle non etablie.
- Mission4Today : notes HSFX v4 retrouvees par l'index de recherche apres
  echec de l'ouverture directe ; elles reprennent le credit AOC
  `II/JG51-Lutz`. SAS : credits Silverplate retrouves de la meme facon apres
  une erreur HTTP 403. Aucune nouvelle attribution n'en est deduite.
- AAA/Wayback : capture du 7 janvier 2009 inaccessible avec l'outil de
  consultation pendant cette passe. Les pages SAS Tiger33 et CW-21 n'ont
  pas pu etre rouvertes non plus ; leurs attributions restent celles de
  l'inventaire et des audits locaux anterieurs.

## Suite de l'inventaire

1. Exploiter la comparaison fichier par fichier des 130 modules AAA deja realisee pour poursuivre les attributions individuelles et distinguer les ressources communes au jeu officiel.
2. Pour chaque correspondance, relever nom, version, auteur, source primaire,
   empreinte, perimetre integre et droits.
3. Retrouver les conditions de redistribution de Silverplate et verifier si les
   effets additionnels attribues a Santobr font partie du perimetre actif.
4. Separer les contributions RMP3, WindConfig v3 et WxTech.
5. Completer les sections cartes, campagnes et utilitaires commencees par le scan, puis poursuivre les appareils, cockpits, objets, effets et sons encore non attribues.

## Presentation dans le switcher

La presentation demandee par Alexis est celle d'un mod ou pack de mods : nom
du mod, auteur ou collectif, contribution integree, et credits du paquet
d'origine quand plusieurs createurs y ont participe.

La premiere liste lisible est conservee dans
`_Documentations/Mods and Tools/Credits - Open Sturmovik.md`. Le present
inventaire conserve les preuves et les attributions a completer. L'ajout de
la page a l'interface du switcher est documente dans `PAGE_CREDITS_SWITCHER_V1.15.md`.
