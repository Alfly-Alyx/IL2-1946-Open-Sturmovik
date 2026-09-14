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

Le 8 septembre 2026, un lancement reel de la copie de test 4.09m moddee avec
6DOF a montre que le chargement utilisait `Files\background0.mat` et sa texture
relative `Files\background0.tga`. Le visuel russe de Forgotten Battles visible
pendant ce test correspondait au fichier de 3 145 772 octets, SHA-256
`6406F179278E47F9C8C00A39384784A02F8C7D9202370A371C483353EE9F1647`,
present a cet emplacement.

Cette observation corrige l'hypothese precedente : placer la texture sous
`Files\gui\Background.tga` ne remplace pas l'ecran de chargement de cette
configuration. Le switcher v1.15 ecrit desormais la variante choisie dans
`Files\background0.tga`, en conservant `Files\background0.mat` qui pointe vers
`background.tga`. L'ancien contenu russe est remplace et ne fait plus partie de
l'etat actif prepare.

Les cinq variantes valides (4:3, 16:10, 16:9, 21:9 et 32:9) conservent le
casque, le manuel et le cartouche complet 1C / Maddox Games. Le 8 septembre,
l'icone historique du switcher a ete integree en bas a droite du rendu, sans
deformation, avec une hauteur proportionnelle a celle du cartouche. Aucun
texte « Open Sturmovik » n'est encore integre : plusieurs
serigraphies et dispositions seront proposees seulement apres validation du
reste de la v1.15.

Le fond libre precedemment examine sous `Files\gui\Background.tga` avait les
caracteristiques suivantes :

- 1024 x 768 pixels ;
- 32 bits par pixel ;
- 3 145 772 octets ;
- SHA-256 `5FA9F7D94C75CD40DDE80EB6E419FD94744F2ADCABC0864D83D8A8A28B6D1561`.

`Files\gui\background0_ru.mat` pointe explicitement vers `background.tga` et
desactive sa degradation, mais ce couple n'a pas ete celui affiche au lancement
observe. L'image examinee n'etait pas Full HD ; elle semble etre une conversion
4:3 adaptee a l'interface historique du jeu. Les ressources
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

Le 10 septembre 2026, le sous-format `IMF\x1A10` des six fonds historiques a
ete decode de maniere reproductible. Les faits verifies sur ces fichiers sont :

- octets 0 a 5 : signature ASCII `IMF\x1A10` ;
- octets 6 et 7 : champ reserve observe a zero ;
- octets 8-9 et 10-11 : largeur et hauteur non signees 16 bits, little-endian ;
- les `hauteur` octets suivants indiquent un filtre, un par ligne ;
- le reste contient `largeur * hauteur * 3` octets de pixels filtres BGR ;
- les filtres 0 a 4 correspondent respectivement a aucun filtre, Sub, Up,
  Average et Paeth, avec une distance de trois octets pour le pixel precedent.

La reconstruction modulo 256, puis l'interpretation BGR 24 bits, redonne les
images 512 x 512 attendues sans lancer le jeu ni `ViewIMF`. Le resultat a ete
controle visuellement sur IL-2 2001, Forgotten Battles, Pacific Fighters
standalone, Pacific Fighters merged et IL-2 1946. Cette description concerne
les fonds `background0.tga` examines ; elle ne suffit pas encore a affirmer que
tous les conteneurs IMF du jeu utilisent exactement la meme structure.

## Variantes nettoyees pour le switcher

Le 10 septembre 2026, six variantes PNG ont ete derivees des fonds extraits et
placees directement sous `_Game Switcher\Resources`. Les sources officielles
sous `D:\Projets\GITHUB\#res\IL2 1946\background\RAW\Official Sources` n'ont
pas ete modifiees. Les variantes retirees comprennent le logo Ubisoft et la
ligne de copyright inferieure. Les titres Forgotten Battles, Pacific Fighters
et les cartouches de la compilation 1946 ont egalement ete retires. A la
demande d'Alexis, le grand logo vert `IL-2 STURMOVIK` des deux fonds au casque
est conserve, tout comme les cartouches 1C/Maddox.

Les premiers essais entierement regeneres en 1254 x 1254 ont ete rejetes car
ils redessinaient aussi les avions, leurs marquages et les cartouches de marque.
Ils n'ont pas ete conserves comme ressources finales. Les six PNG presents dans
le depot repartent des images originales decodees en 512 x 512. Un remplissage
genere n'est applique qu'a l'interieur de masques explicites couvrant les titres,
Ubisoft et les lignes inferieures. Un controle pixel par pixel confirme que
tous les pixels situes hors de ces masques sont identiques aux images extraites.
Ces fichiers restent des variantes retouchees et ne doivent pas etre presentes
comme des extractions binaires originales. Ils devront etre convertis vers le
format moteur seulement apres choix de la variante a integrer.

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

