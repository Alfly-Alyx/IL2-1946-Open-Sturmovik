# Développement d’Open Sturmovik 1.15

Ce dossier regroupe tout ce qui sert à fabriquer et vérifier la version 1.15,
mais ne doit pas être installé dans le jeu.

- `installer/` : source Inno Setup, éléments visuels, payload préparé et contrôles avant compilation ;
- `manifests/` : listes de contenu, profils, utilitaires et rapports de traçabilité ;
- `tools/` : préparation, synchronisation et validations hors jeu ;
- `native/` : sources et projets des composants natifs ;
- `test-assets/` : données minimales réservées aux essais ;
- `docs/` : analyses et documentation technique ;
- `.codex/` : configuration locale du travail sur le dépôt.

Depuis la racine du dépôt, le contrôle général hors ligne est :

```powershell
.\WIP\development\tools\Test-V115OfflineReadiness.ps1
```

Le contrôle final de l’installeur, sans le compiler, est :

```powershell
.\WIP\development\installer\Test-OpenSturmovikInstaller.ps1 -BeforeCompilation
```

Le payload est construit dans `WIP/development/installer/Payload/`. Ce dossier
et `Output/` sont ignorés par Git, tandis que les scripts, manifestes et
documents de `WIP/development/` restent suivis.

Les ressources externes de référence sont conservées dans
`D:\Projets\GITHUB\#res\IL2 1946`. `WIP/resources` a été supprimé après
comparaison et classement de son contenu ; le rapport se trouve dans
`manifests/resources/wip-resources-cleanup-20260913.json`.

La compilation Inno Setup constitue l’étape suivante et n’a pas été lancée.