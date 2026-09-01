# Feuille de route de stabilisation Open Sturmovik 1.15

## Regle de sortie

La version 1.15 ne sera pas declaree stable tant qu'une anomalie reproductible
connue reste sans diagnostic. La cible est :

- aucun blocage au demarrage, au chargement d'une mission ou a la fermeture ;
- aucune exception Java, erreur de ressource, classe sans spawner ou erreur
  sonore dans les parcours couverts ;
- aucun fichier corrompu, absent ou incoherent entre les registres et le
  contenu charge ;
- aucune erreur de selection de profil, copie partielle ou restauration
  impossible ;
- une marge memoire x86 mesuree avec les textures et missions les plus lourdes ;
- tous les avertissements restants expliques, justifies et testes ;
- une installation reproductible sur une base DVD 4.07m propre.

Atteindre le menu est un jalon de diagnostic. Ce n'est pas encore une
validation de la version.

## Proposition de perimetre a faire valider

Cette proposition cherche une v1.15 propre et publiable sans transformer la
stabilisation 4.09m en audit infini de tout IL-2. Elle n'est pas une decision
finale : Alexis valide le contenu de la version.

### Indispensable pour publier la v1.15

1. Corriger le moteur de nuages meteo ou fournir un repli explicitement
   selectionne. Slovakia et Smolensk reproduisent de grands polygones blancs,
   des volumes traversant le relief et 21 exceptions natives
   `EffClouds.PreRender`. Rejouer d'abord la meme mission en A/B
   `TypeClouds=1/0`, puis avec le profil 4.09m stock. Le profil « Realisme max »
   ne peut pas sortir avec le moteur ameliore defectueux.
2. Valider le correctif pause/reprise de Little Boy puis Fat Man, sur terre et
   sur l'eau, sans gel, disparition, rattrapage visuel ou exception.
3. Valider en jeu la correction Slovakia : le `load.ini` libre demandait
   `actors.static`, alors que `fb_maps15.SFS` et le `load.ini` officiel 4.09m
   utilisent `actors_summer.static`. Le gros fichier reste dans le SFS.
4. Corriger ou neutraliser proprement les quatre chunks de cockpit B-29 absents
   (`zOilFlap1`, `zOilFlap2`, `zCompressor1`, `zCompressor2`).
5. Faire une mission Zuti/MDS d'au moins dix minutes et une mission AOC ; zero
   exception de minuteur, spawner, navire, registre ou ressource.
6. Corriger les appareils IA proposes comme appareil joueur. Le Su-2 teste sur
   Berlin n'a ni vue `F1` ni commandes, alors que `F2/F3` fonctionnent et que
   les outils historiques le marquent non pilotable. Retrouver un pack pilotable
   complet ou le masquer du premier groupe joueur.
7. Reparer les presets Allison des P-39D : le stress a produit 33
   `FileNotFoundException`, 32 sample pools de demarrage absents et un preset
   `motor.Allison_V1700_series` invalide.
8. Valider les profils modifies avec et sans 6DOF/TrackIR. Les fichiers des deux
   choix historiques sont actuellement identiques : le libelle ne suffit pas a
   prouver que 6DOF est reellement actif.
9. Valider le profil OpenGL natif, puis conserver les wrappers graphiques dans
   des profils separes, optionnels et reversibles tant qu'ils n'ont pas passe la
   meme matrice sur Intel, NVIDIA et AMD.
10. Mesurer trois demarrages froids et chauds, une grande carte, une mission IA
   dense et les textures les plus lourdes. Le cache de fichiers libres ne peut
   remplacer le wrapper historique qu'apres equivalence de ressources prouvee.
11. Installer sur une copie DVD 4.07m propre, appliquer la chaine 4.08m/4.09m,
   changer de profil, simuler une copie en echec puis restaurer. Le jeu original
   de reference reste en lecture seule.
12. Verifier le profil stock et la desinstallation : aucun `wrapper.dll` requis,
   aucun reste modde, et restauration atomique de `air.ini`, `stationary.ini`,
   `Buttons`, SFS, DLL et executable.
13. Qualifier reellement la cible Windows 32 bits. La v1.15 devra publier au
    moins une combinaison x86 CPU/GPU/pilote testee, son plafond d'espace
    virtuel stable, le reglage 4GT retenu et un profil graphique qui atteint les
    criteres annonces. Une simple compatibilite theorique ne suffit pas.

### A inclure si les essais restent stables

- Ajouter au panache nucleaire une zone atmospherique bornee : souffle radial
  a l'arrivee physique, ascendance chaude, couronne descendante et turbulence
  decroissante. Elle doit suivre l'horloge de simulation, survivre aux pauses,
  etre plafonnee en cout CPU et ne pas inventer des dommages hors des courbes
  documentees.
