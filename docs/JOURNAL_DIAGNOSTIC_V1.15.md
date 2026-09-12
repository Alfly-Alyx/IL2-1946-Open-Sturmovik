# Journal de diagnostic et retour d'experience v1.15

> **Perimetre historique avant le retrait du 12 septembre 2026.** Les constats,
> empreintes, listes de fichiers et commandes lies a MDS, DCG, San FOV ou Malta
> ci-dessous decrivent l'etat observe a leur date, pas le contenu cible actuel.
> MDS est desormais retire localement ; voir [le suivi courant](RETRAIT_COMPOSANTS_V1.15.md)
> et [la reconstruction AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md).
> Les anciens constructeurs et pieces retires sont conserves dans les archives
> externes identifiees par ce suivi ; ne pas reinstaller leur contenu.

Derniere mise a jour : 4 septembre 2026.

Ce document est le point d'entree chronologique des travaux de stabilisation
d'Open Sturmovik 1.15. Il conserve non seulement les resultats utiles, mais
aussi les essais invalides et les mauvaises hypotheses, afin qu'une nouvelle
session ne recommence pas les memes manipulations.

Les rapports specialises restent la source des mesures detaillees. Le present
journal indique ce qui est prouve, ce qui est seulement observe et ce qui reste
a qualifier.

## Regles permanentes de travail

- Le depot reel est
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik` ; le chemin
  equivalent sur `D:` est un lien symbolique. Ne pas creer de second clone a
  cote du depot.
- La branche du jeu est `v1.15`. Le lanceur evolue sur `launcher` dans un
  worktree organise, puis recoit les changements valides de `v1.15`.
- Le jeu original
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\resources\IL2\IL 2 Sturmovik 1946`
  est une reference en lecture seule et ne doit jamais etre modifie.
- Le jeu manipulable est
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test`.
  Toute synchronisation
  significative doit etre transactionnelle et precedee d'une sauvegarde.
- Les patchs et les ressources sous `D:\Projets\GITHUB\#res\IL2 1946` sont des
  sources en lecture seule. Aucun fichier n'y est ajoute sans accord d'Alexis.
- `WIP\resources\IL2` est la zone d'apport
  fournie par Alexis. La lire et l'inventorier sans la modifier. Avant toute
  integration, conserver provenance, auteur, version, licence, taille, SHA-256,
  version IL-2 visee et conflits connus.
  Les archives `.zip`, `.rar` et `.7z` doivent de preference rester intactes ;
  toute extraction de travail se fait sous `WIP`.
- Le laboratoire Selector 5.1.2/Dump Mode est range sous
  `WIP\labs\IL 2 Sturmovik 1946 Selector Dump`. Il ne constitue ni
  le jeu original, ni le jeu de test, ni un paquet distribuable.
- Toujours prevenir Alexis avant d'armer une capture ou de lancer IL-2, puis
  attendre un nouveau `go`.
- Une observation humaine, une ligne de journal et une capture sont trois
  preuves differentes. Ne pas transformer une estimation visuelle en mesure.
- Ne jamais declarer une fonction validee uniquement parce que le menu est
  atteint. Chaque avion, effet ou mod doit etre exerce dans le jeu.

## 1. Reconstitution et choix de version

La premiere copie de test provenait d'une installation officielle beaucoup
plus recente, puis recevait des fichiers 4.09m. Ce melange rendait les arrets a
5 % ambigus : il ne permettait pas de distinguer une base incomplete d'un
defaut de l'add-on. La cible 1.15 a donc ete fixee a IL-2 1946 4.09m, installee
au-dessus d'une base DVD 4.07m propre puis des patchs officiels 4.08m et 4.09m.
Le portage vers 4.15.1m est un chantier separe, car 4.15 exige une base 4.14.1m
officielle non modifiee.

Les anciennes variantes 4.08m et 4.09b sont conservees pour l'histoire et la
compatibilite serveur, mais ne sont pas des cibles de sortie actuelles. Les SFS
ne doivent pas etre supprimes sur le seul critere de nom ou de taille. Les 179
doublons exacts trouves entre archives et fichiers libres ne representent
qu'environ 1,5 Mio et sont conserves tant que la priorite de chargement n'est
pas prouvee chemin par chemin.

References :

- [`VERSION_COMPATIBILITY.md`](VERSION_COMPATIBILITY.md) ;
- [`MATRICE_VERSIONS_SFS.md`](MATRICE_VERSIONS_SFS.md) ;
- [`AUDIT_SFS.md`](AUDIT_SFS.md).

## 2. Selecteur, chemins et securite

