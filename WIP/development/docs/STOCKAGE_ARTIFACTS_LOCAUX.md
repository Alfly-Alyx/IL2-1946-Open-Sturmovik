# Stockage des artefacts locaux

Derniere mise a jour : 13 septembre 2026.

Les donnees locales sont separees des fichiers du jeu :

- `WIP/tests/captures/` contient les traces, journaux, images, dumps et mesures ;
- `WIP/tests/backups/` contient les sauvegardes transactionnelles ;
- `WIP/tests/installations/` contient les copies executables de test ;
- `WIP/analyses/` contient les laboratoires et les sources d'analyse ;
- `WIP/dependances/` contient les outils et SDK locaux ;
- `WIP/temporaire/` contient les extractions regenerables ;
- `WIP/development/` contient les sources versionnees de fabrication et de
  controle du projet.

Le jeu de test actif est :

`D:\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\installations\IL 2 Sturmovik 1946 test`

Le dossier `WIP/resources` n'existe plus. Les ressources de provenance sont
conservees sous `D:\Projets\GITHUB\#res\IL2 1946`.

## Nettoyage verifie du 13 septembre 2026

Quatre arborescences de `WIP/resources` ont ete comparees a leurs sources
canoniques : AAA Community Installer 1.1, Canvas Knights Full Game, Canvas
Knights WWI Assets et la copie IL-2 1946 de reference. Les 49 719 fichiers
correspondants avaient les memes chemins relatifs, tailles et SHA-256.

Le ZIP CW-21 avait le meme SHA-256 que
`#res\IL2 1946\Mods\Utilises\Cockpit_CW-21_for409.zip`. Son extraction locale
et sa copie ont donc ete retirees.

Sept archives uniques, totalisant 55 765 024 050 octets, ont ete deplacees vers
les dossiers correspondants de `#res` avant le nettoyage : IL-2 Sturmovik 2001,
Forgotten Battles, IL-2 Sturmovik 1946, Pacific Fighters, HSFX, TFM et
Ultrapack. Chaque empreinte SHA-256 est consignée dans
`../manifests/resources/wip-resources-cleanup-20260913.json`.

Au total, 49 891 fichiers et 17 323 998 414 octets de doublons ou d'extractions
reproductibles ont ete retires de `WIP/resources`.

## Regles de conservation

1. Une sauvegarde differente reste conservee tant que sa fonction n'est pas
   identifiee.
2. Une copie complete n'est retiree qu'apres comparaison de tous ses fichiers
   avec une source conservee.
3. Les rapports, empreintes et conclusions restent sous
   `WIP/development/manifests` ou `WIP/development/docs`.
4. Les captures brutes restent disponibles tant que l'anomalie qu'elles
   documentent n'est pas resolue.
5. Les worktrees d'autres taches ne sont jamais deplaces ni nettoyes.

## Historique conserve

Le 4 septembre 2026, une sauvegarde complete du jeu de test a ete reduite a un
delta de 248 fichiers apres comparaison de 144 420 fichiers. La sauvegarde
`fb_maps15.SFS` du 3 septembre reste conservee, car son SHA-256
`5D71D28C49B762CD0CE5B6F298D0EF18587E4AEA4839F6CAFBF09A1026FA74A4`
differe de la version actuelle. Les preuves correspondantes se trouvent dans
`../manifests/diagnostics/backup-cleanup-20260904.json`.