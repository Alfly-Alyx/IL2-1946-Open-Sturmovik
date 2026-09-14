# Etat de reprise technique de la version 1.15

> **Document historique.** Le point d'entree obligatoire est desormais
> [`ETAT_COURANT_V1.15.md`](ETAT_COURANT_V1.15.md). Il fait autorite sur ce
> fichier lorsque les deux divergent. Le present fichier conserve les details
> techniques accumules et des etats intermediaires volontairement historiques.

## Candidat nucleaire actuel — couches fixes validees hors jeu

La capture complete
`WIP/tests/captures/startup/20260903-160537Z-profile9-warm-windowed1024-startup`
rejette le candidat precedent a emetteur mobile. Pendant le premier Little Boy,
un point du nuage montait rapidement tandis que la masse des particules restait
basse. Ce comportement est coherent avec le moteur : deplacer un `Eff3DActor`
deplace l'origine des nouvelles particules, mais pas les particules deja emises
dans le monde. Le premier evenement a dure environ 104 secondes et le second
22 secondes ; les deux sont restes entierement reactifs, sans exception Java
nucleaire ni croissance anormale de memoire.

La hauteur estimee de 3 a 4 km ne constitue pas un echec de la cible de 12 km :
a 104 secondes, la courbe implantee place l'ancrage Little Boy vers 4,2 km AGL.
Aucun essai n'a atteint les 600 secondes necessaires pour mesurer le sommet.
Le defaut confirme est la separation visuelle, pas la valeur finale.

Le remplacement construit dans le depot ne deplace plus aucun emetteur actif :

- la tete et le tore initiaux emettent pendant 60 secondes ;
- dix tetes fixes sont creees aux ages 30, 90, 150, 210, 270, 330, 390, 450,
  510 et 570 secondes, a l'altitude calculee pour cet age ;
- cinq tores fixes elargissent la coiffe a 90, 210, 330, 450 et 570 secondes ;
- chaque couche emet 60 secondes, puis ses particules disposent de 128 secondes
  pour s'eteindre naturellement ;
- le rattrapage ignore une couche deja expiree au lieu de creer une rafale ;
- le plafond est de 22 acteurs crees par explosion, quatre tetes de montee et
  deux tores actifs simultanement ;
- la couche stabilisee commence a 600 secondes, les acteurs de montee sont
  liberes a 728 secondes et tout le cycle est nettoye avant 3 728 secondes.

Deux constructions independantes sont identiques. Le cycle obtient 25/25,
l'audit nucleaire 42/42 et le controle global 19 PASS / 2 WARN / 1 FAIL. Le
candidat reste compatible avec le `rt.jar` Java 1.3.1 et le bytecode major 47.
Les altitudes des dix couches sont monotones et le budget de la mission a seize
bombes est verifie hors jeu. Les quatre classes de souffle et de degats sont
conservees octet pour octet. Ce
nouveau candidat n'est pas encore copie dans le dossier de test : conformement
a la regle de securite, une nouvelle synchronisation et tout lancement seront
annonces avant execution.

L'unique echec global est une anomalie distincte revelee par le meme journal : douze echecs de
`motor.Allison.start.begin`, douze de `motor.Allison.start.end`, un preset
`motor.Allison_V1700_series` invalide et 25 `FileNotFoundException`. Elle vient
du chargement sonore de la seconde mission et non de l'effet nucleaire. Le
controle verifie maintenant les trois presets runtime absents, les deux presets
`_tb` incomplets et leur WAV de fin lui aussi absent ; ce defaut ne peut plus
etre masque par un faux PASS.

## Banc A/B de particules valide — marqueur retire

Le troisieme lancement,
`WIP/tests/captures/startup/20260903-142458Z-profile9-warm-windowed1024-startup`,
valide le banc apres deux essais invalides dus aux chemins de matiere. La
capture contient 4 884 images sur 561,5 secondes. Le journal ne contient plus
aucune erreur de ressource et cree exactement les deux sondes attendues.

Observations en jeu :

- la sonde rouge de 64 particules et la bleue de 512 apparaissent toutes les
  deux avec une densite initiale voisine ;
- la rouge s'estompe plus vite et disparait alors que la bleue reste visible ;
- les deux reapparaissent simultanement une fois, puis la rouge recommence a
  s'estomper plus vite ;
