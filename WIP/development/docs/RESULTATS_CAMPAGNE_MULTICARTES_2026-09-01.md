# Resultats de la campagne multicartes du 1er septembre 2026

> **Perimetre historique avant le retrait du 12 septembre 2026.** Les constats,
> empreintes, listes de fichiers et commandes lies a MDS, DCG, San FOV ou Malta
> ci-dessous decrivent l'etat observe a leur date, pas le contenu cible actuel.
> MDS est desormais retire localement ; voir [le suivi courant](RETRAIT_COMPOSANTS_V1.15.md)
> et [la reconstruction AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md).
> Les anciens constructeurs et pieces retires sont conserves dans les archives
> externes identifiees par ce suivi ; ne pas reinstaller leur contenu.

## Perimetre et traces

La campagne instrumentee a utilise le profil 9, IL-2 1946 4.09m modifie,
OpenGL natif, profil graphique x86 securise et fenetre 1 024 x 768. Le dossier
de test etait :

`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`

Le jeu original de reference n'a pas ete modifie. Les traces brutes sont dans :

`WIP/tests/captures/startup/20260901-131015Z-profile9-warm-windowed1024-startup`

La session a produit 33 050 images (2,63 Gio), les compteurs processus et systeme, le
journal Java/natif, deux dumps de gel et les evenements Windows. Process Monitor
a ete arrete manuellement a 13:45:30 UTC apres une rotation anormale de huit
PML totalisant 42,95 Gio. Trois dumps occupent 2,16 Gio. Les images, journaux et compteurs ont continue jusqu'a
la fermeture volontaire du jeu a 14:21:13 UTC. Les PML ne doivent pas etre
supprimes avant l'analyse ciblee ; l'outil de capture doit etre corrige avant un
nouvel essai long.

## Parcours effectue

La session a couvert les deux bombes nucleaires sur Slovakia, puis une campagne
rapide de cartes et d'appareils :

- Slovakia, B-29 Silverplate, Little Boy puis Fat Man ;
- Slovakia brumeux, Tempest, descente depuis environ 5 000 m ;
- Smolensk brumeux, Tempest, descente vers le relief ;
- Okinawa, passage rapide ;
- Mer de Corail, Seafire ;
- Iles du Pacifique, C-47 ;
- Moscou 1, Fairey Battle ;
- Kuban, Miles Magister ;
- Berlin, Su-2 ;
- Normandie 2, RW-8 ;
- stress Smolensk nuageux : 16 B-29 avec Fat Man contre 16 P-39D.

Les passages rapides prouvent le chargement et revelent les erreurs grossieres.
Ils ne qualifient pas a eux seuls le modele de vol, le cockpit, AOC, Zuti ou la
fluidite 60 images/s. La mission Moscou 1 est seulement un candidat pour un
futur essai AOC/G negatifs : aucune manoeuvre normalisee n'a ete mesuree.

## Bloquant : moteur de nuages meteo

Le defaut est reproductible sur Slovakia et Smolensk avec une meteo nuageuse :

- les volumes se changent en grands triangles ou pics blancs translucides ;
- certaines nappes touchent le sol et traversent le relief ;
- le probleme suit les nuages et reapparait selon le point de vue ;
- les flashes et panaches nucleaires rendent le defaut encore plus visible,
  sans en etre la cause unique.

Les images `frame-013275.jpg`, `frame-018200.jpg` et `frame-018700.jpg` montrent
respectivement le defaut sur Slovakia puis Smolensk. Le journal fournit la
cause technique la plus precise actuellement disponible : 21 occurrences de

```text
java.lang.RuntimeException: unknown exception in clouds
    at com.maddox.il2.engine.EffClouds.PreRender(Native Method)
    at com.maddox.il2.engine.EffClouds.preRender(EffClouds.java:93)
```

Les occurrences commencent avec Slovakia a 13:43:18 UTC, continuent avec
Smolensk, puis reapparaissent dans le stress Smolensk. Les passages au ciel
degage n'en produisent pas. Il s'agit donc d'un echec du moteur de nuages meteo
`EffClouds`, distinct de la classe Java `NuclearBlast`.

Le `conf.ini` teste force `TypeClouds=1`, c'est-a-dire les nuages ameliores. La
prochaine experience doit rejouer la meme mission Smolensk, le meme point de
vue et la meme meteo avec :

1. `TypeClouds=1`, reference defectueuse ;
2. `TypeClouds=0`, moteur de nuages standard ;
3. profil 4.09m stock, pour separer un defaut du moteur officiel d'une surcharge
   du mod ou d'une incompatibilite avec l'OpenGL Intel moderne.

La communaute documente bien `TypeClouds=0` comme rendu standard et
`TypeClouds=1` comme rendu ameliore. Elle rapporte aussi des scintillements avec
certains mods de nuages. Sources :

