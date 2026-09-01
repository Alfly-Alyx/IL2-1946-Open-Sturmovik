# Référence des réglages et commandes IL-2 1946 / Open Sturmovik

> Document de travail généré depuis des preuves statiques. Une valeur « observée » n'est pas automatiquement une borne valide du moteur.

## Où sont stockés les réglages

- `conf.ini` contient les réglages globaux : fenêtre, rendu, son, réseau, moteur RTS, souris et joystick.
- `Users/{pilote}/settings.ini` contient les affectations de touches et d'axes, la difficulté et plusieurs préférences du pilote.
- `il2setup.ini` est le catalogue historique de profils lu par `il2setup.exe`; ses clés peuvent être écrites dans `conf.ini` même si elles sont absentes du fichier courant.
- Une commande bouton reçoit un événement relâché/pressé (`0/1`). Ce n'est pas un réglage continu, même lorsque son effet est un interrupteur.

## Plages prouvées des périphériques

| Élément | Minimum | Maximum | Détail |
|---|---:|---:|---|
| Valeur brute d'un axe joystick | -125 | 125 | Constantes `Joy.AXE_MIN_MOVE` et `Joy.AXE_MAX_MOVE`. |
| Valeur normalisée transmise aux commandes | -1 | 1 | `Joy.normal(v) = v × 0,008`. |
| Zone morte | 0 | 50 | Premier entier de chaque ligne d'axe. |
| Coefficients de courbe 1 à 10 | 0 | 100 | Dix valeurs indépendantes, limitées par l'écran de réglage. |
| Filtre d'axe | 0 | 100 | Dernier entier; interface historique par pas de 10. |
| Sensibilité souris X/Y | 0,1 | 10 | Valeur flottante limitée par `GUISetupInput`. |
| Retour de force `FF` | 0 | 1 | Désactivé / activé. |
| Capacité joysticks / axes / POV | — | 4 / 8 / 4 | Quatre joysticks, huit axes et quatre POV par joystick. |

Une ligne moderne de `[rts_joystick]` contient douze entiers : zone morte, dix coefficients, puis filtre. Le moteur sait aussi convertir l'ancien format; les deux formats ne doivent pas être fusionnés aveuglément. Le préfixe de format `1` et le suffixe de numéro de joystick doivent être préservés jusqu'à la fin de la rétro-ingénierie.

## Axes assignables et effet logique

| Identifiant exact | Fonction française observée | Entrée min | Entrée max | Sortie logique min | Sortie logique max | Inversé |
|---|---|---:|---:|---:|---:|---|
| `-aileron` | Ailerons | -1 | 1 | -1 | 1 | oui |
| `-brakes` | Freins | -1 | 1 | 0 | 1 | oui |
| `-elevator` | Profondeur | -1 | 1 | -1 | 1 | oui |
| `-flaps` | Volets | -1 | 1 | 0 | 1 | oui |
| `-pitch` | Pas d'hélice | -1 | 1 | 0 | 1 | oui |
| `-power` | Puissance | -1 | 1 | 0 | 1.1 | oui |
| `-rudder` | Palonnier | -1 | 1 | -1 | 1 | oui |
| `-trimaileron` | Trim d'ailerons | -1 | 1 | -0.5 | 0.5 | oui |
| `-trimelevator` | Trim de profondeur | -1 | 1 | -0.5 | 0.5 | oui |
| `-trimrudder` | Trim de gouvernail | -1 | 1 | -0.5 | 0.5 | oui |
| `aileron` | Ailerons | -1 | 1 | -1 | 1 | non |
| `brakes` | Freins | -1 | 1 | 0 | 1 | non |
| `elevator` | Profondeur | -1 | 1 | -1 | 1 | non |
| `flaps` | Volets | -1 | 1 | 0 | 1 | non |
| `pitch` | Pas d'hélice | -1 | 1 | 0 | 1 | non |
| `power` | Puissance | -1 | 1 | 0 | 1.1 | non |
| `rudder` | Palonnier | -1 | 1 | -1 | 1 | non |
| `trimaileron` | Trim d'ailerons | -1 | 1 | -0.5 | 0.5 | non |
| `trimelevator` | Trim de profondeur | -1 | 1 | -0.5 | 0.5 | non |
| `trimrudder` | Trim de gouvernail | -1 | 1 | -0.5 | 0.5 | non |

La puissance transforme `-1…1` en `0…1,1` afin de couvrir jusqu'à 110 %. Le pas d'hélice, les volets et les freins donnent `0…1`; aileron, profondeur et palonnier donnent `-1…1`; les trims donnent `-0,5…0,5`. Un identifiant commençant par `-` inverse le sens physique avant cette transformation.

## Réglages historiques connus de `il2setup.exe`

