# Test cible appareils et nucleaire — 3 septembre 2026

## Session 12 h 44 UTC — validation du candidat hauteur/reprise

La capture
`WIP/tests/captures/startup/20260903-124421Z-profile9-warm-windowed1024-startup`
est complete : 1 044,7 secondes, 9 041 images et 7 911 echantillons
processus. Le jeu a atteint le menu, execute quatre missions puis s'est ferme
normalement. Aucun dump, evenement Windows, gel permanent ou exception Java
nucleaire n'a ete produit.

### B-29 Silverplate

Le cockpit F1 dedie est visible et ses instruments sont rendus. Les erreurs
`zOilFlap1/2` et `zCompressor1/2` ont disparu du journal. La liaison
`B_29SP -> CockpitB29SP` est donc validee en jeu.

### Essais nucleaires observes

| Evenement | Surface | Duree observee apres detonation | Resultat |
| --- | --- | ---: | --- |
| Little Boy | terre | 66 s | vertical, pas de reset sans pause, encore nettement visible a +50 s |
| Little Boy | terre | 23 s | la pause courte reduit/reinitialise visuellement le nuage, qui recommence a croitre |
| Fat Man | terre | 24 s | vertical et reactif, mais passage trop court pour distinguer sa hauteur finale |
| Little Boy | eau | 18 s | gerbe d'eau sans cratere, gros volume blanc puis nuage brun plus petit |

Fat Man sur l'eau n'a pas ete testee. Aucun de ces passages n'a dure assez
longtemps pour valider la hauteur a dix minutes ou le nettoyage complet.

Le premier Little Boy entre en `mature-rise` a 30 secondes avec six acteurs et
zero reconstruction. L'estimation visuelle d'environ 4 km apres une minute
n'est pas incompatible avec la courbe candidate : la cible de 12 km n'est
atteinte qu'a 600 secondes simulees. Elle devra etre mesuree avec une mission
fixe et le temps accelere plutot qu'estimee depuis une vue externe mobile.

### Pause : echec du correctif actuel

Les images `frame-005711.jpg` a `frame-005717.jpg` sont identiques pendant
environ 0,67 seconde, puis le rendu reprend dans `frame-005718.jpg` avec un
nuage devenu beaucoup plus petit. Aucun message `action=rehydrated` n'apparait
dans le journal : le seuil de 1,5 seconde n'a pas ete franchi. Le menu Echap
visible plus tard correspond a la sortie de mission, pas a cette pause.

Abaisser seulement le seuil ne suffirait pas. L'API Java 4.09m sait creer,
arreter et mettre en pause un `Eff3DActor`, mais n'expose aucune operation pour
placer un fichier `.eff` a un age arbitraire. Recreer le meme effet apres la
pause le ferait donc repartir de zero. La bonne correction doit choisir un
effet de reprise correspondant a la phase et a l'age logiques, sans recreer le
flash ni le front initial.

### Performance et stabilite

| Fenetre | Repondant | Working set max | Prive max | Virtuel max |
| --- | --- | ---: | ---: | ---: |
| Little Boy terre, sans pause | 100 % | 662,7 Mio | 680,7 Mio | 1 976,5 Mio |
| Little Boy terre, pause courte | 100 % | 664,4 Mio | 684,5 Mio | 1 977,8 Mio |
| Fat Man terre | 100 % | 671,0 Mio | 688,6 Mio | 1 975,3 Mio |
| Little Boy eau | 100 % | 594,4 Mio | 610,5 Mio | 1 956,7 Mio |

Le coeur principal consomme environ un coeur logique pendant les passages en
vol. Les 1 291 echantillons `Responding=False` de la session appartiennent aux
chargements initiaux ou de mission ; aucun n'est situe dans les fenetres de
detonation. Deux `Time overflow` ponctuels apparaissent, dont un trois secondes
apres le Little Boy avec pause, sans perte durable de reactivite.

### Duree courte et capacite des emetteurs

La documentation communautaire precise que `nParticles` est le nombre maximal
de particules affichees simultanement, pas un stock consomme definitivement.
`FinishTime` continue donc a commander l'emission et `LiveTime` la vie de
chaque particule. La gerbe d'eau a `FinishTime=2` et `LiveTime=15` : sa duree
totale theorique est d'environ 17 secondes, ce qui correspond directement a la
disparition rapide observee. La boule de feu et le front visible sont eux aussi
volontairement bornes a environ 10 et 17 secondes.

La capacite reste cependant critique pour la forme du nuage. A 1 024
particules/s, une limite simultanee de 256 ne couvre que 0,25 s d'emission ; a
100/s, 512 particules n'en couvrent que 5,12 s. Le moteur doit donc remplacer
ou limiter des particules bien avant leur `LiveTime` nominal. Le comportement
natif exact doit etre mesure par un A/B minimal, mais ces ratios expliquent
pourquoi augmenter seulement `FinishTime` ne garantit ni densite, ni continuite
visuelle.

