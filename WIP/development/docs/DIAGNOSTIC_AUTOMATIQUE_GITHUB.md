# Diagnostic automatique et rapports GitHub

## Etat verifie avant integration

Le 11 septembre 2026, le depot ne contenait aucun mecanisme d'envoi distant :
aucun dossier `.github`, workflow, appel a l'API GitHub, webhook, jeton ou outil
de creation de ticket n'etait present. Les outils existants savaient deja
produire localement `log.lst`, `eventlog.lst`, `sound.log`, les evenements
Windows, les mesures de processus et des dumps ProcDump, mais ces resultats
restaient sous `WIP`.

Le seul depot GitHub appartenant a Alexis et consacre a Open Sturmovik est
`Alfly-Alyx/IL2-1946-Open-Sturmovik`. Les tickets y sont actives. Le depot
`Alfly-Alyx/il2-1946-patches` concerne les patchs historiques du jeu et n'est
pas la destination des diagnostics de l'extension.

## Fonctionnement installe

`Install-OpenSturmovikDiagnostics.ps1` effectue quatre operations reversibles :

1. il active les journaux persistants d'IL-2 dans `conf.ini` ;
2. il configure Windows Error Reporting pour conserver au plus cinq dumps
   complets de `il2fb.exe` ;
3. il enregistre le moniteur dans le demarrage de session de l'utilisateur ;
4. il le lance immediatement lorsque `-StartNow` est demande.

Le moniteur identifie `il2fb.exe` par son chemin complet. Cela couvre un
lancement par raccourci, par double-clic ou par un outil tiers. Il memorise la
taille initiale de tous les `.log` et `.lst` situes a la racine du jeu ainsi que
les journaux textuels sous `dump`, puis ne traite que les donnees ajoutees au
cours de la session.

Les conditions suivantes creent un rapport :

- erreur ou avertissement explicite du moteur ;
- fichier, texture, materiau, maillage, son, preset, classe ou spawner absent,
  invalide, corrompu, non pris en charge ou impossible a charger ;
- exception Java ou native, assertion, violation d'acces ou manque de memoire ;
- code de sortie non nul ;
- fenetre Windows non reactive pendant au moins vingt secondes ;
- evenement Windows concernant `il2fb.exe`, `wrapper.dll`, `jvm.dll` ou
  `jgl.dll` ;
- creation d'un dump WER.

Lorsqu'un dump est present, le lecteur autonome extrait sans paquet externe le
code et l'adresse d'exception, le thread concerne, le module fautif, le decalage
dans ce module, la version Windows du dump et la liste des modules charges.

Chaque rapport contient le profil reconnu par les empreintes de `il2fb.exe` et
`files.SFS`, l'empreinte du wrapper, la duree et le code de sortie, le contexte
autour des lignes fautives, les parametres utiles de `conf.ini`, Windows, CPU,
memoire, GPU, pilote et l'inventaire des SFS racine. Une signature stable
regroupe les repetitions d'une meme anomalie dans un ticket existant ; une
nouvelle occurrence devient un commentaire avec son propre contexte.

Les noms de fichiers et ressources reconnus dans les messages sont aussi
extraits dans une table `Ressources concernees`. Chaque ligne donne le chemin,
l'extension, le journal et son numero de ligne. Si le message contient un
chemin exploitable, le collecteur controle aussi si le fichier libre existe et
publie son chemin relatif, sa taille et son SHA-256. L'absence est formulee
comme une absence parmi les fichiers libres, car la ressource peut encore se
trouver dans un SFS. Le message complet et ses lignes de contexte restent
affiches juste apres. Les extensions IL-2 usuelles sont couvertes, notamment
TGA, MAT, MSH, HIM, SIM, EMD, PRS, WAV, CLASS, INI, PROPERTIES, MIS, SFS, DLL,
EXE et EFF.

## Transport et reprise sans compte utilisateur

Les rapports expurges sont d'abord ecrits sous
`%LOCALAPPDATA%\OpenSturmovik\Diagnostics\Queue`. Le programme envoie leur
version textuelle au service public HTTPS :

`https://androlink-feedback.alex-baujard.workers.dev/api/open-sturmovik/diagnostic`