- [guide `conf.ini` de la 102 Jugoslovenska Eskadrila](https://102nd.rs/il-2-info/il-2-1946/il-2-conf-ini-guide.html) ;
- [reference historique SAS1946 du `conf.ini`](https://www.sas1946.com/main/index.php?topic=9756.0) ;
- [retour SAS1946 sur un mod de nuages et le scintillement](https://www.sas1946.com/main/index.php?topic=31788.0).

Le repli `TypeClouds=0` n'est pas une correction definitive et ne doit pas
devenir silencieusement le profil « Realisme max ». Il sert a isoler la cause et
a conserver un profil jouable pendant l'analyse du moteur ameliore.

## Su-2 non controle pendant l'essai

Sur Berlin, le Su-2 n'acceptait aucune commande. `F2` et `F3` fonctionnaient,
mais `F1` ne pouvait pas ouvrir un cockpit. Les images montrent l'appareil en
vue exterieure sous controle IA.

L'audit statique exhaustif realise apres la campagne corrige le premier
diagnostic. La classe active `air.SU_2` declare directement :

- `FlightModels/Su-2.fmd` ;
- `CockpitSU_2` ;
- `CockpitSU_2_Bombardier` ;
- `CockpitSU_2_TGunner` ;
- son propre `NetAircraft.SPAWN`.

Les quatre classes existent et sont compatibles Java 47. Le fichier runtime
`Su-2_AOC_1a.txt` a aussi ete cree pendant cet essai, preuve que le modele a
atteint `FlightModelMain.load_modData()`. Mission Mate le marque `No`, mais ce
marquage externe ne suffit donc pas a conclure que cette classe est IA-only.
Le prochain essai doit distinguer une erreur de selection/affectation du joueur,
un depart comme spectateur et un defaut d'activation de la vue cockpit. On ne
retirera pas le Su-2 de la liste joueur avant ce retest controle.

Les trois `NullPointerException` a 14:19:04-14:19:05 UTC proviennent de
`AircraftHotKeys$14.begin(AircraftHotKeys.java:2553)` quand des commandes ont
ete envoyees sans appareil joueur valide. Elles appartiennent a la meme famille
de probleme et ne viennent pas de Fat Man.

## Sons des P-39D

Le chargement des 16 P-39D a produit 33 `FileNotFoundException`, 32 refus de
sample pools `motor.Allison.start.begin/end` et :

```text
Cannot load sound preset motor.Allison_V1700_series
(java.lang.Exception: Invalid preset format)
```

Le moteur a continue avec un repli sonore, ce qui explique l'absence de gel.
La v1.15 ne peut cependant pas annoncer des presets propres tant que ce cas
n'est pas corrige. L'audit doit comparer les fichiers libres sous
`Files/presets` et `Files/presets/sounds`, retrouver les WAV/presets Allison
attendus par `motor.Allison_V1700_series`, puis rejouer une mission comportant
un et seize P-39D. La repetition par appareil montre qu'un unique preset absent
multiplie le cout et le bruit du journal avec la taille de la formation.

## Stress 16 B-29 + 16 P-39D + Fat Man

Les messages radio et les images confirment plusieurs annonces de largage et
au moins le treizieme impact direct. Les images montrent les flashes blancs et
plusieurs volumes d'explosion. Le joueur etait spectateur, sans appareil
pilotable ; le test qualifie donc la charge IA/effets, pas les commandes.

Entre 14:19:00 et 14:21:00 UTC :

| Mesure | Resultat |
| --- | ---: |
| Echantillons processus | 898 |
| Echantillons `Responding=False` | 0 |
| Memoire physique maximale IL-2 | 852,3 Mio |
| Memoire privee maximale IL-2 | 720,0 Mio |
| Charge CPU IL-2 | 0,97 coeur equivalent |
| Charge GPU 3D estimee | 56,6 % |
| Memoire GPU locale maximale | 175,5 Mio |
| Memoire GPU validee maximale | 178,6 Mio |

Sur toute la phase de chargement, le pic monte a 864,8 Mio physiques,
732,7 Mio prives et 2 033,7 Mio virtuels. Les 66 mesures non repondantes et le
dump de 16:18:14 locale appartiennent au chargement de la mission, avant le
combat. Ils ne prouvent pas un gel sous les impacts.

Le ressenti d'Alexis — aucune saccade perceptible — est coherent avec l'absence
de mesure non repondante pendant le combat. Le moteur principal consomme
cependant presque exactement un coeur : ce test ne prouve pas une repartition
de la simulation sur quatre coeurs. Il montre seulement qu'un i5-8350U et son
Intel UHD 620 peuvent tenir cette charge a 1 024 x 768 avec le profil securise.
Il ne qualifie ni 1080p60, ni 2K, ni Windows x86.

## Autres erreurs visibles a reprendre

- les quatre chunks du cockpit B-29 restent absents : `zOilFlap1`,
  `zOilFlap2`, `zCompressor1`, `zCompressor2` ;
- `music/inflight` est absent, conforme a l'observation qu'aucune musique ne
  joue en vol ;
- Fairey Battle et Miles Magister ont emis des erreurs de presets sonores,
  de hooks ou de chunks a attribuer appareil par appareil ;
- la campagne rapide ne remplace pas l'essai de dix minutes Zuti/MDS ni l'essai
  normalise AOC/G negatifs ;
- les nuages meteo traversant le sol devront etre testes separement du clipping
  volontaire de brouillard au sol.

## Ordre de correction recommande

1. Reproduire Smolensk nuageux en A/B `TypeClouds=1/0`, puis en 4.09m stock.
2. Identifier la provenance effective de `EffClouds` et de ses ressources dans
   les SFS ; comparer les classes/natifs 4.09m sans remplacer a l'aveugle.
3. Rejouer le Su-2 et les trois variantes B-29 avec un emplacement joueur
   explicitement valide, puis verifier commandes, F1, cockpit et profil AOC.
4. Reparer le preset Allison et ses deux sample pools, puis tester 1 et 16 P-39D.
5. Attribuer les erreurs Fairey Battle/Miles Magister et reprendre les chunks
   B-29.
6. Rejouer le stress avec une mission reproductible, un appareil joueur valide,
   une camera fixe et un suivi assez long pour observer les 16 panaches.
7. Poursuivre le controle rapide des cartes apres le A/B, en conservant carte,
   meteo, avion, altitude et anomalies dans une matrice reproductible.
8. Qualifier separement 1080p60, les quatre coeurs, la memoire LAA et Windows
   32 bits/4GT.
