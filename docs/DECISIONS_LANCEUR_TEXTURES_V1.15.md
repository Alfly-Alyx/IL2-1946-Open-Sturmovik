# Decisions v1.15 : nucleaire, lanceur et textures

Derniere mise a jour : 2 septembre 2026.

> Actualisation du 12 septembre : les resultats MDS ci-dessous sont historiques.
> MDS est retire du contenu local et AOC conserve ses dix reglages sans MDS ;
> voir [le suivi courant](RETRAIT_COMPOSANTS_V1.15.md) et
> [la reconstruction AOC](AUDIT_AOC_SANS_MDS_20260912.md). Les essais reels du jeu
> et de l'installateur restent a refaire apres les controles statiques passes.

## Decision de version

La v1.15 doit rester une version 4.09m stable. Le correctif nucleaire est un
bloquant de cette version, car il corrige un gel et une incoherence visuelle
deja reproduits. Le lanceur complet et la modification profonde du chargement
des textures ne doivent pas retarder cette stabilisation.

| Chantier | Cible recommandee | Condition |
| --- | --- | --- |
| Cycle nucleaire borne | v1.15 | validation locale complete, puis reseau |
| Socle et apercu du lanceur | v1.15 si sans impact sur la date | reste separe et clairement marque comme apercu |
| Remplacement final `il2setup.exe` | version suivante, recommandee v1.16 | application Windows autonome, transactions multi-fichiers et restauration validees |
| Cache de noms du wrapper | v1.15 seulement s'il passe l'A/B | gain median d'au moins une seconde, zero regression |
| Cache de conversion ou d'envoi GPU | version suivante | instrumentation native et budget x86 obligatoires |
| Repaquetage SFS pour accelerer les textures | hors v1.15 | preuve de gain et matrice de compatibilite avant toute adoption |

## Le lanceur peut-il remplacer `il2setup.exe` ?

Oui techniquement. `il2setup.exe` est un configurateur externe qui lit
`il2setup.ini` et ecrit `conf.ini`. Aucune reference a son nom n'a ete trouvee
dans l'executable de jeu 4.09m inspecte. Le jeu consomme la configuration
produite ; il n'exige donc pas que le remplacant reproduise le code de l'ancien
programme. Conserver le nom `il2setup.exe`, ses effets sur `conf.ini` et son
catalogue de profils suffit pour la facade de compatibilite connue.

Ce remplacement n'est cependant pas pret a etre livre dans la v1.15 actuelle.
La branche `launcher` contient une bonne fondation : manifestes, resolveur,
catalogue des 39 profils historiques, 282 commandes, ecriture transactionnelle
de `conf.ini`, sauvegarde hors du jeu, diagnostic et huit tests reussis. Elle ne
contient pas encore l'application Windows WPF autonome ni le fichier final
`il2setup.exe`.

Avant de remplacer le binaire historique, il reste au minimum a :

1. creer l'application .NET autonome et son interface non technique ;
2. rendre obligatoire l'empreinte de l'etat attendu avant toute ecriture ;
3. etendre la transaction a `files.SFS`, `il2fb.exe`, `wrapper.dll`, `air.ini`,
   `stationary.ini`, `conf.ini` et aux commandes du pilote ;
4. prouver la restauration apres une panne provoquee au milieu de chaque etape ;
5. detecter CPU, GPU, VRAM, OS x86/x64, joysticks, TrackIR et 6DOF ;
6. appliquer la politique speciale du jeu original : aucun `wrapper.dll` et
   retrait transactionnel d'un wrapper laisse par un profil modde ;
7. integrer le mode serveur, le testeur de joystick et les profils graphiques ;
8. publier et tester un executable autonome sur Windows 32 bits et 64 bits ;
9. conserver l'ancien configurateur sous sauvegarde recuperable lors de
   l'installation, sans jamais l'ecraser silencieusement.

Conseil de sortie : livrer Open Sturmovik v1.15 sans rendre ce lanceur
obligatoire. Si l'application finale passe toute cette liste avant la
stabilisation, elle pourra etre incluse comme composant optionnel de v1.15 ;
sinon le remplacement officiel doit viser v1.16. La qualite du jeu ne doit pas
dependre d'un lanceur encore incomplet.

## Chargement des textures : ce qui entre dans la v1.15

Les mesures disponibles montrent environ 26 secondes pour un premier
chargement de mission contre 6 secondes pour le second. La pile native place le
fil principal dans la conversion des bitmaps puis `glTexImage2D`. Le cout vient
donc surtout de la lecture, de la conversion et de l'envoi des textures, pas
seulement de la recherche parmi les 89 738 fichiers libres.

Le cache experimental du wrapper reduit l'enumeration isolee de 1 890,2 ms a
473,4 ms, soit 1 416,8 ms de gain. Ce resultat justifie un essai A/B dans le
jeu, mais pas son activation par defaut sans mesure runtime et sans invalidation
fiable.

Perimetre v1.15 recommande :

- conserver `TexCompress=2`, les mipmaps et la haute qualite securisee x86 ;
- comparer trois lancements froids et trois chauds avec wrapper historique puis
  wrapper cache, sur exactement la meme mission ;
- conserver le cache seulement si le gain median au demarrage atteint une
  seconde, sans texture manquante et sans hausse memoire significative ;
- instrumenter les ouvertures de fichiers et documenter les textures relues ;
- ne supprimer aucun doublon et ne repaqueter aucun SFS dans ce lot.

Perimetre apres v1.15 :

- tracer les couples conversion `BmpUtils` / envoi `glTexImage2D` ;
- identifier par empreinte, dimensions, format et drapeaux les conversions
  strictement redondantes ;
- prototyper un cache invalidable de conversion ;
- etudier un chargement anticipe progressif a distance, sans depasser le budget
  d'espace virtuel du processus x86 ;
- qualifier separement chaque wrapper graphique et chaque famille de GPU.

Le critere de succes d'une optimisation profonde sera une baisse mediane d'au
moins 15 % ou trois secondes sur le premier chargement, moins de 5 % de
regression a chaud, zero corruption visuelle et moins de 10 % d'augmentation du
pic de memoire privee.

## Resultats OS_Programs historiques du 2 septembre

Les derniers essais transmis donnent :

- Zuti : 7 PASS, 2 avertissements, zero echec sur dix minutes ;
- contenu general : 17 PASS, 3 avertissements, zero echec ;
- AOC 1a se charge, mais neuf parametres sur dix ne montrent pas encore de
  consommation dans le code actif ; seul `bSwitchMagnetoOn` est prouve ;
- le son P-39 reste incomplet en raison de presets Allison absents.

A cette date, Zuti restait candidat v1.15 sous reserve des avertissements et
AOC 1a ne pouvait pas etre annonce comme entierement fonctionnel. Cette etape
precede la reconstruction AOC puis le retrait de MDS. La regle de compatibilite
reste applicable : aucune autre version AOC ne remplace 1a sans audit de sa
cible, de ses dependances et de ses effets sur les modeles de vol.