| Section / clé | Fonction | Type | Valeurs ou plage | Confiance |
|---|---|---|---|---|
| `[game]/Intro` | Voir l'introduction | `boolean` | `0` ou `1` | `proven` |
| `[rts]/locale` | Langue de l'interface | `choice` | `en`, `fr`, `de`, `ru`, `ja`, `pl`, `lt`, `hu`, `cs` | `proven-read` |
| `[GLPROVIDER]/GL` | Fournisseur graphique | `provider-reference` | nom déclaré dans `[GLPROVIDERS]` | `proven` |
| `[window]/FullScreen` | Plein écran | `boolean` | `0` ou `1` | `proven` |
| `[window]/ChangeScreenRes` | Changer le mode écran | `boolean` | `0` ou `1` | `strong` |
| `[window]/width, height, ColourBits` | Mode vidéo | `display-mode` | modes énumérés par Windows | `proven` |
| `[window]/StencilBits` | Utiliser le stencil buffer | `choice` | `off=0`, `on=8` | `strong` |
| `[rts]/joyUse` | Utiliser un joystick | `boolean` | `0` ou `1` | `proven` |
| `[sound]/SoundSetupId` | Profil sonore | `profile-reference` | identifiant de profil `il2setup.ini` | `proven` |
| `[sound]/SoundUse` | Activer le son | `boolean` | `0` ou `1` | `proven` |
| `[sound]/NumChannels` | Lecture des canaux | `choice` | `default=0`, `8=1`, `16=2`, `32=3` | `inferred` |
| `[sound]/Speakers` | Type de haut-parleurs | `choice` | `default=0`, `headphones=1`, `desktop=2`, `quadraphonic=3`, `surround=4` | `inferred` |
| `[sound]/SoundFlags.reversestereo` | Inverser la stéréo | `boolean` | `0` ou `1` | `proven` |
| `[sound]/SoundFlags.hardware` | Accélération matérielle | `boolean` | `0` ou `1` | `proven` |
| `[sound]/SoundMode` | Mode du moteur sonore 3D | `choice` | `default=0`, `minimal=1`, `balanced=2`, `full=3` | `inferred` |
| `[sound]/SamplingRate` | Fréquence d'échantillonnage | `choice` | `default`, `22050`, `44100` — codage exact non résolu | `inferred` |
| `[sound]/SoundFlags.UseRadioChatter` | Bavardage radio | `boolean` | `0` ou `1` | `proven` |
| `[sound]/SoundFlags.AutoActivation` | Activation automatique | `boolean` | `0` ou `1` | `proven` |
| `[NET]/speed` | Type de connexion | `choice` | `modem-9k6=900`, `modem-14k4=1500`, `modem-28k8=3000`, `modem-56k=5000`, `isdn=10000`, `cable-xdsl=25000`, `lan=100000` | `inferred` |
| `[NET]/SkinDownload` | Téléchargement des livrées | `boolean` | `0` ou `1` | `proven` |
| `[NET]/LocalHost` | Adresse locale | `ip-address` | adresse texte — donnée sensible | `proven` |
| `[NET]/LocalPort` | Port local | `port` | borne valide non encore prouvée | `proven` |

## Clés que les profils peuvent ajouter à `conf.ini`

Cette table couvre les 39 profils statiques d'`il2setup.ini`. Min/max signifie seulement **minimum/maximum observé dans ces profils**, pas limite absolue du moteur.

| Clé | Valeurs observées | Min observé | Max observé | Rôle technique |
|---|---|---:|---:|---|
| `Channels` | 0, 1, 2 | 0 | 2 | Nombre ou mode de canaux audio. |
| `ForceShaders1x` | 0, 1 | 0 | 1 | Force un chemin de shaders compatible avec le matériel ancien. |
| `MusFlags.play` | 0, 1 | 0 | 1 | Autorise la lecture de la musique. |
| `Placement` | 0 | 0 | 0 | Mode de placement spatial des sons. |
| `PolygonOffsetFactor` | -0.0625, -0.15 | -0.15 | -0.063 | Décalage de profondeur des polygones : facteur. |
| `PolygonOffsetUnits` | -1.0, -3.0 | -3 | -1 | Décalage de profondeur des polygones : unités. |
| `RadioEngine` | 0, 2 | 0 | 2 | Moteur utilisé pour les communications radio. |
| `RadioFlags.enabled` | 0, 1 | 0 | 1 | Active les communications radio. |
| `SamplingRate` | 0, 2, 3 | 0 | 3 | Fréquence d'échantillonnage audio ; codage exact encore incomplet. |
| `SoundEngine` | 0, 1 | 0 | 1 | Moteur de rendu sonore. |
| `SoundExt.acoustics` | 0, 1 | 0 | 1 | Active les traitements acoustiques étendus. |
| `SoundExt.occlusions` | 0, 1 | 0 | 1 | Active l'atténuation des sons masqués par des obstacles. |
| `SoundExt.volumefx` | 0, 1 | 0 | 1 | Active les effets sonores volumétriques. |
| `SoundFlags.duplex` | 0, 1 | 0 | 1 | Autorise le fonctionnement audio duplex. |
| `SoundFlags.forceEAX1` | 0, 1 | 0 | 1 | Force le mode EAX 1. |
| `SoundFlags.hardware` | 0, 1 | 0 | 1 | Utilise l'accélération audio matérielle. |
| `SoundFlags.reversestereo` | 0 | 0 | 0 | Inverse les canaux gauche et droit. |
| `SoundFlags.static` | 1 | 1 | 1 | Autorise les tampons sonores statiques. |
| `SoundFlags.streams` | 0, 1 | 0 | 1 | Autorise les flux audio. |
| `SoundFlags.voicemgr` | 0, 1 | 0 | 1 | Active le gestionnaire de voix. |
| `SoundMode` | 0, 1 | 0 | 1 | Niveau ou mode du moteur sonore 3D. |
| `SoundUse` | 0, 1 | 0 | 1 | Active complètement le son. |
| `Speakers` | 0 | 0 | 0 | Configuration des haut-parleurs. |
| `TexCompress` | 0, 1 | 0 | 1 | Niveau ou mode de compression des textures. |
| `TexFlags.ARBMultitextureExt` | 0, 1 | 0 | 1 | Autorise l'extension ARB multitexture. |
| `TexFlags.ClipHintExt` | 0 | 0 | 0 | Autorise l'extension de conseil de clipping. |
| `TexFlags.DepthClampNV` | 0, 1 | 0 | 1 | Autorise le depth clamp NVIDIA. |
| `TexFlags.DisableAPIExtensions` | 0, 1 | 0 | 1 | Désactive les extensions de l'API graphique. |
| `TexFlags.PolygonStipple` | 0, 1 | 0 | 1 | Autorise le tramage de polygones. |
| `TexFlags.SecondaryColorExt` | 0, 1 | 0 | 1 | Autorise la couleur secondaire. |
| `TexFlags.SeparateSpecular` | 0, 1 | 0 | 1 | Sépare la composante spéculaire. |
| `TexFlags.TexAnisotropicExt` | 0, 1 | 0 | 1 | Autorise le filtrage anisotrope. |
| `TexFlags.TexCompressARBExt` | 0, 1 | 0 | 1 | Autorise la compression de textures ARB. |
| `TexFlags.TexEnvCombine4NV` | 0, 1 | 0 | 1 | Autorise la combinaison de textures NVIDIA à quatre unités. |
| `TexFlags.TexEnvCombineDot3` | 0, 1 | 0 | 1 | Autorise la combinaison DOT3. |
| `TexFlags.TexEnvCombineExt` | 0, 1 | 0 | 1 | Autorise la combinaison de textures étendue. |
| `TexFlags.TextureShaderNV` | 0, 1 | 0 | 1 | Autorise les texture shaders NVIDIA. |
| `TexFlags.UseDither` | 1 | 1 | 1 | Active le tramage des couleurs. |
| `TexFlags.UsePaletteExt` | 0 | 0 | 0 | Autorise les textures palettisées. |
| `TexFlags.UseVertexArrays` | 0, 1 | 0 | 1 | Utilise les tableaux de sommets. |
| `TexFlags.VertexArrayExt` | 0, 1 | 0 | 1 | Autorise l'extension de tableaux de sommets. |
| `TexMipFilter` | 1, 2 | 1 | 2 | Choisit le filtrage des niveaux mipmap. |
| `TexQual` | 2, 3 | 2 | 3 | Niveau de qualité des textures. |

