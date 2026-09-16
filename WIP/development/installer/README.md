# Installeur complet Open Sturmovik 1.15

Ce dossier contient le nouvel installeur complet d'Open Sturmovik 1.15.
Il ne s'agit pas d'un patch pour une ancienne version d'Open Sturmovik.
Les anciens scripts Inno Setup ne servent pas de reference.

Le Payload final contient 129 483 fichiers pour 26 257 828 361 octets. La
compilation definitive de la presentation standard avec Inno Setup 6.7.3 a
reussi le 15 septembre 2026. Elle a dure 4 765,687 secondes
(1 h 19 min 26 s) et produit huit fichiers .bin, un executable Setup et
SHA256SUMS.txt pour 7 446 546 037 octets au total, manifeste compris.

Inno Setup 6.7.3 a ete retenu apres comparaison avec l'ancien installeur 1.1,
qui a ete compile avec Inno Setup 6.3.0 et utilise lui aussi le lanceur normal
SetupLdr. Aucun ancien script d'installation n'a ete repris. Le changement de
compilateur conserve donc l'organisation classique Setup.exe + fichiers .bin,
sans ajouter de Setup-0.bin.

L'installation est prevue par-dessus un IL-2 Sturmovik 1946 d'origine en
version 4.07m, 4.08m, 4.09b ou 4.09m. Le script tente de retrouver le dossier
du jeu depuis les entrees de desinstallation Windows et les emplacements
courants Steam, Ubisoft et GOG. Cette detection sert uniquement a proposer
un chemin. La version presente n'est ni lue ni verifiee et un dossier choisi
manuellement n'est pas refuse au motif qu'il ne serait pas reconnu comme une
base compatible.

Le seul refus automatique concerne un dossier qui contient deja Open
Sturmovik. Les marqueurs controles sont :

- .open-sturmovik-installed ;
- Open Sturmovik Switcher.exe, present dans la release v1.1 ;
- Open_Sturmovik_Switcher.bat ;
- _Game Switchers, present dans la release v1.1 ;
- _Game Switcher ;
- _Game_Enhancements.

L'installeur n'enregistre pas de desinstalleur. Comme il remplace des fichiers
d'une installation IL-2 existante, un desinstalleur classique ne pourrait pas
reconstituer proprement la version d'origine du jeu.

## Protection des donnees du joueur

Le dossier Users n'entre jamais dans le Payload et n'apparait dans aucune
source Inno. Les profils, le nom du joueur, les commandes, les preferences et
la progression qui s'y trouvent restent donc inchanges.

Les fichiers deja presents dans Missions et PaintSchemes ne sont pas
remplaces. Le pack ajoute uniquement les fichiers absents dans ces deux
dossiers afin de conserver les missions, campagnes et peintures personnelles.

Le seul fichier de configuration volontairement remplace est le conf.ini de
la racine. Avant toute copie :

1. le conf.ini existant est renomme en conf.ini.bak ;
2. si ce nom existe deja, une sauvegarde datee unique est creee ;
3. le fichier valide _Game Switcher\conf.ini est copie a la racine ;
4. si l'installation est interrompue apres la sauvegarde, l'ancien conf.ini
   est restaure.

Le fichier source valide est :

    D:\Projets\GITHUB\IL2-1946-Open-Sturmovik\_Game Switcher\conf.ini

Le fichier livre contient une resolution de repli de 1024 x 768. A la fin de
l'installation, un outil detecte la resolution active de l'ecran principal
Windows et inscrit cette largeur et cette hauteur dans le conf.ini de la
racine. Le raccourci Open Sturmovik refait la detection avant chaque lancement.
Le raccourci du switcher ouvre directement le selecteur, sans lancer cette detection.
Le jeu reste configure en plein ecran (`FullScreen=1`, `ChangeScreenRes=1`) et
la musique utilise `MusicVolume=2`, valeur choisie et validee directement
dans le jeu par Alexis pour le pack.

Le test reel du 13 septembre a inscrit 1920 x 1080 et le moteur a confirme
Size: 1920x1080 dans log.lst. Les menus restent bases sur une geometrie
logique 1024 x 768 : leurs polices peuvent donc paraitre grandes sans que le
rendu soit revenu a cette resolution. Leur echelle interne reste inchangee.

