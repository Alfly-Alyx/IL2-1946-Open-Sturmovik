# Audit du `conf.ini` historique de la version 1.2

## Source et statut

Le fichier etudie est conserve en lecture seule dans les ressources historiques :

`res\IL2 1946\Patch 1.2\Rajouts de Mods\conf.ini`

Il mesure 32 076 octets et porte une date de modification du 27 decembre 2024. Son en-tete l'attribue a `raven`, le 23 janvier 2024, et le presente comme une configuration maximale pour machines modernes. Il renvoie notamment au projet [IL2 Horus Team - il2fb-ds-config](https://github.com/IL2HorusTeam/il2fb-ds-config) et a sa [documentation publiee](https://il2horusteam.github.io/il2fb-ds-config/).

Ce fichier n'est donc pas un simple `conf.ini` produit par le menu du jeu. Il a ete integre aux travaux d'Open Sturmovik comme base documentee rassemblant des reglages du jeu, de versions officielles recentes et de plusieurs mods.

## Ce qui avait ete prepare

Le fichier contient 388 parametres actifs repartis dans 25 sections. Il rassemble dans un seul profil :

- un affichage 1920 x 1080 en OpenGL natif ;
- un rendu oriente qualite maximale, sans compression des textures, avec filtrage anisotrope, shaders materiels, details de terrain, foret, ombres, eclairage et effets eleves ;
- TrackIR et les reglages 6DOF ;
- les extensions Ultrapack de champ de vision et d'inertie des vues ;
- les options du mod ngHUD ;
- une configuration sonore a 44,1 kHz et 32 canaux avec EAX materiel demande ;
- des courbes pour plusieurs peripheriques de vol ;
- des raccourcis du constructeur de missions ;
- une campagne DGen volontairement dense (`AirIntensity=high`, `GroundIntensity=high`, `RandomFlights=5`) ;
- une configuration reseau complete et une liste de serveurs communautaires.

L'intention etait donc deja celle d'Open Sturmovik : qualite visuelle, immersion, 6DOF, campagnes plus vivantes et fonctions communautaires activees ensemble.

## Reglages graphiques significatifs

| Parametre | Profil historique | Profil maximal 1.15 actuel | Interpretation |
| --- | ---: | ---: | --- |
| `TexMipFilter` | `3` | `2` | L'ancien profil demande le filtrage anisotrope ; le profil actuel reste en trilineaire. |
| `TexCompress` | `0` | `2` | L'ancien profil privilegie la qualite sans compression ; le profil actuel utilise S3TC pour reduire la memoire et les lectures. |
| `TexFlags.UseDither` | `0` | `1` | Le tramage n'est normalement pas utile en couleur 32 bits. |
| `TexFlags.DrawLandByTriangles` | `0` | `1` | L'ancien profil evite le mode de terrain simplifie. |
| `Effects` | `2` | `1` | L'ancien profil demande les effets et leur eclairage ameliores. |
| `CountryDetails` | `2` | absent | L'ancien profil demande davantage de diversite des textures de sol. |
| `Water` | `2` | `4` | L'ancien profil choisit le chemin Shader Model 3 plus generique ; `4` est historiquement le chemin NVIDIA de meilleure qualite. |
| `PolygonOffsetFactor` | `-0.0625` | `-0.15` | Deux corrections possibles du scintillement des routes et aerodromes. |
| `PolygonOffsetUnits` | `-1.0` | `-3.0` | Doit etre valide visuellement avec chaque backend graphique. |

Le profil historique est plus ambitieux sur la nettete, les textures et les effets. Le profil 1.15 actuel est plus prudent pour un processus 32 bits chargeant des textures 2K/4K, mais son nom « maximal » masque ce compromis. Les deux objectifs devront devenir deux profils distincts : **qualite maximale** et **qualite haute securisee pour le budget memoire x86**.

## Parametres a ne pas appliquer aveuglement en 4.09m

### Reglages d'une version plus recente

Le fichier contient `joyTick=5` et indique lui-meme que cette option est apparue en 4.14.1. Elle ne doit pas faire partie du profil moteur 4.09m. Sa presence dans le `conf.ini` du dossier de ressources nomme `_4.09m` montre que ce fichier de configuration a ete copie ou regenere avec une version plus recente ; elle ne prouve pas que les executables de ce dossier sont eux-memes en 4.09m.

### Reglages conditionnes par un mod

Les sections ou cles `Mods`, `6dof_*`, `UP*`, `NewTrackIR` et `ngHUD*` ne produisent un effet que si la classe ou le module correspondant est effectivement charge. Elles devront etre reliees au manifeste des mods de chaque profil. Une cle sans lecteur est au mieux ignoree ; elle ne constitue pas une preuve que la fonction est installee.

### Donnees personnelles ou variables

Les commandes, courbes de joystick, adresses de serveurs, identifiants reseau, volumes et preferences d'interface ne doivent pas etre imposes lors de l'installation. Le selecteur 1.15 fait deja le bon choix structurel : il fusionne seulement un petit profil de valeurs moteur et conserve le reste du `conf.ini` du joueur.

