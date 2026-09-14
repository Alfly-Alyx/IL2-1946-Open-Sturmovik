# Etat courant faisant autorite — Open Sturmovik v1.15

Derniere consolidation : 13 septembre 2026.

## Installeur complet et affichage — 13 septembre 2026

Le nouvel installeur complet 1.15 est préparé dans `installer`, sans compilation. Il doit être posé sur une installation IL-2 sans ancienne version d'Open Sturmovik ; il ne contrôle pas le numéro 4.07/4.08/4.09 présent. Il conserve `Users`, ainsi que les fichiers déjà présents dans `Missions` et `PaintSchemes`. Le `conf.ini` de la racine constitue l'exception : il est sauvegardé en `.bak`, remplacé par le modèle du pack, puis adapté à la résolution active de l'écran principal Windows.

Le modèle, les deux lanceurs VBS et le détecteur de résolution sont présents dans `_Game Switcher` et dans `installer/Payload/_Game Switcher`. Le raccourci direct et le raccourci du switcher refont la détection avant utilisation. Le plein écran, le volume musical 1 et les onze raccourcis Bureau sont les valeurs actuelles de l'installeur. Les détails se trouvent dans `installer/README.md` et `AUDIT_CONF_INI_HISTORIQUE.md`.

Le lancement réel du 13 septembre depuis la copie de test a détecté l'écran principal en 1920 × 1080, écrit la configuration puis maintenu il2fb.exe actif au-delà des dix secondes de contrôle. Le journal du moteur confirme `Size: 1920x1080` pour ce lancement. Le processus s'est ensuite fermé sans événement de plantage Windows. Le même journal signale séparément une tentative refusée de chargement de `GUI/background.tga`, trop volumineux pour le tampon de texture historique. Alexis confirme néanmoins que le fond était visible : cette ligne est donc non bloquante et ne prouve pas l'absence du fond affiché.


Le moteur de l'interface emploie des coordonnées logiques x1024(...) et y1024(...) fondées sur une référence 1024 × 768. Les grandes polices et les gros éléments de menu observés en plein écran sont donc compatibles avec un contexte graphique 1920 × 1080 ; aucune option distincte de taille d'interface n'a été trouvée dans le conf.ini 4.09m.

La rotation des fonds de chargement validée reste incluse dans `Files` et dans le Payload. Son algorithme persistant et son indépendance vis-à-vis des huit fonds de l'assistant Inno Setup sont documentés dans `ROTATION_FONDS_CHARGEMENT.md`.

## Copie actualisee et relance du 12 septembre

La copie `WIP/tests/installations/IL 2 Sturmovik 1946 test` a ete synchronisee
apres les retraits : 287 copies et 1 240 retraits recuperables, dont quatre
anciennes missions de demonstration MDS propres au test. Sauvegarde :
`WIP/tests/installations/sync-20260912-141157`.
Le controle du contenu donne **24 PASS, 1 WARN, 0 FAIL**, sans exception AOC
ou MDS. Les 266 profils AOC distribues sont conformes. Les **42 controles
avant lancement** passent ; les neuf fichiers de reglages et profils joueur
controles sont inchanges. Le profil existant 9 / 4.09m avec 6DOF / HUD
standard / DirectX est conserve, sans reapplication du switcher.

Le jeu a ete lance a la demande d'Alexis pour ses essais. Ce lancement ne
vaut pas validation des vols, des deux armements CW-21 ou de la campagne
complete. Voir [le compte rendu de relance](RELANCE_TEST_V1.15_20260912.md).
Les resultats plus anciens ci-dessous restent historiques.

## Retraits demandes le 12 septembre

DCG 3.43, San FOV 1.0 et la carte Malta de 6S.Maraz sont retires du depot,
avec les missions et campagnes dependantes de Malta. Les sauvegardes verifiees
sont sous `Mods\Retirés\besoin_licence` dans les ressources locales. Le
manifeste des utilitaires declare maintenant huit raccourcis ; l'ancienne
ebauche d'installateur a ete supprimee.
Les credits publics correspondent aux retraits effectifs.

