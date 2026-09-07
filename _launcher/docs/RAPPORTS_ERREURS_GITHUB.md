# Rapports d'erreurs anonymisés vers GitHub

## Objectif

Le launcher doit pouvoir recueillir les erreurs Open Sturmovik, notamment les
textures introuvables, sons introuvables, exceptions Java, erreurs natives,
échecs graphiques et incohérences d'intégrité. Après consentement du joueur, il
peut envoyer automatiquement un rapport minimisé afin que le mainteneur le
retrouve dans un dépôt GitHub dédié.

Le système ne désactive ni ne modifie le rapport d'erreurs global de Windows.
L'option **Envoyer automatiquement les rapports anonymisés** contrôle uniquement
le composant Open Sturmovik.

## Consentement et désactivation

- Aucun envoi externe avant une décision explicite au premier lancement.
- Une fois activé, l'envoi automatique peut être désactivé immédiatement dans
  **Confidentialité et diagnostics**.
- La désactivation arrête les envois et la relance en arrière-plan ; la collecte
  locale minimale nécessaire au diagnostic du lancement peut rester active.
- Les rapports en attente sont visibles, supprimables ou envoyables manuellement.
- Un aperçu exact du JSON anonymisé est disponible avant un envoi manuel.
- Un changement de politique de confidentialité exige un nouveau consentement.
- Les dumps mémoire complets ne sont jamais envoyés automatiquement.

## Architecture retenue

```text
IL-2 / hooks Open Sturmovik / journaux autorisés
    -> événements structurés locaux
    -> normalisation + regroupement + anonymisation
    -> file locale bornée et chiffrée par Windows
    -> relais HTTPS Open Sturmovik
    -> GitHub App (jeton d'installation court)
    -> dépôt privé de rapports, Issues et commentaires
```

Le client ne parle pas directement à l'API GitHub et ne contient aucun secret.
La clé privée de la GitHub App reste sur le serveur, idéalement dans un coffre
de clés utilisable uniquement pour signer. Le relais génère un jeton
d'installation temporaire et dispose seulement du droit **Issues: read/write**
sur le dépôt de rapports sélectionné.

## Pourquoi un relais est obligatoire

Une application GitHub s'authentifie avec une clé privée pour signer un JWT,
puis obtient un jeton d'installation. Distribuer cette clé ou un secret client
dans le launcher donnerait à tout utilisateur la capacité d'agir comme
l'application. Le relais est donc la frontière de confiance : il valide,
limite, déduplique et transmet les rapports sans exposer les identifiants GitHub.

## Données autorisées

Le contrat `_launcher/manifests/error-report.schema.json` utilise une liste
positive. Tout champ non déclaré est rejeté.

Données possibles :

- version du jeu, du launcher et du manifeste actif ;
- type, sévérité et compteur de l'événement ;
- chemin relatif normalisé d'une ressource située sous le dossier du jeu ;
- code d'erreur, module et offsets de pile sans adresse absolue ;
- classe, méthode, fichier source et numéro de ligne d'une pile Java, sans
  argument, variable locale ni contenu mémoire ;
- famille et version de Windows, architecture, fournisseur GPU, identifiant de
  périphérique et version de pilote si le joueur l'a accepté ;
- identifiant aléatoire de session, recréé à chaque lancement ;
- empreinte SHA-256 de l'erreur normalisée pour la déduplication.

## Données interdites

- nom d'utilisateur Windows, nom de machine, adresse électronique ;
- chemin absolu, variables d'environnement et liste générale des fichiers ;
- adresses IP, ports, serveurs récents et contenu réseau ;
- identifiants de pilote IL-2, conversations, mots de passe ou presse-papiers ;
- numéro de série matériel, adresse MAC ou identifiant publicitaire ;
- `conf.ini` complet, `settings.ini` complet ou journal brut ;
- capture d'écran, mission personnelle ou dump mémoire automatique ;
- identifiant d'installation persistant permettant de suivre un joueur.

Le fournisseur du relais voit nécessairement l'adresse IP pendant la connexion.
Elle sert seulement à la protection anti-abus en mémoire à courte durée et ne
doit être ni journalisée ni transmise à GitHub.

## Collecte exhaustive des ressources manquantes

Un simple parseur de `log.lst` ne peut pas promettre de détecter tous les échecs.
La collecte doit être placée au plus près des chargeurs :

1. événements existants de la console pour les erreurs déjà journalisées ;
2. instrumentation Java autour des résolveurs de ressources, textures, effets
   et échantillons ;
