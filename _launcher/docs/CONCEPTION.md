# Conception du lanceur Open Sturmovik

## Intention

Le lanceur doit presenter des decisions de pilote, pas l'empilement technique
qui les realise. Un choix comme **Limiter la tolerance aux G negatifs** peut
modifier plusieurs fichiers ou composants internes, mais l'utilisateur ne voit
jamais « desactiver tel mod » comme proposition de reglage.

La cible fonctionnelle est Open Sturmovik 4.09m. Les anciennes versions restent
des outils de diagnostic et ne font pas partie du parcours normal.

Le launcher remplace entièrement l'ancien `il2setup.exe`. Il conserve ce nom de
fichier comme façade de compatibilité pour les appels historiques du jeu, mais
toutes les entrées — raccourci principal, écran de configuration et appel
`il2setup.exe` — utilisent le même moteur de profils, de transaction et de
diagnostic.

## Parcours principal

1. Au demarrage, verifier rapidement les fichiers critiques du profil actif.
2. Montrer un resume : image, realisme, commandes et mode de vue.
3. Permettre de modifier un domaine sans reinitialiser les autres.
4. Montrer les consequences visibles avant toute application.
5. Construire et valider la transaction complete.
6. Sauvegarder les fichiers touches, appliquer, verifier, puis seulement lancer
   le jeu. En cas d'echec, restaurer automatiquement le dernier etat valide.

Le bouton principal est **Appliquer et jouer**. Un lancement direct reutilise
le dernier profil valide sans ouvrir la configuration, sauf si la verification
rapide detecte une anomalie.

## Navigation proposee

### Accueil

Resume des quatre domaines, etat d'integrite, actions **Jouer**,
**Appliquer et jouer** et **Verifier le jeu**.

### Beaute visuelle

Une reglette utilise uniquement des paliers nommes, connus et testes. Elle ne
produit pas de valeurs arbitraires. Chaque palier expose ce que le joueur verra,
l'estimation de memoire du processus x86 et les limites detectees du GPU ou du
wrapper.

Le seul palier actuellement valide est **Haute qualite securisee x86**, derive
de `_Game Switchers/conf.max.ini`. Les paliers superieurs resteront marques
**A valider** jusqu'a ce qu'un test de demarrage, de mission et de consommation
memoire les certifie.

### Realisme

Le realisme est un ensemble de consequences jouables, pas un interrupteur de
mods. Les libelles suivent ces regles :

- verbe ou resultat compréhensible par le pilote ;
- courte explication de l'effet en vol ;
- aucune reference a un nom de mod, une DLL ou un SFS dans le parcours normal ;
- dependances techniques visibles uniquement dans le diagnostic avance.

Premier exemple identifie dans le depot : **Limiter la tolerance aux G
negatifs**. Sa realisation est liee aux donnees AOC des modeles de vol, mais ce
detail n'est pas le reglage propose au joueur. La correspondance exacte reste
en etat `research` tant que les valeurs cibles et la politique client/serveur ne
sont pas validees.

Les profils **Accessible**, **Historique equilibre** et **Simulation** pourront
selectionner plusieurs effets en une fois. Chaque effet restera ajustable et le
resume expliquera les differences en langage de jeu.

### Commandes

Le lanceur gere des profils par pilote et par peripherique. Il doit :

- lire les sections de commandes du `settings.ini` du joueur sans perdre les
  lignes inconnues ;
- construire le catalogue officiel depuis le fichier existant et completer ce
  catalogue avec les commandes declarees par le manifeste Open Sturmovik ;
- signaler les conflits, doublons, axes non detectes et commandes essentielles
  sans affectation ;
- capturer clavier, souris, boutons et axes de joystick ;
- proposer recherche, categories et filtre **Ajoutees par Open Sturmovik** ;
- sauvegarder avant ecriture et permettre l'import/export d'un profil ;
- ne jamais ecraser les commandes personnelles lors d'un changement graphique
  ou de realisme.

Deux `settings.ini` historiques ont maintenant ete compares a un catalogue
produit par analyse statique des classes de commandes. Le releve actuel contient
282 identifiants uniques et leurs affectations observees. Il reste toutefois en
etat de recherche pour l'editeur : une installation 4.09m strictement d'origine
doit etre cataloguee avec la meme methode avant de pouvoir distinguer avec
certitude les commandes historiques de celles ajoutees par les mods. Les
resultats, plages et limites sont documentes dans
`REFERENCE_REGLAGES_COMMANDES.md`.

