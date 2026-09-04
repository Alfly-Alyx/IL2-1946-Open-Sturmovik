# Suivi differe - anomalie des nuages v1.15

Derniere mise a jour : 2 septembre 2026.

## Symptome confirme

Avec `TypeClouds=1`, les cartes Slovakia et Smolensk en meteo brumeuse
produisent de grands triangles ou pics blancs translucides. Certaines nappes
touchent le sol, traversent le relief et reapparaissent selon le point de vue.

Les flashes et panaches nucleaires rendent le defaut plus visible mais ne le
causent pas. Les passages par temps degage ne reproduisent pas l'exception.

## Preuves disponibles

- 21 occurrences de
  `java.lang.RuntimeException: unknown exception in clouds` ;
- point d'appel : `com.maddox.il2.engine.EffClouds.PreRender` ;
- reproduction sur Slovakia, Smolensk et un stress Smolensk comportant
  16 B-29 et 16 P-39D ;
- cartes deja parcourues : Slovakia, Smolensk, Okinawa, Mer de Corail,
  Iles du Pacifique, Moscou 1, Kuban, Berlin et Normandie 2 ;
- la session V1.15 active utilise `TypeClouds=0` comme temoin.

## Protocole apres la campagne active

Utiliser exactement la meme mission, la meme meteo et le meme point de vue sur
Smolensk :

1. Open Sturmovik avec `TypeClouds=1` ;
2. Open Sturmovik avec `TypeClouds=0` ;
3. IL-2 4.09m stock avec la configuration equivalente.

Pour chaque passage, conserver images, journal, classe `EffClouds` effective,
archives SFS chargees, backend graphique et informations du pilote OpenGL.

## Audit technique

- identifier la provenance effective de `EffClouds.class` ;
- identifier les ressources, materiaux et textures de nuages chargees depuis
  les fichiers libres et les SFS ;
- comparer la classe et les ressources avec 4.09m stock ;
- distinguer les nuages meteo, le brouillard au sol, les modifications
  graphiques et les particularites du pilote OpenGL moderne ;
- verifier les parametres passes a `EffClouds.PreRender` et les conditions qui
  declenchent l'exception ;
- mesurer si l'erreur entraine une reconstruction ou un rechargement repete des
  ressources graphiques.

`TypeClouds=0` ne doit pas devenir la correction definitive du profil de
realisme maximal. Aucun fichier de la copie de test ne doit etre modifie avant
la fin de la campagne V1.15 active.
