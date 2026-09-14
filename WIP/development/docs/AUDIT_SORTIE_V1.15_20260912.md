# Verdict de sortie — Open Sturmovik v1.15

Audit du 12 septembre 2026, sur la branche `v1.15`.

> Suite de cet audit : la copie de test a depuis ete actualisee et relancee
> a la demande d'Alexis. Voir [le compte rendu](RELANCE_TEST_V1.15_20260912.md).
> Les etats Git, la copie anterieure et les essais decrits ci-dessous sont
> ceux de l'audit initial, avant cette relance et sa consolidation.

## Révision après suppression de l'ancienne ébauche

Alexis a supprimé `installer/Open_Sturmovik_Update_1.15.iss` après cet audit ;
son absence a été vérifiée. Les observations ci-dessous sur son comportement
sont donc historiques et ne doivent plus être présentées comme les défauts
d'un installateur actuel. Aucun de ses fichiers n'a été restauré.

Le verdict sur le **contenu du jeu**, indépendamment de l'installateur, reste
une qualification finale non acquise : les essais en jeu du contenu après
retrait MDS et reconstruction des classes concernées restent à effectuer ;
la copie de test est encore documentée comme antérieure aux retraits. Les
deux armements CW-21 attendent leur confirmation en vol et le son moteur
trop faible reste décrit comme non corrigé dans l'état courant.

Les résultats de tests ci-dessous sont ceux obtenus avant cette suppression.
Les contrôles qui lisent l'ancien fichier `.iss` ne sont pas présentés comme
ayant été exécutés avec succès après sa suppression.

## Verdict

**La v1.15 n'est pas prête, en l'état, pour une publication définitive.**
Les contrôles hors jeu exécutés avant la suppression de l'ébauche passaient,
mais l'installation complète n'est pas encore
produite ni validée et les fichiers actuels n'ont pas reçu leur validation
fonctionnelle finale en jeu après les retraits et reconstructions.

La cible confirmée par Alexis est une **réinstallation complète du pack** sur
une installation IL-2 compatible, sans dépendance à Open Sturmovik v1.10.
L'ancien scénario de patch d'une version précédente n'est pas la cible de sortie.

Cet audit n'a lancé ni le jeu ni une installation, n'a changé aucune branche
et n'a créé aucun commit, tag ou release. Les précisions de présentation,
de nom et de licence ont été mises à jour séparément dans les documents.

## État examiné

- Racine Git : `C:/Users/Alexis/DATA/Projets/GITHUB/IL2-1946-Open-Sturmovik`.
- HEAD local : `78de71fa36ce800257d9ecd28bce5e991ccf36e5`.
- La référence GitHub `refs/heads/v1.15` pointe sur ce même commit au contrôle.
- Les dernières modifications de crédits, de présentation et de licence sont
  encore locales et non commitées ; leur présence locale n'implique pas leur
  présence sur GitHub.
- Les releases GitHub retournées sont `v1.0` et `v1.1` ; aucune release v1.15
  ni exécutable final v1.15 n'est publié au moment du contrôle.
- Aucun lancement GitHub Actions n'est retourné pour `v1.15`. Ce constat
  n'est pas, à lui seul, une exigence supplémentaire de publication.

