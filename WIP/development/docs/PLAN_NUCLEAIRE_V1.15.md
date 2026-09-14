# Plan nucleaire propose

> **Chantier suspendu le 4 septembre 2026.** Ce plan est conserve pour une
> reprise eventuelle. Les missions de calibration ont ete supprimees et aucune
> etape ne doit etre executee sans nouvelle demande explicite d'Alexis.

Derniere mise a jour : 3 septembre 2026.

Le travail restera sur `v1.15`, independamment du lanceur.

## Phase 1 — Nouveau socle visuel hors jeu

1. Supprimer le surveillant de pause a 25 ms.
2. Conserver sans modification le souffle, les degats et le delai `distance / 343`.
3. Ajouter un etat nucleaire persistant contenant :
   - heure de detonation ;
   - position et altitude ;
   - puissance ;
   - surface terre/eau ;
   - phase courante ;
   - acteurs crees et detruits.
4. Ajouter les compteurs de diagnostic.
5. Construire les phases visuelles bornees.
6. Programmer explicitement la destruction de chaque acteur.
7. Porter le sommet de Little Boy vers environ 12 km et Fat Man vers 13,5 km.

## Phase 2 — Validation automatisee

Les essais hors jeu devront prouver :

- compilation Java major 47 ;
- construction reproductible ;
- aucun appel a une API posterieure a Java 1.3 ;
- ordre correct des phases ;
- pause sans progression du temps ;
- reprise directement a l'age reel ;
- destruction de tous les acteurs avant `3 728 s` ;
- aucune reference residuelle ;
- empreintes et ressources coherentes.

## Phase 3 — Preparation du jeu de test

Apres reussite complete :

1. creer une sauvegarde transactionnelle ;
2. synchroniser uniquement les classes et effets nucleaires necessaires ;
3. verifier leurs empreintes ;
4. preparer les missions ;
5. armer les captures ;
6. m'arreter et vous prevenir avant le lancement.

## Phase 4 — Essais en jeu

Je recommande quatre sessions separees :

1. Little Boy puis Fat Man sur terre, sans pause, puis avec pause et demi-tour.
2. Little Boy et Fat Man sur l'eau, avec acceleration temporelle.
3. Seize B-29 pendant au moins dix minutes, puis acceleration jusqu'au nettoyage complet.
4. Autorite multijoueur hote/client, seulement apres validation locale.

Chaque etape aura un critere de passage. Nous n'entamerons pas la suivante si
une explosion repart a zero, si un acteur reste retenu, si la memoire continue
de croitre ou si une exception apparait.

Apres validation nucleaire, le nouveau commit `v1.15` sera fusionne a nouveau
dans `launcher` pour actualiser ses manifestes et controles.

## Etat de realisation

Les phases 1 et 2 sont realisees dans le depot. Le candidat a emetteur mobile a
ete teste puis rejete ; son remplacement par couches fixes n'est pas encore
synchronise dans la copie de test :

- le surveillant temps reel a 25 ms et sa reflexion ont ete retires ;
- l'age et les phases utilisent exclusivement l'horloge de simulation IL-2 ;
- le temps reel et la reconstruction apres pause ont ete retires : un acteur
  recree repart toujours a l'age visuel zero dans IL-2 4.09m ;
- le battement d'une seconde utilise uniquement l'horloge de simulation ;
- les bornes sont 1, 30, 120, 600, 1 800 et 3 600 secondes ;
- une pause fige l'age logique sans detruire ni recreer les acteurs ;
- les effets transitoires sont liberes a 130 secondes ;
- la tete et le tore initiaux cessent leur emission a 60 secondes ;
- dix tetes fixes sont ancrees aux ages 30, 90, 150, 210, 270, 330, 390, 450,
  510 et 570 secondes, avec cinq tores fixes intermediaires ;
- aucun emetteur actif n'est deplace : les particules deja emises restent ainsi
  groupees avec l'origine qui les a produites ;
