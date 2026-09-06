# Campagne finale Open Sturmovik v1.15

Derniere mise a jour : 6 septembre 2026.

Cette campagne couvre exactement les dix points v1.15 de `IL2.txt`. Alexis a
deja effectue des vols et confirme que la simulation continue a la perte de
focus. Quatre anomalies restent a recontroler apres correction ; elles ne sont
pas declarees resolues par les seuls audits hors jeu. Ne pas lancer le jeu sans
Alexis et ne pas lui faire recommencer les essais acquis sans regression.

## Prochaine session demandee apres le push v1.15

Ordre convenu avec Alexis, sans lancement automatique :

1. **CW-21 :** profil 8, ouvrir la liste de l'editeur de missions rapides
   (pas `Mission simple`). Choisir `4 x .303`, charger, entrer au cockpit et
   tirer ; revenir au menu, choisir `2 x .303 + 2 x .50` et recommencer.
   Verifier que le choix persiste et que les deux chargements fonctionnent.
   Conserver la nouvelle trace `[OS CW-21]` du preset moteur pour poursuivre
   le diagnostic du volume trop faible, encore non corrige.
2. **Liste d'avions :** verifier Allies / Axe / as ; noms Constructeur Modele
   Variante et, pour les as, prenom nom modele. Controler notamment Hurricane
   par variantes, Sea Hurricane, Typhoon, Tempest puis Sea Fury, ainsi que
   Spitfire puis Seafire. Les comptes hors jeu restent 535 / 516 / 535.
3. **Switcher :** fermer completement le jeu avant chaque changement. Dans
   la copie de test seulement, exercer 4.08m, 4.09b et 4.09m, profils Original,
   modifies sans 6DOF et avec 6DOF. Verifier la version au menu, les noms
   d'origine ou Open Sturmovik selon le profil, les listes compatibles et le
   retour au profil 8. Ne pas changer de version sur une session ouverte.
   Les controles hors jeu couvrent deja neuf profils et deux HUD ; la GUI et
   les lancements reels restent a valider.

Discuter de la release apres ces trois validations. Aucun succes hors jeu
ne remplace ces retours utilisateur ; les points ouverts de la campagne
complete ci-dessous restent visibles.

Derniere synchronisation : `manifests/test/aircraft-family-evolution-v1.15.json`,
sauvegarde `WIP/test-installations/sync-20260906-221033`. Le dossier AOC de test
contient desormais cinq profils, contre 266 dans le paquet ; cette difference
reste l'unique FAIL de contenu accepte pour les essais cibles, pas pour la
qualification de distribution.

## Historique : reprise des quatre anomalies du 6 septembre

**Retour de la session du soir :** KB-29P fonctionnel et titre de fenetre
`Open Sturmovik` confirmes par Alexis. CW-21 : seul l'armement 4 x .303 est
visible et son moteur est audible mais trop faible par rapport aux autres sons.
Nuages : fonctionnement et qualite visuelle valides par Alexis en DirectX,
avec Slovakia puis Smolensk charges et aucune exception de nuages dans le log.
Ces resultats priment sur les attentes ci-dessous. Voir
`ESSAI_V1.15_2026-09-06_SOIR.md` pour les traces et leurs limites.

