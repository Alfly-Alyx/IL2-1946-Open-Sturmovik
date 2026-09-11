# Credits des mods - inventaire initial

Etat du 11 septembre 2026. Cible : Open Sturmovik v1.15 sur IL-2 1946 4.09m.

## Objet et regles

Ce document est la source de travail de la future page **Credits** du switcher.
Il ne constitue pas encore la liste exhaustive des centaines de ressources
historiques du pack. Une entree n'est presentee comme utilisee que lorsque son
integration dans la v1.15 est etablie par les fichiers, un manifeste ou un audit
du depot.

Les noms d'auteur sont conserves sous la forme publiee. Une attribution
incertaine reste marquee comme telle. L'inclusion d'un nom dans les credits ne
vaut ni licence ni autorisation de redistribution.

## Socle historique

| Composant | Credits identifies | Utilisation dans Open Sturmovik v1.15 | Preuves et limites |
| --- | --- | --- | --- |
| AAA Community Installer 1.1 | AAA Team & Community | Socle historique local de nombreux appareils, cartes, objets, effets et mecanismes de chargement ; le `wrapper.dll` actif correspond exactement a celui de ce paquet. | Paquet conserve dans `D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1`. La correspondance fichier par fichier avec chacun de ses mods reste a etablir : le collectif ne doit pas remplacer les credits individuels. |
| 6DOF Tracker 2.0 | sHr | Variante 6DOF proposee par les profils modifies du switcher. Les cinq classes du module correspondent octet pour octet a la source AAA locale ; l'executable v1.15 conserve la distinction 6DOF historique avec les adaptations Open Sturmovik documentees. | `manifests/profiles-6dof-v1.15.json` et module local `MODS/6DOF_Tracker_2_0_sHr`. Validation complete avec materiel TrackIR encore requise. |

## Mods dont l'integration est confirmee

| Mod ou contribution | Auteur ou credits publies | Perimetre exact dans la v1.15 | Etat des droits / point restant |
| --- | --- | --- | --- |
| Zuti Moving Dogfight Server v1.13 STD | `|ZUTI|` ; remerciements publies a la communaute UltraPack, Oleg Maddox et QTim | Coeur MDS charge, textes, exemples et outils ; correction locale minimale de `ZutiTimer_ExtendPlanesWings`. | Le lisez-moi exige une autorisation avant inclusion dans un pack. Aucune preuve d'autorisation pour Open Sturmovik n'est conservee. |
| Certificates AI mod v3.0 | Nom publie : Certificates | Integre indirectement dans Zuti MDS v1.13 d'apres le lisez-moi original. | Auteur, source primaire et droits a confirmer separement avant l'affichage final. |
| Fireballs Carrier Takeoff mod v5.3.x | Nom publie : Fireballs | Integre indirectement dans Zuti MDS v1.13 d'apres le lisez-moi original. | Auteur, source primaire et droits a confirmer separement avant l'affichage final. |
| Advanced Engine Management - AOC 1a | II/JG51-Lutz | Trois classes moteur fusionnees avec la base 4.09m/Zuti et 266 profils conserves sous `_Game_Enhancements/Mod_AOC_Public`. | Ensemble 1a complet retrouve dans HSFX 4.0. Audit statique passe ; la validation fonctionnelle en jeu reste partielle. |
| Tiger33 Ultimate Sound Mod V3 | Tiger33 | Integration ciblee de dix presets de demarrage et de dix-huit WAV absents. Les deux SFS complets ne sont pas montes et deux WAV Sabre anterieurs sont conserves. | Source et compatibilite 4.09m + UP 2.01 confirmees. Conditions de redistribution a consigner avant publication. |
| Cockpit CW-21 pour 4.09 | Conversion publiee par Epervier pour Rebels 409 ; credits Team Daidalos | Quatre classes de cockpit et 165 ressources authentiques, avec adaptation locale de la classe CW-21 pour l'enregistrement des armements. | Integration statique confirmee ; validation complete en vol encore requise. Les droits de redistribution restent a consigner. |
| B-29 Silverplate v1.2, Little Boy et Fat Man | 1C/Maddox ; O_Magpie ; Fireball ; SAS~Cirx ; MrJolly ; Lt.Wolf ; Fat Duck ; VC-81_BOLTER ; O_Leigh ; Max_Thehitman ; Ranwers ; Wolfighter ; Twister. La publication cite aussi Santobr pour des effets additionnels. | Huit ressources de modeles de bombes identiques au paquet ; plusieurs classes sont fusionnees ou adaptees pour Zuti et le moteur 4.09m. | Les credits sont retrouves, mais aucune licence publiee ni autorisation n'est conservee. La presence exacte des effets additionnels de Santobr reste a verifier. |

