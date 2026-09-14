# Suivi de l'anomalie des nuages v1.15

Derniere mise a jour : 6 septembre 2026.

## Emplacement de `TypeClouds`

La configuration officielle IL-2 4.09m conserve volontairement deux valeurs :

- `Typeclouds=1` sous `[game]` ; la classe Java 4.09m
  `com.maddox.il2.engine.Config.loadGame()` la lit dans
  `Config.newCloudsRender` ;
- `TypeClouds=1` sous `[Render_OpenGL]` ; cette section complete est transmise
  au chargeur natif `RenderContext.loadConfig()` pour le profil OpenGL.

Le profil v1.15 reproduit donc les deux emplacements officiels. Ce ne sont pas
deux definitions concurrentes dans une meme section : elles alimentent les
deux etages de configuration du jeu.

## Symptome confirme

Avec `TypeClouds=1`, les cartes Slovakia et Smolensk en meteo brumeuse ont
produit de grands triangles ou pics blancs translucides. Certaines nappes
touchaient le sol, traversaient le relief et reapparaissaient selon le point de
vue.

Les journaux contiennent 21 occurrences de
`java.lang.RuntimeException: unknown exception in clouds`, au point d'appel
`com.maddox.il2.engine.EffClouds.PreRender`. La classe Java effective est
l'enveloppe 4.09m ; le rendu fautif se poursuit dans le moteur natif.

## Anciennes ressources (ne prouve pas la cause)

Le chemin actif `Files/Effects/clouds` provenait du vieux paquet
`RMP3_ZloyPetrushkO_Atm2_modv4_3_s`. Il melangeait notamment des materiaux
double face, un mipmap force, de longues distances et des textures modifiees.
Il etait la seule surcharge identifiee sur le chemin des nuages natifs.

Le second dossier `Files/3do/Effects/clouds` etait une copie rangee sous un
mauvais niveau. Le moteur 4.09m resout `Effects/clouds`, pas
`3do/Effects/clouds`. Cette copie ne constituait donc ni un profil de repli ni
une variante plus detaillee.

## Correction detaillee retenue

La v1.15 remplace les anciennes ressources visuelles de nuages par **WxTech clouds Jan 2023**, le paquet
cumulus complet le plus detaille retrouve :

- deux textures RGBA 1024 x 1024 pour le nuage detaille ;
- un materiau `Cloud4x4.mat` a deux couches, avec texture de volume et texture
  d'alpha distinctes ;
- une texture RGBA 256 x 256 pour les nuages simples ;
- un nouveau voile interieur RGBA 128 x 128 ;
- une geometrie `DATA.cld` plus riche et documentee par l'auteur ;
- aucun remplacement Java ou natif, donc aucun conflit de classe avec le moteur
  4.09m.