La reprise apres pause exige toujours des effets propres a chaque phase et a
l'age logique. Avant de decouper les emissions persistantes, un essai A/B doit
determiner si le moteur recycle, ecrase ou bride les particules lorsque la
capacite simultanee est atteinte. Les nombres d'acteurs, la memoire et le
nettoyage seront ensuite controles sur la mission de seize B-29.

## Nouveau candidat pret pour le prochain essai

Le correctif prepare apres ce retest est maintenant construit, controle et
synchronise dans le dossier de test, sans lancement du jeu. Il remplace le
surveillant natif inefficace a 25 ms par un battement d'une seconde de temps de
simulation. Le temps reel n'est echantillonne qu'a chaque battement pour
detecter une interruption du rendu. Apres une reprise, seuls la tete, le tore et
la colonne persistants sont recrees a la phase logique courante ; le flash, la
boule de feu et l'onde initiale ne sont jamais rejoues.

La position du coeur du panache est maintenant pilotee explicitement par une
courbe quadratique continue, relative au terrain local. Elle atteint a dix
minutes simulees environ 12 000 m AGL pour Little Boy et 13 500 m AGL pour Fat
Man. Les acteurs transitoires et persistants ont chacun une destruction
programmee, et aucun etat ne doit rester actif apres 3 728 secondes.

Les validations hors jeu obtiennent 18 PASS sur 18 pour le cycle de vie et
41 PASS sur 41 pour l'audit nucleaire statique. Deux constructions propres
produisent les memes treize classes Java major 47 et le souffle ainsi que les
degats conservent leurs quatre empreintes precedentes. Le modele physique du
souffle n'a donc volontairement pas ete modifie dans ce lot visuel.