- Qualifier le profil graphique maximal 1 920 x 1 080 a 60 images/s. Les
  configurations candidates et les criteres sont dans
  `CONFIGURATIONS_MATERIELLES_V1.15.md` ; 2 560 x 1 440 sera une cible separee.
- Corriger les chargements de terrain par a-coups seulement si une trace prouve
  une cause modifiable sans casser l'ordre `MODS`, `Files`, SFS. Le moteur ne
  fournit pas automatiquement un vrai streaming moderne de textures.
- Faire un essai son, commandes, joystick, souris, fermeture et serveur dedie.
  Le gestionnaire/testeur de joystick appartient au lanceur separe.

### A reporter apres la v1.15

- l'audit exhaustif de tous les avions, cockpits, armes, nuages et cartes ;
- la generalisation du controle de pause aux explosions conventionnelles,
  incendies, fumees, trainees et poussieres. C'est un objectif obligatoire a
  terme, mais il commencera par un inventaire et des essais A/B : seuls les
  effets qui reproduisent le defaut seront enregistres, afin de ne pas modifier
  aveuglement toutes les particules du moteur ;
- le repaquetage ou decoupage des SFS sous 100 Mo ;
- le portage 4.15.1m, les utilitaires historiques incompatibles et la refonte
  profonde des DLL natives ;
- le nouveau lanceur tant que sa branche n'a pas passe sa propre validation.

Reporter ne signifie pas ignorer une erreur bloquante decouverte pendant les
tests v1.15 : toute regression reproductible du parcours publie reste a
diagnostiquer avant la sortie.

## A faire en premier

| Etat | Action | Resultat courant | Validation encore attendue |
|---|---|---|---|
| Fait statique | Remplacer le `WheelTire.mat` nul du Bf-109G-2 | Materiau texte valide, controle par empreinte | Aucun echec du `hier.him` au prochain lancement |
| Fait statique | Corriger `ZutiTimer_ExtendPlanesWings` | Cast premature neutralise, Java 45 conserve | Zero exception Zuti pendant 10 minutes et en mission |
| Fait statique | Reconstituer les dependances des 17 avions sans spawner | Registre `Plane.class` fusionne, 343 `SPAWN`, Java 47 | Zero `No spawner`, appareil statique et pilotable verifies |
| Fait statique | Reparer la coherence des six navires | `chief.ini` fusionne avec les six sections, sans doublon | Zero `Wrong chief's type`, navires mobiles verifies |
| Valide au second demarrage | Supprimer les collisions sonores et corriger les presets/WAV | Zero collision ; dix mixeurs Tiger33 complets ; vingt WAV manifestes, dont deux Sabre historiques conserves ; zero `Invalid preset format` jusqu'au menu | Sons verifies en vol |
| Fait statique | Expliquer et corriger les 28 `FileNotFoundException` | Les 28 appels sont attribues ; TBM-1 Multi1/USA corrige, sons corriges, introduction coupee | Zero exception dans la nouvelle capture |
| Decision v1.15 | Traiter `Records/Intro 04 Ed.trk` | `Intro=0`; la piste defectueuse reste conservee pour investigation | Demarrage normal propre sans introduction |
| Fait statique | Verifier `air.ini`, `stationary.ini` et `Buttons` comme ensemble atomique | INI 4.09m controles, Buttons present, registre avions fusionne | Chargement d'une mission representative puis campagne exhaustive |

## Stabilisation et performances

| Priorite | Action | Validation attendue |
|---|---|---|
| P1 | Refaire un passage Selector/Dump avec `Intro=0` | Ressources du demarrage pur separees de celles de la demonstration |
| P1 | Analyser la trace Process Monitor de 4,66 Go avec un filtre limite au PID IL-2 | Chemins lents, lectures repetees et fichiers absents quantifies |
| P1 statique fait, experimental | Le wrapper cache 4.09m utilise une liste atomique et un manifeste de 4 893 dossiers ; ajout, retrait, renommage et cache tronque ont ete testes sur banc | Mesurer le profil 11/12 dans le jeu puis refuser toute promotion si une ressource differe du wrapper historique |
| P1 statique fait | Les 63 bridages du demarrage ont conduit a un audit complet : 179 valeurs libres normalisees et une surcharge du `files.SFS`, sans changer le resultat runtime | Zero `Str2FloatClamp` au demarrage puis dans les missions couvrant les effets restants |
| P1 statique resolu hors jeu | Le profil generique garde les extensions NVIDIA desactivees et utilise `HardwareShaders=0`, `Forest=2`, `LandGeom=2`; le code 4.09m imprime quand meme un avis s'il manque son ancienne extension `GL_NV_texture_shader` | Classer automatiquement l'avis attendu, puis construire une sonde OpenGL x86 et verifier AMD, NVIDIA, Intel, GPU inconnu et chaque wrapper |
| P1 | Refaire deux mesures legeres, a froid puis a chaud, sans Dump et sans Process Monitor | Temps normal du jeu mesure sans surcharge de diagnostic |
| P1 | Mesurer les missions et textures les plus lourdes | Pic de memoire privee compatible x86 avec marge de securite |

