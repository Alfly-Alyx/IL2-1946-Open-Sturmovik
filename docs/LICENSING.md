# Licence et périmètre des droits d'Open Sturmovik

Décision d'Alfly du 12 septembre 2026 : permettre le téléchargement,
l'utilisation, la modification, la diffusion sur Internet, le partage et
les forks non commerciaux, et interdire tout usage commercial des
contributions couvertes.

Le texte applicable aux contributions originales d'Alfly est
[LICENSE.md](../LICENSE.md), version 1.0. Le présent document explique son
périmètre ; il ne concède pas de droits supplémentaires sur les composants tiers.

## Nature du projet

Open Sturmovik est un projet personnel d'Alfly de regroupement et de
compilation de mods, avec un travail d'intégration et de compatibilité entre
eux. Il repose sur le travail de la communauté et vise à proposer à cette
communauté et à tout joueur une version enrichie d'IL-2 Sturmovik 1946,
facile à installer et à utiliser. L'expérience recherchée est celle du jeu
de base avec les améliorations déjà intégrées, sur une installation
existante du jeu.

Créé en 2006 comme un pack destiné à une escadrille virtuelle, Open Sturmovik
a souffert de nombreux bugs liés aux incompatibilités entre mods. Le travail
actuel vise à résoudre ces problèmes pour proposer un Open Sturmovik aussi
fiable et utilisable que possible.

Le nom « Open Sturmovik » est associé à ce projet depuis sa création en 2006.
Il identifie ce projet original. La licence permet les forks clairement
identifiés comme dérivés ; Alfly demande aux projets distincts d'adopter
un autre nom pour éviter toute confusion.
La mention de l'origine Open Sturmovik dans les descriptions et les crédits
reste permise et les attributions requises doivent être conservées.

La v1.15 est destinée à être distribuée comme une réinstallation complète
du pack sur une base IL-2 compatible, sans dépendre d'Open Sturmovik v1.10.

Le mérite de la réalisation du jeu, des mods et de leurs améliorations
revient à leurs auteurs respectifs. Le rôle d'Alfly est de les réunir,
de travailler à leur compatibilité et de faciliter leur installation et
leur utilisation. Les crédits conservent l'attribution du travail communautaire.

## Ce que cette licence couvre

Elle couvre les contributions originales d'Alfly pour Open Sturmovik, dans
la mesure des droits qu'il détient, notamment la logique propre aux outils,
au switcher et à l'installateur, ainsi que la documentation originale.
Elle comprend ses apports originaux à la sélection, à l'organisation,
à la compilation, à l'intégration et à la compatibilité du pack, dans la
mesure où ces apports sont protégés et où il en détient les droits.
Elle n'est pas une déclaration de propriété de tous les fichiers d'un dossier.

Le regroupement de créations communautaires ne transfère pas les droits
de leurs auteurs à Alfly. Pour les recueils, le droit français prévoit
une protection lorsque le choix ou la disposition constitue une création
intellectuelle ; la licence ne présume pas que toute opération technique
remplit cette condition. Voir l'[article L112-3 du Code de la propriété
intellectuelle](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006278879/),
consulté le 12 septembre 2026.

Les permissions comprennent la copie de sources et de binaires, les modifications,
les forks publics, les miroirs et la redistribution gratuite non commerciale,
sans accord individuel préalable. Le maintien des mentions d'auteur et de
licence est requis. Le code des modifications peut être publié, sans obligation
supplémentaire de le publier imposée par cette licence.

Toute exploitation commerciale de ces contributions est interdite, y compris
dans les forks et les versions modifiées. La licence ne prévoit pas
d'exception sur autorisation écrite. Un tiers qui partage ou modifie ces
contributions ne peut pas accorder de droits commerciaux sur elles.

## Éléments conservant leurs propres conditions

