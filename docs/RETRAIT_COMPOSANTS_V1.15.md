# Retrait des composants soumis a permission — 12 septembre 2026

## Demande et etat reel

Alexis a demande le retrait des composants dont les conditions explicites
demandent une autorisation non retrouvee pour leur inclusion dans Open Sturmovik,
leur conservation hors du pack, puis la mise a jour des credits. Le dossier
confirme est **un seul dossier `besoin_licence`** sous :

`D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés`.

Les recherches de contact se limitent aux emails publies et aux pages accessibles
sans inscription. Aucun compte cree, aucune demande envoyee. Une adresse
retrouvee ne constitue pas une autorisation de redistribution.

| Composant | Etat du contenu actif | Sauvegarde |
| --- | --- | --- |
| Lowengrin DCG 3.43 | Retire : 391 fichiers utilitaires et 2 notices | `besoin_licence/Lowengrin DCG 3.43`, 393 fichiers verifies par SHA-256 ; `manifest-sha256.json` |
| San FOV Changer 1.0 | Retire : 4 fichiers utilitaires et 2 notices | `besoin_licence/San FOV Changer 1.0`, 6 fichiers verifies par SHA-256 ; `manifest-sha256.json` |
| Malta v1.3 — 6S.Maraz | Retire : 192 fichiers, dont 96 missions, 3 campagnes dependantes et fichiers associes ; 7 declarations carte et 1 entree QMB retirees | `besoin_licence/Malta - 6S.Maraz` : 210 copies verifiees, incluant 2 configurations avant modification et 16 fichiers sources AAA |
| Zuti MDS 1.13 | **Encore present. Retrait moteur non effectue.** | `besoin_licence/Zuti MDS 1.13/sauvegarde_partielle_20260912` : 689 fichiers, 7 885 098 octets verifies par SHA-256 ; sauvegarde partielle des classes fusionnees et pieces associees, pas un mod complet retire |

Le manifeste Malta est
[`manifests/mods/retired-malta-v1.15.json`](../manifests/mods/retired-malta-v1.15.json).
Les archives DCG/San reproduisent le contenu local distribue avant retrait,
pas une certification de paquet original complet de leurs auteurs.
La source locale Malta contient la carte et sa notice mais pas les trois
missions annoncees par cette notice : le dossier est un corpus reconstitue.

Les suppressions ont porte sur les seuls fichiers suivis Git, inventories et
verifies identiques a leur copie sauvegardee. Les sources historiques ont ete
conservees. Les configurations utilisateur, DGen/NGen et les dossiers WIP
n'ont pas ete nettoyes ou resynchronises par cette operation.

## Conditions retrouvees dans les notices

| Composant | Source primaire locale | Condition concernant le pack |
| --- | --- | --- |
| DCG 3.43 | Archive `documentation/Readme.txt`, ligne 273 | Permission ecrite demandee avant hebergement Internet ou redistribution sur CD/DVD |
| San FOV 1.0 | Archive `documentation/Manuel - San FOV Changer 1.0 - anglais.pdf`, p. 10 | Permission demandee avant inclusion dans un mod-pack ; restrictions de diffusion et d'usage commercial |
| Malta | Source AAA `MODS/MapMods/Maps/mrz_Malta/Malta release-notes-1_3.txt`, lignes 102–104, copie dans l'archive | Distribution inchangee permise ; permission demandee pour modification ou incorporation dans un mod plus grand |
| Zuti MDS 1.13 | `_Documentations/Mods and Tools/Zuti MDS 1.13/Lisez-moi - Zuti MDS 1.13.txt`, lignes 5–9 | Contacter l'auteur et demander sa permission avant inclusion dans un pack |

Il s'agit de conditions de redistribution/integration, pas d'une preuve
d'obligation d'achat pour installer ces mods chez soi. L'absence d'une preuve
dans les fichiers examines ne prouve pas que l'auteur n'a jamais donne d'accord.
Les autres composants aux conditions incompletement documentees n'ont pas ete
retires sur ce seul motif. Cela ne vaut pas validation globale des droits du pack.

## Contacts demandes

Chaque sous-dossier contient `CONTACT_DEVELOPPEUR.txt` avec resultat, sources,
date et limites de la recherche.

| Auteur | Resultat |
| --- | --- |
| Lowengrin | `lowengrin@shaw.ca`, adresse historique publiee pour PayPal dans le Readme, ligne 18 ; reception actuelle non verifiee |
| San | Adresse email publique non trouvee |
| 6S.Maraz | Adresse email publique non trouvee |
| Zuti | Adresse email publique non trouvee |

