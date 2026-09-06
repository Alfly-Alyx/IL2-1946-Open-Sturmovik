# Audit fonctionnel des outils externes

Date de mise a jour : 6 septembre 2026.

## Conclusion

L'audit initial a porte sur les 14 groupes de l'ancien dossier `_OS_Programs`. Apres verification de leur usage communautaire, IL2 Connect et VoiceOverlay ont ete retires le 1er septembre 2026. Les 12 groupes conserves sont maintenant separes entre `_Utilities` (10 groupes) et le dossier commun `_Game_Enhancements` (San FOV et Gapa). Aucun de ces programmes externes n'est copie, active ou lance par le selecteur Open Sturmovik, les scripts ou la configuration actuelle.

En l'etat :

- les calculateurs autonomes et plusieurs interfaces s'ouvrent sous Windows x64 ;
- aucun outil qui depend du jeu n'est valide de bout en bout avec Open Sturmovik v1.15 / IL-2 1946 4.09m ;
- les generateurs de missions ont des listes d'avions incompletes ou obsoletes ;
- les chemins conserves dans plusieurs fichiers pointent vers d'anciennes installations Windows XP ;
- leur configuration finale et leur validation en situation restent a effectuer sur la copie de test commune.

La recommandation pour la v1.15 reste de ne rien lancer automatiquement. La decision du mainteneur est toutefois de remettre en service, comme outils externes a fenetre, Bombsight Table 2, HardBall408, IL2 Compare, JoyCtrl, Lowengrin DCG, Mission Mate, San's FOV Changer, WeatherSet et ZipNav. Le manifeste v1.15 decrit leurs cibles et l'installateur prepare dix raccourcis de bureau : ces neuf outils et le switcher, sans lancer les programmes. IL2 Connect et VoiceOverlay ont ete retires faute d'usage communautaire recent identifiable ; leurs suppressions restent recuperables par Git.

## Portee et methode

La cible de compatibilite est celle du depot : Open Sturmovik v1.15 sur IL-2 1946 4.09m.

L'audit a couvert :

- les 14 sous-dossiers initiaux de l'ancien `_OS_Programs` et leurs 18 executables, avant le retrait de 2 dossiers et 3 executables ;
- les aides locales, README, PDF, RTF et anciens documents Word de `_Documentations` ;
- les chemins et reglages livres avec chaque outil ;
- les dependances Windows visibles et l'architecture des executables ;
- les references eventuelles dans le selecteur, les scripts et les configurations du depot ;
- la comparaison des listes d'avions de DCG, Mission Mate et QMT avec `Files/com/maddox/il2/objects/air.ini` ;
- des lancements courts dans une copie de travail separee, sans lancer IL-2 et sans modifier les originaux.

Le terme **demarre** signifie seulement que le processus ou sa fenetre est reste actif pendant le controle. Il ne prouve ni la generation correcte d'une mission, ni l'ecriture sure de `conf.ini`, ni le fonctionnement en vol.

Gapa, San's FOV Changer et VoiceOverlay n'ont volontairement pas ete lances : ils peuvent respectivement modifier la courbe gamma de l'ecran, communiquer avec une version precise du jeu, ou injecter un ancien overlay graphique. Aucun essai materiel de joystick, client vocal ou partie en vol n'a ete effectue.

## Classification fonctionnelle a conserver

Le projet doit distinguer la nature d'un composant de son simple mode de lancement. Le fait qu'un programme possede une fenetre externe ne signifie pas qu'il a le meme effet qu'un mod moteur.

