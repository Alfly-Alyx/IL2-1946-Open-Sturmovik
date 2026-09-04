# Etat courant faisant autorite — Open Sturmovik v1.15

Derniere consolidation : 4 septembre 2026, apres l'essai interrompu des
cameras nucleaires.

## Regle de lecture

Ce document est la source de verite pour reprendre le travail. Les journaux et
rapports dates conservent l'historique et les preuves, y compris les erreurs de
protocole, mais ne doivent pas etre utilises comme consigne lorsqu'ils
contredisent cet etat courant.

## Perimetre et emplacements

- depot de travail :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik` ;
- branche active : `v1.15` ;
- ne jamais executer `git switch` sans demande explicite d'Alexis ou sans son
  accord prealable ;
- copie de test modifiable :
  `WIP/test-installations/IL 2 Sturmovik 1946 test` ;
- reference originale protegee, lecture seule :
  `WIP/resources/IL2/IL 2 Sturmovik 1946` ;
- ressources externes et sauvegarde des outils, lecture seule :
  `D:\Projets\GITHUB\#res\IL2 1946` ;
- donnees lourdes de travail, captures, SDK, sauvegardes et laboratoires :
  `WIP/`.

Le lanceur constitue un axe lie mais separe dans son worktree
`WIP/worktrees/launcher`. Le chantier nucleaire reste sur `v1.15`.

## Cible de la v1.15

- base IL-2 1946 4.09m moddee ;
- installation possible au-dessus d'une base DVD 4.07m avec les donnees des
  correctifs 4.08m et 4.09m necessaires ;
- profil de test 9 : 4.09m modifie, choix 6DOF historique, wrapper historique,
  OpenGL natif ;
- executable PE32 x86 Large Address Aware ;
- cible Windows 32 bits : jusqu'a 3 Gio d'espace utilisateur avec 4GT ; la
  qualification x86 reelle reste obligatoire ;
- quatre coeurs physiques au maximum pour la v1.15 ; le support HT sera etudie
  ulterieurement ;
- profil graphique de test : haute qualite securisee x86, fenetre 1024 x 768 ;
- objectif du projet : realisme maximal, qualite visuelle elevee et mods
  compatibles entre eux, actifs par defaut seulement apres validation.

## Etat fonctionnel confirme

La validation precedente au dernier lancement donne 47 controles de
disponibilite reussis, avec une seule anomalie de contenu explicitement toleree
pour l'essai : la chaine sonore Allison.

Sont actuellement verifies hors jeu ou deja confirmes en jeu :

- 52 SFS racine conformes a la base 4.09m, sans SFS posterieur ;
- `air.ini`, `stationary.ini`, `Buttons`, `files.SFS`, executable et wrapper du
  profil 9 coherents ;
- executable Large Address Aware et masque d'affinite de quatre coeurs
  physiques ;
- 343 enregistrements SPAWN regroupes dans une `Plane.class` Java major 47 ;
- TBF-1C, TBM-3 et Pokryshkins MiG-3 restaures et pilotables ;
- Su-2 restaure et valide en vol avec son cockpit ;
- cockpit pilote du B-29 Silverplate restaure ;
- materiau `WheelTire.mat` du Bf-109G-2 repare ;
- collision periodique `ZutiTimer_ExtendPlanesWings` corrigee statiquement ;
- six navires reintegres dans `chief.ini` ;
- collisions directes de noms de presets sonores nettoyees ;
- profil Intel UHD 620 stable en mode Excellent. Les avis Perfect sur les
  anciennes extensions NVIDIA sont des avis de capacite, pas des erreurs de
  chargement.

## Blocages de sortie connus

1. Le rendu nucleaire n'est pas encore valide sur tout son cycle.
2. La chaine sonore Allison est incomplete : trois presets runtime manquent,
   deux presets `_tb` sont incomplets et `Allison_XX_Startup.wav` manque.
3. Le probleme critique des nuages reste a traiter : textures incorrectes,
   intersections avec le sol et comportement a controler sur plusieurs cartes.
4. Zuti MDS et AOC 1a doivent encore recevoir une validation runtime complete,
   puis AOC 3A devra etre etudie separement avant toute substitution.
5. Le chargement progressif des textures, les saccades de paysage, les profils
   anticrenelage et les wrappers graphiques modernes restent a qualifier.
6. La licence ou l'autorisation de redistribution de Silverplate v1.2 n'est pas
   etablie.

OS_Programs attend la fin du chantier des bombes atomiques avant de poursuivre
les bombes lourdes. Le lanceur ne doit pas faire deriver la stabilisation du
runtime v1.15.

## Chantier nucleaire suspendu

