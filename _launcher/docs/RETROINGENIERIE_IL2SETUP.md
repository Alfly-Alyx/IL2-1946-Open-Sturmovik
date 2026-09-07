# Rétro-ingénierie statique de `il2setup.exe`

## Périmètre et preuve binaire

L'analyse porte sur deux exemplaires retrouvés localement : celui de la copie de
test et celui de la base 4.09m. Ils sont strictement identiques :

- taille : 225 280 octets ;
- SHA-256 : `CEEE5EFB50BF1BB9424865321C4D1A2D33A1EEBCB9A3719563174CDC32549928` ;
- format : PE32 i386, application MFC ;
- version de fichier et de produit : `1.0.0.2` ;
- signature Authenticode : absente.

Cette étude est statique. Le programme n'a pas été exécuté. L'outil
`_launcher/tools/Inspect-Il2Setup.py` lit les tables PE, les imports et les
ressources sans charger le code de l'exécutable.

## Contrat de fichiers observé

Les chaînes et imports prouvent les points suivants :

- chemin de configuration : `%s\conf.ini` ;
- catalogue des profils : `%s\il2setup.ini` ;
- lecture par `GetPrivateProfileIntA` et `GetPrivateProfileStringA` ;
- écriture par `WritePrivateProfileStringA` ;
- dossier et module obtenus par `GetCurrentDirectoryA` et
  `GetModuleFileNameA` ;
- modes d'affichage énumérés par `EnumDisplaySettingsA` ;
- présence de DirectX 8 testée par `LoadLibraryA("d3d8.dll")` et
  `GetProcAddress("Direct3DCreate8")` ;
- propriétés joystick ouvertes par `rundll32 shell32,Control_RunDLL joy.cpl`.

Le remplaçant devra donc conserver le nom physique `il2setup.exe`, fonctionner
depuis le dossier du jeu et reproduire ce contrat avant d'ajouter les fonctions
Open Sturmovik. Il ne devra cependant pas reproduire l'écriture clé par clé sans
sauvegarde : toutes les modifications passeront par le moteur transactionnel du
launcher.

## Interface historique

Les ressources françaises contiennent une fenêtre **Configurer**, les boutons
**OK**, **Annuler**, **Voir l'introduction**, et cinq onglets :

1. Pilote ;
2. Vidéo ;
3. Joystick ;
4. Son ;
5. Réseau.

Les contrôles et identifiants sont conservés dans
`_launcher/manifests/il2setup-1.0.0.2.json`. Ils servent de preuve et non de
contrainte pour la future interface.

## Correspondance avec `conf.ini`

Les niveaux de confiance signifient :

- **prouvé** : nom de section/clé et contrôle présents dans le binaire, avec
  profil correspondant dans `il2setup.ini` lorsqu'il existe ;
- **fort** : relation directe et non ambiguë, mais valeur exacte à confirmer
  par un futur essai différentiel ;
- **inféré** : ordre ou codage déduit des libellés et valeurs statiques, à ne
  pas appliquer automatiquement avant validation.

### Général

| Réglage | Section / clé | Valeurs | Confiance |
|---|---|---:|---|
| Voir l'introduction | `game/Intro` | `0` ou `1` | prouvé |
| Langue de l'interface | `rts/locale` | `en`, `fr`, `de`, `ru`, `ja`, `pl`, `lt`, `hu`, `cs` | prouvé en lecture ; écriture à confirmer |

### Vidéo

| Réglage | Section / clé | Valeurs | Confiance |
|---|---|---:|---|
| Fournisseur | `GLPROVIDER/GL` | valeur résolue dans `GLPROVIDERS` (`Opengl32.dll`, `dx8wrap.dll`, etc.) | prouvé |
| Fenêtré / plein écran | `window/FullScreen` | `0` ou `1` | prouvé |
| Changer le mode écran | `window/ChangeScreenRes` | `0` ou `1` | fort |
| Mode vidéo | `window/width`, `height`, `ColourBits` | mode énuméré par Windows | prouvé |
| Stencil buffer | `window/StencilBits` | `0` ou `8` | fort |

`DepthBits` n'apparaît pas dans les chaînes du binaire : il doit être préservé
tant qu'une preuve supplémentaire ne montre pas qu'il est modifié indirectement.

### Réglages graphiques avancés

La section active est `Render_OpenGL` ou `Render_DirectX` selon le fournisseur.
Le catalogue `il2setup.ini` définit des profils héritables par une clé `Parent`.
Le choix est mémorisé dans `VideoSetupId`.

Les clés directement connues du binaire sont :

- `TexMipFilter` ;
- `TexCompress` ;
- `TexFlags.UseDither` ;
- `TexFlags.PolygonStipple` ;
- `TexFlags.UseVertexArrays` ;
- `TexFlags.DisableAPIExtensions` ;
- `TexFlags.ARBMultitextureExt` ;
- `TexFlags.TexEnvCombineExt` ;
- `TexFlags.SecondaryColorExt` ;
- `TexFlags.VertexArrayExt` ;
- `TexFlags.ClipHintExt` ;
- `TexFlags.UsePaletteExt` ;
- `TexFlags.TexEnvCombine4NV` ;
- `TexFlags.TexEnvCombineDot3` ;
- `TexFlags.DepthClampNV` ;
- `TexFlags.SeparateSpecular` ;
- `TexFlags.TextureShaderNV` ;
- `TexFlags.TexAnisotropicExt` ;
- `TexFlags.TexCompressARBExt` ;
- `ForceShaders1x` ;
- `PolygonOffsetFactor` ;
- `PolygonOffsetUnits`.

