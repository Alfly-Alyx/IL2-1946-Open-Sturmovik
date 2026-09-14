# Verification du switcher et preparation du test — 7 septembre 2026
> **Mise a jour du 13 septembre 2026.** L'incompatibilite de demarrage decrite ci-dessous a ete corrigee par un registre `Plane` propre a chaque profil. Les profils modifies 2, 5 et 8 ont chacun conserve une fenetre `Open Sturmovik` active pendant 15 secondes. Le detail reproductible et les deux empreintes se trouvent dans `CORRECTION_SWITCHER_V1.15.md`. Les paragraphes suivants restent un historique de l'etat du 7 septembre.

> **Perimetre historique avant le retrait du 12 septembre 2026.** Les constats,
> empreintes, listes de fichiers et commandes lies a MDS, DCG, San FOV ou Malta
> ci-dessous decrivent l'etat observe a leur date, pas le contenu cible actuel.
> MDS est desormais retire localement ; voir [le suivi courant](RETRAIT_COMPOSANTS_V1.15.md)
> et [la reconstruction AOC sans MDS](AUDIT_AOC_SANS_MDS_20260912.md).
> Les anciens constructeurs et pieces retires sont conserves dans les archives
> externes identifiees par ce suivi ; ne pas reinstaller leur contenu.

Etat historique avant correction. Voir maintenant `CORRECTION_SWITCHER_V1.15.md`
pour le registre beta distinct, la memorisation et la restauration corrigees.

## Resultat et perimetre

La copie de test est remise sur **4.09m modifie sans 6DOF, HUD standard**.
Aucun jeu, HTA, outil de capture ou enregistreur n'a ete lance pendant cet audit.
Le contenu runtime du depot n'a pas ete modifie. Branche conservee : `v1.15`,
HEAD examine : `544e57b799782ffe7153279ddfca22cb926f1e6b`.

**La commutation des fichiers passe ; la compatibilite globale du switcher
n'est pas validee.** Le profil 4.09b modifie presente une incoherence de registre
demontree ci-dessous. Le choix HUD immersion en Original reste trompeur tant
que son chargement n'est pas etabli. Ne pas presenter le succes des copies
comme une preuve de fonctionnement en jeu.

Copie preparee :
`C:\Users\Alexis\DATA\Projets\GITHUB\IL2-1946-Open-Sturmovik\WIP\tests\installations\IL 2 Sturmovik 1946 test`.

Sauvegarde recuperable des quatorze fichiers actifs, journaux des appels et
rapport mesure : `WIP/tests/installations/switcher-matrix-20260907-081003/`.
Le fichier `result.json` donne 18 cas PASS, les deux controles `keep`, les
arguments invalides refuses et la preservation de 29 fichiers surveilles
(configuration, Users, AOC de test et fichiers actifs du depot).

Une premiere tentative de l'outil d'audit avait echoue avant execution du BAT
sur l'echappement du chemin avec espaces. Son rapport FAIL est conserve sous
`switcher-matrix-20260907-080743`. Les quatorze empreintes actives etaient
inchangees. Cette tentative n'est pas comptee comme un test du switcher.

## Controles passes, hors jeu uniquement

- Classement et noms : 11 tests de regression PASS ; 535 / 516 / 535 entrees
  preservees. Les cinq fichiers de la derniere synchronisation des noms ont
  exactement leurs empreintes attendues dans le depot et dans le test.
- CW-21 : le vrai bytecode d'enregistrement et d'import tardif passe le test
  anti-doublons. Trois choix uniques, quatre points d'armes, calibres et
  munitions attendus ; les deux classes corrigees sont identiques dans le test.
  Cela ne valide ni le menu visible, ni le tir, ni le volume moteur.
- Interface : les neuf choix version/mode correspondent aux neuf profils.
  Les 27 transmissions de choix (neuf profils fois standard/immersion/keep)
  passent dans un environnement JavaScript inerte, sans ActiveX ni fenetre.
- Les 18 appels reels du BAT dans la copie de test (neuf profils fois deux
  HUD) passent. EXE, files.SFS, wrapper, sept ou quatre fichiers de version,
  air.ini, stationary.ini et fichier HUD sont verifies apres chaque copie.
- Les trois profils Original retirent le wrapper ; le profil 1 retire en plus
  les trois archives 4.09. Les appels suivants restaurent les fichiers requis.
- Les EXE avec et sans 6DOF sont distincts. Les instructions aux offsets
  `0xF205`, `0xF282` et le bloc de 46 octets a `0x1B820` correspondent au
  differentiel AAA documente dans `manifests/profiles-6dof-v1.15.json`.
- `keep` preserve chacun des deux fichiers HUD lors du passage 9 vers 8.
  Les arguments invalides sont refuses sans modification des fichiers actifs.
  Aucune transaction temporaire n'est restee apres la sequence.
