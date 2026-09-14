# Organisation du dossier WIP

Derniere mise a jour : 13 septembre 2026.

La racine du depot reproduit maintenant une installation d'Open Sturmovik. Les
dossiers de fabrication, d'analyse et d'essai sont tous ranges sous `WIP/`.

## Structure actuelle

- `WIP/development/` : sources du projet qui ne sont pas installees dans le jeu :
  `installer`, `manifests`, `tools`, `native`, `test-assets` et documentation
  technique. Ce sous-dossier reste versionne malgre l'exclusion generale de
  `WIP`.
- `WIP/analyses/` : audits, laboratoires, plans d'analyse et recherches sur les
  fonds de chargement. Les donnees lourdes de laboratoire ne sont pas versionnees.
- `WIP/tests/` : installations de test, sauvegardes, captures, faux Bureau et
  plans d'essai. Le jeu de test actif est
  `WIP/tests/installations/IL 2 Sturmovik 1946 test`.
- `WIP/dependances/` : SDK, outils externes et utilitaires d'analyse locaux.
- `WIP/temporaire/` : extractions et resultats regenerables encore utiles.
- `WIP/worktrees/` : emplacement reserve aux autres taches Git. Son contenu ne
  doit jamais etre deplace ou nettoye par une tache qui ne le possede pas.

L'installeur se trouve dans `WIP/development/installer/`. Son payload est dans
`WIP/development/installer/Payload/`. Les commandes principales sont donc :

```powershell
.\WIP\development\installer\Test-OpenSturmovikInstaller.ps1 -BeforeCompilation
.\WIP\development\tools\Test-OpenSturmovikSwitcher.ps1
```

## Racine du jeu

Les dossiers `_Documentations`, `_Game Switcher`, `_Game_Enhancements`,
`_Utilities`, `DGen`, `Files`, `i18n`, `Intros`, `Missions`, `NGen`,
`PaintSchemes` et `samples` appartiennent au jeu. Le petit dossier `docs` ne
contient que les notices livrees avec Open Sturmovik. `.git` et `WIP` restent a
la racine pour le fonctionnement du depot ; `.open-sturmovik-loading-rotation`
est un etat d'execution du jeu.

## Ressources externes

`WIP/resources` a ete nettoye le 13 septembre 2026. Les quatre arborescences en
double ont ete comparees fichier par fichier par chemin, taille et SHA-256 avec
`D:\Projets\GITHUB\#res\IL2 1946`. Les sept archives absentes de `#res` ont
ete classees dans les dossiers du jeu ou du pack correspondant avant le retrait
des copies. Le rapport exact est
`WIP/development/manifests/resources/wip-resources-cleanup-20260913.json`.

Toute nouvelle source externe doit desormais aller directement dans
`D:\Projets\GITHUB\#res\IL2 1946`, selon les categories definies dans
`AGENTS.md`. Une extraction temporaire peut etre placee sous
`WIP/temporaire/`, puis retiree lorsque sa source et ses conclusions sont
conservees.