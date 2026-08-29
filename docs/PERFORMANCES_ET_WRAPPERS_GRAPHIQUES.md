# Chargements, execution et wrappers graphiques

## Diagnostic actuel

Le depot est deja place sur un SSD NVMe. Le stockage brut n'est donc probablement pas le premier goulot d'etranglement sur cette machine. En revanche, le chargeur doit connaitre 89 738 fichiers repartis dans 4 892 dossiers avant de pouvoir resoudre rapidement les surcharges.

Une mesure a chaud, hors jeu, donne environ 1,4 seconde pour enumerer seulement les noms avec l'API de haut niveau utilisee par l'audit. Le calcul Python des empreintes IL-2 de tous les chemins prend environ 3,4 secondes ; le code natif du wrapper sera plus rapide, mais cette mesure confirme un cout lineaire visible. Un parcours qui force en plus une requete de metadonnees pour chaque fichier monte vers environ 19 a 21 secondes. Ce dernier nombre est une borne haute, pas un temps de lancement attribue au jeu.

Le wrapper 4.09m construit a ensuite ete mesure hors jeu par un hote PE32 qui
expose les memes fonctions SFS et voit le vrai dossier `Files` au travers d'une
jonction temporaire en lecture seule. L'indexation froide des 89 738 fichiers,
l'ecriture atomique d'un cache de 5 545 156 octets et du manifeste des 4 893
dossiers racine comprise prennent **1 890,2 ms**. Le processus suivant valide le
manifeste, charge le cache et resout une ressource en **473,4 ms**. Ce banc isole
montre un gain de **1 416,8 ms** sur la phase du wrapper, pas sur le demarrage
complet d'IL-2 ; il devra etre repete plusieurs fois pendant les futurs essais du
jeu.

`Files\.preload` contient 417 directives, dont 412 uniques et seulement 114 pointent vers une surcharge libre presente. Les 298 autres peuvent etre fournies par les SFS. Les cinq repetitions sont insignifiantes. Modifier ce fichier peut accelerer un ecran de chargement tout en provoquant des saccades plus tard ; aucune entree ne doit etre retiree sans trace d'acces et comparaison en mission.

L'EXE modifie demarre Java 1.3.1 avec `-Xcomp -Xverify:none -Xmx1G -Xincgc`. `-Xcomp` force la compilation des methodes au lieu de commencer en mode mixte : c'est un candidat credible pour expliquer une partie du cout initial en echange d'une execution ensuite plus reguliere. `-Xverify:none` reduit la verification des classes, mais ne contourne pas la limite de version : le test isole confirme que les classes version 50 restent refusees. Ces options devront etre comparees par des EXE de test separes, jamais modifiees directement dans le seul profil stable.

## Ordre des optimisations

| Priorite | Action | Gain attendu | Risque |
| ---: | --- | --- | --- |
| 1 | Mesurer demarrage, menu et deux missions temoins | Etablit une base fiable | Aucun pour une copie de test |
| 2 | Mesurer le chargeur cache 4.09m experimental deja porte | Fort sur l'indexation des 89 738 fichiers | Regression encore possible dans le jeu |
| 3 | Valider l'invalidation automatique du manifeste en installation reelle | Conserve le gain sans ressources fantomes | Faible ; banc isole deja valide |
| 4 | Creer des profils de contenu actif plutot que scanner toutes les cartes/avions | Potentiellement fort | Dependances manquantes si le graphe est incomplet |
| 5 | Etudier un SFS propre au mod, reproductible et optionnel | Moins d'ouvertures de petits fichiers | Outil/format, priorites et maintenance a valider |
| 6 | Ajuster `.preload` d'apres les traces | Compromis demarrage/saccades | Regression en mission |
| 7 | Ajuster tas Java et affinite avec mesures | Stabilite et fluidite CPU | Crash par manque de memoire native ou mauvais masque |
| 8 | Comparer `-Xcomp` au mode mixte dans un EXE de test | Demarrage potentiellement plus court | Compilation en cours de jeu et micro-saccades |