Son empreinte SHA-256 lors de la preparation est :

    77B73E1F14CB7FEBF9EC14B63A68D42A45AF4BB7D26AA6978DF2143D8C7B6103

## Information de licence

NOTICE_INSTALLATION.txt est affiche avant la copie. Cette page informe
l'utilisateur que le pack est gratuit, que les contributions originales
d'Alfly sont partageables pour les usages non commerciaux, et que les
elements tiers conservent leurs propres conditions.

Aucune case d'acceptation n'est demandee. Les textes complets LICENSE.md,
docs\LICENSING.md et docs\THIRD_PARTY_NOTICES.md sont livres dans le Payload.

## Raccourcis du Bureau

Onze raccourcis sont crees sur le Bureau commun Windows :

- Open Sturmovik, avec adaptation automatique a l ecran principal et icone issue de
  l'executable il2fb.exe actif a la racine ;
- Open Sturmovik Switcher, avec ouverture directe, console masquee et icone propre ;
- Bombsight Table 2 ;
- HardBall 4.08 ;
- IL2 Sticks ;
- IL2 Compare ;
- JoyCtrl ;
- Mission Mate 6 ;
- Quick Mission Tuner ;
- WeatherSet ;
- ZipNav.

Aucun utilitaire n'est lance automatiquement pendant ou apres l'installation.

## Organisation des profils du switcher

Les neuf dossiers historiques sont conserves, car chacun correspond directement
a un choix de l'interface. Ils contiennent maintenant tous leurs fichiers moteur.
Le sous-dossier `Profiles\Files` de chacun contient aussi sa classe `Plane` compatible : variante historique pour 4.08m/4.09b, variante v1.15 pour 4.09m.
Le dossier partage `Version Payloads` a ete supprime du depot et du Payload.
Le document `docs\ORGANISATION_PROFILS_SWITCHER.md` decrit leur contenu et les
controles d'integrite.
## Identite visuelle

L'assistant utilise la presentation et les couleurs standard du style moderne
d'Inno Setup. Il n'embarque aucun fond, aucune colonne illustree et aucun
panneau personnalise. Cette presentation conserve les controles natifs et leur
comportement normal sur toutes les versions de Windows.

Une page d'accueil textuelle precede la page Information. Elle affiche
**Open Sturmovik** en grand puis la formule
**Made possible by the community, for the community**, sans grande
illustration.

Le petit logo transparent
exec-37073acd__logo-IL2-A__master-1024.png apparait en haut a gauche de
l'en-tete des pages. Le titre et la description sont decales vers la droite
pour ne jamais le recouvrir. L'executable Setup conserve l'icone Windows
exec-0631d7c4__avion-carte__Windows.ico, derivee de l'illustration
exec-0631d7c4__avion-carte__master-1024. Les anciennes ressources graphiques
restent rangees dans assets comme references de travail, sans etre incluses.

La rotation des fonds de chargement du jeu est un mecanisme distinct et reste
active. Ses lanceurs sont _Game Switcher\Open_Sturmovik_Fonds.vbs et
_Game Switcher\Open_Sturmovik_Fonds.bat. Il est documente dans
docs\ROTATION_FONDS_CHARGEMENT.md.
## Parties de 1 Go

Le script Inno active le decoupage avec :

    DiskSpanning=yes
    SlicesPerDisk=1
    DiskSliceSize=1000000000

Chaque fichier .bin produit est donc limite a 1 000 000 000 octets.
Le controle final a confirme cette limite pour les huit parties et a produit
Output\SHA256SUMS.txt. Six parties font exactement 1 000 000 000 octets ;
la partie 1 fait 984 962 048 octets, la partie 8 fait 446 545 533 octets et
l'executable fait 15 037 567 octets. Les neuf fichiers doivent toujours etre
conserves et distribues ensemble.

## Incident du premier essai reel

Le premier essai reel du 14 septembre 2026 s'est interrompu apres la copie
d'environ 16,14 Gio. Deux causes ont ete observees :

- F-Secure a place Open-Sturmovik-1.15-Setup.exe en quarantaine sous le
  verdict heuristique Drop.Win32.FakeProgSelfRun.444087. Une autre compilation
  avec Inno Setup 7.1.0 a ensuite ete detectee le 15 septembre sous le verdict
  Drop.Win32.FakeProgSelfRun.413706 ;
- le rappel de progression tentait d'extraire le fond suivant pendant
  l'extraction du Payload. Le journal contient 186 911 occurrences de
  Cannot call file extractor recursively.

