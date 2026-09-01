# Protocole d'essai multicartes du 1er septembre 2026

## Etat de preparation

Le dossier de test est
`C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test`. Le jeu original reste en
lecture seule. Le profil retenu est le profil 9 : 4.09m modifie, choix 6DOF
historique, wrapper de mods historique et OpenGL natif. La fenetre reste en
1 024 x 768 et le profil graphique x86 securise est conserve pour comparer les
resultats aux captures precedentes.

La validation a froid avant armement obtient 17 PASS, un avertissement de dump
attendu, zero FAIL et 46 controles de disponibilite reussis. Aucun processus
IL-2, FrameCapture, Process Monitor ou ProcDump n'est actif.

## Instrumentation retenue

La premiere passe utilise la capture de fenetre, les compteurs CPU/GPU/memoire,
les journaux IL-2, ProcDump differe et Process Monitor. La trace fichiers sert a
identifier les ressources de chaque carte, les absences et les lectures
repetees. Elle alourdit le PC : les temps mesures seront classes
« instrumentes », pas utilises seuls comme temps de chargement normaux.

Une seconde campagne courte sans Process Monitor mesurera plus tard les temps et
la fluidite reels sur les cartes qui auront fonctionne.

## Ordre des cartes

### 1. Slovakia ete : correction SFS et Little Boy

- Mission rapide `SlovakiaRedNone00`.
- B-29 Silverplate, emport Little Boy.
- Largage par `Alt+Espace` ou `Ctrl+B` (`Weapon3`).
- Ne pas mettre en pause avant l'impact.
- Laisser le panache se developper, conserver un point de vue reconnaissable.
- Pause de cinq secondes, reprise, observation pendant quinze secondes.
- Deuxieme pause courte d'environ une seconde, nouvelle observation.
- Si possible, traverser ensuite la colonne sans risquer le sol.

Controles : continuité visuelle immediate, absence de rattrapage accelere,
arrivee differee du souffle, jeu repondant, et zero erreur
`maps/slovakia/actors.static`. Le journal doit charger
`actors_summer.static` depuis `fb_maps15.SFS` et ne plus annoncer une carte
statique endommagee.

### 2. Mbug Slovakia winter : carte libre et terrain proche

- Mission rapide `Mbug_Slovakia_winterRedNone00`.
- Utiliser un Hawker disponible, de preference Typhoon ou Hurricane.
- Vol bas et rapide pendant deux a trois minutes.
- Faire un virage large, changer une fois de vue puis revenir au cockpit.
- Une pause courte permet de voir si une fumee, trainee ou effet conventionnel
  perd son etat ; noter visuellement tout cas sans conclure avant les journaux.

Controles : saccades de chargement, apparition tardive des textures, changements
de niveau de detail, texture d'appareil manquante et erreurs provenant des
ressources libres `Files`.

### 3. CAN Channel : charge de carte et textures partagees

- Mission rapide `CAN_ChannelRedNone00`.
- Tempest Mk V si disponible, sinon Typhoon puis Hurricane.
- Vol bas et rapide pendant trois minutes, avec vue avant puis laterale.
- Ne pas declencher d'explosion nucleaire : cette passe doit isoler carte,
  appareil, textures, GPU et lectures de fichiers.

Cette carte est retenue parce que ses missions rapides sont sensiblement plus
denses et qu'elle sollicite les textures partagees de `Files/Maps/_Tex`, dont
le volume libre depasse un Gio. Elle doit fournir un cas plus exigeant que les
deux Slovakia.

## Arret et criteres

Quitter proprement apres la troisieme carte. En cas de gel, attendre au moins
quinze secondes avant de fermer et indiquer l'action exacte qui l'a precede.
Ne pas multiplier les actions pendant un blocage : la chronologie doit garder
une cause identifiable.

Le passage est acceptable si :

- chaque carte atteint le vol et revient au menu sans gel ;
- Little Boy conserve exactement son etat visuel apres les deux pauses ;
- le souffle arrive selon le temps de simulation et aucune exception ABI ne
  reapparait ;
- Slovakia charge ses objets statiques ;
- aucune texture d'avion ou de terrain indispensable ne manque ;
- chaque erreur restante peut etre attribuee a une ressource et a une
  consequence precise.

Cette campagne ne qualifie pas encore Windows x86, les 60 images/s ou tous les
effets. La qualification Windows 32 bits est obligatoire pour la v1.15 et devra
etre effectuee sur une machine x86 reelle. La preservation de pause sera ensuite
generalisee, par essais A/B, a toute explosion, incendie ou fumee qui reproduit
le defaut nucléaire.