| Famille | Effet reel | Exemples et classement |
| --- | --- | --- |
| Mods moteur, regles et rendu | Code ou ressources charges par IL-2 ; changent directement les comportements, calculs, effets ou images produits par le moteur | AOC, classes Java du mod, effets, wrapper et contenus de `Files`/SFS. Aucun des programmes de `_Utilities` n'appartient a cette famille. |
| Compagnons actifs pendant le jeu | Programme externe restant actif et agissant pendant une partie, sans devenir une classe du moteur | San's FOV Changer agit sur le champ de vision ; Gapa agit sur l'affichage systeme. Bombsight et ZipNav peuvent rester visibles mais ne changent pas le moteur. |
| Configuration du jeu et des peripheriques | Modifie un fichier de reglages avant le lancement ; le programme n'est ensuite plus necessaire | JoyCtrl et IL2 Sticks pour `conf.ini`. |
| Creation et preparation de contenu | Genere ou modifie campagnes et missions avant leur chargement par le jeu | Lowengrin DCG, Mission Mate, Quick Mission Tuner et WeatherSet. DCG peut remplacer DGen/NGen dans son mode le plus invasif, mais reste un generateur externe et non un mod moteur comparable a AOC. |
| Consultation et aide au pilote | Affiche des donnees ou effectue des calculs sans modifier le jeu | HardBall408, IL2 Compare, Bombsight Table 2 et ZipNav. |
| Multijoueur et communaute | Aide a rejoindre des joueurs ou fournit des salons textuels/vocaux ; ne modifie pas les mecanismes de vol | Connexion IP native d'IL-2 et future solution vocale actuelle. IL2 Connect et VoiceOverlay ont ete supprimes : le premier n'etait pas un lobby, le second ne fournissait aucun salon vocal et affichait seulement l'activite de tres anciens clients. |

Cette classification devra etre reprise dans le futur lanceur : les mods moteur/rendu doivent etre presentes comme des composants du profil de jeu, tandis que les generateurs, comparateurs, aides au pilote et services communautaires doivent apparaitre dans des rubriques externes distinctes.

## Etat des 14 utilitaires

| Utilitaire | Verification locale | Etat pour 4.09m | Decision v1.15 |
| --- | --- | --- | --- |
| Bombsight Table 2 | Processus demarre ; aide locale presente | Calculateur autonome, sans donnees du mod | Utilisable manuellement apres controle des raccourcis en vol |
| Gapa | Non lance par precaution | Ancien outil gamma/LUT teste a l'origine sous Windows 98/XP | Optionnel seulement ; desactive par defaut |
| HardBall408 | Fenetre `HardBall408` ouverte | Donnees 4.08, donc incompletes pour 4.09m et le mod | A remettre en service avec donnees mises a niveau ou avertissement 4.08 explicite |
| IL2 Sticks | Fenetre ouverte | Chemins Windows XP invalides ; ecrit `conf.ini` | Ne pas integrer en meme temps que JoyCtrl |
| IL2C / IL2 Compare | Fenetre `IL2 Compare v2.4` ouverte | Donnees arretees a AEP 2.01 | A remettre en service apres reconstruction de son catalogue |
| il2con / IL2 Connect | Fenetre ouverte pendant l'audit | `GamePath` vide, ancien journal et recherche de `il2.exe`/ancienne cle de registre | Supprime du paquet ; utiliser la connexion IP native d'IL-2 |
| JoyCtrl / IL2 JoyControl | Fenetre ouverte | Non relie au `conf.ini` actif ; essai joystick non fait | Meilleur candidat pour les courbes de commandes |
| Lowengrin DCG 3.43 | Fenetre ouverte ; configuration temporaire creee | Reconnait les ajouts officiels 4.09, mais pas toutes les classes du mod | Candidat apres configuration et synchronisation des donnees |
| Mission Mate 6.0.1 | S'ouvre et demande le dossier d'IL-2 | Catalogue d'avions incomplet/corrompu | Son chemin racine et celui de HardBall sont maintenant initialisables sans valeur propre a une machine |
| Quick Mission Tuner 2.00.0009 | Outil principal et deux editeurs ouverts ; Shift-Rot execute avec le nom de fichier attendu | Listes 2007 incompletes | Desactive jusqu'a mise a jour des donnees et essais sur copies |
| San's IL2 FOV Changer RC 1.0 | Non lance par precaution ; dependances presentes | Points memoire dependants de la version et essai 4.09m restant | `DeviceLink.txt` 4.09m restaure, ancienne adresse materielle retiree et configuration reproductible preparee |
| VoiceOverlay Alpha 1.1 | Non lance par precaution | Cible TeamSpeak 2/Ventrilo 2.2 et anciens hooks DirectX/OpenGL ; aucun client compatible detecte | Supprime du paquet |
| WeatherSet | Fenetre ouverte | Edite des champs meteo/vent, mais leur effet reel sous 4.09m n'est pas etabli | Conserver comme editeur experimental ; essai A/B en jeu requis |
| ZipNav 1.1 | Fenetre ouverte ; `Act.jar` fonctionne avec Java 17 | Le paquet contient ses cartes, mais leur couverture et leurs echelles ne sont pas encore validees | Candidat au test de navigation stock et mod |

