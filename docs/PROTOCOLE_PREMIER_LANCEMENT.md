# Premier lancement instrumente de la version 1.15

## Perimetre

Le protocole utilise uniquement la copie de test courante :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-installations\IL 2 Sturmovik 1946 test`.

L'installation de reference sans le suffixe `test` reste en lecture seule. Le
profil retenu est le choix 9 : **4.09m modifie, 6DOF, wrapper historique et
OpenGL natif**. Les wrappers cache et graphiques modernes sont exclus de cette
premiere mesure.

Le test commence au lancement de `il2fb.exe`, observe tous les paliers visibles,
reste quelques secondes au menu principal, puis ferme proprement le jeu. Aucune
mission n'est lancee.

## Preparation

1. Compiler `tools/FrameCapture.cs` avec `tools/Build-TestTools.ps1`.
2. Conserver Process Monitor et ProcDump x86 portables sous
   `WIP/sdk/test-tools/sysinternals` ; ces outils Microsoft ne sont pas distribues
   avec l'add-on.
3. Copier le selecteur courant dans la copie et activer le profil 9 avec
   `-Profile 9 -Hud 3 -Windowed1024 -NoPause`.
4. Activer les journaux de diagnostic avec
   `tools/Enable-IL2StartupDiagnostics.ps1`.
5. Executer `tools/Start-IL2StartupCapture.ps1 -ValidateOnly` : ce mode ne lance
   ni capture ni jeu.
6. Redemarrer Windows. Ne pas ouvrir d'application inutile avant la mesure a
   froid.

## Etat prepare le 30 aout 2026

Le dossier de test a ete reconstruit transactionnellement depuis la base DVD
4.07m authentique, puis le contenu utile de l'add-on a ete superpose. L'ancienne
copie a ete conservee sous
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\test-backups\IL 2 Sturmovik 1946 test.backup-before-clean-20260830`.

La nouvelle copie contient 142 648 fichiers et 26 530 020 000 octets. Elle
possede les 52 SFS attendus jusqu'a 4.09m et aucun SFS posterieur. Les fichiers
4.09m officiels correspondent aux empreintes du patch de reference. Le profil 9
a ensuite ete active en 1024 x 768 fenetre avec le profil graphique x86
securise. Le controle avant lancement passe toutes ses verifications, notamment
les 52 SFS jusqu'a 4.09m, les empreintes des SFS et DLL officiels, EXE PE32 LAA,
wrapper, `air.ini`, `stationary.ini`, 56 classes Java version 47,
journalisation, affinite CPU et outils de capture.

Aucun lancement du jeu n'a ete effectue apres cette reconstruction.

La commande de validation finale, sans lancement ni enregistrement, est :

```powershell
& .\tools\Start-OpenSturmovikProfile9Capture.ps1 -ValidateOnly
```

Apres le redemarrage, la mesure a froid s'arme avec une seule commande :

```powershell
& .\tools\Start-OpenSturmovikProfile9Capture.ps1
```

Elle attend ensuite `il2fb.exe` pendant trois minutes. Le jeu doit etre lance
seulement apres l'affichage de `CAPTURE_ARMEE` et apres l'avertissement explicite
adresse a l'utilisateur.

## Capture

La capture reelle est armee avant le lancement de l'EXE. Elle produit dans
`WIP/captures/startup` :

- une trace Process Monitor des acces aux fichiers, au Registre, aux processus et
  aux DLL ;
- une trace WPR/ETW pour CPU, disque, threads et piles disponibles ;
- dix images par seconde limitees a la fenetre visible d'IL-2, avec horodatage ;
- un echantillon CPU/memoire/threads toutes les 100 ms ;
- la chronologie des DLL nouvellement chargees ;
- les journaux `log.lst`, `eventlog.lst` et `sound.log` ;
- les empreintes avant/apres des fichiers critiques de la copie et de la
  reference.

Sur la machine de test, Windows peut refuser le profil noyau WPR avec le code
`0xc5585011` lorsque le compte ne dispose pas de la politique « profiler les
performances systeme ». Le script ne modifie pas cette politique : il poursuit
alors avec les compteurs locaux CPU par processeur logique et disque, echantillonnes
chaque seconde, en plus des mesures du processus toutes les 100 ms. Cette
degradation est inscrite dans la chronologie du test.

La trace Process Monitor peut contenir des chemins d'autres activites Windows
survenues pendant la courte mesure. Elle reste locale, dans un dossier ignore par
Git, et ne doit jamais etre publiee brute.