- chaque couche emet 60 secondes et se vide naturellement pendant 128 secondes ;
- un rattrapage ignore les couches expirees afin de ne jamais les creer en rafale ;
- le nuage stabilise commence a 600 secondes, puis les acteurs de montee sont
  liberes a 728 secondes ;
- l'emetteur stabilise cesse avant 3 600 secondes, ses particules finissent a
  3 718 secondes et le nettoyage de securite intervient a 3 728 secondes ;
- les altitudes des couches suivent une courbe quadratique relative au terrain
  local jusqu'a 12 000 m AGL pour Little Boy et 13 500 m AGL pour Fat Man ;
- chaque acteur est detruit explicitement et toutes les references sont liberees
  avant la borne de securite de 3 728 secondes ;
- les treize classes restent en version majeure 47 ;
- deux constructions propres produisent les memes treize fichiers et le meme
  manifeste ;
- l'audit contre le `rt.jar` Java 1.3.1 livre avec le jeu ne trouve aucun appel
  a une API plus recente ;
- le test de cycle de vie obtient 25 PASS sur 25, dont la conservation octet
  pour octet des quatre classes de souffle et de degats ;
- l'audit nucleaire complet obtient 42/42 ; le controle global obtient 19 PASS /
  2 WARN / 1 FAIL, l'echec portant uniquement sur la chaine sonore Allison
  independante du rendu nucleaire ;
- le B-29 Silverplate utilise maintenant son cockpit pilote Silverplate complet,
  sans modifier les autres variantes du B-29 ;
- la precedente synchronisation reste sauvegardee sous
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260903-174338`,
  mais son candidat mobile est maintenant rejete ;
- le nouveau candidat fixe doit encore passer l'audit global, puis faire l'objet
  d'un nouveau plan et d'une nouvelle sauvegarde transactionnelle.

Le souffle et les degats n'ont pas ete retouches pendant ce lot. Les classes
`ShockAction`, `ShockData`, `DamageAction` et `DamageData` gardent leurs
empreintes precedentes. Leur exactitude physique fera l'objet d'un lot separe,
afin de ne pas melanger une correction visuelle et un changement de modele de
degats.

Le resultat du dernier jeu lance est decrit par
`manifests/test/nuclear-runtime-20260903-160537Z.json`. Il confirme une bonne
reactivite mais rejette le deplacement continu de l'emetteur.

## Limite que seul IL-2 peut encore trancher

Le nouvel etat logique reste au meme age de simulation pendant une pause et ne
recree plus rien a la reprise. Le moteur natif 4.09m peut toutefois recycler ou
recharger visuellement un emetteur lorsqu'il revient dans le champ de la
camera. Les couches fixes garantissent que cette reprise se fait a l'altitude
de la phase courante plutot qu'a partir du sol. Les essais avec pause et
demi-tour doivent encore confirmer le resultat reel.

### Hauteur nominale et hauteur visible du champignon

Le point de detonation est place a environ 600 m au-dessus du sol pour Little
Boy et 503 m pour Fat Man. Les couches sont posees une fois, a des altitudes
calculees sur une courbe quadratique a ralentissement progressif. La couche de
570 s se trouve juste sous le sommet et l'effet stabilise est cree exactement a
la cible d'environ 12 000 m pour Little Boy ou 13 500 m pour Fat Man a dix
minutes.

Ces valeurs sont des cibles nominales proches des 40 000 a 50 000 pieds
rapportes pour les nuages d'Hiroshima et Nagasaki. Elles ne donnent pas encore
le bord superieur exact rendu par IL-2 : les particules ont leur propre taille,
vitesse, dispersion et sensibilite au vent. Avant validation, la capture devra
donc mesurer separement :

- l'altitude de l'ancrage stabilise ;
- le sommet visuel et la base visible du nuage ;
- la continuite de la montee entre 1, 30, 120 et 600 secondes ;
- l'absence de saut, de reapparition au sol ou de redemarrage d'une phase ;
- la difference effective entre Little Boy et Fat Man.

Le prototype pilote maintenant une suite d'origines fixes ; la forme, la
dispersion et la vitesse interne des particules restent gerees par les fichiers
`.eff`. Ce comportement reste une adaptation du moteur, pas une simulation de
dynamique des fluides, et doit etre juge dans le jeu avant d'etre declare
realiste.

## Scenarios reproductibles prepares

Le generateur de mission rapide n'enregistre pas de mission nucleaire autonome.
Le dernier profil pilote conserve toutefois `B-29-SP=FatMan`. Il est plus sur
de reconstruire les scenarios ci-dessous dans le QMB que d'inventer un fichier
`.mis` non valide :

| Session | Carte | Appareil et emport | Manipulation obligatoire |
| --- | --- | --- | --- |
| Terre A | Smolensk | B-29 Silverplate + Little Boy | aucun arret, observer jusqu'a la phase suivante |
| Terre B | Smolensk | B-29 Silverplate + Little Boy, puis Fat Man | pause/reprise apres detonation, demi-tour complet, sortie puis retour dans le champ |
| Eau | Mer de Corail ou Okinawa | Little Boy puis Fat Man | impact sur l'eau, pause et acceleration temporelle |
| Dense | Smolensk | seize B-29 avec bombes atomiques | dix minutes minimum, puis temps accelere jusqu'au nettoyage |
| Reseau | mission validee precedente | hote puis client | seulement apres les quatre validations locales |

Chaque capture doit conserver la meme resolution, le meme profil graphique et
les memes options de mission au sein d'une comparaison. Les lignes
`Open Sturmovik nuclear:` doivent montrer un seul evenement par detonation, des
phases strictement croissantes, `created == destroyed`, zero echec de nettoyage
et zero etat actif a la fin du cycle. La memoire privee et virtuelle doit
revenir a un plateau apres la destruction des effets.

## Arret de securite actuel

La construction reproductible, le test de cycle de vie et la synchronisation
transactionnelle sont termines. Les vingt-trois empreintes installees sont
conformes et la sauvegarde est :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-nuclear-fixed-layers-20260903`.