## Analyse et remise en service, outil par outil

Tous les outils retenus restent des applications Windows separees du jeu. DCG, Mission Mate, WeatherSet, JoyCtrl, HardBall et IL2 Compare servent principalement avant ou apres une partie. Bombsight et ZipNav peuvent rester visibles pendant le vol. IL2 Connect prepare puis lance une connexion reseau. San FOV conserve une interface externe mais agit pendant l'execution du jeu. VoiceOverlay est le seul qui dessine directement une surcouche dans l'image du jeu.

### 1. Bombsight Table 2

**Role.** Calculateur IAS/TAS et table de bombardement autonome avec raccourcis globaux.

**Etat.** Le programme demarre sans integration au jeu. Son utilite ne depend pas du catalogue d'avions de 4.09m.

**A faire.** Le lancer manuellement, verifier en vol que la fenetre et les raccourcis restent accessibles et qu'ils n'entrent pas en conflit avec IL-2 ou le selecteur.

### 2. Gapa

**Role.** Reglage gamma/contraste par profils et application du dernier profil au demarrage.

**Etat.** La documentation date de 2002 et mentionne Windows 98/XP. Le test a ete evite pour ne pas changer la LUT de l'ecran de travail.

**A faire.** Si l'outil est conserve, le placer dans une categorie « affichage, a vos risques », ne jamais le lancer automatiquement et documenter une procedure de retour aux couleurs par defaut. Tester sur une machine de jeu, HDR desactive puis active, avec fermeture normale et forcee.

### 3. HardBall408

**Role.** Consultation et comparaison des caracteristiques d'avions.

**Etat.** La fenetre s'ouvre. Les donnees sont explicitement celles de la 4.08 : les avions ajoutes en 4.09 et les classes Open Sturmovik n'y figurent pas. Le paquet inclut d'anciens composants VB/ActiveX.

**A faire.** Le garder comme reference « 4.08 historique » ou le remplacer par une edition dont les donnees 4.09 sont documentees. Garder ses DLL dans son propre dossier : ne jamais les copier dans les repertoires systeme de Windows. Mission Mate ne doit pas le presenter comme une source 4.09 tant que ses donnees ne sont pas actualisees.

### 4. IL2 Sticks

**Role.** Edition des axes et sauvegarde de profils de commandes dans `conf.ini`.

**Etat.** L'interface demarre, mais `IL2-Sticks.ini` contient encore :

- `C:\Program Files\Ubi Soft\IL-2 Sturmovik Forgotten Battles` ;
- un dossier de profils sous `C:\Documents and Settings\Administrator\...`.

**A faire.** Remplacer ces chemins par un choix explicite de l'installation cible et d'un dossier de profils portable. Verifier la sauvegarde `conf.ini.org`, n'autoriser l'ecriture que jeu ferme et tester restauration, axes et zones mortes avec un joystick reel. Choisir **soit** IL2 Sticks **soit** JoyCtrl : ils ne doivent jamais modifier le meme `conf.ini` simultanement.

### 5. IL2C / IL2 Compare

**Role.** Comparaison de performances d'avions.