## Catalogue des commandes boutons

Le relevé contient **282 commandes uniques**, dont **236 publiques**, **15 internes** et **9 présentes seulement dans un `settings.ini` sans déclaration retrouvée dans les classes analysées**.

L'origine historique ou ajoutée par Open Sturmovik reste `unclassified` tant qu'un catalogue 4.09m propre n'a pas été produit avec la même méthode.

### Vues extérieures et cockpit (`aircraftView`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `cockpitSwitch` | — | — | 0 / 1 | `registered` | non |
| `changeCockpit` | Position pilote ou mitrailleur | Pilot or Gunner Position | 0 / 1 | `registered` | oui |
| `cockpitView` | — | — | 0 / 1 | `registered` | non |
| `fov90` | Vue large | Wide View | 0 / 1 | `registered` | oui |
| `fov85` | Champ de vision 85 | FOV 85 | 0 / 1 | `registered` | non |
| `fov80` | Champ de vision 80 | FOV 80 | 0 / 1 | `registered` | non |
| `fov75` | Champ de vision 75 | FOV 75 | 0 / 1 | `registered` | non |
| `fov70` | Vue normale | Normal View | 0 / 1 | `registered` | oui |
| `fov65` | Champ de vision 65 | FOV 65 | 0 / 1 | `registered` | non |
| `fov60` | Champ de vision 60 | FOV 60 | 0 / 1 | `registered` | non |
| `fov55` | Champ de vision 55 | FOV 55 | 0 / 1 | `registered` | non |
| `fov50` | Champ de vision 50 | FOV 50 | 0 / 1 | `registered` | non |
| `fov45` | Champ de vision 45 | FOV 45 | 0 / 1 | `registered` | non |
| `fov40` | Champ de vision 40 | FOV 40 | 0 / 1 | `registered` | non |
| `fov35` | Champ de vision 35 | FOV 35 | 0 / 1 | `registered` | non |
| `fov30` | Vue viseur | Gunsight  View | 0 / 1 | `registered` | oui |
| `fovSwitch` | Basculer Champ de vision | Toggle FOV | 0 / 1 | `registered` | non |
| `fovInc` | Agrandir Champ de vision | Increase FOV | 0 / 1 | `registered` | non |
| `fovDec` | Diminuer Champ de vision | Decrease FOV | 0 / 1 | `registered` | non |
| `CockpitView` | Vue cockpit | Cockpit View | 0 / 1 | `registered` | oui |
| `CockpitShow` | Vue sans cockpit | No Cockpit View | 0 / 1 | `registered` | oui |
| `OutsideView` | Vue externe | External View | 0 / 1 | `registered` | oui |
| `NextView` | Vue prochain ami | Next Friendly View | 0 / 1 | `registered` | oui |
| `NextViewEnemy` | Vue prochain ennemi | Next Enemy View | 0 / 1 | `registered` | oui |
| `OutsideViewFly` | Vue Fly-by | Fly-by View | 0 / 1 | `registered` | oui |
| `PadlockView` | Verrouillage Ennemi | Padlock Enemy | 0 / 1 | `registered` | oui |
| `PadlockViewFriend` | Verrouillage Ami | Padlock Friendly | 0 / 1 | `registered` | oui |
| `PadlockViewGround` | Verrouillage Ennemi sol | Padlock Enemy Ground | 0 / 1 | `registered` | oui |
| `PadlockViewFriendGround` | Verrouillage Ami sol | Padlock Friendly Ground | 0 / 1 | `registered` | oui |
| `PadlockViewNext` | Verrouillage Suivant | Padlock Next | 0 / 1 | `registered` | oui |
| `PadlockViewPrev` | Verrouillage Précédent | Padlock Previous | 0 / 1 | `registered` | oui |
| `PadlockViewForward` | Vue instantané vers l'avant avec verrouillage | Instant View Forward with Padlock | 0 / 1 | `registered` | oui |
| `ViewEnemyAir` | Verrouillage externe, ennemi aérien | External Padlock, Enemy Air | 0 / 1 | `registered` | oui |
| `ViewFriendAir` | Verrouillage externe, Ami aérien | External Padlock, Friendly Air | 0 / 1 | `registered` | oui |
| `ViewEnemyDirectAir` | Verrouillage externe, Ennemi aérien le plus proche | External Padlock, closest Enemy Air | 0 / 1 | `registered` | oui |
| `ViewEnemyGround` | Verrouillage externe, Ennemi sol | External Padlock, Enemy Ground | 0 / 1 | `registered` | oui |
| `ViewFriendGround` | Verrouillage externe, Ami sol | External Padlock, Friendly Ground | 0 / 1 | `registered` | oui |
| `ViewEnemyDirectGround` | Verrouillage externe, Ennemi sol le plus proche | External Padlock, closest Enemy Ground | 0 / 1 | `registered` | oui |
| `OutsideViewFollow` | Vue chasse | Chase View | 0 / 1 | `registered` | oui |
| `NextViewFollow` | Vue chasse ami suivant | Next Friendly Chase View | 0 / 1 | `registered` | oui |
| `NextViewEnemyFollow` | Vue chasse ennemi suivant | Next Enemy Chase View | 0 / 1 | `registered` | oui |
| `cockpitAim` | Activer viseur | Toggle Gunsight | 0 / 1 | `registered` | oui |
| `cockpitUp` | Relever/Baisser le siège du pilote | Toggle Seat Position | 0 / 1 | `registered` | non |

