# Audit complet Little Boy / Fat Man pour la v1.15

Derniere generation : 2026-09-01T21:40:26.767173+00:00.

## Verdict

- coherence statique : **PASS** (33 controles reussis, 0 echec) ;
- aptitude a publier : **BLOQUEE PAR LA VALIDATION EN JEU ET L'ABSENCE DE LICENCE SILVERPLATE** ;
- l'ancien gel Silverplate/Zuti et l'erreur d'ABI de la secousse sont corriges ;
- le panache reste incorrect apres pause ou sortie du champ de la camera.

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
| classe generee com.maddox.il2.objects.effects.NuclearBlast$VisualAction | **PASS** | empreinte, taille et Java 1.3 conformes |
| classe generee com.maddox.il2.objects.effects.NuclearBlast$VisualData | **PASS** | empreinte, taille et Java 1.3 conformes |
| integration com.maddox.il2.objects.air.B_29SP | **PASS** | classe attendue active |
| integration com.maddox.il2.objects.weapons.BombGunLittleBoy | **PASS** | classe attendue active |
| integration com.maddox.il2.objects.weapons.BombGunFatMan | **PASS** | classe attendue active |
| emports B-29 Silverplate | **PASS** | Little Boy et Fat Man utilisent deux crochets distincts |
| liaison BombGunLittleBoy -> BombLittleBoy | **PASS** | une munition, classe de bombe correcte |
| liaison BombGunFatMan -> BombFatMan | **PASS** | une munition, classe de bombe correcte |
| ABI Silverplate / Zuti | **PASS** | surcharge a six arguments et enregistrement des 12 effets presents |
| distribution differee du souffle | **PASS** | NuclearBlast.schedule remplace la distribution nucleaire immediate |
| declaration air.ini | **PASS** | occurrences valides=1 |
| ressource Files/3do/Arms/LittleBoy/LittleBoy.msh | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/LittleBoy/mono.sim | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/LittleBoy/skin.mat | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/LittleBoy/skin.tga | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/FatMan.msh | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/mono.sim | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/skin.mat | **PASS** | identique au paquet Silverplate v1.2 |
| ressource Files/3do/Arms/FatMan/skin.tga | **PASS** | identique au paquet Silverplate v1.2 |
| empreintes des huit effets | **PASS** | effets visuels conformes au manifeste |
| limites du moteur d'effets | **PASS** | nParticles <= 512 et LiveTime <= 128 pour chaque emetteur |
| materiaux des effets | **PASS** | tous les MatName se resolvent |
| unicite des classes nucleaires | **PASS** | aucune definition libre concurrente |

## Ce qui empeche encore la validation v1.15

- Le panache repart apres pause/reprise et apres une sortie puis un retour dans le champ de la camera.
- La surveillance de pause native n'a donc aucun benefice visuel valide ; son controle toutes les 25 ms doit etre retire ou remplace.
- La duree des Eff3DActor initiaux et stabilises n'est pas encore explicitement bornee ; les sessions longues ou denses exigent un audit de retention.
- Le nuage stabilise est place a seulement 5 000 m pour 10 kt avant mise a l'echelle, sous le maximum historique documente de 40 000 a 50 000 pieds.
- Fat Man avec/sans pause, les deux airbursts sur l'eau, la visibilite image par image du flash et l'autorite multijoueur exigent encore un essai dedie.
- Les blessures thermiques, le rayonnement ionisant, les retombees et la turbulence persistante du panache ne sont pas implementes.
- Silverplate v1.2 n'a pas de licence publiee et n'accorde aucune autorisation de redistribution ; une permission explicite, une installation externe ou un remplacement est requis avant publication.

## Sources de realisme retenues

- [Chronologie NPS des bombardements](https://www.nps.gov/articles/000/the-atomic-bombings-of-hiroshima-and-nagasaki.htm) : Little Boy explose a environ 600 m et le diametre maximal de la boule de feu est atteint vers une seconde ;
- [Histoire du projet Manhattan, Department of Energy](https://www.energy.gov/sites/default/files/maprod/documents/DE99001330.pdf) : Fat Man, 21 kt, explosion a 1 650 pieds ;
- [Guide HHS/REMM](https://remm.hhs.gov/PlanningGuidanceNuclearDetonation.pdf) : pour 10 kt, rayons de reference 20/10/5/2 psi = 0,48/0,71/0,97/1,8 km ;
- [Rapport OSTI sur Hiroshima et Nagasaki](https://www.osti.gov/opennet/servlets/purl/16009191-5O5srR/16009191.pdf) : maximum du nuage vers dix minutes et 40 000 a 50 000 pieds.

## Prochain essai cible

Le prochain essai nucleaire ne doit pas etre un simple largage libre. Il devra
capturer Little Boy puis Fat Man, sans pause et avec pause, un demi-tour complet,
un passage hors champ, la visibilite image par image du flash, puis un airburst
sur l'eau. La mission dense doit en plus mesurer le nombre d'acteurs d'effets
encore vivants apres plusieurs explosions.

Rapport machine : `manifests/effects/nuclear-static-audit-v1.15.json`.