**Etat.** L'application s'ouvre, mais son historique indique des donnees arretees a AEP 2.01. Elle ne peut pas servir de reference fiable pour 4.09m.

**A faire.** La remise en service exige un nouveau jeu de donnees verifie. Il faut d'abord determiner si son format de donnees peut etre regenere sans modifier l'executable, produire un catalogue 4.09m/Open Sturmovik, puis comparer plusieurs courbes avec des valeurs de reference. Tant que ce catalogue n'existe pas, l'interface fonctionne mais ses resultats restent historiques.

### 6. il2con / IL2 Connect

**Role.** Connexion/lancement du jeu et gestion de parametres reseau anciens.

**Etat.** La fenetre demarre, mais `il2_conn.ini` a un `GamePath` vide et conserve un ancien journal sur `F:`. Le programme recherche une ancienne cle `HKLM\SOFTWARE\1C\IL-2 Sturmovik\1.0` et `il2.exe`, alors que la cible utilise `il2fb.exe` et une installation portable.

**Decision.** IL2 Connect peut memoriser des serveurs, verifier leur ping et leurs informations, puis simplifier une connexion IP ; il ne fournit pas lui-meme de serveur, d'annuaire mondial ni de service Internet. Il n'existe donc aucun nombre d'utilisateurs « presents sur IL2 Connect » a consulter. Aucune trace recente de l'outil precis n'a ete identifiee dans les recherches communautaires, alors que les connexions directes d'IL-2 1946 restent documentees. L'outil a ete supprime : Open Sturmovik documentera plutot la connexion IP native, avec la meme version 4.09m et les memes fichiers chez l'hote et les joueurs.

### 7. JoyCtrl / IL2 JoyControl

**Role.** Reglage et profils de courbes joystick.

**Etat.** L'application demarre. Elle n'est pas encore pointee vers le `conf.ini` de l'installation Open Sturmovik et aucun peripherique n'a ete teste.

**A faire.** C'est le candidat recommande pour les commandes :

1. demander a l'utilisateur de choisir le `conf.ini` cible ;
2. creer une sauvegarde horodatee avant chaque ecriture ;
3. bloquer l'ecriture quand IL-2 est lance ;
4. verifier aller-retour d'un profil, axes, inversion, zones mortes et restauration ;
5. conserver IL2 Sticks desactive si JoyCtrl est retenu.

### 8. Lowengrin DCG 3.43

**Role.** Generation de campagnes et missions dynamiques, avec modes pouvant remplacer DGen/NGen.

**Etat.** L'interface demarre, mais le paquet n'est pas configure pour cette installation. Parmi les trois generateurs analyses, son catalogue est le plus proche de la cible officielle : les 18 identifiants d'avions ajoutes par la 4.09 y sont presents. Il ne couvre toutefois que 319 des 535 classes uniques du `air.ini` actif ; 216 classes du mod manquent encore.

**A faire.** Proceder par etapes :

1. configurer le chemin de `il2fb.exe` dans une copie de jeu ;
2. tester d'abord le mode de generation manuelle, sans remplacement de DGen/NGen ;
3. produire un rapport des classes, charges utiles et peintures absentes ;
4. completer `class.dcg` et les tables associees a partir des donnees actives, avec controle humain ;
5. generer, ouvrir puis jouer une campagne test ;
6. n'envisager le remplacement DGen/NGen qu'avec manifeste des fichiers, sauvegarde et restauration automatique.

Tant que ces points ne sont pas valides, DCG doit rester un outil manuel hors du selecteur.

### 9. Mission Mate 6.0.1

**Role.** Creation de missions pour IL-2 1946, avec prise en charge declaree de contenu modde.

**Etat.** L'outil s'ouvre mais demande le dossier du jeu. `FBPath.txt` est vide, l'emplacement HardBall n'est pas renseigne et le programme cherche historiquement les avions mods sous `MODS/STD/.../air.ini`, alors que le depot actif utilise `Files/com/maddox/il2/objects/air.ini`.

