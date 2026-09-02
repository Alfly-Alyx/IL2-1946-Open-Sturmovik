# Audit du chargement des textures IL-2 4.09m

Derniere mise a jour : 2 septembre 2026.

## Conclusion courte

Le premier chargement d'une mission est ralenti principalement par la lecture,
la conversion et l'envoi des textures vers OpenGL sur le fil principal. Les
captures existantes montrent environ 26 secondes au premier chargement contre
6 secondes au second. Une pile native place le jeu dans
`opengl32!glTexImage2D`, appele sous
`il2_corep4!BmpUtils_BMP8PalTo4TGA4`.

Le wrapper historique ajoute aussi un cout d'enumeration des fichiers libres,
mais son cache experimental ne gagne que 1,42 seconde dans le banc isole. Il ne
peut donc pas expliquer a lui seul les 20 secondes recuperees par le chargement
chaud.

La priorite est de mesurer les textures converties ou envoyees plusieurs fois,
puis de mettre en cache seulement les conversions prouvees redondantes. Aucun
abaissement de qualite, changement de tas Java, repaquetage SFS ou nettoyage de
`.preload` ne doit etre applique avant cette trace.

## Chemin de chargement etabli

Dans le profil Open Sturmovik 4.09m, le chemin utile est :

1. le wrapper recherche les surcharges dans `MODS`, puis `Files`, avant le repli
   vers les archives SFS ;
2. le moteur ouvre les textures et materiaux demandes par la carte, les objets,
   l'appareil et le cockpit ;
3. les bitmaps palettises sont convertis par les fonctions `BmpUtils` du moteur
   natif ;
4. OpenGL cree ou remplace la texture avec `glTexImage2D` ;
5. les ressources encore vivantes rendent les chargements suivants beaucoup
   plus rapides.

Les etapes 3 et 4 sont synchrones dans les preuves actuelles : le fil principal
attend le pilote graphique pendant la conversion et l'envoi. Cela explique
mieux les pauses visibles que la seule recherche d'un nom de fichier.

## Mesures deja disponibles

| Mesure | Resultat | Interpretation |
| --- | ---: | --- |
| Enumeration froide de 89 738 fichiers par le wrapper | 1 890,2 ms | Cout reel au demarrage |
| Validation et lecture du cache experimental | 473,4 ms | Gain isole de 1 416,8 ms |
| Premier chargement de la mission B-29 de reference | environ 26 s | Lecture, conversion et envoi a froid |
| Second chargement immediat de la meme mission | environ 6 s | Benefice cumule des caches |
| Rechargements de cockpit B-29 uniquement au premier passage | 8 | Candidats a tracer et dedupliquer |

Les journaux citent aussi plusieurs chargements de `skin1o.tga` et
`256-1.tga`. Leur repetition textuelle ne suffit pas encore a prouver huit
decodages complets : il faut la correler aux ouvertures de fichiers et aux appels
OpenGL.

## Configuration graphique actuelle

Le jeu de test utilise notamment :

| Cle `[Render_OpenGL]` | Valeur | Decision actuelle |
| --- | ---: | --- |
| `TexQual` | 3 | conserver pendant les comparaisons |
| `TexMipFilter` | 2 | conserver le filtrage trilinaire |
| `TexCompress` | 2 | conserver la compression S3TC |
| `TexLarge` | 1 | conserver les grandes textures |
| `TexLandQual` | 3 | conserver |
| `TexLandLarge` | 1 | conserver |
| `HardwareShaders` | 0 | profil Excellent compatible, ne pas melanger au test |
| `TypeClouds` | 0 | nuages ameliores isoles pour les essais en cours |

La compression est deja activee. La desactiver augmenterait les transferts et la
pression sur l'espace virtuel du processus 32 bits. Reduire `TexQual` ferait
probablement gagner du temps, mais au prix d'une degradation visuelle ; ce n'est
pas l'objectif de l'optimisation Open Sturmovik.

## Limites de la capture du 2 septembre

La capture Zuti/AOC du 2 septembre a ete lancee sans trace de fichiers et la
trace de performances Windows n'a pas pu etre armee. Elle confirme la stabilite
et la memoire du jeu, mais elle ne permet pas d'attribuer chaque pause a une
texture precise. Ses 13 718 images ne remplacent pas une trace d'acces.

Il ne faut donc tirer aucune conclusion sur une texture individuelle a partir de
cette seule session.

## Plan d'amelioration priorise

### 1. Mesure A/B du cache de wrapper

