# Preparation des utilitaires Open Sturmovik v1.15

Date : 6 septembre 2026.

## Perimetre

Ce lot couvre les neuf utilitaires demandes pour la v1.15 :
Bombsight Table 2, HardBall408, IL2 Compare, JoyCtrl, Lowengrin DCG,
Mission Mate 6, WeatherSet, ZipNav et San's IL2 FOV Changer. Le dixieme
raccourci ouvre le switcher Open Sturmovik.

Aucun de ces programmes ne doit etre lance automatiquement avec le jeu. La
preparation et l'installation des raccourcis sont deux operations distinctes.

## Ce qui est prepare

- `manifests/utilities-v1.15.json` fixe les dix noms, executables, dossiers de
  travail et descriptions des raccourcis ;
- `tools/Initialize-OpenSturmovikUtilities.ps1` configure une installation
  cible sans chemin provenant d'une ancienne machine ;
- `tools/Install-OpenSturmovikUtilityShortcuts.ps1` cree les dix raccourcis sur
  le Bureau choisi ;
- `tools/Complete-OpenSturmovikV115Update.ps1` est le point d'entree que
  l'installateur de mise a jour appelle apres la pose des fichiers : il execute
  l'initialisation, puis installe exactement les dix raccourcis ;
- `tools/Test-OpenSturmovikUtilityShortcuts.ps1` controle les cibles, le
  manifeste, DeviceLink, les cartes ZipNav et les composants Mission
  Mate/HardBall sans modifier le Bureau.

## Initialisation d'une installation

L'initialiseur exige un dossier contenant `il2fb.exe`, puis :

1. ecrit ce dossier racine dans `Mission Mate 6/FBPath.txt` ;
2. renseigne dans `MisMate.ini` le chemin absolu de `HardBall408.exe` ;
3. rend les cartes fournies avec ZipNav visibles sous `mods/mapmods` au moyen
   d'une jonction, sans recopier les 168 Mio de cartes et sans remplacer un
   dossier deja present ;
4. conserve le `DeviceLink.txt` officiel 4.09m a la racine ;
5. regle `conf.ini` avec `SaveAspect=0`, le port DeviceLink 1711 et une adresse
   IPv4 locale non boucle ;
6. conserve les points de debut et de fin documentes dans le `pref.ini` du FOV
   Changer, mais ne reutilise pas l'adresse materielle de l'ancienne machine.

La position memorisee de Bombsight Table 2 a ete ramenee a `32,32`. Son ancien
`Left=1045` pouvait placer la fenetre hors ecran sur un poste mono-ecran.

Mission Mate conserve son catalogue embarque pour le premier essai. Son import
automatique de mods cherche historiquement `MODS/STD`, alors qu'Open Sturmovik
charge son contenu sous `Files`. Il ne faut donc pas relier `Files` a
`MODS/STD` : le wrapper parcourrait deux fois les memes ressources. Les avions
du mod seront ajoutes depuis l'interface de Mission Mate apres validation de la
generation avec son catalogue de base.

Chaque fichier texte modifie recoit au plus une sauvegarde
`.opensturmovik-v1.15.bak`, et l'ecriture passe par un fichier temporaire. Les
options `-SkipDeviceLink` et `-SkipZipNavMaps` permettent d'omettre les deux
integrations concernees.

## Validation runtime differee

La campagne finale doit encore confirmer :

- DCG en generation manuelle avant tout remplacement de DGen/NGen ;
- une mission jetable stock puis une mission utilisant un avion du mod dans
  Mission Mate ;
- l'effet A/B de WeatherSet sur une copie de mission ;
- les raccourcis et le retour au FOV initial, avec et sans 6DOF ;
- l'echelle et plusieurs caps connus dans ZipNav ;
- l'etiquetage 4.08 de HardBall et l'anciennete des donnees IL2 Compare ;
- les raccourcis en vol de Bombsight Table 2 ;
- l'aller-retour d'un profil JoyCtrl avec sauvegarde exacte de `conf.ini`.

Ces controles seront effectues ensemble dans la copie de test lorsque tous les
correctifs hors jeu de la v1.15 seront figes.

Le DCG livre est la version 3.43 (octobre 2009), d'apres son propre historique.
Une version recente ne doit pas l'ecraser sans migration separee : les formats
de donnees et les campagnes existantes ont evolue. Pour la v1.15, le premier
test reste donc volontairement en generation manuelle et sans remplacement de
`DGen.exe` ou `NGen.exe`.

## Appel depuis l'installateur de mise a jour

Apres avoir copie le contenu v1.15 dans le dossier du jeu, l'installateur appelle
`tools/Complete-OpenSturmovikV115Update.ps1` avec ce dossier comme
`InstallationRoot`. Par defaut, les raccourcis sont installes sur le Bureau de
l'utilisateur Windows courant. Le mode tous utilisateurs reste explicite et ne
doit etre choisi que par un installateur eleve. Une cible absente ou un nombre de
raccourcis different de dix fait echouer la finalisation au lieu de laisser une
installation partielle silencieuse. Le mode `-WhatIf` n'initialise pas le
composant Windows des raccourcis et annonce chaque entree comme simulee ; le
mode `-ValidateOnly` reste entierement sans ecriture.