La classe du B-29 Silverplate est egalement corrigee pour utiliser
`CockpitB29SP` au poste pilote. Son maillage dedie contient bien
`zOilFlap1/2` et `zCompressor1/2`, absents du cockpit standard qui provoquait
les douze avertissements observes. Le controle global obtient 19 PASS,
3 avertissements connus et zero echec. La copie de test est sauvegardee dans
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260903-143540`
et les 47 controles de preparation retournent `Ready=True`.

La validation restante est exclusivement en jeu : cockpit Silverplate, Little
Boy et Fat Man sur terre avec puis sans pause/demi-tour, avant les essais sur
l'eau, en temps accelere, en mission dense et enfin en reseau.

## Retest corrige de 13 h 32 UTC

La capture
`WIP/tests/captures/startup/20260903-113213Z-profile9-warm-windowed1024-startup`
a dure environ 850 secondes et contient 7 386 images ainsi que 6 440
echantillons processus. Elle couvre le Su-2 restaure et deux detonations de
Little Boy. Fat Man n'a pas ete essayee pendant cette session.

### Su-2 valide

Le Su-2 est maintenant pilotable. La vue F1, les commandes et les postes ont
ete valides en jeu apres restauration du `TGunnerSU2.him` AAA authentique et de
sa texture. Le journal ne contient plus aucune erreur `TGunnerSU2`,
`CockpitSU_2` ou `RuntimeException` pendant ce passage.

### Little Boy sans pause

Le premier evenement est cree a `11:40:36`, passe en `early-rise` a 1 000 ms
et en `mature-rise` a 30 000 ms. L'explosion reste verticale et continue :
aucun reset n'apparait a 30 secondes. Le jeu reste repondant dans toute la
fenetre de mesure.

Les images montrent un ecran blanc sur au moins 1,52 seconde, avec environ
95 % des pixels presque blancs au maximum. Cette mesure est une duree de rendu
plein ecran, pas encore une validation physique du flash. Le volume blanc
devient tres grand en quelques secondes et rejoint visuellement le B-29 place
a 5 000 m. La vue externe ne permet cependant pas de transformer cette
observation en altitude mesuree.

### Little Boy avec pause et demi-tour

Le second evenement est cree a `11:44:26`. Il atteint `mature-rise` a
30 000 ms puis `late-rise` a exactement 120 000 ms. Il s'ecoule environ
119 secondes reelles entre ces deux transitions au lieu de 90 : les quelque
29 secondes supplementaires correspondent a la pause. L'horloge de simulation
et l'age logique de l'explosion sont donc correctement geles.

Le meme etat conserve six acteurs du debut a la fin (`created=6`,
`destroyed=0`). La pause ne detruit ni ne recree ces acteurs. Pourtant, le
champignon disparait visuellement a la reprise, revient progressivement, puis
reprend une montee lente. Cela demontre que le moteur natif vide ou invalide le
contenu visible de ses systemes de particules lors de la pause ; l'emetteur
encore vivant doit ensuite repeupler son tampon. Ce n'est plus un redemarrage
de la detonation logique.

Un demi-tour complet de la camera ne fait plus disparaitre le champignon. Le
defaut de culling observe dans l'ancien candidat est donc corrige pour Little
Boy. La pause/reprise reste en revanche un echec visuel bloquant.

### Stabilite et anomalies distinctes

- aucune des deux fenetres nucleaires ne contient d'echantillon
  `responding=False` ;
- pic du premier passage : 693,3 Mio prives, 676,0 Mio de working set et
  1 997,5 Mio virtuels ;
- pic du passage avec pause : 704,3 Mio prives, 684,8 Mio de working set et
  1 996,3 Mio virtuels ;
- un `Time overflow (2280)` apparait quatre secondes apres la seconde
  detonation : il indique un retard ponctuel de simulation, sans gel Windows ;
- douze erreurs de cockpit B-29 demandent les morceaux absents `zOilFlap1`,
  `zOilFlap2`, `zCompressor1` et `zCompressor2`. La classe B-29 Silverplate
  declare actuellement `CockpitB29`, dont le fichier
  `3DO/Cockpit/B-29/CockpitB29.him` ne contient pas ces morceaux. Le depot
  possede pourtant la paire coherente `CockpitB29SP` et
  `3DO/Cockpit/B-29-SP/CockpitB29SP.him`, qui les contient tous les quatre.
  Cette liaison de cockpit est donc le candidat de correction, independant du
  cycle nucleaire ;
- `warning: no files : music/inflight` est reproduit a chaque entree en
  mission et confirme l'absence de musique en vol deja signalee ;
- aucun evenement d'erreur Windows et aucune exception Java nucleaire ne sont
  enregistres.

Sept echantillons de metriques manquent vers la fin parce qu'une lecture
d'analyse a verrouille temporairement le CSV encore actif. Cette lacune vient
de l'outil de capture, pas du jeu ; les prochaines analyses ne liront ce fichier
qu'apres sa fermeture.

### Conclusion technique du retest

Le socle logique persistant, l'horloge de simulation, l'orientation et la
resistance au demi-tour sont valides pour Little Boy. Le correctif restant ne
doit donc pas toucher au souffle, aux degats ni au delai `distance / 343`.

Le rendu n'est toutefois pas encore un vrai rendu par phases : les frontieres
1/30/120 s ne font que journaliser l'etat et les six emetteurs Silverplate
restent actifs pendant 600 secondes. La cible de 12 km n'est utilisee qu'a
600 secondes pour ancrer l'effet stabilise ; elle ne contraint pas la
trajectoire du panache initial. Il faut maintenant separer le coeur persistant
du champignon des particules decoratives, reconstruire seulement la phase
courante apres reprise et piloter explicitement une courbe hauteur/diametre en
fonction de l'age de simulation. Le flash, la boule de feu et l'onde initiale
ne devront jamais etre rejoues lors de cette reconstruction.

## Capture de reference

- Dossier : `WIP/tests/captures/startup/20260903-045354Z-profile9-warm-windowed1024-startup`
- Profil : 4.09m modde, 6DOF historique, OpenGL natif, 1024x768 fenetre.
- GPU detecte : Intel UHD Graphics 620, OpenGL 4.6.0 (31.0.101.2141).
- Duree mesuree : 1 087,2 s, 7 441 echantillons processus et 9 318 images.
- Pic memoire : 698,7 Mio de working set, 715,4 Mio prives et 2 011,3 Mio virtuels.
- Les trois fenetres de 55 s autour des detonations ne contiennent aucun echantillon `Responding=False`.

## Appareils restaures

| Appareil | Present dans l'editeur | Joueur | Cockpit F1 | Verdict |
|---|---:|---:|---:|---|
| Grumman TBF-1C | oui | oui | oui | valide |
| Grumman TBM-3 | oui | oui | oui | valide |
| Pokryshkins MiG-3 | oui | oui | oui | valide |

Le payload restaure de 25 fichiers est donc confirme en jeu et pas seulement
par empreinte.

## Su-2

Le Su-2 est present mais reste non pilotable et sans vue cockpit F1. Deux
tentatives produisent la meme exception :

```text
INTERNAL ERROR: Can't open file '3DO/Cockpit/Il-10-TGun/TGunnerSU2.him'
WARNING: object '3DO/Cockpit/Il-10-TGun/TGunnerSU2.him' of class 'HIM' not loaded
java.lang.RuntimeException: INTERNAL ERROR: HierMeshObj: Can't load HIM 3DO/Cockpit/Il-10-TGun/TGunnerSU2.him
```

Ce defaut etait independant du registre `air.ini` : la classe se chargeait, mais
son tableau de cockpits exigeait une ressource de poste arriere absente. Apres l'essai,
le paquet AAA historique exact a ete retrouve dans
`AAA_Community_Installer_ver_1_1/MODS/SU_2`. Ses classes correspondent octet pour
octet aux classes Su-2 deja actives. `TGunnerSU2.him` et la texture associee ont
donc ete restaures dans le depot, sans substitution de cockpit. Le retest de
13 h 32 UTC valide maintenant la correction en jeu.

## Little Boy et Fat Man : resultats observes

Trois detonations terrestres ont ete realisees avec le B-29 Silverplate : deux
Little Boy et une Fat Man.

Points positifs :

- aucune `NoClassDefFoundError` ;
- aucun gel permanent ni `AppHang` autour des detonations ;
- jeu reactif jusqu'a la fermeture normale ;
- souffle et degats n'ont pas ete modifies pendant cette correction visuelle.

Defauts visuels communs aux deux bombes :

1. le champignon est couche a 90 degres et rampe sur le terrain ;
2. le nuage monte approximativement de 500 a 1 000 m puis repart visuellement
   de zero ;
3. le defaut apparait sans pause et sans demi-tour.

La capture montre notamment le flash dans `frame-005725.jpg`, puis le long
panache horizontal a la transition de 30 s dans `frame-007493.jpg` et
`frame-008983.jpg`.

## Causes etablies par le journal et le bytecode

Le journal cree deux etats a chaque detonation (`1/2`, `3/4`, puis `5/6`). Le
patch d'airburst appelait directement `bombFatMan_land/water`, puis
`Bomb.doExplosion` rappelait le meme rendu via `Explosions.generate`.

La rotation historique de Silverplate est `yaw=0, pitch=90, roll=0`. Les acteurs
crees par `NuclearBlast` utilisaient une `Loc` sans cette orientation : leur axe
d'emission devenait horizontal.

Enfin, la transition `mature-rise` enregistree exactement a 30 000 ms detruisait
les acteurs puis recreait les memes fichiers `.eff`. Un acteur IL-2 neuf repart
necessairement a l'age visuel zero : le reset etait donc produit par notre
prototype lui-meme, et non par la pause.

## Correctif hors jeu prepare apres la capture

- suppression du second appel visuel dans Little Boy et Fat Man ;
- conservation de l'unique chemin `Bomb.doExplosion` -> `Explosions.generate` ;
- echelle visuelle calculee depuis la puissance (15 kt ou 21 kt) ;
- transmission de la puissance exacte du souffle au futur etat visuel ;
- orientation `0/90/0` imposee aux acteurs de phase ;
- conservation continue des six acteurs initiaux aux frontieres 1, 30 et
  120 secondes ;
- ajout du nuage stabilise a 600 s sans destruction prematuree du panache ;
- destruction et liberation de toutes les references a 3 600 s.

Validations hors jeu : 16/16 reussies, audit statique 39/39, controle global du
contenu 18 PASS / 3 WARN / 0 FAIL. Les quatre classes modifiees ont ete
synchronisees transactionnellement dans la copie de test. Sauvegarde :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260903-073117`.
Le correctif n'est pas encore valide en jeu.

