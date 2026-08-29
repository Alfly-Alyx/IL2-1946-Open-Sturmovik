# Audit statique de `_OS_Programs`

Date de l'audit : 29 aout 2026. Aucun de ces programmes n'a ete execute et aucun fichier du dossier `D:\Projets\GITHUB\IL2-1946-Open-Sturmovik\_OS_Programs` n'a ete modifie.

Le selecteur Open Sturmovik, les scripts et les fichiers de configuration actifs ne lancent actuellement aucun des quatorze groupes d'utilitaires. Ils sont donc tous presents comme outils manuels, mais aucun n'est « active » par l'add-on.

| Utilitaire local | Etat actuel | Compatibilite utile avec la cible 4.09m |
| --- | --- | --- |
| Bombsight Table 2 | Lancement manuel possible ; aucune integration au jeu | Calculateur autonome IAS/TAS et visee, utilisable tel quel |
| Gapa | Lancement manuel possible ; aucune integration | Outil systeme de gamma/contraste ; a tester avec les pilotes modernes et le HDR |
| HardBall408 4.08 | Donnees statiques 4.08 et anciens composants VB/ActiveX | Incomplet pour 4.09m et les avions du mod ; une edition 4.09 existe |
| IL2 Sticks 1.0h | Non configure : chemins Windows XP appartenant a une ancienne machine | Peut modifier `conf.ini`, mais ne doit pas etre utilise en meme temps que JoyCtrl |
| IL2 Compare 2.4 | Autonome ; donnees IL-2 FB 2.01 | L'outil peut s'ouvrir, mais ses comparaisons sont obsoletes pour 4.09m |
| IL2 Connect 1.21 | Non configure : `GamePath` vide ; recherche `il2.exe` au lieu de `il2fb.exe` | Ne peut pas lancer cet add-on sans adaptation et ses services reseau sont anciens |
| IL2 JoyControl 1.4.2.1 | Present mais non relie au `conf.ini` actif | Meilleur candidat que IL2 Sticks pour les courbes et profils ; configuration requise |
| Lowengrin DCG 3.43 | Non configure ; ancien journal « No game configuration file » | Compatible dans son principe avec 4.09m, mais installation invasive si DGen/NGen est remplace ; versions 3.49/3.50 plus recentes a evaluer |
| Mission Mate 6.0.1 | `FBPath.txt` et emplacement HardBall vides | Bon candidat 4.09m/mods apres configuration ; la version 6.0.3 est plus recente |
| Quick Mission Tuner 2.00.0009 | Donnees 2007 ; aucune integration | Listes d'avions/cartes incompletes ; a laisser desactive par defaut et ne travailler que sur des copies de missions |
| San's FOV Changer RC 1.0 | Preference liee a une ancienne machine ; dependances .NET 2/Managed DirectX | Injection dependante de l'executable, donc non validee pour les EXE modifies ; ne pas activer par defaut |
| VoiceOverlay Alpha 1.1 | Overlay TeamSpeak 2/Ventrilo 2.2 ; hooks DirectX anciens | Obsolete et risque de conflit/crash avec d'autres overlays ; ne pas activer |
| WeatherSet | Edite les champs `[WEATHER]` apparus avec le patch 4.10 | Sans effet utile sur la cible 4.09m ; reserve a un futur profil 4.10+ |
| ZipNav 1.1 | Attend `mods\mapmods`, alors que l'add-on utilise `Files\Maps` | Non compatible avec l'arborescence actuelle sans configuration/adaptation ; l'extraction des cartes demande Java |

## Dependances visibles sur cette machine

- Java 17 64 bits est installe. Cela ne garantit pas qu'un ancien `Act.jar` fonctionne sans adaptation.
- .NET Framework 3.5 et .NET Framework 4.x sont installes.
- Le runtime Visual Basic 6 32 bits est present ; le runtime Visual Basic 5 systeme ne l'est pas.
- Tous les executables examines sont non signes.

## Decision v1.15

La v1.15 ne doit activer automatiquement aucun de ces outils. Sur decision du mainteneur, les programmes actuellement incompatibles restent presents dans `_OS_Programs`, sans suppression ni modification, mais demeurent desactives. Les candidats a une integration ulterieure sont JoyControl, Mission Mate et DCG, apres essais dans une copie de jeu. VoiceOverlay, Quick Mission Tuner et San's FOV Changer restent desactives par securite. IL2 Sticks et JoyControl ne doivent jamais ecrire simultanement dans le meme `conf.ini`.

## Sources communautaires principales

- [Bombsight Table 2](https://www.mission4today.com/index.php?kid=337&name=Knowledge_Base&op=show)
- [IL2 JoyControl](https://www.mission4today.com/index.php?file=details&id=1021&name=Downloads)
- [Forum officiel de Lowengrin DCG](https://forum.jg1.org/forum/8-lowengrins-dynamic-campaign-generators-dcg-for-il-2-cfs2/)
- [Blog de Lowengrin DCG](https://il2dcg.blogspot.com/)
- [Mission Mate 6.0.3](https://www.mission4today.com/index.php?file=details&id=4&name=Downloads3)
- [San's FOV Changer](https://www.sas1946.com/main/index.php?topic=19698.0)
- [Vent et meteo introduits en 4.10](https://www.mission4today.com/index.php?file=print&kid=643&name=Knowledge_Base&page=1)