### Mitrailleur (`gunner`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `Fire` | Feu | Fire | 0 / 1 | `registered` | oui |
| `Mouse` | — | — | 0 / 1 | `registered` | non |

### Divers (`misc`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `autopilotAuto_` | — | — | 0 / 1 | `registered` | non |
| `cockpitEnter` | — | — | 0 / 1 | `registered` | non |
| `cockpitLeave` | — | — | 0 / 1 | `registered` | non |
| `cockpitRealOff` | — | — | 0 / 1 | `registered` | non |
| `cockpitRealOn` | — | — | 0 / 1 | `registered` | non |
| `target_` | — | — | 0 / 1 | `registered` | non |
| `autopilot` | Bascule autopilote | Toggle Autopilot | 0 / 1 | `registered` | oui |
| `autopilotAuto` | Automatisation des mitrailleurs | Toggle Level Autopilot | 0 / 1 | `registered` | non |
| `ejectPilot` | Sauter en parachute | Bail Out | 0 / 1 | `registered` | oui |
| `cockpitDim` | Pare soleil du viseur | Tinted Reticle Dimmer | 0 / 1 | `registered` | oui |
| `cockpitLight` | Eclairage cockpit | Cockpit Lights | 0 / 1 | `registered` | oui |
| `toggleNavLights` | Feux de navigation | Toggle Nav. Lights | 0 / 1 | `registered` | non |
| `toggleLandingLight` | Phare d'atterrissage | Toggle Landing Light | 0 / 1 | `registered` | non |
| `toggleSmokes` | Fumigènes de bout d'aile | Toggle Wingtip Smoke | 0 / 1 | `registered` | oui |
| `pad` | Activer la carte | Toggle Map | 0 / 1 | `registered` | oui |
| `chat` | Chat | Chat | 0 / 1 | `registered` | oui |
| `onlineRating` | Stats. multijoueur | Online Rating | 0 / 1 | `registered` | oui |
| `onlineRatingPage` | Page statistiques suivante | Next Ratings Page | 0 / 1 | `registered` | non |
| `showPositionHint` | Afficher/cacher la barre de vitesse | Toggle Speed Bar | 0 / 1 | `registered` | non |
| `iconTypes` | Afficher/cacher les icônes | Toggle Icon Types | 0 / 1 | `registered` | non |
| `showMirror` | Rétroviseur afficher/modes | Toggle Mirrors Show/Mode | 0 / 1 | `registered` | non |

### Communications et ordres (`orders`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `deactivate` | — | — | 0 / 1 | `registered` | oui |
| `order0` | — | — | 0 / 1 | `registered` | oui |
| `order1` | — | — | 0 / 1 | `registered` | oui |
| `order10` | — | — | 0 / 1 | `settings-only` | oui |
| `order11` | — | — | 0 / 1 | `settings-only` | oui |
| `order12` | — | — | 0 / 1 | `settings-only` | oui |
| `order13` | — | — | 0 / 1 | `settings-only` | oui |
| `order14` | — | — | 0 / 1 | `settings-only` | oui |
| `order15` | — | — | 0 / 1 | `settings-only` | oui |
| `order16` | — | — | 0 / 1 | `settings-only` | oui |
| `order17` | — | — | 0 / 1 | `settings-only` | oui |
| `order2` | — | — | 0 / 1 | `registered` | oui |
| `order3` | — | — | 0 / 1 | `registered` | oui |
| `order4` | — | — | 0 / 1 | `registered` | oui |
| `order5` | — | — | 0 / 1 | `registered` | oui |
| `order6` | — | — | 0 / 1 | `registered` | oui |
| `order7` | — | — | 0 / 1 | `registered` | oui |
| `order8` | — | — | 0 / 1 | `registered` | oui |
| `order9` | — | — | 0 / 1 | `registered` | oui |
| `activate` | Activer les communications | Toggle Comms | 0 / 1 | `registered` | oui |