- les retours frequents vers Codex font perdre le premier plan a IL-2 : cette
  reapparition commune peut provenir du culling ou du rechargement graphique et
  ne doit pas etre attribuee au cycle Java sans un essai futur sans perte de
  focus.

Les jalons 10, 60, 120, 130, 150, 180, 240 et 300 secondes sont tous atteints.
A 310 secondes, l'etat passe a `complete` avec `actors=0`, `created=8`,
`destroyed=8`, `ticks=310` et `rehydrates=0`. La reapparition observee n'a donc
pas ete provoquee par le mecanisme Java de rehydratation. Le processus est reste
reactif apres la detonation.

Conclusion : 64 particules ne suffisent pas a un composant majeur et persistant
du champignon. Le plafond moteur de 512 doit etre reserve aux couches visuelles
principales, avec un petit nombre d'acteurs simultanes pour proteger l'espace
x86. La coupure finale doit attendre la vidange naturelle de chaque phase ou
utiliser un effet de sortie borne plutot que detruire un nuage encore visible.

Le marqueur `_OS_TEST_NUCLEAR_PARTICLE_AB.enabled` a ete retire apres l'essai.
Les deux fichiers `.eff` restent inertes dans la copie de test et le rendu
nucleaire normal est de nouveau selectionne.

Au moment de ce banc, deux constructions etaient identiques, les treize classes
etaient en Java major 47, le cycle nucleaire obtenait 18/18, le banc A/B 8/8,
l'audit statique 41/41, le contenu de la copie de test 19 PASS / 2 WARN / 0 FAIL
et la preparation finale 47/47 (`Ready=True`). Le souffle et les degats etaient
inchanges.

Sauvegarde transactionnelle des classes remplacees :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.nuclear-particle-ab-backup-20260903-142012Z`.

Empreintes des deux effets corriges installes :

- A : `AD45E9925A63FFA70C28FE40C8EE23B4C65CD99E7921FB202290ED53B7E88850` ;
- B : `88D062389657CB18A1CB25F34CE654F64B8023E8938D3ABF106B8BF3642A556A`.

Le controle final a revele que `fb_maps15.SFS` avait change depuis le controle
reussi de 12 h 36 : meme taille et horodatage, mais 112 octets differents dans
un seul bloc autour de l'adresse 282 937 392. Cette variante inconnue a ete
sauvegardee dans
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.fb_maps15-backup-20260903-134100Z`,
puis la copie officielle 4.09m du depot a ete restauree. Son empreinte est
`AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9`.
Le jeu original n'a pas ete modifie.

Prochaine action : reporter cette mesure dans le prototype visuel par phases,
conserver 512 pour les couches principales, ajouter une marge de vidange avant
destruction et isoler plus tard la reapparition liee au focus. Aucun nouveau
lancement n'est programme sans avertissement prealable.

## Etat courant du 3 septembre 2026 — candidat teste, pause encore bloquante

La capture complete
`WIP/tests/captures/startup/20260903-124421Z-profile9-warm-windowed1024-startup`
valide en jeu le cockpit `CockpitB29SP` : vue F1 et instruments fonctionnels,
sans les anciens avertissements de morceaux manquants. Le Su-2 et les trois
appareils AAA restaures restent valides.

Les quatre detonations de la session n'ont produit ni gel, ni exception Java,
ni croissance memoire anormale. Little Boy et Fat Man restent verticaux. Le
Little Boy terrestre sans pause est encore clairement visible a +50 s. La
branche eau produit correctement une gerbe et aucun cratere.

La pause courte reproduit toutefois la reduction/reset visuel. Le battement de
reprise ne s'est pas declenche : la sequence figee visible dans la capture dure
environ 0,67 s, sous le seuil de 1,5 s, et le journal conserve
`rehydrates=0`. Abaisser le seuil ne reglerait pas le probleme de fond car
recreer un `.eff` le remet a l'age zero.

L'audit des effets etablit aussi que la gerbe d'eau est volontairement bornee a
environ 17 secondes (`FinishTime=2` puis `LiveTime=15`). `nParticles` est une
limite simultanee et non un stock consommable, mais les debits actuels ne
laissent coexister que 0,25 a 5,12 secondes d'emission sur plusieurs composants.
Le mode de recyclage natif doit etre mesure avant d'ajuster ces valeurs. La
prochaine correction doit fournir des effets de reprise propres a chaque phase
et a l'age logique. Elle sera construite et validee hors jeu avant toute
nouvelle synchronisation. Fat Man sur l'eau, la hauteur a 600 secondes, le
nettoyage final, la mission dense et le reseau restent a tester. Rapport
detaille : `docs/RESULTATS_TEST_NUCLEAIRE_2026-09-03.md`.

