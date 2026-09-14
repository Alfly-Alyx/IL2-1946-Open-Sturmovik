# Ameliorations du jeu

Ce dossier racine unique regroupe les composants qui ameliorent IL-2 pendant
son execution, qu'ils soient charges par le moteur ou actifs en parallele.

- `Gapa` agit en parallele sur la courbe gamma/LUT de l'affichage Windows.
- `Mod_AOC_Public` contient les profils du module moteur AOC 1a ; ses trois
  classes chargeables restent necessairement sous `Files`, mais leur chargeur
  lit et cree les profils dans ce dossier.

Cette reunion est une regle d'organisation de la v1.15. Elle ne signifie pas
que ces composants partagent le meme mecanisme de chargement.

Gapa reste desactive par defaut jusqu'a validation sur une
installation de test. AOC est charge par les classes libres de la v1.15.

San FOV Changer est retire du paquet faute de preuve d'autorisation de
redistribution. Ses fichiers et notices sont archives localement hors du jeu ;
les reglages DeviceLink et FOV du joueur restent conserves.