Les notices locales ont ete examinees en premier. AAA/Wayback a ete recherche
mais les captures visees etaient inaccessibles. Les pages et resultats publics
Mission4Today, SAS, WSGF et les sites historiques d'auteurs n'ont pas donne
d'adresse supplementaire attestee. Les liens precis et echecs d'acces figurent
dans les fichiers de contact. Aucun recours a l'inscription ou a une messagerie
de forum n'est propose, conformement a la demande d'Alexis.

## Credits et integration apres retrait

Les lignes DCG et San ont ete retirees de la source Markdown des credits et
de sa page generee dans le switcher. Malta et les trois campagnes retirees
n'avaient pas d'entree sur cette page. Les rapports de scan dates restent
conserves comme preuves historiques ; ils ne representent plus l'inventaire
actuel de ces composants.

Zuti et les contributions incorporees encore presentes restent credites.
Retirer seulement un nom d'auteur masquerait du code encore distribue.

Le manifeste, les scripts de preparation/finalisation, l'installateur et les
tests des raccourcis annoncent **sept utilitaires et le switcher, soit huit
raccourcis**. L'initialisation ne depend plus de San et ne regle plus le FOV,
SaveAspect ou DeviceLink. Les reglages existants n'ont pas ete modifies.

Pour Malta, Darwin Small, `Flag_Malta`, `Malta_42` et les textures communes ont
ete preserves. Les trois campagnes retirees sont `Fortress_Malta`,
`OperationAegeus` et `FliegerkorpsX`, dont toutes les missions dependaient de
`mrz_Malta`. Aucune mission restante examinee n'appelle cette carte.

## Limite technique Zuti

Voir [l'analyse reproductible du retrait Zuti](AUDIT_RETRAIT_ZUTI_V1.15_20260912.md).
Le scan trouve 253 classes contenant une reference Zuti ; les remplacer ou
les supprimer en bloc introduirait 317 references de membres introuvables
dans 82 classes. Ce constat ne signifie pas que les 253 classes appartiennent
exclusivement au mod : plusieurs contiennent des fonctions partagees.

Au minimum, les controles d'avions, le moteur AOC et les explosions contiennent
des apports melanges. Les familles internes doivent etre traitees ensemble,
et les trois versions proposees par le switcher doivent rester compatibles.
Les ressources disponibles n'etablissent pas encore une methode de retrait
qui conserve ces fonctions. Aucun remplacement moteur n'a ete applique.

La regle du depot exige une demande explicite dans une tache dediee pour
modifier le moteur. Une reconstruction des familles partagees reste donc a
definir avec Alexis avant application. La sortie finale reste ouverte tant
que ce retrait n'est pas realise ou qu'une permission correspondante n'est
pas obtenue. Aucun installateur final ni publication n'a ete produit.

## Verifications

- DCG/San : sauvegardes verifiees avant retrait ; huit cibles de raccourcis
  passent sous Windows PowerShell 5.1 ; huit declarations Inno coherentes ;
  syntaxe des six scripts modifies valide.
- Initialiseur exerce dans une copie minimale sans San/DCG : chemins
  Mission Mate prepares ; `conf.ini` et profil utilisateur inchanges par SHA-256.
- Malta : 210 copies verifiees ; 192 anciens chemins retires ; aucun appel
  actif `mrz_Malta` dans les missions ; 24 fichiers temoins preserves.
- Credits : 41 contributions apres retrait des deux lignes ; page generee
  identique au Markdown, UTF-8 sans BOM et fins de ligne CRLF. Les empreintes
  du BAT ont ete actualisees dans les deux manifestes courants.
- `Test-SwitcherGui.cjs` : neuf profils, 18 combinaisons profil/HUD,
  restaurations et navigation Credits passes ; controle de logique hors jeu.
- `Test-AircraftNameReview.py` : 12 tests passes.
- `Test-OpenSturmovikContent.ps1 -ExcludeNuclear` sur le depot : 24 PASS,
  1 WARN, 0 FAIL. L'avertissement concerne l'absence de nouveau dump runtime.
  Le test confirme encore la presence de Zuti ; il ne valide pas son retrait
  ni les droits de redistribution. Rapport conserve dans le dossier d'audit
  local `.codex/visualizations/2026/09/12/01a094b0-535f-7413-93c1-d5a15ca65ad3/audit-final/contenu-apres-retraits.json`.
- Reproduction de l'analyse Zuti : inventaire identique apres normalisation
  du chemin D:/C: ; aucune reconstruction moteur appliquee.
- Aucun jeu lance pour ces retraits. Les essais runtime et la qualification
  de l'installateur restent a faire apres resolution des points ouverts.
