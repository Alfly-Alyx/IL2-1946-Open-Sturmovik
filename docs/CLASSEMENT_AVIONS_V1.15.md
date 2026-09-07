# Classement des avions v1.15

6 septembre 2026. Demande d'Alexis : conserver son classement et ses abreviations,
ordonner les allies puis l'axe puis les as. Les avions ordinaires suivent
constructeur, modele, variante ; les as suivent prenom, nom, modele d'avion.

## Sauvegarde et controle

Sauvegarde effectuee avant transformation dans
`D:\Projets\GITHUB\#res\IL2 1946\Sauvegarde_classement_avions_v1.15_20260906-204522`.
Elle conserve les trois air.ini, plane_ru.properties, le switcher et son manifeste.

| Fichier | Avant | Apres |
| --- | ---: | ---: |
| Files/com/maddox/il2/objects/air.ini | 535 | 535 |
| _Game Switchers/408m air.ini/Air.ini/air.ini | 516 | 516 |
| _Game Switchers/409m air.ini/Air.ini/air.ini | 535 | 535 |

Aucun identifiant, classe Java, camp, drapeau ou autre champ technique n'est
modifie. Les entrees normalisees sont identiques a la sauvegarde, hors ordre
et espaces. Aucun avion ajoute, retire ou duplique. Les camps suivent ceux
de chaque air.ini d'origine, meme lorsqu'ils different entre 4.08 et 4.09.
Le fichier actif et celui du switcher 4.09 sont identiques.

En 4.09 : 310 allies, 210 axe, 15 entrees d'as. Les variantes sont rangees
dans leur famille avec un tri naturel des nombres et chiffres romains.
Les abreviations d'Alexis sont conservees, dont V.S pour Vickers-Supermarine,
N.A pour North American, Me et FW. Les noms affiches viennent du fichier
plane_ru.properties ; les cles techniques ne sont pas renommees.

29 libelles manquants sont ajoutes pour des avions deja enregistres. Deux
doublons de libelles sont consolides en conservant la derniere valeur effective.
Le libelle Tu-4 hors liste est conserve, sans ajouter d'avion. Les remplacements
historiques de slots du pack (DB-3F/PZL, Do-335V-13/He-219, U-2TM/Tiger Moth)
gardent leurs libelles ; leur fidelite physique n'est pas reevaluee ici.

## Reproduction et sources

`tools/Update-AircraftPresentation.py --backup-root <sauvegarde>` controle
la transformation sans ecriture active ; `--apply` exige les empreintes
source attendues et la branche v1.15. Le rapport durable, les correspondances
des as et les empreintes sont dans `manifests/aircraft/presentation-v1.15.json`.
Les deux empreintes air.ini attendues par le switcher sont actualisees.
Le test hors jeu du switcher a passe pour neuf profils et deux variantes HUD.
La presentation effective dans les menus doit encore etre observee en jeu.

Sources locales prioritaires : sauvegarde des fichiers personnels d'Alexis,
pack original Open Sturmovik 1.1 et AAA Community Installer 1.1 sous #res.
Aucun air.ini de forum n'a ete importe.

Sources de recoupement consultees lors du classement :

