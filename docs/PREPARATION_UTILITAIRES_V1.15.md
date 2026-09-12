# Preparation des utilitaires Open Sturmovik v1.15

Mise a jour : 12 septembre 2026.

## Perimetre courant

Sept utilitaires sont fournis avec un raccourci : Bombsight Table 2,
HardBall408, IL2 Compare, JoyCtrl, Mission Mate 6, WeatherSet et ZipNav.
Le huitieme raccourci ouvre le switcher Open Sturmovik.

Lowengrin DCG 3.43 et San FOV Changer 1.0 ont ete retires a la demande
explicite d'Alexis. Leur redistribution demande une autorisation de l'auteur
qui n'est pas conservee avec le pack. Leurs fichiers et notices sont archives
avec leurs empreintes sous
`D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence`.
Le retrait concerne les composants distribues ; aucun profil joueur, campagne
personnelle ou reglage de l'installation de test n'a ete supprime.

Aucun utilitaire n'est lance automatiquement avec le jeu. La preparation des
chemins et l'installation des raccourcis sont deux operations distinctes.

## Initialisation

`manifests/utilities-v1.15.json` definit les huit cibles et leurs noms.
`tools/Initialize-OpenSturmovikUtilities.ps1` exige une installation contenant
`il2fb.exe`, puis :

1. inscrit la racine dans `Mission Mate 6/FBPath.txt` ;
2. configure le chemin de HardBall408 dans `Mission Mate 6/MisMate.ini` ;
3. relie les cartes fournies avec ZipNav a `mods/mapmods`, sans recopier leurs
   donnees ni remplacer un dossier deja present.

L'option `-SkipZipNavMaps` omet la troisieme etape. Les anciens parametres
`-DeviceLinkAddress` et `-SkipDeviceLink`, reserves a l'integration San, sont
retires. L'initialiseur ne modifie plus `conf.ini` : DeviceLink, SaveAspect et
les reglages FOV existants restent ceux du joueur. Le document officiel
`DeviceLink.txt` reste fourni a la racine.

Chaque fichier texte modifie recoit au plus une sauvegarde
`.opensturmovik-v1.15.bak` ; son remplacement passe par un fichier temporaire.
Mission Mate conserve son catalogue embarque. Ne pas relier `Files` a
`MODS/STD` pour son import automatique : cela ferait parcourir deux fois les
memes ressources au chargeur. HardBall et ZipNav restent des programmes
separes, avec leurs propres donnees.

Le manifeste conserve la position initiale `32,32` de Bombsight Table 2,
choisie pour eviter une fenetre hors ecran sur un poste mono-ecran.

## Raccourcis et finalisation

`tools/Install-OpenSturmovikUtilityShortcuts.ps1` valide les huit cibles avant
creation sur le Bureau choisi. `-ValidateOnly` n'ecrit rien ; `-WhatIf` annonce
les actions simulees. Le mode tous utilisateurs reste explicite.

Le finaliseur PowerShell `tools/Complete-OpenSturmovikV115Update.ps1` execute
l'initialisation, le diagnostic sauf `-SkipDiagnostics`, puis les huit
raccourcis. Une cible absente ou un compte incorrect fait echouer ce finaliseur.
Le script Inno Setup declare directement les huit raccourcis dans `[Icons]`
et appelle l'initialiseur et l'installation du diagnostic apres copie des
fichiers. Aucun installateur final n'a ete compile par ce retrait.

## Verification du retrait

Le controle des cibles retourne huit raccourcis valides sous Windows
PowerShell 5.1, sans modifier le Bureau. Les huit declarations Inno Setup
concordent. Un essai de l'initialiseur dans une petite installation fictive,
sans DCG ni San, configure les chemins Mission Mate et conserve octet pour
octet un `conf.ini` personnalise et un fichier de profil joueur. Aucun jeu
ni utilitaire externe n'est lance ; la fixture est retiree apres controle.

Ces verifications ne constituent pas de nouveaux essais en jeu.

## Validation fonctionnelle restante

La campagne finale doit encore couvrir les outils conserves : generation de
mission dans Mission Mate, effet A/B de WeatherSet, echelles et caps ZipNav,
etiquetage HardBall et anciennete IL2 Compare, utilisation Bombsight Table 2
et aller-retour JoyCtrl avec sauvegarde exacte. Les essais portent sur des
copies de donnees et conservent les validations deja acquises.
