# Options et outils fournis — crédits v1.15

Relevé du 11 septembre 2026. Les notices et métadonnées locales identifient les auteurs ci-dessous. « Fourni » ne signifie pas lancé ou sélectionné ; aucun utilitaire ni jeu n’a été exécuté pour ce scan. Les anciennes preuves de chargement sont identifiées comme telles.

| Composant | Version relevée | Auteur / attribution | Statut | Preuve |
| --- | --- | --- | --- | --- |
| AOC - Advanced Engine Management | 1a adapté AOC/Zuti | II/JG51-Lutz | intégré, statique vérifié | 266 profils présents ; 3/3 classes identiques au manifeste. Source documentée HSFX4. Runtime non essayé. |
| 6DOF Tracker | 2.0 sHr | à confirmer ; ne pas transformer suffixe sHr en attribution sans source | mod optionnel vérifié | 5/5 fichiers identiques source AAA ; activable profils 3/6/9, pas activation actuelle. |
| Zuti Moving Dogfight Server | 1.13 STD | Zuti ; Fireball pour CTO/Carrier incorporés selon historique original | intégré selon audit existant | Audit existant 30 classes chargées dans ancien dump ; scan actuel confirme outils et 6 missions exemples. Exemples ne prouvent pas usage runtime. |
| BombBayDoors Plus | notice 2.5.3 ; version code exacte inconnue | Zuti et Fireball — attribution documentaire BAT | identification partielle | Notice sans auteur. 121/123 chemins présents source AAA v2 mais 13 seulement identiques. Ne pas affirmer module 2.5.3 intégral depuis seule notice. |
| HUDConfig | source de comparaison v1 | à identifier | complet non confirmé | 4/6 chemins présents, 0 identique ; 2 textures absentes. Fusion possible non analysée. |
| HUD Immersion | non indiquée | à identifier | option fournie | Option pour profils moddés. HUD racine différent de variantes historiques switcher ; ne pas qualifier sélection courante. |
| Bf-110G - variantes viseur Schräge Musik | non indiquée | magot | variantes fournies | Notice signée magot ; dit copier variante vers xeticle.tga. Sélection actuelle non prouvée. |
| Blackout Darker | 10 pour cent plus sombre | à identifier | variante fournie | Notice décrit 10% plus sombre, ne prouve pas sélection. |
| Variantes textures véhicules et bus | non indiquée | à identifier | variantes fournies | Instructions copier variantes Guy, NAAFI ou RAF et enlever préfixe. Ne pas assimiler noms de variantes à auteurs. |
| Gamma Panel - Gapa | 1.0.0.20 | Tomasz Porosiński | compagnon optionnel fourni | Notice et version Windows concordent ; désactivé par défaut selon README améliorations. |
| San's IL2 FOV Changer | RC 1.0 | San ; code joystick basé sur Mark Harris | retiré le 12 septembre 2026 | Notice conservée dans `Mods/Retirés/besoin_licence/San FOV Changer 1.0` ; ne figure plus dans les crédits des outils fournis. |
| Bombsight Table 2 | 2 (désignation paquet) | WT_Pedropan ; WT_Pitr | outil externe fourni | Auteurs section Authors. Aides RTF .txt référencées dans programme : maintenir originaux. |
| HardBall Aircraft Viewer | 4.08 | Matt « Flight Lieutenant HardBall » Henderson | outil externe fourni | Notice signée. FileVersion Windows 4.00.0008 ; données historiques 4.08. |
| IL2 Sticks | 1.0h Beta | FoolTrottel | outil historique fourni | Version notice juillet 2005 ; auteur métadonnée manuel. HTML référencé dans executable. |
| IL2 Compare | 2.4 | à confirmer ; Ross Youss remercié dans manuel HardBall pour IL2 Compare | outil externe fourni | Version 2.4.0.0 ; données AEP 2.01. Le remerciement ne suffit pas à établir attribution directe complète. |
| IL2 JoyControl - JoyCtrl | 1.4.2.1 | Oleg_BS | outil externe fourni | LegalCopyright (c) Oleg_BS, CompanyName BreakSoft. Aucune notice locale identifiée. |
| Lowengrin Dynamic Campaign Generator | 3.43 | Lowengrin ; prénom non établi dans scan | retiré le 12 septembre 2026 | Notice conservée dans `Mods/Retirés/besoin_licence/Lowengrin DCG 3.43` ; ne figure plus dans les crédits des outils fournis. |
| Mission Mate | 6.0.1 | CrazySchmidt ; Barbs | outil externe fourni | Auteurs en tête du manuel. Ne pas recopier liste familiale/testeurs. Skins Geoff Fisken fournies dans outil : Dave Bakshi selon manuel, sans preuve copie dans jeu. |
| Quick Mission Tuner 1946 | 2.00.0009 | DiverseWare | outil historique fourni | FileVersion et copyright DiverseWare 2003-2007 ; catalogue ancien. |
| IL2 Properties Editor et Difficulty Editor | Properties 2.0 ; Difficulty V1 fichier | MadBran, signature MWF 12T - MadBran - F4U-1C | outils auxiliaires QMT | Notice version 2.0 ; FileVersion générique Properties 1.0.0.0. Conserver regroupés sous QMT. |
| Shift-Rot | non indiquée | Antonio M. | outil auxiliaire QMT | Signature Created by Antonio M. |
| WeatherSet | inconnue | à identifier | outil externe fourni | Pas de notice/version/auteur identifié localement. Fonctionnement effet 4.09m non validé ancien audit. |
| ZipNav | 1.1 | à identifier | outil externe fourni | Readme décrit changements V1.0 ; nom exe V1.1. Ne pas déduire auteur du préfixe zip. |
| Zuti Airports Extractor et Mods Conflicts Revealer | non indiquées | Zuti pour Airports Extractor ; second à confirmer | outils auxiliaires MDS | 2 jars et 2 run.bat. Pas de notice libre trouvée ; pas exécutés. |

Le scan seul ne signe pas l’auteur de 6DOF. L’attribution sHr conservée dans la page de crédits est aussi recoupée par les [notes HSFX v4 sur Mission4Today](https://mail.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&start=0&t=7663), qui créditent Shr pour le module 6DOF.

Les chemins, les sources et les exclusions sont consignés dans [le manifeste des options](<../manifests/mods/credits-v1.15/options.json>). Les aides appelées par les programmes gardent leur accès applicatif ; voir [le classement des documents](<CLASSEMENT_DOCUMENTATIONS_V1.15.md>).

## Complément des sources du dossier Packs

Le manuel SAS Engine Mod v27 de BAT, page 6, attribue BombBayDoors Plus 2.5.3 à Zuti et Fireball. Cela complète l’auteur laissé inconnu par la lecture de la seule notice du jeu, sans établir la version de son code. Voir [la provenance exacte](SCAN_PACKS_CREDITS_V1.15.md).