Les premiers audits ont montre quatre defauts structurels : le choix `Quiet`
pouvait laisser un profil partiellement bascule, les chemins des deux
`air.ini` oubliaient le sous-dossier `Air.ini`, les HUD etaient copies vers un
repertoire `MODS\STD\i18n` inexistant et les profils originaux reclamaient un
`wrapper.dll` qui n'existe pas dans le jeu stock.

Le selecteur actuel verifie toutes les sources avant ecriture, controle les
copies, restaure l'etat precedent en cas d'echec et ne publie plus de faux
message de succes. `Quiet` ne modifie rien. Les HUD vont dans `Files\i18n`.
Les profils stock n'utilisent pas de wrapper ; les profils modifies utilisent
leur chargeur de mods. `stationary.ini` est bascule avec `air.ini` et le jeu ne
doit jamais recevoir un registre d'avions d'une autre famille de `Buttons`.

Le palier d'environ 60 % reste associe en pratique au chargement des appareils,
des cockpits et des modeles de vol. Une incoherence entre `air.ini`, les classes
et `Buttons` peut donc bloquer ici. Cette association est une heuristique de
diagnostic, pas une table officielle de tous les pourcentages.

## 3. Demarrage, chargement et environnement x86

Le principal cout statique identifie est l'indexation d'environ 89 738 fichiers
libres. Le cache d'un Selector plus recent est prometteur, mais son wrapper ne
peut pas remplacer directement l'ancien executable et un cache perime doit
etre invalide par manifeste. OpenGL natif reste le repli garanti ; les profils
dgVoodoo2, DXVK, Mesa et IL2GE devront rester distincts et reversibles.

Les executables modifies sont Large Address Aware. La cible est un processus
x86 pouvant disposer de pres de 4 Gio d'espace virtuel sous Windows 64 bits,
ou de pres de 3 Gio sous Windows 32 bits configure avec 4GT. Cela ne signifie
pas que le jeu peut employer les 16 ou 32 Gio de RAM de la machine. La RAM
systeme supplementaire sert au systeme, au cache disque, aux outils et a la
VRAM partagee ; elle ne change pas la limite d'adressage du processus.

L'affinite courante autorise au plus quatre coeurs physiques d'apres la
topologie Windows. Le moteur principal mesure generalement autour d'un coeur
actif ; la presence de quatre coeurs ameliore surtout les taches annexes et la
stabilite du systeme. L'Hyper-Threading pourra etre qualifie plus tard, mais ne
doit pas etre presente comme une acceleration deja prouvee.

Sur l'Intel UHD 620 de la machine de test, les messages refusant l'ancien mode
Perfect NVIDIA sont attendus : le profil securise utilise le chemin ARB et
Excellent. Les extensions NVIDIA ne doivent etre activees que sur un GPU
NVIDIA detecte.

References :

- [`RESULTATS_TESTS_DEMARRAGE_2026-08-30.md`](RESULTATS_TESTS_DEMARRAGE_2026-08-30.md) ;
- [`RESULTATS_TESTS_DEMARRAGE_2026-08-31.md`](RESULTATS_TESTS_DEMARRAGE_2026-08-31.md) ;
- [`AUDIT_CHARGEMENT_TEXTURES_4.09M.md`](AUDIT_CHARGEMENT_TEXTURES_4.09M.md) ;
- [`AUDIT_BINAIRES_X86.md`](AUDIT_BINAIRES_X86.md) ;
- [`PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md`](PERFORMANCES_ET_WRAPPERS_GRAPHIQUES.md).

## 4. Contenu, appareils et mods

Les erreurs initiales comprenaient un `WheelTire.mat` du Bf-109G-2 entierement
nul, une exception periodique `ZutiTimer_ExtendPlanesWings`, 17 classes sans
enregistrement `SPAWN`, six navires refuses, des collisions de presets sonores,
des WAV absents et une introduction defectueuse. Les corrections statiques et
les preuves disponibles sont centralisees dans `ETAT_REPRISE_V1.15.md`.

Le Su-2 n'etait pas pilotable : aucune vue F1, aucune commande et aucun cockpit.
La cause etait le maillage manquant `TGunnerSU2.him`. La restauration d'un
fichier AAA authentique et de sa texture a rendu le Su-2 pilotable en jeu.

Le B-29 Silverplate utilisait d'abord le cockpit B-29 standard, qui ne contient
pas les morceaux `zOilFlap1/2` et `zCompressor1/2`. La liaison au cockpit
Silverplate dedie a supprime ces avertissements et la vue F1 a ete validee.
TBF-1C, TBM-3 et Pokryshkins MiG-3 ont ete retrouves sous leurs constructeurs
ou appellations correctes et valides pilotables. Les entrees encore absentes de
l'editeur ne doivent pas etre ajoutees a `air.ini` avant preuve de leur classe,
de leur spawner, de leur cockpit et de leur modele de vol dans `Buttons`.

