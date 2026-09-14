# Audit des profils 4.08 / 4.09

Derniere mise a jour : 7 septembre 2026.

## Couples binaires

Les neuf dossiers du selecteur ont ete compares par SHA-256 et par contenu SFS.
La source locale AAA Community Installer 1.1 a ensuite permis de retrouver le
vrai differentiel binaire entre les executables avec et sans 6DOF.

| Groupe | Resultat |
| --- | --- |
| Six profils modifies | Meme format d'`il2fb.exe` de 274 432 octets et meme `wrapper.dll` de 233 472 octets ; deux empreintes d'EXE existent maintenant selon le choix 6DOF |
| Trois profils Original | Meme `il2fb.exe` de 4 548 608 octets ; aucun `wrapper.dll` requis |
| 4.08 modifie avec/sans 6DOF | `files.SFS` et wrapper identiques ; EXE distincts |
| 4.09b modifie avec/sans 6DOF | `files.SFS` et wrapper identiques ; EXE distincts |
| 4.09m modifie avec/sans 6DOF | `files.SFS` et wrapper identiques ; EXE distincts |

L'EXE v1.15 commun etait la variante 6DOF. Les trois profils sans 6DOF ont ete
restaures a partir du differentiel exact des deux EXE AAA historiques, sans
remplacer les ressources PE ni l'ajustement Large Address Aware courant :

- avec 6DOF : SHA-256
  `7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21` ;
- sans 6DOF : SHA-256
  `BA1C702C1FC0DCC3D760FAEE46F74AD8BDF3D8CB5CE44B2CA40DAA3F75343C80`.

Ces empreintes finales incluent la ressource Windows v1.15 qui declare
`Open Sturmovik` comme description et nom de produit, ainsi que l'icone
`avion-ciel` reservee aux profils modifies. Les empreintes
intermediaires, avant ce marquage mais apres la restauration du differentiel
6DOF, restent consignees dans `manifests/profiles-6dof-v1.15.json`.

Les cinq classes de `6DOF_Tracker_2_0_sHr` sont deja presentes dans `Files` et
identiques a la source locale. Elles fournissent six valeurs TrackIR et leur
consommation par `HookPilot`. Le manifeste reproductible est
`manifests/profiles-6dof-v1.15.json` et l'outil de reconstruction est
`tools/Patch-IL2No6DofProfiles.ps1`.

## Evolution des `files.SFS`

| Transition | Ajouts | Retraits | Contenus modifies | Identiques |
| --- | ---: | ---: | ---: | ---: |
| 4.08 modifie -> 4.09b modifie | 0 | 0 | 16 | 9 955 |
| 4.08 Original -> 4.09b Original | 0 | 0 | 16 | 10 059 |
| 4.09b modifie -> 4.09m modifie | 470 | 0 | 62 | 9 909 |
| 4.09b Original -> 4.09m Original | 468 | 0 | 86 | 9 989 |

Le profil 4.09m n'est donc pas un simple renommage de 4.09b. Parmi les ajouts identifiables figurent des classes d'avions, cockpits, armes, vehicules et decals. Les changements connus touchent notamment `SFSInputStream`, le rendu, le reseau, le moteur, l'interface, les registres et les traductions. La version 1.15 doit continuer a utiliser les dossiers `4.09final...` pour sa cible stable.

## Registres libres

Le selecteur basculait deja `air.ini`, mais les deux fichiers historiques `stationary.ini` n'etaient jamais copies. Le fichier actif du depot correspondait encore au profil commun 4.08/4.09b :

| Registre | Taille | SHA-256 |
| --- | ---: | --- |
| 4.08/4.09b | 52 177 | `C9E5A7E59941945D0434B58CB6F0097EBFC4E31236D0FFF49907830B13E11DD4` |
| 4.09m | 53 246 | `9A446C92C5D88986EDADC280689C9F4A1799EEFE1E646017A79E2B7544A18882` |

Le selecteur 1.15 inclut maintenant `stationary.ini` dans la meme transaction verifiee que l'EXE, `files.SFS` et `air.ini`. Les choix 1 a 6 installent le registre 4.08/4.09b ; les choix 7 a 9 installent le registre 4.09m.

### Role verifie de `stationary.ini`

Le fichier local officiel `bldconf.ini` branche explicitement le module de
l'editeur complet `builder.PlMisStatic` sur
`com/maddox/il2/objects/stationary.ini`. Ce registre alimente les familles
d'objets statiques placables dans une mission : `Artillery`,
`StationaryArmor`, `StationaryObjects`, `StationaryPlanes`,
`StationaryShips` et `StationaryShipPack`. Chaque ligne associe le nom presente
par l'editeur a une classe Java concrete et a son camp numerique.

Ce n'est donc pas un second `air.ini`. `air.ini` declare la liste des appareils
du moteur ; `stationary.ini` declare leurs representations posees au sol, ainsi
que les canons, blindes, objets et navires statiques. Un appareil peut etre
present dans la liste de vol sans avoir son equivalent statique, ou inversement.
Une mission deja sauvegardee contient la classe concrete de l'objet ; un
registre ou une classe incompatible peut faire disparaitre un choix de
l'editeur ou empecher le chargement correct de cet objet.

