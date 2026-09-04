# Resultats du test nucleaire du 4 septembre 2026

## Perimetre

Session analysee :
`WIP/captures/startup/20260904-051619Z-profile9-warm-windowed1024-startup`.

- IL-2 1946 4.09m modde, profil 9 et 6DOF historique ;
- rendu OpenGL natif, profil x86 securise, 1024 x 768 fenetre ;
- B-29 Silverplate et Little Boy sur Smolensk, surface terrestre ;
- mission `Nuclear-Little-Boy-Static-Cameras` ;
- nouvelle pile de cinq cameras centrees sur l'impact ;
- capture d'images, compteurs processus et compteurs systeme ;
- pas de Process Monitor, de WPR exploitable ni de piste NTRK neuve.

Le jeu a ete detecte a 05:17:01 UTC. La mission a commence a 05:20:06, la
detonation a eu lieu a 05:21:08 et le jeu a ete ferme volontairement a
05:26:58. La mission a donc conserve l'explosion pendant environ 330 secondes.

## Verdict logique

Le controleur nucleaire est valide jusqu'au jalon de 270 secondes :

- un seul evenement nucleaire a ete cree ;
- aucune seconde detonation et aucun reset logique ;
- aucune exception, `FileNotFoundException`, `No spawner` ou
  `Wrong chief's type` ;
- passage en `early-rise` a 1 s, `mature-rise` a 30 s et `late-rise` a 120 s ;
- couches fixes creees a 30, 90, 150, 210 et 270 s ;
- les trois acteurs transitoires sont detruits a 130 s ;
- zero couche sautee ;
- le jeu est reste repondant pendant tous les 2 426 echantillons entre la
  detonation et 330 s.

Les hauteurs logiques AGL observees sont 603 m a la detonation, 1 714 m a 30 s,
3 766 m a 90 s, 5 590 m a 150 s, 7 186 m a 210 s et 8 554 m a 270 s. Elles
correspondent a la courbe programmee pour Little Boy. La cible de 12 km n'est
pas encore validee en jeu : elle n'est atteinte qu'a 600 secondes simulees. La
mission a ete arretee juste avant la couche suivante de 330 s.

Ce passage ne teste ni la pause/reprise, ni le demi-tour, ni l'eau, ni Fat Man,
ni le nettoyage complet a 3 728 s. Le menu visible a environ 330 s correspond a
la fin volontaire de la mission et ne constitue pas un essai de pause.

## Verdict visuel des cameras

Les cameras sont maintenant bien alignees sur le point d'impact. Le flash, la
boule de feu et le panache sont effectivement captures. La geometrie verticale
n'est toutefois pas exploitable pour mesurer l'explosion :

- la premiere vue est environ 600 m au-dessus de l'airburst de 603 m ;
- a 1 s, le flash blanc remplit l'image ;
- a 5 s, la boule de feu occupe presque tout le cadre ;
- entre 30 et 90 s, la camera est englobee par la fumee ou trop proche de la
  colonne ;
- les vues plus hautes montrent selon leur orientation le sol, une partie du
  panache hors cadre ou l'interieur d'une couche ;
- a 210 s, une vue ne montre que le terrain alors que le journal prouve que
  neuf acteurs sont encore actifs et que la cible logique se trouve a 7 186 m ;
- a 270-300 s, une nouvelle couche redevient visible, parfois en bordure ou en
  remplissant de nouveau le cadre.

Il ne s'agit donc pas d'une disparition ou d'un reset du controleur. Les vues
changent de relation avec un panache qui traverse successivement les altitudes
de la pile. L'outil n'enregistre pas les touches, si bien que la camera exacte
selectionnee a chaque image ne peut pas etre certifiee apres coup.

Images locales de reference :

- `frame-001950.jpg` : flash a environ 1 s ;
- `frame-001987.jpg` : boule de feu a environ 5 s ;
- `frame-002216.jpg` : camera dans le panache a 30 s ;
- `frame-002761.jpg` : panache occupant le cadre a 90 s ;
- `frame-003313.jpg` : colonne visible lateralement a 150 s ;
- `frame-003864.jpg` : terrain seul a 210 s malgre la continuite logique ;
- `frame-004414.jpg` : camera dans une couche a 270 s ;
- `frame-004689.jpg` : couche en bordure du cadre a 300 s.

## Performances et stabilite

Pendant les 330 secondes suivant la detonation :