AOC 1a, Zuti/MDS et tous les programmes historiques restent soumis a un audit
de version, de chargement et de conflit. AOC 3A est un candidat plus vaste, pas
un remplacement valide. Les bombes lourdes conventionnelles, dont FAB-5000,
sont volontairement isolees du lot nucleaire.

References :

- [`AUDIT_APPAREILS_AIR_INI.md`](AUDIT_APPAREILS_AIR_INI.md) ;
- [`AUDIT_BUTTONS_MODELES_DE_VOL.md`](AUDIT_BUTTONS_MODELES_DE_VOL.md) ;
- [`AUDIT_ZUTI_AOC.md`](AUDIT_ZUTI_AOC.md) ;
- [`AUDIT_OS_PROGRAMS.md`](AUDIT_OS_PROGRAMS.md) ;
- [`SUIVI_ANOMALIES_APPAREILS_V1.15.md`](SUIVI_ANOMALIES_APPAREILS_V1.15.md).

## 5. Cartes, nuages et commandes

La campagne multicartes a montre un defaut critique commun des nuages : texture
incorrecte et volumes pouvant toucher ou traverser le sol. Ce chantier n'est
pas corrige dans le candidat nucleaire et doit rester ouvert. Un stress de 16
B-29 contre 16 appareils n'a pas fait chuter visiblement le moteur sur la
machine testee, mais ce constat ne remplace pas une mesure 1080p60.

Plusieurs avions demarrant sans poste pilote ont donne l'impression que les
commandes etaient cassees. Toujours verifier la variante exacte, la presence
d'un cockpit et le statut pilotable avant d'attribuer le symptome a la carte.

Commandes effectivement lues dans `Users\0\settings.ini` :

- `F2` : vue externe ;
- `F7` : cible terrestre ennemie ;
- `Alt+F7` : vue directe de la cible terrestre ennemie ;
- `F8` : vue externe suiveuse de l'objet courant, et non selection de cible ;
- `Ctrl+F2` : objet ennemi suivant ;
- `A` : pilote automatique.

Ne plus conseiller `F8` pour selectionner le camion cible. Ne pas supposer non
plus qu'une camera statique FMB possede un point de visee enregistre : le format
4.09m conserve sa position et sa hauteur, mais son orientation depend de la vue
heritee.

References :

- [`RESULTATS_CAMPAGNE_MULTICARTES_2026-09-01.md`](RESULTATS_CAMPAGNE_MULTICARTES_2026-09-01.md) ;
- [`SUIVI_ANOMALIE_NUAGES_V1.15.md`](SUIVI_ANOMALIE_NUAGES_V1.15.md).

## 6. Evolution du correctif nucleaire

Les premiers essais de Little Boy et Fat Man ont reproduit plusieurs defauts :
gel apres largage, explosion tournee de 90 degres et champignon rampant au sol,
reset ou disparition apres pause/demi-tour, disparition rapide, absence de
souffle sensible a 5 000 m et rendu similaire des deux bombes. Sur l'eau, la
gerbe apparaissait sans cratere, ce qui est coherent pour un airburst, mais la
duree et la montee etaient trop faibles.

La rotation a ete corrigee et le jeu est ensuite reste reactif. Le premier
correctif de pause, fonde sur un surveillant temps reel toutes les 25 ms, a ete
retire : recreer un `Eff3DActor` relance son age visuel a zero et ne peut pas
reprendre une particule a un age arbitraire. Une pause fige correctement le
temps de simulation, mais le moteur peut vider/repeupler ses particules a la
reprise. La perte de focus vers Codex est donc elle-meme un biais d'essai.

Le prototype suivant deplacait un emetteur actif vers le haut. Il a ete rejete :
les particules deja emises restent a leur ancienne position, tandis que seules
les nouvelles suivent l'origine. Le resultat etait un point montant rapidement
et une masse stagnant pres du sol.

Le candidat actuel emploie des couches fixes creees a 30, 90, 150, 210, 270,
330, 390, 450, 510 et 570 secondes, puis une couche stabilisee a 600 secondes.
Little Boy vise environ 12 km AGL et Fat Man 13,5 km AGL. Tous les acteurs ont
une fin bornee et le nettoyage de securite intervient avant 3 728 secondes. Les
classes restent en Java major 47 et compatibles avec la JVM 1.3.1. Le souffle,
les degats et le delai `distance / 343` n'ont pas ete modifies dans ce lot :
leur realisme physique reste donc a qualifier separement.

