# Notes techniques de reprise : commandes et entrees

Ce document conserve les preuves et les incertitudes qui servent a construire
le catalogue de commandes. Il complete la reference destinee au lecteur et
doit permettre de reprendre l'analyse sans recommencer l'inventaire.

## Perimetre analyse

- Profil identifie par l'extraction : **4.09m modifie sans 6DOF**.
- Methode : lecture de fichiers et desassemblage statique des classes ; aucune
  classe du jeu n'a ete chargee ni executee.
- Classes actuellement inventoriees : `AircraftHotKeys.class`,
  `HookKeys.class` et `order/OrdersTree.class`.
- Libelles anglais : `i18n/controls.properties` de la meme extraction.
- Libelles francais observes : fichier historique nomme
  `Files/i18n/controls_ru.properties`, lu en Windows-1252 malgre son suffixe.
- Profils utilisateur compares : deux `settings.ini`, identifies dans le
  catalogue par leur empreinte et non par leur chemin personnel.

Les tailles et SHA-256 de toutes ces sources sont enregistres dans
`../manifests/hotkeys-4.09m-modified.json`.

## Resultat actuel

L'extraction trouve 273 enregistrements statiques et les fusionne avec les
commandes observees dans les profils :

| Mesure | Valeur |
|---|---:|
| Commandes uniques | 282 |
| Commandes publiques avec libelle | 236 |
| Commandes internes | 15 |
| Commandes dont le libelle reste a etablir | 31 |
| Commandes affectees dans au moins un echantillon | 132 |
| Commandes vues uniquement dans `settings.ini` | 9 |

Les commandes vues uniquement dans les profils sont `order10` a `order17` et
`AIRCRAFT_STABILIZER`. Elles doivent etre preservees par l'editeur, mais ne
doivent pas encore etre proposees comme commandes officiellement disponibles.
L'alias possible entre `AIRCRAFT_STABILIZER` et la commande enregistree
`Stabilizer` reste a prouver.

## Plages prouvees dans le code analyse

### Entree physique des axes

La classe `Joy` declare :

- quatre joysticks ;
- huit axes par joystick ;
- quatre POV ;
- 70 boutons ;
- une entree d'axe brute bornee de -125 a +125 ;
- un coefficient de normalisation de 0,008, soit une valeur normalisee de
  -1 a +1.

Une commande d'axe dont l'identifiant commence par `-` inverse le signe de
l'entree physique. Le tiret n'est donc pas une seconde action : il represente
l'orientation inverse du meme axe logique.

### Valeurs envoyees aux commandes de vol

Le traitement statique de `AircraftHotKeys.doCmdPilotMove` donne :

| Famille | Transformation | Plage logique |
|---|---|---:|
| Puissance | `valeur * 0,55 + 0,55` | 0 a 1,1 |
| Pas d'helice, volets et freins | `valeur * 0,5 + 0,5` | 0 a 1 |
| Ailerons, profondeur et direction | valeur normalisee directe | -1 a +1 |
| Trims | `valeur * 0,5` | -0,5 a +0,5 |

Ces plages de sortie ne doivent pas etre confondues avec les nombres stockes
pour calibrer un joystick.

### Calibration et courbes

L'analyse de `GUISetupInput` montre :

| Parametre | Minimum | Maximum | Remarque |
|---|---:|---:|---|
| Zone morte | 0 | 50 | Limite appliquee par l'interface analysee. |
| Points de courbe | 0 | 100 | Dix coefficients, valeur par defaut 10, 20, ..., 100. |
| Filtre affiche | 0 | 10 | L'interface l'enregistre multiplie par dix. |
| Filtre enregistre | 0 | 100 | Representation dans les donnees de sensibilite. |
| Sensibilite souris | 0,1 | 10 | Valeur bornee par l'interface analysee. |

Le format recent de sensibilite contient douze valeurs. Un ancien format est
converti par le jeu. Le prefixe de cle, le suffixe d'axe et la migration ne
doivent pas etre reecrits avant d'avoir documente exactement les deux formats.

## Methode reproductible

`../tools/Read-IL2HotKeyCatalogue.ps1` :

1. desassemble statiquement les classes fournies ;
2. releve les constructions de commandes et leur environnement ;
3. associe les libelles anglais et francais lorsqu'ils existent ;
4. fusionne les affectations observees dans les `settings.ini` ;
5. classe les commandes internes, publiques ou sans libelle ;
6. associe les plages logiques prouvees aux axes connus ;
7. peut comparer le resultat a un catalogue historique de reference.

Le script ne conserve que les noms relatifs, tailles et empreintes de ses
sources. Les chemins locaux ne doivent jamais entrer dans le manifeste.

`../tools/New-IL2CommandReference.ps1` transforme ensuite ce catalogue et ceux
d'`il2setup` en `REFERENCE_REGLAGES_COMMANDES.md`.

## Limites et anomalies a ne pas oublier

- **Origine historique ou mod ajoute : non resolue.** Le profil analyse est
  modifie. La classification exige une base 4.09m strictement d'origine,
  extraite avec la meme methode.
- **Libelles francais parfois errones.** Certaines traductions observees ne
  correspondent pas au libelle anglais, notamment autour de paliers de
  puissance. Conserver les deux langues et signaler l'anomalie plutot que
  corriger silencieusement la preuve.
- **Commandes sans libelle.** Une commande enregistree dans le code n'est pas
  necessairement une option destinee au joueur.
- **Commandes de profil orphelines.** Elles peuvent provenir d'une version
  differente, d'un mod retire ou d'un alias. Elles sont a conserver sans les
  activer automatiquement.
- **Minimum et maximum.** Pour un bouton, 0 et 1 decrivent l'etat de l'entree,
  pas un reglage ajustable. Pour une cle d'`il2setup.ini`, le minimum et le
  maximum publies sont parfois seulement les extremes observes dans les 39
  profils, pas une validation du parseur ou du moteur.
- **6DOF.** La presence de commandes de vue ou de mouvement ne prouve pas que
  l'ensemble executable/classes actif fournit un vrai mode 6DOF.

## Prochaines preuves a obtenir

1. Extraire les memes trois classes et les libelles d'une installation 4.09m
   strictement d'origine, puis utiliser la comparaison de catalogues.
2. Retrouver le code qui charge chaque section de `settings.ini` et documenter
   les regles exactes d'encodage des gestes, combinaisons, boutons, POV et axes.
3. Resoudre `AIRCRAFT_STABILIZER`, `Stabilizer` et `order10` a `order17`.
4. Cartographier toutes les classes de commandes ajoutees par Open Sturmovik,
   au-dela des trois classes deja inventoriees.
5. Tester sur copies jetables les bornes que le code statique ne permet pas de
   conclure, lorsque l'autorisation de lancer les outils cibles sera donnee.
6. Ajouter au futur PDF des exemples commentes de sections `settings.ini`, en
   retirant tout nom de pilote ou autre information personnelle.