## Prochain essai

1. Little Boy sur terre, 90 s sans pause ni demi-tour.
2. Fat Man dans les memes conditions.
3. Seulement si les deux restent verticaux et continus : pause/reprise puis
   demi-tour.
4. Ensuite : eau, acceleration temporelle, mission dense et nettoyage complet.

## Banc A/B de capacite des particules

Le passage valide est conserve dans
`WIP/tests/captures/startup/20260903-142458Z-profile9-warm-windowed1024-startup` :

- 4 884 images sur 561,5 secondes ;
- sondes rouge 64 et bleue 512 visibles sans erreur de chargement ;
- densite initiale proche, puis extinction nettement plus rapide de la rouge ;
- une reapparition simultanee apres des pertes de premier plan, sans aucune
  rehydratation Java (`rehydrates=0`) ;
- huit checkpoints atteints de 10 a 300 secondes ;
- nettoyage complet a 310 secondes : huit acteurs crees, huit detruits, zero
  acteur restant ;
- aucune periode `Responding=False` apres la detonation.

Le pic mesure pendant toute la session est de 821,4 Mio de working set,
695,1 Mio prives et 1 969,8 Mio d'espace virtuel. Les deux seules periodes non
reactives precedent la detonation : 65,1 secondes au chargement initial et 4,3
secondes au chargement de la mission. La consommation CPU moyenne du processus
sur le passage complet represente 82,6 % d'un coeur, soit 20,7 % de la capacite
des quatre coeurs autorises. Ces valeurs ne constituent pas encore une
configuration minimale ; elles alimentent le futur corpus de mesures.

Conclusion : le plafond 512 est utile pour les couches principales du futur
champignon. Il faut toutefois limiter leur nombre simultane, scinder la duree
reelle en phases bornees et laisser chaque phase se vider avant destruction pour
eviter une coupure visible.

## Candidat construit apres le banc A/B

Le correctif de reprise a ete retire : plus de comparaison temps reel/temps de
simulation et plus de destruction-recreation apres une pause. La tete principale
passe de 128 a 512 particules. Les transitions visuelles sont desormais
chevauchees et bornees : retrait des transitoires a 130 s, ajout du stabilise a
600 s, retrait du panache de montee a 728 s, fin naturelle des dernieres
particules a 3 718 s et garde-fou a 3 728 s.

Deux constructions propres produisent les memes treize classes. Le test hors
jeu obtient 21/21, l'audit nucleaire 41/41 et le controle global 19 PASS / 3 WARN
/ 0 FAIL. Les quatre classes de souffle et de degats restent identiques octet
pour octet.