- charge IL-2 moyenne : environ 0,89 coeur logique ;
- memoire de travail : 653,11 a 659,22 Mio ;
- memoire privee : 670,65 a 676,73 Mio ;
- espace virtuel : 1 962,61 a 1 965,11 Mio ;
- utilisation GPU 3D IL-2 sur Intel UHD 620 : 82,35 % en moyenne et 97,06 % au
  maximum ;
- memoire GPU locale du processus : 162,36 Mio en moyenne, 164,47 Mio au
  maximum ;
- activite disque C: : environ 1,98 % en moyenne ;
- echantillons non repondants en mission : zero.

La croissance d'environ 5,4 Mio de memoire privee entre la detonation et 330 s
est faible et se stabilise. Aucun signe de fuite ou de saturation de l'espace
virtuel x86 n'apparait sur ce passage. La charge GPU elevee a seulement
1024 x 768 confirme en revanche que les effets et le rendu OpenGL natif peuvent
devenir le facteur limitant sur l'Intel UHD 620. Les images de l'enregistreur ne
constituent pas une mesure FPS du jeu.

Les deux intervalles `not responding`, de 78,0 s puis 3,4 s, se situent avant le
debut de la mission : initialisation du jeu puis chargement de Smolensk. Ils ne
sont pas lies a la detonation. Les 150 erreurs `Descripteur non valide` de la
capture d'images sont elles aussi limitees a deux changements de fenetre avant
la mission. Les 5 152 images suivantes, dont toute la detonation, sont valides.

## Anomalies non nucleaires encore visibles

- `samples/music/menu/ab.wav` manque ;
- `music/inflight` est absent, conformement au probleme de musique en vol deja
  repertorie ;
- les deux avis Perfect NVIDIA restent attendus sur l'Intel UHD 620 avec le
  profil OpenGL securise ;
- le son Allison reste un echec autorise uniquement pour ce test nucleaire et
  demeure bloquant pour la sortie globale v1.15.

## Correction de protocole recommandee

Conserver une camera verticale haute pour la vue de rayon. La vue spectaculaire
principale demandee par Alexis est placee a 1 km a l'ouest de l'impact et a
1 200 m d'altitude. Deux vues de mesure distinctes sont placees a 20 km/6 km et
30 km/7 km afin de contenir respectivement le profil de Little Boy et le sommet
de 13,5 km vise pour Fat Man. Les trois usages ne doivent pas etre confondus :
la vue a 1 km sert a juger la boule de feu et l'onde initiale, les vues eloignees
servent aux dimensions, et la vue verticale sert au rayon au sol.

Le prochain essai visuel doit conserver une seule camera pendant toute une
detonation. Changer de camera au milieu du cycle empeche de distinguer le
culling, le franchissement de la camera et la croissance physique du panache.

Manifeste machine :
`manifests/test/nuclear-runtime-20260904-051619Z.json`.

## Deploiement des cameras de profil

Les quatre missions terre/eau Little Boy et Fat Man utilisent maintenant sept
cameras dans un ordre explicite : 1 km, 20 km, 30 km, trois vues rapprochees
en altitude, puis une verticale a 16 km. Les huit fichiers de mission ont ete
copies transactionnellement dans le jeu de test et leurs huit empreintes sont
identiques aux sources du depot.

La sauvegarde precedente et son recu se trouvent sous
`WIP/test-backups/sync-cam-20260904-055053Z`. Le deploiement est consigne dans
`manifests/test/nuclear-profile-cameras-v1.15-deployment.json`. Aucun lancement
du jeu n'a ete effectue pendant cette operation.

## Essai des distances de camera, 4 septembre 2026 apres-midi

La session `20260904-133506Z-profile9-warm-windowed1024-startup` a atteint le
vol et s'est terminee volontairement, sans gel signale. La capture contient les
images, les mesures processus et les compteurs systeme ; Process Monitor avait
ete volontairement desactive pour ne pas recreer plusieurs dizaines de Gio de
traces.

Le retour operateur est sans ambiguite : la reference a 1 km est trop proche
pour suivre le developpement complet du champignon. Elle a donc ete remplacee,
ainsi que les trois vues rapprochees en altitude, par un recul de 5 km. Les
vues de mesure a 20 km et 30 km sont conservees et restent les deux premieres
du cycle `Ctrl+F2`.