### Vue et 6DOF

Le choix est explicite : **Vue classique** ou **Vue cockpit 6DOF**. Le lanceur
verifie l'executable, le chargeur et les classes necessaires ; une simple cle
dans `conf.ini` n'est pas une preuve.

Les deux jeux de fichiers 4.09m actuellement disponibles sont strictement
identiques. Le manifeste expose donc la vue classique et bloque honnetement le
6DOF avec une explication. Lorsque des fichiers reellement distincts seront
retrouves et valides, seule la disponibilite du manifeste changera : l'ecran et
le moteur de resolution sont deja prevus pour les deux choix.

### Verification du jeu

Trois niveaux sont prevus :

1. **Rapide** : executables, SFS, wrapper, registres principaux et profil actif.
2. **Complete** : tous les fichiers geres par le manifeste, tailles, SHA-256 et
   coherences transversales deja couvertes par
   `tools/Test-OpenSturmovikContent.ps1`.
3. **Reparer** : telecharger ou retrouver les sources autorisees, preparer une
   transaction, sauvegarder, copier, reverifier et restaurer en cas d'echec.

Les donnees du joueur (commandes, campagnes, captures, skins, missions et
profils personnels) sont exclues de toute reparation automatique. Une anomalie
est classee **Critique**, **Avertissement** ou **Information**, avec une action
formulee en langage clair.

### Confidentialité et diagnostics

Un volet permet d'activer ou désactiver l'envoi automatique des rapports
anonymisés, d'afficher les rapports en attente, de prévisualiser les données,
de les supprimer ou de les envoyer manuellement. Aucun secret GitHub n'est
présent dans le launcher ; un relais HTTPS contrôlé utilise une GitHub App à
permissions minimales. Le contrat complet est décrit dans
`RAPPORTS_ERREURS_GITHUB.md`.

## Architecture

```text
Interface WPF
    -> Modele de presentation
        -> Resolveur de capacites
            -> Catalogue et manifestes versionnes
            -> Detecteurs materiel / installation / peripheriques
        -> Moteur de transaction
            -> Preparation -> sauvegarde -> application -> verification
            -> restauration atomique en cas d'echec
        -> Service d'integrite
            -> controle rapide / complet / rapport / reparation
        -> Adaptateurs IL-2
            -> conf.ini / settings.ini / profils binaires / processus du jeu
        -> Diagnostics
            -> log.lst / exceptions Java / futurs hooks natifs
            -> regroupement -> anonymisation -> file locale consentie
```

Principes structurants :

- **manifeste d'abord** : aucune option active sans sources, empreintes et
  regles de compatibilite ;
- **plan avant ecriture** : fermer sans appliquer ne change rien ;
- **ecriture minimale** : fusionner les cles gerees et conserver les lignes
  inconnues ;
- **transaction unique** : graphismes, realisme, 6DOF et commandes forment un
  seul plan validable et restaurable ;
- **etat hors du jeu** : dernier profil valide, rapports et sauvegardes sont
  stockes dans les donnees applicatives Open Sturmovik ;
- **diagnostic honnete** : une option non prouvee est indisponible, jamais
  simulee par un libelle optimiste.

## Donnees et confidentialite

Les reglages generes restent locaux. Les mots de passe serveur et donnees
personnelles ne sont ni ajoutes au manifeste, ni journalises. Les rapports
d'integrite contiennent des chemins relatifs lorsque cela suffit.

## Premier lot d'implementation

1. Stabiliser le schema et le resolveur en lecture seule (réalisé dans le
   présent socle).
2. Relever de vrais `settings.ini` et construire le catalogue statique
   (realise) ; produire la base 4.09m d'origine avant de classer les commandes
   ajoutees (a faire).
3. Porter dans le futur domaine .NET le moteur transactionnel de référence
   `tools/Set-IL2Configuration.ps1`. Son aperçu, sa préservation des clés
   inconnues, sa sauvegarde et son remplacement atomique sont déjà testés sur
   une copie jetable de `conf.ini` ; aucun fichier réel du jeu n'a été modifié.
4. Creer l'application WPF et brancher l'accueil, l'image et l'integrite.
5. Ajouter l'editeur de commandes, puis le 6DOF des qu'un profil distinct est
   disponible.
6. Construire un paquet autonome, signe et installable, avec deux raccourcis :
   lancement direct et configuration.