Le candidat a ensuite ete synchronise dans la copie de test : quatre operations,
17 fichiers deja conformes, aucune suppression. La sauvegarde recuperable est
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260903-174338`.
Le controle apres copie conserve 19 PASS / 3 WARN / 0 FAIL et les 47 controles
de preparation passent (`Ready=True`). Aucun lancement d'IL-2 n'a ete effectue
avec ce candidat au moment de cette note.

## Session 16 h 05 UTC — rejet de l'emetteur mobile

La capture
`WIP/tests/captures/startup/20260903-160537Z-profile9-warm-windowed1024-startup`
est complete : 8 309 images, deux detonations terrestres et fermeture volontaire
du jeu. Le premier evenement a ete observe pendant environ 104 secondes ; il a
atteint `mature-rise` mais pas la frontiere 120 s. Le second a dure environ
22 secondes. Aucun des deux n'a donc atteint le sommet programme a 600 s.

L'estimation de 3 a 4 km pendant le premier passage concorde avec la courbe
nominale : a 104 s, elle donne environ 4 209 m AGL pour Little Boy. Ce passage
ne permet ni de valider ni de rejeter la cible finale de 12 km.

Le rendu est toutefois rejete pour une autre raison, confirmee par l'observation
en vol et les images : un point de creation du nuage monte rapidement, tandis
que la masse deja emise stagne plus bas. `ActorPos.setAbs` deplace l'emetteur,
mais pas les particules existantes qui restent dans l'espace du monde. Le nuage
se separe donc mecaniquement en une origine mobile et une ancienne masse basse.

Les mesures montrent qu'il ne s'agit pas d'un gel :

| Evenement | Repondant | Prive max | Virtuel max | CPU equivalent moyen |
| --- | ---: | ---: | ---: | ---: |
| Little Boy 1, 104 s | 721/721 | 670,7 Mio | 1 966,4 Mio | 0,77 coeur |
| Little Boy 2, 22 s | 151/151 | 676,1 Mio | 1 984,2 Mio | 0,80 coeur |

Le candidat suivant supprime tout mouvement d'emetteur. Il cree dix couches de
tete fixes entre 30 et 570 s, cinq couches de tore intermediaires et la couche
stabilisee a 600 s. Les emissions de montee durent 60 s et leurs particules se
vident pendant 128 s. Le maximum est borne a 22 acteurs crees par explosion ;
les couches trop anciennes sont ignorees lors d'un rattrapage. Deux builds sont
identiques, les 25 controles de cycle passent et l'audit nucleaire obtient
42/42. Le controle global retourne 19 PASS / 2 WARN / 1 FAIL : l'unique echec
est la chaine Allison distincte. Le souffle, les degats et leur delai ne
changent pas.

Altitudes nominales AGL des origines fixes, arrondies au metre :

| Age simule | Little Boy | Fat Man | Tore ajoute |
| ---: | ---: | ---: | :---: |
| 30 s | 1 716 m | 1 775 m | non |
| 90 s | 3 768 m | 4 114 m | oui |
| 150 s | 5 591 m | 6 193 m | non |
| 210 s | 7 187 m | 8 012 m | oui |
| 270 s | 8 554 m | 9 571 m | non |
| 330 s | 9 694 m | 10 870 m | oui |
| 390 s | 10 605 m | 11 910 m | non |
| 450 s | 11 289 m | 12 689 m | oui |
| 510 s | 11 744 m | 13 208 m | non |
| 570 s | 11 972 m | 13 468 m | oui |
| 600 s | 12 000 m | 13 500 m | couche stabilisee |

Ces valeurs placent les origines, pas le bord superieur exact des particules.
Le prochain test devra mesurer la base, le coeur et le sommet visible separement.

Le journal de la seconde mission contient aussi 25 `FileNotFoundException` :
douze echecs de `motor.Allison.start.begin`, douze de
`motor.Allison.start.end`, puis `motor.Allison_V1700_series` invalide. Ce
probleme sonore, deja vu lors du stress P-39D, est distinct du chantier
nucleaire et doit etre corrige avant la validation generale v1.15. Le
validateur le classe desormais explicitement en echec.

Rapport machine :
`manifests/test/nuclear-runtime-20260903-160537Z.json`.

## Candidat a couches fixes installe dans la copie de test

Le candidat qui remplace l'emetteur mobile a ete synchronise le 3 septembre
2026 a 17 h 00 UTC. La transaction a remplace quatre fichiers, cree les deux
nouveaux effets `rise-head` et `rise-torus`, constate dix-sept fichiers deja
conformes et n'a rien supprime. Les vingt-trois empreintes du plan correspondent
exactement aux fichiers installes.

Sauvegarde recuperable :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-nuclear-fixed-layers-20260903`.

Apres installation, le cycle hors jeu obtient toujours 25/25 et l'audit
nucleaire 42/42. Les quarante-six controles de preparation sans rapport avec
Allison passent. La preparation generale reste volontairement marquee
`Ready=False`, car la chaine sonore Allison produit l'unique echec global connu.
Cette anomalie n'est ni masquee ni attribuee au candidat nucleaire.

