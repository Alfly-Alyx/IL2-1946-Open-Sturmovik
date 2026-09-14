# Outils sauvegardes pour Open Sturmovik

Derniere mise a jour : 4 septembre 2026.

Le dossier `D:\Projets\GITHUB\#res\IL2 1946\Outils` est une sauvegarde, pas
un repertoire de travail. Les copies actives et les sorties de compilation
restent sous `WIP/dependances/sdk/`.

L'inventaire controle se trouve dans
`manifests/tools/backup-tools-20260904.json`. Il couvre notamment :

- extraction, inspection et reconstruction SFS : SFS Extractor 3.1,
  SFS Manager 4.1, SFSA Packer, MikeTool et le code OpenIL2 ;
- inspection de `Buttons` : NTRK Wizard pour les Buttons 4.10 ;
- Java : CFR 0.152 pour decompiler et Temurin JDK 17.0.20+8 pour compiler ;
- Windows x86 : LLVM-MinGW 20260826 avec LLVM 23.1.0 et MSVCRT pour
  reconstruire le wrapper 32 bits ;
- archives : 7-Zip 26.02 et son extracteur autonome `7zr` ;
- formats IL-2 : ViewIMF, Msh ConverterEx, Msh Viewer et Actors Tool ;
- validation : Universal Static.ini Checker et HEdit.

La sauvegarde OpenIL2 est un bundle Git complet au commit
`63031643bd14c0f89255b97a9e954b552ed215f1`. L'archive JDK a ete testee avec
7-Zip : 492 fichiers, 317 543 400 octets apres extraction, aucune erreur.

LLVM-MinGW provient de la
[publication officielle 20260826](https://github.com/mstorsjo/llvm-mingw/releases/tag/20260826).
Son archive MSVCRT a ete testee avant extraction. La reconstruction de
`wrapper.dll` produit bien un PE32 i386 et le banc de test valide creation du
cache, reutilisation, invalidation apres ajout d'un fichier et recuperation
apres corruption.

Avant de supprimer une copie de travail, comparer son SHA-256 avec le manifeste.
Ne jamais ecraser silencieusement une archive portant le meme nom mais une
empreinte differente.