Executer la meme mission et le meme profil avec le wrapper historique, puis le
wrapper cache experimental. Les choix 11/12 du switcher activent le cache ; les
choix 8/9 restaurent le wrapper historique. Chaque passe doit conserver le meme
`conf.ini`, les memes mods et la meme mission.

But : verifier si le gain isole d'environ 1,4 seconde existe aussi dans IL-2.
Ce cache accelere la resolution des fichiers libres ; il ne constitue pas encore
un cache de textures converties.

### 2. Trace du premier et du second chargement

Utiliser `tools/Start-IL2FlightBugCapture.ps1 -WithFileTrace` ou
`tools/Start-OpenSturmovikProfile9Capture.ps1 -WithFileTrace`, avec une limite de
trace explicite. Pour chaque configuration :

1. mesurer un premier chargement apres redemarrage du jeu ;
2. revenir au menu ;
3. recharger immediatement la meme mission ;
4. fermer normalement et archiver la capture ;
5. compter les ouvertures par texture, les octets lus, les erreurs et la memoire
   maximale.

La mission ne doit pas etre changee entre les passes. Les essais AOC, Zuti,
nuages et textures ne doivent pas partager une meme comparaison si une seule
variable n'est pas maintenue.

### 3. Identifier les conversions redondantes

La prochaine instrumentation native doit relever autour de `BmpUtils` et
`glTexImage2D` :

- nom logique de la texture ;
- dimensions, format et niveau de mipmap ;
- identifiant ou adresse de texture OpenGL ;
- duree de conversion et d'envoi ;
- nombre d'appels identiques dans une meme mission.

Le premier candidat est une texture dont le meme contenu, les memes dimensions
et les memes drapeaux sont convertis plusieurs fois. Une simple repetition de
nom avec des drapeaux differents n'est pas necessairement un doublon.

### 4. Mettre en cache au niveau le moins risque

Ordre recommande :

1. conserver le cache de noms du wrapper s'il passe le test runtime ;
2. supprimer les references de materiaux strictement dupliquees dans un contenu
   Open Sturmovik controle ;
3. experimenter un cache de conversion indexe par empreinte du fichier, format,
   dimensions et drapeaux ;
4. envisager une conversion hors ligne seulement si le moteur accepte le format
   sans changement de nom ni perte visuelle.

Le cache doit etre invalide des qu'une texture, un materiau ou un parametre de
conversion change. Il doit rester supprimable et ne jamais alterer les sources.

### 5. Examiner `.preload` en dernier

Le fichier `.preload` contient 417 directives, dont 412 uniques. L'ajout d'une
texture peut deplacer une pause vers le demarrage sans reduire le temps total ;
la suppression peut introduire une saccade en vol. Toute modification exige une
trace montrant a quel moment la ressource est reellement demandee.

## Criteres de validation

Une optimisation de texture n'est acceptee que si :

- le premier chargement median baisse d'au moins 15 % ou de 3 secondes sur la
  mission de reference ;
- le second chargement ne regresse pas de plus de 5 % ;
- aucune texture noire, blanche, floue, absente ou corrompue n'apparait dans les
  captures interieur/exterieur ;
- aucune nouvelle erreur de materiau, texture, OpenGL ou fichier absent
  n'apparait dans les journaux ;
- le pic de memoire privee n'augmente pas de plus de 10 % ;
- trois passages successifs produisent le meme resultat fonctionnel ;
- le cache s'invalide apres modification d'une texture et le wrapper historique
  peut etre restaure sans laisser de fichier actif.

Pour le cache de wrapper seul, un gain reproductible d'au moins une seconde au
demarrage suffit, sous reserve de zero regression fonctionnelle.

## Actions explicitement ecartees pour le moment

- ne pas augmenter `-Xmx1G` : le jeu 32 bits doit conserver de l'espace virtuel
  pour OpenGL, les textures et les allocations natives ;
- ne pas desactiver `TexCompress=2` ;
- ne pas reduire `TexQual` pour masquer un probleme de conversion ;
- ne pas repaqueter massivement les textures dans des SFS ;
- ne pas supprimer des entrees `.preload` sans trace ;
- ne pas remplacer toutes les TGA par un autre format sans matrice de
  compatibilite materiaux/mipmaps/transparence.

## Verdict actuel

Le chargement des textures est **fonctionnel mais insuffisamment optimise au
premier passage**. Le cache de wrapper est pret pour un A/B de laboratoire. La
seule optimisation a conserver sans nouvel essai est la configuration actuelle
avec compression S3TC et mipmaps trilineaires. L'amelioration principale reste a
implementer apres identification des conversions redondantes.