Les essais ont valide le flash, l'onde initiale, la verticalite, la stabilite
jusqu'aux couches 30 et 90 secondes et l'absence de seconde detonation sans
pause. Ils n'ont pas encore mesure le diametre de la boule de feu, la largeur
de la colonne, la vitesse du front, les rayons de degats, la montee complete a
600 secondes, le nettoyage a 3 728 secondes ou l'autorite reseau.

References :

- [`PLAN_NUCLEAIRE_V1.15.md`](PLAN_NUCLEAIRE_V1.15.md) ;
- [`RESULTATS_TEST_NUCLEAIRE_2026-09-03.md`](RESULTATS_TEST_NUCLEAIRE_2026-09-03.md) ;
- [`MODELE_SOUFFLE_NUCLEAIRE_V1.15.md`](MODELE_SOUFFLE_NUCLEAIRE_V1.15.md) ;
- [`BUG_CRITIQUE_B29_FATMAN.md`](BUG_CRITIQUE_B29_FATMAN.md).

## 7. Erreurs de protocole deja commises

### Cameras mal placees

Le premier jeu de cameras etait a l'est de l'impact et regardait aussi vers
l'est. La detonation etait derriere elles. Les cinq positions sont maintenant
a l'ouest, sur la route est du B-29, mais l'orientation n'est toujours pas un
`look-at` persistant. Une vue suiveuse F2 ne permet pas de mesurer une hauteur
ou un diametre : la distance et l'angle changent et le nuage sort du cadre.

### Missions terminees trop tot

Un passage s'est termine a 28 secondes, deux secondes avant la premiere couche
fixe. Un autre s'est termine a 42 secondes. Ces passages prouvent la stabilite
initiale, mais pas les phases tardives. Une validation de montee doit durer au
moins 210 secondes ; le sommet exige 600 secondes simulees.

### Banc de particules

Deux essais ont ete invalides par de mauvais chemins de matiere avant que le
banc rouge/bleu fonctionne. Il a montre que 64 particules s'epuisent plus vite
que 512, mais la reapparition simultanee apres perte de focus ne prouve pas une
reconstruction Java. Ne plus laisser le marqueur de banc actif apres l'essai.

### Premier essai NTRK invalide

Lors de la session de capture
`WIP/captures/startup/20260903-192906Z-profile9-warm-windowed1024-startup`,
`Ctrl+R` semblait ne rien faire. C'etait exact : aucune nouvelle piste
`quickNNNN.ntrk` n'a ete creee. La commande avait ete inseree sous
`[HotKey misc]`, section acceptee comme texte mais ignoree par IL-2 4.09m pour
`quickSaveNetTrack`.

La liaison correcte est desormais unique et placee sous :

```ini
[HotKey $$$misc]
Ctrl R=quickSaveNetTrack
[HotKey timeCompression]
```

Le profil fautif reste recuperable dans
`Users\0\settings.ini.open-sturmovik-quick-track-20260903-212609.bak`. La
correction a cree la sauvegarde
`Users\0\settings.ini.open-sturmovik-quick-track-20260903-213953.bak`.
L'outil `tools/Set-IL2QuickTrackBinding.ps1` refuse toute modification pendant
que `il2fb.exe` fonctionne, retire les anciennes liaisons au mauvais endroit et
verifie qu'il n'en existe exactement qu'une dans `[HotKey $$$misc]`.

Cette session reste utile pour le rendu : un seul evenement Little Boy a cree
les couches 30 s et 90 s, sans exception nucleaire. Elle a dure 481,7 s et
contient 3 095 mesures, avec des maxima de 674,9 Mio de working set, 694,2 Mio
prives et 1 971,1 Mio virtuels. Les 563 etats `Responding=False` appartiennent
a l'ensemble de la session et ne doivent pas etre attribues a la detonation
sans correlation temporelle. L'essai est invalide pour la piste et pour les
mesures visuelles, pas pour l'existence des deux couches.

## 8. Protocole NTRK corrige a employer une seule fois

1. Verifier qu'IL-2 est ferme et que la liaison se valide avec `-ValidateOnly`.
2. Noter les fichiers `records\quick*.ntrk` existants, leurs tailles et dates.
3. Prevenir Alexis, armer la capture, attendre `go`, puis lancer le jeu.
4. Charger la mission Little Boy terrestre et activer le pilote automatique.
5. Presser `Ctrl+R` une fois au debut. L'ancienne interface peut ne pas afficher
   d'indicateur ; ne pas en conclure immediatement que l'action a echoue.
6. Rester dans IL-2, sans basculer vers Codex, et laisser passer au moins
   210 secondes simulees apres la detonation.
