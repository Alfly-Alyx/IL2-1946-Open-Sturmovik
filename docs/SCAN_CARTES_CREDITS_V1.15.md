# Cartes et contributions — scan local Open Sturmovik v1.15

> **Perimetre historique avant le retrait du 12 septembre 2026.** Les constats,
> empreintes, listes de fichiers et commandes lies a MDS, DCG, San FOV ou Malta
> ci-dessous decrivent l'etat observe a leur date, pas le contenu cible actuel.
> MDS est desormais retire localement ; voir [le suivi courant](RETRAIT_COMPOSANTS_V1.15.md)
> et [la reconstruction AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md).
> Les anciens constructeurs et pieces retires sont conserves dans les archives
> externes identifiees par ce suivi ; ne pas reinstaller leur contenu.

Scan en lecture seule du 11 septembre 2026. Racine Git vérifiée : `C:/Users/Alexis/DATA/Projets/GITHUB/IL2-1946-Open-Sturmovik`, accessible par `D:/Projets/GITHUB/IL2-1946-Open-Sturmovik`. Branche vérifiée : `v1.15`. Aucun déplacement ni aucune modification du jeu par cette sous-tâche.

## Périmètre et méthode

Lecture de `Files/Maps/all.ini`, des fichiers INI déclarés trouvés en fichiers libres, de toutes les 21 notices/historiques de cartes identifiés ci-dessous, et des notices pertinentes de la source locale AAA Community Installer 1.1. Recherche textuelle des références `Mbug_`, `fsmd_`, `Bombsaways_Tarawa`, et des attributions explicites. Le script `scan-maps.ps1` reproduit l'inventaire et le plan de rangement. Aucun lancement du jeu, aucune lecture de ses archives SFS, aucune affirmation sur le chargement effectif en partie.

[manifeste des cartes](<../manifests/mods/credits-v1.15/maps.json>) donne chaque paire déclarée via ses lignes de registre, alias et fichier INI, les références `[static]` et les exemples de textures observés. Le registre fournit **406 paires textuelles, 198 chemins INI distincts, 112 noms de dossiers ciblés**, dont **163 chemins INI présents en fichiers libres**. Ces nombres ne représentent pas 198 mods : cartes d'origine, variantes et mods coexistent dans ce registre.

Les 35 chemins sans INI libre ne sont pas déclarés cassés : leurs données peuvent se trouver en SFS, non inspectés dans ce scan. Le registre contient trois lignes avec 0x1A (116, 199, 312), des doublons et des alias. Les paires de part et d'autre de 0x1A ont été extraites à titre d'inventaire seulement. L'effet de ces octets dans le moteur reste inconnu, non testé. Aucune correction du registre n'a été faite.

## Attributions utilisables pour une première liste de crédits

Chaque ligne ci-dessous associe une notice explicite à un INI déclaré dans `Files/Maps/all.ini` et présent en fichiers libres. Les notices identifient l'origine des composants ; sauf précision, leur présence seule ne prouve pas que tous les fichiers correspondent encore exactement à la version historique annoncée.