Le prochain passage doit commencer par Little Boy sur terre, sans pause ni
demi-tour, et rester en observation au moins 210 secondes apres la detonation.
Il doit montrer plusieurs masses fixes successives qui se chevauchent, et non
un point unique montant au-dessus d'un nuage abandonne au sol. Aucun lancement
n'a ete effectue apres cette synchronisation.

## Session 17 h 24 UTC — premier passage des couches fixes

La capture
`WIP/tests/captures/startup/20260903-172444Z-profile9-warm-windowed1024-startup`
contient une detonation terrestre de Little Boy. Le jeu est reste repondant et
n'a produit ni exception nucleaire ni nouvel avertissement de ressource. Le
journal ne contient qu'un evenement nucleaire : la duplication visuelle reste
donc corrigee.

La mission s'est toutefois terminee seulement 28 secondes apres la detonation.
Le rendu a ainsi montre le flash, la boule initiale et le nuage precoce, mais il
n'a pas atteint la premiere couche fixe programmee a 30 secondes. L'absence de
ligne `rise-layer-30s` est normale pour ce passage et ne prouve pas une panne du
battement visuel.

Sur ces 27,9 secondes, les 206 mesures indiquent :

| Mesure | Valeur |
| --- | ---: |
| Echantillons non repondants | 0 |
| Memoire de travail maximale | 654,3 Mio |
| Memoire privee maximale | 670,7 Mio |
| Espace virtuel maximal | 1 967,0 Mio |
| Charge CPU moyenne du processus | 0,96 coeur |

Le rendu initial est juge prometteur, mais la colonne parait trop fine et pas
assez dense. Les images embarquees ne permettent pas d'en tirer un diametre :
la vue plongeante suit le B-29, le nuage est coupe par le bord de l'ecran et la
distance de prise de vue change continuellement.

Rapport machine :
`manifests/test/nuclear-runtime-20260903-172444Z.json`.

## Missions de calibration a cameras fixes

Quatre missions reproductibles sont maintenant fournies sous
`Missions/Single/US/Open Sturmovik Tests` : Little Boy et Fat Man sur terre,
puis les deux armes au-dessus de l'eau. Les missions terrestres utilisent
Smolensk et un camion cible. Les missions maritimes utilisent une zone d'ocean
deja occupee par des routes de porte-avions sur `CoralSea/load.ini` et un
tanker cible. Dans les deux cas, le B-29 Silverplate vole a 5 000 m avec les
emports verifies `LittleBoy` ou `FatMan`.

Le tanker maritime sert uniquement de point de visee pour le pilote
automatique. Little Boy detone vers 600 m et Fat Man vers 503 m au-dessus de la
surface ; elles ne doivent donc pas percuter la coque. Ce scenario qualifie la
branche visuelle `water` sans la confondre avec une explosion de contact ou
sous-marine.

Le premier essai de camera, capture dans
`WIP/tests/captures/startup/20260903-184355Z-profile9-warm-windowed1024-startup`, a
revele une erreur de cadrage. La bombe a pourtant detruit la cible exactement a
`110000, 95000` et l'etat nucleaire a atteint la couche de 30 s. Les cameras
etaient a l'est de l'impact et leur vue initiale regardait aussi vers l'est :
l'explosion etait donc derriere l'operateur. Les 4 569 images confirment que les
vues ne contiennent que le paysage. Ce passage ne permet aucune mesure de
diametre ou de hauteur.

Le moteur est reste stable pendant les 66,9 secondes mesurees apres la
detonation : 448 echantillons repondants sur 448, 654,0 Mio de memoire de
travail, 671,6 Mio prives, 1 966,9 Mio virtuels et 0,79 coeur en moyenne. Il n'y
a ni exception nucleaire ni seconde creation de l'evenement.

Les vingt positions de mission ont ete corrigees. Dans chaque scenario, les
cinq cameras sont maintenant toutes placees a l'ouest de l'impact et alignees
avec la route est du bombardier, a 1 km, 3,5 km, 6 km, 12 km et 17 km. Avant
`Ctrl+F2`, l'operateur doit revenir en vue avant et utiliser sa commande de
recentrage : l'orientation heritee regarde alors naturellement vers la cible.
Le format de mission 4.09m ne conserve pas un point a regarder, uniquement la
position et la hauteur de la camera.

Les manifestes
`manifests/test/nuclear-static-camera-missions-v1.15.json` et
`manifests/test/nuclear-static-camera-water-missions-v1.15.json` conservent les
coordonnees, surfaces, cibles et ordres des vues. Le validateur controle les
quatre missions et leurs dix positions de camera. Cette geometrie permettra de
mesurer :

- la continuite aux ages 30, 90, 150 et 210 secondes ;
- la largeur de la colonne et du chapeau ;
- la hauteur visible par rapport aux origines nominales ;
- le diametre de la boule de feu et la symetrie du front initial ;
- la difference reelle entre Little Boy et Fat Man.