Les 179 copies exactes conservees ne representent que 1,5 Mo et n'ont pas d'effet mesurable attendu sur ce probleme. Les supprimer n'est pas une optimisation pertinente.

## Ce que confirme le cache du Selector communautaire

Le code source public du Selector 3.3 confirme que le cache evite l'enumeration
recursive de `MODS` et `FILES`. Il confirme aussi une limite essentielle :
`~wrapper.cache` est accepte sans verifier si le contenu du dossier a change.

La version 1.15 contient maintenant un port 4.09m separe qui corrige la convention
d'appel et remplace ce cache aveugle par deux paires liste/manifeste sous
`.open-sturmovik-cache`. Le manifeste valide tous les dossiers connus avant de
lire les 89 738 entrees. Une ligne vide, un fichier tronque, une fin absente, un
compteur incoherent ou un horodatage de dossier different force une enumeration
complete. Le banc isole a valide cache froid, cache chaud, ajout de fichier et
corruption. Les choix 11/12 sont experimentaux jusqu'aux mesures en jeu ; les
choix 8/9 restent le repli stable.

La priorite observee et conservee par le port est `MODS`, puis `FILES`, puis SFS.
Toute future reduction ou repartition du contenu doit conserver cet ordre et
detecter les collisions d'empreintes avant activation.

## Execution CPU et memoire

- conserver Large Address Aware sur les EXE modifies ;
- conserver provisoirement `-Xmx1G` jusqu'a mesure simultanee du tas Java et de la memoire native ;
- conserver le profil stable avec ses options JVM et tester le retrait de `-Xcomp` uniquement dans un profil experimental ;
- utiliser le masque calcule par le selecteur, qui choisit au plus quatre coeurs physiques et conserve 15 comme repli ;
- ne pas promettre quatre fois plus de performances : l'ancien moteur conserve des chemins principalement sequentiels, tandis que le son et certains services utilisent leurs propres threads ;
- distinguer un profil **Qualite maximale** du futur profil **Performance equilibree** : certains reglages visuels augmentent surtout la charge CPU et le nombre d'appels de dessin.

Le Selector recent sait construire au lancement des options `-Xmx`, `-Xss` et `-XX:PermSize`/`MaxPermSize` depuis `RamSize` et `MemoryStrategy`, ainsi qu'ajouter une section JVM. Cela offre une methode plus propre qu'une modification binaire pour les futurs essais. Ce n'est pas encore une preuve que 2 Gio de tas sont stables avec la JVM 1.3 et les allocations natives du moteur : le profil stable reste donc a 1 Gio jusqu'aux mesures.

## Architecture des profils graphiques

Le jeu dispose deja de deux chemins : OpenGL natif via `jgl.dll`, et Direct3D 8 via `jgl.dll` puis `dx8Wrap.dll`. Le futur selecteur graphique ne doit jamais ecraser le `wrapper.dll` des mods.

| Profil propose | Chaine | Usage |
| --- | --- | --- |
| OpenGL natif | IL-2 -> `jgl.dll` -> pilote OpenGL | Defaut sur un pilote fonctionnel ; moins de couches |
| DirectX 8 natif | IL-2 -> `jgl.dll` -> `dx8Wrap.dll` -> D3D8 systeme | Repli historique |
| dgVoodoo2 x86 | meme chaine, puis `D3D8.dll` -> D3D11/12 | Candidat Windows principal a tester |
| DXVK x86 | meme chaine, puis `d3d8.dll` -> Vulkan | Experimental sous Windows |
| Mesa OpenGL/D3D12 x86 | IL-2 -> OpenGL Mesa -> D3D12 | Recuperation si l'OpenGL constructeur est casse |
| IL2GE | Extension du coeur/rendu OpenGL | Qualite visuelle optionnelle, pas accelerateur universel |

L'executable etant 32 bits, seuls des DLL **x86** peuvent etre chargees. Chaque profil devra conserver ses DLL dans un dossier source distinct, activer seulement les noms attendus a cote de l'EXE, controler les SHA-256, sauvegarder l'etat precedent et restaurer automatiquement OpenGL natif en cas d'echec.

