# Stockage des captures et sauvegardes locales

Derniere mise a jour : 4 septembre 2026.

Les donnees lourdes produites pendant les essais doivent rester dans le dossier
reel du projet, sans etre envoyees dans Git :

- `WIP/captures/` : captures, journaux, mesures, dumps et traces de sessions ;
- `WIP/test-backups/` : sauvegardes transactionnelles du jeu de
  test auparavant creees sur le Bureau ;
- `WIP/test-installations/` : installations de test actives ;
- `WIP/resources/IL2/` : ressources utilisateur deplacees du
  Bureau, y compris la reference originale protegee ;
- `WIP/labs/` : copies de laboratoire, dont le clone Selector Dump ;
- `WIP/sdk/` : outils, dependances et sorties regenerables.

Ces repertoires sont ignores par Git. Leurs rapports legers, manifestes,
empreintes et conclusions restent versionnes sous `docs/` et `manifests/`.

Le jeu de test actif se trouve desormais sous
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test`.
Le jeu original se trouve sous
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\resources\IL2\IL 2 Sturmovik 1946`
et reste strictement en lecture seule.

Le dossier `WIP/resources/IL2` est la zone d'apport utilisateur
deplacee du Bureau sur demande explicite. Son contenu ne doit etre ni modifie ni
nettoye sans demande explicite et doit d'abord etre inventorie en lecture seule.
Les paquets peuvent rester en `.zip`, `.rar` ou `.7z` : l'archive originale est
la reference a conserver. L'analyse lit si possible la table interne sans
extraction ; si une extraction est necessaire, elle se fait dans une copie
temporaire sous `WIP/`, jamais par reecriture de l'archive source.
Une version decompressee fournie par Alexis peut etre comparee a l'archive, mais
ne remplace pas cette derniere comme preuve de provenance.

Le depot `D:\Projets\GITHUB\IL2-1946-Open-Sturmovik` est un lien symbolique ;
les donnees sont donc physiquement rangees dans
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik` et un deplacement
de `C:` vers le chemin `D:` ne libere pas d'espace disque.

Etat releve avant rangement :

- `WIP/captures/` : environ 95,8 Gio et 231 071 fichiers ;
- `WIP/sdk/` : environ 22,0 Gio et 132 746 fichiers ;
- jeu de test actif : environ 24,7 Gio ;
- ressources utilisateur : environ 68,1 Gio et 49 670 fichiers ;
- 22 sauvegardes de test sur le Bureau : environ 25,2 Gio au total, dont une
  sauvegarde complete de 24,9 Gio et une copie de `fb_maps15.SFS` de 0,32 Gio.
- laboratoire Selector Dump auparavant sur le Bureau : 151 802 fichiers et
  environ 25,3 Gio.

Apres rangement, les 22 sauvegardes se trouvent sous
`WIP/test-backups/` et le laboratoire sous
`WIP/labs/IL 2 Sturmovik 1946 Selector Dump/`. Aucun de ces dossiers
n'est suivi par Git.

Le 4 septembre 2026, le jeu de test (141 653 fichiers, environ 24,71 Gio) et la
zone de ressources (49 670 fichiers, environ 68,07 Gio) ont ete deplaces hors du
Bureau, sans copie intermediaire et sans modifier leur contenu. Les deux anciens
chemins du Bureau n'existent plus. Les anciens rapports conservent volontairement
leurs chemins historiques afin de rester des preuves fideles de chaque session.

Regles :

1. ne pas placer les captures dans le depot Git suivi ;
2. ne pas supprimer une session brute tant que son manifeste et sa conclusion
   ne sont pas verifies ;
3. ne pas creer une copie complete du jeu pour une modification de quelques
   fichiers : sauvegarder seulement les cibles remplacees ;
4. donner a chaque sauvegarde un identifiant UTC et conserver la liste des
   chemins et empreintes ;
5. deplacer ou supprimer une sauvegarde seulement apres resolution exacte du
   chemin et verification qu'elle n'est pas le jeu actif ou le jeu original ;
6. si l'espace manque, conserver en priorite journaux, dumps, mesures,
   manifestes et images jalons plutot que chaque image intermediaire identique.

## Rangement du 4 septembre 2026

Les anciennes racines `test-results/`, `build/`, `tmp/` et `local-artifacts/`
ont ete regroupees dans la structure unique `WIP/` decrite par
`docs/ORGANISATION_WIP.md`.
Dans l'etat courant, il ne subsiste plus de dossier lourd de travail a la
racine du depot.

L'ancien worktree nucleaire, propre et deja integre a `v1.15`, a ete supprime :
129 049 fichiers et environ 21,21 Gio ont ete liberes. Le worktree actif du
lanceur a ete conserve avec ses changements locaux puis range sous
`WIP/worktrees/launcher`.

Six doublons locaux d'archives ou de pages de provenance ont ete supprimes
uniquement apres comparaison SHA-256 avec leur sauvegarde sous
`D:\Projets\GITHUB\#res\IL2 1946`. Cela represente environ 349 Mio
supplementaires. Les captures documentees, les ressources, le jeu original et
le jeu de test n'ont pas ete supprimes.

## Nettoyage verifie du 4 septembre 2026

La sauvegarde complete
`IL 2 Sturmovik 1946 test.backup-before-clean-20260830` contenait 144 420
fichiers et 26 725 181 698 octets. Une comparaison SHA-256 avec le jeu de test
actif et le jeu original protege a etabli que 144 172 fichiers etaient des
doublons exacts. Les 248 fichiers differents, soit seulement 976 717 octets,
ont ete recopies avec leur arborescence dans
`WIP/test-backups/backup-before-clean-20260830.delta`, puis chaque copie a ete
rehachee avant la suppression de la sauvegarde complete. Le dossier de
sauvegardes est ainsi passe d'environ 25,2 Gio a 0,32 Gio sans perdre le
differentiel historique.

La copie de `fb_maps15.SFS` du 3 septembre a ete conservee : son SHA-256
`5D71D28C49B762CD0CE5B6F298D0EF18587E4AEA4839F6CAFBF09A1026FA74A4`
differe de la version actuelle et n'a pas ete retrouve dans les revisions Git
connues. Elle ne doit pas etre supprimee tant que sa provenance fonctionnelle
n'a pas ete determinee.

Les extractions temporaires reproductibles de Tiger33, des outils SFS et des
anciens essais de compilation ont ete supprimees de `WIP/tmp` apres verification
de leurs archives sources. Ce dossier ne contient plus qu'environ 3,9 Mio de
petits artefacts encore utiles.

Alexis a autorise le tri prudent des captures le 4 septembre 2026. Les seize
traces Process Monitor de sessions chaudes ou de vols prolonges, soit exactement
63 660 459 237 octets, ont ete supprimees apres controle de chaque chemin et de
chaque taille contre `manifests/diagnostics/capture-pruning-20260904.json`. Les
quatre fichiers PML des trois sessions de reference a froid ont ete conserves.

Apres ce tri, `WIP/captures` contient 254 848 fichiers et 41 217 659 829
octets (environ 38,39 Gio). Les principaux postes restants sont 20,36 Gio de
JPEG, 8,84 Gio de PML de reference et 8,24 Gio de dumps memoire. Les JPEG
forment les chronologies visuelles des essais nucleaires et les dumps couvrent
encore des blocages non resolus : ils restent conserves jusqu'a production et
validation d'un substitut plus compact ou jusqu'a classification individuelle.

Les preuves structurees se trouvent dans
`manifests/diagnostics/backup-cleanup-20260904.json`.