3. instrumentation native du chemin SFS/fichiers et des créations de textures
   ou buffers sonores lorsqu'aucun événement Java n'existe ;
4. capture des exceptions Java non traitées et des erreurs natives sous forme
   module + offset ;
5. vérificateur d'intégrité du launcher avant lancement.

Chaque point d'instrumentation émet un événement structuré et limité. Il ne
copie pas un journal arbitraire. Une ressource manquante répétée mille fois est
agrégée en un événement avec `occurrences=1000`, première et dernière date.

L'exhaustivité ne sera annoncée que lorsque chaque chemin de chargement aura une
preuve statique et un test négatif contrôlé.

### Premier collecteur vérifié

`_launcher/tools/Convert-IL2LogToEvents.ps1` transforme actuellement les formes
de messages observées en événements structurés et regroupés. Les expressions
reconnues sont versionnées dans
`_launcher/manifests/diagnostic-patterns.json`. Elles couvrent notamment :

- `Cannot load sound preset ...` ;
- `warning: no files : ...` ;
- les textures et matériaux que le moteur indique ne pas pouvoir charger ;
- les préchargements de ressources échoués et archives SFS absentes ;
- les composants de maillage introuvables ;
- les exceptions/erreurs Java avec leurs trames ;
- les messages `INTERNAL ERROR`, `ERROR` et `FATAL` restants.

Le test autonome utilise un journal synthétique et vérifie neuf catégories
concrètes, leur regroupement, leur anonymisation et leur conformité au schéma.
Sur le journal existant
`test-results/startup/20260901-131015Z-profile9-warm-windowed1024-startup/logs/log.lst`,
le collecteur a regroupé 148 occurrences en 59 événements : 68 occurrences
d'exceptions Java, 57 de ressources absentes, 17 d'erreurs sonores et 6 autres
erreurs. Ce relevé a été effectué en lisant le fichier déjà présent ; aucun
programme du jeu n'a été lancé.

Cette étape ne couvre pas encore les échecs silencieux des chargeurs natifs ni
les arrêts du processus avant vidage du journal. Ces deux chemins nécessiteront
respectivement les points d'instrumentation moteur et un observateur de
processus dans la future application.

## File locale et résilience

- Taille maximale proposée : 10 Mio et 5 000 événements agrégés.
- Conservation maximale proposée : 14 jours.
- Écriture atomique et reprise après coupure.
- Chiffrement lié au compte Windows lorsque l'API est disponible.
- Envoi par lots, temporisation exponentielle et respect de `Retry-After`.
- Aucun blocage du lancement ou de la fermeture du jeu.
- Un rapport rejeté par le schéma reste local avec une explication ; il n'est
  jamais envoyé « au mieux ».

## Organisation dans GitHub

Le relais crée une Issue par empreinte d'erreur dans un dépôt privé, puis ajoute
des occurrences agrégées en commentaires. Exemple de titre :

`[missing-texture] 3do/plane/.../skin.tga — Open Sturmovik 1.15`

Labels prévus :

- `telemetry:auto` ;
- `kind:missing-texture`, `kind:missing-sound`, `kind:crash`, etc. ;
- `version:1.15` ;
- `severity:error` ;
- `status:triage`.

Le corps contient le résumé lisible et le JSON conforme au schéma. Les longues
listes sont fractionnées en commentaires, sans dépasser les limites GitHub. Le
relais maintient localement la correspondance empreinte -> numéro d'Issue afin
d'éviter une recherche GitHub à chaque événement.

## Limitation d'abus

- corps HTTPS limité à 256 Kio ;
- validation stricte du type et de la taille de chaque champ ;
- quotas par jeton de session et limite transitoire par adresse réseau ;
- challenge anti-automatisation lors de l'activation initiale si nécessaire ;
- regroupement côté client et côté relais ;
- temporisation exponentielle sur les réponses 403/429 ;
- interdiction des pièces jointes et du Markdown non généré par le relais.

## Étapes de réalisation

1. Stabiliser le schéma et le moteur local d'anonymisation.
2. Identifier et tester chaque source d'événement sans réseau.
3. Ajouter la page de consentement, l'aperçu et la suppression de file.
4. Créer un dépôt privé de rapports et une GitHub App limitée aux Issues.
5. Déployer le relais avec clé protégée, quotas et journal serveur sans IP.
6. Effectuer un test fermé, auditer les rapports et seulement ensuite proposer
   l'activation aux joueurs.
