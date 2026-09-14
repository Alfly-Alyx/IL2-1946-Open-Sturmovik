# Resultats des tests cibles du 2 septembre 2026

## Perimetre et trace

- profil : 4.09m modifie, profil 9, OpenGL natif, fenetre 1024 x 768 ;
- nuages : `TypeClouds=0`, temoin standard et non correction definitive ;
- capture : `WIP/tests/captures/startup/20260902-180643Z-profile9-warm-windowed1024-startup` ;
- duree : 29 min 19 s entre detection et arret du processus ;
- images : 14 659 trames ;
- fin Windows : `AppHangTransient`, fermeture forcee demandee apres diagnostic.

## Appareils

### Su-2

Le Su-2 charge la mission mais son cockpit arriere echoue sur la ressource
absente `3DO/Cockpit/Il-10-TGun/TGunnerSU2.him`. La pile part de
`CockpitSU_2_TGunner` et remonte jusqu'a `Mission.loadAir`. Le probleme explique
le cockpit incomplet et doit etre corrige dans un chantier appareil distinct.

### B-29 et B-29 Silverplate

Alexis n'a constate aucun probleme de pilotage ou d'affichage pendant les deux
passages. Le journal conserve toutefois quatre erreurs de morceaux de cockpit
absents : `zOilFlap1`, `zOilFlap2`, `zCompressor1` et `zCompressor2`, ainsi que
des rechargements inattendus de textures du cockpit B-29. Les avions ne sont
donc valides que provisoirement ; ces avertissements doivent etre qualifies.

### KB-29P et CW-21

Le KB-29P n'a pas ete trouve dans la Mission rapide. Sa ligne `air.ini` et son
FMD B-29 existent, mais il n'enregistre aucun cockpit direct. Le CW-21 n'a pas
ete trouve dans l'editeur complet et ne possede aucun libelle i18n. Son futur
nom doit placer le constructeur en premier : `Curtiss-Wright CW-21`.

### TBF-1C, TBM-3 et MiG-3 Pokryshkin

Les trois appareils etaient absents de l'editeur pendant cette session. Le
diagnostic post-capture montre que la copie de test n'avait pas recu les 25
classes, cockpits et maillages deja restaures dans le depot. La classe MiG-3
Pokryshkin de la copie etait encore l'ancienne version sans `cockpitClass`.

Le validateur controle maintenant explicitement les 25 fichiers, leurs
empreintes et Java major 47. Ils ont ete synchronises dans la copie de test et
doivent etre retestes avant le prochain largage.

## Gel Little Boy

A 18:35:28 UTC, Little Boy a declenche :

```text
java.lang.NoClassDefFoundError: com/maddox/il2/objects/effects/NuclearBlast$State
    at com.maddox.il2.objects.effects.NuclearBlast.beginVisual(Unknown Source)
    at com.maddox.il2.objects.effects.Explosions.bombFatMan_land(Explosions.java:885)
    at com.maddox.il2.objects.weapons.BombLittleBoy.interpolateTick(BombLittleBoy.java)
```

L'image s'est immobilisee avant tout effet nucleaire visible. Apres l'exception,
1 006 des 1 014 echantillons etaient non repondants et le processus n'a consomme
qu'environ 1,44 seconde CPU jusqu'a sa fermeture. Ce comportement prouve un gel
logique, pas une saturation materielle. Les pics de la session sont 693,5 Mio de
memoire physique, 709,7 Mio de memoire privee et 2 020,3 Mio d'espace virtuel.

## Cause et correction

Le fichier de `NuclearBlast$State` avait bien ete copie, mais sous le mauvais
nom libre. Les deux noms fautifs appartenaient deja a d'anciennes classes :

| Classe nouvelle | Mauvaise adresse | Classe reellement adressee | Adresse correcte |
| --- | --- | --- | --- |
| `NuclearBlast$PhaseAction` | `2A3CF08C7344E18A` | `NuclearBlast$VisualAction` | `8D53953C1956F06A` |
| `NuclearBlast$State` | `AB04450E05C9E67C` | `NuclearBlast$VisualData` | `51AD1FEC90031C8A` |

Le pipeline applique maintenant quatre protections :

1. egalite exacte entre classes `NuclearBlast*.class` generees et mappees ;
2. absence de doublon dans les noms libres ;
3. recalcul independant de l'empreinte SFS depuis chaque nom Java ;
4. controle du paquet AAA complet dans la copie de test.

## Etat apres correction hors jeu

- cycle de vie nucleaire : 12/12 PASS ;
- audit nucleaire statique : 39/39 PASS ;
- contenu Open Sturmovik : 18 PASS, 3 WARN, 0 FAIL ;
- preparation du lancement : 47/47 PASS ;
- synchronisation : 30 changements appliques, 10 fichiers deja conformes ;
- sauvegarde : `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.sync-backup-20260902-212957`.

Les trois avertissements attendus restent la validation visuelle en jeu, la
licence Silverplate non publiee et l'absence de dump Selector pour ce passage.

## Prochain critere de passage

1. verifier TBF-1C, TBM-3 et MiG-3 Pokryshkin dans l'editeur puis en joueur ;
2. rejouer Little Boy sur Smolensk sans pause ;
3. ne passer a Fat Man que si aucun `NoClassDefFoundError`, gel ou redemarrage
   visuel n'apparait ;
4. analyser le journal avant toute nouvelle modification.