7. Presser `Ctrl+R` une seconde fois pour fermer la piste, puis quitter la
   mission et le jeu normalement.
8. Prouver la creation d'un nouveau `quickNNNN.ntrk` par date, taille et SHA-256.
9. Ne lancer une relecture qu'apres cette preuve. Utiliser la relecture pour
   regler les cameras sans refaire un largage.
10. Restaurer la liaison utilisateur originale apres la campagne de tests.

Le precontrole suivant la correction obtient 47/47 pour le test nucleaire cible.
Il utilise maintenant la reference protegee sous
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\resources\IL2\IL 2 Sturmovik 1946`.
La base contient
46 pistes historiques et zero `quick*.ntrk`. Ces nombres et les empreintes sont
conserves dans `manifests/test/nuclear-ntrk-preflight-v1.15.json` ; toute
nouvelle piste sera donc identifiable sans ambiguite.

## 9. Points encore ouverts pour la sortie 1.15

- Valider une piste NTRK complete, puis mesurer Little Boy et Fat Man sur terre
  et sur l'eau avec cadrage reproductible.
- Qualifier pause, demi-tour, acceleration temporelle, mission de seize B-29,
  nettoyage complet et autorite hote/client.
- Mesurer et corriger le diametre de la boule de feu, la largeur/densite de la
  colonne, la vitesse et le rayon de l'onde, les rayons de degats, la montee et
  la duree reelles. Ne pas regler ces valeurs a l'oeil sans echelle.
- Traiter le defaut global des nuages et leur intersection avec le sol dans un
  lot separe du correctif nucleaire.
- Poursuivre Zuti, AOC 1a, sons Allison et appareils/variantes non encore
  qualifies. AOC 3A reste une decision ulterieure.
- Mesurer le chargement progressif des textures, l'anticrenelage et les profils
  graphiques modernes sans depasser le budget d'adressage x86.
- Etablir les configurations minimale et recommandee a partir de mesures
  1080p/2K a 60 FPS, et non a partir de la seule RAM installee.
- Terminer le lanceur uniquement si ses fonctions essentielles, son mode
  remplacement d'`il2setup.exe`, ses profils reversibles et son testeur de
  joystick sont stables sans retarder la qualite du jeu 1.15.

## 10. Regle de decision pour le prochain intervenant

Avant toute nouvelle modification, lire dans cet ordre :

1. ce journal ;
2. [`REFERENCE_RETROINGENIERIE_MOTEUR.md`](REFERENCE_RETROINGENIERIE_MOTEUR.md) ;
3. [`ETAT_REPRISE_V1.15.md`](ETAT_REPRISE_V1.15.md) ;
4. le rapport specialise du chantier concerne ;
5. le manifeste de la derniere copie de test ;
6. les derniers journaux et mesures brutes.

Si une observation contredit ce journal, conserver les deux faits, identifier
les versions exactes des fichiers et refaire un seul essai A/B. Ne jamais
reecrire l'historique pour donner l'impression qu'un essai invalide avait
reussi.

## 11. Session NTRK du 3 septembre 2026 a 20 h 12 UTC

La correction `[HotKey $$$misc]` est validee par deux pistes effectivement
creees. La piste de reference `quick0001.ntrk` couvre 121 secondes apres une
detonation terrestre de Little Boy. Le controleur nucleaire cree les couches
de 30 et 90 secondes, atteint `late-rise` a 120 secondes, ne se duplique pas et
ne produit aucune exception. Les 910 mesures de cette fenetre restent toutes
repondantes ; la memoire de travail culmine a 651,5 Mio.

La vue F2 suit toujours le B-29 : le panache quitte le cadre vers 60 secondes,
alors que son etat logique continue. Ne plus confondre sortie de cadre, culling
visuel et reset logique. Les images de capture enregistrent la fenetre au
premier plan ; toute bascule vers Codex ou l'Explorateur invalide donc la mesure
visuelle, meme si les compteurs du processus restent utilisables.

Le passage devait durer 210 secondes, mais l'operateur d'analyse a utilise
l'horodatage de la premiere mission pour chronometrer la seconde. La piste a
ete arretee a 121 secondes. C'est une erreur de protocole documentee, pas une
defaillance du jeu. La prochaine reprise doit commencer par relire la piste
existante pour regler `Ctrl+F2` et l'orientation des cameras statiques, puis
faire une seule prise neuve en se fondant sur les lignes `event=N action=created`
du journal courant, jamais sur l'heure de destruction de la cible.

Rapport detaille :
[`RESULTATS_TEST_NUCLEAIRE_2026-09-03.md`](RESULTATS_TEST_NUCLEAIRE_2026-09-03.md).
Mesures machine :
`manifests/test/nuclear-runtime-20260903-201222Z.json`.

## 12. Remplacement des cameras alignees par une pile verticale

Les cinq cameras placees a l'ouest du point d'impact n'ont pas fourni une vue
reproductible. Le format `.mis` 4.09m ne stocke pas leur orientation absolue et
la vue heritee pouvait donc montrer uniquement le paysage. Les quatre missions
de calibration utilisent maintenant cinq cameras exactement au-dessus de
l'impact, a 1 200, 3 000, 10 000, 16 000 puis 6 000 m. La ligne de 6 000 m est
placee en dernier pour devenir la premiere candidate du cycle inverse.

Procedure : passer en F2, regarder verticalement vers le sol, puis utiliser
`Ctrl+F2`. Tous les changements de camera conservent les memes coordonnees X/Y
et ne changent que l'altitude. Les NTRK precedents embarquent l'ancienne
mission : ils ne servent pas a valider cette nouvelle geometrie.

Les tests hors jeu passent et les huit fichiers ont ete copies de maniere
transactionnelle dans le dossier de test. La reference originale, maintenant
rangee sous `WIP\resources\IL2\IL 2 Sturmovik 1946`, n'a pas ete
modifiee. Le deploiement est consigne dans
`manifests/test/nuclear-vertical-camera-v1.15-deployment.json`.

## 13. Relocalisation des donnees lourdes hors du Bureau

Le 4 septembre 2026, apres fermeture du jeu, les deux dossiers ont ete deplaces
sur le meme volume `C:` vers le depot reel, dans une zone ignoree par Git :

- jeu de test : `WIP\test-installations\IL 2 Sturmovik 1946 test` ;
- ressources : `WIP\resources\IL2` ;
- reference originale protegee :
  `WIP\resources\IL2\IL 2 Sturmovik 1946`.

Le jeu de test contient 141 653 fichiers pour environ 24,71 Gio et son
`il2fb.exe` est present. Les ressources contiennent 49 670 fichiers pour environ
68,07 Gio. Les deux anciens chemins du Bureau ont disparu. Les scripts actifs
resolvent maintenant ces emplacements relativement a leur propre dossier, ce
qui evite de dependre du Bureau ou de la lettre `D:` symbolique.

Les rapports et manifestes produits avant ce deplacement conservent leur ancien
chemin absolu : il indique l'emplacement reel au moment de la mesure. Les
manifestes operationnels courants sont, eux, regeneres vers la nouvelle cible.
Aucun lancement du jeu n'a ete effectue pendant ou apres ce rangement.

## 14. Little Boy et pile de cameras verticale, 4 septembre 2026

La premiere mission lancee depuis le nouvel emplacement a dure environ
330 secondes apres la detonation de Little Boy. Le controleur a cree un seul
evenement, atteint les couches de 30, 90, 150, 210 et 270 secondes et detruit
les trois acteurs transitoires a 130 secondes. Il n'y a aucune exception, aucun
reset logique et aucun echantillon non repondant apres le debut de la mission.
La memoire privee reste entre 670,65 et 676,73 Mio pendant la fenetre nucleaire.

Les cameras verticales prouvent desormais le point d'impact, mais elles
traversent le volume du panache : la vue basse est engloutie par la boule de feu
et les vues hautes montrent alternativement le sol, une couche hors cadre ou
l'interieur du nuage. La disparition visuelle a 210 secondes n'est pas un reset,
car le journal conserve neuf acteurs et cree correctement la couche de
270 secondes. Cette geometrie est donc invalide pour mesurer le profil complet.

Le prochain protocole separe desormais une camera spectaculaire a 1 km, une
camera verticale haute pour le rayon et deux cameras de mesure laterales a
20 et 30 km pour le profil. Une seule vue doit etre conservee pendant chaque
prise. La pause/reprise, Fat Man, l'eau, le sommet a
600 secondes et le nettoyage a 3 728 secondes restent non testes.

Rapport :
[`RESULTATS_TEST_NUCLEAIRE_2026-09-04.md`](RESULTATS_TEST_NUCLEAIRE_2026-09-04.md).
Manifeste : `manifests/test/nuclear-runtime-20260904-051619Z.json`.

## 15. Cameras de profil et rangement WIP, 4 septembre 2026

Les quatre missions nucleaires de calibration possedent desormais, dans cet
ordre, une vue de profil a 1 km, deux vues de mesure a 20 et 30 km, trois vues
rapprochees a 3/6/10 km d'altitude et une verticale a 16 km. Le validateur hors
jeu passe pour deux manifestes, quatre missions et quatorze groupes de cameras.
Les huit fichiers deployes correspondent aux huit sources du depot. Leur
sauvegarde transactionnelle est conservee sous
`WIP/test-backups/sync-cam-20260904-055053Z`.

Toutes les donnees lourdes de travail sont maintenant regroupees sous `WIP/` :
captures, ressources, jeux de test, sauvegardes, laboratoires, SDK et
worktrees. L'ancien worktree nucleaire, propre et deja integre a `v1.15`, a
ete supprime et a libere environ 21,21 Gio. Le worktree `launcher`, avec ses
cinq changements locaux, a ete deplace sans perte vers
`WIP/worktrees/launcher` et la tache LAUNCHER a ete avertie.

La sauvegarde patrimoniale des outils reste independante sous
`D:\Projets\GITHUB\#res\IL2 1946\Outils`. CFR, 7-Zip, le bundle Git complet
OpenIL2 et le JDK Temurin employe pour compiler y ont ete ajoutes et controles.
Voir `manifests/tools/backup-tools-20260904.json`.

