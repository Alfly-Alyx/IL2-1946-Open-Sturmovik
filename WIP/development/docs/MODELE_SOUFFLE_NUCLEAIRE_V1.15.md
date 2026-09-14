# Modele de souffle nucleaire de la v1.15

## Verdict actuel

Le souffle implemente dans la v1.15 est une approximation de gameplay
coherente, mais pas encore un modele physique complet. Il ne doit pas etre
presente comme la version finale de la devise « Realisme max ».

Le correctif visuel du 3 septembre 2026 ne modifie volontairement ni ce
souffle, ni les degats. Cette separation permet au prochain essai de dire si
la reconstruction du champignon corrige la pause sans introduire une autre
variable.

## Ce que le modele fait deja

- puissances distinctes de 15 kt pour Little Boy et 21 kt pour Fat Man ;
- mise a l'echelle des distances par la racine cubique de la puissance ;
- courbe de surpression de reference comportant des points a 20, 10, 5, 2,
  1 et 0,5 psi ;
- degats du moteur limites au rayon retenu ;
- impulsion radiale plafonnee appliquee aux avions jusque dans la zone externe ;
- livraison retardee individuellement en fonction de la distance ;
- aucun calcul couteux par particule.

Ces choix donnent le bon ordre de grandeur des zones de danger. Le guide HHS
indique par exemple, pour une explosion de 10 kt au sol, une zone de degats
graves d'environ 0,8 km, une zone moderee jusqu'a environ 1,6 km et une zone
legere jusqu'a environ 4,8 km. Ces zones restent des ordres de grandeur et
changent avec la puissance, la hauteur d'explosion, la topographie et la meteo.

## Limites connues

Le delai actuel est `distance / 343`. Il assimile donc tout le front a une
onde acoustique. D'apres Glasstone et Dolan, la vitesse du front est au
contraire liee a la surpression par les relations de Rankine-Hugoniot : elle
est superieure a la vitesse du son pres de la detonation, puis s'en rapproche
lorsque le front faiblit.

L'impulsion appliquee a l'avion est par ailleurs instantanee. Le modele ne
represente pas encore :

- la duree de la phase positive de pression ;
- la phase negative et le retour d'air ;
- la pression dynamique et le vent qui suivent le front ;
- le roulis, le tangage et les efforts structuraux dus a l'orientation de
  l'appareil ;
- la reflexion au sol, la tige de Mach et les masquages par le relief ;
- la densite de l'air selon l'altitude et la meteo ;
- le souffle turbulent persistant dans la colonne et le chapeau ;
- les effets thermiques, ionisants et les retombees.

## Limites du rendu de particules 4.09m

Le rendu visuel et le souffle physique sont deux sous-systemes distincts. Le
test du 3 septembre 2026 confirme que la classe Java peut rester vivante et le
jeu repondant alors que le contenu visible d'un emetteur repart apres une
pause.

Les fichiers `.eff` combinent trois limites qu'il faut toutes respecter :

- `FinishTime` fixe la duree pendant laquelle l'emetteur voudrait produire ;
- `LiveTime` fixe la vie d'une particule et le moteur 4.09m la borne a 128 s ;
- `nParticles` borne le nombre de particules affichees simultanement.

| Effet actuel | Particules simultanees | Debit/s | Historique couvert par la capacite | `LiveTime` |
| --- | ---: | ---: | ---: | ---: |
| tete `buff` | 128 | 500 | 0,256 s | 128 s |
| tore terre `circleL` | 512 | 100 | 5,12 s | 128 s |
| colonne | 512 | 1 | 512 s | 128 s |
| gerbe eau `circle` | 256 | 1 024 | 0,25 s | 15 s |
| boule de feu `ring` | 256 | 500 | 0,512 s | 8 s |
| front visible `shock` | 128 | 500 | 0,256 s | 15 s |
| nuage stabilise | 512 | 4 | 128 s | 128 s |

La duree totale theorique d'un effet fini est `FinishTime + LiveTime` : la
gerbe d'eau actuelle vaut ainsi environ 17 secondes, comme dans la capture.
Pour les emetteurs de 600 ou 3 000 secondes, les ratios ci-dessus ne signifient
pas que l'emission s'arrete lorsque la capacite est pleine. Ils mesurent la
quantite d'historique qui peut coexister au debit demande. Le moteur doit alors
recycler, ecraser ou brider des particules ; son choix natif exact reste a
etablir par un A/B minimal. Il est donc faux de traiter `nParticles` comme un
stock consommable, mais tout aussi faux de supposer qu'un grand `FinishTime`
garantit a lui seul une fumee dense et continue.

L'API 4.09m de `Eff3DActor` ne fournit aucune methode Java pour avancer un
effet a un age donne. La correction de pause ne pourra donc pas recreer le meme
fichier `.eff`. Elle devra employer des effets de phase/pre-age adaptes a
l'age logique et des tranches d'emission bornees, avec destruction explicite.

## Evolution recommandee

Apres validation du rendu Little Boy/Fat Man, le modele suivant devra remplacer
le simple `distance / 343` par une table temps-distance dependante de la
puissance et de la surpression. Chaque cible recevra ensuite une impulsion sur
une courte duree, avec composantes de translation et de rotation, puis une
phase negative plus faible. L'altitude d'explosion, l'altitude de la cible et
la hauteur du terrain devront entrer dans le calcul de reflexion.

Cette evolution doit etre calibree hors jeu, puis comparee en jeu a plusieurs
distances. Elle devra conserver un cout borne pour les missions comportant
seize bombardiers et rester compatible avec le moteur x86/Java 1.3.

## Sources techniques

- [Glasstone et Dolan, *The Effects of Nuclear Weapons*, DTRA, 1977](https://www.dtra.mil/Portals/125/Documents/NTPR/newDocs/NTREReport/Glasstone%201977%20-%20The%20Effects%20of%20Nuclear%20Weapons.pdf), chapitre 3 : vitesse du choc, surpression, pression dynamique et reflexion ;
- [HHS/REMM, *Planning Guidance for Response to a Nuclear Detonation*, 3e edition](https://remm.hhs.gov/PlanningGuidanceNuclearDetonation_2023.pdf), zones de degats et facteurs qui modifient leur geometrie ;
- [HHS/REMM, synthese des explosions nucleaires](https://remm.hhs.gov/nuclearexplosion.htm), ordres de grandeur des degats et de la surpression.
- [SAS1946, explication des parametres `.eff`](https://www.sas1946.com/main/index.php?topic=21098.0), sens de `FinishTime`, `LiveTime`, `EmitFrq` et `nParticles` dans le moteur IL-2 ;
- [SAS1946, structure et distance de chargement des effets](https://www.sas1946.com/main/index.php?topic=52442.0), limites pratiques des effets communautaires ;
- [DOE/OSTI, histoire technique de Hiroshima et Nagasaki](https://www.osti.gov/opennet/servlets/purl/16009191-5O5srR/16009191.pdf), montee du nuage pendant la premiere minute et altitude de 40 000 a 50 000 pieds apres environ dix minutes.