Aucun compte GitHub, jeton, Git ou Git Credential Manager n'est necessaire sur
le PC utilisateur. L'authentification GitHub appartient au service Cloudflare,
avec le bot dedie `open-sturmovik-diagnostics`, autorise uniquement sur
`Alfly-Alyx/IL2-1946-Open-Sturmovik` pour les Issues en lecture/ecriture et les
metadonnees en lecture seule. Les trois secrets serveur portent le prefixe
`OPEN_STURMOVIK_GITHUB_` ; aucun repli vers le bot AndroLink n'est autorise.
Le bot dedie est installe et son envoi reel a ete verifie le 12 septembre 2026.
Le PC ne lit plus les anciens identifiants d'environnement ou DPAPI. Le script
historique `Set-OpenSturmovikGitHubCredential.ps1` n'est plus necessaire.

En cas d'absence de reseau, de limite du service ou de refus GitHub, le rapport
reste dans la file. Le moniteur reprend les envois au demarrage et apres chaque
session. La file n'est videe qu'apres reception d'un accuse complet avec le bon
identifiant et une URL d'issue du depot attendu. Un recu local evite de renvoyer
un rapport deja livre. Le JSON est transmis explicitement en UTF-8, y compris
sous Windows PowerShell 5.1.

Le service regroupe les occurrences par signature et rouvre le ticket si
necessaire. Chaque partie porte un marqueur stable pour reprendre les extraits
manquants apres une reponse perdue. Les recus et correspondances de signatures
sont conserves trente jours dans le stockage KV du service. Une empreinte salee
de la connexion limite les envois a dix tentatives par vingt-quatre heures.
Aucun texte de rapport n'est conserve dans ce stockage KV.

L'envoi est borne a 1 000 000 octets et vingt extraits. Si des extraits doivent
etre omis, le ticket le precise et une copie complete du rapport nettoye est
conservee dans `Sent/<identifiant>.report.json` avant suppression de la file.
Les dumps bruts ne sont jamais transmis.

Le service est maintenu dans `feedback/src/worker.js` du projet AndroLink.
Sa route Open Sturmovik impose son depot de destination ; les suggestions
manuelles AndroLink continuent a creer des Discussions dans le depot AndroLink.
Les reprises sont verifiees pour les reponses perdues et les envois concurrents
dans une instance. KV n'etant pas un verrou global, une creation simultanee
depuis plusieurs instances peut exceptionnellement produire un doublon. Les
tickets comportant plus de mille commentaires demandent une intervention de
maintenance pour une reprise automatique sure.

Verification locale sans reseau ni compte :

```powershell
powershell -NoProfile -File tools\Test-OpenSturmovikDiagnosticTransport.ps1
powershell -NoProfile -File tools\Test-OpenSturmovikDiagnostics.ps1
```