### Options couteuses sans rapport direct avec la qualite graphique

`RandomFlights=5` et les intensites DGen elevees augmentent le nombre d'unites et le temps de generation ou de chargement des missions. Elles correspondent a un profil de campagne dense, pas a un profil graphique. Elles devront etre presentees separement dans le futur lanceur.

### Son materiel

`SoundFlags.hardware=1` demande EAX. Ce choix ne doit devenir automatique que si la pile sonore compatible retenue, par exemple DSOAL/OpenAL Soft, est presente et validee. Sinon le repli doit rester logiciel.

## Affinite CPU

Le fichier historique explique `ProcessAffinityMask`, mais la ligne est commentee. Il n'appliquait donc aucune limite CPU. Le selecteur 1.15 complete cette intention en calculant un masque de quatre coeurs physiques maximum a partir de la topologie Windows.

## Decision pour Open Sturmovik 1.15

Le fichier historique doit rester une reference de conception et ne doit pas remplacer integralement le `conf.ini` du joueur. Sa reprise sera faite par familles :

1. reprendre les valeurs de qualite visuelle verifiees dans un profil « qualite maximale » ;
2. conserver un profil compresse pour les machines proches de la limite memoire 32 bits ;
3. choisir l'eau et les extensions selon le GPU et le wrapper graphique reellement actifs ;
4. activer les cles 6DOF, Ultrapack et ngHUD seulement lorsque leur module est present dans le profil choisi ;
5. separer la densite DGen, le son EAX et les preferences du joueur des reglages graphiques ;
6. exclure de la cible 4.09m les cles propres aux versions officielles ulterieures.

Ces choix devront etre controles par capture du demarrage puis par une mission de reference. Une ligne presente dans `conf.ini` ne sera consideree comme prise en charge qu'apres identification de son lecteur dans le moteur ou le mod, puis verification en execution.

## Configuration distribuée par l'installeur 1.15 — 13 septembre 2026

Le modèle faisant autorité est `_Game Switcher/conf.ini`. Une copie identique est conservée dans `installer/Payload/_Game Switcher/conf.ini`. Le fichier contient `width=1024` et `height=768` comme repli sûr, `FullScreen=1`, `ChangeScreenRes=1`, `SaveAspect=0` et `MusicVolume=2`.

À la fin de l'installation, `_Game Switcher/Set-OpenSturmovikNativeResolution.ps1` interroge l'écran principal déclaré par Windows. `EnumDisplaySettings` fournit la résolution physique du mode actif, même lorsque la mise à l'échelle Windows est supérieure à 100 %. En cas d'échec de cette interrogation, la taille exposée par `System.Windows.Forms.Screen` sert de repli. Le script exige une résolution d'au moins 640 × 480, remplace une occurrence unique de chaque clé et écrit `conf.ini` par fichier temporaire.

Le raccourci Bureau `Open Sturmovik` appelle `_Game Switcher/Open_Sturmovik_Game.vbs`. Ce lanceur exécute la détection en fenêtre masquée, puis démarre `il2fb.exe` dans le dossier du jeu. `_Game Switcher/Open_Sturmovik_Switcher.vbs` actualise aussi la résolution avant d'ouvrir le switcher. Le réglage suit donc l'écran principal actif sur une autre machine ou après un changement d'écran ; aucune valeur 1920 × 1080 propre à la machine de préparation n'est distribuée.

L'installeur renomme d'abord le `conf.ini` déjà présent à la racine en `conf.ini.bak`, avec suffixe daté si nécessaire. Le modèle du pack est ensuite copié, adapté à l'écran, puis utilisé par le jeu. Les profils et préférences du joueur sous `Users` restent hors du Payload.

Essai réel du 13 septembre 2026 : le lanceur a détecté \\.\DISPLAY1 en 1920 × 1080, inscrit les six valeurs attendues et démarré la copie WIP/tests/installations/IL 2 Sturmovik 1946 test. Le processus il2fb.exe était encore actif après dix secondes. Ce contrôle valide l'enchaînement détection, écriture et démarrage sur cet écran ; il ne transforme pas 1920 × 1080 en valeur distribuée, car le modèle du Payload reste à 1024 × 768 avant détection.

Le journal natif fournit une seconde preuve indépendante : log.lst, ligne 873 de cette copie, contient Size: 1920x1080. Les lignes 906 à 909 concernent le refus d'un fond GUI/background.tga de 18 662 400 octets par un tampon limité à 4 202 496 octets. Cette erreur porte sur une texture du menu et non sur la taille du contexte graphique. Alexis confirme que le fond restait visible ; l'erreur est donc non bloquante dans ce lancement.

Les classes examinées construisent les écrans historiques avec des coordonnées x1024(...) et y1024(...). Le menu et ses polices peuvent ainsi paraître très grands sur un écran moderne alors que le contexte graphique est bien en 1920 × 1080. Aucun paramètre séparé de mise à l'échelle de l'interface n'est présent dans le conf.ini 4.09m analysé.