Zuti MDS est retire du contenu local. Les 699 originaux touches sont archives
avec verification des empreintes dans
`Mods/Retirés/besoin_licence/Zuti MDS 1.13/retrait_complet_pack_20260912` :
648 fichiers retires, dont 544 classes correspondant a 543 noms internes ;
51 fichiers remplaces, dont quatre classes, 43 missions et quatre catalogues
de textes. Les 43 missions dediees a MDS sont retirees avec leurs fichiers
associes. La simulation des trois versions passe : aucun marqueur Zuti dans
les classes controlees et aucune nouvelle rupture de reference detectee.
Les tests statiques et cibles passent ; les essais reels du jeu et de
l'installateur restent a refaire. La version finale ne peut pas encore etre declaree prete. Le [suivi des retraits](RETRAIT_COMPOSANTS_V1.15.md)
fait autorite sur ces composants. Les resultats historiques ci-dessous restent
dates ; la copie WIP est maintenant synchronisee comme indique ci-dessus.
Les anciens controles du Bureau temporaire ne qualifient pas un installateur.

## Perimetre de travail

- depot local verifie : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik` ;
- branche active : `v1.15`, sans changement, fusion ni rebase ;
- le lanceur reste dans son depot/worktree separe ;
- aucun nouveau worktree ni changement de branche n'est requis pour ce retrait ;
- aucun chantier v1.20 ne fait partie de cette reprise ;
- la copie de test a ete actualisee apres les retraits avant la relance demandee ;
- le lancement du 12 septembre est explicitement demande par Alexis ; les
  essais precedents et leurs limites sont distingues ci-dessous ;
- le vrai Bureau n'a pas ete modifie : les raccourcis ont ete verifies dans un
  Bureau temporaire.

Ce document remplace les anciens plans lorsqu'ils contredisent ce perimetre.
Pour toute ressource encore manquante, la regle commune est decrite dans
`docs/SOURCES_RESSOURCES_MANQUANTES_V1.15.md` : ressources locales, archives
AAA/Wayback 2006-2010, publications d'origine, puis paquets historiques complets
et miroirs verifiables. Aucun parametre physique n'est invente.

## Etat des dix points de `IL2.txt`

### Derniere reprise, apres les retours du test du 7 septembre

Les retours utilisateur acquis sont : KB-29P fonctionnel, titre de fenetre
`Open Sturmovik`, nuages WxTech juges magnifiques en DirectX et simulation
continue a la perte de focus. Ne pas refaire ces essais sans regression.

Le deuxieme armement CW-21 est maintenant enregistre directement dans les
collections lues par le jeu : la methode historique `weaponsRegister` de cette
installation ne faisait rien. Le test du bytecode produit passe, mais les deux
armements doivent encore etre selectionnes et essayes en vol. Le moteur trop
discret reste non corrige : une trace du preset reel est prete au chargement
du CW-21 ; aucun volume arbitraire n'a ete applique.

Le test utilisateur du 7 septembre a revele des doublons `4 x .303` et
`sans armement`. Le chargement tardif ajoutait ses deux choix d'origine a
notre liste. Une liste anti-doublons propre au CW-21 corrige ce chemin ; le
test renforce execute aussi le vrai bytecode d'import, avec entrees simulees.
Voir `CW21_DUPLICATE_LOADOUTS_V1.15.md`. La confirmation visuelle et les tirs
restent a obtenir, sans relancement automatique du jeu.

Le classement Constructeur / Modele / Variante est termine, par familles et
evolution, avec les derives navals apres leur famille terrestre. Allies, Axe
puis as (prenom, nom, modele) restent separes. Les trois listes conservent
exactement leurs entrees : active **535**, 4.08 **516**, 4.09 **535**.
Voir `CLASSEMENT_AVIONS_V1.15.md` et `CW21_COCKPIT_ARMAMENT_V1.15.md`.

Les prefixes Bereznyak-Isayev manquants devant BI-1 et BI-6 sont ajoutes.
La revue finale des noms corrige ensuite 188 libelles selon le concepteur
d'origine, sans fabricant sous licence. Mustang Mk.III/Mk.IV et Tomahawk
restent des noms nationaux distincts des designations US ; les Hawk suivent
Model 75/81 puis leur variante. Les familles Li-2/L2D et Macchi sont
repositionnees selon leur concepteur, sans changer aucune ligne technique.
Les 27 cas Early/Late sont examines : Serie I ajoutee aux G.55, distinctions
conservees quand aucun autre bloc exact n'est etabli. Les conflits IAR80early
et Bf-109E-1_Late sont documentes, pas declares resolus.
Voir `REVISION_NOMS_AVIONS_V1.15.md` et `manifests/aircraft/name-review-v1.15.json`.

Le commit de consolidation `eb674095b014e117edbf5bb92eb1cc68d141a67c` a ete
pousse et verifie sur GitHub `v1.15` avant ce test. Les correctifs du 7 septembre
font l'objet d'une consolidation distincte : preparation hors jeu 6 PASS,
copie de test synchronisee par `manifests/test/bi-cw21-dedup-v1.15.json`.

La revue finale des noms passe ensuite 11 tests de regression et les six
controles de preparation hors jeu. Ses cinq fichiers runtime sont synchronises
par `manifests/test/aircraft-name-review-v1.15.json` ; sauvegarde recuperable
`WIP/tests/installations/sync-20260907-063226`. Aucun jeu lance, aucun profil
joueur modifie ; l'ecart AOC connu de la copie de test reste preserve.

**Prochaine sequence demandee :** validation des choix uniques et des deux
armements CW-21, de la liste d'avions et du switcher. La discussion
de release vient ensuite ; aucun tag, publication ou installateur final n'est
autorise par le seul push. Les autres points ouverts restent documentes.

### Verification sans jeu ni captures du 7 septembre

Voir `VERIFICATION_SWITCHER_TEST_V1.15.md`. Les 18 commutations reelles
(neuf profils, deux fichiers HUD) passent, ainsi que les deux controles keep.
La copie est revenue au profil 8 / 4.09m / sans 6DOF / HUD standard ;
29 fichiers surveilles restent inchanges. Le classement repasse 11 tests,
le test anti-doublons CW-21 passe et la preparation du test repasse 42/42
controles avec la seule exception AOC deja connue. Aucun jeu ni capture lance.

**Ne pas confondre ces succes avec la compatibilite globale.** L'audit des
classes propres a chaque version trouve 18 classes d'avions manquantes et
deux dependances CW-21 manquantes dans le profil 4.09b modifie, qui selectionne
le registre 4.09m. Le HUD immersion propose en Original ne prouve pas son
chargement sans wrapper. Ces points ne sont pas corriges par cet audit initial.

Suite demandee : `CORRECTION_SWITCHER_V1.15.md`. Le registre beta est maintenant
distinct, avec 516 entrees dont les classes sont presentes ; les 535 entrees
4.09m et les deux autres listes sont inchangees. L'etat du profil et le HUD
conserve sont memorises, et active-profile.txt entre dans la restauration.
Le choix definitif concernant HUD immersion en stock attend encore Alexis.

| No | Point v1.15 | Etat courant hors jeu | Reste avant fermeture |
| ---: | --- | --- | --- |
| 1 | KB-29P et CW-21 absents de la liste de l'editeur | KB-29P corrige a son adresse de classe canonique, ancien doublon retire. Cockpit CW-21 4.09 integre ; armement 4 x .303 ou 2 x .303 + 2 x .50 au choix. Voir CW21_COCKPIT_ARMAMENT_V1.15.md. | Verifier la presence des deux appareils dans la liste utilisee par Alexis, puis cockpit et deux armements CW-21. |
| 2 | Polygones blancs et erreurs de nuages | WxTech Jan 2023 conserve, sans retrait supplementaire de la physique Atmosphere. Intel OpenGL reste une piste pour les pics ; essai DirectX original prepare, reversible, sans baisse de resolution des textures. | Comparer la meme scene en DirectX/OpenGL puis au stock ; exiger zero artefact/exception et conserver le detail et le realisme. |
| 3 | Sons Allison des P-39 et boucle de ralenti persistante | Chaine Allison completee. Vingt drapeaux de boucle de demarrage retires dans dix presets Tiger33, sans modifier les WAV ni les courbes RPM. Allison etait deja sans ces boucles : cause globale non demontree. | Ecouter P-39N et Bf-109 DB-600, cockpit/exterieur, demarrage et depart en vol ; verifier le regime reel. |
| 4 | Retrait MDS et stabilite du moteur | Retrait applique localement ; controles statiques sur trois versions et tests cibles passes. Anciens essais radar/R/R/R historiques. | Mission standard de dix minutes, FMB, hote/client et fermeture dans une copie actualisee ; installateur a revalider. |
| 5 | AOC compatible 4.09m | AOC V1/1a HSFX 4.0 conserve : trois classes sans MDS reconstruites, 266 profils inchanges, dix reglages consommes. | Verifier le repli Bf-109G-6 Early vers Defaut.txt, chauffe, demarrage, G negatifs, carburant et magnetos dans la copie actualisee. |
| 6 | Absence de pause a la perte de focus | Alexis confirme que la simulation continue pendant la perte de focus. | Retour utilisateur valide pour l'essai fenetre effectue ; ne pas lui faire recommencer ce point sans regression observee. |
| 7 | Profils avec/sans 6DOF et TrackIR | Les cinq classes 6DOF/TrackIR sont identifiees et les EXE 4.08, 4.09b et 4.09m sont distincts entre profils avec et sans 6DOF selon la source AAA. | Valider six axes, profil sans translation, recentrage, perte de focus et restauration. |
| 8 | Mission Mate et WeatherSet | DCG et San FOV retires le 12 septembre. L'initialiseur prepare Mission Mate/HardBall sans modifier les reglages FOV ou DeviceLink. | Effectuer une operation reversible par outil conserve dans une copie actualisee. |
| 9 | ZipNav, IL2 Compare, HardBall408, Bombsight Table 2, JoyCtrl | Ces cinq outils completent les deux precedents. Le switcher porte le total a huit raccourcis ; leurs cibles ont ete controlees apres retrait. | Tester demarrage, donnees et ecritures reversibles dans une copie actualisee, sans runtime installe globalement. |
| 10 | Non-regression finale | Campagne et reprise des quatre anomalies decrites dans `docs/CAMPAGNE_FINALE_V1.15.md`. | Rejouer les controles affectes par les correctifs, conserver les acquis puis terminer les points encore ouverts. |

## Decisions techniques actives

### Nuages

Le candidat v1.15 est **WxTech clouds Jan 2023**, pas le rendu stock. Le choix
privilegie le maximum de detail et de realisme retrouve tout en restant une
surcharge compatible avec l'architecture 4.09m. Les fichiers et empreintes sont
figes dans `manifests/effects/clouds-4.09m-v1.15.json`. La base stock ne sert que
de temoin A/B.

`TypeClouds=1` reste sous `[game]` pour le type de nuages, et dans la section
du rendu actif : `[Render_OpenGL]` ou `[Render_DirectX]`. Le reglage OpenGL est
conserve pendant l'essai DirectX. Ces sections ont des consommateurs distincts
et ne constituent pas un doublon de configuration. La copie de test est
preparee en DirectX avec le `dx8wrap.dll` original 4.09m, sans nouveau wrapper.
La piste Intel/OpenGL et la methode A/B sont documentees dans
`SUIVI_ANOMALIE_NUAGES_V1.15.md`. Alexis a valide le fonctionnement et la
qualite du rendu DirectX ; cela ne valide pas le chemin Intel/OpenGL.

### AOC

La v1.15 selectionne **AOC V1/1a de HSFX 4.0**, premier ensemble complet dont
la compatibilite IL-2 4.09m est demontree. V2a est documente mais son paquet
complet n'a pas ete retrouve ; V3a est documente en developpement mais aucune
publication complete exploitable n'a ete recuperee. Le numero le plus eleve ne
prime jamais sur la compatibilite et l'integrite du paquet.

Le constructeur courant `tools/Build-OpenSturmovikAocPatch.ps1` utilise une
base Open Sturmovik 4.09m personnalisee et expurgee des quatre methodes Motor
propres a MDS. FlightModelMain et RealFlightModel restent identiques ; les
autres methodes et champs Motor sont preserves. Les consommateurs AOC HSFX et
les 266 profils sous `_Game_Enhancements/Mod_AOC_Public` sont inchanges.
Le paquet HSFX original contenait 267 profils ; celui du Bf-109G-6 Early reste
volontairement omis pour utiliser `Defaut.txt`.
La preuve est [l'audit AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md).
`tools/Test-OpenSturmovikAoc.ps1` verifie les trois sorties et les profils ;
l'integration locale est appliquee et verifiee statiquement ; le vol reste a valider.

### Configuration et utilitaires

San FOV etant retire, l'initialiseur ne modifie plus `SaveAspect`, le port
DeviceLink ni les adresses reseau. Les configurations existantes sont conservees.
`TypeClouds=1` reste sous
`[game]` et dans la section du fournisseur graphique selectionne ; les
preferences du fournisseur inactif sont conservees.

`manifests/utilities-v1.15.json` declare sept utilitaires et le switcher, soit
exactement huit raccourcis.
`tools/Complete-OpenSturmovikV115Update.ps1` est le point d'entree de fin de mise
a jour : une fois les fichiers poses, il initialise la cible puis cree les huit
raccourcis sur le Bureau. La verification historique a utilise uniquement
`WIP/tests/desktop/v1.15-clean-pretest-20260906`.

### Organisation et switcher

Le dossier de documentation runtime est `_Documentations`, au pluriel. Ses cinq
sous-dossiers ont des intitules anglais : `Campaigns`, `Game and Patches`,
`Maps`, `Mission Building` et `Mods and Tools`. `_Runtime_Addons` et l'ancien
`Mod_AOC_Public` de la racine ont ete retires ; AOC reside uniquement sous
`_Game_Enhancements/Mod_AOC_Public`.

Le switcher est maintenant un seul fichier `.bat`, avec interface integree
inspiree du menu principal IL-2. Il propose neuf profils : Original, sans 6DOF
et avec 6DOF pour 4.08m, 4.09b et 4.09m. Ses transactions reelles ont ete
exercees hors jeu sur les neuf profils et les deux fichiers HUD : remplacements
et retraits exacts, zero transaction abandonnee. La copie est revenue au profil
8. Le profil 4.09b utilise sa liste propre de 516 entrees. Les trois choix 4.08m
utilisent maintenant le payload moteur/son 4.08m et retirent les archives 4.09.
Le BAT est force en fins de ligne Windows, necessaires a ses sous-routines.
Son lancement direct ne garde plus de console ouverte. Le raccourci Bureau
utilise le meme BAT avec une fenetre CMD masquee ; ce comportement a ete
verifie sur un raccourci cree dans le Bureau temporaire, sans l'executer.
Son dossier est `_Game Switcher` au singulier et ses images/icones sont sous
`Resources`. L'icone historique v1.1 retrouvee est active ; les variantes
v1.15, Demo 2001 et Steam citees restent conservees dans ce dossier.
Voir les correctifs et limites dans `CORRECTION_SWITCHER_V1.15.md`.

Les six EXE modifies portent les metadonnees Windows `Open Sturmovik`; les trois
EXE Original sont inchanges. La surcharge `Config` fixe le titre de fenetre
des seuls profils avec wrapper. La reconstruction est idempotente et repasse
sans modifier les empreintes. Alexis a confirme le titre en jeu ; l'affichage
du Gestionnaire des taches et les profils Original restent a qualifier.

## Copie preparee pour la reprise ciblee

- cible : `WIP/tests/installations/IL 2 Sturmovik 1946 test` ;
- plan complet : `WIP/tests/plans/v1.15-clean-pretest-20260906.json` ;
- dernier correctif : `WIP/tests/plans/runtimefix-20260906.json`, 184 entrees
  verifiees conformes apres synchronisation ;
- correction finale du nom :
  `WIP/tests/plans/v1.15-documentations-name-20260906.json` ;
- derniers plans appliques :
  `manifests/test/cw21-and-aircraft-presentation-v1.15.json`, puis
  `manifests/test/aircraft-family-evolution-v1.15.json`,
  `manifests/test/bi-cw21-dedup-v1.15.json`, et enfin
  `manifests/test/aircraft-name-review-v1.15.json` ;
- derniere sauvegarde recuperable : `WIP/tests/installations/sync-20260907-063226` ;
- AOC du depot : 266 profils distribues ; AOC de la copie de test : cinq profils
  (`Defaut`, B-29, CW-21, Mosquito-FBMkVI et P-51D-20), chacun de 274 octets.
  Cet inventaire de test a ete preserve. Les trois classes fusionnees sont conformes ;
- contenu de test : **24 PASS, 1 WARN, 1 FAIL** ; le WARN concerne le nouveau
  dump absent et le FAIL l'inventaire AOC different de celui du paquet. Cet
  ecart seul est accepte explicitement pour la synchronisation ciblee, sans
  qualifier la distribution complete ;
- dernier controle de contenu du depot, sans dump et hors nucleaire :
  **25 PASS, 1 WARN, 0 FAIL** ; le WARN demande une verification runtime.
  L'ancien controle avec dump ne constitue pas un nouvel essai des fichiers corriges ;
- disponibilite ciblee : **42/42**, `Ready=True` uniquement avec l'exception
  AOC ci-dessus, resolution de fenetre actuelle conservee. Rapport :
  `build/runtimefix-test-readiness-20260906.json` ;
- preparation v1.15 hors jeu : **6 PASS, 0 WARN, 0 FAIL** ;
- preparation Git : les ressources a empreinte stricte (air.ini, presentation,
  cockpit CW-21, nuages, profils AOC, presets sonores modifies et batch principal)
  sont preservees sans conversion de fins de ligne par `.gitattributes`.
  Leurs octets testes doivent etre identiques dans Git ;
- raccourcis temporaires : **10/10**, vrai Bureau non modifie ;
- les journaux et captures des essais utilisateur precedents ne valident pas
  les nouveaux correctifs ; une tentative de controle du menu a ete interrompue
  apres l'echec de capture Windows `SetIsBorderRequired` (0x80004002).
  Aucun vol n'a ete charge et le jeu lance par la tache a ete ferme.

## Blocages reels restants

Il ne manque plus de paquet AOC pour commencer les essais. Les prochains
controles utilisateur sont les deux armements CW-21, le classement des avions
et le switcher. Le son CW-21, AOC, le moteur apres retrait MDS, 6DOF/TrackIR, les utilitaires et
la non-regression complete restent a qualifier ou diagnostiquer. Les nuages
DirectX, le titre modifie et la perte de focus ont deja ete confirmes par Alexis.
L'inventaire des profils AOC de test est desormais conforme aux 266 profils
distribues ; leur fonctionnement en vol reste a qualifier.
Les bombes
nucleaires, nouveaux wrappers et chargement progressif des textures restent
hors v1.15.
