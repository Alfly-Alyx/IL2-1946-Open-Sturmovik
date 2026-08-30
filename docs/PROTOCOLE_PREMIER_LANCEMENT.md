# Premier lancement instrumente de la version 1.15

## Perimetre

Le premier test utilise uniquement la copie :
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`.

L'installation de reference sans le suffixe `test` reste en lecture seule. Le
profil retenu est le choix 8 : **4.09m modifie, sans 6DOF, wrapper historique et
OpenGL natif**. Les wrappers cache et graphiques modernes sont exclus de cette
premiere mesure.

Le test commence au lancement de `il2fb.exe`, observe tous les paliers visibles,
reste quelques secondes au menu principal, puis ferme proprement le jeu. Aucune
mission n'est lancee.

## Preparation

1. Compiler `tools/FrameCapture.cs` avec `tools/Build-TestTools.ps1`.
2. Conserver Process Monitor portable sous `build/test-tools/sysinternals` ; cet
   outil Microsoft n'est pas distribue avec l'add-on.
3. Copier le selecteur courant dans la copie et activer le profil 8 avec
   `-Profile 8 -Hud 3 -NoPause`.
4. Activer les journaux de diagnostic avec
   `tools/Set-IL2StartupDiagnostics.ps1`.
5. Executer `tools/Start-IL2StartupCapture.ps1 -ValidateOnly` : ce mode ne lance
   ni capture ni jeu.
6. Redemarrer Windows. Ne pas ouvrir d'application inutile avant la mesure a
   froid.

## Capture

La capture reelle est armee avant le lancement de l'EXE. Elle produit dans
`test-results/startup` :

- une trace Process Monitor des acces aux fichiers, au Registre, aux processus et
  aux DLL ;
- une trace WPR/ETW pour CPU, disque, threads et piles disponibles ;
- dix images par seconde limitees a la fenetre visible d'IL-2, avec horodatage ;
- un echantillon CPU/memoire/threads toutes les 100 ms ;
- la chronologie des DLL nouvellement chargees ;
- les journaux `log.lst`, `eventlog.lst` et `sound.log` ;
- les empreintes avant/apres des fichiers critiques de la copie et de la
  reference.

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
