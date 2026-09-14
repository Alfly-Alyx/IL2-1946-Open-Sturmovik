# Protocole A/B des particules nucleaires — v1.15

## Objectif

Ce banc determine le comportement du moteur 4.09m lorsque le nombre maximal de
particules simultanees est atteint. Il repond a une question unique : le moteur
recycle-t-il, ecrase-t-il ou bride-t-il les particules pendant une emission
longue ? Le resultat servira a dimensionner le futur rendu nucleaire par phases
sans gaspiller la memoire x86.

Ce n'est pas un effet destine a la version livree. Il ne s'active que si le
fichier `_OS_TEST_NUCLEAR_PARTICLE_AB.enabled` existe a la racine du jeu.

## Construction de l'essai

Lors d'une detonation nucleaire, les six effets Silverplate habituels sont
immediatement arretes et deux emetteurs experimentaux apparaissent a la meme
altitude :

| Sonde | Couleur | Position relative | `nParticles` |
| --- | --- | ---: | ---: |
| A | rouge | 750 m a l'ouest | 64 |
| B | bleu | 750 m a l'est | 512 |

Toutes les autres valeurs physiques sont identiques : emission de 100
particules/s pendant 180 s, `LiveTime=128`, meme taille, meme vitesse, meme
matiere et aucun vent. Les couleurs servent uniquement a distinguer les deux
sondes.

Le journal inscrit des points de controle a 10, 60, 120, 130, 150, 180, 240 et
300 secondes simulees. Les deux acteurs sont detruits et leurs references
liberees a 310 secondes.

## Essai en jeu

1. Utiliser Smolensk, le B-29 Silverplate et Little Boy a 5 000 m.
2. Larguer sans mettre le jeu en pause et garder les deux sondes dans le champ.
3. Observer la continuite, la densite et les eventuelles pulsations rouge/bleu.
4. Accelerer le temps seulement apres le point de 10 s.
5. Revenir a la vitesse normale autour des points 120, 130, 150, 180, 240 et
   300 s lorsque l'operateur de capture le demande.
6. Attendre le message de nettoyage a 310 s, revenir au menu puis quitter.

Interpretation :

- si les deux sondes restent continues jusqu'a 180 s, les slots sont recycles ;
- si la rouge pulse ou perd nettement sa densite avant la bleue, la capacite
  tronque l'historique visuel ;
- si elles disparaissent vers 129/133 s puis reviennent, le pool attend la mort
  des anciennes particules avant de reutiliser les slots ;
- leur disparition progressive apres 180 s doit se terminer au plus tard vers
  308 s.

## Securite et retour arriere

`tools/Install-NuclearParticleABProbe.ps1` refuse explicitement le dossier du
jeu original et exige un nom de cible contenant `test`. L'option `-Disable`
retire le marqueur apres l'essai. Les deux fichiers `.eff` inertes peuvent
rester dans la copie de test, mais le marqueur ne doit jamais etre distribue
avec Open Sturmovik.

La construction doit obtenir 18/18 au cycle nucleaire et 8/8 au controle du
banc A/B avant toute copie. Le dossier de test ne doit etre modifie qu'apres une
sauvegarde transactionnelle, et le jeu ne doit etre lance qu'apres avertissement
explicite d'Alexis.

## Etat de preparation du 3 septembre 2026

- cycle nucleaire : 18/18 PASS ;
- controle du banc : 8/8 PASS, y compris resolution du materiau ;
- audit nucleaire statique : 41/41 PASS ;
- contenu du dossier de test : 19 PASS, 2 avertissements connus, 0 echec ;
- preparation du profil 9 fenetre 1 024 x 768 : 47/47, `Ready=True` ;
- sauvegarde :
  `C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\backups\IL 2 Sturmovik 1946 test.nuclear-particle-ab-backup-20260903-142012Z` ;
- ressources corrigees redeployees :
  - A : `AD45E9925A63FFA70C28FE40C8EE23B4C65CD99E7921FB202290ED53B7E88850` ;
  - B : `88D062389657CB18A1CB25F34CE654F64B8023E8938D3ABF106B8BF3642A556A` ;
- lancement du banc corrige : reussi, puis marqueur retire.

## Premier essai invalide a 13 h 47 UTC

Le premier largage n'a montre que le flash et le front de choc, sans les deux
sondes ni le champignon normal. Le masquage des effets Silverplate prouve que le
mode A/B etait actif. Les deux `.eff` utilisaient toutefois
`../../Fireworks/TEXTURES/SmokeN.mat` depuis
`3do/Effects/OpenSturmovikTest`, ce qui resolvait a tort vers
`3do/Fireworks/TEXTURES`.

Cette session ne fournit donc aucune information sur le recyclage des
particules. Elle est conservee comme validation du marqueur et du chemin de
neutralisation.

## Deuxieme essai invalide a 14 h 11 UTC

La capture
`WIP/tests/captures/startup/20260903-141052Z-profile9-warm-windowed1024-startup`
contient 3 758 images sur 431 secondes. Le second largage a encore montre le
flash et le front de choc sans aucune sonde. Le premier correctif
`../Fireworks/TEXTURES/SmokeN.mat` resolvait en realite vers le sous-dossier
inexistant `3do/Effects/Fireworks/TEXTURES`.

Le journal confirme le diagnostic a `14:17:07` : deux erreurs
`Can't open file '3DO/Effects/Fireworks/TEXTURES/SmokeN.mat'` encadrent la
creation des deux effets, puis `particle-probe-start` indique bien deux acteurs
actifs. L'activation Java fonctionne donc ; seul le chargement du materiau
echouait.

La ressource libre se trouve dans `3do/Effects/Textures/SmokeN.mat`. Le chemin
correct depuis `3do/Effects/OpenSturmovikTest` est donc
`../Textures/SmokeN.mat`. Le controle automatise resout maintenant chaque
`MatName` comme le ferait l'arborescence du jeu et exige que le fichier cible
existe. Il obtient 8/8 avant le prochain lancement.

## Troisieme essai valide a 14 h 25 UTC

La capture
`WIP/tests/captures/startup/20260903-142458Z-profile9-warm-windowed1024-startup`
contient 4 884 images sur 561,5 secondes. La detonation intervient a
`14:29:32`. Les deux sondes sont visibles et aucune erreur de ressource
n'apparait dans le journal.

La densite initiale parait voisine, mais la sonde rouge limitee a 64 particules
s'estompe puis disparait avant la sonde bleue limitee a 512. Les deux sondes ont
reapparu ensemble une seule fois apres un retour vers la fenetre Codex. Ce point
reste compatible avec un culling ou rechargement lie a la perte de focus ; il
n'est pas produit par le prototype, qui termine avec `rehydrates=0`.

Le moteur atteint les huit checkpoints jusqu'a 300 secondes. A 310 secondes,
le nettoyage donne `actors=0`, `created=8`, `destroyed=8` et `ticks=310`. Aucun
echantillon `Responding=False` n'apparait entre la detonation et la fermeture.
Le marqueur A/B est retire apres la capture.

Decision de conception :

- ne pas employer 64 particules pour la tete, le tore ou la colonne principale ;
- employer au plus 512 particules sur un nombre limite de couches majeures ;
- realiser les transitions avec des phases bornees et une vidange naturelle ;
- ne pas detruire un acteur a une echeance ou ses particules restent visibles ;
- qualifier separement la perte de focus, la pause et le culling de la camera.
