# Preparation de l'installateur de mise a jour v1.15

Le script Inno Setup `Open_Sturmovik_Update_1.15.iss` est destine a etre place
avec les sous-dossiers suivants :

```text
Open_Sturmovik_Update_1.15.iss
assets/
  OpenSturmovik-Setup.ico
  OpenSturmovik-Wizard.bmp
Payload/
  ...fichiers de mise a jour reproduisant leur emplacement dans le jeu...
```

Le dossier `Payload` n'est volontairement pas fabrique avant le gel du contenu
v1.15. Cette separation empeche qu'un ancien test, un fichier WIP ou une
ressource de developpement entre silencieusement dans l'installateur.

## Compilateur portable prepare

Inno Setup 7.1.0 x64 est prepare en mode portable officiel sous
`WIP/sdk/inno-setup-portable/Inno Setup 7.1.0`. Le compilateur est
`ISCC.exe` dans ce dossier. L'installateur source officiel est conserve sous
`WIP/sdk/inno-setup-portable/downloads` avec sa signature `.issig`.

Controles effectues avant execution :

- SHA-256 de l'installateur :
  `0362A383ED217D4C4239B5933866DD96D3EB2102737DA92F80F6057A4B40DF2F` ;
- empreinte identique a celle inscrite dans la signature officielle `.issig` ;
- signature Authenticode valide, editeur `Pyrsys B.V.` ;
- `ISCC.exe --version` retourne `7.1.0` ;
- aucun desinstalleur portable n'a ete cree.

Le compilateur ne doit pas etre utilise avant la fin des essais runtime de la
v1.15 et le gel explicite du dossier `Payload`.

## Comportement prepare

- l'utilisateur doit choisir une installation existante contenant
  `il2fb.exe` ;
- les applications `il2fb.exe` en cours sont fermees avant remplacement ;
- le contenu de `Payload` est copie en conservant son arborescence ;
- seuls les anciens fichiers et dossiers explicitement remplaces par la v1.15
  sont supprimes, notamment `_Runtime_Addons`, le `Mod_AOC_Public` racine et
  l'ancien `_Documentation` singulier ; leur contenu v1.15 se trouve
  respectivement dans les emplacements conserves ou sous `_Game_Enhancements`
  et `_Documentations` ;
- dix raccourcis sont crees sur le Bureau : les neuf outils retenus et
  `Open Sturmovik Switcher` ;
- le raccourci `Open Sturmovik Switcher` lance l'unique BAT avec une console
  masquee ; le BAT reste directement utilisable et ne garde plus la console
  ouverte une fois son interface chargee ;
- l'initialiseur des utilitaires configure les chemins locaux sans lancer le
  jeu ni les programmes externes ;
- l'installateur utilise l'icone bouclier et le fond d'ecran fournis dans les
  ressources locales du projet.

Le fond du switcher retenu le 11 septembre 2026 est la remasterisation de la
jaquette Pacific Fighters Retail, livree sous
`Resources\Backgrounds\Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.png`.
Le dossier `Resources\Icons` contient les deux icones actives.
`Open_Sturmovik_Switcher.ico`, issu du dessin `logo-IL2-B`, est l'icone de la
fenetre et du raccourci. `Open_Sturmovik_Game.ico`, issu du dessin
`avion-ciel`, est reserve aux executables de jeu modifies.

Le script reprend le principe de detection du dossier existant de
`IL2_Open_Sturmovik_Patch_1.1.iss`, mais ne reprend pas la longue suppression
globale de l'ancien installateur 1.1. Les suppressions v1.15 sont bornees a une
liste connue et relisible de ressources devenues obsoletes.

## Controle avant compilation

Avant de compiler, il faudra produire le dossier `Payload`, verifier ses
empreintes, puis executer les controles hors-jeu v1.15. La compilation Inno
Setup doit enfin etre essayee dans une copie jetable du jeu, jamais directement
sur l'installation de reference.
