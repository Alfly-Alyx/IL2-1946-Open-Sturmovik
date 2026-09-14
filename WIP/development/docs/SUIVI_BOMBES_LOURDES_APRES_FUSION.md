# Suivi differe - bombes conventionnelles de 5 a 10 tonnes

Derniere mise a jour : 2 septembre 2026.

## Etat

L'audit de la FAB-5000 est termine au niveau statique, mais sa correction doit
reprendre apres la fusion du cycle nucleaire v1.15. La classe globale
`Explosions` est actuellement modifiee par ce chantier et ne doit pas recevoir
deux implementations concurrentes.

## Reprise obligatoire

- confirmer sur une source sovietique primaire la masse totale, le chargement
  explosif et la composition exacte de la FAB-5000 NG ;
- remplacer la sphere generique de 2 500 m par des effets distincts de souffle,
  fragmentation, dommages structuraux, cratere et choc au sol ;
- traiter le rayon horizontal et vertical par distance oblique ;
- distinguer explosion au sol, en air libre et enfouie, avec hauteur
  d'explosion ;
- supprimer la fragmentation generique physiquement impossible produite pour
  les avions ;
- creer des effets visuels FAB-5000 dedies au lieu de reutiliser ceux de la
  FAB-1000 ;
- borner les recherches d'acteurs et eviter les explosions secondaires
  recursives pour preserver la stabilite du moteur ;
- tester les anneaux de distance au sol, les avions empiles verticalement et
  une mission dense avant integration.

Toute implementation devra etre preparee comme correctif isole, puis appliquee
sur la version de `Explosions` issue de la fusion nucleaire.