## Campagne de non-regression

La validation fonctionnelle doit ensuite couvrir au minimum :

1. demarrage direct sans introduction, introduction activee, puis fermeture ;
2. profil modde sans 6DOF, profil modde avec 6DOF/TrackIR, et profil stock ;
3. mission rapide air-air, air-sol, porte-avions, carte lourde et mauvais temps ;
4. chacun des appareils declares dans `air.ini`, avec modele de vol `Buttons`,
   cockpit, armement, son, skin et apparition statique ;
5. navires, vehicules, DCA, trains et objets declares dans les registres ;
6. campagne, enregistrement/relecture d'une piste et chargement d'une sauvegarde ;
7. client multijoueur, serveur dedie et compatibilite reseau 4.09m ;
8. musiques par pays, fonds d'ecran, HUD, langues et toutes les resolutions du
   futur lanceur ;
9. installation complete sur une copie 4.07m propre, mise a niveau 4.09m,
   changement de profil, erreur simulee et restauration transactionnelle.

Chaque parcours doit conserver ses journaux et etre rejoue apres tout correctif
touchant aux classes, registres, SFS, sons, modeles 3D, wrapper ou executable.

## Etat au 31 aout 2026

- le profil 4.09m modde sans 6DOF, charge par Selector 5.1.2, atteint le menu ;
- aucun evenement de plantage Windows n'a ete enregistre ;
- la capture a extrait 10 201 ressources SFS, soit 604,2 Mio ;
- le pic observe est de 907,2 Mio resident et 1 598,8 Mio prive ;
- le profil 9 4.09m modde a atteint le menu en environ 130,7 secondes sans
  introduction ; aucun crash n'a eu lieu et Alexis a ferme le jeu volontairement ;
- les correctifs statiques P0 sont controles par un validateur qui retourne 15
  `PASS`, un `WARN` attendu faute de Dump recent et zero `FAIL` ; le parcours
  jusqu'au menu ne montre plus d'erreur Zuti, de spawner, de navire, d'effet,
  de materiau ou de fichier absent ;
- les deuxieme et troisieme passages confirment zero preset invalide et zero
  erreur de contenu jusqu'au menu ; `LandGeom=2` supprime la reecriture du
  profil. L'analyse de `il2_core.dll` prouve que les deux lignes Perfect sont
  l'avis attendu du detecteur 2004 face a un pilote Intel sans
  `GL_NV_texture_shader`, pas une autre incoherence de `conf.ini` ;
- la 28e erreur de fichier provenait des chemins `TBM1.him` absents de la classe
  TBM-1 ; les `hier.him` Multi1 et USA ont ete confirmes dans `fb_3do08p.SFS` ;
- la famille nucleaire corrigee ne gele plus sans pause et Fat Man a termine un
  nouveau parcours ; en revanche, le correctif natif de pause/reprise a echoue
  en jeu. Le panache repart aussi apres un demi-tour qui le fait sortir du champ,
  ce qui designe le cycle rendu/culling. L'audit dedie obtient 33 PASS statiques,
  mais la correction visuelle, la retention bornee des acteurs et l'altitude du
  nuage stabilise restent obligatoires ;
- l'erreur de ressource Slovakia est expliquee et corrigee statiquement : la
  surcharge utilise maintenant `actors_summer.static`, chemin officiel 4.09m ;
  la disparition des erreurs et le retour des objets statiques restent a
  confirmer en jeu ;
- la v1.15 ne peut toujours pas etre qualifiee stable avant ce nouvel essai,
  le test Zuti de dix minutes et les missions de validation ;
- la recherche des paquets historiques AAA est commencee dans
  `D:\Projets\GITHUB\res\IL2 1946\Mods`.
- le dossier de test a recu les correctifs de facon transactionnelle ; les
  sauvegardes horodatees restent a cote de celui-ci. Le controle de contenu
  retourne 16 PASS, un WARN de dump attendu et zero FAIL ; les 46 controles de
  disponibilite passent.