Le registre 4.08/4.09b mesure 52 177 octets et 818 entrees. Celui de 4.09m
mesure 53 246 octets et 836 entrees. Les 18 ajouts sont tous dans
`StationaryPlanes`, notamment le CW-21, les D.XXI, I-15/I-16, Avia B.534,
G.55, Re.2000, S.328 et SM.79. C'est pourquoi le switcher remplace ce registre
avec la version : conserver le fichier 4.09m en 4.08/4.09b exposerait dans
l'editeur des classes absentes de ces payloads.

Recoupement communautaire :

- [Mission4Today, configuration de l'editeur complet](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=16676)
  reproduit le branchement `builder.PlMisStatic` vers `stationary.ini` ;
- [SAS, guide Mod Activator 4.09](https://www.sas1946.com/main/index.php?topic=5310.0)
  confirme que l'ajout de lignes de navires dans ces registres fait apparaitre
  les nouvelles categories dans l'editeur complet ;
- la recherche AAA prioritaire via Wayback n'a fourni aucune page exploitable
  supplementaire ; aucun contenu inaccessible n'est suppose.

## Transaction hors jeu exercee

Le 6 septembre 2026, le switcher corrige a ete execute dans la copie isolee,
sans lancer IL-2 :

| Etape | Resultat verifie |
| --- | --- |
| Profil 1, 4.08m Original, HUD standard | EXE et `files.SFS` originaux ; wrapper et trois archives 4.09 retires ; HUD standard exact |
| Profil 2, 4.08m modifie sans 6DOF, HUD immersion | EXE marque, wrapper, `files.SFS` et DLL coeur/son 4.08m exacts ; archives 4.09 absentes ; HUD immersion exact |
| Profil 8, 4.09m modifie sans 6DOF, HUD standard | EXE marque, wrapper, `files.SFS`, charge utile, `air.ini`, `stationary.ini` et HUD 4.09m exacts |

Les trois appels ont retourne zero, sans chemin introuvable ni message duplique.
Aucun dossier `_transaction-*` n'est reste. La copie de test est donc revenue
au profil 8 dans un etat mesure, pas seulement declare.

Le controle etendu du 7 septembre a ensuite exerce les neuf profils avec les
deux fichiers HUD. Les choix 1/2/3 utilisent tous le payload 4.08m et retirent
les archives 4.09 ; 4/5/6 utilisent le payload 4.09b ; 7/8/9 utilisent le
payload 4.09m. Les 18 commutations normales passent. Le test de panne tardive
du BAT unique restaure aussi les 14 fichiers actifs et revient au profil 8.

## Fichiers actifs avant le premier essai runtime

La racine du depot n'est pas consideree comme une installation de jeu complete
ni comme la preuve d'un profil correctement active. La campagne finale devra
partir de la copie actuellement validee au choix 8, `4.09m modifie (sans
6DOF)`, puis comparer le choix 9, `4.09m modifie avec 6DOF`, et enfin revenir au
choix 8 pour prouver le comportement TrackIR et la restauration en conditions
runtime.

## Compatibilite Plane par profil — 13 septembre 2026

### Faits verifies

Un clic sur `il2fb.exe` apres activation du profil 2 (4.08m modde) ou du profil 5 (4.09b modde) pouvait ne produire aucune fenetre. Le profil 5 quittait avec le code 1 pendant l'initialisation de `Ship`; le journal Java indiquait `RuntimeException: Can't set property`. Le profil 4.09b Original demarrait, ce qui a circonscrit le probleme au chargement des classes libres par `wrapper.dll`.

Les essais A/B dans `WIP/tests/installations/IL 2 Sturmovik 1946 test` ont isole `Files/2B9A89D62FA5D19A`, classe `com.maddox.il2.objects.vehicles.planes.Plane`. La variante v1.15 de 83 967 octets, SHA-256 `FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059`, est destinee a 4.09m. La variante historique Open Sturmovik de 82 699 octets, SHA-256 `CFCC074266A0EDFF44D439884D92667EAD6EAC84FE3B59E8BBA97B08244634BB`, permet aux moteurs 4.08m et 4.09b d'achever leur demarrage.

`Plane` appartient au registre des avions places comme objets statiques. Les avions pilotables restent declares par le `air.ini` propre a chaque version et par leurs classes. La correction ne retire ni les classes `Ship` libres ni les entrees d'avions de `air.ini`.

Chaque dossier de profil contient desormais `Profiles/Files/2B9A89D62FA5D19A`. Les profils 1 a 6 possedent la variante historique compatible; les profils 7 a 9 possedent la variante v1.15 pour 4.09m. Le BAT verifie son empreinte, le prepare, sauvegarde le fichier actif comme seizieme element transactionnel, le copie et le restaure en cas d'echec. Tous les chemins sont calcules depuis `%~dp0`.

Essais reels apres integration, chacun arrete volontairement apres 15 secondes : profils 2, 5 et 8 encore actifs, fenetre intitulee `Open Sturmovik`. Le passage au profil 8 a restaure exactement l'empreinte 4.09m.

### Deduction et limite

La difference de `Plane` provoquait l'echec d'initialisation observe avec les assemblages anciens. Les trois demarrages valident l'amorcage et l'arrivee de la fenetre; ils ne remplacent pas un essai en mission de chaque avion statique, avion pilotable et navire pour les neuf profils.