Copie a utiliser :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test`.
Profil 8, 4.09m modifie sans 6DOF. Aucun changement de version pendant cette
passe. Les correctifs ont ete synchronises avec sauvegarde avant le lancement
instrumente autorise par Alexis.

1. **Titre.** Au menu, lire la barre de titre : `Open Sturmovik` est attendu.
   Verifier aussi le volet Processus du Gestionnaire des taches. Le nom du
   fichier `il2fb.exe` dans Details peut rester identique. La verification des
   profils Original se fera plus tard, jeu ferme entre chaque changement.
2. **Avions.** Dans la liste d'avions de l'editeur utilise par Alexis, chercher
   `Curtiss-Wright CW-21` et `Boeing KB-29P Ravitailleur`. L'ecran `Mission
   simple`, qui liste des fichiers de mission, n'est pas cette liste d'avions.
   Charger le CW-21, entrer dans son cockpit et tirer une courte rafale avec
   `4 x .303`, puis recharger avec `2 x .303 + 2 x .50` et refaire la rafale.
   Verifier instruments, train, verriere et vue externe. Charger ensuite le
   KB-29P comme appareil joueur : cockpit pilote B-29, quatre moteurs et retour
   au menu sans erreur. Son ravitaillement reste un essai fonctionnel distinct.
3. **Nuages.** Reprendre la mission et la meteo qui montraient les pics blancs,
   avec les memes altitude et point de vue. DirectX est prepare avec WxTech et
   `TypeClouds=1` ; noter pics, transparences, detail, profondeur et fluidite.
   La comparaison OpenGL utilisera exactement la meme scene, seulement apres
   fermeture du jeu. DirectX est un candidat de contournement Intel, pas encore
   le choix definitif. Ne pas accepter une baisse de detail comme resolution.
4. **Son.** Reprendre le P-39N comme temoin Allison, puis un Bf-109 a moteur
   DB-600 pour les presets de demarrage corriges. Demarrer, attendre la fin du
   son de lancement, monter progressivement les gaz et regarder le compte-tours.
   Ecouter au cockpit et en vue externe, reduire, arreter puis redemarrer.
   Faire aussi un depart deja en vol. Noter si le ralenti persiste, sur quel
   avion et a quel regime : plein gaz ne signifie pas toujours plein regime.

Apres chaque probleme, garder le nom de l'avion, la mission, les conditions et
l'heure approximative pour retrouver le passage du journal. Les anciens vols
ne valident pas ces nouveaux fichiers. Conserver les nouvelles traces utiles ;
ne pas effacer les preuves d'une anomalie sous pretexte que le candidat echoue.

### Limite de cette copie : AOC

Le dossier de test `_Game_Enhancements/Mod_AOC_Public` ne contient au moment de
la preparation que `Defaut.txt` et `P-51D-20_AOC_1a.txt`, identiques octet pour
octet. Les trois classes AOC+Zuti correspondent au manifeste. Cet etat existant
est preserve : les quatre correctifs ne restaurent ni ne suppriment de profils.
Le depot distribue, lui, 266 profils. Le controle strict du contenu de test
conserve donc un **FAIL AOC d'inventaire**, accepte explicitement uniquement
pour cette synchronisation ciblee. Ce n'est pas une qualification du paquet AOC
complet. Avant la campagne finale de distribution, clarifier/restaurer l'etat
des profils avec Alexis. Les nouveaux profils peuvent etre crees par les vols.

### Trace de la preparation ciblee

- plan : `WIP/test-plans/runtimefix-20260906.json`, 183 copies et un retrait ;
- sauvegarde : `WIP/test-installations/sync-20260906-193015` ; l'ancien doublon
  `Files/com/maddox/il2/objects/air/KB_29P.class` y reste recuperable ;
- contenu de test : **24 PASS, 1 WARN (pas de nouveau dump), 1 FAIL AOC** ;
- disponibilite de la reprise ciblee : **42/42 controles**, `Ready=True` avec
  cette seule exception AOC explicite ; rapport
  `build/runtimefix-test-readiness-20260906.json`. Ce controle conserve la
  resolution de fenetre actuelle ; il ne force pas un passage en 1024 x 768 ;
- contenu du depot : **28 PASS, 0 WARN, 0 FAIL** avec le dump de laboratoire
  existant, qui ne prouve pas le chargement des nouveaux fichiers en session ;
- DirectX prepare par `tools/Set-OpenSturmovikGraphicsBackend.ps1` ; sauvegarde
  dans la copie : `conf.before-DirectX-39c6375b6e3948d4b1a57c837d4d5c8a.ini`.

Le diagnostic graphique retourne `configuration-not-yet-tested` : le dernier
journal concerne encore OpenGL, tandis que la configuration preparee est
DirectX. Ce resultat est attendu avant le prochain vol et ne vaut pas succes.

Details et sources : `CW21_COCKPIT_ARMAMENT_V1.15.md`,
`BRANDING_EXECUTABLES_V1.15.md`, `SUIVI_ANOMALIE_NUAGES_V1.15.md` et
`SUIVI_ANOMALIE_SONS_V1.15.md`.

## Preparation initiale (historique, avant les vols et les quatre correctifs)

1. `tools/Test-V115OfflineReadiness.ps1` : **6 PASS, 0 WARN, 0 FAIL** ;
2. contenu v1.15 avec exclusion explicite du nucleaire : **24 PASS, 1 WARN,
   0 FAIL** ; le seul avertissement demande un dump runtime ;
3. AOC **V1/1a HSFX 4.0** selectionne sans ambiguite dans
   `manifests/aoc-v1.15.json`, avec trois classes AOC+Zuti et 266 profils
   distribues ; `Defaut.txt` est present et le profil specifique du Bf-109G-6
   Early est absent avant lancement ;
4. huit ressources WxTech et retraits des anciennes ressources nuages verifies ;
5. plan complet applique : `WIP/test-plans/v1.15-clean-pretest-20260906.json`,
   puis correctifs du switcher et du nom `_Documentations` :
   `WIP/test-plans/v1.15-switcher-fix-20260906.json` et
   `WIP/test-plans/v1.15-documentations-name-20260906.json` ;
6. sauvegarde de cette preparation initiale :
   `WIP/test-installations/sync-20260906-131433` ;
7. disponibilite au lancement : **47/47**, `Ready=True` ;
8. dix raccourcis verifies dans
   `WIP/test-desktop/v1.15-clean-pretest-20260906`, sans
   modification du vrai Bureau.
9. transactions du switcher exercees hors jeu sur 4.08m Original, 4.08m
   Open Sturmovik sans 6DOF, puis retour au profil 8 4.09m : empreintes exactes,
   HUD standard/immersion exacts et aucune transaction abandonnee.

Si le depot change avant l'essai, regenerer un plan et resynchroniser
transactionnellement, jeu ferme. Sinon, ne pas rejouer inutilement la
synchronisation deja validee.

## Parcours runtime unique

| No | Point de `IL2.txt` | Controle de sortie |
| ---: | --- | --- |
| 1 | KB-29P et CW-21 dans la liste d'avions de l'editeur | Les deux appareils sont selectionnables et pilotables. Cockpit B-29 pilote uniquement pour le KB-29P, quatre moteurs, instruments et ravitaillement ; B-29 standard toujours chargeable. Cockpit CW-21, deux armements au choix, placement, sauvegarde et rechargement sans erreur. |
| 2 | Polygones blancs et erreurs de nuages | Avec `TypeClouds=1`, parcourir Slovakia et Smolensk sous la meteo fautive. Aucun triangle blanc, nuage au sol anormal ni `unknown exception in clouds`. Le rendu WxTech doit etre plus detaille, profond et realiste que le temoin stock 4.09m, avec des performances acceptables. `TypeClouds=0` ne sert que de temoin. |
| 3 | Sons Allison des P-39 | Sur un P-39, verifier demarrage froid, ralenti cockpit/exterieur, montee en regime, vol stabilise, reduction et arret. `Allison_1001.wav` et `xallison_1001.wav` restent distincts et audibles ; aucun silence, mauvais moteur ou preset absent dans le journal. |
| 4 | Zuti pendant dix minutes, MDS et fermeture | Jouer au moins dix minutes une mission MDS couvrant radar, limites d'appareils, rearmement/reparation/ravitaillement et porte-avions ; quitter la mission puis le jeu. Aucun conflit de classe, minuteur orphelin ou erreur de fermeture. Si possible, repeter avec un hote et un client issus de la meme copie. |
| 5 | AOC V1/1a | Avant lancement, verifier que `Bf-109G-6Early_AOC_1a.txt` est absent et que `Defaut.txt` est present. Charger une premiere fois le Bf-109G-6 Early : le chargeur doit creer le fichier specifique comme copie exacte de `Defaut.txt`, puis terminer cette premiere construction sans appliquer le profil. Quitter la mission, verifier l'identite des deux fichiers, puis recharger la meme mission : le profil genere doit cette fois etre lu. Tester demarrage a froid, chauffe/huile, G negatifs, carburant et magnetos, puis un cycle Zuti R/R/R. Apres la campagne, supprimer le fichier Bf genere afin de retrouver l'etat distribue a 266 profils. |
| 6 | Perte de focus sans pause | Simulation continue en mode fenetre : confirme par Alexis. Conserver cet acquis et `DrawIfNotFocused=1` ; ne refaire le test qu'en cas de regression ou pour qualifier un mode non encore essaye. |
| 7 | Profils avec/sans 6DOF, TrackIR et marquage | Activer le profil 8 sans 6DOF puis le profil 9 avec 6DOF. Verifier les six axes, le recentrage, l'absence de translation dans le profil 8 et la reprise apres perte de focus. En mode fenetre, les profils modifies doivent afficher `Open Sturmovik` dans leur barre de titre et dans le volet Processus du Gestionnaire des taches ; le volet Details peut conserver `il2fb.exe`. Activer ensuite le profil 7 Original et verifier son titre et ses metadonnees d'origine, puis revenir au profil 8 et confirmer la restauration de son EXE. |
| 8 | DCG, Mission Mate, WeatherSet et FOV Changer | Depuis le Bureau temporaire, ouvrir chaque raccourci, creer ou modifier une donnee jetable, la relire puis fermer sans toucher a l'installation de reference. Pour le FOV Changer, confirmer `SaveAspect=0`, DeviceLink sur 1711 et le changement/recentrage de FOV. |
| 9 | ZipNav, IL2 Compare, HardBall408, Bombsight Table 2 et JoyCtrl | Ouvrir chaque raccourci. Verifier cartes/echelle/navigation ZipNav, comparaison de deux donnees connues, calcul HardBall, fenetre visible de Bombsight Table et JoyCtrl sur une copie de `conf.ini` jeu ferme avec restauration exacte. Aucun runtime ancien n'est installe globalement. |
| 10 | Non-regression finale | Mission rapide, FMB, mission solo, campagne, MDS hote/client, son, commandes, joystick, souris et fermeture. Zero plantage, erreur Java bloquante, ressource manquante ou modification hors cible. |

## Suite de la campagne complete, apres la reprise ciblee

1. verifier qu'IL-2 est ferme et conserver les rapports/empreintes frais ;
2. qualifier l'inventaire AOC du paquet complet avant de conclure sur la
   distribution ; un `Ready=True` avec exception AOC n'y suffit pas ;
3. tester les dix raccourcis depuis le Bureau temporaire s'ils ne sont pas
   deja valides ;
4. terminer les points 1 a 9 encore ouverts, sans modifier les fichiers actifs
   pendant la session ;
5. apres chaque passe AOC temoin, restaurer le profil specifique et verifier son
   empreinte avant de poursuivre ;
6. apres une correction, fermer le jeu, synchroniser les seuls changements
   necessaires et rejouer les controles affectes ; conserver les traces utiles
   et les resultats des essais non affectes ;
7. executer le point 10 uniquement lorsque les neuf premiers sont verts ;
8. tester enfin l'installateur de mise a jour avec le vrai Bureau : il doit creer
   exactement dix raccourcis ;
9. conserver le rapport final, les journaux, les captures utiles et les
   empreintes, en distinguant clairement les candidats et le resultat final.

Les chantiers v1.20, notamment les bombes nucleaires, nouveaux wrappers et
chargement progressif des textures, sont exclus de cette campagne.
