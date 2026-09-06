# Ameliorations du jeu

Ce dossier racine unique regroupe les composants qui ameliorent IL-2 pendant
son execution, qu'ils soient charges par le moteur ou actifs en parallele.

- `San's IL2 FOV Changer` agit sur le champ de vision pendant l'execution du jeu.
- `Gapa` agit en parallele sur la courbe gamma/LUT de l'affichage Windows.
- `Mod_AOC_Public` contient les profils du module moteur AOC 1a ; ses trois
  classes chargeables restent necessairement sous `Files`, mais leur chargeur
  lit et cree les profils dans ce dossier.

Cette reunion est une regle d'organisation de la v1.15. Elle ne signifie pas
que les trois composants partagent le meme mecanisme de chargement.

San FOV et Gapa restent desactives par defaut jusqu'a validation sur une
installation de test. AOC est charge par les classes libres de la v1.15.