## Familles multiformat preparees les 8 et 9 septembre 2026

Le fond actif `Maddox` et les quatre compositions demandees par Alexis sont
declines dans les rapports `4x3`, `16x10`, `16x9`, `21x9` et `32x9`, avec une
definition maximale de 3840 x 2160. L'image n'est jamais etiree. Lorsque le
rapport de l'ecran differe de celui de la source, la composition complete reste
au centre et les zones laterales ou horizontales sont prolongees par une
extension assombrie et floutee. Le switcher choisit la famille la plus proche
a partir de la section `[window]` de `conf.ini`.

| Famille | Emplacement dans le depot | Nature |
| --- | --- | --- |
| Fond actif sans logo IL-2 | `_Game Switcher\Resources\Loading Backgrounds\Maddox` | casque, manuel et micro ; famille actuellement utilisee par le switcher |
| Forgotten Battles remasterise | `_Game Switcher\Resources\Loading Backgrounds\Forgotten Battles 2003 Remaster` | combat La-7 / Fw 190 sans titre Forgotten Battles |
| Casque + logo IL-2 rouge | `_Game Switcher\Resources\Loading Backgrounds\Helmet Red 2001` | variante au logo rouge conserve integralement dans chaque rapport |
| Boite IL-2 2001 | `_Game Switcher\Resources\Loading Backgrounds\IL-2 2001 Box Art` | composition hivernale inspiree du dessin de boite |
| Casque + logo IL-2 vert | `_Game Switcher\Resources\Loading Backgrounds\Helmet Green 2001` | variante au logo vert conserve integralement dans chaque rapport |

Chaque famille contient une copie `Source\Clean.png`, puis un
`Background.png`, un `Background.tga` et un `Preview.jpg` par rapport. Les
originaux fournis, avant retrait de leurs anciens cartouches, sont conserves
sous `Source\Original.png`. Les dimensions, empreintes et sources sont
inventoriees dans `_Game Switcher\Resources\Loading Backgrounds\manifest.json`.

Le seul cartouche Maddox Games applique a ces cinq familles est derive de
l'image du depot de marque `DEVELOPMENT GROUP MADDOX GAMES`, enregistree au
nom de 1C. Sa geometrie n'est pas regeneree : le traitement deterministe retire
le fond blanc et applique une couleur or sur une plaque noire. La source
Internet intacte est conservee sous
`_Game Switcher\Resources\Loading Backgrounds\Shared\Sources\Maddox-Games-trademark-RBC-original.jpg`
et le master commun sous
`_Game Switcher\Resources\Loading Backgrounds\Shared\Maddox-Games-Official-Gold.png`.
La fiche du registre est :
https://companies.rbc.ru/trademark/235490/development-group-maddox-games/.

Les remasterisations Pacific Fighters restent des candidats separes :

| Candidat | Emplacement dans le depot | Nature |
| --- | --- | --- |
| Pacific Fighters — PF-splash1 | `_Game Switcher\Resources\Loading Backgrounds\Pacific Fighters 2004 Remaster\PF-splash1\16x10` | reconstruction detaillee 16:10 de la composition historique ; les deux marquages numeriques `05` ont ete verifies et corriges |
| Pacific Fighters — PF-splash4 | `_Game Switcher\Resources\Loading Backgrounds\Pacific Fighters 2004 Remaster\PF-splash4\16x10` | remasterisation 16:10 reconstruite en haute definition, et non simple agrandissement |
| Pacific Fighters — PF-splash5 | `_Game Switcher\Resources\Loading Backgrounds\Pacific Fighters 2004 Remaster\PF-splash5\16x10` | remasterisation 16:10 reconstruite en haute definition, et non simple agrandissement |
| Pacific Fighters — montage rejete | `_Game Switcher\Resources\Loading Backgrounds\Pacific Fighters 2004 Remaster\16x10` | candidat rejete : le fond fusionne FB+AEP+PF a plusieurs avions ne correspond pas au fond recherche |

Les trois illustrations destinees au fond de l'interface du switcher, et non
au chargement du jeu, sont rangees separement sous
`_Game Switcher\Resources\Backgrounds`. Alexis a retenu la remasterisation de
la jaquette `Pacific Fighters Retail` comme fond actif du switcher. Elle est
conservee sous
`Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.png`. La variante
de combat est conservee sous
`Open_Sturmovik_Switcher_Alternate__Corsair_vs_Zero.png`.

