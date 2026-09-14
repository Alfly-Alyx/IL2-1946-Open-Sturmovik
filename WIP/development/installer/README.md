# Installeur complet Open Sturmovik 1.15

Ce dossier contient le nouvel installeur complet d'Open Sturmovik 1.15.
Il ne s'agit pas d'un patch pour une ancienne version d'Open Sturmovik.
Les anciens scripts Inno Setup ne servent pas de reference.

Le Payload a ete prepare le 13 septembre 2026 : 129 483 fichiers pour
26 257 828 254 octets. La compilation definitive avec Inno Setup 7.1.0
a reussi le 13 septembre 2026 en 4 120,375 secondes (1 h 08 min 40 s).
Elle produit huit fichiers .bin, un executable Setup et SHA256SUMS.txt pour
7 472 333 788 octets au total, manifeste compris.

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

Le logo exec-d2e28692__logo-IL2-B__master-1024.png est utilise par
l'assistant d'installation. Les huit fonds 1586 x 992 demandes sont ranges
dans assets\backgrounds sous les noms 01.png a 08.png. Les huit fonds ne changent pas selon une minuterie. La progression totale de la
copie est divisee en huit intervalles ; `CurInstallProgressChanged` choisit
l'image 01 a 08 correspondant a l'intervalle atteint. Chaque PNG est extrait
temporairement au premier besoin et affiche avec une opacite de 150. Cette
rotation appartient uniquement a l'assistant d'installation. La rotation des
fonds de chargement du jeu est un mecanisme distinct. Ses lanceurs sont
`_Game Switcher\Open_Sturmovik_Fonds.vbs` et
`_Game Switcher\Open_Sturmovik_Fonds.bat`. Il est documente dans
`docs\ROTATION_FONDS_CHARGEMENT.md`.

assets\source-manifest.json conserve pour chaque image son chemin source, ses
dimensions et son empreinte SHA-256.

## Parties de 1 Go

Le script Inno active le decoupage avec :

    DiskSpanning=yes
    SlicesPerDisk=1
    DiskSliceSize=1000000000

Chaque fichier .bin produit est donc limite a 1 000 000 000 octets.
Write-ReleaseChecksums.ps1 a confirme cette limite pour les huit parties et
l'executable, puis a produit Output\SHA256SUMS.txt. Six parties font exactement
1 000 000 000 octets ; la partie 1 fait 982 193 152 octets, la partie 8
fait 472 333 218 octets et l'executable fait 17 806 529 octets. Toutes les
parties doivent etre publiees ensemble dans la meme GitHub Release.

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

Ce controle verifie les huit fonds et le logo par leurs empreintes, les onze
cibles de raccourci, l'absence de Users et de conf.ini a la racine du Payload,
la provenance du nouveau conf.ini, le refus d'une ancienne installation Open
Sturmovik et le decoupage a 1 Go.

Le source Inno est Open_Sturmovik_1.15.iss. La compilation definitive a ete
realisee avec ISCC.exe 7.1.0 apres validation du contenu. Le controle
Test-OpenSturmovikInstaller.ps1 execute sur la sortie compilee retourne Status OK.
L'etape suivante est un essai reel d'installation sur une copie jetable du jeu.

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