Le correctif prepare tous les fonds avant la copie et supprime la section
Run qui lancait PowerShell avec ExecutionPolicy Bypass. La resolution
native, le plein ecran, le format du fond de chargement et
active-profile.txt sont maintenant regles directement par le code Inno avec
GetSystemMetrics.

Le fichier .open-sturmovik-installing est cree avant la premiere copie. Une
installation interrompue qui porte ce marqueur peut etre reprise par le meme
installeur. Le marqueur est supprime uniquement lorsque
.open-sturmovik-installed a ete ecrit. Si l'assistant s'arrete normalement
avant la fin, le conf.ini d'origine est restaure depuis sa sauvegarde.

La sortie definitive reconstruite avec Inno Setup 6.7.3 porte l'empreinte
SHA-256 suivante pour son executable :

    18BE7C202FC2683F401D24018A6B677FC9BC1E70FE4C4B2425C79379882C7058

Le 15 septembre 2026, une copie de cet executable a ete placee dans un nouveau
dossier ne beneficiant pas de l'exclusion creee lors de la restauration de
l'ancienne compilation. Le fichier a ete lu integralement pour recalculer son
empreinte, est reste present apres le controle et n'a produit aucune nouvelle
alerte dans le journal F-Secure. Ce resultat valide le correctif avec les
signatures F-Secure de cette machine au moment du test ; il ne remplace pas la
classification des autres moteurs antivirus. Une signature de code
Authenticode reste la mesure durable pour etablir la reputation des prochaines
versions d'un executable auto-extractible.

## Preparation et controles

Prepare-OpenSturmovikPayload.ps1 fabrique WIP\development\installer\Payload depuis une liste
fermee des fichiers et dossiers du jeu. Les dossiers de developpement, WIP,
les sources natives, les outils du depot, les tests, Git et Users ne peuvent
pas entrer dans cette copie.

La preparation normale s'effectue depuis la racine du depot :

    .\WIP\development\installer\Prepare-OpenSturmovikPayload.ps1

Pour reconstruire un Payload deja present :

    .\WIP\development\installer\Prepare-OpenSturmovikPayload.ps1 -Replace

Le controle avant compilation est :

    .\WIP\development\installer\Test-OpenSturmovikInstaller.ps1 -BeforeCompilation

Ce controle verifie les huit fonds, le logo et l'icone par leurs empreintes,
les onze cibles de raccourci, l'absence de Users et de conf.ini a la racine du
Payload, la provenance du nouveau conf.ini, le refus d'une ancienne
installation Open Sturmovik et le decoupage a 1 Go. Il interdit aussi tout
appel a l'extracteur depuis le rappel de progression et tout lancement de
PowerShell par l'installeur.

Le source Inno est Open_Sturmovik_1.15.iss. La compilation definitive a ete
realisee avec ISCC.exe 6.7.3 apres validation du contenu. Le controle
Test-OpenSturmovikInstaller.ps1 execute sur la sortie compilee retourne Status
OK. Aucun essai d'installation n'a ete lance sur la machine de compilation.
L'etape suivante est un essai controle sur une installation IL-2 de test.

Documentation Inno Setup utilisee :

- https://jrsoftware.org/ishelp/topic_setup_diskslicesize.htm
- https://jrsoftware.org/ishelp/topic_setup_wizardbackimagefile.htm
- https://jrsoftware.org/ishelp/topic_isxfunc_wizardsetbackimage.htm

## Profil installe par defaut

La preparation du Payload assemble toujours le profil 8 comme configuration
active initiale : **4.09m Open Sturmovik sans 6DOF**, HUD standard et langue
francaise. Les binaires, `files.SFS`, `wrapper.dll`, les fichiers moteur 4.09m,
les donnees, les fonds, les 14 musiques et les catalogues francais sont copies
aux emplacements actifs du jeu. `_Game Switcher\active-profile.txt` enregistre
le meme choix.

Le fond de chargement initial 4:3 accompagne la resolution de repli 1024 x 768.
A la fin de l'installation, `Set-OpenSturmovikNativeResolution.ps1` choisit le
fond 4:3, 16:10, 16:9, 21:9 ou 32:9 correspondant a l'ecran detecte et met a
jour l'etat actif. Le lanceur repete cette adaptation avant chaque demarrage.