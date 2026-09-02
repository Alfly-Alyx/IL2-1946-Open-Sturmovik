# Organisation Git d'Open Sturmovik

## Branches de travail

| Branche | Role | Regle |
| --- | --- | --- |
| `v1.15` | Stabilisation et livraison du jeu modde 4.09m | Branche du dossier de travail principal. Chaque changement doit etre teste, documente, commite et pousse ici. |
| `launcher` | Developpement du Lanceur Open Sturmovik | Part de `v1.15`. Integrer regulierement `v1.15` dans `launcher`, jamais l'inverse avant que le lanceur soit declare livrable. |
| `main` | Ligne stable generale du depot | Ne recoit `v1.15` qu'apres validation de la version et revue explicite de la divergence historique. |
| `v1.2` | Version historique publiee | Conservation uniquement. |
| `archived_v1.1` | Archive de l'ancienne branche 1.1 | Conservation uniquement ; le nom evite l'ambiguite avec le tag `v1.1`. |
| `archive/recovered-sfs-2024` | Sauvegarde locale du commit orphelin contenant trois SFS bruts | Ne pas pousser telle quelle : ses blobs depassent 100 Mio. Leur contenu est conserve par Git LFS dans `v1.15`. |

Les branches publiques `v1.15`, `launcher` et `main` ne doivent pas etre
rebasees ni poussees de force.

## Worktrees

Le seul depot de travail place dans `D:\Projets\GITHUB` est :

```text
D:\Projets\GITHUB\IL2-1946-Open-Sturmovik
```

Il reste attache a `v1.15`. Les worktrees auxiliaires sont places hors de
`D:\Projets\GITHUB`, dans :

```text
%USERPROFILE%\DATA\Worktrees\IL2-1946-Open-Sturmovik\<branche>
```

Un worktree appartenant a une autre tache Codex et contenant des changements
ne doit jamais etre supprime, deplace ou reutilise. Un worktree temporaire se
retire avec `git worktree remove` seulement apres verification de son etat et
apres sauvegarde de tous ses commits.

## Synchronisation des deux axes

Le cycle normal est le suivant :

1. terminer un lot coherent sur `v1.15` ;
2. tester, commiter et pousser `v1.15` ;
3. fusionner `v1.15` dans `launcher` avec un commit de fusion explicite ;
4. mettre a jour les manifestes et controles du lanceur si les fichiers du jeu
   ont change ;
5. tester, commiter et pousser `launcher`.

Pour la publication 1.15, deux issues restent possibles :

- si le lanceur satisfait ses criteres de validation, fusionner `launcher`
  dans `v1.15` et livrer l'ensemble ;
- sinon, publier le jeu depuis `v1.15` sans fusionner le lanceur, qui continuera
  sur sa branche.

## Archive des trois SFS recuperes

Le commit brut `7e93f90794ae85f0ea92f88f1935eb490855600b` est conserve par la branche
locale `archive/recovered-sfs-2024`. Les trois contenus ont ete migres vers Git
LFS et sont presents dans `v1.15` :

| Fichier | OID SHA-256 Git LFS | Taille |
| --- | --- | ---: |
| `fb_3do.SFS` | `e95d1e3659b04f1638cc644b292846f94c1823cd5b63419f71fc26deff0c057b` | 154 030 389 octets |
| `fb_3do19.SFS` | `4527fc779f188364e2fc8739e53d74c85b3a47471b01f169586e4f1afbb6b670` | 187 104 836 octets |
| `fb_maps15.SFS` | `af87651fbca2450a57735ed2013f12fc9f307abfb8b2913f22eb5543322d8ad9` | 343 180 796 octets |

Une verification `git lfs push --dry-run origin v1.15` ne signale aucun objet
restant a envoyer.
