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