## Fond de la selection des missions retenu le 11 septembre 2026

Alexis a retenu l'illustration du SBD Dauntless pour le fond de la selection
des missions. La source de travail est conservee dans le depot sous
`_Game Switcher\Resources\Backgrounds\Open_Sturmovik_Missions_Background__SBD_Dauntless.png`
(1586 x 992 pixels, SHA-256
`6C6E2C38A135D8D19505579251EFF0BD96FFBFB5E5AE4E98B5E05722A6FFC6A8`).

La texture active est `Missions\Background.tga`. Le fichier reste conforme au
format deja utilise a cet emplacement : TGA standard non compresse, type 2,
968 x 608 pixels, BGRA 32 bits, origine inferieure gauche et pied TGA 2.0. Le
passage au rapport 968:608 emploie un recadrage centre de 3,316 pixels sur
chaque bord lateral avant reduction bicubique ; l'image n'est pas deformee.
L'empreinte SHA-256 du fichier integre est
`88C63E7A103AEA84076E710500255F21D5536B3ECAEB40149615E40A83A2B3B8`.
Le materiau `Missions\background.mat` reste inchange et continue de pointer
vers `background.tga`.

Les termes `Remaster` et `adaptation` sont volontaires : ces fichiers respectent
les compositions historiques mais ne sont pas des copies binaires des textures
d'origine. Les references 4:3 restees intactes sont conservees sous
`WIP\analyses\fonds-chargement\loading-candidates\sources`. La page historique
[Forgotten Battles](https://aiss.stars.ne.jp/il2fb/index.html) identifie les
trois ecrans d'origine et la page
[Pacific Fighters](https://aiss.stars.ne.jp/pf/index.html) distingue le titre
autonome du titre fusionne FB+AEP+PF. La couverture 2001 provient de la
[reference MobyGames](https://www.mobygames.com/game/5410/il-2-sturmovik/cover/group-2482/cover-9646/).

Aucun marquage `Open Sturmovik` n'a ete ajoute. Les propositions de serigraphie
et de disposition seront produites apres validation du fond retenu, comme
demande par Alexis.

## Remplacement du fond localise dans les neuf profils

Le 11 septembre 2026, Alexis a precise que le probleme de fond concernait les
neuf profils. Six archives `files.SFS` distinctes alimentent ces profils : une
archive stock et une archive mods pour chacune des versions 4.08, 4.09b et
4.09m ; les variantes mods avec et sans 6DOF partagent la meme archive. Les
faits verifies sont les suivants :

- les six archives sont des SFS v202 ;
- `gui\background.tga` contient deja le fond officiel IL-2 Sturmovik 1946,
  786 956 octets, SHA-256
  `831B136385DBC87651DA610B5F3BE12E1833B3CCEB3E78707F6ADAD82DF5D18F` ;
- `gui\background0.tga`, empreinte SFS `287C53E300FD73AD`, contient quatre
  variantes historiques selon l'archive : `A4159D8D...E8925` dans les stocks
  4.08/4.09b, `B39734DC...B5EE` dans les mods 4.08/4.09b,
  `CD2C6320...181FC` dans le stock 4.09m et `AC3314AC...6AA0B` dans les mods
  4.09m ;
- `gui\background.mat` pointe vers `background.tga`, tandis que les materiaux
  `gui\background0_cs.mat`, `gui\background0_de.mat`,
  `gui\background0_fr.mat` et `gui\background0_ru.mat` pointent vers
  `background0.tga` ;
- l'entree `gui\background0.tga` occupe seule sa plage de donnees. Son dernier
  entier de TOC correspond a la somme non signee de ses octets sur 32 bits.

La source officielle utilisee est conservee sous
`D:\Projets\GITHUB\#res\IL2 1946\background\Official In Games Backgrounds\Originaux\IL-2 Sturmovik 1946 (2006)\gui\background.tga`.
Elle commence par la signature `IMF\x1A10` et mesure 512 x 512 pixels apres
decodage.

La reconstruction reproductible est implementee dans
`tools\Repack-SfsEntry.py`. L'outil conserve l'ordre de la TOC, remplace une
seule plage, recalcule la taille et la somme de l'entree, decale les offsets
posterieurs, reconstruit les blocs DEFLATE de 32 768 octets, puis rechiffre les
metadonnees. Il rouvre enfin le resultat et compare toutes les entrees a la
source. Exemple :

```powershell
python tools\Repack-SfsEntry.py `
  "_Game Switcher\4.09m Mods ON 6DOF\files.SFS" `
  "C:\chemin-temporaire\files.SFS" `
  --path "gui\background0.tga" `
  --replacement "D:\Projets\GITHUB\#res\IL2 1946\background\Official In Games Backgrounds\Originaux\IL-2 Sturmovik 1946 (2006)\gui\background.tga"
```

La methode a d'abord ete controlee sans remplacement sur le `TestIniA.SFS`
v201 livre avec SFS Manager 4.1 : en-tete, TOC, contenu de chaque entree et flux
decompresse sont restes identiques. Chaque archive reconstruite a ensuite ete
rouverte et comparee integralement a sa source. Seule `gui\background0.tga`
change ; toutes les autres entrees et leurs metadonnees fonctionnelles restent
identiques.

| Profils | Entrees | Taille reconstruite | SHA-256 reconstruit |
| --- | ---: | ---: | --- |
| `4.08 stock` | 10 075 | 22 237 821 | `42342CE1089C42B4FBB61F6CFC3850F3AC27FAFE6F4192CD7C6CF042E056F7EC` |
| `4.08 mods NO 6DOF`, `4.08 mods 6DOF` | 9 971 | 21 232 146 | `E00F86B80183313B846F72F153A9102A1DC40AFBB90323DE8AC7DE34DED0D5FD` |
| `4.09b stock` | 10 075 | 22 235 571 | `08682F88511336D083A068A2D3DE81BC02F2AE8A27DF61666FC91F3DFF95BCC2` |
| `4.09b mods NO 6DOF`, `4.09b mods 6DOF` | 9 971 | 21 236 211 | `53B97E4993C17DECDEEC6E4E46E70F42ED01A625AE9AEB274A14327C399F890E` |
| `4.09m stock` | 10 543 | 23 998 523 | `FCFCE245EC23FF314C6CD86E9A51D563D091CFF74DDD0B46B704B670C0340C6A` |
| `4.09m mods NO 6DOF`, `4.09m mods 6DOF` | 10 441 | 23 010 398 | `5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71` |

Fait valide en execution : Alexis a confirme que l'image officielle IL-2 1946
s'affiche au demarrage du profil `4.09m mods 6DOF` avec l'archive reconstruite.
La structure et le contenu des cinq autres archives distinctes ont ete verifies
statiquement ; elles utilisent le meme format SFS v202 et la meme entree cible.
Le fond de selection des missions reste la texture SBD Dauntless distincte sous
`Missions\Background.tga`.

Les informations communautaires recoupees sont la description des materiaux de
splash sur [SAS 1946](https://www.sas1946.com/main/index.php?topic=37662.0) et
la publication de [SFS Manager 4.1](https://www.sas1946.com/main/index.php?topic=63325.12).
Les recherches dans les archives AAA/All Aircraft Arcade et sur Mission4Today
n'ont pas fourni d'instruction de reconstruction exploitable pour ce cas
precis. La description binaire est confirmee pour les archives v201 et v202
testees ; sa generalisation aux autres revisions SFS reste une hypothese.


## Fond actif du sélecteur — optimisation du 13 septembre 2026

La source PNG Pacific Fighters Retail 1586 × 992 est conservée. Le rendu actif utilise `Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.jpg`, encodé en JPEG qualité 92 : 627 063 octets au lieu de 4 634 420. Cette copie vise uniquement le temps d’ouverture du HTA ; le cadrage et les dimensions restent identiques.

## Application par profil dans le switcheur

Le défaut observé en septembre 2026 venait du fait que la transaction changeait
Files/gui/Background.tga pour le menu moddé, mais ne changeait ni
Missions/Background.tga ni samples/Music/Menu. Les trois modes stock pouvaient
donc conserver le fond et la musique Open Sturmovik précédemment actifs.

Les neuf dossiers sous _Game Switcher possèdent maintenant une arborescence
Profiles/Missions et Profiles/samples/Music/Menu. Les profils 4.08m, 4.09b et
4.09m stock utilisent le fond officiel commun de 786 476 octets et 13 pistes
stock. Les six profils Open Sturmovik utilisent le fond de 2 354 220 octets et
les 14 pistes du pack. Le fichier stock Cz.wav est un repli byte-identique à la
piste officielle de.wav, car les ressources stock analysées ne livrent pas de
piste tchèque dédiée.

Le BAT sauvegarde le fond actif et l’union des noms de pistes, supprime les
anciennes pistes, copie le jeu exact du profil et sait restaurer chaque présence
ou absence si la validation finale échoue. Le rapport
profile-presentation-resources-v1.15.json donne les empreintes de chaque copie.
