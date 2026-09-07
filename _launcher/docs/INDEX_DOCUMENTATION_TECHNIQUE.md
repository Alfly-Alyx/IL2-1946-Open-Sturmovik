# Documentation technique d'Open Sturmovik

## Objectif durable : preparer un PDF de reference

Alexis souhaite realiser, a terme, un PDF detaille qui explique le
fonctionnement d'Open Sturmovik et d'IL-2 Sturmovik 1946 : le jeu, son moteur,
son demarrage, ses fichiers, ses formats, ses reglages, ses commandes, ses
mods, ses erreurs et les outils du projet.

Cette intention est une exigence permanente du projet. Toute nouvelle
decouverte utile doit etre documentee au moment ou elle est verifiee, meme si
elle n'est pas necessaire au code en cours. Le futur PDF ne devra pas reposer
sur des souvenirs ou sur des suppositions refaites apres coup.

Le PDF devra pouvoir servir a la fois :

- au joueur qui veut comprendre ce que change un reglage ;
- au contributeur qui doit retrouver le fichier ou le composant responsable ;
- au developpeur qui maintient le lanceur, le moteur ou un mod ;
- au diagnostic d'une installation endommagee ou d'une ressource manquante ;
- a la conservation de connaissances sur un moteur ancien et peu documente.

## Regle de documentation

Chaque constat technique doit, autant que possible, conserver :

1. la version du jeu, du mod, du fichier ou de l'outil concernee ;
2. la source exacte de la preuve : nom relatif, taille, empreinte, classe,
   methode, cle de configuration ou extrait minimal ;
3. la methode d'observation : lecture directe, comparaison, desassemblage
   statique, test controle ou inference ;
4. le niveau de certitude defini ci-dessous ;
5. les limites connues et la prochaine verification a effectuer ;
6. une explication en francais comprehensible, separee du detail interne.

Les chemins personnels, identifiants et autres donnees sensibles ne doivent
pas etre recopies dans les documents ou les rapports distribuables. Les
empreintes et noms relatifs suffisent normalement a identifier une source.

### Niveaux de certitude

| Niveau | Signification |
|---|---|
| Prouve | Lu directement dans le code, le format ou confirme par un test reproductible. |
| Fortement etaye | Plusieurs observations concordent, mais une validation manque encore. |
| Infere | Explication plausible issue du contexte ou d'une comparaison incomplete. |
| Non resolu | Question identifiee ; aucune conclusion ne doit encore etre presentee comme vraie. |

Une valeur observee n'est pas automatiquement une limite valide. Les valeurs
presentes dans un fichier, les valeurs acceptees par le parseur et les limites
effectivement appliquees par le moteur doivent etre distinguees.

## Plan envisage du futur PDF

| Chapitre | Contenu attendu | Etat actuel |
|---|---|---|
| 1. Vue d'ensemble | Histoire des versions visees, place d'Open Sturmovik, vocabulaire. | A structurer |
| 2. Demarrage du jeu | Executables, Selector, wrapper, chargement des classes et ordre d'initialisation. | Premiers artefacts disponibles |
| 3. Architecture du moteur | Parties natives et Java, moteur de vol, rendu, son, entrees et interface. | A cartographier |
| 4. Arborescence et fichiers | Fichiers historiques, dossiers ajoutes, SFS, INI, missions, utilisateurs, ressources. | Regles de nommage et premiers formats documentes |
| 5. Configuration graphique | `conf.ini`, anciens profils `il2setup.ini`, rendu OpenGL/DirectX et limites x86. | Catalogue statique disponible |
| 6. Son | Configuration, banques et chargement ; diagnostic des sons manquants. | Collecte des erreurs commencee |
| 7. Commandes et peripheriques | `settings.ini`, environnements de commandes, axes, courbes, joystick, souris et commandes de mods. | Catalogue de 282 commandes disponible |
| 8. Vues et 6DOF | Vue classique, classes et fichiers requis, difference entre profils. | Comparaison incomplete |
| 9. Realisme et modele de vol | Effets presentes au joueur, donnees internes, contraintes G et synchronisation reseau. | Premier effet identifie |
| 10. Mods et compatibilite | Detection, dependances, commandes ajoutees et differences entre versions. | Base historique comparable manquante |
| 11. Integrite et reparation | Empreintes, fichiers critiques, donnees protegees, transaction et restauration. | Contrat initial disponible |
| 12. Diagnostics | `log.lst`, textures, sons, materiaux, SFS, exceptions Java et rapports anonymises. | Collecteur initial disponible |
| 13. Lanceur | Remplacement d'`il2setup.exe`, profils, interface, confidentialite et GitHub App. | Architecture et contrats initiaux disponibles |
| Annexes | Tables exhaustives, empreintes, formats, glossaire et methodes de reproduction. | En construction continue |

## Documents disponibles

- `CONCEPTION.md` : intention, parcours joueur et architecture du lanceur.
- `RETROINGENIERIE_IL2SETUP.md` : fonctionnement actuellement connu de
  l'ancien `il2setup.exe`.
- `REFERENCE_REGLAGES_COMMANDES.md` : reference lisible des reglages
  `conf.ini`, profils `il2setup.ini`, commandes et plages de valeurs.
- `NOTES_TECHNIQUES_COMMANDES.md` : preuves et points de reprise concernant
  les commandes, axes et fichiers `settings.ini`.
- `RAPPORTS_ERREURS_GITHUB.md` : collecte, anonymisation, consentement et
  envoi des diagnostics par un relais utilisant une GitHub App.

## Catalogues et preuves exploitables

- `../manifests/il2setup-1.0.0.2.json` : contrat de comportement de l'ancien
  configurateur.
- `../manifests/il2setup-catalogue-1.0.0.2.json` : 39 profils historiques et
  leurs cles de configuration observees.
- `../manifests/hotkeys-4.09m-modified.json` : catalogue statique des
  commandes de la version analysee.
- `../manifests/diagnostic-patterns.json` : familles de messages actuellement
  reconnues dans les journaux.
- `../manifests/open-sturmovik-1.15.json` : capacites et fichiers declares pour
  la cible Open Sturmovik actuelle.

Les manifestes sont des donnees de travail versionnees. Le PDF devra les
transformer en explications et tableaux lisibles, sans masquer leur version ni
leur niveau de validation.

## Questions a conserver ouvertes

- Produire un catalogue strictement identique depuis une installation 4.09m
  de reference afin de distinguer les commandes historiques de celles ajoutees.
- Cartographier l'ordre complet de demarrage et le role de chaque executable,
  bibliotheque, archive SFS et classe principale.
- Identifier tous les lecteurs et ecrivains de `conf.ini`, `settings.ini` et
  des autres fichiers de configuration.
- Prouver les limites acceptees, puis celles effectivement appliquees, pour
  chaque cle qui n'est actuellement connue que par les profils historiques.
- Documenter les formats de ressources et les chemins de recherche des
  textures, sons, materiaux, meshes et fichiers localises.
- Distinguer ce qui doit etre identique entre client et serveur de ce qui reste
  purement local.
- Identifier et valider un vrai ensemble de fichiers 6DOF distinct du profil
  classique.
- Maintenir un glossaire francais/anglais des termes visibles dans le jeu et
  des identifiants utilises en interne.

