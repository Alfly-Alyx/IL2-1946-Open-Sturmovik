# Audit des musiques nationales et des fonds d'ecran

## Musiques retrouvees

L'add-on contient deja quatorze pistes distinctes dans
`samples\Music\Menu`. Leur nom reprend le code interne de la nation utilise par
IL-2 et par `PaintSchemes\regiments.ini` :

| Fichier | Nation interne |
| --- | --- |
| `Cz.wav` | Tchecoslovaquie (`cz`) |
| `de.wav` | Allemagne |
| `du.wav` | Hollande |
| `fr.wav` | France |
| `gb.wav` | RAF |
| `hu.wav` | Hongrie |
| `it.wav` | Italie |
| `ja.wav` | aviation de l'armee japonaise |
| `pl.wav` | Pologne |
| `ro.wav` | Roumanie |
| `ru.wav` | URSS |
| `sk.wav` | Slovaquie |
| `Um.wav` | US Marine Corps (`um`) |
| `us.wav` | USAAF |

Les empreintes SHA-256 des quatorze fichiers sont differentes : il s'agit bien
de pistes propres, pas de copies renommees. La casse irreguliere de `Cz.wav` et
`Um.wav` fonctionne sur Windows, mais le manifeste du futur lanceur devra
normaliser les codes en minuscules pour rester deterministe.

`Files\i18n\country.properties` declare beaucoup plus de nations que les
quatorze musiques disponibles. Le lanceur devra donc afficher la couverture
reelle, permettre une association explicite et utiliser une piste generique ou
une nation parente en repli. Il faudra encore confirmer par capture quand le
moteur choisit la musique : pays selectionne, branche d'aviation, camp ou profil
du pilote.

## Fond d'ecran actif

Le fond libre actuellement charge par l'add-on est
`Files\gui\Background.tga`. Son en-tete donne les caracteristiques suivantes :

- 1024 x 768 pixels ;
- 32 bits par pixel ;
- 3 145 772 octets ;
- SHA-256 `5FA9F7D94C75CD40DDE80EB6E419FD94744F2ADCABC0864D83D8A8A28B6D1561`.

`Files\gui\background0_ru.mat` pointe explicitement vers `background.tga` et
desactive sa degradation. L'image active n'est donc pas Full HD ; elle semble
etre une conversion 4:3 adaptee a l'interface historique du jeu. Les ressources
nommees `Fond ecran installeur` sont differentes : `1.bmp` et `1.jpg` mesurent
1600 x 740 et servent a l'installateur, tandis que la jaquette Ubisoft mesure
3335 x 2214.

## Fond de chargement du premier IL-2 Sturmovik (2001)

Extraction du 8 septembre 2026, sans installation ni lancement de la demo.
La source telechargee est la demo officielle 1.0 de 2001 publiee par Maddox
Games et conservee par
[Mission4Today](https://www.mission4today.com/index.php?file=details&id=3564&name=downloads).
Elle n'est pas le jeu commercial complet.

`demo.SFS` est une archive SFS v201 de 90 276 662 octets, contenant 14 670
entrees et le commentaire `Copyright (c) 1997-2001 Maddox Games Ltd.`. Le chemin
historique `gui/background0.tga` a ete extrait avec `tools/Analyze-Sfs.py`.
Il s'agit d'un TGA standard RGB 24 bits de 512 x 512 pixels, 786 476 octets,
SHA-256
`1E9CFDC8DC39C475FD736ABEE5EDCAFCE5AC24558BC241B5E0F27405DFFCE8F6`.
Le fichier `gui/background0.mat` de la meme archive pointe directement vers
ce nom et porte le SHA-256
`776C9605A9432485B6E67D0F0A69684615362C59F6B6E969CE040F011BB821BC`.

Copies de reference conservees hors du jeu actif :

- `D:\Projets\GITHUB\#res\IL2 1946\background\RAW\OFFICIEL-2001-DEMO__gui__background0.tga` : octets originaux ;
- `D:\Projets\GITHUB\#res\IL2 1946\background\RAW\OFFICIEL-2001-DEMO__gui__background0.png` : simple apercu PNG, sans retouche.

Le visuel correspond au casque, aux lunettes, au manuel et au logo visibles
sur la
[capture de la version Windows commerciale de 2001](https://www.mobygames.com/game/5410/il-2-sturmovik/screenshots/windows/21202/).
Cette correspondance visuelle etablit l'identite du dessin avec une confiance
elevee, mais ne prouve pas encore que les octets de la demo et du jeu complet
sont identiques. Une extraction du SFS commercial de 2001 reste necessaire
pour certifier cette identite binaire.

### Extension `.tga` et conteneur IMF d'IL-2

L'extension ne suffit pas a identifier le format reel. Les deux atlas d'interface
examines le 31 aout 2026, `Files\gui\GAME\basicelements.tga` et
`Files\gui\GAME\staticelements.tga`, ne commencent pas par un en-tete TGA
standard : leurs premiers octets sont `49 4D 46 1A 31 30`, soit la signature
`IMF` suivie de la variante `10` du conteneur d'image proprietaire d'IL-2. Un
visualiseur TGA ordinaire les refuse donc, meme si leur nom se termine par
`.tga`.

Il ne faut ni les renommer en `.imf`, ni les convertir a l'aveugle : les fichiers
`.mat` du moteur les referencent par leur nom historique et peuvent dependre de
leur format, de leur palette et de leur canal alpha. L'inspection ou une future
conversion reproductible doit passer par un outil compatible IMF, tel que
`ViewIMF`, en conservant l'original et son empreinte. Cette observation est
particulierement importante pour les atlas GUI susceptibles de contenir des
sprites ou masques, dont le curseur. Elle ne prouve toutefois pas, a elle seule,
que l'atlas est la cause d'un curseur invisible.

## Regle pour le futur lanceur

Les captures communautaires originales seront conservees dans leur resolution
source lorsque leur auteur et leur droit de redistribution sont connus. Une
etape reproductible produira ensuite la texture compatible avec l'interface du
jeu, sans ecraser la source. Le lanceur pourra selectionner ou faire tourner les
fonds valides, mais n'enverra au moteur que le format, le ratio et la taille
confirmes par les essais.

La selection de musique et de fond reste independante de la reglette graphique :
changer la qualite du rendu ne doit ni remplacer une piste nationale ni perdre
le choix visuel du joueur.