La [publication originale de WxTech](https://www.sas1946.com/main/index.php?topic=70195.0)
indique que le chemin correct est `Effects/Clouds` et que la copie `3do` de
l'archive est superflue. Une [discussion anterieure sur la meme architecture
Big Clouds](https://www.sas1946.com/main/index.php?topic=40413.24) rapporte son
fonctionnement de 4.09 a 4.12. Cela fournit une compatibilite structurelle
solide, mais pas encore la validation runtime Open Sturmovik.

Les huit fichiers actifs et l'empreinte de l'archive source sont figes dans
`manifests/effects/clouds-4.09m-v1.15.json`. Trois auxiliaires de travail du
moddeur, non references par les materiaux, ne sont pas livres. Les six fichiers
du faux chemin `Files/3do/Effects/clouds` et les deux restes incompatibles de
l'ancien paquet sont retires.

Ce retrait ne constitue pas une desinstallation de tout le module Atmosphere :
celui-ci ne se limitait pas aux nuages. Les classes de vent et de vol IA
WindConfig_v3 restent presentes. La preservation des anciens fichiers et les
limites d'attribution sont detaillees dans
[RMP3_ATMOSPHERE_PRESERVATION.md](RMP3_ATMOSPHERE_PRESERVATION.md).

Les nuages stock du `files.SFS` 4.09m restent le temoin stable A/B. Ils ne sont
pas la correction retenue, car leur rendu est moins detaille.

## Validation finale a effectuer

### Retour positif du 6 septembre au soir

Alexis confirme « nuage fonctionne et MAGNIFIQUE » apres le lancement
`20260906-175627Z-profile8-warm-configured-display-startup`. Le journal final
confirme DirectX8 via `dx8wrap.dll`, avec missions Slovakia puis Smolensk et
zero occurrence de `unknown exception in clouds`. Les ressources WxTech sont
conservees. Le rendu est valide pour cet essai ; la comparaison A/B mesuree et
la generalisation a toutes les meteo restent distinctes. Details dans
`ESSAI_V1.15_2026-09-06_SOIR.md`.

### Piste Intel OpenGL et comparaison reversible du 6 septembre

Le journal de la copie de test identifie `Opengl32.dll`, Intel UHD Graphics 620,
pilote `31.0.101.2141`. Des pics restent observes avec WxTech : le remplacement
des textures ne suffit donc pas a accuser ou innocenter RMP3.

La [discussion SAS « Spiky clouds »](https://www.sas1946.com/main/index.php?topic=57847.0)
associe un symptome comparable a Intel/OpenGL et propose un GPU dedie ou
DirectX. [Mission4Today « Clouds Strange »](https://www.mission4today.com/index.php?file=viewtopic&name=ForumsPro&t=16639)
decrit egalement des nuages cristallins. C'est une piste a tester, pas une
correction visuelle deja validee. AAA/Wayback reste inaccessible.

`Config.loadEngine(String)` en 4.09m selectionne `Render_DirectX` lorsque
`GLPROVIDER/GL` correspond a `GLPROVIDERS/DirectX` ; sinon il selectionne
`Render_OpenGL`. Le profil prepare utilise le `dx8wrap.dll` original 4.09m,
SHA-256 `A4DB066DAB59C6CF5AF1D7F01643FC83BB29D00FD1DCA177F6CAF99FFB7027FA`,
avec WxTech et `TypeClouds=1` conserves. Aucun changement de `UseAlpha`, de
texture, de geometrie ou de physique atmospherique n'est effectue.

`tools/Set-OpenSturmovikGraphicsBackend.ps1 -GameRoot <copie> -Backend DirectX
-Apply` prepare ce candidat et sauvegarde le conf.ini precedent. Sans `-Apply`,
il ne fait qu'annoncer les changements. `-Backend OpenGL -Apply` permet de
revenir au fournisseur natif, en conservant les reglages OpenGL precedents.
Les deux choix restent disponibles ; le jeu n'est jamais lance par cet outil.

La comparaison prioritaire porte sur **la meme mission et les memes nuages**
en DirectX puis OpenGL. La voie DirectX reste Excellent, pas Perfect. Le detail
visuel et les performances doivent etre compares avant toute decision finale.

La copie de test ne doit etre synchronisee qu'apres la fin des travaux hors
jeu. La campagne finale utilisera exactement la meme mission, la meme meteo et
le meme point de vue :

1. WxTech avec `TypeClouds=1` sur Smolensk puis Slovakia ;
2. WxTech avec `TypeClouds=0` comme controle du chemin simple ;
3. IL-2 4.09m stock avec la configuration equivalente comme reference visuelle
   et de performance.

Le candidat ne sera valide que si les quatre conditions sont reunies :

- aucun polygone blanc, nuage au sol anormal ou erreur
  `unknown exception in clouds` ;
- detail, profondeur et eclairage visiblement superieurs au stock ;
- frequence d'images acceptable dans la mission dense ;
- marge memoire suffisante dans le processus 32 bits.

`TypeClouds=0` ne doit pas devenir la correction definitive du profil de
realisme maximal.
