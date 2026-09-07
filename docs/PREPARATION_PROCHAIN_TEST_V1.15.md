# Preparation du prochain test v1.15

Derniere mise a jour : 1er septembre 2026.

## Candidat pause nucleaire invalide en jeu

La capture `20260901-060621Z-profile9-warm-windowed1024-startup` a prouve que
la pause fige bien l'horloge de simulation, mais que le sous-systeme natif des
emetteurs reconstruit leur age apres le retour du rendu 3D. Le panache pleinement
forme redevient une petite sphere a la premiere image de reprise, puis rattrape
environ 5,5 secondes plus tard. Le processus reste repondant et la memoire est
stable : ce n'est ni un gel de la JVM, ni un manque de RAM.

Le candidat suivant enregistrait seulement les douze emetteurs Little Boy/Fat
Man et l'emetteur stabilise. Une surveillance partagee detectait les transitions
de pause sur une horloge reelle et appelait la pause native de ces effets. Elle
ne modifiait pas le menu, les nuages meteorologiques, les fumees ou les
explosions conventionnelles.

Ce candidat a depuis ete teste dans
`20260901-131015Z-profile9-warm-windowed1024-startup` et **n'est pas valide**.
Le panache Little Boy repart de zero apres pause/reprise. Il repart aussi apres
un demi-tour qui le retire puis le remet dans le champ de la camera. Aucun
message d'indisponibilite de l'API native n'apparait : le correctif ne traite
pas la reconstruction/coupure du rendu des particules.

Les trois classes concernees ont ete synchronisees transactionnellement dans le
seul dossier de test. Sauvegarde recuperable :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260901-083925`

La chaine de fichiers reste saine : l'audit dedie obtient 33 PASS et zero echec
statique. Cela valide les classes, emports, maillages, textures, materiaux et
limites declarees, pas le rendu final. La surveillance a 25 ms ne doit pas etre
consideree comme une correction livrable ; sa suppression ou son remplacement
et la duree de retention des `Eff3DActor` doivent etre traites avant le prochain
essai nucleaire de qualification.

Le dix-septieme controle couvre la carte Slovakia. Sa surcharge `load.ini`
demandait `actors.static`, alors que le SFS officiel 4.09m contient et demande
`actors_summer.static`. Une seule ligne a ete synchronisee et l'ancienne version
reste dans la sauvegarde recuperable :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260901-085130`

Le fichier officiel de 5,8 Mio n'a pas ete duplique : le chemin corrige restaure
le repli normal vers `fb_maps15.SFS`.

Le prochain essai nucleaire devra etre lance seulement apres un nouveau candidat.
Il comparera Little Boy puis Fat Man sans pause et avec pause, un demi-tour, une
sortie volontaire du champ, l'eclair image par image et un airburst sur l'eau.
Une mission dense devra mesurer les acteurs d'effets encore vivants. Alexis doit
etre prevenu avant l'armement de la capture et avant le lancement du jeu.

## Etat pret avant redemarrage

La synchronisation a ete autorisee puis appliquee au seul dossier
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`. L'installation originale
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946` est restee strictement en lecture
seule. La sauvegarde transactionnelle recuperable est :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-121346`

Le controle statique du projet donne **15 PASS, 1 WARN, 0 FAIL**. Le seul WARN
est normal avant un nouveau lancement : aucun Dump runtime recent n'a encore
confirme les classes effectivement chargees.

Apres synchronisation et activation du profil 9, le meme controle sur le jeu de
test donne egalement **15 PASS, 1 WARN, 0 FAIL**. La validation de disponibilite
complete passe maintenant ses **45 controles** et retourne `Ready=True`, dont
la verification explicite de `LandGeom` selon le fournisseur du GPU.

Trois lancements ont atteint le menu puis Alexis a ferme volontairement le jeu.
Le second a confirme la disparition des six presets moteur invalides. Il a
aussi isole la derniere incoherence graphique : `LandGeom=3`, reserve au mode
Perfect, etait la seule valeur reecrite par le moteur en `2`. Le profil Intel
securise utilise maintenant `HardwareShaders=0`, `Forest=2`, `LandGeom=2` et
`Water=2`. Le troisieme lancement a conserve `conf.ini` octet pour octet et a
atteint le menu en 94,4 secondes. L'analyse hors jeu du coeur 4.09m montre que
les deux lignes Perfect proviennent de l'absence de l'ancienne extension
`GL_NV_texture_shader` sur le pilote Intel, meme si les shaders ARB modernes
sont presents. Elles sont maintenant classees comme avis de capacite attendu
par `tools/Test-IL2GraphicsCompatibility.ps1`; aucune matrice de lancement
supplementaire n'est necessaire pour ce point.

La synchronisation corrective a cree une seconde sauvegarde recuperable :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-132504`