### Vue panoramique (`PanView`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `Mouse` | — | — | 0 / 1 | `registered` | non |
| `TrackIR` | — | — | 0 / 1 | `registered` | non |
| `PanReset` | Centrer la vue | Center View | 0 / 1 | `registered` | oui |
| `PanUp` | Vue vers le haut | Pan View Up | 0 / 1 | `registered` | oui |
| `PanDown` | vue vers le bas | Pan View Down | 0 / 1 | `registered` | oui |
| `PanLeft2` | vue vers la gauche | Pan View Left | 0 / 1 | `registered` | oui |
| `PanRight2` | vue vers la droite | Pan View Right | 0 / 1 | `registered` | oui |
| `PanLeft` | vue vers le haut gauche | Pan View Up Left | 0 / 1 | `registered` | oui |
| `PanRight` | vue vers le haut droite | Pan View Up Right | 0 / 1 | `registered` | oui |
| `PanLeft3` | vue vers le bas gauche | Pan View Down Left | 0 / 1 | `registered` | oui |
| `PanRight3` | vue vers le bas droite | Pan View Down Right | 0 / 1 | `registered` | oui |

### Pilotage et systèmes de l'avion (`pilot`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `AIRCRAFT_STABILIZER` | — | — | 0 / 1 | `settings-only` | oui |
| `ElevatorUp` | Profondeur haut | Elevator Up | 0 / 1 | `registered` | oui |
| `ElevatorDown` | Profondeur bas | Elevator Down | 0 / 1 | `registered` | oui |
| `AileronLeft` | Aileron gauche | Aileron Left | 0 / 1 | `registered` | oui |
| `AileronRight` | Aileron droite | Aileron Right | 0 / 1 | `registered` | oui |
| `RudderLeft` | Palonnier à fond à gauche | Rudder Left Full | 0 / 1 | `registered` | oui |
| `RudderRight` | Palonnier à fond à droite | Rudder Right Full | 0 / 1 | `registered` | oui |
| `Stabilizer` | Stabilisateur de niveau | Level Stabilizer | 0 / 1 | `registered` | non |
| `AIRCRAFT_RUDDER_LEFT_1` | Palonnier gauche | Rudder Left | 0 / 1 | `registered` | oui |
| `AIRCRAFT_RUDDER_CENTRE` | Palonnier Neutre | Rudder Neutral | 0 / 1 | `registered` | oui |
| `AIRCRAFT_RUDDER_RIGHT_1` | Palonnier droite | Rudder Right | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_V_PLUS` | Trim de profondeur Cabreur | Elevator Trim Negative | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_V_0` | Trim de profondeur au neutre | Elevator Trim Neutral | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_V_MINUS` | Trim de profondeur Piqueur | Elevator Trim Positive | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_H_MINUS` | Trim d'aileron à gauche | Aileron Trim Left | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_H_0` | Trim d'aileron au neutre | Aileron Trim Neutral | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_H_PLUS` | Trim d'aileron à droite | Aileron Trim Right | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_R_MINUS` | Trim de lacet à gauche | Rudder Trim Left | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_R_0` | Trim de lacet au neutre | Rudder Trim Neutral | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TRIM_R_PLUS` | Trim de lacet à droite | Rudder Trim Right | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TOGGLE_ENGINE` | Allumage/extinction moteur | Toggle Engine | 0 / 1 | `registered` | oui |
| `AIRCRAFT_POWER_PLUS_5` | Augmenter la puissance moteur | Increase Engine Power | 0 / 1 | `registered` | oui |
| `AIRCRAFT_POWER_MINUS_5` | Diminuer la puissance moteur | Decrease Engine Power | 0 / 1 | `registered` | oui |
| `Boost` | Boost (WEP) On/Off | Boost (WEP) On/Off | 0 / 1 | `registered` | oui |
| `Power0` | Puissance 0 | Power 0 | 0 / 1 | `registered` | oui |
| `Power10` | Ouverture Soute Bombe | Power 10 | 0 / 1 | `registered` | non |
| `Power20` | Puissance 20 | Power 20 | 0 / 1 | `registered` | oui |
| `Power30` | Puissance 30 | Power 30 | 0 / 1 | `registered` | oui |
| `Power40` | Ouverture Porte Cockpit | Power 40 | 0 / 1 | `registered` | oui |
| `Power50` | Puissance 50 | Power 50 | 0 / 1 | `registered` | oui |
| `Power60` | Puissance 60 | Power 60 | 0 / 1 | `registered` | oui |
| `Power70` | Puissance 70 | Power 70 | 0 / 1 | `registered` | oui |
| `Power80` | Puissance 80 | Power 80 | 0 / 1 | `registered` | oui |
| `Power90` | Puissance 90 | Power 90 | 0 / 1 | `registered` | oui |
| `Power100` | Puissance 100 | Power 100 | 0 / 1 | `registered` | oui |
| `Step0` | Pas d'hélice 0 | Prop. Pitch 0 | 0 / 1 | `registered` | oui |
| `Step10` | Pas d'hélice 1 | Prop. Pitch 1 | 0 / 1 | `registered` | non |
| `Step20` | Pas d'hélice 2 | Prop. Pitch 2 | 0 / 1 | `registered` | non |
| `Step30` | Pas d'hélice 3 | Prop. Pitch 3 | 0 / 1 | `registered` | oui |
| `Step40` | Pas d'hélice 4 | Prop. Pitch 4 | 0 / 1 | `registered` | non |
| `Step50` | Pas d'hélice 5 | Prop. Pitch 5 | 0 / 1 | `registered` | non |
| `Step60` | Pas d'hélice 6 | Prop. Pitch 6 | 0 / 1 | `registered` | oui |
| `Step70` | Pas d'hélice 7 | Prop. Pitch 7 | 0 / 1 | `registered` | non |
| `Step80` | Pas d'hélice 8 | Prop. Pitch 8 | 0 / 1 | `registered` | non |
| `Step90` | Pas d'hélice 9 | Prop. Pitch 9 | 0 / 1 | `registered` | oui |
| `Step100` | Pas d'hélice 10 | Prop. Pitch 10 | 0 / 1 | `registered` | non |
| `StepAuto` | Pas d'hélice Auto | Prop. Pitch Auto | 0 / 1 | `registered` | oui |
| `StepPlus5` | Augmenter Pas d'hélice | Increase Prop. Pitch | 0 / 1 | `registered` | non |
| `StepMinus5` | Diminuer Pas d'hélice | Decrease Prop. Pitch | 0 / 1 | `registered` | non |
| `Mix0` | Mélange 0 | Mixture 0 | 0 / 1 | `registered` | non |
| `Mix10` | Mélange 10 | Mixture 10 | 0 / 1 | `registered` | non |
| `Mix20` | Mélange 20 | Mixture 20 | 0 / 1 | `registered` | non |
| `Mix30` | Mélange 30 | Mixture 30 | 0 / 1 | `registered` | non |
| `Mix40` | Mélange 40 | Mixture 40 | 0 / 1 | `registered` | non |
| `Mix50` | Mélange 50 | Mixture 50 | 0 / 1 | `registered` | non |
| `Mix60` | Mélange 60 | Mixture 60 | 0 / 1 | `registered` | non |
| `Mix70` | Mélange 70 | Mixture 70 | 0 / 1 | `registered` | non |
| `Mix80` | Mélange 80 | Mixture 80 | 0 / 1 | `registered` | non |
| `Mix90` | Mélange 90 | Mixture 90 | 0 / 1 | `registered` | non |
| `Mix100` | Mélange 100 (Richesse auto) | Mixture 100 (Auto Rich) | 0 / 1 | `registered` | non |
| `MixPlus20` | Augmenter mélange | Increase Mixture | 0 / 1 | `registered` | non |
| `MixMinus20` | Diminuer mélange | Decrease Mixture | 0 / 1 | `registered` | non |
| `MagnetoPlus` | Magneto suivante | Magneto Next | 0 / 1 | `registered` | non |
| `MagnetoMinus` | Magneto Précédente | Magneto Prev. | 0 / 1 | `registered` | non |
| `CompressorPlus` | Surpresseur étage suivant | Supercharger Next Stage | 0 / 1 | `registered` | non |
| `CompressorMinus` | Surpresseur étage précédent | Supercharger Prev. Stage | 0 / 1 | `registered` | non |
| `EngineSelectAll` | Sélectionner tous les moteurs | Select All Engines | 0 / 1 | `registered` | non |
| `EngineSelectNone` | Désélectionner tous les moteurs | Unselect All Engines | 0 / 1 | `registered` | non |
| `EngineSelectLeft` | Selectionner moteurs gauches | Select Left Engines | 0 / 1 | `registered` | non |
| `EngineSelectRight` | Selectionner moteurs droits | Select Right Engines | 0 / 1 | `registered` | non |
| `EngineSelect1` | Sélectionner moteur #1 | Select Engine #1 | 0 / 1 | `registered` | non |
| `EngineSelect2` | Sélectionner moteur #2 | Select Engine #2 | 0 / 1 | `registered` | non |
| `EngineSelect3` | Sélectionner moteur #3 | Select Engine #3 | 0 / 1 | `registered` | non |
| `EngineSelect4` | Sélectionner moteur #4 | Select Engine #4 | 0 / 1 | `registered` | non |
| `EngineSelect5` | Sélectionner moteur #5 | Select Engine #5 | 0 / 1 | `registered` | non |
| `EngineSelect6` | Sélectionner moteur #6 | Select Engine #6 | 0 / 1 | `registered` | non |
| `EngineSelect7` | Sélectionner moteur #7 | Select Engine #7 | 0 / 1 | `registered` | non |
| `EngineSelect8` | Sélectionner moteur #8 | Select Engine #8 | 0 / 1 | `registered` | non |
| `EngineToggleAll` | Bascule sélection tous les moteurs | Toggle Selection for All Engines | 0 / 1 | `registered` | non |
| `EngineToggleLeft` | Bascule moteurs gauches | Toggle Left Engines | 0 / 1 | `registered` | non |
| `EngineToggleRight` | Bascule moteurs droits | Toggle Right Engines | 0 / 1 | `registered` | non |
| `EngineToggle1` | Sélectionner/Désélectionner moteur #1 | Select/Unselect Engine #1 | 0 / 1 | `registered` | non |
| `EngineToggle2` | Sélectionner/Désélectionner moteur #2 | Select/Unselect Engine #2 | 0 / 1 | `registered` | non |
| `EngineToggle3` | Sélectionner/Désélectionner moteur #3 | Select/Unselect Engine #3 | 0 / 1 | `registered` | non |
| `EngineToggle4` | Sélectionner/Désélectionner moteur #4 | Select/Unselect Engine #4 | 0 / 1 | `registered` | non |
| `EngineToggle5` | Sélectionner/Désélectionner moteur #5 | Select/Unselect Engine #5 | 0 / 1 | `registered` | non |
| `EngineToggle6` | Sélectionner/Désélectionner moteur #6 | Select/Unselect Engine #6 | 0 / 1 | `registered` | non |
| `EngineToggle7` | Sélectionner/Désélectionner moteur #7 | Select/Unselect Engine #7 | 0 / 1 | `registered` | non |
| `EngineToggle8` | Sélectionner/Désélectionner moteur #8 | Select/Unselect Engine #8 | 0 / 1 | `registered` | non |
| `EngineExtinguisher` | Extincteur | Fire Extinguisher | 0 / 1 | `registered` | non |
| `EngineFeather` | Hélice en drapeau | Feather Prop. | 0 / 1 | `registered` | non |
| `AIRCRAFT_FLAPS_NOTCH_UP` | Volets haut | Flaps Up | 0 / 1 | `registered` | oui |
| `AIRCRAFT_FLAPS_NOTCH_DOWN` | Volets bas | Flaps Down | 0 / 1 | `registered` | oui |
| `Gear` | Train d'atterrissage haut/bas | Gear Up/Down | 0 / 1 | `registered` | oui |
| `AIRCRAFT_GEAR_UP_MANUAL` | Rentrer le train manuellement | Rise Gear manually | 0 / 1 | `registered` | non |
| `AIRCRAFT_GEAR_DOWN_MANUAL` | Baisser le train manuellement | Lower Gear manually | 0 / 1 | `registered` | non |
| `Radiator` | Radiateur ou volets de blindage | Cowl or Armor Flaps | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TOGGLE_AIRBRAKE` | Aérofrein | Airbrake | 0 / 1 | `registered` | non |
| `Brake` | Freins de roue | Wheel Brakes | 0 / 1 | `registered` | oui |
| `AIRCRAFT_TAILWHEELLOCK` | Verrouillage roulette de queue | Lock Tail Wheel | 0 / 1 | `registered` | non |
| `AIRCRAFT_DROP_TANKS` | Larguer les bidons | Jettison Droptanks | 0 / 1 | `registered` | oui |
| `AIRCRAFT_DOCK_UNDOCK` | Attache/Détache avion | Attach/Detach Aircraft | 0 / 1 | `registered` | non |
| `WINGFOLD` | Replier/Délier les ailes | Toggle Wing Fold | 0 / 1 | `registered` | non |
| `AIRCRAFT_CARRIERHOOK` | Déplier/Replier crosse d'appontage | Toggle Arresting Hook | 0 / 1 | `registered` | non |
| `AIRCRAFT_BRAKESHOE` | Placer/Enlever les cales | Toggle Chocks | 0 / 1 | `registered` | non |
| `COCKPITDOOR` | Ouvrir/Fermer la verrière | Open/Close Canopy | 0 / 1 | `registered` | non |
| `Weapon0` | Arme 1 | Weapon 1 | 0 / 1 | `registered` | oui |
| `Weapon1` | Arme 2 | Weapon 2 | 0 / 1 | `registered` | oui |
| `Weapon2` | Arme 3 | Weapon 3 | 0 / 1 | `registered` | oui |
| `Weapon3` | Arme 4 | Weapon 4 | 0 / 1 | `registered` | oui |
| `Weapon01` | Armes 1+2 | Weapon 1+2 | 0 / 1 | `registered` | non |
| `GunPods` | Activer/désactiver les pods canons | Toggle Gun Pods On/Off | 0 / 1 | `registered` | non |
| `SIGHT_AUTO_ONOFF` | Mode auto viseur | Toggle Sight Mode (Auto) | 0 / 1 | `registered` | non |
| `SIGHT_DIST_PLUS` | Augmenter la distance du viseur | Increase Sight Distance | 0 / 1 | `registered` | non |
| `SIGHT_DIST_MINUS` | Diminuer la distance du viseur | Decrease Sight Distance | 0 / 1 | `registered` | non |
| `SIGHT_SIDE_RIGHT` | Ajuster le viseur à droite | Adjust Sight Control to Right | 0 / 1 | `registered` | non |
| `SIGHT_SIDE_LEFT` | Ajuster le viseur à gauche | Adjust Sight Control to Left | 0 / 1 | `registered` | non |
| `SIGHT_ALT_PLUS` | Augmenter l'altitude du viseur | Increase Sight Altitude | 0 / 1 | `registered` | non |
| `SIGHT_ALT_MINUS` | Diminuer l'altitude du viseur | Decrease Sight Altitude | 0 / 1 | `registered` | non |
| `SIGHT_SPD_PLUS` | Augmenter la vitesse du viseur | Increase Sight Velocity | 0 / 1 | `registered` | non |
| `SIGHT_SPD_MINUS` | Diminuer la vitesse du viseur | Decrease Sight Velocity | 0 / 1 | `registered` | non |