## Etat courant du 3 septembre 2026 — candidat suivant pret

Le nouveau candidat nucleaire est construit et synchronise dans
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`. Aucun lancement n'a ete
effectue apres cette synchronisation. La sauvegarde transactionnelle est
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260903-143540`.

Le correctif retire le surveillant natif a 25 ms. Un battement d'une seconde de
simulation detecte maintenant une reprise du rendu sans faire progresser l'age
logique pendant une pause. Il recree seulement les trois composants persistants
du panache a leur age courant, sans rejouer le flash, la boule de feu ou l'onde
initiale. Une courbe de montee relative au sol conduit le coeur visuel vers
12 000 m AGL pour Little Boy et 13 500 m AGL pour Fat Man a 600 secondes. Tous
les acteurs ont un nettoyage borne et l'etat doit etre libere avant 3 728 s.

Deux constructions independantes produisent les memes treize classes Java
major 47. Le test de cycle de vie obtient 18/18, l'audit nucleaire statique
41/41 et le controle global 19 PASS / 3 WARN / 0 FAIL. Les quatre classes de
souffle et de degats sont strictement inchangees afin d'isoler la correction
visuelle.

Le B-29 Silverplate utilise desormais son cockpit pilote `CockpitB29SP` et son
maillage dedie, qui contient les quatre morceaux absents du cockpit standard.
Le patch est idempotent, protege par empreintes et limite a `B_29SP` ; B-29
standard et KB-29P ne changent pas. Les 47 controles du profil 9, fenetre
1 024 x 768, retournent `Ready=True`.

Prochaine validation : charger le B-29 Silverplate et verifier son cockpit,
puis Little Boy sur terre sans pause, Little Boy avec pause et demi-tour, et
enfin Fat Man dans les memes conditions. Toujours armer la capture et prevenir
Alexis avant tout lancement.

## Mise a jour du 3 septembre 2026 — retest Su-2 et Little Boy

La capture
`WIP/tests/captures/startup/20260903-113213Z-profile9-warm-windowed1024-startup`
valide le Su-2 restaure : cockpit F1, commandes et postes fonctionnent, sans
erreur de chargement associee.

Little Boy est maintenant verticale, continue aux frontieres 30/120 secondes
et reste visible apres un demi-tour complet. La pause fait encore disparaitre
temporairement le panache, qui revient puis reprend sa montee. Le journal prouve
que l'etat logique survit : six acteurs restent enregistres sans destruction ni
recreation, et la transition 30 -> 120 secondes conserve exactement 90 secondes
de simulation malgre environ 29 secondes de pause reelle. Le defaut restant est
donc dans la conservation du contenu des particules natives, pas dans l'horloge
ni dans l'etat `NuclearBlast`.

La cible de 12 km n'est pour l'instant appliquee qu'a l'acteur stabilise cree a
600 secondes. La montee initiale depend toujours des vitesses des fichiers
`.eff` et n'est pas contrainte par une courbe hauteur/age. La prochaine version
du prototype doit fournir un coeur visuel persistant, reconstruire uniquement
la phase courante apres reprise et piloter hauteur et diametre par le temps de
simulation, sans rejouer le flash ni la boule de feu.

Les deux fenetres nucleaires restent repondantes et plafonnent a environ
704,3 Mio prives. Une pointe `Time overflow (2280)` suit la seconde detonation.
Douze avertissements B-29 concernent quatre morceaux de cockpit absents
(`zOilFlap1/2`, `zCompressor1/2`). `B_29SP` lie actuellement `CockpitB29` et
son ancien maillage, alors que la paire `CockpitB29SP`/`CockpitB29SP.him`
presente dans le depot contient les quatre morceaux attendus. Cette liaison est
le candidat de correction ; elle reste distincte du chantier nucleaire.
Fat Man, l'eau, l'acceleration temporelle et le nettoyage complet restent a
tester apres la prochaine correction visuelle. Rapport detaille :
`docs/RESULTATS_TEST_NUCLEAIRE_2026-09-03.md`.

