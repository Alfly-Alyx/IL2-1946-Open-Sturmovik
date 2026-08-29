# Wrapper cache 4.09m

Cette variante 32 bits conserve la priorite `Mods`, puis `Files`, et les deux
exports attendus par l'EXE modde 4.09m. Elle n'execute aucune indexation dans
`DllMain` : l'initialisation est differee jusqu'au premier appel SFS.

Le cache se trouve dans `.open-sturmovik-cache`. Une paire `*.cache` / `*.dirs`
est acceptee uniquement si son en-tete, sa fin, son nombre d'entrees et tous les
horodatages de dossiers concordent. Ajouter, supprimer ou renommer un fichier
modifie l'horodatage de son dossier parent et force donc une reconstruction.
Modifier seulement le contenu d'un fichier ne change pas son chemin ni son hash
SFS et ne rend pas l'index perime.

La DLL reste experimentale tant qu'elle n'a pas ete validee par un lancement du
jeu et une mission de test. `Build-Wrapper.ps1` exige une chaine LLVM-MinGW
portable et ne l'installe pas sur le poste.

Le banc hors jeu sur les 89 738 fichiers reels mesure 1 890,2 ms a froid et
473,4 ms avec le cache valide. Ces temps incluent l'hote de test et ne doivent
pas etre presentes comme le temps de demarrage complet du jeu.

Source amont : [Selector 3.3.0 sur SourceForge](https://sourceforge.net/p/il2selector/code/HEAD/tree/trunk/3.3.0/).