La chaine LLVM-MinGW 20260826 MSVCRT manquante a ensuite ete sauvegardee et
extraite sous `WIP/sdk/toolchains`. Elle reconstruit un `wrapper.dll` PE32 i386
de 46 080 octets. Le banc de test du cache passe ses quatre controles : premier
cache, reutilisation, invalidation de repertoire et recuperation d'un cache
corrompu. Ce test reste hors jeu.

## 16. Nettoyage local verifie, 4 septembre 2026

La sauvegarde complete du jeu de test du 30 aout occupait 26 725 181 698
octets. Un audit par chemin, taille puis SHA-256 l'a comparee au jeu de test et
a l'original protege. Sur 144 420 fichiers, 144 172 etaient des doublons exacts,
dont dix retrouves sous un autre chemin. Les 248 contenus restants, soit
976 717 octets, ont ete exportes dans
`WIP/test-backups/backup-before-clean-20260830.delta` puis rehaches apres copie.
La sauvegarde complete a seulement alors ete supprimee.

L'ancienne copie de `fb_maps15.SFS` n'a pas ete supprimee : son empreinte
`5D71D28C49B762CD0CE5B6F298D0EF18587E4AEA4839F6CAFBF09A1026FA74A4`
est unique par rapport au depot, au jeu de test, a l'original protege et aux
deux objets Git connus. Les extractions temporaires reproductibles Tiger33,
SFS et les anciens bancs de compilation ont en revanche ete retirees de
`WIP/tmp`, leurs archives sources restant sauvegardees sous `res`.