## Mise a jour du 3 septembre 2026 — essai nucleaire

La capture `20260903-045354Z-profile9-warm-windowed1024-startup` confirme que
TBF-1C, TBM-3 et Pokryshkins MiG-3 sont presents et pilotables. Le paquet AAA
authentique du Su-2 a ete retrouve dans les ressources locales. Les deux fichiers
omis du poste arriere, `TGunnerSU2.him` et sa texture `skin1o.tga`, sont maintenant
restaures dans `Files` et integres aux controles reproductibles. Le Su-2 doit etre
resynchronise puis reteste en jeu ; il n'est pas encore valide pilotable.

Little Boy et Fat Man ne figent plus le jeu, mais le premier prototype par
phases produisait deux etats par bombe, omettait la rotation Silverplate de
90 degres et recreait les effets a 30 s. Cela explique le champignon horizontal
et son reset. Un second correctif hors jeu supprime le double appel, restaure
l'orientation et garde le panache continu aux frontieres 1/30/120 s. Il passe
16/16 validations de cycle et 39/39 controles statiques. Les quatre classes
modifiees sont synchronisees dans la copie de test avec la sauvegarde
`IL 2 Sturmovik 1946 test.sync-backup-20260903-073117` ; elles doivent maintenant
etre verifiees en jeu. Rapport detaille :
`docs/RESULTATS_TEST_NUCLEAIRE_2026-09-03.md`.

Derniere mise a jour : 2 septembre 2026, apres le gel Little Boy et sa correction statique.

Ce document est le point d'entree d'une nouvelle session de travail. Il separe
les faits observes, les causes demontrees, les corrections appliquees et les
hypotheses encore a verifier. Il doit etre mis a jour apres chaque correction ou
test important.

## Etat immediat du 2 septembre : paquet corrige, nouvel essai requis

La capture ciblee
`WIP/tests/captures/startup/20260902-180643Z-profile9-warm-windowed1024-startup`
a reproduit un gel definitif de Little Boy. Le journal isole un
`NoClassDefFoundError` sur `NuclearBlast$State`. Les noms libres SFS des deux
nouvelles classes internes etaient faux : ils ecrasaient les anciennes classes
`VisualAction` et `VisualData`. Les adresses corrigees sont
`8D53953C1956F06A` pour `NuclearBlast$PhaseAction` et `51AD1FEC90031C8A`
pour `NuclearBlast$State`.

