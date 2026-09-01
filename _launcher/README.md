# Lanceur Open Sturmovik

Ce dossier contient le nouveau lanceur, concu comme une application Windows
pilotee par des manifestes. L'interface parle des effets recherches par le
joueur (qualite d'image, comportement sous G negatifs, commandes, 6DOF) et ne
demande jamais de connaitre le nom d'un mod ou d'un fichier technique.

Convention d'installation : seul le dossier de premier niveau ajoute a la racine
du jeu porte le prefixe `_` : `_launcher`. Ses sous-dossiers (`docs`,
`manifests`, `tools`, `tests` et `fixtures`) et leurs fichiers gardent des noms
normaux. Les noms historiques du jeu, dont `il2setup.exe` et `conf.ini`, ne sont
jamais renommes.

## Etat du socle

- conception fonctionnelle et architecture : `docs/CONCEPTION.md` ;
- rétro-ingénierie statique de l'ancien configurateur :
  `docs/RETROINGENIERIE_IL2SETUP.md` ;
- architecture des rapports anonymisés : `docs/RAPPORTS_ERREURS_GITHUB.md` ;
- index et plan de la documentation destinee au futur PDF :
  `docs/INDEX_DOCUMENTATION_TECHNIQUE.md` ;
- reference lisible des reglages, commandes et limites connues :
  `docs/REFERENCE_REGLAGES_COMMANDES.md` ;
- preuves et points de reprise sur les commandes :
  `docs/NOTES_TECHNIQUES_COMMANDES.md` ;
- contrat de manifeste : `manifests/launcher.schema.json` ;
- premier manifeste 4.09m : `manifests/open-sturmovik-1.15.json` ;
- contrat de compatibilité `il2setup.exe` :
  `manifests/il2setup-1.0.0.2.json` ;
- schéma des rapports : `manifests/error-report.schema.json` ;
- catalogue des messages de diagnostic observés :
  `manifests/diagnostic-patterns.json` ;
- catalogue statique des commandes :
  `manifests/hotkeys-4.09m-modified.json` ;
- catalogue complet des 39 profils historiques d'`il2setup` :
  `manifests/il2setup-catalogue-1.0.0.2.json` ;
- validateur sans modification du jeu : `tools/Test-LauncherManifest.ps1` ;
- collecteur local de `log.lst` : `tools/Convert-IL2LogToEvents.ps1` ;
- lecteur déclaratif des profils historiques :
  `tools/Read-Il2SetupCatalogue.ps1` ;
- lecteur statique et fusionneur des commandes :
  `tools/Read-IL2HotKeyCatalogue.ps1` ;
- generateur de la reference lisible des reglages et commandes :
  `tools/New-IL2CommandReference.ps1` ;
- moteur de modification transactionnelle de `conf.ini`, en aperçu par défaut :
  `tools/Set-IL2Configuration.ps1` ;
- anonymiseur local sans envoi : `tools/New-AnonymizedErrorReport.ps1` ;
- validateur d'un rapport prêt à envoyer : `tools/Test-ErrorReport.ps1` ;
- resolveur de configuration en lecture seule :
  `tools/Resolve-LauncherPlan.ps1`.

Le socle ne modifie encore aucun fichier du jeu et n'envoie aucun rapport. Il
rend les choix explicites, refuse une capacité indisponible et produit le plan
qu'un futur moteur transactionnel appliquera après confirmation.

## Essai local

```powershell
pwsh -File _launcher/tools/Test-LauncherManifest.ps1
pwsh -File _launcher/tools/Resolve-LauncherPlan.ps1
pwsh -File _launcher/tests/Test-LogCollector.ps1
pwsh -File _launcher/tests/Test-Il2SetupCatalogue.ps1
pwsh -File _launcher/tests/Test-HotKeyCatalogue.ps1
pwsh -File _launcher/tests/Test-CommandReference.ps1
pwsh -File _launcher/tests/Test-TransactionalConfiguration.ps1
```

Pour afficher les details techniques du plan sans rien appliquer :

```powershell
pwsh -File _launcher/tools/Resolve-LauncherPlan.ps1 -TechnicalDetails
```

## Direction technique

La cible prevue est une application Windows desktop en .NET 8/WPF, publiee en
autonome pour ne pas dependre d'un SDK sur le poste du joueur. Le domaine reste
independant de WPF : l'interface, la resolution des choix, les transactions et
la verification d'integrite seront des couches separees. Les scripts presents
ici servent de reference executable au contrat de donnees avant la creation du
projet .NET.
