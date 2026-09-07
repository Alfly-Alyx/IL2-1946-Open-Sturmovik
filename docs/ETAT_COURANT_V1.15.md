# Etat courant faisant autorite — Open Sturmovik v1.15

Derniere consolidation : 7 septembre 2026.

## Perimetre de travail

- depot local verifie : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik` ;
- branche active : `v1.15`, sans changement, fusion ni rebase ;
- le lanceur reste dans son depot/worktree separe ;
- aucune autre tache IA n'est active et aucun nouveau worktree n'est requis ;
- aucun chantier v1.20 ne fait partie de cette reprise ;
- la copie de test a ete synchronisee apres consolidation des travaux hors jeu ;
- aucun jeu ne doit etre lance pour la consolidation Git ; les essais precedents
  et leurs limites sont distingues ci-dessous ;
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

Les prefixes Bereznyak-Isayev manquants devant BI-1 et BI-6 sont ajoutes ;
les trois air.ini sont inchanges octet pour octet. Mustang Mk.III/Mk.IV et
Curtiss Hawk/Tomahawk sont conserves apres verification historique.

Le commit de consolidation `eb674095b014e117edbf5bb92eb1cc68d141a67c` a ete
pousse et verifie sur GitHub `v1.15` avant ce test. Les correctifs du 7 septembre
font l'objet d'une consolidation distincte : preparation hors jeu 6 PASS,
copie de test synchronisee par `manifests/test/bi-cw21-dedup-v1.15.json`.

**Prochaine sequence demandee :** validation des choix uniques et des deux
armements CW-21, de la liste d'avions et du switcher. La discussion
de release vient ensuite ; aucun tag, publication ou installateur final n'est
autorise par le seul push. Les autres points ouverts restent documentes.

| No | Point v1.15 | Etat courant hors jeu | Reste avant fermeture |
| ---: | --- | --- | --- |
| 1 | KB-29P et CW-21 absents de la liste de l'editeur | KB-29P corrige a son adresse de classe canonique, ancien doublon retire. Cockpit CW-21 4.09 integre ; armement 4 x .303 ou 2 x .303 + 2 x .50 au choix. Voir CW21_COCKPIT_ARMAMENT_V1.15.md. | Verifier la presence des deux appareils dans la liste utilisee par Alexis, puis cockpit et deux armements CW-21. |
| 2 | Polygones blancs et erreurs de nuages | WxTech Jan 2023 conserve, sans retrait supplementaire de la physique Atmosphere. Intel OpenGL reste une piste pour les pics ; essai DirectX original prepare, reversible, sans baisse de resolution des textures. | Comparer la meme scene en DirectX/OpenGL puis au stock ; exiger zero artefact/exception et conserver le detail et le realisme. |
| 3 | Sons Allison des P-39 et boucle de ralenti persistante | Chaine Allison completee. Vingt drapeaux de boucle de demarrage retires dans dix presets Tiger33, sans modifier les WAV ni les courbes RPM. Allison etait deja sans ces boucles : cause globale non demontree. | Ecouter P-39N et Bf-109 DB-600, cockpit/exterieur, demarrage et depart en vol ; verifier le regime reel. |
| 4 | Zuti dix minutes, MDS et fermeture | Zuti MDS 1.13 charge, correctif `ExtendPlanesWings` integre ; les methodes R/R/R sont preservees dans la classe moteur fusionnee avec AOC. | Exercer radar, limite d'appareils, R/R/R, porte-avions, hote/client et fermeture. |
| 5 | AOC compatible 4.09m | AOC V1/1a complet retrouve dans HSFX 4.0 : trois classes et 267 profils sources. La v1.15 en distribue 266 ; le profil specifique du Bf-109G-6 Early est retire afin que cet appareil utilise `Defaut.txt`. Les dix reglages ont un consommateur dans la fusion AOC+Zuti reproductible. | Verifier la creation du profil Bf depuis `Defaut.txt`, son chargement au second passage, puis chauffe, demarrage, G negatifs, carburant, magnetos et coexistence Zuti. |
| 6 | Absence de pause a la perte de focus | Alexis confirme que la simulation continue pendant la perte de focus. | Retour utilisateur valide pour l'essai fenetre effectue ; ne pas lui faire recommencer ce point sans regression observee. |
| 7 | Profils avec/sans 6DOF et TrackIR | Les cinq classes 6DOF/TrackIR sont identifiees et les EXE 4.08, 4.09b et 4.09m sont distincts entre profils avec et sans 6DOF selon la source AAA. | Valider six axes, profil sans translation, recentrage, perte de focus et restauration. |
| 8 | DCG, Mission Mate, WeatherSet, FOV Changer | Initialisation et cibles controlees dans la copie de test. `SaveAspect=0` est sous `[window]` conformement au manuel San FOV Changer ; DeviceLink 4.09m et les chemins Mission Mate/HardBall sont prepares. | Ouvrir les quatre raccourcis et effectuer une operation reversible par outil. |
| 9 | ZipNav, IL2 Compare, HardBall408, Bombsight Table 2, JoyCtrl | Les cinq outils completent les quatre precedents. Le switcher porte le total de la mise a jour a dix raccourcis, tous crees et verifies dans le Bureau temporaire. Cartes ZipNav et position visible de Bombsight Table 2 controlees. | Tester demarrage, donnees et ecritures reversibles, sans runtime installe globalement. |
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

Le petit ensemble local etait incomplet : le chargeur AOC etait present, mais
les parties moteur avaient ete remplacees par Zuti. La fusion courante conserve
Zuti comme base, restaure uniquement les consommateurs AOC de HSFX, lit les 266
profils distribues sous `_Game_Enhancements/Mod_AOC_Public` et ne fabrique
aucune donnee physique. Le paquet HSFX original en contenait 267 ; le profil
du Bf-109G-6 Early est volontairement omis pour utiliser `Defaut.txt`.
Le constructeur est `tools/Build-OpenSturmovikAocZutiPatch.ps1` et la preuve
detaillee se trouve dans `docs/AUDIT_ZUTI_AOC.md`.

### Configuration et utilitaires

`SaveAspect=0` reste sous `[window]`. Le manuel fourni avec San FOV Changer 1.0
l'exige avec un bloc `[DeviceLink]` sur le port 1711. `TypeClouds=1` reste sous
`[game]` et dans la section du fournisseur graphique selectionne ; les
preferences du fournisseur inactif sont conservees.

`manifests/utilities-v1.15.json` declare neuf utilitaires et le switcher, soit
exactement dix raccourcis.
`tools/Complete-OpenSturmovikV115Update.ps1` est le point d'entree de fin de mise
a jour : une fois les fichiers poses, il initialise la cible puis cree les dix
raccourcis sur le Bureau. La verification actuelle a utilise uniquement
`WIP/test-desktop/v1.15-clean-pretest-20260906`.

### Organisation et switcher

Le dossier de documentation runtime est `_Documentations`, au pluriel. Ses cinq
sous-dossiers ont des intitules anglais : `Campaigns`, `Game and Patches`,
`Maps`, `Mission Building` et `Mods and Tools`. `_Runtime_Addons` et l'ancien
`Mod_AOC_Public` de la racine ont ete retires ; AOC reside uniquement sous
`_Game_Enhancements/Mod_AOC_Public`.

Le switcher `.bat` gere neuf profils : Original, sans 6DOF et avec 6DOF pour
4.08m, 4.09b et 4.09m. Sa transaction reelle a ete exercee hors jeu sur les
profils 1, 2 et 8, avec les HUD standard et immersion : remplacements et
retraits exacts, zero message parasite, zero transaction abandonnee. La copie
est revenue au profil 8.

Les six EXE modifies portent les metadonnees Windows `Open Sturmovik`; les trois
EXE Original sont inchanges. La surcharge `Config` fixe le titre de fenetre
des seuls profils avec wrapper. La reconstruction est idempotente et repasse
sans modifier les empreintes. Alexis a confirme le titre en jeu ; l'affichage
du Gestionnaire des taches et les profils Original restent a qualifier.

## Copie preparee pour la reprise ciblee

- cible : `WIP/test-installations/IL 2 Sturmovik 1946 test` ;
- plan complet : `WIP/test-plans/v1.15-clean-pretest-20260906.json` ;
- dernier correctif : `WIP/test-plans/runtimefix-20260906.json`, 184 entrees
  verifiees conformes apres synchronisation ;
- correction finale du nom :
  `WIP/test-plans/v1.15-documentations-name-20260906.json` ;
- derniers plans appliques :
  `manifests/test/cw21-and-aircraft-presentation-v1.15.json`, puis
  `manifests/test/aircraft-family-evolution-v1.15.json` ;
- derniere sauvegarde recuperable : `WIP/test-installations/sync-20260906-221033` ;
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
et le switcher. Le son CW-21, AOC, MDS/Zuti, 6DOF/TrackIR, les utilitaires et
la non-regression complete restent a qualifier ou diagnostiquer. Les nuages
DirectX, le titre modifie et la perte de focus ont deja ete confirmes par Alexis.
L'inventaire des profils AOC
de test devra etre clarifie avec lui avant qualification du paquet complet.
Les bombes
nucleaires, nouveaux wrappers et chargement progressif des textures restent
hors v1.15.
