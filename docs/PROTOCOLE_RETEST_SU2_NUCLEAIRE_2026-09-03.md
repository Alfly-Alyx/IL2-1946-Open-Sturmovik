# Protocole de retest Su-2 et bombes nucleaires — 3 septembre 2026

## Etat prepare

- cible : copie de test uniquement ;
- profil : 4.09m modde, profil 6DOF historique, OpenGL natif ;
- affichage : 1024 x 768, fenetre ;
- profil graphique : haute qualite securisee Intel x86 ;
- affinite : quatre coeurs physiques au maximum, masque `85` ;
- journal, journal d'evenements et dessin hors focus : actives ;
- contenu : 18 controles PASS, 3 avertissements connus, aucun echec ;
- sauvegarde avant restauration Su-2 :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-backups\IL 2 Sturmovik 1946 test.sync-backup-20260903-132243`.

La capture doit inclure les performances a 100 ms, les images a 10 Hz, les
journaux et les empreintes des classes et ressources Su-2/nucleaires. Le jeu ne
doit etre lance qu'apres le message explicite indiquant que la capture est armee.

## Test 1 — Su-2

Dans l'Editeur de mission complet, placer un `Su-2` sovietique en vol et cocher
`Player`. Eviter un depart au sol pour ne pas melanger ce controle avec un
probleme d'affectation ou de procedure moteur.

1. Demarrer la mission et attendre dix secondes sans toucher aux commandes.
2. Confirmer que F1 ouvre le poste pilote.
3. Tester roulis, tangage, lacet et gaz pendant trente secondes.
4. Utiliser `C` pour parcourir le poste bombardier puis le poste mitrailleur.
5. Au poste arriere, bouger la vue et tirer une courte rafale.
6. Revenir au pilote, larguer une bombe conventionnelle si l'emport le permet,
   puis quitter seulement la mission.

Critere de passage : appareil controlable, trois postes accessibles, aucune
`RuntimeException`, aucune ressource cockpit absente et aucun blocage.

## Test 2 — Little Boy, temoin sans pause

Utiliser le B-29 Silverplate sur une carte terrestre, de preference Smolensk,
avec Little Boy. Effectuer la detonation sans mettre le jeu en pause et sans
quitter l'effet des yeux pendant au moins 150 secondes.

Verifier :

- flash initial visible ;
- champignon vertical et centre sur l'impact ;
- montee continue au-dela de 30 puis 120 secondes ;
- aucun retour a une petite explosion et aucun redemarrage du nuage ;
- jeu reactif et memoire stabilisee.

## Test 3 — Little Boy, pause et culling camera

Recommencer Little Boy. Mettre en pause environ vingt secondes apres l'impact,
attendre cinq a dix secondes, reprendre, puis effectuer un demi-tour complet de
la camera vers 45 secondes avant de revenir sur le champignon. Observer de
nouveau jusqu'a au moins 150 secondes.

Critere de passage : l'effet reprend a son age logique, sans repartir de zero,
sans disparaitre definitivement et sans changer d'orientation.

## Tests 4 et 5 — Fat Man

Reproduire successivement le temoin sans pause, puis le scenario pause/demi-tour
avec Fat Man. Les criteres sont identiques. Sa geometrie peut etre plus ample,
mais son sommet cible est d'environ 13,5 km contre environ 12 km pour Little Boy.

## Arret immediat et signalement

Interrompre la mission et signaler l'instant approximatif si l'un des cas
suivants apparait :

- gel ou boite « laisser le programme repondre » ;
- champignon couche a 90 degres ;
- retour visible au debut de l'animation ;
- disparition apres pause ou demi-tour ;
- perte du cockpit Su-2, des commandes ou d'un poste ;
- nouvelle erreur affichee par le jeu.

Ne pas fermer immediatement le processus en cas de gel : laisser quelques
secondes a la collecte, puis suivre la consigne donnee pendant la session.