La nouvelle disposition a ete synchronisee dans les quatre missions terre/eau.
Les huit fichiers du jeu de test correspondent aux sources et le validateur
hors jeu passe. Voir
`manifests/test/nuclear-5km-close-v1.15-deployment.json`.

## Essai Little Boy depuis la camera a 5 km

La session
`WIP/captures/startup/20260904-135929Z-profile9-warm-windowed1024-startup`
a charge la mission Little Boy a `14:05:09Z`, l'a declaree jouable a
`14:05:27Z` et a enregistre la detonation a `14:06:25Z`. Alexis a quitte la
mission volontairement vers `14:06:35Z`, puis le jeu a ete ferme a
`14:06:41Z`. La fenetre exploitable apres detonation ne couvre donc qu'environ
dix secondes.

La troisieme vue statique, probablement la reference a 5 km et 1 200 m, a bien
ete atteinte. Sa position est correcte, mais son axe de visee ne l'etait pas :
le point d'impact restait hors cadre. Les images `frame-003206.jpg` a
`frame-003208.jpg` montrent seulement une grande bordure lumineuse decoupee a
gauche pendant environ 0,3 s. Ni le centre de la boule de feu, ni l'onde de
choc, ni le panache ne sont mesurables sur cette prise. La distance de 5 km
n'est pas invalidee ; c'est le cadrage qui l'est.

Le journal prouve toutefois que le code nucleaire a poursuivi son cycle : un
seul evenement a ete cree avec une altitude AGL cible de 603 m, puis la phase
`early-rise` a ete atteinte a une seconde avec six acteurs vivants. Aucun
reset, aucune exception et aucun echantillon `not responding` n'apparaissent
entre le debut de la mission et sa fermeture. Autour de l'impact, IL-2 utilise
en moyenne environ 0,95 a 0,97 coeur logique ; la memoire de travail reste
autour de 654,5 Mio, la memoire privee sous 673 Mio et l'espace virtuel autour
de 1 969 Mio. Le moteur GPU 3D Intel reste approximativement entre 48 et 73 %
et la memoire GPU locale autour de 161 Mio. Il n'y a donc aucun cout brutal
mesurable lors de cette detonation hors champ.

La mission IL-2 ne stocke que `x y hauteur` dans `[StaticCamera]`, sans angle de
visee. L'angle depend de l'etat de la vue et doit etre corrige avec la souris.
Le prochain protocole doit donc afficher les icones, selectionner la camera,
puis centrer l'icone du camion cible avant le largage. Il doit aussi demarrer
et arreter un enregistrement NTRK afin de pouvoir rejouer une seule detonation
avec plusieurs cadrages. La communaute confirme que `Shift+F2`/`Ctrl+F2`
parcourent les cameras statiques, y compris pendant la lecture d'une piste :
<https://www.sas1946.com/main/index.php?topic=33600.0>. La reference des
raccourcis 1946 confirme que la souris oriente la vue :
<https://cheatography.com/alejulian/cheat-sheets/il-2-sturmovik-1946/>.

Anomalies non nucleaires encore visibles dans ce lancement :

- `samples/music/menu/ab.wav` manque ;
- `music/inflight` est absent ;
- le pilote DirectX du joystick ne trouve aucun peripherique ;
- les deux avis Perfect restent des avis attendus du profil Intel securise.

## Balisage terrestre de 1 a 5 km

Les missions terrestres Little Boy et Fat Man possedent maintenant cinq
P-51D-5NT allies statiques sur l'axe ouest-est. Ils sont places a 1, 2, 3, 4
et 5 km avant le camion cible, avec un cap de 90 degres : chaque nez pointe
donc vers l'impact. Cette ligne sert a la fois de repere de visee pour la camera
et de temoins physiques pour observer le rayon de destruction.

Les avions sont des objets `vehicles.planes.Plane$P_51D5NT`, enregistres dans
le `stationary.ini` du jeu de test. Ils ne se deplacent pas et ne modifient pas
la trajectoire du B-29. Leur destruction eventuelle fait partie de la mesure et
devra etre relevee distance par distance. Les missions maritimes n'ont pas recu
ces avions terrestres ; leur balisage sera realise avec des objets navals.

Les quatre fichiers terrestres ont ete sauvegardes puis deployes dans le jeu de
test. Les quatre empreintes source/destination sont identiques. Voir
`manifests/test/nuclear-range-markers-v1.15-deployment.json`.
