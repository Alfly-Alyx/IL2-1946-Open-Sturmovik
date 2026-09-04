# Audit complet Little Boy / Fat Man pour la v1.15

Derniere generation : 2026-09-03T17:01:04.206072+00:00.

## Verdict

- coherence statique : **PASS** (42 controles reussis, 0 echec) ;
- aptitude a publier : **BLOQUEE PAR LA VALIDATION EN JEU ET L'ABSENCE DE LICENCE SILVERPLATE** ;
- l'ancien gel Silverplate/Zuti et l'erreur d'ABI de la secousse sont corriges ;
- le prototype a emetteur mobile a ete rejete apres capture ; son remplacement par couches fixes bornees reussit les controles hors jeu, mais son comportement camera/pause reste a valider en vol.

Le mot `PASS` ne couvre que les fichiers, les liaisons Java et les limites
statiques. Il ne signifie pas que l'effet visuel final est valide.

## Controles statiques

| Controle | Etat | Detail |
| --- | --- | --- |
| classe generee com.maddox.il2.objects.effects.Explosions | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.ai.Explosion | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.ai.MsgExplosion | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.weapons.BombLittleBoy | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.weapons.BombFatMan | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$DamageAction | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$DamageData | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$ShockAction | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$ShockData | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$PhaseAction | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$VisualTickAction | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$State | **PASS** | empreinte, taille et Java 1.3 conformes |
| adressage SFS des classes generees | **PASS** | chaque nom libre correspond a l'empreinte de sa classe Java |
| integration com.maddox.il2.objects.air.B_29SP | **PASS** | classe attendue active |
| integration com.maddox.il2.objects.weapons.BombGunLittleBoy | **PASS** | classe attendue active |
| integration com.maddox.il2.objects.weapons.BombGunFatMan | **PASS** | classe attendue active |
| emports B-29 Silverplate | **PASS** | Little Boy et Fat Man utilisent deux crochets distincts |
| cockpit pilote B-29 Silverplate | **PASS** | CockpitB29SP et son maillage B-29-SP remplacent le cockpit B-29 standard incompatible |
| liaison BombGunLittleBoy -> BombLittleBoy | **PASS** | une munition, classe de bombe correcte |
| liaison BombGunFatMan -> BombFatMan | **PASS** | une munition, classe de bombe correcte |
| ABI Silverplate / Zuti | **PASS** | surcharge a six arguments et transactions visuelles terre/eau presentes |
| distribution differee du souffle | **PASS** | NuclearBlast.schedule remplace la distribution nucleaire immediate |
| age visuel fonde uniquement sur la simulation | **PASS** | Time=['current'], reflection=False |
| etat nucleaire persistant | **PASS** | temps, position, altitude, puissance, surface, phase et acteurs suivis |
| cycle de vie borne des acteurs | **PASS** | postDestroy explicite, listes videes et etats termines retires |
| origines fixes des couches de particules | **PASS** | aucun Eff3DActor actif n'est deplace apres sa creation |
| ordre et delai de nettoyage | **PASS** | phases=[1, 30, 120, 600, 1800, 3600], limite=3728s |
| sommets des champignons | **PASS** | Little Boy=12000m, Fat Man=13500m |
| declaration air.ini | **PASS** | occurrences valides=1 |
| ressource Files/3do/Arms/LittleBoy/LittleBoy.msh | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/LittleBoy/mono.sim | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/LittleBoy/skin.mat | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/LittleBoy/skin.tga | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/FatMan.msh | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/mono.sim | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/skin.mat | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/skin.tga | **PASS** | identique au paquet Silverplate v1.2 |
| empreintes des dix effets | **PASS** | effets visuels conformes au manifeste |
| limites du moteur d'effets | **PASS** | nParticles <= 512 et LiveTime <= 128 pour chaque emetteur |
| materiaux des effets | **PASS** | tous les MatName se resolvent |
| unicite des classes nucleaires | **PASS** | aucune definition libre concurrente |

## Ce qui empeche encore la validation v1.15

- Le nouveau rendu par couches fixes n'est pas encore valide dans IL-2 apres pause/reprise et sortie puis retour dans le champ de la camera.
- Le masquage camera peut encore relancer l'emetteur de la phase courante ; il ne doit cependant plus pouvoir rejouer la detonation complete apres une seconde.
- Les compteurs runtime doivent confirmer que tous les acteurs crees sont detruits et qu'aucun etat ne subsiste apres 3 600 secondes simulees.
- Les sommets cibles de 12 km et 13,5 km sont implantes mais leur placement visuel doit etre confirme en jeu.
- Fat Man avec/sans pause, les deux airbursts sur l'eau, la visibilite image par image du flash et l'autorite multijoueur exigent encore un essai dedie.
- Les blessures thermiques, le rayonnement ionisant, les retombees et la turbulence persistante du panache ne sont pas implementes.
- Silverplate v1.2 n'a pas de licence publiee et n'accorde aucune autorisation de redistribution ; une permission explicite, une installation externe ou un remplacement est requis avant publication.

## Sources de realisme retenues

- [Chronologie NPS des bombardements](https://www.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm) : Little Boy explose a environ 600 m et le diametre maximal de la boule de feu est atteint vers une seconde ;
- [Histoire du projet Manhattan, Department of Energy](https://www.energy.gov/sites/default/files/maprod/documents/DE99001330.pdf) : Fat Man, 21 kt, explosion a 1 650 pieds ;
- [Guide HHS/REMM](https://remm.hhs.gov/PlanningGuidanceNuclearDetonation.pdf) : pour 10 kt, rayons de reference 20/10/5/2 psi = 0,48/0,71/0,97/1,8 km ;
- [Rapport OSTI sur Hiroshima et Nagasaki](https://www.osti.gov/opennet/servlets/purl/16009191-5O5srR/16009191.pdf) : maximum du nuage vers dix minutes et 40 000 a 50 000 pieds.
- [The Effects of Nuclear Weapons, edition officielle GovInfo](https://www.govinfo.gov/content/pkg/GOVPUB-D-PURL-gpo106759/pdf/GOVPUB-D-PURL-gpo106759.pdf) : stabilisation vers dix minutes, visibilite possible pendant une heure ou davantage et, sous environ 20 kt, rayon de la tige voisin de la moitie du rayon du nuage.

## Prochain essai cible

Le prochain essai nucleaire ne doit pas etre un simple largage libre. Il devra
capturer Little Boy puis Fat Man, sans pause et avec pause, un demi-tour complet,
un passage hors champ, la visibilite image par image du flash, puis un airburst
sur l'eau. La mission dense doit en plus mesurer le nombre d'acteurs d'effets
encore vivants apres plusieurs explosions.

Rapport machine : `manifests/effects/nuclear-static-audit-v1.15.json`.