| Composant | Auteur ou contribution établie | Preuves locales dans le jeu | Limite de version |
|---|---|---|---|
| Ukraine, été et hiver | **Autopilot** | `_Documentations/Maps/AP_Ukraine/Lisez-moi - Ukraine beta ete et hiver.txt:49`, `AP_Ukraine/load.ini`, `AP_Ukraine/load_w.ini` | Notice beta du 15 avril 2008 ; ne pas nommer ce composant « Kiev d'origine ». |
| B29 Alley | **delvpier** | `_Documentations/Maps/B29_Alley/Lisez-moi - installation.txt:16`, `B29_Alley/load.ini` | Pas de version signée dans la notice. |
| Bessarabia, repeuplement | **Zipzapp** ; **Fly_zo** pour l'installateur historique | `_Documentations/Maps/Bessarabia/Lisez-moi - repeuplement par Zipzapp.txt:7,9`, `Bessarabia/load.ini`, `Bessarabia/actors.static` | Crédit du repeuplement documenté ; ne pas remplacer l'auteur de la carte d'origine par Zipzapp. |
| Guadalcanal, septembre 1942 | **Marco** | `_Documentations/Maps/guadal/Lisez-moi - Guadalcanal septembre 1942 version 1-2.txt:1,15`, `Guadal/Sept_load.ini` | Notice version 1-2 du 6 avril 2008 et beta 1 du 8 mars 2008 conservées séparément. |
| Channel, petite carte dérivée de Pacific Islands | **Kapteeni** | `_Documentations/Maps/Kt_channel/Lisez-moi - Channel.txt:30`, `Kt_channel/load.ini` | Notice indique IL-2 4.09 beta et objets Slovakia. Distinct de CAN_Channel. |
| Eastafrica | **Kapteeni** ; **Fly_zo** pour le correctif de load.ini | `_Documentations/Maps/Kt_eastafrica/Lisez-moi - Eastafrica beta 0.91.txt:1,3,45`, `Kt_eastafrica/load.ini` | Notice beta 0.91, dérivée de Sands of Time. |
| Lybia N-E / Tobruk | **BADA** | `_Documentations/Maps/Lybia_N-E/Lisez-moi - Lybia N-E alpha 1.3.txt:3,28`, `Lybia_N-E/tob2_M_load.ini` | Notice alpha 1.3. Ne pas transférer automatiquement cette attribution à la variante JV69 distincte. |
| BP Midway et eau du Pacifique | **Boosher** : carte ; **panzerkeil** : objets statiques ; **Viking** : couleur de l'eau | `_Documentations/Maps/midway/Lisez-moi - eau du Pacifique pour BP Midway.txt:4-10`, `midway/BPload.ini:41` cible `BPactors.static` présent ; le même INI référence `Bombsaways_Tarawa/Tarawa/Shallows1a_Fields_A.tga` | L'auteur des textures d'eau peu profonde n'est pas signé dans cette notice. Le nom de dossier Bombsaways_Tarawa ne suffit pas à l'identifier. |
| Darwin Small | **Neil Lowe** | `_Documentations/Maps/NTL_Darwin_Small/Lisez-moi - Darwin Small 1.0.txt:2`, `NTL_Darwin_Small/NTL_Darwin_Small_load.ini` | Notices 1.0 et 1.1 conservées. Éviter une liste exhaustive des « Special Thanx » : elle ne distingue pas tous les rôles et n'est pas la liste des auteurs du composant. |
| Alpen | **Zipzapp** ; **JV69_BADA** : aérodromes Augsburg, München-Riem, Memmingen ; **Lowfighter** : châteaux suisses | `_Documentations/Maps/zip_Alpen/Lisez-moi - Alpen beta 2.txt:31,33,96`, `zip_Alpen/zip_Alpen_load.ini`, variantes east/west déclarées | Notice beta 2. Les trois INI partagent le dossier et ses ressources ; l'auteur des variantes east/west n'est pas distinctement signé. |
| Mbug Slovakia winter | **may-bug** : adaptation hivernale ; **Slovakia Team** : carte d'origine | Source locale `Packs/AAA_Community_Installer_ver_1_1/MODS/_DOCS_/readme_Mbug_Slovakia_winterMap.txt`, signée may-bug et explicitement créditant Slovakia Team ; `Files/Maps/Mbug_Slovakia_winter/load.ini`, `actors.static`, textures `Mbug_*` | Origine documentée. INI et texture échantillon divergent en SHA-256 de la source AAA ; ne pas présenter l'installation comme une copie binaire intacte de cette archive. |

La source locale est sous `D:/Projets/GITHUB/#res/IL2 1946`.

## Contributions établies, attribution principale encore à compléter

- **LAL Normandie 43** : INI `LALnormandy1/LAL_load1.ini` déclaré, `LAL1actors.static` présent. Notices FR/EN décrivent les textures issues de la communauté slovaque ; **BADA** a compilé des données et **HALLY** a guidé l'auteur. Les deux notices ne signent pas cet auteur. Sources : `_Documentations/Maps/LALnormandy1/Lisez-moi - Normandie 43 - francais.txt:10,32,35` et `LAL_Normandie-43.txt:10,31,34`. SG2_Wasy et Tiger 33 y sont nommés comme auteurs d'une dépendance sonore ; cela ne fait pas d'eux les auteurs de la carte.
- **Slovenia** : six INI présents et déclarés (Off_S, Off_W, On_S, On_W, Summer, Winter) avec références statiques existantes. Trois noms plus anciens déclarés n'ont pas d'INI libre. La source `_DOCS_/Zuti_Slovenia_ReadMe.doc` annonce IL-2 4.09b, les textures hivernales de may_bugs, **mapalm** pour les documents historiques et **Fly_Zo** pour l'aide initiale. Le DOC n'a fait l'objet que d'une extraction partielle de chaînes ASCII/UTF-16 depuis les octets : ne pas considérer cela comme une lecture intégrale fiable du document et ne pas inférer un auteur de son nom de fichier.
- **Phasmid** : la source `_DOCS_/Phasmid_mountain_textures_instructions.txt` est signée et demande d'être créditée. Elle décrit explicitement les textures v1 `fsmd_mount1`, `fsmd_mount2` et leurs variantes enneigées. Les INI actuels observés ciblent `fsmd_mount3`, des dérivées `fsmd_mount3base`, `fsmd_mount3_cald`, `GW_fsmd_rock_3a/b`. La texture `Files/Maps/_Tex/Land/Summer/zip_Alpen/fsmd_mount3.tga` correspond exactement à celle de la source AAA `_Tex/land/summer/fsmd_mount3.tga` (SHA-256 `70CA94E3CE6CFDE2EA92E0EF68D516E7F73714E0A3E80159312E01F302C0FAE2`). Parenté solide avec ce paquet de sources, attribution/version de fsmd_mount3 à corroborer explicitement avant d'afficher « Phasmid v1 ».
- **Philippines** : carte et variantes `load.ini`/`aload.ini` déclarées ; historique de Philippines 2.0 trouvé, mais aucune signature auteur dans les deux notices du dossier.
- **Svir** : `Kt_svir/load.ini` et `loadw.ini` déclarés, notice d'installation non signée. Le préfixe Kt ne suffit pas à transférer l'attribution Kapteeni.
- **JV69 Lybia N-E** : `JV69_LYBIA_N-E/JV69_M_load.ini` déclaré, notice non signée. Ne pas fusionner arbitrairement avec Lybia_N-E alpha 1.3.
- **The Slot** : six variantes datées déclarées et présentes. Historique 1.0, 1.1, 1.2 et 1.x présent ; auteur absent de cette notice.