Le 12 septembre 2026, ces deux suites passent sous Windows PowerShell 5.1 :
transport sans identifiants, UTF-8, conservation de la file, validation des
recus, absence de renvoi apres livraison, collecte expurgee, lecteur minidump,
moniteur avec un faux processus et installation simulee sans modifier le registre.
L'essai reel du 12 septembre 2026 a cree
[l'issue #2](https://github.com/Alfly-Alyx/IL2-1946-Open-Sturmovik/issues/2)
avec le vrai script `Send-OpenSturmovikDiagnostic.ps1` sous Windows PowerShell
5.1.19041.6456. Le rapport `75a9fe69dfee461aa51e7c9e3d4b27fe` et son unique
commentaire de journal sont entierement fictifs ; leur auteur GitHub observe
est `open-sturmovik-diagnostics[bot]`. Les accents du journal sont intacts.
La file de test contient ensuite zero rapport et la retransmission du meme
rapport retourne `ALREADY_SENT`, avec la meme URL et sans nouveau commentaire.
Aucun jeu installe ni inventaire du PC n'a ete utilise pour cet essai.

La lecture des JSON UTF-8 sans BOM est explicite, car Windows PowerShell 5.1
les interpretait autrement et alterait les accents avant la transmission.
Le test de transport couvre desormais ce format produit par le collecteur.

## Protection des donnees

Avant ecriture dans la file, le collecteur remplace le dossier du jeu, le profil
Windows, les dossiers AppData et temporaire, le nom d'utilisateur et le nom de
machine. Il masque aussi les adresses IP, courriels et lignes ressemblant a un
mot de passe, jeton, secret ou cle API. Ainsi, meme une file hors ligne ne
contient que la version expurgee du rapport.

Les dumps memoire complets restent dans
`%LOCALAPPDATA%\OpenSturmovik\Diagnostics\Dumps`. Leur nom, taille et SHA-256
sont ajoutes au ticket, mais leur contenu n'est jamais envoye automatiquement :
un dump peut contenir des fragments de documents, identifiants ou conversations
issus de la memoire du processus. Il peut etre analyse localement avec les
outils de retro-ingenierie deja presents, puis un resultat textuel expurge peut
etre ajoute au ticket.

## Limites connues

- Le moniteur doit etre actif pour attribuer avec certitude les nouveaux
  journaux a une session. Son enregistrement au demarrage et son lancement par
  l'installateur reduisent cette fenetre, sans pouvoir couvrir une session
  Windows ou PowerShell aurait ete explicitement bloque.
- La propriete Windows `Responding` qualifie un gel de l'interface. Un defaut
  visuel sans message de journal, evenement, gel ou fermeture anormale ne peut
  pas etre devine automatiquement.
- L'authentification GitHub est geree par le service. Si ce service ou son bot
  est indisponible, la collecte reste locale et les rapports sont conserves
  pour une tentative ulterieure, sans demander de compte GitHub au joueur.
- Le dump brut n'est pas televerse vers le depot public. Cette limite est
  volontaire et n'empeche pas la publication de son empreinte et de son analyse
  textuelle expurgee.

## Verification reproductible

Le test hors jeu cree une fausse installation, ajoute une
`FileNotFoundException`, un chemin utilisateur, un courriel, une adresse IP et
un faux secret, ainsi qu'une texture libre existante. Il controle la detection,
l'identification du profil, la redaction, le chemin et la ligne de la ressource,
son etat sur disque, sa taille, son SHA-256 et le rendu GitHub. Il verifie aussi
qu'une fermeture propre sans nouveau message ne produit pas de rapport, que le
lecteur reconnait un minidump minimal, qu'un faux processus `il2fb.exe` est
observe de bout en bout et que l'installation `-WhatIf` ne touche pas au
registre :

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-OpenSturmovikDiagnostics.ps1
```

Validation effectuee le 11 septembre 2026 :

- le test complet retourne `PASS` sous Windows PowerShell 5.1, avec detection
  de trois anomalies synthetiques, redaction, rendu GitHub, fermeture saine,
  lecture de minidump et surveillance du faux jeu valides ;
- l'installation de test contient les sept composants runtime avec les memes
  SHA-256 que le depot, un seul moniteur actif, tous les journaux IL-2 demandes
  et la politique WER `DumpCount=5`, `DumpType=2` ;
- Git Credential Manager a ete valide depuis Windows PowerShell 5.1 contre le
  depot cible, avec les tickets actives et sans enregistrer un second jeton ;
- l'essai reel de transport a cree le ticket GitHub
  [#1](https://github.com/Alfly-Alyx/IL2-1946-Open-Sturmovik/issues/1), puis ce
  ticket de controle a ete ferme avec la raison `completed`.

Les composants sont :

- `Watch-OpenSturmovikDiagnostics.ps1` : surveillance et reprise de file ;
- `Collect-OpenSturmovikDiagnostic.ps1` : detection, contexte et expurgation ;
- `Send-OpenSturmovikDiagnostic.ps1` : creation ou mise a jour du ticket ;
- `Read-OpenSturmovikMinidump.ps1` : exception et modules d'un dump natif ;
- `Install-OpenSturmovikDiagnostics.ps1` : journaux, WER et demarrage ;
- `Set-OpenSturmovikGitHubCredential.ps1` : ancien utilitaire DPAPI, inutilise par le transport actuel ;
- `Test-OpenSturmovikDiagnostics.ps1` : regression hors jeu.

## Identite du service verifiee le 12 septembre 2026

- GitHub App : `open-sturmovik-diagnostics`, App ID `4918929`.
- Installation : `161089524`, limitee au depot Open Sturmovik ; Issues en
  lecture/ecriture et Metadata en lecture seule.
- L'ancienne application `androlink-feedback` ne dispose plus de l'acces a ce
  depot et conserve uniquement AndroLink.
- Les trois secrets propres au bot sont enregistres dans Cloudflare. La copie
  temporaire de la cle telechargee pour la configuration a ete supprimee.
- Version du service testee : `e5cc4277-e5f5-4b11-a3a6-088320a1b13e`.

Ces essais valident les sources de la branche v1.15 et le service distant.
Ils ne constituent pas une installation ou une publication d'une nouvelle
version du jeu.