### Vues instantanées (`SnapView`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `SnapPanSwitch` | Bascule vues rapide/panoramique | Toggle Snap/Pan View | 0 / 1 | `registered` | oui |
| `Snap_0_0` | Regarder devant | Look Forward | 0 / 1 | `registered` | oui |
| `Snap_0_1` | Regarder Face haut | Look Front Up | 0 / 1 | `registered` | non |
| `Snap_0_m1` | Regarder face bas | Look Front Down | 0 / 1 | `registered` | oui |
| `Snap_m1_0` | Regarder face gauche | Look Front Left | 0 / 1 | `registered` | oui |
| `Snap_1_0` | Regarder face droit | Look Front Right | 0 / 1 | `registered` | oui |
| `Snap_m1_1` | Regarder face haut gauche | Look Front Up Left | 0 / 1 | `registered` | non |
| `Snap_1_1` | Regarder face haut droit | Look Front Up Right | 0 / 1 | `registered` | non |
| `Snap_m1_m1` | Regarder face bas gauche | Look Front Down Left | 0 / 1 | `registered` | non |
| `Snap_1_m1` | Regarder face bas droite | Look Front Down Right | 0 / 1 | `registered` | non |
| `Snap_m3_0` | Regarder arrière gauche | Look Back Left | 0 / 1 | `registered` | oui |
| `Snap_3_0` | Regarder arrière droite | Look Back Right | 0 / 1 | `registered` | oui |
| `Snap_m3_1` | Regarder arrière haut gauche | Look Back Up Left | 0 / 1 | `registered` | non |
| `Snap_3_1` | Regarder arrière haut droite | Look Back Up Right | 0 / 1 | `registered` | non |
| `Snap_m3_m1` | Regarder arrière bas gauche | Look Back Down Left | 0 / 1 | `registered` | non |
| `Snap_3_m1` | Regarder arrière bas droite | Look Back Down Right | 0 / 1 | `registered` | non |
| `Snap_0_2` | Regarder haut | Look Up | 0 / 1 | `registered` | oui |
| `Snap_m2_2` | Regarder haut gauche | Look Up Left | 0 / 1 | `registered` | non |
| `Snap_2_2` | Regarder haut droite | Look Up Right | 0 / 1 | `registered` | non |
| `Snap_0_m2` | Regarder bas | Look Down | 0 / 1 | `registered` | oui |
| `Snap_m2_m2` | Regarder bas gauche | Look Down Left | 0 / 1 | `registered` | non |
| `Snap_2_m2` | Regarder bas droite | Look Down Right | 0 / 1 | `registered` | non |
| `Snap_m2_0` | Regarder gauche | Look Left | 0 / 1 | `registered` | oui |
| `Snap_2_0` | Regarder droite | Look Right | 0 / 1 | `registered` | oui |