Sources distantes : [branche](https://api.github.com/repos/Alfly-Alyx/IL2-1946-Open-Sturmovik/git/ref/heads/v1.15),
[releases](https://github.com/Alfly-Alyx/IL2-1946-Open-Sturmovik/releases),
[exécutions v1.15](https://api.github.com/repos/Alfly-Alyx/IL2-1946-Open-Sturmovik/actions/runs?branch=v1.15).

## Contrôles réussis avant suppression de l'ébauche et limites

| Contrôle exécuté | Résultat consigné lors de l'audit | Ce qu'il ne prouve pas |
| --- | --- | --- |
| `tools/Test-V115OfflineReadiness.ps1` | 7 PASS, 0 WARN, 0 FAIL au niveau agrégé. Le contrôle de contenu inclus retourne 24 PASS, 1 WARN, 0 FAIL, avec exclusion explicite du nucléaire. | Le WARN interne demande une preuve de chargement en exécution. Le succès du contrôle de présence du protocole ne signifie pas que ce protocole a été exécuté. |
| `tools/Test-NoMds.py` | 1 929 classes examinées ; 648 chemins retirés absents ; 51 fichiers nettoyés et neuf archives de profils conformes. | Une installation ancienne n'est pas nettoyée par la seule absence de ces fichiers dans le dépôt. Ce contrôle ne lance pas le moteur reconstruit. |
| `tools/Audit-SwitcherClassAvailability.py` | Aucune classe d'appareil directement absente parmi les 516 / 516 / 535 entrées des profils modifiés 4.08m / 4.09b / 4.09m, avec les archives communes examinées et les archives propres aux versions. | L'analyse utilise notamment les 48 archives communes de la copie de test ; elle ne qualifie pas une nouvelle installation. Des références indirectes restent non résolues. |
| Crédits et interface du switcher | `Build-SwitcherCredits.py --check` et `Test-SwitcherGui.cjs` réussis après la dernière régénération. | Il s'agit du contenu généré et de tests avec une interface simulée, sans lancement du jeu. |
| Manifestes du switcher | BAT de 74 525 octets ; SHA-256 `0AEB27942B6E3297BB71D80E146D0A2F8A04521DE1C27668400EB9906E08BFCB`, conforme aux deux manifestes. | Une empreinte conforme ne démontre pas toute la compatibilité du pack. |
| Raccourcis | Huit cibles vérifiées, données Mission Mate et cartes ZipNav présentes. `InstalledShortcutsVerified=false`. | Aucun ensemble de raccourcis produit par une installation réelle n'a été validé dans cet audit. |

Le contrôle de diagnostic utilise des données synthétiques et un faux processus
de jeu, avec génération locale et simulation d'installation ; aucun rapport
n'a été envoyé à GitHub et aucun véritable IL-2 n'a été lancé.

L'audit nucléaire retourne aussi 42 PASS et zéro FAIL statique. Ce chantier
est déclaré hors du périmètre de qualification v1.15 par l'état courant ;
il n'est pas utilisé comme blocage prioritaire ici. L'état de publication
codé en dur dans son outil n'est pas une conclusion nouvelle sur les droits.

## Blocages de livraison complète

1. **Le paquet complet et son exécutable n'existent pas encore.**
   `installer/Payload` et `installer/Output` sont absents. Les emplacements
   correspondants dans les ressources locales `Patch v1.15` ne fournissent
   pas de paquet final. Le compilateur portable est disponible, mais l'ancienne
   ébauche `installer/Open_Sturmovik_Update_1.15.iss` a été supprimée après
   cet audit. Il faut constituer le contenu complet avec ses licences et notices,
   puis créer et éprouver le futur installateur pour la cible
   confirmée de réinstallation complète.

2. **La reconnaissance de la base IL-2 reste à mettre en œuvre et à valider.**
   Dans l'ancienne ébauche, `FindPreviousInstallation`, lignes 72–82,
   cherchait une entrée de registre Open Sturmovik puis proposait un chemin
   Ubisoft par défaut. Le contrôle aux lignes 91–92 vérifiait seulement la
   présence d'`il2fb.exe`. Il ne validait ni les archives nécessaires ni une
   version compatible et ne reconnaissait pas automatiquement les installations
   ordinaires du jeu. Le futur installateur devra vérifier une base compatible.

3. **Une réinstallation par simple recopie conserverait des fichiers obsolètes.**
   Dans l'ancienne ébauche, la section `[InstallDelete]`, lignes 40–55, ne
   prenait pas en charge les retraits DCG, San, Malta et MDS. Les étapes `[Run]`
   ne les traitaient pas non plus. Par exemple, `Files/00A5F952A58045D8`,
   déclaré retiré dans [le manifeste MDS](../manifests/mods/retired-zuti-mds-v1.15.json),
   aurait été conservé dans une ancienne installation par cette ébauche.
   La livraison complète doit partir d'une base propre ou assurer une remise
   en état contrôlée, avec préservation des données du joueur. Aucun nettoyage
   de l'installation d'Alexis n'a été effectué par cet audit.

4. **La conservation des données et la réinstallation réelle restent à éprouver.**
   La copie générique de l'ancienne ébauche excluait `Users`, mais pas automatiquement
   `conf.ini` ni les données personnelles ailleurs dans l'arborescence.
   Le contenu final devra être contrôlé à cet égard. Il faut essayer la
   détection, l'installation complète, une réinstallation et les outils dans
   une copie dédiée, y compris les droits d'écriture lorsque le jeu est dans
   `Program Files`.

Un défaut du test de raccourcis est également identifié :
`Test-OpenSturmovikUtilityShortcuts.ps1`, lignes 134–137, compare la cible du
raccourci installé à `entry.Target` au lieu de tenir compte de
`entry.ShortcutTarget`. Le switcher vise correctement `mshta.exe` avec le BAT
dans ses arguments, mais cette branche du test attendrait le BAT comme cible.
Le PASS consigné n'exécutait pas cette branche faute de `-DesktopPath`. Le test
doit être corrigé avant de servir à valider les raccourcis réellement installés.

## Validation fonctionnelle encore nécessaire

Les [retraits du 12 septembre](RETRAIT_ZUTI_MDS_V1.15.md) et
[l'état courant](ETAT_COURANT_V1.15.md) indiquent que la copie de test n'est
pas encore actualisée avec les retraits. Les anciens essais ne valident donc
pas l'ensemble actuel.

Les essais ciblés restant nécessaires sont :

- démarrage, mission standard, éditeur complet de missions, hôte/client et
  fermeture après retrait MDS et reconstruction des classes concernées ;
- fonctionnement AOC avec les 266 profils distribués ;
- deux armements CW-21, absence de doublons et diagnostic de son moteur,
  dont le volume trop faible reste décrit comme non corrigé ;
- sons concernés Allison/Tiger33 et fin des boucles de démarrage ;
- profils historiques, 6DOF/TrackIR et opérations représentatives des outils.

La référence statique non résolue des F-86-A5/F1/F30 via `X_86` vers
`MIG_15SV` doit faire l'objet d'un essai ciblé ; elle ne constitue pas à elle
seule un plantage reproduit. Voir l'explication dans
[CORRECTION_SWITCHER_V1.15.md](CORRECTION_SWITCHER_V1.15.md).

Les acquis utilisateur sont conservés : KB-29P fonctionnel, titre de fenêtre,
qualité des nuages DirectX sur les scènes essayées et maintien de la simulation
à la perte de focus. Ils ne sont pas annulés par cet audit et ne nécessitent
pas d'être répétés sans changement ou régression les concernant. La campagne
à terminer est décrite dans [CAMPAGNE_FINALE_V1.15.md](CAMPAGNE_FINALE_V1.15.md).

## Crédits, licence et conditions tierces

La relecture bornée n'a pas mis en évidence de nouvelle restriction explicite
incompatible visant un composant encore actif. Les quatre restrictions déjà
identifiées concernent les composants retirés. Aucun autre retrait n'a été
décidé dans cet audit.

Les permissions de tous les éléments tiers ne sont pas pour autant établies :
les inventaires conservent notamment des limites de preuve pour Tiger33,
CW-21 et Silverplate. L'attribution des images et l'appel aux auteurs ne
complètent pas ces permissions. La licence d'Alfly porte sur ses seuls apports
originaux dans la mesure de ses droits, selon [LICENSING.md](LICENSING.md).

La notice Silverplate a été corrigée pour distinguer une permission non
retrouvée d'une interdiction démontrée. Cette correction documentaire ne
modifie ni les droits de l'auteur ni les fichiers du composant. Les conditions
des composants tiers doivent accompagner les éléments effectivement livrés.

## Conditions pour réexaminer le verdict

Le passage à une sortie définitive demande un ensemble complet identifié,
un installateur adapté à cette réinstallation et testé sur une copie dédiée,
la clôture des essais fonctionnels affectés par les derniers changements,
puis la fixation et la publication des fichiers réellement validés avec leurs
notices. Les contrôles hors jeu réussis constituent une base utile pour cette
qualification ; ils ne suffisent pas à déclarer la sortie définitive prête.

## Traces locales de cet audit

- Résultat agrégé :
  `C:/Users/Alexis/.codex/visualizations/2026/09/12/01a094b0-535f-7413-93c1-d5a15ca65ad3/audit-sortie-v115-20260912-offline.txt`.
- Rapport de disponibilité : même dossier, sous
  `audit-fonctionnement-final/classes-profiles-full-sfs.json`.
- Rapport nucléaire : même dossier, sous `audit-fonctionnement-final/nuclear.json`.

Les commandes ont été exécutées depuis `C:/Users/Alexis/.codex` avec les
chemins absolus du dépôt et une exception Git temporaire `safe.directory`
limitée au dépôt concerné. Les programmes synthétiques du contrôle de
diagnostic se sont terminés ; aucun jeu ou processus lourd de cet audit
n'est laissé en cours.
