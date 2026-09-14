# Controls et Explosions sans MDS — 12 septembre 2026

Cette reconstruction ciblée conserve les apports indépendants des classes
mixtes de la branche `v1.15`. Les résultats ci-dessous sont des preuves de
bytecode et des tests ciblés. Ils ne remplacent pas une qualification en jeu
du retrait de MDS et de toutes ses autres familles.

## Sources vérifiées

Priorité aux ressources locales et aux fichiers effectifs du pack. Aucun code
de forum ni fichier d'une version différente n'a été intégré. La recherche
historique AAA/Wayback, Mission4Today et SAS et ses limites sont consignées dans
[l'audit du retrait](AUDIT_RETRAIT_ZUTI_V1.15_20260912.md).

| Entrée | SHA-256 |
| --- | --- |
| `Files/34B2D47E9F860052` — Controls initial | `FD7983C25155A9DEA555D0B87ECD507BD0680A052A227CE524F65828EAFF1667` |
| `Files/72DCDDF4D2AD25E8` — Explosions initial | `24CCB92F1AD8BCAD777CAF03B9357CD7756E3E1248986A2C3B7FD317DDD2CF9A` |
| Explosions du SFS 4.09m ON vérifié | `1D5AAA0B19AED7BA95C4B0122C5B277712BF38E3F0CCA5307724A22DC4917891` |
| Controls reconstruit | `10A83C20736127AB46387C448936BC6F09410A1F996514148B401F423D0BF136` |
| Explosions reconstruit | `66C9816220AD8942B06FF41F1CD846AF6FFA35DA9F5A57BA6ED26E10CBF6CCD2` |

Les deux entrées initiales sont conservées sous leurs chemins `Files/...` dans
`D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence\Zuti MDS 1.13\sauvegarde_partielle_20260912`.
Cette sauvegarde représente une intégration partielle et fusionnée, pas un
paquet MDS complet. Ses deux copies ont été revérifiées par SHA-256.

## Changements observables — confiance élevée

Controls perd cinq méthodes privées de traitement/notation du largage de fret,
le champ `ZUTI_PROCESS_CARGO_DROPS`, son initialisation et l'unique appel depuis
`update`. Le calcul de son argument est retiré aussi : aucun appel `toString`
inutile ne reste dans la boucle d'armes. Les autres instructions de cette
boucle sont conservées, notamment les appels `shots`, les soutes et
l'alternance des bombes et roquettes du Mustang. Les 64 autres méthodes sont
identiques après sérialisation canonique ASM. Tous les autres champs sont
conservés, dont `bMoveSideDoor`, `bHasBayDoors` et les positions mémorisées.
La méthode publique `setActiveDoor(int)` demeure inchangée.

Explosions retrouve une durée de cratère de 80 secondes dans `fontain` et
600 secondes dans `bomb1000_land`. La sélection par catégorie et les accès aux
réglages de mission MDS disparaissent. Le calcul abandonné du cratère nucléaire
est supprimé ; aucun cratère nucléaire n'est réactivé. Les surcharges de
`generate`, les effets Silverplate, la mise à l'échelle par puissance et
l'ensemble du cycle `NuclearBlast` sont conservés. Les 63 autres méthodes
sont identiques après sérialisation canonique ASM.

La méthode `fontain` reconstruite est identique à celle du SFS 4.09m après
une renumérotation bijective de deux variables locales : le compilateur du
SFS utilisait les emplacements 9/10 pour le rayon du cratère/de la lumière ;
la classe libre emploie les emplacements 10/9. Aucun autre opcode, constante,
appel ou branche n'est normalisé pour ce contrôle. La décompilation CFR 0.152
des deux méthodes produit également le même texte.

Les pools de constantes sont reconstruits, afin de supprimer les références
inutilisées. Aucun octet correspondant à `Zuti` (sans distinction de casse)
ne subsiste dans les deux sorties. La version ClassFile historique est
conservée : Controls 45.3, Explosions 47.0, compatibles avec Java 1.3.

## Reproduction et contrôles

Le correctif se trouve dans
[`OpenSturmovikControlsExplosionsPatcher.java`](../tools/java/OpenSturmovikControlsExplosionsPatcher.java),
le test dans
[`TestControlsExplosionsNoMds.java`](../tools/java/TestControlsExplosionsNoMds.java).
Le constructeur
[`Build-OpenSturmovikControlsExplosionsPatch.ps1`](../tools/Build-OpenSturmovikControlsExplosionsPatch.ps1)
ne possède aucune option d'installation. Il exige un dossier de sortie hors
du dépôt partagé et contrôle les empreintes des sources.

1. Avec `SfsArchive.extract_class` de `tools/Analyze-Sfs.py`, extraire
   `com.maddox.il2.objects.effects.Explosions` du SFS
   `_Game Switcher/4.09m Mods ON (NO 6DOF)/files.SFS`, dont le SHA-256 est
   `5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71`,
   vers un fichier de travail sous `C:\Users\Alexis\.codex`.
2. Appeler le constructeur avec `-RepositoryRoot` désignant le dépôt,
   `-SourceRoot` désignant la sauvegarde partielle ci-dessus,
   `-StockExplosions` désignant le fichier extrait, et `-OutputRoot` désignant
   un dossier de travail sous `.codex`. Un JDK 17 avec `java` et `javac` est
   nécessaire ; le constructeur utilise l'ASM interne livré avec ce JDK.
3. Vérifier `manifest.json` et les deux candidats de `files-staging`. Les
   empreintes attendues figurent dans le tableau ci-dessus.

Contrôles exécutés avec succès : analyse ASM `BasicVerifier` de toutes les
méthodes, égalité canonique des méthodes non concernées, préservation des
champs hors MDS, absence de constantes MDS et idempotence du nettoyage
d'Explosions. Le test JVM exécute le vrai bytecode `setActiveDoor` dans une
classe isolée munie de ses seuls champs nécessaires ; il couvre l'aller-retour
porte latérale/cockpit, les sélections répétées et la mémorisation des
positions. Il ne charge pas le moteur natif.

Le constructeur nucléaire nettoie maintenant l'entrée mixte reconnue avant
reconstruction, puis contrôle encore sa sortie. Un donneur ne peut ainsi
réintroduire les dépendances MDS. Son exécution sans `-Install` a produit
13 classes : 12 strictement identiques aux classes actives initiales, et
Explosions strictement identique au candidat sans MDS ci-dessus.

Restent à qualifier avec l'ensemble reconstruit : démarrage, missions, IA,
réseau, portes/soutes, tirs et effets nucléaires sur les profils distribués.
Les tests isolés ne prouvent ni le comportement complet du moteur ni la
compatibilité de toutes les autres classes remplacées par le retrait MDS.
