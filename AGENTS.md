# Regles de travail du depot

- Avant toute action, les IA doivent lire ce fichier `AGENTS.md` completement,
  du debut a la fin. Elles ne doivent pas anticiper, extrapoler ou interpreter
  les demandes d'Alexis. Elles doivent appliquer uniquement ce qui est demande
  explicitement. En cas d'ambiguite, elles doivent s'arreter et demander a
  Alexis au lieu de choisir elles-memes une interpretation.
- Les IA ne peuvent changer de branche (`git switch`, `git checkout` ou toute
  commande equivalente) que sur demande explicite d'Alexis.
- Le checkout local partage (le dossier original du depot, affiche comme
  `Local` dans Codex) ne doit jamais etre bascule sur une autre branche, place
  en `detached HEAD`, deplace vers un worktree ou modifie par un handoff sans
  autorisation explicite d'Alexis.
- Avant toute operation susceptible de changer la branche, le `HEAD` ou
  l'emplacement du checkout local partage, les IA doivent s'arreter et obtenir
  l'autorisation explicite d'Alexis.
- Les IA ne peuvent modifier, fusionner, rebaser, reinitialiser ou supprimer
  une autre branche que sur demande explicite d'Alexis.
- Les IA ne peuvent en aucun cas toucher a la branche `main` sans demande
  explicite d'Alexis.
- Les IA ne peuvent mettre la branche courante a jour depuis une autre branche
  (notamment par merge, rebase ou cherry-pick) que sur demande explicite
  d'Alexis.
- En l'absence de demande explicite, les IA doivent rester sur la branche
  courante et limiter leurs modifications a celle-ci.

## Objectif du projet

- Open Sturmovik vise la beaute maximale et le realisme maximal.

## Distribution et installation

- Open Sturmovik est heberge sur un depot GitHub public et telechargeable
  gratuitement sous la forme d'un executable.
- Cet executable doit detecter une installation existante d'IL-2 et installer
  Open Sturmovik par-dessus cette installation.

## Emplacement des depots et dossiers de travail

- Les sous-dossiers d'un dossier principal dont le nom commence par `_` ne
  doivent pas eux-memes commencer par `_`.
- Le dossier `D:\Projets\GITHUB` est reserve au main.
- Tous les dossiers de travail des taches doivent etre places dans
  `C:\Users\Alexis\.codex`.
- Une tache peut creer son propre dossier de travail dans
  `C:\Users\Alexis\.codex` a condition que ce dossier soit celui de sa branche
  assignee et qu'il ne s'agisse pas d'un worktree.
- La creation ou l'utilisation de ce dossier de branche ne doit jamais changer
  la branche, le `HEAD`, le contenu ou l'emplacement du dossier commun.
- Les IA ne doivent pas utiliser `D:\Projets\GITHUB` comme dossier de travail
  d'une tache.

## Isolation obligatoire des taches

- Une tache doit travailler exclusivement dans la branche qui lui a ete
  assignee par Alexis. Une branche assignee a une autre tache est interdite.
- Le checkout principal partage d'Open Sturmovik doit rester en permanence sur
  la branche `v1.15`. Il est reserve a Alexis et sert de base stable.
- Aucune tache ne doit placer sa branche assignee dans le checkout principal
  partage, ni changer la branche `v1.15` qui y est attendue, sauf demande
  explicite d'Alexis visant precisement ce checkout.
- Avant toute modification, chaque tache doit verifier son dossier racine Git
  et sa branche courante. Elle doit renouveler cette verification avant tout
  commit, merge, rebase, cherry-pick, reset ou push.
- Si une tache constate que son dossier est sur la branche d'une autre tache,
  elle doit s'arreter immediatement. Elle ne doit surtout pas executer
  `git switch`, `git checkout` ou une commande equivalente pour recuperer sa
  branche : cela deplacerait encore le checkout du voisin. Elle doit signaler
  le conflit a Alexis et attendre son autorisation explicite.
- Si une tache constate que le checkout principal partage n'est plus sur
  `v1.15`, elle doit s'arreter et le signaler a Alexis. Elle ne doit pas tenter
  de remettre elle-meme `v1.15` sans demande explicite d'Alexis.
- Une tache ne doit jamais modifier, deplacer, supprimer, reutiliser ou
  nettoyer le dossier de travail ou la branche d'une autre tache.
- Le principe obligatoire est : une tache = une branche assignee.

## Sources obligatoires

### Choix des variantes (demande d'Alexis du 6 septembre 2026)

- Lorsque plusieurs variantes realistes et compatibles peuvent etre proposees
  dans le perimetre demande, toujours permettre a l'utilisateur de choisir
  entre elles plutot que d'en exclure une arbitrairement.
- Verifier les sources et la faisabilite avant de decider d'ecarter une
  variante. Si le choix ne peut pas etre propose, expliquer la limite a Alexis
  avant de trancher. Cette regle ne dispense pas des controles de compatibilite.

### Classement des sources de mods (demande d'Alexis du 6 septembre 2026)

- Tout mod retire doit etre conserve dans
  `D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés`.
- Tout mod utilise doit avoir ses ressources sources dans
  `D:\Projets\GITHUB\#res\IL2 1946\Mods\Utilisés`.
- Tout mod en reserve doit etre conserve dans
  `D:\Projets\GITHUB\#res\IL2 1946\Mods\Reserve`.