| Élément | Traitement |
| --- | --- |
| Jeu IL-2, exécutables, DLL, SFS et patchs officiels | Les droits des ayants droit du jeu restent applicables. Leur présence dans le dépôt ou l'installateur ne les place pas sous la licence d'Alfly. |
| Mods, cartes, avions, campagnes, textures, sons, illustrations et programmes tiers | Les conditions de chaque auteur restent applicables, y compris quand des fichiers ont été déplacés, renommés, adaptés ou intégrés à un pack. |
| Classes reconstruites, décompilées, corrigées ou fusionnées à partir d'IL-2 ou de mods tiers | La reconstruction et la modification ne font pas disparaître les droits attachés aux éléments d'origine. Cette licence ne requalifie pas ces fichiers entiers comme créations originales d'Alfly. |
| `tools/Analyze-Sfs.py` | L'en-tête identifie les algorithmes dérivés d'OpenIL2 sous BSD-2-Clause-Patent. La notice correspondante est conservée dans `THIRD_PARTY_NOTICES.md`. La restriction commerciale d'Alfly ne remplace pas ces permissions. |
| `native/wrapper-cache-409m` | La licence propre au wrapper SAS reste celle de son `LICENSE.txt`, y compris pour l'adaptation conservée dans ce dossier. |
| Images et ressources visuelles du pack, du switcher et de l'installateur | Plusieurs visuels sont des remixes d'images des titres IL-2 Sturmovik (2001), Pacific Fighters et Forgotten Battles. Les fonds des menus de missions et de pays proviennent de captures de la communauté. Les droits sur ces images restent ceux de leurs ayants droit ; leur présence ou leur adaptation ne les place pas sous la licence des contributions originales d'Alfly. |
| Notices, citations et documents historiques de tiers | Leurs droits restent ceux de leurs auteurs ; la licence de la documentation originale d'Alfly ne s'étend pas à ces documents. |

Les [notices tierces](THIRD_PARTY_NOTICES.md) et
[crédits du pack](<../_Documentations/Mods and Tools/Credits - Open Sturmovik.md>)
conservent les attributions et conditions retrouvées. Les crédits ne constituent
pas une permission de redistribution. Les inventaires existants ne sont pas
présentés comme une certification exhaustive des droits de tous les fichiers.

Cette distinction est importante pour l'installateur : la permission portant
sur sa logique ne suffit pas, à elle seule, à autoriser tout son contenu.

## Documents à livrer

Chaque distribution des contributions couvertes doit conserver `LICENSE.md`.
Pour le pack complet, livrer aussi `docs/LICENSING.md`,
`docs/THIRD_PARTY_NOTICES.md`, les crédits et les notices propres aux composants
tiers effectivement distribués.

Le futur installateur complet devra inclure ces documents dans le contenu
distribué. L'ancienne ébauche a été supprimée ; aucun script d'installation
actuel ne permet de vérifier leur inclusion automatique. Voir la
[préparation de l'installateur](../installer/README.md).

## Qualification du choix

La licence est spécifique et non commerciale. Elle autorise les sources
accessibles et les forks, mais n'est pas une licence open source au sens de
la définition OSI, qui ne permet pas d'interdire un domaine d'activité comme
les usages commerciaux. Elle ne doit pas être annoncée sous les identifiants
MIT ou GPL, qui autorisent ces usages.

Sources de comparaison consultées le 12 septembre 2026 :

- [Définition Open Source, points 1 et 6 — OSI](https://opensource.org/osd) ;
- [Permissions MIT — Choose a License](https://choosealicense.com/licenses/mit/) ;
- [Permissions GPLv3 — Choose a License](https://choosealicense.com/licenses/gpl-3.0/) ;
- [Licence d'un dépôt public — GitHub](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

Ces sources expliquent la différence entre les modèles ; le texte de
`LICENSE.md` est propre à Open Sturmovik et n'est pas une version modifiée de MIT
ou de GPL. Aucune nouvelle condition n'est appliquée rétroactivement aux droits
déjà accordés par une licence tierce.
