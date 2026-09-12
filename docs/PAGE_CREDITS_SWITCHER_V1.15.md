# Page Credits du switcher v1.15

Le bouton **Credits** ouvre une page intégrée au switcher, avec sept rubriques,
quatre tableaux et 41 contributions. Le slogan **« par la communauté, pour la
communauté »** figure en tête. AAA est crédité comme forum dont les auteurs et
contributeurs ont partagé plusieurs améliorations ; aucun pack AAA n’est annoncé
comme intégré. Le bouton **Appliquer** et son voyant sont verts.

Le contenu défile et un menu permet de rejoindre chaque rubrique. **Retour** et
Échap ramènent au sélecteur en conservant les choix de version, mode et HUD en
cours, y compris ceux qui n’ont pas été appliqués.

## Source et génération

Le 12 septembre 2026, les entrées DCG et San FOV ont été retirées après leur
archivage hors du pack. Malta et ses campagnes retirées n'avaient pas d'entrée
dans cette page. Zuti reste crédité tant que son code est encore présent ;
voir [le suivi du retrait](RETRAIT_COMPOSANTS_V1.15.md).

La source éditable est
`_Documentations/Mods and Tools/Credits - Open Sturmovik.md`.
Les attributions, les réserves et les inventaires en cours y sont conservés.
Les références documentaires locales apparaissent en texte avec leur chemin
en infobulle ; les trois liens web ouvrent leur source dans le navigateur.

```text
python tools/Build-SwitcherCredits.py
python tools/Build-SwitcherCredits.py --check
node tools/Test-SwitcherGui.cjs
```

Le générateur transforme le Markdown en HTML embarqué dans le BAT. La page ne
lit ni ne lance le fichier Markdown à l’exécution et n’exige aucune bibliothèque
ou connexion réseau pour afficher les crédits. Après toute régénération,
actualiser `entryPointSha256` dans `manifests/switcher-v1.15.json` à partir du BAT
en UTF-8 sans BOM avec fins de ligne CRLF.

## Vérification et périmètre

- Contenu embarqué identique à la source selon le contrôle du générateur.
- Tests de sélection : neuf profils, dix-huit combinaisons profil/HUD,
  dix-huit restaurations et garde HUD stock.
- Navigation Credits vérifiée sur les trois versions : choix conservés,
  sans accès au disque ni lancement de processus pendant l’aller-retour.
- Relecture des liens externes : URLs http(s) validées et passées directement
  au navigateur, sans interpréteur de commandes ; schémas locaux/scripts refusés.
- BAT sans BOM, CRLF uniquement ; contrôle des espaces Git sans erreur.
- La partie batch de bascule des fichiers, avant le marqueur HTA, est inchangée.

Le switcher isolé a démarré dans Windows. La capture visuelle automatique a
échoué avec `SetIsBorderRequired / 0x80004002`, puis la géométrie de clic était
indisponible. Ce contrôle n’est donc pas une validation visuelle automatisée.
Après présentation de la copie de test et corrections demandées, Alexis a
autorisé le commit et la publication sur `v1.15` et dans le dépôt partagé.

Le conf.ini expérimental préparé séparément reste hors production et hors de
cette publication. Aucun réglage graphique ou CPU livré avec le switcher
n’est modifié par ce changement.
