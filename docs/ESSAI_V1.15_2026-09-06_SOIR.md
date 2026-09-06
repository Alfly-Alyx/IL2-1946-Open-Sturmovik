# Essai v1.15 du 6 septembre 2026 au soir

Session : `20260906-175627Z-profile8-warm-configured-display-startup` sous
`WIP/captures/startup`. Jeu PID 22256, lance a 17:57:42 UTC (19:57:42 locale).
Profil 8, IL-2 4.09m modifie sans 6DOF, configuration DirectX preparee.
Ne pas modifier les fichiers actifs pendant cet essai.

## Observations acquises

- **Titre confirme visuellement** : `Open Sturmovik` dans la barre de fenetre,
  capture `screen/frames/frame-001520.jpg`. Cela ne qualifie pas les profils
  Original ni le nom affiche dans le Gestionnaire des taches.
  Alexis confirme ensuite explicitement le bon nom de la fenetre.
- **KB-29P fonctionnel selon Alexis** (message « KP29 fonctionne »).
  Le retour valide le fonctionnement observe pendant cette session ; il ne
  constitue pas a lui seul une validation detaillee du ravitaillement en vol.
- **Retour Alexis : armement CW-21 incomplet**. Il ne voit que le choix
  `4 x .303`. L'alternative `2 x .303 + 2 x .50` n'est donc pas validee.
  La classe presente dans la copie et celle du depot ont la meme empreinte
  `8B97C4067A78619DD19023806AF8A6CE7F736CBE3ED756922DE6071688F4FF2B`.
  Les trois libelles d'armement sont presents dans la copie. Cela prouve la
  copie des fichiers, pas l'enregistrement effectif de la variante en memoire.
- **Retour Alexis : son moteur CW-21 faible**, audible et fonctionnel, mais
  plus faible que les autres sons. Ne pas confondre ce desequilibre de volume
  avec la boucle de ralenti signalee lors de la session precedente. Aucun
  reglage de gain n'est change pendant le vol.
- **Nuages valides par Alexis** : « fonctionne et MAGNIFIQUE ». Le journal
  final confirme `provider: dx8wrap.dll`, `renderer: DirectX8.` ; Slovakia puis
  Smolensk ont ete charges et aucune `unknown exception in clouds` n'est
  presente. Ce retour qualifie les scenes de cet essai et le rendu apprecie,
  pas toutes les cartes/meteo ni une comparaison mesuree avec le stock.
- **Nouveau pilote par defaut choisi par Alexis** : Jack "Hawk" Miller.
  La copie de test a ete renommee apres son accord, avec sauvegarde du registre.
  **Contrainte confirmee ensuite** : aucun profil joueur existant ne doit etre
  renomme par la mise a jour, meme s'il porte encore le nom d'origine russe ou
  anglais. Le script de migration a donc ete retire. Le changement du defaut
  interne reste a finaliser ; voir `docs/DEFAULT_PILOT_V1.15.md`.

## Couverture et limites des diagnostics

- Capture d'images a 5 images/s, mesures processus a 100 ms, inventaire des
  modules, compteurs systeme et ProcDump sur exception non geree actifs.
- La capture d'images existante copie le rectangle de la fenetre a l'ecran :
  une autre fenetre superposee peut donc apparaitre. Ce n'est pas une preuve
  de visibilite continue du jeu lorsqu'il est masque. Aucun micro enregistre.
- Process Monitor a ete arme a 17:56:43 UTC puis a atteint sa limite a
  17:57:48 UTC (1,5 Gio constates pour un seuil de 1 Gio). Il a ete arrete a
  17:57:56 UTC. La trace initiale ne couvre donc pas tout le vol : un filtre
  IL-2 avec rejet des evenements hors cible est necessaire avant une nouvelle
  capture de fichiers durable. Ne pas presenter cette trace comme complete.
- WPR a refuse le profil GeneralProfile avec `0xc5585011`. Aucune politique
  Windows n'a ete modifiee ; les compteurs processus/systeme restent le repli.
- Le journal `log.lst` peut rester vide pendant que le jeu le garde ouvert ;
  ne pas deduire de cette absence de lignes qu'il n'existe aucune erreur.
- L'inventaire AOC de test demeure distinct des 266 profils distribues. Son
  exception explicite est inscrite dans le rapport de preparation de session.

Les traces permettent de reproduire les constats. Le simple demarrage ne
valide ni les nuages, ni les deux armements, ni les sons de tous les avions.

## Fin de session

Le processus jeu a quitte a 18:06:14 UTC. L'enregistreur d'images, les compteurs
et ProcDump se sont termines ; aucun de ces processus ne reste actif. Les
fichiers de diagnostic sont conserves. La capture de fichiers tronquee n'a pas
ete reprise avant la fermeture du jeu ; ce point reste a corriger pour le
prochain lancement instrumente.

Le journal comporte encore des messages `HierMesh: Can't find chunk` pour
`zOilFlap1`, `zOilFlap2`, `zCompressor1`, `zCompressor2` lors du passage avec
cockpit B-29 a 18:04:36 UTC, et des rechargements de textures. Ils sont a
examiner separement : le retour KB-29P fonctionnel n'est pas une absence totale
de messages techniques. Les avertissements Perfect ne qualifient pas non plus
une panne de rendu, cette session utilisant DirectX/Excellent.