### Temps et pause (`timeCompression`)

| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |
|---|---|---|---:|---|---|
| `timeSpeedUp` | Accélérer le temps x2/x4/x8 | Accelerate Time x2/x4/x8 | 0 / 1 | `registered` | oui |
| `timeSpeedNormal` | Temps normal | Normal Time | 0 / 1 | `registered` | oui |
| `timeSpeedDown` | Décélérer le temps x2/x4 | Decelerate Time x2/x4 | 0 / 1 | `registered` | oui |
| `timeSpeedPause` | Pauser le jeu | PauseGame | 0 / 1 | `registered` | oui |
| `timeSkip` | Saut dans le temps | Time Skip | 0 / 1 | `registered` | non |

## Commandes internes

Ces commandes ont un identifiant ou un environnement marqué interne. Le lanceur ne doit pas les proposer au joueur sans preuve supplémentaire.

| Environnement | Identifiant | Libellé |
|---|---|---|
| `$$$misc` | `quickSaveNetTrack` | Enregistrement rapide |
| `$$$misc` | `radioChannelSwitch` | Switch canaux Radio |
| `$$$misc` | `radioMuteKey` | Silence radio joueur |
| `$$$misc` | `soundMuteKey` | Couper le son |
| `pilot` | `$$+SIGHTCONTROLS` | — |
| `pilot` | `$$$1` | — |
| `pilot` | `$$$10` | — |
| `pilot` | `$$$2` | — |
| `pilot` | `$$$3` | — |
| `pilot` | `$$$4` | — |
| `pilot` | `$$$5` | — |
| `pilot` | `$$$6` | — |
| `pilot` | `$$$7` | — |
| `pilot` | `$$$8` | — |
| `pilot` | `$$$9` | — |