Son catalogue contient 322 classes uniques : 312 correspondent aux 535 classes actives, 223 manquent et 10 sont etrangeres au catalogue actif. Aucun des 18 identifiants ajoutes officiellement en 4.09 n'est present. Deux entrees `A6M2` sont dupliquees et leurs attributs sont manifestement incoherents. `MMModFlyable.txt` est vide.

**A faire.** Ne pas corriger la liste a la main au cas par cas. Creer un convertisseur reproductible qui :

1. lit le `air.ini` actif et les fichiers de charges/cartes necessaires ;
2. produit une nouvelle structure Mission Mate avec rapport des valeurs non convertibles ;
3. alimente `MMModFlyable.txt` ;
4. remplace la recherche fixe de `MODS/STD` par un chemin configurable vers `Files` ;
5. ecrit les missions dans un dossier de sortie separe ;
6. valide au minimum une mission stock 4.09 et une mission utilisant des avions du mod.

HardBall doit rester facultatif et clairement etiquete 4.08.

### 10. Quick Mission Tuner 2.00.0009

**Role.** Modification de missions, des proprietes et de la difficulte ; outil auxiliaire de rotation/deplacement.

**Etat.** Les trois interfaces graphiques demarrent. Shift-Rot fonctionne si son contrat historique est respecte : un `mission.mis` et un `mission.cfg` dans son dossier de travail ; il produit alors `mission1.mis`. Le seul echantillon livre n'a donc pas le bon nom pour un lancement direct.

Le catalogue QMT couvre 302 des 535 classes actives ; 233 manquent et une entree n'existe plus dans la liste active. Les 18 ajouts officiels 4.09 manquent tous.

**A faire.** Regenerer les tables avions, cartes et charges utiles, puis faire travailler l'outil uniquement sur une copie de mission. Ajouter un petit lanceur qui choisit l'entree, cree le dossier temporaire avec les noms attendus et n'ecrase jamais l'original.

### 11. San's IL2 FOV Changer RC 1.0

**Role.** Changement de champ de vision par raccourcis, DeviceLink/UDP et parametres propres a la version du jeu.

**Etat.** Les dependances visibles sont presentes (.NET 2+/3.5, DirectInput manage). L'ancienne adresse materielle de `pref.ini` a ete retiree. Le `DeviceLink.txt` officiel de la 4.09m a ete restaure a la racine. Les points de debut/fin propres a l'executable n'ont volontairement pas ete modifies. Le `conf.ini` appartient a l'installation de jeu et sera configure par l'initialiseur v1.15.

**A faire.** Ne jamais reprendre les anciennes valeurs comme valeurs par defaut. Dans une installation de test 4.09m :

1. appliquer l'initialiseur a la copie de test : `SaveAspect=0`, section `[DeviceLink]`, port 1711 et adresse IPv4 locale non boucle ;
2. verifier les points correspondant exactement a l'executable 4.09m utilise ;
3. tester tous les raccourcis, la coexistence avec le profil 6DOF, le multijoueur, l'arret du programme et la restauration du FOV.

### 12. VoiceOverlay Alpha 1.1

**Role.** Affichage des intervenants TeamSpeak 2 ou Ventrilo 2.2 dans DirectX 8/9 ou OpenGL.

**Etat.** Ces clients ne sont pas detectes sur la machine de test. La notice avertit de conflits possibles avec d'autres hooks, notamment Fraps, et de plantages si l'overlay est ferme pendant le jeu.

**Decision.** Le supprimer. Les traces communautaires retrouvees concernent principalement 2005-2011 et aucune utilisation recente de ce programme precis n'a ete identifiee. TeamSpeak et Ventrilo ont change de generations, tandis que VoiceOverlay ne sait lire que TeamSpeak 2 et Ventrilo 2.2. Une remise en service demanderait un environnement vocal historique et des essais de stabilite sans benefice pour une installation actuelle. Le dossier a ete retire du paquet ; sa version auditee reste recuperable dans l'historique Git.