## Arret et analyse

Apres quelques secondes au menu, le jeu est ferme par son interface. Le script
arrete ensuite les trois captures et finalise les fichiers. Les images servent a
dater les paliers `0, 5, 10, ... 100 %`; les traces sont regroupees entre deux
paliers successifs. Un chemin absent n'est classe comme panne qu'apres verification
du repli et de la consequence visible.

Le redemarrage donne la mesure a froid. Des lancements ulterieurs sans redemarrage
donneront les mesures a chaud, avec le meme profil et le meme protocole.

## Reproduction separee du bug critique en vol

Ce scenario ne doit pas etre melange avec la mission d'endurance de dix minutes.
Il utilise le profil 9, le mode fenetre 1024 x 768 et le wrapper historique. La
capture est preparee avec :

```powershell
& .\tools\Start-IL2FlightBugCapture.ps1 -ValidateOnly
```

Puis elle est armee, sans lancer automatiquement le jeu, avec :

```powershell
& .\tools\Start-IL2FlightBugCapture.ps1
```

Le script ajoute ProcDump x86 12.01, telecharge depuis la page officielle
[Microsoft Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump).
Le binaire doit porter une signature Microsoft valide ; l'empreinte du binaire
utilise le 31 aout 2026 est
`264E7AB0E27DC1545E70D14C9DB8C11D1E402D7E4E2863EBF66964FEE6644F1C`.
Il surveille les exceptions non gerees et une fenetre bloquee, puis ecrit au
maximum deux dumps complets. La video, les compteurs, les DLL et les journaux
restent actifs si le bug est seulement fonctionnel ou visuel.

Process Monitor est desactive par defaut pour reduire le cout et ne pas perturber
la reproduction. Ajouter `-WithFileTrace` seulement si le symptome parait lie a
un fichier. Les dumps peuvent contenir des chemins et des donnees presentes en
memoire : ils restent sous `WIP/captures`, sont ignores par Git et ne doivent pas
etre publies bruts.

## Parcours Selector/Dump 4.09m

Un second clone independant est prepare sous
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\labs\IL 2 Sturmovik 1946 Selector Dump`. Il a ete copie le
30 aout 2026 depuis la copie de test validee : 6 490 dossiers, 141 540 fichiers
et 26 528 657 353 octets. La copie source et l'installation originale n'ont pas
ete modifiees.

Le profil de base est le choix 8, **4.09m modifie sans 6DOF**, afin de mesurer le
chargement des mods sans ajouter la variable TrackIR/6DOF. Selector 5.1.2 est
installe uniquement dans ce clone. Les fichiers anterieurs et leurs empreintes
sont conserves sous `_OpenSturmovikLab\pre-selector-backup`; le manifeste complet
est `_OpenSturmovikLab\selector-dump-lab.json`.

Reglages du laboratoire :

- `ModType=7`, Classic Mod Game pour les dossiers `Files` et `MODS` ;
- `RamSize=1024`, strategie memoire equilibree ;
- `DumpMode=3`, soit copie des ressources et journalisation SFS ;
- `InstantDump=1`, pour conserver le plus d'information possible en cas de
  blocage ou d'arret brutal ;
- `UseCachedFileLists=0`, afin que le premier inventaire ne depende d'aucun
  cache ancien ;
- OpenGL natif, profil graphique x86 securise, 1024 x 768 fenetre et quatre
  coeurs physiques maximum ;
- dossier `dump` vide avant le premier passage.

L'installation reproductible s'effectue avec :

```powershell
& .\tools\Install-IL2SelectorDumpLab.ps1 `
  -GameRoot 'C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\labs\IL 2 Sturmovik 1946 Selector Dump'
```

Le controle complet, sans lancement, est :

```powershell
& .\tools\Start-OpenSturmovikSelectorDumpCapture.ps1 -ValidateOnly
```

Il passe 56 controles au 30 aout 2026. Pour la vraie mesure, la commande sans
`-ValidateOnly` arme Process Monitor, les images, les compteurs et les journaux,
puis attend l'apparition de `il2fb.exe`. Le jeu ne doit etre lance qu'apres
l'affichage `CAPTURE_ARMEE` et l'avertissement explicite donne a l'utilisateur.
Lorsque le processus se termine, le contenu de `dump` est copie avec un manifeste
SHA-256 dans le dossier de resultats du passage.
