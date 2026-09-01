# Catalogue des mods historiques et sources AAA

## Objectif

Ce catalogue sert a retrouver la provenance des composants reunis dans Open
Sturmovik entre 2006 et 2010. Les archives telechargees sont conservees hors du
depot Git dans :

`D:\Projets\GITHUB\res\IL2 1946\Mods`

Aucun fichier retrouve n'est copie automatiquement dans l'add-on. Il doit etre
identifie, compare, teste sur une copie et documente avant integration.

## Informations conservees pour chaque paquet

- nom, auteur, version, date et nom de fichier d'origine ;
- page AAA et capture Wayback ;
- URL de telechargement d'origine et archive eventuelle ;
- taille et SHA-256 du fichier recupere ;
- base IL-2 requise et autres dependances ;
- ordre d'installation historique ;
- inventaire des fichiers fournis et des chemins ecrases ;
- licence ou permission de redistribution connue ;
- correspondance avec les fichiers actuels d'Open Sturmovik ;
- anomalies corrigees, conflits et decision finale.

## Sources AAA retrouvees

### Unified Installer 1.0

- page AAA archivee le 7 janvier 2009 :
  [Unified Installer Version 1.0](https://web.archive.org/web/20090107030230/http://allaircraftarcade.com/forum/viewtopic.php?t=7688) ;
- fichiers annonces :
  `AAA_Community_Installer_ver_1_0_part01.exe`, puis les parties `02` a `04`
  en RAR ;
- l'index Wayback conserve plusieurs pages du telechargeur pour la premiere
  partie, mais celles-ci sont de petites pages HTML et non le binaire complet ;
- statut : provenance confirmee, archives completes encore a retrouver.

### Patch modde 4.09b1m et switcher 4.08m/4.09b

- page AAA archivee le 1er janvier 2008 :
  [4.09b1m Patch MOD Version & 4.08m to 4.09bm Switcher](https://web.archive.org/web/20080101055533/http://allaircraftarcade.com/forum/viewtopic.php?t=1932) ;
- fichiers annonces : `409_MOD_b1m.exe` et
  `IL2_Mod_Switcher_4_08m_to_4_09bm.exe` ;
- cette page explique l'origine probable de la structure multiversion
  historique encore presente dans Open Sturmovik ;
- statut : pages et noms confirmes, binaires a retrouver et comparer.

## Recherches prioritaires issues du premier Dump

| Famille | Signatures recherchees | But |
|---|---|---|
| Bf-109G-2 | `3DO/Plane/Bf-109G-2/WheelTire.mat` | Retrouver le materiau d'origine ; le fichier actuel ne contient que des octets nuls |
| Sons moteur | DB-600, Rolls-Royce Merlin, Sabre, Sakae et Pratt & Whitney R-2800 | Retrouver des presets compatibles avec le moteur sonore 4.09m |
| Sons manquants | `Allison_XX_Starter.wav`, `mg__ffe.wav`, `mg__ffi.wav` | Completer les references deja presentes dans les presets |
| Zuti/MDS | `ZutiTimer_ExtendPlanesWings` et dependances | Identifier la version exacte et la correction de la `ClassCastException` |
| Appareils | CW-21, D.XXI, I-15bis, I-16 type 5/6, Avia B-534, G.55, Re.2000, Letov S-328, SM.79 | Reconstituer le paquet de classes et son ordre d'enregistrement |
| Navires | Essex, Akagi, Kagero, Akizuki, Indianapolis, Fletcher | Reconstituer les classes, registres et mission d'introduction compatibles |

## Miroir secondaire analyse

### `32372-IL-2-Complete-Edition.zip`

- page : [miroir Avsim.su](https://www.avsimsu.com/f/igra-il-2-105/vertolet-dlya-il-2-32372.html) ;
- fichier de collection :
  `C:\Users\Alexis\Downloads\32372-IL-2-Complete-Edition.zip` ;
- taille : 57 397 462 octets, soit 54,7 Mio ;
- SHA-256 :
  `9A0717E9AA721A25DA14DC88BF3D2A6A04BDB9DD79ABC862FF0C5D518293DCA9` ;
- contenu : 1 068 entrees et 120,8 Mio non compresses ;
- le nom est trompeur : il ne s'agit pas d'une installation complete du jeu,
  mais d'un paquet communautaire avec une arborescence `IL-2 Complete Edition`,
  des presets de compatibilite sonore et deux mods d'helicopteres ;
- il ne contient ni les trois WAV manquants, ni le materiau Bf-109G-2, ni la
  classe Zuti recherchee ;
- il contient dix presets de demarrage generiques pour DB-600, Merlin, Sabre,
  Sakae et Pratt & Whitney R-2800, dates du 15 juin 2009 ;
- son fichier d'instructions dit explicitement que ces presets rendent les
  sons compatibles avec SAS Buttons et avertit contre les definitions sonores
  multiples dans `MODS` et `Files`.

Comparaison avec Open Sturmovik : 185 fichiers `.prs` sont presents ; 26 noms
existent plusieurs fois et 24 de ces noms correspondent a des contenus
differents. Les collisions touchent notamment DB-600, DB-601, DB-603, DB-700,
Merlin, Sabre, plusieurs Pratt & Whitney et six presets d'armes. Cette priorite
de chargement doit etre reconstruite avant de remplacer les fichiers au hasard.

Decision appliquee puis corrigee apres essai : les definitions concurrentes de
premier niveau ont ete retirees au profit de `Files/presets/sounds`. Le premier
test runtime a cependant prouve que les dix petits presets generiques du paquet
etaient incomplets pour ce moteur : six d'entre eux ont produit
`Invalid preset format` pendant le prechargement. Ils ne servent donc plus de
source active. Les trois anciens noms WAV introuvables ont ete remplaces par des
echantillons locaux verifies ; ce paquet n'etait pas leur source.

### Tiger33 Ultimate Sound Mod V3

- publication principale : [Tiger33 Ultimate Sound Mod V3 sur SAS1946](https://www.sas1946.com/main/index.php?topic=3258.0) ;
- compatibilite annoncee par l'auteur : 4.09m avec UP 2.01, plus profils separes
  pour UP3/DBW et HSFX 6 ;
- l'installation complete demande le paquet JSGME/readme **et** les deux archives
  SFS sonores ;
- liens MediaFire historiques encore accessibles au 31 aout 2026 :
  [JSGME et documentation](https://www.mediafire.com/download/jzlu95c8mlb1sc1/UV3_JSGME+ReadMe(2).rar)
  et [archives SFS](https://www.mediafire.com/download/e05zc2coigf39cq/UV3_SFS.rar).

| Archive recue | Taille | SHA-256 | Contenu controle |
|---|---:|---|---|
| `UV3_JSGME_ReadMe.rar` | 20 844 939 | `2E0F495973C250823952A6E578437057C4422C58FD8E1E4CD4D0D3A029856CE9` | Trois RAR de profils et deux PDF anglais/francais |
| `UV3_SFS.rar` | 314 342 108 | `37BCD6C0B39F1293048220A024D5C9A36AC7A24EBBF7EABD3D96A62D4FBA6FB2` | `tigersounds_1.sfs` et `tigersounds_2.sfs` |

Les deux archives sont conservees sans modification dans
`D:\Projets\GITHUB\res\IL2 1946\Mods\Tiger33 Ultimate Sound Mod V3`.

Les trois RAR internes comptent respectivement 393, 788 et 772 entrees. Une
recherche d'extensions executables dans les enveloppes et les archives internes
n'a trouve aucun `.exe`, `.dll`, script ou installateur ; les deux SFS restent
des donnees opaques tant que leur index n'est pas audite. Aucun fichier n'a ete
execute.

Statut v1.15 : **source ciblee active pour les demarrages moteur**. Le paquet est
historiquement compatible avec la base visee, mais Open Sturmovik conserve sa
composition sonore personnalisee : les deux SFS ne sont pas montes. Seuls dix
presets mixeur complets et dix-huit WAV absents ont ete extraits ; les deux WAV
Sabre deja presents ont ete conserves. L'origine, les archives, les empreintes
et la politique d'integration sont fixes dans
`manifests/audio/tiger33-startup-sounds.json`. Le reste de Tiger33 demeure une
source de comparaison jusqu'a une comparaison A/B et une verification de
redistribution.

## Sources secondaires a recouper

Les miroirs SAS1946, Mission4Today, All Aircraft Simulations, CombatACE et les
anciens modpacks Ultrapack/HSFX/DBW peuvent conserver des copies ou des notes.
Ils servent a retrouver les paquets, mais la provenance AAA, les empreintes et
la compatibilite 4.09m doivent etre privilegiees.