### 13. WeatherSet

**Role.** Edition des sections meteo et vent des fichiers `.mis` (`CloudType`, vitesse/direction/altitude du vent, turbulence et rafales).

**Etat.** L'editeur demarre. Des missions du depot contiennent deja ces champs, mais la documentation 4.09 locale ne permet pas d'affirmer que le moteur cible les interprete tous. Le manuel MDS 1.13 ne valide pas non plus cette fonction. L'outil ne doit donc pas etre declare fonctionnel en jeu sur la seule base de son interface.

**A faire.** Creer deux missions minimales identiques, l'une sans ces champs et l'autre avec des valeurs extremes, puis comparer en 4.09m les nuages, la derive, les rafales et la turbulence. S'il n'existe aucune difference observable, classer WeatherSet « 4.10+ seulement » au lieu de chercher a l'integrer a la v1.15. Toujours travailler sur une copie.

### 14. ZipNav 1.1

**Role.** Calcul de route a partir des cartes et de leurs coordonnees.

**Etat.** L'interface demarre. Son paquet contient ses propres cartes et inclut notamment Bessarabia, MTO et Slovakia, mais leur correspondance exacte avec toutes les cartes actives n'est pas etablie. L'initialiseur prepare `mods/mapmods` comme jonction vers ces donnees, sans les copier ni remplacer un dossier deja present. Le helper `Act.jar` s'execute avec Java 17 et affiche correctement son aide, ce qui valide la dependance Java mais pas l'extraction complete d'une carte.

**A faire.** Tester une carte stock et une carte du mod, comparer l'echelle et plusieurs caps connus, puis documenter les cartes reellement prises en charge. Ne pas recopier les donnees de ZipNav dans le jeu : l'utilitaire doit conserver son arborescence autonome.

## Compatibilite des catalogues d'avions

La source active `Files/com/maddox/il2/objects/air.ini` contient 536 lignes d'avions et 535 identifiants uniques.

| Outil | Identifiants uniques | Presents dans la liste active | Manquants par rapport a la liste active | Ajouts officiels 4.09 presents |
| --- | ---: | ---: | ---: | ---: |
| Lowengrin DCG | 320 | 319 | 216 | 18/18 |
| Mission Mate | 322 | 312 | 223 | 0/18 |
| Quick Mission Tuner | 303 | 302 | 233 | 0/18 |

Ces nombres mesurent uniquement la correspondance des identifiants. Ils ne prouvent pas que les charges utiles, pays, annees, peintures, roles et comportements sont corrects.

## Dependances, securite et isolation

- Les 18 executables audites etaient 32 bits et non signes. Apres retrait d'IL2 Connect et des deux executables VoiceOverlay, 15 executables audites restent dans `_Utilities` et `_Game_Enhancements`. L'absence de signature ne prouve pas qu'ils sont malveillants, mais impose de conserver les originaux, enregistrer leurs empreintes et limiter leur acces aux dossiers necessaires.
- Les runtimes Visual Basic 6, .NET 3.5/4.x et Java 17 necessaires aux outils concernes sont presents sur la machine auditee.
- HardBall livre son propre runtime VB5 et d'anciennes DLL/OCX : ils doivent rester dans son dossier, sans installation systeme.
- Les editeurs de mission doivent toujours ecrire dans une copie ou un dossier de sortie, jamais directement sur l'unique original.
- IL2 Sticks et JoyCtrl doivent utiliser une sauvegarde transactionnelle et ne jamais etre actifs ensemble.
- DCG ne doit pas remplacer DGen/NGen avant qu'une restauration complete ait ete testee.
- Aucun utilitaire ne doit etre lance automatiquement par le selecteur tant que ses criteres d'acceptation ne sont pas remplis.

## Perimetre de cet audit

Cet audit v1.15 est strictement fonctionnel : presence, configuration, compatibilite 4.09m, demarrage et resultat observable. Les questions de publication ou de provenance peuvent etre suivies separement, mais elles ne constituent pas un critere fonctionnel de la v1.15.