Le constructeur verifie maintenant l'exhaustivite des classes generees et les
audits recalculent chaque adresse SFS depuis le nom Java. Deux constructions
independantes donnent douze classes identiques ; les 12 controles de cycle de
vie, les 39 controles nucleaires statiques, les 18 controles de contenu et les
47 controles de preparation passent. La copie de test a recu le paquet corrige,
les deux anciennes classes restaurees et les 25 fichiers AAA de TBF-1C, TBM-3
et MiG-3 Pokryshkin. La sauvegarde transactionnelle est
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260902-212957`.

La correction n'est pas encore validee dans IL-2. Le prochain passage doit
d'abord confirmer la presence des trois appareils restaures, puis rejouer
Little Boy sur Smolensk sans pause. Fat Man ne doit etre essayee qu'apres ce
premier critere de passage. Voir `RESULTATS_TESTS_CIBLES_2026-09-02.md`.

## Etat le plus recent : nuages bloques, charge IA stable, sons a corriger

La campagne complete est documentee dans
`RESULTATS_CAMPAGNE_MULTICARTES_2026-09-01.md`. Les traces sont dans
`WIP/tests/captures/startup/20260901-131015Z-profile9-warm-windowed1024-startup`.

Le nouveau bloquant principal est le moteur de nuages meteo : Slovakia et
Smolensk produisent des triangles/pics blancs, des volumes traversant le sol et
21 `RuntimeException` dans `EffClouds.PreRender`. Le `conf.ini` teste utilise
`TypeClouds=1`. La prochaine action sure est un A/B strict sur Smolensk avec
`TypeClouds=1`, puis `0`, puis un profil 4.09m stock. Ne pas confondre ce defaut
avec les panaches nucleaires : il apparait aussi sans bombe.

Le Su-2 de Berlin n'a pas ete affecte comme appareil joueur : `F2/F3`
fonctionnaient, mais pas `F1` ni les commandes. Trois `NullPointerException` de
`AircraftHotKeys$14.begin` ont ete declenchees sans appareil joueur valide.
L'audit statique montre pourtant un `SPAWN`, `FlightModels/Su-2.fmd` et trois
cockpits presents ; le profil `Su-2_AOC_1a.txt` a ete genere en vol. Le diagnostic
IA-only est donc abandonne au profit d'un retest de selection/affectation joueur.
Le meme symptome a ete observe sur un B-29 : tester separement B-29, B-29SP et
KB-29P, car leurs classes, FMD et cockpits ne sont pas identiques.

L'audit automatise couvre maintenant les 535 lignes uniques de `air.ini` : 535
classes d'appareil presentes, aucune classe de cockpit referencee absente et
aucune classe Java au-dessus de 47. Il trouve 516 declarations pilotables
directes, un candidat herite et 18 appareils probablement IA-only. Le doublon
exact `CW-21` a ete retire. Les deux anciennes variantes Sea Hurricane ont des
cles `Legacy` distinctes et leurs libelles i18n existent. Les ensembles AAA
authentiques TBF-1C, TBM-3 et MiG-3 Pokryshkin ont ete restaures dans `Files`,
sans encore declarer leurs FMD verifies dans `Buttons`. Les rapports sont
`AUDIT_APPAREILS_AIR_INI.md`, `AUDIT_AAA_COCKPITS_V1.15.md` et
`AUDIT_BUTTONS_MODELES_DE_VOL.md`.

Le stress Smolensk nuageux avec 16 B-29/Fat Man et 16 P-39D a produit plusieurs
largages et impacts sans ralentissement perceptible. Pendant le combat, zero des
898 echantillons processus etait non repondant. Pics : 852,3 Mio physiques,
720 Mio prives, 0,97 coeur CPU equivalent, environ 56,6 % du moteur GPU 3D et
178,6 Mio de memoire GPU validee. Ce resultat ne qualifie ni 1080p60, ni les
quatre coeurs, ni Windows x86.

Le meme stress a revele un preset `motor.Allison_V1700_series` invalide, 32
sample pools Allison de demarrage absents et 33 `FileNotFoundException`. Les
anciens presets sonores ne sont donc pas encore propres pour les P-39D en grand
nombre.

## Bombes nucleaires : chaine statique saine, rendu encore bloque

La session instrumentee
`WIP/tests/captures/startup/20260901-060621Z-profile9-warm-windowed1024-startup`
atteint la mission B-29 + Little Boy, reproduit deux fois le rattrapage visuel
apres pause et se termine volontairement sans exception Java nouvelle. Le
panache developpe a `06:12:28.621Z` est reduit a une petite sphere sur la
premiere image de reprise a `06:12:31.298Z`, puis retrouve un volume comparable
vers `06:12:36.785Z`. CPU, disque et memoire restent stables.

Le code du menu gele correctement `Time`, mais ne transmet pas cet etat a la
methode protegee `Eff3D.pause(boolean)` du moteur natif. Un premier candidat a
enregistre uniquement les emetteurs nucleaires, surveille la transition toutes
les 25 ms et propage la pause native par reflexion.

La campagne `20260901-131015Z-profile9-warm-windowed1024-startup` a maintenant
invalide ce candidat : Little Boy repart encore de zero apres pause/reprise. Le
meme redemarrage visuel survient apres un demi-tour qui retire puis remet le
panache dans le champ. Le probleme est donc lie au cycle rendu/culling des
particules, pas seulement a l'horloge de pause. Aucun message d'echec de la
reflexion n'est journalise : l'appel natif ne suffit simplement pas.

Les trois classes modifiees ont ete deployees dans le dossier de test, sans
lancer le jeu. Leur sauvegarde est :

`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260901-083925`

L'audit nucleaire dedie retourne 33 PASS et zero echec statique. Les douze
classes Java major 47, les deux `BombGun`, les deux emports du B-29SP, les huit
effets et tous leurs materiaux sont coherents. La sortie reste toutefois bloquee
par le rendu : le surveillant 25 ms n'a aucun benefice visuel prouve, les
`Eff3DActor` initiaux n'ont pas encore une duree de retention explicitement
bornee, et le nuage stabilise est place trop bas par rapport aux 40 000-50 000
pieds documentes. Voir `AUDIT_BOMBES_NUCLEAIRES_V1.15.md` et
`manifests/effects/nuclear-static-audit-v1.15.json`.

Fat Man a termine sa mission sans gel pendant la meme campagne. Le stress de
16 B-29/Fat Man a egalement termine sans ralentissement en vol perceptible, mais
il ne mesure pas encore le nombre d'acteurs d'effets retenus. Les airbursts sur
l'eau, l'eclair image par image et l'autorite multijoueur restent a tester.
Toujours prevenir Alexis avant capture et lancement.

Une anomalie distincte de cette mission est maintenant corrigee statiquement.
La surcharge libre `Files/Maps/Slovakia/load.ini` demandait l'ancien nom
`actors.static`, absent de la base 4.09m. La lecture directe de `fb_maps15.SFS`
a retrouve la ressource officielle `maps/slovakia/actors_summer.static`,
5 824 549 octets, SHA-256
`AB5980161F5B517A371B75E1F6721283826615A732A6043AD21CD7A7AED70A47`.
Le `load.ini` officiel 4.09m la demande aussi sous ce nom. Seule cette ligne a
donc ete corrigee ; le gros fichier reste dans le SFS et n'est pas duplique.
La version precedente du `load.ini` du dossier de test est sauvegardee dans
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260901-085130`.
Le prochain test doit confirmer zero `DAMAGED`, `FAILED` et
`FileNotFoundException` pour la carte Slovakia.