## Detection a effectuer

La selection automatique doit combiner : fournisseur et identifiant PCI du GPU, version du pilote, architecture x86, version OpenGL reellement creee, extensions OpenGL necessaires, presence et version du chargeur Vulkan, fonctionnalites Vulkan, niveaux D3D11/12 et essai graphique court. Le nom « NVIDIA », « AMD » ou « Intel » ne suffit pas.

Sur la machine d'analyse : Intel UHD Graphics 620, pilote `31.0.101.2141`, Core i5-8350U 4 coeurs/8 processeurs logiques, environ 32 Gio de RAM et SSD NVMe WD Blue SN580. Ce materiel fournit un bon test pour le profil Intel et pour la construction d'un masque de quatre coeurs physiques.

Le fichier `conf.max.ini` conserve maintenant les extensions NVIDIA (`TexEnvCombine4NV`, `DepthClampNV`, `TextureShaderNV`) desactivees comme valeur generique. Le selecteur ne les active que si l'adaptateur graphique actif est identifie comme NVIDIA ; Intel, AMD et les cartes inconnues gardent le profil ARB. Cette detection par fournisseur est une premiere barriere de securite, pas encore un test des extensions OpenGL. Le mode IL2GE exige en outre `Water=0` et `DynamicalLights=0`, ce qui est incompatible avec le profil maximal OpenGL actuel et justifie un fichier separe.

## Evaluation des candidats

- **OpenGL natif** reste le point de reference : une couche de traduction ne rend pas automatiquement un jeu limite par le CPU plus rapide.
- **dgVoodoo2 2.87.3** est la version courante au 29 aout 2026. Elle implemente notamment Direct3D 8.1 sur D3D11/12 et son auteur autorise l'inclusion de fichiers individuels avec un jeu ou un mod ; la compatibilite avec la double traduction propre a IL-2 doit etre mesuree avant distribution : [documentation officielle dgVoodoo2](https://dgvoodoo2.dege.freeweb.hu/dgVoodoo2/ReadmeGeneral/).
- **DXVK 3.0.2** est la version courante au 29 aout 2026. DXVK fournit D3D8 vers Vulkan et exige ici ses DLL x86, mais la branche 3.x demande Vulkan 1.4 et plusieurs fonctions modernes. Le « dernier » DXVK ne conviendra donc pas automatiquement aux GPU anciens ; la version devra etre choisie par capacites et par test. Le projet cible officiellement Wine/Linux et indique que Windows n'est pas officiellement supporte, avec des risques supplementaires sur les pilotes Intel/AMD et les overlays : [versions DXVK](https://github.com/doitsujin/dxvk/releases), [fonctions Vulkan requises](https://github.com/doitsujin/dxvk/wiki/Driver-support), [limites Windows](https://github.com/doitsujin/dxvk/wiki/Windows).
- **IL2GE** demande un selecteur IL-2 recent, le mode Perfect et OpenGL 4.5. Ses reglages obligatoires et ses limitations en font un profil visuel separe : [projet officiel IL2GE](https://gitlab.com/vrresto/il2ge).
- **Mesa** peut fournir OpenGL sur D3D12 sous Windows, mais sera reserve au depannage et non choisi comme chemin rapide par defaut : [pilote OpenGL-on-D3D12 de Mesa](https://docs.mesa3d.org/drivers/d3d12.html).

## Protocole de validation ulterieur

Les tests seront faits sur une copie complete, jamais sur le jeu de reference : lancement a froid puis a chaud, temps jusqu'au menu, chargement d'une petite mission et d'une grande carte, frametime moyen et percentiles, occupation CPU par coeur, memoire privee/virtuelle, lectures disque, erreurs graphiques, alt-tab, plein ecran, fermeture et second lancement avec cache. Chaque backend sera compare a OpenGL natif avec le meme `conf.ini`, puis avec son profil dedie.