Il reste a :

1. armer la capture ;
2. prevenir Alexis avant le lancement ;
3. lancer IL-2 seulement apres son accord ;
4. effectuer d'abord Little Boy sur terre pendant au moins 210 secondes sans
   pause ni demi-tour ;
5. analyser les couches visibles avant de poursuivre la matrice locale.

La copie obtient 46/47 controles de preparation. L'unique echec est la chaine
sonore Allison deja connue et independante du candidat nucleaire ; elle bloque
la qualification generale de la v1.15, mais pas l'observation ciblee des couches
du champignon. Aucun lancement n'a ete effectue avec ce candidat.

Le lancement doit etre annule si IL-2 est deja actif, si un fichier du dossier
de test change entre-temps ou si un nouveau controle echoue.

## Mise a jour apres le premier passage des couches fixes

Le candidat a maintenant ete lance une fois. Il valide la stabilite initiale,
mais la mission a pris fin a 28 secondes apres la detonation, deux secondes
avant la premiere couche fixe. Le resultat reste donc incomplet pour le rendu
par phases.

Les prochains passages ne doivent plus utiliser la vue suiveuse du bombardier.
Le premier passage avec les cameras a valide le point d'impact et la stabilite
du moteur, mais pas le cadrage : les vues placees a l'est regardaient a
l'oppose de la cible. Les quatre missions `Nuclear-*-Static-Cameras` fixent
desormais le point d'impact sur terre ou au-dessus de l'eau et proposent cinq
distances alignees a l'ouest de la cible. Le protocole devient :