Decisions confirmees par Alexis : Little Boy et Fat Man ne sont que le premier
banc du correctif de pause. A terme, toute explosion de bombe, tout incendie et
toute fumee reproduisant le defaut devra etre prise en charge. La qualification
sur un Windows 32 bits reel est imperative pour l'objectif v1.15 ; le plafond
theorique x86 ne remplacera pas une campagne CPU/GPU/pilote/4GT mesuree.

## Perimetre et regles de securite

- Depot de travail reel :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik`.
- `D:\Projets\GITHUB\IL2-1946-Open-Sturmovik` est un lien vers ce depot.
- Jeu original de reference :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\D:\Projets\GITHUB\#res\IL2 1946\0 - ORIGINAL GAMES DO NOT MODIFIED\Il-2 Sturmovik 1946 _4.09m`.
  Ne jamais le modifier.
- Jeu de test :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\installations\IL 2 Sturmovik 1946 test`.
- Laboratoire Selector Dump :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\analyses\labs\IL 2 Sturmovik 1946 Selector Dump`.
- Ressources en lecture seule sauf accord explicite :
  `D:\Projets\GITHUB\#res\IL2 1946`.
- Les mods historiques retrouves doivent aller dans
  `D:\Projets\GITHUB\#res\IL2 1946\Mods`.
- Toujours prevenir Alexis avant de lancer le jeu ou une capture.
- La cible de la v1.15 reste IL-2 1946 4.09m modde. Le portage 4.15.1m est un
  chantier separe.

## Dernier test de reference

Le dernier lancement complet est conserve dans :

`WIP/tests/captures/startup/20260830-201020Z-selector-dump-cold-windowed1024-startup`

Le jeu a atteint le menu principal. Le Selector a extrait 10 201 ressources,
soit environ 604,2 Mio. Le temps mesure, fortement ralenti par l'instrumentation
et le Dump Mode, est de 209,9 secondes ; le menu est apparu vers 178,9 secondes.
Le pic de memoire est d'environ 907,2 Mio en working set et 1 598,8 Mio en
memoire privee. Le fichier a lire en premier est `logs/log.lst`.

L'introduction etait encore active (`Intro=1`). Les pourcentages observes
pendant ce test appartiennent donc en partie au chargement de la mission
d'introduction et ne constituent pas encore une cartographie pure du demarrage.

## Priorites immediates et etat prouve

