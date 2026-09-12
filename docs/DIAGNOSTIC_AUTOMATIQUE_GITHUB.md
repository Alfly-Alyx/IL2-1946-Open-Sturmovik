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

## Transport, reprise et authentification

Les rapports expurges sont d'abord ecrits sous
`%LOCALAPPDATA%\OpenSturmovik\Diagnostics\Queue`. L'envoi utilise l'API des
tickets GitHub. En cas d'absence de reseau, de limite API ou d'identifiant, le
fichier reste dans la file et sera repris au prochain demarrage du moniteur ou
a la fin de la prochaine session de jeu.

L'identifiant est cherche dans cet ordre :

1. variable de processus `OPEN_STURMOVIK_GITHUB_TOKEN` ;
2. jeton chiffre par DPAPI pour l'utilisateur courant ;
3. Git Credential Manager, lorsqu'une connexion GitHub existe deja.

Le jeton DPAPI peut etre configure interactivement avec :

```powershell
powershell -ExecutionPolicy Bypass -File tools\Set-OpenSturmovikGitHubCredential.ps1
```

Sur la machine de developpement d'Alexis, Git Credential Manager fournit deja
une authentification valable pour le depot, sans copie du secret dans le pack.

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
- L'API GitHub exige une authentification. Sans elle, la collecte reste complete
  et locale, mais aucun programme ne peut creer anonymement un ticket GitHub.
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
- `Set-OpenSturmovikGitHubCredential.ps1` : configuration DPAPI facultative ;
- `Test-OpenSturmovikDiagnostics.ps1` : regression hors jeu.
