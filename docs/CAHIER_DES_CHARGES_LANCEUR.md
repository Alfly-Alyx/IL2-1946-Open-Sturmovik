# Cahier des charges du lanceur Open Sturmovik

Ce document conserve les exigences du futur lanceur. Sa realisation commencera
apres stabilisation du chargement du jeu et des profils 4.08m/4.09m.

## Demarrage normal

- Le raccourci Bureau **Open Sturmovik** lance directement le jeu.
- Aucune fenetre de configuration n'est affichee lors d'un demarrage normal.
- Le dernier profil entierement valide est reutilise.
- Lors de la premiere utilisation, le profil par defaut est **Open Sturmovik
  4.09m complet**, avec tous les mods communautaires retenus et compatibles.
- Si la transaction precedente est incomplete ou si un fichier critique a
  change, le jeu n'est pas lance silencieusement : le lanceur de configuration
  s'ouvre avec un diagnostic comprehensible.

## Configuration a la demande

Un second raccourci Bureau, **Open Sturmovik - Configuration**, ouvre le lanceur
et donne acces aux choix suivants :

- version stock ou modifiee ;
- 4.08m, 4.09b historique ou 4.09m ;
- profil sans 6DOF ou avec 6DOF lorsqu'une difference fonctionnelle aura ete
  restauree et validee ;
- activation et reglage du suivi de tete 6DOF et de TrackIR ;
- resolution, mode fenetre ou plein ecran ;
- profil graphique et wrapper moderne compatible ;
- qualite visuelle commandee par une reglette continue ;
- lancement du client ou du serveur Open Sturmovik ;
- diagnostic, verification et retour transactionnel au dernier etat valide.

Les reglages choisis sont enregistres hors des fichiers proprietaires du jeu.
Fermer le lanceur sans appliquer ne modifie rien.

### Reglette de qualite visuelle

Le lanceur presente une reglette deplacable plutot qu'une simple liste de deux
profils. Ses deux bornes fonctionnelles sont :

- **Haute qualite securisee x86** : profil utilise pendant la stabilisation,
  avec textures S3TC, effets moderes et eau generique afin de conserver une
  marge dans l'espace d'adressage 32 bits ;
- **Qualite maximale** : reprend l'intention du `conf.ini` historique, avec
  textures non compressees, filtrage anisotrope, effets ameliores et details
  supplementaires, lorsque la memoire et le backend graphique ont ete valides.

Les positions intermediaires correspondent a des ensembles de valeurs connus et
testes, pas a des nombres arbitraires. Le deplacement de la reglette affiche
l'estimation de memoire et les fonctions qui changent. Si le GPU, le wrapper ou
le budget memoire ne permettent pas le niveau demande, le lanceur explique la
limite et propose la position sure la plus proche. Pendant les essais 1.15, la
position par defaut et la limite appliquee sont **Haute qualite securisee x86**.

### Vue, 6DOF et TrackIR

Un volet dedie permet de regler le suivi de tete sans modifier les autres
commandes du joueur :

- activer ou desactiver le 6DOF ;
- activer ou desactiver TrackIR lorsqu'un peripherique et son pilote sont
  detectes ;
- regler separement les translations, rotations, sensibilites, zones mortes,
  lissage et recentrage ;
- tester les mouvements avant d'appliquer le profil ;
- conserver des profils distincts par peripherique et par joueur.

Le lanceur ne presente le 6DOF comme fonctionnel que si l'executable et les
classes necessaires correspondent au manifeste actif. Des lignes `6dof_*` ou
`NewTrackIR` presentes dans `conf.ini` ne suffisent pas a prouver que la fonction
est chargee. Le mode sans 6DOF devra utiliser un executable reellement distinct,
et non une copie du meme binaire.

### Serveur Open Sturmovik

Le lanceur permet de choisir **Client** ou **Serveur Open Sturmovik**. Le mode
serveur utilise un manifeste dedie mais la meme version de donnees, d'appareils,
de modeles de vol et de mods que les clients autorises a le rejoindre.

L'interface serveur donnera acces au nom et a la description du serveur, aux
ports, au nombre de joueurs, au mot de passe, a la difficulte, a la mission ou a
la rotation de missions, aux journaux et aux commandes demarrer/arreter. Les
secrets ne seront pas inscrits dans les journaux ni dans les fichiers suivis par
Git.

Le serveur possede sa propre configuration generee et sauvegardee ; il ne
reutilise pas aveuglement le `conf.ini` du client. Les reglages graphiques,
TrackIR et 6DOF y sont sans objet. Avant implementation, il faut encore
identifier et valider le runtime serveur 4.09m ainsi que ses fichiers SFS :
aucun executable serveur dedie n'est actuellement present a la racine de
l'add-on.

## Raccourcis et installation

- Les raccourcis sont crees par l'installateur Open Sturmovik, pas par une copie
  manuelle silencieuse.
- Leur cible ne depend pas d'un chemin absolu propre au poste de developpement.
- Le raccourci principal utilise un mode direct sans interface.
- Le raccourci de configuration utilise un argument explicite ouvrant
  l'interface.
- Desinstaller le lanceur retire uniquement ses propres raccourcis et reglages.

## Profils et compatibilite

Le lanceur ne doit pas empiler arbitrairement des mods. Chaque profil correspond
a un manifeste connu comprenant SFS, DLL, EXE, wrapper, registres et contenus
libres. Le profil complet n'est declare valide que si :

1. ses sources sont presentes et leurs empreintes correspondent ;
2. `air.ini`, les modeles de vol et `stationary.ini` sont coherents ;
3. les classes Java chargees sont compatibles avec la JVM active ;
4. les conflits de chemins entre mods ont une priorite documentee ;
5. le jeu atteint le menu principal sans erreur bloquante ;
6. les textures 2K/4K respectent les limites memoire mesurees du moteur.

Les utilitaires historiques non compatibles restent visibles dans la
documentation mais ne sont pas proposes comme options actives.

## Cible de version

La cible finale du lanceur et du paquet principal est exclusivement **Open
Sturmovik 4.09m**. Les profils 4.08m et 4.09b sont conserves pendant la phase de
reconstruction et de validation, ainsi que provisoirement pour rejoindre des
serveurs communautaires restes sur ces versions. Ils sont identifies comme
profils de compatibilite historiques et ne sont jamais proposes comme choix par
defaut. Ils pourront etre retires du paquet principal lorsque leur maintien ne
sera plus necessaire.

## Musiques nationales et fonds d'ecran

Le lanceur permet d'associer a chaque pays disponible dans IL-2 un ensemble
musical propre. L'association porte sur l'identifiant interne du pays et non
uniquement sur son nom traduit. Elle doit definir au minimum les musiques de
menu et, lorsque le moteur le permet, les phases de decollage, vol et crash.
Une musique generique sert de repli lorsqu'aucun ensemble national valide n'est
installe. Le joueur peut ecouter un extrait, activer ou couper la musique et
regler son volume sans modifier les sons du moteur ou des armes.

Les fonds d'ecran Full HD provenant de captures de la communaute sont geres
comme un ensemble visuel Open Sturmovik. Le lanceur peut proposer un fond fixe,
une rotation ou un choix aleatoire. Chaque image conserve sa resolution, son
auteur, sa source et son autorisation de redistribution lorsqu'ils sont connus.
Le paquet ne publie pas une image communautaire dont la provenance ou le droit
de redistribution reste incertain.
