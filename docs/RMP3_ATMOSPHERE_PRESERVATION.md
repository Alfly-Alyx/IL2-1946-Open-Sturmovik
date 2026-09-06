# RMP3 Atmosphere : conservation et perimetre reel

Audit du 6 septembre 2026, Open Sturmovik v1.15 / IL-2 4.09m.

## Ce qui est conserve

La sauvegarde `RMP3_Atmosphere_nuages_avant_WxTech_PARTIEL.zip` contient les
sept fichiers suivis sous `Files/Effects/clouds` dans le commit
`acf2d91500fd7196b1ccb3c24c6f1c5040264c78`, avant leur remplacement par WxTech.
Elle est destinee a `D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés`.

Ce n'est **pas** une distribution complete ou un installateur de
`RMP3_ZloyPetrushkO_Atm2_modv4_3_s`. L'archive originale exacte n'a pas ete
retrouvee dans les ressources locales consultees. Aucun fichier manquant n'a
ete recree. L'attribution des anciens nuages a RMP3 provient du suivi du depot
et du temoignage historique ci-dessous ; elle n'a pas ete verifiee par une
comparaison avec l'archive originale complete.

La sauvegarde est hors du jeu. Elle ne reactive pas les anciens nuages et ne
doit pas etre fusionnee directement avec les materiaux WxTech.

## Faits verifies localement (confiance elevee)

- Le remplacement WxTech concerne les ressources du chemin
  `Files/Effects/clouds`, ainsi que le retrait de la copie sous
  `Files/3do/Effects/clouds`. Il ne prouve pas une desinstallation de tout
  Atmosphere.
- `Files/96F4C2FA0F2B0FD0` est `com/maddox/il2/fm/Wind`, 3906 octets,
  SHA-256 `9F4D4CD46FEBC05547AE1D1E7556414DD040E008DEEB9F7A51548B40D2D8D6FD`.
- `Files/E9BD6E7219DE5998` est `com/maddox/il2/fm/AIFlightModel`, 13178 octets,
  SHA-256 `1088EBE8BE3351E2A7DA0743882D5B3C1DD88E8CBEC380DE6E8680B4496676D1`.
- Ces deux classes sont inchangees depuis le commit cite et identiques aux
  fichiers de `Packs/AAA_Community_Installer_ver_1_1/MODS/WindConfig_v3`
  dans les ressources locales. Leur presence ne suffit pas a attribuer
  l'ensemble du comportement actif a RMP3.
- `Files/684916A0E86D1CC8` est `RealFlightModel`, 29047 octets,
  SHA-256 `1115B13B81727674B4141D8BA791D1EF919A70BE20C69FB4700AE3F37538C979`.
  Il correspond au correctif AOC/Zuti documente dans `manifests/aoc-v1.15.json`,
  et n'est pas identique au fichier WindConfig_v3. Il n'a pas ete modifie
  pendant cet audit.

La notice locale `MODS/_DOCS_/WindConfig_v3_README.txt` decrit les parametres
`WindVelocity`, `WindDirection`, `WindTop`, `WindTurbulence` et `WindGust` dans
la section `[Weather]` d'une mission. Elle decrit aussi l'application du vent
au joueur et a l'IA, avec une attenuation au sol. C'est la documentation de
WindConfig_v3, pas une preuve que toutes les fonctions de RMP3 sont actives.

## Sources historiques et limites

- [Discussion RMP3, aout 2010, AviaSkins](https://forum.aviaskins.com/showthread.php?nojs=1&p=60663) :
  un inventaire de conflits cite le nom exact du module pour plusieurs
  materiaux de nuages **et** pour `684916A0E86D1CC8`. Cela etablit que ce module
  ne se limitait pas aux textures. Le contenu indexe est accessible ;
  l'ouverture directe de la page a echoue pendant l'audit.
- [Notes HSFX v4 publiees sur Mission4Today](https://mail.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&start=0&t=7663) :
  Atmosphere v1/v3.1 traite aussi du vent, des rafales, des turbulences et,
  pour v3, du souffle des helices. Ces versions different de la v4.3 RMP3 :
  ne pas transposer automatiquement toutes leurs fonctions ou dependances.
- [Discussion SAS sur une installation UP 2.01 / 4.09m](https://www.sas1946.com/main/index.php?topic=6631.84) :
  cite `Atm_mod3.1Wind_Turb&Prop` parmi les modules actifs ; confirme le
  contexte historique, pas la compatibilite exacte de RMP3 v4.3.
- AAA via Wayback : tentative sur
  `https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/`
  en echec. Le lien FileFront historique du RealModPack 3 et sa tentative
  d'ouverture via Wayback n'ont pas permis de recuperer l'archive.

## Reproduction et suites

1. Verifier la racine Git et la branche `v1.15`.
2. Lister les anciens fichiers avec `git ls-tree -r --long
   acf2d91500fd7196b1ccb3c24c6f1c5040264c78 -- Files/Effects/clouds`.
3. Exporter uniquement ces fichiers avec
   `git -c core.autocrlf=false -c core.eol=lf archive --format=zip`, puis
   joindre cette notice. Comparer chaque entree de l'archive au blob Git
   d'origine et verifier l'empreinte de la copie dans le dossier Mods.
   La desactivation locale a cette commande de la conversion CRLF garantit
   une sauvegarde exacte des blobs, sans modifier la configuration Git.
4. Identifier les classes avec le parseur `parse_class` du script
   `tools/Audit-JavaClasses.py` et comparer leurs SHA-256 aux ressources AAA.
5. Avant toute eventuelle restauration de fonctions RMP3, retrouver sa
   distribution exacte et comparer ses classes/dependances a AOC/Zuti 4.09m.
   La presence actuelle du souffle des helices RMP3 reste inconnue. Aucun
   changement de physique ni test en jeu n'a ete effectue pour cet audit.

Decision : conserver les ressources retirees ; ne pas assimiler le
remplacement visuel des nuages a l'abandon de toutes les fonctions
atmospheriques. Le fonctionnement effectif doit etre confirme en jeu.