Alexis a arrete le chantier des bombes le 4 septembre 2026. Aucun nouveau test,
aucune nouvelle mission et aucune modification de l'effet nucleaire ne doivent
etre entrepris sans une nouvelle demande explicite. Les classes, mesures et
captures deja obtenues sont conservees pour une reprise ulterieure.

### Etat technique au moment de la suspension

Le candidat courant utilise des couches fixes bornees plutot qu'un emetteur
mobile. Le souffle, les degats et le delai de propagation `distance / 343` ont
ete conserves. Les classes sont Java major 47, leur construction est
reproductible et le cycle hors jeu nettoie ses acteurs avant 3 728 secondes.

Les cibles physiques encore a mesurer dans le jeu sont notamment :

- hauteur, largeur et vitesse de montee du champignon ;
- diametre et duree de la boule de feu ;
- vitesse, largeur et rayon d'action de l'onde de choc ;
- souffle, degats, vents verticaux, turbulences et instabilite aerodynamique ;
- comportement distinct sur terre et sur l'eau ;
- pause, reprise, demi-tour, sortie du champ, retour camera et acceleration du
  temps ;
- disparition complete des effets, memoire stable et autorite reseau
  hote/client ;
- mission dense de seize B-29 pendant au moins dix minutes.

## Faits etablis sur les cameras

- Alexis fixe une limite ferme de **six cameras maximum par mission**.
- Une section 4.09m `[StaticCamera]` stocke seulement `x y hauteur`. Elle ne
  stocke ni nom, ni azimut, ni inclinaison permettant une visee automatique.
- Dans les reglages actifs, `Ctrl+F2=NextViewEnemy` et
  `Shift+F2=NextView`.
- `Ctrl+F2` parcourt la liste complete des vues ennemies, dont les acteurs
  ennemis et les cameras statiques neutres ou ennemies. Il ne constitue pas un
  acces direct a une camera precise.
- Le nombre d'appuis necessaire n'est pas garanti par l'ordre des lignes du
  fichier mission. La consigne precedente « un appui = camera 20 km » est
  invalide et ne doit plus etre donnee.
- La vue doit etre identifiee visuellement puis orientee a la souris. Une prise
  de mesure ne doit plus changer de vue apres le cadrage.
- `Ctrl+R` demarre et arrete une piste NTRK. L'apparition du message HUD et la
  creation du fichier doivent etre confirmees avant de considerer la piste
  enregistree.

Les quatre missions nucleaires de calibration creees pour ces essais ont ete
supprimees du depot et de la copie de test a la demande d'Alexis. Leurs
resultats, captures et manifestes historiques restent des preuves, mais il
n'existe plus de mission nucleaire active a lancer.

## Dernier essai du 4 septembre au soir

Capture :
`WIP/captures/startup/20260904-192415Z-profile9-warm-windowed1024-startup`.

- jeu lance en profil 9, mission Little Boy chargee et jouee ;
- aucune bombe larguee et aucune explosion observee ;
- aucun plantage ni exception nucleaire ;
- Alexis a volontairement quitte lorsque la consigne de camera s'est revelee
  ambigue ;
- aucune nouvelle piste NTRK n'a ete creee : les pistes les plus recentes
  restent `quick0000.ntrk` et `quick0001.ntrk` du 3 septembre ;
- la capture de ce passage ne constitue donc pas un test nucleaire et ne doit
  pas etre utilisee pour juger le rendu.

## Suite apres le commit

Aucun test nucleaire n'est planifie. La prochaine priorite v1.15 devra etre
choisie hors de ce chantier, parmi la chaine sonore Allison, les nuages, la
validation Zuti/AOC, le chargement des textures ou la consolidation des
resultats OS_Programs. Tout nouveau lancement restera annonce a Alexis avant
l'armement de la capture et avant le demarrage du jeu.

## Ressources ajoutees

Les packs Ultrapack 3.4 Cassie, TFM-412 Level 38, HSFX 7.0.3 et SAS ModAct 6.40
sont presents sous `D:\Projets\GITHUB\#res\IL2 1946\Packs`. Ils ciblent des
bases posterieures a 4.09m et servent uniquement de sources de comparaison ou
de retroportage. Aucun ne doit etre installe directement dans la v1.15.

## Discipline de reprise

- ne jamais modifier l'original protege ou la bibliotheque `#res` ;
- ne jamais lancer le jeu sans prevenir Alexis ;
- ne jamais supposer qu'une touche ou une camera fonctionne parce qu'un forum
  le dit : verifier d'abord les raccourcis actifs et une mission minimale ;
- distinguer les faits constates, les validations hors jeu et les hypotheses ;
- ne pas supprimer une ressource ou une capture unique sans inventaire et
  accord ;
- ne pas declarer la v1.15 prete tant que tous les blocages de sortie retenus
  ne sont pas testes sur la cible x86.