1. lancer la mission dediee ;
2. activer le pilote automatique avec `A` si necessaire ;
3. revenir en vue avant et utiliser la commande de recentrage ;
4. passer aux cameras par `Ctrl+F2`, avant le largage si le cadrage est stable ;
5. conserver IL-2 au premier plan et ne plus basculer vers la conversation ;
6. observer Little Boy au moins 210 secondes sans pause ;
7. seulement apres validation, reproduire Fat Man avec le meme cadrage ;
8. repeter ensuite les deux armes au-dessus de l'eau ;
9. creer enfin une mission distincte avec jalons de distance pour qualifier
   les degats et le souffle sans polluer l'essai visuel.

La finesse de la colonne est un defaut candidat, pas encore une valeur a
corriger a l'aveugle. Le prochain cadrage fixe doit fournir l'echelle qui manque
avant de modifier `Size`, `EmitVelocity`, `EmitTheta` ou `EmitFrq`.

## Protocole de piste NTRK

Le second passage Little Boy a confirme la visibilite jusqu'a 42 secondes et la
creation de la couche de 30 s, mais la vue `F2` a suivi le bombardier. Le profil
de test utilise `F7` pour une cible terrestre et `F8` pour suivre l'objet
courant ; les prochaines consignes doivent respecter ces affectations reelles.

L'action `quickSaveNetTrack`, initialement sans touche, a d'abord ete liee par
erreur sous `[HotKey misc]`. La session du 3 septembre a 19 h 29 UTC n'a donc
produit aucune piste malgre l'appui sur `Ctrl+R`. Ce test invalide est conserve
dans `RESULTATS_TEST_NUCLEAIRE_2026-09-03.md` et ne doit pas etre compte comme
une panne NTRK du jeu.

L'outil `tools/Set-IL2QuickTrackBinding.ps1` place maintenant l'unique liaison
`Ctrl R=quickSaveNetTrack` sous `[HotKey $$$misc]`, refuse d'ecrire pendant que
le jeu fonctionne et valide la section apres ecriture. Le profil corrige a ete
sauvegarde sous
`Users/0/settings.ini.open-sturmovik-quick-track-20260903-213953.bak`.
Prochain protocole :

1. armer la capture et lancer Little Boy sur terre ;
2. activer le pilote automatique avec `A` ;
3. inventorier les `quick*.ntrk`, puis lancer l'enregistrement avec `Ctrl+R` ;
4. garder la detonation visible en `F2` pendant au moins 210 secondes ;
5. arreter la piste avec `Ctrl+R`, puis terminer la mission ;
6. verifier par date, taille et SHA-256 la creation du nouveau `quickNNNN.ntrk` ;
7. lire cette piste sans refaire le largage ;
8. utiliser `Ctrl+F2` pour les cameras statiques et `F7` pour la cible terrestre ;
9. repeter la lecture aux cadrages 1, 3,5, 6, 12 et 17 km ;
10. seulement apres cette calibration, lancer Fat Man puis les deux missions
    maritimes.

## Etat de preparation de la prochaine piste

Le deplacement du jeu de reference a ete confirme. Son chemin courant est
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\D:\Projets\GITHUB\#res\IL2 1946\0 - ORIGINAL GAMES DO NOT MODIFIED\Il-2 Sturmovik 1946 _4.09m` et les outils de
capture, de validation et de synchronisation l'utilisent desormais par defaut
en lecture seule.

Le precontrole cible obtient `Ready=True`, 47 controles sur 47. Il autorise
uniquement l'echec Allison deja connu afin de ne pas confondre ce son manquant
avec la validation visuelle nucleaire ; cet echec reste bloquant pour la sortie
globale v1.15. Le profil contient 46 pistes historiques et aucune piste
`quick*.ntrk`, ce qui donne une base non ambigue pour detecter le prochain
enregistrement.

L'etat complet, les empreintes des quatre missions, du profil de touches et des
rapports de preparation sont figes dans
`manifests/test/nuclear-ntrk-preflight-v1.15.json`. Aucun jeu ni capture n'a ete
lance pendant cette preparation. Le prochain lancement reste soumis a
l'avertissement d'Alexis et a un nouveau `go`.