Alexis a ensuite autorise explicitement le tri prudent des captures. Les seize
PML de sessions chaudes ou prolongees, soit 63 660 459 237 octets, ont ete
supprimes apres validation stricte de leur emplacement et de leur taille. Les
quatre PML appartenant aux trois sessions a froid de reference ont ete
conserves. `WIP/captures` occupe desormais 41 217 659 829 octets, environ
38,39 Gio. Les sequences JPEG et les quatorze dumps memoire restent en place :
les premieres documentent le deroulement temporel des effets et les seconds
concernent encore des blocages a analyser. Voir
`manifests/diagnostics/capture-pruning-20260904.json` et
`manifests/diagnostics/backup-cleanup-20260904.json`.

## 17. Camera de mesure a 20 km prioritaire, 4 septembre 2026

Les essais precedents ont confirme que `Ctrl+F2` suit l'ordre d'insertion des
lignes `[StaticCamera]`. La vue a 1 km arrivait donc avant les vues de mesure et
pouvait etre prise a tort pour la camera eloignee. Les quatre missions
Little Boy/Fat Man sur terre et sur l'eau commencent desormais par la camera a
20 km et 6 000 m d'altitude. La camera a 30 km et 7 000 m vient en deuxieme,
puis la reference a 1 km en troisieme.

Un seul appui sur `Ctrl+F2`, apres une vue F2 orientee vers l'est dans l'axe du
B-29, doit donc afficher la vue de mesure principale. Les huit fichiers ont ete
deployes transactionnellement et correspondent aux sources par SHA-256. Le
validateur passe pour deux manifestes, quatre missions et quatorze groupes de
cameras. Le jeu n'a pas ete lance. Voir
`manifests/test/nuclear-20km-first-v1.15-deployment.json`.

## 18. Recul des cameras proches a 5 km, 4 septembre 2026

