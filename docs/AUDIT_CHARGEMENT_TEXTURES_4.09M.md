# Audit du chargement des textures IL-2 4.09m

Derniere mise a jour : 11 septembre 2026.

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

La mission ne doit pas etre changee entre les passes. Les essais AOC, moteur,
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


## Limite du tampon natif de texture — 11 septembre 2026

Cette découverte est conservée pour la rétro-ingénierie du moteur existant et une éventuelle réimplémentation compatible. Elle provient du premier essai réel de rotation des fonds ; ce n'est pas une estimation tirée de la taille d'un fichier compressé.

**R — fait observé, confiance élevée.** Open Sturmovik v1.15, profil 8 (4.09m moddé sans 6DOF), cœur officiel, DirectX via `dx8Wrap.dll`, fenêtre 1024 × 768. Le 11 septembre à 18:18:31 UTC, `Mat.New("gui/backgrounds/forgotten-battles-box.mat")` provoque :

```text
INTERNAL ERROR: Texture Buffer (limit 4202496 Bytes)is to small to fit 4719936 Bytes!
```

Le moteur refuse ensuite la texture RGB24 non compressée 1586 × 992 puis son matériau. **4 719 936 = 1586 × 992 × 3** : la demande correspond aux pixels RGB décodés. La limite rapportée est **4 202 496 octets**, soit **4,202496 Mo décimaux** (environ 4,0078125 Mio). La carte graphique annonce pourtant une dimension maximale de 8192 pixels ; cette capacité du pilote ne prouve donc pas que le chargeur du moteur accepte des images de cette dimension.

Le journal brut est versionné dans [`test-assets/loading-rotation/native-first-launch.log`](../test-assets/loading-rotation/native-first-launch.log), SHA-256 `E1546123324F15E3BB9C7B95D7AE31B769A0280E46287C9A8B39F4812299DAE8`. Le manifeste [`texture-buffer-limit-409m.json`](../manifests/engine/texture-buffer-limit-409m.json) conserve le contexte et les empreintes exactes des binaires de cet essai.

**S — localisation statique, confiance élevée.** La chaîne formatée `Texture Buffer (limit %i Bytes)is to small to fit %i Bytes!` apparaît aux offsets **de fichier** suivants (ce ne sont pas des adresses mémoire ni les adresses d'allocation du tampon) :

| Binaire 4.09m | Offset de la chaîne | SHA-256 |
| --- | --- | --- |
| `il2_core.dll` | `0x1253E0` | `3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3` |
| `il2_corep4.dll` | `0x1393E8` | `0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979` |

Reproduction sans lancer le jeu : rechercher cette chaîne ASCII dans les deux DLL identifiées et comparer leurs empreintes. Reproduction runtime historique : profil 8, rotation activée, TGA RGB24 de 1586 × 992, lancement direct de `il2fb.exe`, lecture de l'erreur de tampon dans `log.lst`. La réduction ultérieure des copies corrige ce jeu de données ; les PNG source et les empreintes des anciens TGA restent conservés.

**Décision du paquet, distincte du fait moteur.** À la demande d'Alexis, les quatre TGA de rotation sont limités à **4 200 000 octets, en-tête compris**. Le générateur produit **1495 × 935 RGB24**, soit **4 193 475 octets de pixels + 18 octets d'en-tête = 4 193 493 octets** par fichier. La marge face au tampon observé est de 9 021 octets pour les pixels. Les PNG originaux restent intacts. Ce plafond du paquet est un choix conservateur ; il ne modifie aucune DLL du cœur.

**I / U — limites de la conclusion.** La structure du tampon et son site d'allocation restent inconnus. La présence de la chaîne dans les deux DLL ne prouve pas que chaque variante a été exécutée pendant l'essai. L'acceptation à la frontière exacte, les autres profils, les formats IMF/DDS/RLE et les dimensions 1495 × 935 restent à qualifier dans le moteur. Réduire la taille compressée sur disque ne prouve pas qu'on réduit le besoin de mémoire après décodage. Aucune modification HD du cœur n'a été intégrée.

### Essai des copies réduites — 11 septembre 2026, 19:52:59 UTC

**R — matériau accepté, affichage non encore confirmé visuellement.** Le lancement direct suivant de la copie isolée (profil 8, PID 9312) a créé à 19:53:22 UTC un nouvel état de rotation avec `last=il2-2001-box`, `position=1`. Aucun état précédent n'existait. Le helper actif, SHA-256 `F057D53D3E7B9DCF865AB3ADEA2395DAB3BB8875634C9AFE6632AC2243E6C571`, n'écrit cet état qu'après un retour non nul de `Mat.New` : le matériau de la TGA **1495 × 935 RGB24**, **4 193 475 octets de pixels**, a donc passé ce préchargement natif. Ce constat valide l'acceptation de ce matériau dans ce profil ; il ne prouve ni le cadrage ni l'affichage à l'écran des quatre variantes.

Preuves : `WIP/loading-rotation-launches/20260911-195259Z/launch.json`, `state-after.properties` et `material-acceptance.json`. Le fichier `log.lst` n'avait pas encore publié la nouvelle session lors de l'observation de l'état : l'ancien journal ne sert pas à déclarer ce lancement exempt d'erreurs. Le jeu reste ouvert pour l'essai demandé par Alexis.

### Confirmation visuelle du relancement

Le second lancement direct demandé le 11 septembre à 19:56:58 UTC a accepté un autre matériau réduit, `background-3`, puis avancé la position de 1 à 2 sans changer la signature du cycle. Alexis a confirmé « le changement fonctionne parfaitement ». L'acceptation de deux matériaux 1495 × 935 successifs et le changement visible sont donc confirmés pour ce profil. Rapport versionnable : [`loading-rotation-runtime-validation.json`](../manifests/loading-rotation-runtime-validation.json). Le comportement à la limite exacte de 4 202 496 octets et la compatibilité de tous les formats/profils restent inconnus.