- Preparation generale du depot : 6 PASS ; contenu : 25 PASS, 1 WARN, 0 FAIL.
- Preparation finale du test, profil 8 : 42/42 controles passes **avec la seule
  exception AOC historique**. Contenu : 24 PASS, 1 WARN (pas de nouveau dump),
  1 FAIL connu (cinq profils AOC de test au lieu des 266 du paquet).
  Les cinq profils AOC et les profils joueur sont preserves, pas remplaces.

Rapports de preparation :
`WIP/tests/plans/switcher-final-readiness-20260907.json` et `.content.json`.
Le controle de presence des outils de trace ne les execute pas.

## Matrice reellement appliquee

Les deux HUD ont ete copies et verifies pour chaque numero ci-dessous.
Les colonnes registres decrivent les fichiers libres, pas ce que le stock
charge depuis ses propres SFS.

| Version affichee | Original | Mod sans 6DOF | Mod avec 6DOF | Ressources moteur/cartes | air.ini libre | stationary.ini libre |
| --- | ---: | ---: | ---: | --- | --- | --- |
| 4.08m | 1 | 2 | 3 | 4.08m pour 1 ; **4.09b pour 2/3** | 4.08, 516 entrees | 4.08/4.09b |
| 4.09b | 4 | 5 | 6 | 4.09b | **4.09m, 535 entrees** | 4.08/4.09b |
| 4.09m | 7 | 8 | 9 | 4.09m | 4.09m, 535 entrees | 4.09m |

### 4.09b : incoherence demontree, confiance elevee

Les profils 5/6 selectionnent `409m air.ini`, alors que leur `files.SFS` reste
la beta. L'indexation locale de 2 465 classes libres (zero erreur de lecture),
du SFS de chaque profil, des 48 SFS communs de l'installation de test et des
trois SFS de son payload ne trouve pas les classes de 18 entrees de ce registre :

```text
DXXI_DK, DXXI_DU, I-15bis, I-15bis_Skis,
I-16type5_Skis, I-16type5_SPB, I-16type6, I-16type6_Skis,
AviaB534, G-55, G-55-Late, DXXI_SARJA3_EARLY,
DXXI_SARJA3_LATE, DXXI_SARJA4, S-328, RE-2000, SM-79, Sarvanto_DXXI
```

Le CW-21 a une classe libre mais les dependances `CW21xyz` et
`PaintSchemeFMPar00du` ne sont pas trouvees dans cet ensemble 4.09b.
Elles sont disponibles avec les ressources 4.09m. Le numero 6 partage le SFS,
le wrapper et les registres du numero 5 ; changer le seul EXE pour le 6DOF
ne fournit pas ces classes manquantes.

Deduction : ce registre ne permet pas de qualifier 4.09b comme profil modifie
complet. La forme exacte de l'erreur au chargement n'a pas ete observee dans
ce test sans jeu. La correction doit traiter explicitement le registre et les
dependances propres a 4.09b ; ne pas recopier arbitrairement les classes 4.09m,
ni retirer des entrees de la liste 4.09m pour masquer le probleme.
Aucun de ces fichiers n'est change par cet audit.

L'analyse des profils 2/3 et 8/9 trouve respectivement les 516 et 535 classes
d'avions declarees. Elle releve cependant dans les trois versions une reference
non resolue de `X_86` vers `MIG_15SV`, pour F-86-A5/F1/F30. C'est un signal
statique, pas un crash reproduit : le chemin conditionnel qui l'utilise reste
a examiner. Le test CW-21 prepare n'est pas remplace par un essai F-86.

### 4.08 modifie : assemblage historique, pas 4.08 pur

Fait verifie : les choix 2/3 installent les DLL et archives 4.09b, avec le
files.SFS et le registre du profil 4.08 modifie. Ce choix est explicite dans le
BAT et le manifeste courant. Les anciens BAT de la ressource locale AAA 1.1
ne copiaient que le dossier du profil au-dessus du pack ; ils ne remettaient
pas les DLL et cartes d'une installation 4.08 pure. Voir `AUDIT_PROFILES.md`
et `MATRICE_VERSIONS_SFS.md` pour les empreintes et la provenance.

La compatibilite de tous les mods v1.15 avec cet assemblage reste inconnue.
L'absence de classe d'avion manquante ne prouve pas celle de signatures Java,
maillages, FM ou appels natifs incompatibles. Le texte de la GUI gagnera a
nommer cet assemblage historique au lieu de laisser entendre du 4.08 pur.

### HUD : fichier remplace versus affichage effectif

Faits verifies : les choix standard et immersion remplacent seulement
`Files/i18n/hud_log_ru.properties`. Le premier contient notamment les messages
de mission en francais ; le second masque MissionComplete/MissionFailed et
adapte les annonces de destruction. Ce n'est pas un remplacement de toute
la classe HUD, ni une modification globale du compteur vitesse/altitude.

Le mode Original retire le wrapper qui active l'arbre libre des mods ; pourtant
la GUI laisse choisir immersion et le BAT annonce la copie comme reussie.
**Cette copie ne prouve pas l'activation du HUD immersion en stock.** D'apres
l'architecture de chargement locale, il faut s'attendre au HUD du jeu stock,
pas a celui de l'arbre libre. Cette deduction n'a pas fait l'objet d'un nouvel
essai visuel. Il faudra clarifier ce choix dans l'interface ou etablir une
solution compatible avant de le promettre a l'utilisateur, sans transformer
silencieusement le mode stock en mode modde.