## Affectations non confirmées ou probablement anciennes

Une ligne `settings-only` a été vue dans un profil joueur mais aucune déclaration correspondante n'a été retrouvée dans les classes statiques analysées. Elle doit être conservée lors d'une réécriture, mais signalée comme non confirmée.

| Environnement | Identifiant | Exemples d'affectation |
|---|---|---|
| `orders` | `order10` | Q |
| `orders` | `order11` | W |
| `orders` | `order12` | E |
| `orders` | `order13` | R |
| `orders` | `order14` | T |
| `orders` | `order15` | Y |
| `orders` | `order16` | U |
| `orders` | `order17` | I |
| `pilot` | `AIRCRAFT_STABILIZER` | N, N |

## Limites et prochaines preuves nécessaires

- Produire le même catalogue depuis une installation 4.09m strictement d'origine pour classer chaque commande comme historique ou ajoutée.
- Résoudre les alias observés, notamment `AIRCRAFT_STABILIZER` face à la commande déclarée `Stabilizer`.
- Vérifier pourquoi les anciens profils contiennent `order10` à `order17` alors que la classe analysée ne déclare que `order0` à `order9`.
- Corriger ou remplacer certains libellés français manifestement incohérents; le libellé anglais est conservé comme référence parallèle.
- Étendre l'inventaire à toutes les clés de `conf.ini` et aux formats SFS, missions, modèles de vol, rendu, son et réseau.