- Tout mod necessitant une licence ou n'etant pas libre d'utilisation doit etre
  conserve dans
  `D:\Projets\GITHUB\#res\IL2 1946\Mods\Besoin Licence`.
- Ce classement porte sur les sources et sauvegardes ; il ne deplace pas les
  fichiers actifs du jeu. Une integration partielle doit etre documentee.
  Une sauvegarde partielle ne doit jamais etre presentee comme un mod complet.

### Integration des futurs mods et patchs

- Les futurs mods libres d'utilisation peuvent etre integres a Open Sturmovik,
  apres verification de leur compatibilite avec la version ciblee du pack.
- Les donnees telechargees d'un mod libre d'utilisation doivent etre placees
  dans `D:\Projets\GITHUB\#res\IL2 1946\Mods\Utilisés` si le mod est utilise,
  ou dans `D:\Projets\GITHUB\#res\IL2 1946\Mods\Reserve` s'il est conserve en
  reserve.
- Les mods necessitant une licence ou n'etant pas libres d'utilisation doivent
  etre telecharges sans etre integres a Open Sturmovik, puis places dans
  `D:\Projets\GITHUB\#res\IL2 1946\Mods\Besoin Licence`.
- Pour chaque mod necessitant une autorisation, l'adresse e-mail de l'auteur
  doit etre placee dans le dossier du mod. Aucune autre coordonnee ne doit y
  etre ajoutee.
- Pour chaque mod ajoute a Open Sturmovik, les credits d'Open Sturmovik doivent
  etre mis a jour.
- Open Sturmovik doit contenir les patchs de mise a jour d'IL-2 afin de
  faciliter l'installation pour l'utilisateur.

### Recherche et compatibilite

- Pour toute recherche ou modification liee a IL-2 1946, les IA doivent
  consulter et utiliser en priorite les ressources locales du dossier
  `D:\Projets\GITHUB\#res\IL2 1946`.
- Les IA doivent egalement rechercher les informations pertinentes dans les
  sources communautaires historiques suivantes :
  - le forum AAA, aussi appele All Aircraft Arcade ; ce forum n'existe plus et
    doit etre consulte dans les archives de la Wayback Machine ;
  - le forum Mission4Today ;
  - le forum SAS.
- Les IA doivent recouper ces sources lorsqu'elles se contredisent et indiquer
  clairement les sources utilisees. Si une source est inaccessible, elles
  doivent le signaler au lieu de supposer son contenu.
- Si un fichier requis est manquant, incomplet ou inutilisable, les IA ne
  doivent pas l'inventer ni le remplacer arbitrairement. Elles doivent le
  rechercher dans `D:\Projets\GITHUB\#res\IL2 1946`, puis dans les sources
  communautaires indiquees ci-dessus.
- Pour cette recherche sur les forums, AAA / All Aircraft Arcade, consulte via
  la Wayback Machine, est prioritaire sur Mission4Today et SAS.
- Avant de copier, restaurer ou adapter un fichier trouve, les IA doivent
  verifier sa compatibilite avec la version exacte du pack ciblee par la tache,
  notamment son origine, sa version, ses dependances, son format et son ordre
  de chargement. Un fichier dont la compatibilite n'est pas etablie ne doit pas
  etre integre sans autorisation explicite d'Alexis.

## Documentation de la retro-ingenierie

- Toute information entrant dans le cadre de la retro-ingenierie d'IL-2 1946
  doit etre documentee. Aucune decouverte utile ne doit rester uniquement dans
  une conversation, un script temporaire ou la memoire d'une tache.
- Cette obligation couvre notamment le comportement du moteur, les formats de
  fichiers, structures binaires, protocoles, algorithmes observes, dependances,
  interfaces, limites, erreurs, adresses, signatures, methodes de test et outils
  d'analyse.
- La documentation doit distinguer clairement les faits verifies, les
  observations reproductibles, les deductions, les hypotheses et les points
  encore inconnus. Elle doit indiquer les versions concernees, les sources, les
  commandes ou etapes de reproduction et le niveau de confiance.
- Les resultats doivent etre documentes de facon a rester exploitables pour
  deux objectifs hypothetiques : modifier et moderniser le moteur de jeu
  existant, ou recreer depuis zero un moteur compatible avec le pack.
- Cette obligation de documentation n'autorise pas, a elle seule, la
  modification du moteur de jeu. Une telle modification doit etre demandee
  explicitement par Alexis dans une tache dediee.

## Gestion des ressources CPU

- Tout processus demandant beaucoup de CPU et lance ou utilise par une tache
  doit etre ferme des qu'il n'est plus activement necessaire a l'etape en
  cours. Il ne doit etre relance qu'au moment ou il redevient utile.
- Avant de se mettre en attente, de demander une intervention a Alexis ou de
  terminer, chaque tache doit fermer les processus gourmands en CPU qu'elle a
  demarres et dont elle n'a plus l'usage immediat.
- Cette regle concerne notamment le jeu, les serveurs, compilations, tests,
  analyseurs, indexeurs, emulateurs et outils graphiques laisses en arriere-plan.
- Une tache ne doit pas fermer arbitrairement un processus systeme, un
  processus d'Alexis ou un processus appartenant a une autre tache. Si un tel
  processus consomme beaucoup de CPU, elle doit le signaler a Alexis.