Les listes visibles indiquent les codages suivants, encore à valider :

- filtre mipmap : `1=bilinéaire`, `2=trilinéaire`, `3=anisotrope` ;
- compression : `0=aucune`, `1=16 bits`, `2=S3TC`.

Le catalogue historique contient aussi `TexQual`. Il peut donc être copié par
le moteur générique des profils sans être nommé explicitement dans le code.
Cette distinction est importante : le remplaçant doit parser le catalogue de
façon déclarative et ne pas limiter les profils aux seules chaînes embarquées.

### Joystick

| Réglage | Section / clé | Valeurs | Confiance |
|---|---|---:|---|
| Utiliser un joystick | `rts/joyUse` | `0` ou `1` | prouvé |
| Propriétés | aucune | ouvre le panneau Windows `joy.cpl` | prouvé |

L'ancien outil ne mappe pas les commandes IL-2 et ne connaît pas les commandes
ajoutées par Open Sturmovik. L'éditeur de commandes du nouveau launcher est donc
une fonction nouvelle, pas une simple reproduction.

### Son

Le profil global est mémorisé par `sound/SoundSetupId` et résolu depuis la
catégorie `Sound` de `il2setup.ini`. Les contrôles directs correspondent à :

| Réglage | Clé sous `sound` | Codage inféré |
|---|---|---:|
| Lecture des canaux | `NumChannels` | `0=Défaut`, `1=8`, `2=16`, `3=32` |
| Type de haut-parleurs | `Speakers` | `0=Défaut`, `1=Casque`, `2=Bureau`, `3=Quadriphonique`, `4=Surround` |
| Inverser la stéréo | `SoundFlags.reversestereo` | booléen |
| Accélération matérielle | `SoundFlags.hardware` | booléen |
| Mode du moteur 3D | `SoundMode` | `0=Défaut`, `1=Minimal`, `2=Équilibré`, `3=Total` |
| Taux d'échantillonnage | `SamplingRate` | choix visibles : `Défaut`, `22050`, `44100`; codage exact non résolu |
| Bavardage radio | `SoundFlags.UseRadioChatter` | booléen |
| Activation automatique | `SoundFlags.AutoActivation` | booléen |

Le binaire connaît également `SoundUse`, `SoundEngine`, `Channels`,
`SoundFlags.forceEAX1` et `SoundFlags.Hardware`. D'autres clés sonores sont
appliquées par les profils déclaratifs du fichier INI.

Le catalogue retrouvé contient 40 sections, dont 39 profils, mesure 16 168
octets et porte
l'empreinte SHA-256
`C5656BE666AFBEE705F9C3946F5B5012A4488403D5DEF2074DB6C82155D59C45`.
Il prouve que les catégories `OpenGL`, `DirectX` et `Sound` sont des listes de
profils et que l'héritage utilise `Parent`. L'analyse statique des ressources
montre trois choix visibles pour `SamplingRate`, tandis que les profils utilisent
les valeurs `0`, `2` et `3` — notamment `3` dans le profil sonore maximum.
Il serait donc incorrect d'assimiler directement l'index de la liste à la
valeur écrite. Ce réglage reste bloqué à l'écriture jusqu'au test différentiel.

Le lecteur déclaratif `_launcher/tools/Read-Il2SetupCatalogue.ps1` résout
maintenant les héritages sans coder les profils en dur. Sur le catalogue réel,
il valide les trois catégories et les 39 profils. Il relève aussi un profil
orphelin, `ATIRAGEGL`, qui existe dans le fichier mais n'est référencé par aucune
catégorie. Cette anomalie est préservée comme donnée historique ; elle ne doit
pas devenir un choix présenté au joueur.

### Réseau

| Réglage | Clé sous `NET` | Valeurs | Confiance |
|---|---|---:|---|
| Type de connexion | `speed` | voir ci-dessous | inféré |
| Téléchargement des livrées | `SkinDownload` | `0` ou `1` | prouvé |
| Adresse locale | `LocalHost` | adresse texte | prouvé |
| Port local | `LocalPort` | entier | prouvé |

La table statique conduit à la correspondance probable :

- modem 9,6 K : `900` ;
- modem 14,4 K : `1500` ;
- modem 28,8 K : `3000` ;
- modem 56 K : `5000` ;
- ISDN : `10000` ;
- câble/xDSL : `25000` ;
- LAN : `100000`.

Le futur launcher ne doit jamais inclure `LocalHost`, `remoteHost`, les ports ou
les adresses de serveur dans un rapport automatique.

## Ce que l'ancien outil ne fait pas

L'analyse ne montre aucun mécanisme de :

- sauvegarde ou restauration transactionnelle ;
- vérification d'intégrité ;
- réglage des commandes IL-2 ;
- sélection 6DOF ;
- gestion sémantique du réalisme ;
- collecte structurée des textures ou sons manquants ;
- anonymisation et rapport GitHub.

Ces fonctions appartiennent au nouveau launcher. La compatibilité
`il2setup.exe` doit donc être une façade d'entrée vers le même moteur moderne,
et non un second programme indépendant.

## Validation encore requise

Lorsque l'exécution sera de nouveau autorisée, chaque contrôle devra être testé
sur une copie jetable : empreinte de `conf.ini` avant, un seul changement dans
l'interface, empreinte et diff après, puis annulation et fermeture. Cette
campagne confirmera les codages marqués **fort** ou **inféré**, le comportement
de **Annuler**, le code de retour et les arguments de ligne de commande.