La session `20260904-133506Z-profile9-warm-windowed1024-startup` a ete arretee
volontairement apres constat que la vue a 1 km etait trop proche. Les quatre
cameras rapprochees ont ete reculees a 5 km dans les missions Little Boy et
Fat Man sur terre et sur l'eau. Les vues a 20 et 30 km restent respectivement
premiere et deuxieme dans le cycle ; la reference a 5 km devient la troisieme.

Le deploiement est transactionnel, ses huit fichiers correspondent aux sources
par SHA-256 et la sauvegarde precedente se trouve sous
`WIP/test-backups/sync-cam5-20260904`. Aucun jeu n'a ete relance. Voir
`manifests/test/nuclear-5km-close-v1.15-deployment.json`.

## 19. Essai 5 km : position valide, visee invalide, 4 septembre 2026

La session `20260904-135929Z-profile9-warm-windowed1024-startup` a declenche
Little Boy a `14:06:25Z` et a ete fermee volontairement environ dix secondes
plus tard. La vue statique a 5 km affichait le terrain, mais le point d'impact
etait hors champ. Seule une bordure lumineuse decoupee est visible pendant
trois images, de `frame-003206.jpg` a `frame-003208.jpg`. Cette prise ne permet
donc pas de qualifier la boule de feu, l'onde, la largeur, la hauteur ou la
duree du panache.

Le controleur nucleaire n'a pas plante : evenement unique, passage a
`early-rise` a une seconde, six acteurs crees, aucun reset et aucun echantillon
non repondant en mission. La memoire reste stable et la charge CPU reste proche
d'un coeur logique. Le probleme est exclusivement le protocole visuel.

Une ligne `[StaticCamera]` ne contient que sa position et sa hauteur. Elle ne
memorise aucun azimut ni aucune inclinaison. Le prochain essai utilisera donc
l'icone du camion cible pour centrer la vue a la souris avant le largage et
enregistrera simultanement une piste NTRK. Cette piste permettra de reprendre
la meme detonation sous plusieurs angles sans refaire le vol. References :
<https://www.sas1946.com/main/index.php?topic=33600.0> et
<https://cheatography.com/alejulian/cheat-sheets/il-2-sturmovik-1946/>.

## 20. Avions temoins de rayon, 4 septembre 2026

Cinq P-51D-5NT allies statiques balisent desormais l'axe de la camera a
respectivement 1, 2, 3, 4 et 5 km du point d'impact des missions terrestres
Little Boy et Fat Man. Leur cap est 90 degres, vers la cible situee a l'est.
Ils rendent l'axe visible avant le largage et permettront de constater le rayon
de destruction sans instrument externe.

Le type statique est present dans le `stationary.ini` de la copie de test. Le
validateur hors jeu passe et les quatre fichiers deployes correspondent aux
sources. Sauvegarde :
`WIP/test-backups/sync-range-markers-20260904-162052`. Manifeste :
`manifests/test/nuclear-range-markers-v1.15-deployment.json`.

Les missions sur l'eau restent volontairement inchangees : des avions poses
sur la mer pourraient disparaitre ou generer des evenements parasites au debut
de la mission. Elles recevront des temoins navals dedies.

Le chemin canonique de la bibliotheque externe a egalement ete corrige vers
`D:\Projets\GITHUB\#res\IL2 1946`. Cette bibliotheque reste une source et une
sauvegarde en lecture seule ; le travail actif demeure sous `WIP/`.

## 21. Essai interrompu et suspension du chantier nucleaire, 4 septembre 2026

La session `20260904-192415Z-profile9-warm-windowed1024-startup` a charge la
mission Little Boy mais n'a produit ni largage ni explosion. Le jeu est reste
reactif et Alexis l'a ferme volontairement lorsque la consigne de navigation
s'est revelee insuffisamment maitrisee. Aucune nouvelle piste NTRK n'a ete
creee. Ce passage ne qualifie donc aucun comportement nucleaire.

Le raccourci actif dit explicitement `Ctrl+F2=NextViewEnemy`. La source
communautaire indique que cette liste peut aussi contenir les cameras statiques,
mais elle contient d'abord ou en meme temps les autres vues ennemies. Le nombre
d'appuis n'identifie donc pas une camera precise. L'affirmation precedente
« un appui selectionne 20 km » etait injustifiee. De plus, sept cameras avaient
ete introduites alors qu'Alexis fixe une limite de six cameras maximum par
mission.

Alexis a ensuite arrete le chantier des bombes et demande la suppression des
missions creees. Les huit fichiers `.mis`/`.properties` ont ete retires du
depot et de la copie de test. Les manifestes et captures historiques restent
pour expliquer les essais passes, mais aucune mission nucleaire active ne doit
etre relancee. `docs/ETAT_COURANT_V1.15.md` devient la source de verite pour la
reprise du projet.
