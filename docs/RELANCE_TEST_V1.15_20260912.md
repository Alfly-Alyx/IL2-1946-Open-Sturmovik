# Mise a jour et relance du test v1.15 — 12 septembre 2026

Alexis a demande d'actualiser et de relancer la copie de test, puis de
committer et pousser sur `v1.15`, avant un inventaire de l'espace recuperable.
La branche et la racine partagee sont restees inchangees.

## Copie synchronisee

Racine du depot :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik`.
La seule installation modifiee est
`WIP/test-installations/IL 2 Sturmovik 1946 test`.
La reference `WIP/resources/IL2/IL 2 Sturmovik 1946` est restee en lecture seule.

La selection part de la synchronisation complete du 9 septembre, de ses
changements ulterieurs, des manifestes de retraits et des fichiers actuels
de licence, credits et outils. Elle inclut les 266 profils AOC du pack.
Elle exclut `conf.ini`, `Users`, `_Game Switcher/conf.ini` et
`_Game Switcher/active-profile.txt`.

Le plan comporte 1 963 entrees : 698 copies potentielles et 1 265 retraits.
**1 527 operations effectives** ont ete appliquees : **287 copies** et
**1 240 retraits recuperables** ; 436 entrees etaient deja conformes.
Le profil existant **9 / 4.09m avec 6DOF / HUD standard / DirectX** est
conserve. Les fichiers actifs correspondent deja au profil 9 ; aucune
reapplication du switcher n'a ete necessaire. Les empreintes des neuf fichiers
de reglages et de profils joueur controles sont identiques avant/apres.

La sauvegarde transactionnelle est
`WIP/test-installations/sync-20260912-141157` :
1 317 anciens fichiers conserves, 210 nouveaux chemins, un recu et un rapport
de contenu. Elle permet le retour a l'etat precedent et doit etre conservee
pendant les essais du nouveau contenu.

Une seconde synchronisation ciblee a ensuite remplace les six executables
modifies par les variantes dont l'icone de fenetre est corrigee, puis a
reapplique le profil 9. Ses onze fichiers et leurs anciens exemplaires sont
conserves dans `WIP/test-installations/sync-20260912-145919`. Les trois
executables Original sont restes strictement identiques.

Deux tentatives precedentes ont ete annulees avec restauration automatique :
un refus d'acces du bac a sable, puis la detection de quatre missions MDS
propres au test. Ces quatre missions sont identiques par SHA-256 aux exemples
deja archives avec le retrait MDS ; elles ne sont pas des adaptations joueur.
Elles n'ont aucun texte associe. Leur liste figure dans
[le manifeste de relance](../manifests/test/relaunch-v115-20260912.json).
La derniere synchronisation les retire avec sauvegarde, sans exception au test.

## Resultats verifies

- Contenu de test : **24 PASS, 1 WARN, 0 FAIL**, sans echec autorise.
  Le WARN indique l'absence d'un nouveau dump des classes chargees en execution.
- Retrait MDS : **1 927 classes examinees**, 648 chemins retires absents,
  51 chemins nettoyes et neuf archives de profils controles.
- AOC : trois classes sans MDS et **266 profils conformes**.
- Disponibilite avant lancement : **42/42**, `Ready=True`, sans changement
  de resolution ou des reglages du joueur.
- Disponibilite apres la correction des icones : **48/48**, `Ready=True`.
- Rotation des fonds : installee et activee en mode aleatoire avec les quatre
  images choisies et le fond officiel `il2-2001` prioritaire.
- Test GUI du switcher : PASS ; lecture et comparaison de l'ancien `.iss`
  sautees explicitement, car ce fichier a ete supprime.
- Test des utilitaires sans Bureau : PASS. Le controle des liens verifie
  maintenant la cible effective `mshta.exe` et les arguments JavaScript exacts.
  Huit liens temporaires passent, et deux contre-epreuves rejettent une cible
  BAT incorrecte et une casse incorrecte des arguments.

Limite du dernier controle : a la premiere creation du lien temporaire du
switcher, Windows a restitue `C:\Windows\System32` comme dossier de travail.
La valeur preparee et affectee par le generateur etait correcte. Le lien
temporaire a ete corrige pour eprouver le test ; le generateur et le vrai
Bureau n'ont pas ete modifies. Ce resultat ne valide pas la creation initiale
de ce raccourci dans le futur installateur.

## Lancement et limites

`il2fb.exe` a ete lance depuis le dossier de test le 12 septembre 2026 a
14:13:38, heure de Paris. La capture fournie par Alexis montre ensuite le titre
Open Sturmovik, la version **4.09m** et le chargement a **5 %**.
A sa demande, la mention Windows « Ne repond pas » n'est pas interpretee
comme une anomalie. Le jeu est laisse ouvert pour ses essais.

Apres la correction des icones, le profil 9 a ete relance a 15:01:28 avec
l'executable SHA-256
`7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21`.
La fenetre native portait le titre `Open Sturmovik`. Son icone de classe
32 x 32 etait identique pixel par pixel a l'icone source `avion-ciel`, sans
aucun pixel different. Alexis a confirme visuellement l'icone dans la barre de
titre et la barre des taches. Le jeu a ensuite ete ferme avant les controles
finaux et le commit.

L'arrivee au menu et les vols ne sont pas declares reussis par ce compte rendu.
Les deux armements CW-21, son moteur, les fonctions reconstruites apres retrait
MDS, AOC, 6DOF et la campagne de non-regression restent a exercer en jeu.
La qualification finale de la v1.15 reste distincte de cette relance.
Aucun nouvel installateur, executable de distribution, tag ou release n'est cree.
Les anciennes captures ne prouvent pas le comportement de cette composition.

## Preuves locales et reproduction

Le dossier local de preuves est
`C:\Users\Alexis\.codex\visualizations\2026\09\12\01a094b0-535f-7413-93c1-d5a15ca65ad3` :
plan `relaunch-v115-20260912-plan.json`, empreintes personnelles
`relaunch-v115-settings-before.json`, controle `relaunch-v115-readiness.json`
et lancement `relaunch-v115-process.json`. Les donnees personnelles et les
journaux bruts ne sont pas ajoutes a Git.

Le plan utilise `New-OpenSturmovikTestSyncPlan.ps1` avec `OnlyIncludedPaths`
et une liste explicite. `Sync-OpenSturmovikTestContent.ps1 -Apply` verifie les
empreintes, sauvegarde les anciens fichiers et valide le contenu avant de
produire son recu. Le controle avant lancement est
`Test-IL2StartupReadiness.ps1 -Profile 9 -ExcludeNuclear`, avec les racines
explicites du depot, du test et de la reference. Le controle MDS reproductible
est `Test-NoMds.py --content-root <copie-test> --manifest-root <depot>`.
Ces controles doivent etre executes jeu ferme ; ne pas resynchroniser une
session en cours.