## Attributions a resoudre avant affichage final

| Candidat | Observation verifiee | Pourquoi il n'entre pas encore dans la liste finale |
| --- | --- | --- |
| RMP3 Atmosphere v4.3 / ZloyPetrushkO | Les anciens nuages RMP3 ont ete remplaces par WxTech. Deux classes actives correspondent exactement au `WindConfig_v3` du paquet AAA ; une autre classe historiquement associee a RMP3 appartient maintenant a la fusion AOC/Zuti. | Le perimetre actif ne peut pas encore etre attribue proprement a RMP3. Il faut distinguer RMP3, WindConfig v3 et WxTech fichier par fichier. |
| San's IL2 FOV Changer | Outil fourni sous `_Game_Enhancements`, avec un code joystick base sur un travail de Mark Harris. | Desactive par defaut et non valide : a crediter comme outil optionnel, pas comme mod actif. L'identite complete de San et les droits doivent etre retrouves. |
| Gamma Panel 1.0 (`Gapa`) | Tomasz Porosinski, copyright 2002-2003. | Outil fourni mais desactive par defaut ; il releve des credits des utilitaires optionnels, pas des mods actifs. |
| Appareils, cartes, objets, cockpits et effets herites du pack AAA | Le paquet local contient les modules et quelques lisez-moi, mais pas une table de credits exhaustive. | Une simple presence dans le paquet source ne prouve pas que chaque ressource est encore active dans la v1.15. |

## Sources recoupees pour cette premiere passe

### Ressources locales prioritaires

- `D:\Projets\GITHUB\#res\IL2 1946\Mods\Utilisés` et son classement ;
- `D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1` ;
- `_Documentations/Mods and Tools/Zuti MDS 1.13` ;
- `manifests/aoc-v1.15.json`, `manifests/audio/tiger33-startup-sounds.json`,
  `manifests/aircraft/cw21-cockpit-v1.15.json`,
  `manifests/mods/zuti-mds-1.13-static.json` et
  `manifests/profiles-6dof-v1.15.json` ;
- `docs/AUDIT_ZUTI_AOC.md`, `docs/CW21_COCKPIT_ARMAMENT_V1.15.md`,
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

La recherche AAA/Wayback n'a pas fourni de page individuelle exploitable pour
Zuti MDS, Tiger33, le cockpit CW-21 ou Silverplate pendant cette passe. Aucun
contenu inaccessible n'a ete suppose. Mission4Today et SAS confirment les
attributions indiquees, mais ne remplacent pas les autorisations de
redistribution.

## Suite de l'inventaire

1. Comparer les fichiers actifs de `Files` a chaque module du paquet AAA 1.1.
2. Pour chaque correspondance, relever nom, version, auteur, source primaire,
   empreinte, perimetre integre et droits.
3. Retrouver les conditions de redistribution de Silverplate et verifier si les
   effets additionnels attribues a Santobr font partie du perimetre actif.
4. Separer les contributions RMP3, WindConfig v3 et WxTech.
5. Ajouter ensuite les cartes, appareils, cockpits, objets, effets, sons,
   campagnes et utilitaires dans des sections distinctes.

## Presentation future dans le switcher

Deux variantes compatibles restent ouvertes :

- une fenetre Credits integree, courte, avec les noms et contributions, puis un
  lien vers cet inventaire detaille ;
- une fenetre Credits complete, avec sections deroulantes et etats
  d'attribution.

Le choix d'interface n'est pas tranche par ce document.