Source de la commande 4.09m :
[discussion SAS1946 sur les cameras statiques](https://www.sas1946.com/main/index.php?topic=33600.0).
Le manuel officiel de 1946 decrit leur placement dans le Full Mission Builder :
[manuel IL-2 1946](https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/15280/manuals/manual_english.pdf?t=1447351319).

Les huit fichiers de mission corriges ont ete synchronises dans la copie de
test et leurs empreintes correspondent au depot. Les anciennes missions restent
recuperables dans
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-nuclear-cameras-aligned-20260903-210413`.

## Session 19 h 08 UTC — visibilite a 42 secondes

La capture
`WIP/tests/captures/startup/20260903-190834Z-profile9-warm-windowed1024-startup`
contient deux chargements de la mission Little Boy. Le premier a ete abandonne
sans detonation. Pendant le second, la bombe a detruit la cible a `12:02:18` et
la mission s'est terminee a `12:03:00`, soit 42 secondes simulees plus tard.

La vue `F2` plongeante montre le flash blanc, l'anneau initial et le nuage. Ce
dernier reste visible jusqu'a la fin de la mission et la couche fixe de 30 s est
bien creee. Il n'y a ni reset, ni seconde detonation, ni exception. En revanche,
la camera continue de suivre le B-29 : le nuage sort progressivement par le bas
de l'image apres environ 20 secondes. Les images ne permettent toujours pas de
mesurer la hauteur, la largeur ou la vitesse de montee.

Les 284 echantillons recueillis entre la detonation et la fin de la mission sont
tous repondants. Le maximum atteint 650,0 Mio de memoire de travail, 667,7 Mio
prives et 1 984,0 Mio virtuels, pour 0,78 coeur en moyenne. Le rapport machine
est `manifests/test/nuclear-runtime-20260903-190834Z.json`.

L'audit du profil de commandes explique aussi l'echec de la consigne `F8` :
`F8=OutsideViewFollow` suit l'objet courant, tandis que la cible terrestre est
`F7=ViewEnemyGround` et sa vue directe `Alt+F7=ViewEnemyDirectGround`.
L'enregistrement rapide n'avait aucune touche. Une premiere execution de
`tools/Set-IL2QuickTrackBinding.ps1` a bien ecrit
`Ctrl R=quickSaveNetTrack`, mais dans `[HotKey misc]`. Cette section est
incorrecte pour cette commande dans IL-2 4.09m ; l'essai qui a suivi a donc ete
invalide et aucune piste n'a ete creee. Ce profil fautif reste sauvegarde sous
`Users/0/settings.ini.open-sturmovik-quick-track-20260903-212609.bak`.

Le prochain passage doit enregistrer un `.ntrk` pendant une seule detonation.
La piste sera ensuite rejouee plusieurs fois afin de choisir et orienter les
cameras sans repeter le largage. La communaute 1946 confirme que le mode NTRK
est le plus robuste et que les cameras statiques restent accessibles pendant la
lecture :
[enregistrement NTRK](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=26144),
[cameras statiques en piste](https://www.sas1946.com/main/index.php?topic=33600.0).

## Session 19 h 29 UTC — premier essai NTRK invalide

La capture
`WIP/tests/captures/startup/20260903-192906Z-profile9-warm-windowed1024-startup`
a dure 481,7 secondes et contient 3 095 mesures processus. Alexis a presse
`Ctrl+R`, sans retour visible. Le controle apres fermeture confirme qu'aucun
nouveau `quickNNNN.ntrk` n'existe : la piste n'a jamais demarre.

La cause n'est pas le moteur de piste ni la mission. `quickSaveNetTrack` est
une commande de l'environnement special `[HotKey $$$misc]`, alors que la
premiere version de l'outil l'avait placee dans `[HotKey misc]`. Le profil a
ete corrige seulement apres l'arret complet du jeu. Il contient desormais une
unique liaison :

```ini
[HotKey $$$misc]
Ctrl R=quickSaveNetTrack
[HotKey timeCompression]
```

La correction est sauvegardee sous
`Users/0/settings.ini.open-sturmovik-quick-track-20260903-213953.bak` et le mode
`-ValidateOnly` confirme son emplacement. L'outil refuse aussi de modifier le
profil si `il2fb.exe` est actif.

La session n'est toutefois pas vide : Little Boy a cree un seul evenement,
puis les couches fixes de 30 et 90 secondes aux altitudes logiques d'environ
1 714 m et 3 766 m AGL. Aucune exception nucleaire n'apparait. Les maxima de la
session sont 674,9 Mio de working set, 694,2 Mio prives et 1 971,1 Mio virtuels,
pour environ 0,66 coeur en moyenne. Les 563 echantillons non repondants sont
repartis sur toute la session et ne sont pas attribuables a l'explosion sans
une correlation temporelle plus fine.

Conclusion : ne pas refaire la mission pour regler les cameras tant que la
creation d'une piste n'est pas prouvee. Le prochain essai doit commencer par un
inventaire des pistes, enregistrer 210 secondes sans perte de focus, fermer
l'enregistrement avec un second `Ctrl+R`, puis verifier date, taille et SHA-256
du nouveau fichier avant toute relecture.

## Session 20 h 12 UTC — NTRK valide et continuite jusqu'a 120 secondes

La capture
`WIP/tests/captures/startup/20260903-201222Z-profile9-warm-windowed1024-startup`
contient deux passages Little Boy sur terre et deux pistes NTRK valides. La
liaison placee sous `[HotKey $$$misc]` est donc confirmee par le moteur :

- `quick0000.ntrk`, 131 953 octets, couvre environ 72 secondes apres la
  detonation ;
- `quick0001.ntrk`, 201 531 octets, couvre environ 121 secondes apres la
  detonation.

La seconde piste est conservee comme prise de reference pour regler les
cameras. Son SHA-256 est
`5FE5E7B50464092B43CC3C2D42E588437D291F7B45B33D7D346586CE32622AB9`.
Elle est copiee dans le sous-dossier `ntrk` de la capture, avec la premiere
prise et leurs metadonnees.

Le second cycle nucleaire est continu jusqu'a l'arret volontaire : creation
unique, phase precoce a 1 seconde, couche fixe a 30 secondes, couche fixe a 90
secondes, puis passage en phase tardive a 120 secondes. Les altitudes logiques
visees sont respectivement 601 m, 639 m, 1 713 m, 3 765 m et 4 706 m AGL.
Il n'y a ni seconde detonation, ni reset logique, ni exception nucleaire.

Les 910 echantillons entre la detonation et l'arret de la piste sont tous
repondants. Le processus utilise en moyenne 0,953 coeur, avec un 95e percentile
de 1,082 coeur. La memoire de travail varie seulement de 648,9 a 651,5 Mio, la
memoire privee de 666,3 a 668,9 Mio et l'espace virtuel culmine a 1 984 Mio.
Aucune croissance anormale n'est visible sur ces deux minutes.

La vue F2 montre le flash blanc puis un panache volumineux. Le panache reste
dans le bord inferieur droit jusqu'a environ 50 secondes, puis sort entierement
du cadre vers 60 secondes parce que la camera suit le B-29. Cette disparition
de l'image n'est pas un reset : le journal continue jusqu'a 120 secondes.

La cible de 210 secondes n'a pas ete atteinte. L'operateur d'analyse a ancre
son chronometre sur le premier passage au lieu du second et a demande l'arret
de la piste trop tot. Cette erreur de protocole est conservee explicitement ;
elle ne doit pas etre attribuee au jeu. Le verdict est donc : succes pour la
continuite logique, la stabilite et la reactivite jusqu'a 120 secondes, mais
resultat non concluant pour les couches 150/210 secondes, les dimensions
visuelles et la reprise apres pause.

Rapport machine :
`manifests/test/nuclear-runtime-20260903-201222Z.json`.

La prochaine action utile n'est pas un nouveau largage immediat. Il faut
d'abord relire `quick0001.ntrk`, atteindre une camera statique avec
`Ctrl+F2`, l'orienter vers l'est en direction du point d'impact
`110000, 95000`, puis confirmer que cette vue reste exploitable. Ensuite, un
unique enregistrement neuf devra depasser reellement 210 secondes simulees.

## Correction suivante — cameras centrees verticalement

La prise precedente a montre que la vue F2 pouvait garder le panache dans le
cadre seulement une cinquantaine de secondes. Les cameras decalees vers
l'ouest exigeaient en plus une orientation manuelle fiable que le format de
mission 4.09m ne sait pas enregistrer. Cette geometrie est donc remplacee dans
les quatre missions de calibration.

Les cinq cameras partagent maintenant exactement les coordonnees horizontales
du point d'impact. Elles forment une pile verticale a 1 200, 3 000, 10 000,
16 000 et 6 000 metres. La camera principale de 6 000 m est volontairement la
derniere ligne de la section `[StaticCamera]`, car le cycle 4.09m selectionne
habituellement ces objets dans l'ordre inverse d'insertion.

Avant `Ctrl+F2`, l'operateur doit utiliser F2 et regarder verticalement vers le
sol. La camera fixe herite alors de ce regard, mais sa position est desormais
exactement au-dessus de l'explosion : elle ne peut plus viser un terrain vide
simplement parce que l'orientation absolue n'est pas stockee. Les autres
cameras permettent de changer d'echelle sans changer de centre.

Le validateur obtient `PASS` pour les quatre missions et les dix definitions
partagees. Les huit fichiers `.mis` et `.properties` ont ete synchronises dans
la copie de test ; leurs huit empreintes correspondent au plan. La sauvegarde
precedente est recuperable dans
`WIP/tests/backups/IL 2 Sturmovik 1946 test.sync-backup-nuclear-cameras-overhead-20260904`.

Deploiement :
`manifests/test/nuclear-vertical-camera-v1.15-deployment.json`.

Cette modification ne peut pas corriger les cameras deja embarquees dans les
deux NTRK existants. Le prochain test devra donc charger la mission Little Boy
mise a jour. Il commencera par une qualification courte de `Ctrl+F2` avant de
laisser tourner une prise complete de 210 secondes.