Deux autres limites de presentation : `keep` ecrit `hud=keep` dans l'etat au
lieu de nommer le fichier conserve ; la GUI affiche le profil actif en texte
mais ne recale pas ses boutons sur cet etat a la reouverture. Les controles
effectues n'ont pas modifie ces comportements.

## Reproduction sans jeu ni capture

Depuis le depot v1.15, avec Node.js, Python et Java disponibles :

```powershell
python tools/Test-AircraftNameReview.py
node tools/Test-SwitcherGui.cjs
python tools/Audit-SwitcherClassAvailability.py --game-root "WIP/tests/installations/IL 2 Sturmovik 1946 test" --output WIP/tests/plans/switcher-class-availability-20260907-full-sfs.json
```

Le rapport statique detaille les noms internes et les 48 archives communes.
L'outil retourne 1 lorsqu'une classe d'avion declaree manque (cas 4.09b actuel),
et distingue les references directes non resolues par un WARN.
Il ne s'appuie pas sur un dump 4.09m pour certifier 4.08/4.09b. Methode :
adresses de classes `Finger(cod/Finger.Int(sdw<classe>cwc2w9e))` dans la table
SFS, puis recherche des references directes des classes libres et de leurs
superclasses libres. Ce n'est pas un test exhaustif du lieur JVM ou du moteur.

`Test-SwitcherTransactions.ps1` exige des chemins absolus `-RepositoryRoot` et
`-GameRoot`. Sans `-Apply`, il ne fait que son precontrole. Avec `-Apply`, il
exerce les 18 commutations, les controles keep et les retours supplementaires.
Il refuse une autre branche ou une autre installation, exige initialement le
profil 8/HUD standard, sauvegarde les quatorze fichiers et les restaure en cas
d'echec. Les remplacements d'EXE peuvent necessiter l'autorisation du bac a sable.
Il ne lance jamais l'entree graphique sans arguments.

Le test CW-21 est reproduit avec la commande Java du document
`CW21_DUPLICATE_LOADOUTS_V1.15.md`. La derniere preparation utilise
`Test-IL2StartupReadiness.ps1 -Profile 8 -ExcludeNuclear` avec les chemins
absolus du depot/test et `-AllowedContentFailures 'AOC 1a + Zuti 1.13'`.
Sans cette exception precise, ne pas annoncer un contenu de distribution valide.

## Sources et acces

Priorite donnee aux fichiers du depot et a la ressource locale
`D:\Projets\GITHUB\#res\IL2 1946\Packs\AAA_Community_Installer_ver_1_1` :
BAT 4.08/4.09, dossiers de profils, fichiers HUD et sources cites dans le
manifeste. Aucun nouveau fichier communautaire n'a ete integre.

- [AAA / Wayback, archive 2010](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/)
  et archive 2008 du sujet 1932 : acces indisponible pendant la recherche ;
  aucun contenu suppose. La copie locale AAA reste la preuve exploitable.
- [Guide de patchs Mission4Today](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1),
  consulte : distingue les etapes officielles 4.08m puis 4.09m ; ne qualifie pas
  l'assemblage modifie particulier de ce depot.
- [Guide SAS UltraPack 2.0, decembre 2009](https://www.sas1946.com/main/index.php?topic=2652.0),
  resultat indexe consulte : rappelle que 4.09m et 4.09b1m sont distincts.
  [Guide SAS Mod Activator](https://www.sas1946.com/main/index.php?topic=5310.0) :
  extrait indexe accessible mais ouverture directe refusee (403).
  Aucun de ces guides ne remplace le controle des classes propres au pack.

## Prochaine session utilisateur, pas de lancement automatique

1. Rester en profil 8 / 4.09m pour les premiers essais. Dans **Editeur de
   missions rapides**, pas Mission simple, verifier le classement et les trois
   choix uniques du CW-21. Essayer les deux armements en cockpit. Le son faible
   du CW-21 reste un diagnostic ouvert.
2. Jeu ferme, comparer les HUD standard/immersion dans ce meme profil puis
   revenir au standard. Comparer une meme situation declenchant un message ;
   l'absence d'un message de mission dans immersion peut etre volontaire.
3. Comparer 8 et 9 avec un dispositif TrackIR : rotation, translation, recentrage
   et retour a 8. L'integrite des EXE ne remplace pas ce test materiel.
4. Le mode Original doit conserver son titre et son contenu stock. Fermer le
   jeu avant toute commutation. Reporter les essais des avions en 4.09b modifie
   jusqu'au traitement du registre incompatible ; ne pas utiliser ce profil
   pour qualifier les 535 avions 4.09m. Les autres essais historiques ne seront
   pas marques valides avant leur execution.

Les acquis utilisateur (KB-29P, nuages, titre modifie, perte de focus) restent
conserves. Aucune capture ni lancement n'est programme par cette preparation.