| Priorite | Etat | Fait etabli ou prochaine action sure |
| --- | --- | --- |
| `Bf-109G-2/WheelTire.mat` | Corrige statiquement | Le fichier nul a ete remplace par un materiau texte coherent utilisant `../TEXTURES/wheels.tga`. Empreinte active `BA1D8713D743CBE4FA75E0702837B36B46988EA98BFECFBD7C3D41D419179EEB`. Le prochain lancement doit confirmer le prechargement du `hier.him`. |
| `ZutiTimer_ExtendPlanesWings` | Corrige statiquement | Le `checkcast Actor` premature a ete neutralise sans changer la taille ni la version Java 45. Empreinte active `70E039E839F092346CF8E4F06BA8431C3FF550237C6888D1BAE7B057E22D12C5`. Il reste le test de dix minutes et le test en mission MDS. |
| 17 appareils sans spawner | Corrige statiquement | `Plane.class` a ete reconstruit par union bytecode reproductible : 343 enregistrements `SPAWN`, Java major 47, empreinte `FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059`. Le Dump puis une mission doivent confirmer zero `No spawner`. |
| Six navires refuses | Corrige statiquement | Le `chief.ini` actif fusionne 426 sections 4.09m et 78 extensions communautaires, sans doublon, dont les six types refuses. Empreinte `14E9D0CE1C3B991FF3C43D9643F4744439126F690B3E294BA27EF1B18786AD8D`. Validation runtime encore requise. |
| Presets sonores | Valides au second demarrage | Les 26 collisions de noms ont ete supprimees. Les petits presets SAS refuses ont ete remplaces par dix mixeurs complets Tiger33 4.09m et leurs WAV, avec manifeste d'empreintes. Le second lancement a confirme zero `Invalid preset format` jusqu'au menu ; l'ecoute en vol reste a faire. |
| Trois WAV absents | References corrigees | Les anciens noms introuvables ne sont plus demandes : Allison utilise `Allison_tb_XX_Starter.wav`, MG FF exterieur `MG_FFx.wav` et cockpit `MG_FF.wav`. Les deux MG FF sont actuellement identiques au niveau binaire, ce qui rend la substitution conservative. |
| 28 `FileNotFoundException` | 28 attribuees et corrections preparees | 26 venaient des presets Sakae/P&W ; une de l'introduction defectueuse ; la derniere de `AirportCarrier.clsBigArrestorPlane` quand `TBM1.class` demandait deux maillages inexistants. La classe TBM-1 pointe maintenant vers les `hier.him` Multi1 et USA confirmes dans `fb_3do08p.SFS`, empreinte `BFAC0C3D60CB49DB6D857362196B79305E9D4AE5665E06146E8C30D374374C6B`. |
| Introduction | Desactivee pour la v1.15 | `Intro=0` dans le profil de test evite la piste defectueuse, ses erreurs reseau et sa `NumberFormatException`. La piste est conservee pour analyse/reparation ulterieure, mais ne bloque plus le demarrage normal. |
| 63 `Str2FloatClamp` au demarrage | Corrige statiquement | Les neuf bornes affichees par le moteur ont ete appliquees a tout le contenu libre : 179 valeurs dans 168 effets. Une surcharge corrige l'effet restant dans `files.SFS` sans repaqueter l'archive. Le rendu runtime est conserve puisque le moteur utilisait deja ces valeurs bridees. |
| `air.ini` / `stationary.ini` / `Buttons` | Ensemble statique coherent | `air.ini` et `stationary.ini` actifs correspondent aux references 4.09m du selecteur ; `Buttons` est present et le registre `Plane.class` couvre les classes dumppees. Une mission representative reste obligatoire pour prouver la correspondance des modeles de vol. |

### Les 17 classes d'appareils non enregistrees

`CW_21`, `DXXI_DK`, `DXXI_DU`, `I_15BIS`, `I_15BIS_SKIS`, `I_16TYPE5`,
`I_16TYPE5_SKIS`, `I_16TYPE6`, `I_16TYPE6_SKIS`, `AVIA_B534`,
`DXXI_SARJA3_EARLY`, `DXXI_SARJA3_LATE`, `DXXI_SARJA4`, `G_55`, `RE_2000`,
`LetovS_328`, `SM79i`.

### Les six navires refuses par l'introduction

`USSEssexCV9`, `IJNAkagiCV`, `IJNKageroDD41`, `IJNAkizukiDD42`,
`USSIndianapolisCA35`, `USSFletcherDD445`.

## Ressources et outils deja retrouves

Le dossier `D:\Projets\GITHUB\#res\IL2 1946\Outils` contient notamment :

- SFS Extractor V3.1 ;
- SFS Manager V4.1 ;
- SFS Packer/SFSA V1.1.0.1 ;
- NTRK Wizard pour Buttons 4.10 ;
- IL-2 Extractor de SAS~Storebror, compatible avec les SFS dits `benito` ;
- Universal `static.ini` Checker V1.3 ;
- Actors Tool V1.5.