## Présences qui ne suffisent pas à établir un mod actif

Les dossiers avec INI libre mais non ciblés par ce registre sont **ag_Norway**, **Benghalli**, **CAN_EnglishChannel**, **cztx_BurmaLower** et **Singapore2**. Les autres dossiers non ciblés, y compris ressources et dossiers d'outils, sont listés dans le JSON. Leur présence n'a pas été présentée comme activation. Les cartes historiques déclarées sans notice signée restent dans l'inventaire, sans attribution déduite du préfixe.

La notice `_Documentations/Maps/Singapore2/Lisez-moi - textures Singapore 2.txt:23` est signée **Jeff** pour une retouche de textures de Singapore 2. Le registre cible `singapore/load2.ini`, pas `Singapore2/load2.ini` ; les deux fichiers ont des SHA-256 différents. Il faut comparer leur contenu et provenance avant d'ajouter Jeff aux crédits du composant effectivement déclaré.

## Plan de rangement

`maps-document-moves.json` contient **21 déplacements proposés**, chacun avec chemin source/destination, taille et SHA-256. Tous les documents ont été lus. Aucune de leurs appellations n'est référencée par les INI de cartes lors de la recherche textuelle locale. Les références éventuelles dans le reste du projet sont à vérifier par la tâche qui centralise les déplacements.

Les notices sont destinées à `_Documentations/Maps/<dossier de carte>/`. Les versions 1.0/1.1 de Darwin, beta/1-2 de Guadalcanal et les langues FR/EN de LAL Normandie restent distinctes. La notice `ag_Norway/add to all.ini.txt` est bien une instruction lisible et est incluse. En revanche les fichiers `texts*.txt`, `labels*.txt`, `outNStationary.txt` et `new_map/mapsize.txt` sont des ressources/données techniques, pas des notices à déplacer.

## Vérifications et inconnues

- Toutes les observations concernent les fichiers présents sur v1.15 à la date du scan ; les notices peuvent décrire des versions historiques 4.09b.
- Les SHA-256 de `Mbug_Slovakia_winter/load.ini` sont `71E6C2ED5699DCFCDEE1B0EAC78F89EBA0A9A8DDD34C6386130EE416D04FB111` (jeu) et `5484FF9BE83A1D0E54631E587A7D851ADBDE2D8D6874268D0E646740D795B6BB` (source AAA).
- Les SHA-256 de `_Tex/land/winter/Mbug_sk_LowLand0_Hiver.tga` sont `CC995692DEC9BE0291D55C881DCE225C10215D2E30CD41F6D2D088D5BA347334` (jeu) et `3997AB8B3C62BC825C7EB47852A5548763BD0E7D02C95D20D26A9409A64E6294` (source AAA).
- Le scan des crédits ne vérifie ni les droits de redistribution ni la compatibilité d'une future restauration ; aucune restauration n'a été faite.
- La recherche communautaire AAA/Wayback, Mission4Today, SAS est centralisée par la tâche principale. Aucune page distante n'a été lue par cette sous-tâche.
- Aucun processus de jeu, serveur ou analyseur permanent n'a été lancé. Le script s'est terminé.

## Complément après classement

Les 21 notices de cartes ont été déplacées et leurs empreintes vérifiées ; leurs liens ci-dessus pointent désormais vers `_Documentations`. Les fichiers du jeu ont conservé leur emplacement. Le journal global est disponible dans [CLASSEMENT_DOCUMENTATIONS_V1.15.md](CLASSEMENT_DOCUMENTATIONS_V1.15.md).

La notice Alpen, ligne 70, attribue explicitement `fsmd_mount3` à Phasmid et les champs Bob à Rus_Andrey. La comparaison a retrouvé `fsmd_mount3.tga` et `bob_fields_1.tga` identiques aux sources. Ces deux contributions précises sont donc attribuables ; cela ne signifie pas que les packs de textures complets sont intégrés. Les empreintes et la citation locale sont conservées dans [les preuves d’attribution AAA](../manifests/mods/credits-v1.15/aaa-authors.json).