- [SAS, guide activateur 4.09](https://www.sas1946.com/main/index.php?topic=5310.0)
  et [Mission4Today, ordre de la liste](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=24480)
  : extraits indexes consultes ; acces direct respectivement refuse et indisponible.
- [Fondation France Libre, Albert Durand](https://francelibre.net/albert-durand/).
- [Liste des as hongrois](https://en.wikipedia.org/wiki/List_of_World_War_II_aces_from_Hungary)
  et [Jorma Sarvanto](https://en.wikipedia.org/wiki/Jorma_Sarvanto) pour les noms.
- [Bell P-39/P-400](https://en.wikipedia.org/wiki/Bell_P-39_Airacobra),
  [Douglas SBD](https://en.wikipedia.org/wiki/Douglas_SBD_Dauntless),
  [avions militaires japonais](https://en.wikipedia.org/wiki/List_of_military_aircraft_of_Japan),
  [Smithsonian, Nakajima Ki-43](https://airandspace.si.edu/collection-objects/nakajima-ki-43-iib-hayabusa-peregrine-falcon-oscar/nasm_A19600098000).

AAA/Wayback etait inaccessible lors des essais. Aucune information issue
d'une page inaccessible n'est presentee comme verifiee.

## Raffinement demande : familles et ordre d'evolution

Alexis a ensuite demande de remplacer le tri alphabetique des modeles par
des blocs suivant leur evolution, notamment Hurricane, Sea Hurricane,
Typhoon, Tempest, Sea Fury. Cette deuxieme passe est realisee par
`tools/Reorder-AircraftFamilies.py --backup-root <sauvegarde> --apply`.
La premiere passe de nommage reste documentee ci-dessus ; ne pas relancer son
ancien constructeur pour ecraser ce nouveau classement.

Nouvelle sauvegarde avant modification :
`D:\Projets\GITHUB\#res\IL2 1946\Sauvegarde_avant_tri_evolution_v1.15_20260906`.
Le manifeste `manifests/aircraft/family-evolution-v1.15.json` conserve toutes
les sequences explicites et les empreintes. Le manifeste de presentation
principal pointe vers ce rapport et contient les nouvelles empreintes.

Regles de presentation appliquees :

- Les trois groupes Allies, Axe, As sont conserves, ainsi que les constructeurs.
- Une famille et ses variantes restent contigues. La filiation prime sur un
  tri global par annee : les Seafire suivent tous les Spitfire, sans s'intercaler
  entre les millesimes Spitfire ; meme principe pour Sea Hurricane et Sea Gladiator.
- Des espaces separent les familles dans air.ini. Les commentaires de famille
  restent dans plane_ru.properties ; aucune fausse entree ni section moteur
  n'est ajoutee a air.ini.
- Les versions Early precedent leur version standard ; les versions Late
  suivent leur base. Les suffixes mod, armement, export ou reconnaissance
  restent rattaches au modele concerne.
- Cas corriges explicitement : Mosquito IV, VI, XVI ; LaGG-3 puis La-5/La-7 ;
  Yak-1, Yak-7, Yak-9, Yak-3, Yak-15 ; Bf-109G-14 avant G-10 ; Ki-61 Ko,
  Otsu, Hei ; Spitfire IX avant VIII suivant leur introduction operationnelle.
  Les variantes d'une meme branche restent groupees meme si leurs dates se
  chevauchent avec une autre branche.

Le classement est une organisation editoriale des modeles presents, pas une
datation historique nouvelle de chaque mod. Les variantes non datees du pack
restent aupres de leur base sans qu'une annee soit inventee ou ajoutee au nom.
L'ordre des appareils des as est inchange. Tous les noms affiches sont
strictement identiques a ceux de la sauvegarde de cette deuxieme passe.

Controles : comparaison complete des lignes techniques normalisees,
535/535 pour le fichier actif, 516/516 en 4.08, 535/535 en 4.09 ; aucune ligne
ajoutee, retiree, modifiee ou dupliquee. Des assertions verifient les principales
sequences, la coherence du switcher et l'identite des libelles avant/apres.

Sources : fichiers locaux Open Sturmovik 1.1 et libelles deja verifies ; demande
explicite d'Alexis pour la disposition des familles ;
[Sea Power Centre de la marine australienne, filiation du Sea Fury](https://seapower.navy.gov.au/history/units/hawker-sea-fury-mark-11),
[RAF Museum, evolution du Mosquito](https://www.rafmuseum.org.uk/blog/the-wooden-wonder-of-the-raf/),
[variantes tardives du Spitfire](https://en.wikipedia.org/wiki/Supermarine_Spitfire_%28late_Merlin-powered_variants%29),
[Bf-109G-14 et G-10](https://en.wikipedia.org/wiki/Messerschmitt_Bf_109_variants),
[Yak-9](https://en.wikipedia.org/wiki/Yakovlev_Yak-9) et
[Yak-3](https://en.wikipedia.org/wiki/Yakovlev_Yak-3).
Mission4Today a ete reconsulte pour l'ordre des entrees et SAS pour ses outils
de listes, sans importer leurs fichiers ni appliquer de contenu BAT/4.10 a 4.09.
Le nouvel essai AAA/Wayback est reste inaccessible.

Le classement est aussi synchronise vers la copie de test au moyen du plan
`manifests/test/aircraft-family-evolution-v1.15.json`. Aucun jeu n'est lance
pendant cette passe ; le rendu des menus reste a confirmer manuellement.

## Retours du test du 7 septembre : BI et appellations historiques

Alexis signale l'absence du constructeur devant BI-1 et BI-6. Le classement
avait bien reconnu Bereznyak-Isayev dans ses commentaires, mais `tidy()` ne
l'ajoutait pas aux libelles affiches. Les deux libelles sont corriges dans
`Files/i18n/plane_ru.properties`, ainsi que cette regle du constructeur.
Aucune date, entree technique, famille ou autre appellation n'est changee.

Sauvegarde verifiee avant modification :
`D:\Projets\GITHUB\#res\IL2 1946\Sauvegarde_avant_correctifs_BI_CW21_v1.15_20260907`.
Les trois air.ini restent identiques octet pour octet (535 / 516 / 535).
Le manifeste de presentation contient l'empreinte actuelle et renvoie a
`manifests/aircraft/display-name-corrections-v1.15.json`. Le rapport de tri
`family-evolution-v1.15.json` reste le resultat historique de la deuxieme passe,
avant cette correction de deux noms ; ne pas le prendre pour l'empreinte
actuelle du fichier de libelles ni rejouer le tri pour appliquer cette correction.

Les noms questionnes sont conserves apres verification :

- Bereznyak-Isayev est l'attribution usuelle aux concepteurs du BI ; le bureau
  de construction est l'OKB-293 dirige par Bolkhovitinov, et non une entreprise
  commerciale portant le nom des deux concepteurs.
- N.A signifie North American. Mustang Mk.III est la designation RAF des
  P-51B/C ; Mk.IV celle du P-51D (le P-51K est Mk.IVA).
- Curtiss Hawk est authentique : Hawk 75 appartient a la famille P-36,
  Hawk 81 a celle du premier P-40. Tomahawk est l'appellation britannique des
  premiers P-40 ; elle ne doit pas etre remplacee arbitrairement par Warhawk.

Sources locales prioritaires : `Packs/AAA_Community_Installer_ver_1_1/MODS/STD/i18n/plane_ru.properties`
et `0 - ORIGINAL GAMES DO NOT USE/IL2-1946-Open-Sturmovik _1.1/Files/i18n/plane_ru.properties`
dans les ressources IL2 1946 : les libelles Mustang et Curtiss y existaient
deja ; les BI n'y avaient pas non plus de prefixe affiche.
Recoupement historique : [Bereznyak-Isayev BI](https://en.wikipedia.org/wiki/Bereznyak-Isayev_BI-1),
[variantes du Mustang](https://en.wikipedia.org/wiki/North_American_P-51_Mustang_variants),
[Curtiss Hawk 75](https://en.wikipedia.org/wiki/Curtiss_P-36_Hawk),
[US Navy, P-40B Tomahawk](https://www.history.navy.mil/content/history/museums/nnam/explore/collections/aircraft/p/p-40b-tomahawk.html)
(ce dernier accessible par son extrait indexe, ouverture directe en echec).
AAA/Wayback reste inaccessible lors du nouvel essai ; aucun contenu suppose.
Mission4Today et SAS ont aussi ete consultes pour le CW-21, voir son diagnostic.
