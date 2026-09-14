# Boucle moteur persistante — IL-2 4.09m / v1.15

6 septembre 2026. Retour utilisateur : un son de ralenti reste audible a
100 % des gaz sur plusieurs avions. Aucun nouvel essai en jeu pendant l'audit.

## Faits statiques verifies

- `MotorSound` cree les `SamplePool` `motor.<nom>.start.begin` et `.start.end`.
  `onEngineState(2)` et `onEngineState(4)` declenchent ces sons. Cette classe
  n'annule pas ensuite les flux de ces pools.
- `SamplePool.load` lit `[samples]`, cree chaque `Sample` puis charge sa
  section `sample.<nom>`. `Sample.load` lit `infinite` (faux par defaut) et
  transmet le drapeau de boucle au moteur sonore natif.
- `SectFile.listFindString` compare les noms sans distinction de casse.
  La difference `Start`/`start` n'est donc pas, a elle seule, une section absente.
- Dix presets Tiger33 des familles DB-600, Merlin, Sabre, Sakae et R-2800
  contenaient chacun deux `infinite 1` dans leurs echantillons de demarrage.
  Ces vingt valeurs sont devenues `infinite 0`. Aucun WAV, gain, controle
  RPM, modele moteur ou profil AOC n'est modifie par cette correction.
- Les empreintes avant adaptation sont conservees sous `sourcePresetSha256`
  et les empreintes finales sous `presetSha256` dans
  `manifests/audio/tiger33-startup-sounds.json`.

## Portee et incertitude

La configuration de boucles de demarrage et sa suppression sont certaines.
Son role dans tout le symptome entendu reste a confirmer : les presets Allison
etaient deja finis, et 100 % des gaz n'indique pas a lui seul le regime moteur
reel. Ne pas declarer tous les sons corriges sans ecoute en jeu.

Source locale prioritaire : archive Tiger33 UV3_SFS dans
`D:\Projets\GITHUB\#res\IL2 1946\Mods\Utilisés\Tiger33 Ultimate Sound Mod V3`.
[Publication Tiger33](https://www.sas1946.com/main/index.php?topic=3258.0).
Le constat du chargement repose sur les classes de la copie 4.09m, et non sur
une supposition issue du forum. AAA/Wayback est reste inaccessible lors des
recherches precedentes ; les ressources locales font foi pour le code charge.

## Reproduction

Decompiler avec CFR 0.152 les classes `com/maddox/sound/Sample`, `SamplePool`,
`com/maddox/il2/objects/sounds/MotorSound` et `com/maddox/rts/SectFile` du dump
4.09m sous `WIP/analyses/labs/IL 2 Sturmovik 1946 Selector Dump/dump`.
Le constructeur des rapports de contenu controle les empreintes et rejette
desormais toute boucle infinie dans les dix presets de demarrage.

Test a effectuer : P-39N (Allison, temoin) puis Bf-109G-6 Early (DB-600).
Demarrage, attente de la fin du son transitoire, observation du compte-tours,
paliers bas regime/mi-regime/plein gaz, vue cockpit puis exterieure, arret
complet et redemarrage. Verifier aussi une mission commencant deja en vol.
Noter l'avion, le regime reel et le moment ou une eventuelle boucle persiste.