Ne pas executer aveuglement ces anciens binaires dans le jeu original. Les
extraire et lire leurs instructions dans un laboratoire ou un dossier temporaire
avant usage.

Pages historiques deja recuperees :

- [AAA Unified Installer v1.0, archive du 7 janvier 2009](https://web.archive.org/web/20090107030230/http://allaircraftarcade.com/forum/viewtopic.php?t=7688)
- [AAA 4.09b1m mod patch/switcher, archive du 1er janvier 2008](https://web.archive.org/web/20080101055533/http://allaircraftarcade.com/forum/viewtopic.php?t=1932)

Le fichier de collection
`C:\Users\Alexis\Downloads\32372-IL-2-Complete-Edition.zip` n'est pas le jeu
complet. Il fait 57 397 462 octets, contient 1 068 entrees (environ 120,8 Mio
decompressees) et a pour SHA-256
`9A0717E9AA721A25DA14DC88BF3D2A6A04BDB9DD79ABC862FF0C5D518293DCA9`.
Il fournit des presets sonores historiques de compatibilite SAS Buttons, mais
pas les trois WAV absents, le materiau du Bf-109G-2 ni la classe Zuti corrigee.

## Ordre de reprise recommande

1. Conserver le resultat courant : 15 `PASS`, zero `FAIL`; le seul `WARN` exige
   un Dump runtime. Les 45 controles de disponibilite passent dans la copie.
2. Trois passages corriges ont atteint le menu : environ 130,7 secondes lors de
   la reference, 171,5 secondes avec 78 % de charge CPU systeme moyenne, puis
   94,4 secondes avec 34 % de charge moyenne et un cache chaud.
   Utiliser `RESULTATS_TESTS_DEMARRAGE_2026-08-31.md` comme reference.
3. Prevenir Alexis, armer la capture, puis lancer le jeu seulement apres
   l'affichage `CAPTURE_ARMEE`.
4. La correction `LandGeom=2` confirme zero reecriture de `conf.ini`. Les deux
   lignes Perfect sont l'avis attendu du detecteur 4.09m lorsque l'ancienne
   extension `GL_NV_texture_shader` manque ; utiliser le rapport graphique
   automatique plutot qu'une nouvelle matrice de profils.
5. Comparer automatiquement `log.lst`, `sound.log`, le Dump et les acces fichiers
   au test de reference.
6. Si le demarrage est propre, preparer le scenario de bug critique en vol, puis
   charger une mission minimale avec TBM-1, les 17
   appareils statiques et les six navires, puis valider `Buttons`/modeles de vol.

## Definition de termine pour cette passe

- zero erreur de materiau Bf-109G-2 ;
- zero exception Zuti durant au moins dix minutes puis en mission ;
- zero `No spawner` ;
- zero `Wrong chief's type` dans une introduction reparee ou une mission de test ;
- zero collision effective de preset son ;
- chaque fichier audio demande existe ;
- chaque `FileNotFoundException` est supprimee ou documentee comme repli
  volontaire prouve ;
- `air.ini`, `stationary.ini`, `Plane.class`, `Ship.class` et `Buttons` proviennent
  d'un ensemble de version coherent et reproductible.

## Controle statique reproductible

Lancer depuis la racine du depot :

```powershell
.\tools\Test-OpenSturmovikContent.ps1
```

Au 31 aout 2026, le resultat sans Dump est **15 PASS, 1 WARN, 0 FAIL**. Le WARN
ne signale pas une anomalie de contenu : il rappelle que les classes effectives
du jeu ne peuvent etre prouvees qu'avec `-DumpRoot` apres la prochaine capture.

La preparation exacte de cette prochaine capture et la synchronisation
transactionnelle sont consignees dans
[`PREPARATION_PROCHAIN_TEST_V1.15.md`](PREPARATION_PROCHAIN_TEST_V1.15.md).
Les synchronisations ont ete appliquees avec des sauvegardes recuperables. Les
trois demarrages ont atteint le menu sans crash ; les deux derniers ont valide
les presets Tiger33. Le troisieme a atteint le menu en 94,4 secondes et conserve
`conf.ini` octet pour octet. Les 45 controles de disponibilite passent. Les
deux lignes Perfect ont ete expliquees hors jeu par l'absence de
`GL_NV_texture_shader` sur Intel et sont desormais classees automatiquement.