La normalisation finale des dix presets a ensuite cree :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-133554`

La synchronisation du correctif `LandGeom` et du selecteur a cree :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test.sync-backup-20260831-144614`

## Plan transactionnel prepare

Le manifeste `manifests/test/v1.15-test-sync.json` contient les empreintes de la
source et de la copie de test avant intervention. Il a applique :

- 209 fichiers a copier ou remplacer ;
- 26 anciens presets sonores a retirer de leur emplacement conflictuel ;
- 235 entrees dans le plan ; lors de la seconde application, 31 operations
  restaient a faire et 204 fichiers etaient deja conformes.

Les retraits ne seront pas detruits : les anciens fichiers seront deplaces dans
une sauvegarde horodatee placee a cote du dossier de test. Le script refuse le
jeu original, les liens de dossiers, un plan devenu perime et toute operation
pendant qu'IL-2 est actif. Une validation fonctionnelle automatique est lancee
apres la copie ; en cas d'echec, les anciens fichiers sont restaures.

La simulation deja executee n'a rien modifie :

```powershell
& .\tools\Sync-OpenSturmovikTestContent.ps1 `
  -DestinationRoot 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test'
```

La commande autorisee et executee a ete :

```powershell
& .\tools\Sync-OpenSturmovikTestContent.ps1 `
  -DestinationRoot 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test' `
  -Apply
```

## Configuration active

La copie est configuree avec :

- profil 9, 4.09m modde et choix historique 6DOF ;
- wrapper historique et OpenGL natif ;
- EXE PE32 Large Address Aware ;
- 1024 x 768 fenetre ;
- qualite graphique x86 securisee pour Intel UHD 620 ;
- affinite `85`, soit quatre coeurs physiques sur cette machine ;
- journaux de diagnostic actifs.

Le selecteur avertit que les fichiers historiques du choix 6DOF sont binairement
identiques a ceux du profil sans 6DOF. Le libelle est donc conserve, mais cette
copie ne prouve pas encore qu'un comportement 6DOF distinct est active.

## Reprise apres redemarrage

Alexis redemarre le PC avant la capture. Aucune capture et aucun jeu n'ont ete
lances pendant cette preparation. Apres le redemarrage :

1. verifier rapidement qu'aucun processus parasite ou ancien enregistreur ne
   tourne ;
2. prevenir Alexis avant d'armer la capture ;
3. armer la capture avec la commande ci-dessous ;
4. lancer `il2fb.exe` seulement apres l'affichage `CAPTURE_ARMEE` ;
5. ne plus afficher Codex ni le Gestionnaire des taches devant la fenetre IL-2 ;
6. rester quelques secondes au menu, fermer proprement et analyser les erreurs,
   les temps par palier et les acces aux fichiers.

```powershell
& .\tools\Start-OpenSturmovikProfile9Capture.ps1
```

La premiere execution reste un demarrage instrumente, pas encore une mission.
Les objectifs runtime sont : zero `FileNotFoundException`, zero `No spawner`,
zero exception Zuti, zero refus d'enregistrement de navire, et disparition des
63 avertissements `Str2FloatClamp` connus. La validation du Dump devra aussi
confirmer qu'aucune classe chargee ne depasse Java major 47.