## Plan de remise en service recommande

### Priorite 0 - Integration portable commune

- Ajouter un catalogue manuel des outils, pas un auto-lanceur.
- Faire choisir le dossier du jeu et valider la presence de `il2fb.exe`.
- Stocker les reglages propres a Open Sturmovik sans reutiliser les chemins historiques.
- Fournir sauvegarde, journal et restauration pour toute ecriture dans le jeu.

### Priorite 1 - Premier outil fonctionnel

- Integrer JoyCtrl seul.
- Valider les profils sur un joystick reel et la restauration de `conf.ini`.

### Priorite 2 - Generation de campagnes

- Configurer DCG en mode manuel.
- Synchroniser classes, charges et peintures avec les donnees actives.
- Jouer une campagne de validation avant tout mode DGen/NGen.

### Priorite 3 - Creation de missions

- Regenerer les donnees Mission Mate depuis `Files`.
- Valider une mission 4.09 stock et une mission Open Sturmovik.
- N'evaluer QMT qu'apres avoir mis ses listes au meme niveau.

### Priorite 4 - Navigation et outils optionnels

- Appliquer la jonction ZipNav `mods/mapmods` preparee par l'initialiseur.
- Effectuer le test A/B WeatherSet.
- Valider Bombsight en vol.

### Priorite 5 - Outils de consultation et de connexion

- Valider Bombsight Table 2 en vol et ses raccourcis globaux.
- Reconstruire ou etiqueter clairement les donnees HardBall408.
- Determiner le format de donnees IL2 Compare et regenerer son catalogue 4.09m/Open Sturmovik.
- Documenter la connexion IP native d'IL-2 1946 sans dependre d'IL2 Connect.

### Hors cible courante

Gapa, IL2 Sticks et Quick Mission Tuner restent historiques, redondants ou risques. IL2 Connect et VoiceOverlay ont ete supprimes du paquet ; le multijoueur IP natif d'IL-2 remplace le premier et un client vocal actuel remplace le second.

## Criteres pour declarer un outil fonctionnel

Un utilitaire ne doit passer au statut « fonctionnel » que si :

1. sa version, sa cible et ses fichiers d'entree sont identifies ;
2. il demarre sur une installation Windows de test propre ;
3. il utilise des chemins configurables et aucune ancienne machine ;
4. ses donnees couvrent la cible 4.09m et les classes Open Sturmovik qu'il doit manipuler ;
5. ses ecritures sont sauvegardees et restaurables ;
6. un scenario reel en jeu reussit ;
7. la fermeture normale et forcee ne laisse ni processus, ni affichage, ni fichier dans un etat degrade ;
8. son mode d'emploi et ses limites sont integres a la documentation du projet.

## Sources locales utilisees

- Ancien `_OS_Programs/*`, maintenant reparti entre `_Utilities/*` et `_Game_Enhancements/*` : aides, README, historiques, configurations et donnees livres avec les outils ; les sources IL2 Connect et VoiceOverlay ont ete lues avant leur suppression recuperable par Git.
- `_Documentations/Mods and Tools/HardBall Aircraft Viewer 4.08/Manuel - HardBall Aircraft Viewer 4.08.rtf`.
- `_Documentations/Mods and Tools/San FOV Changer 1.0/Manuel - San FOV Changer 1.0 - anglais.pdf`.
- `_Documentations/Mods and Tools/Zuti MDS 1.13/Manuel - Zuti MDS 1.13.pdf`.
- `_Documentations/Game and Patches/4.08m/Notes de version 4.08m - francais.rtf` et documentation locale du patch 4.09.
- Les anciens `.doc` de `_Documentations/Campaigns`, verifies comme documentations de campagnes/missions et non comme manuels des utilitaires.
- `Files/com/maddox/il2/objects/air.ini`, compare aux catalogues DCG, Mission Mate et QMT.
- `docs/VERSION_COMPATIBILITY.md` pour la cible 4.09m du depot.
