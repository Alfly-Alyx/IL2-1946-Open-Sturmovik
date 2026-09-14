# Reconstruction AOC sans MDS — 12 septembre 2026

## Perimetre et resultat

Demande explicite : retirer completement Zuti, tout en preservant AOC et les
autres mods. Ce rapport traite uniquement les trois classes AOC de la branche
`v1.15`, base IL-2 4.09m. Aucun lancement du jeu n'est effectue par cette analyse.
Les sorties ont ete integrees localement avec les autres classes du retrait.
Les controles statiques globaux sur trois versions passent ; les vrais essais
du jeu et de l'installateur restent a refaire. Le retrait n'est pas encore
commite ni pousse. Les sections ci-dessous conservent les etapes de preparation
du candidat, anterieures a cette application coordonnee.

**Faits verifies, confiance elevee :** le constructeur conserve les deux sorties
`FlightModelMain` et `RealFlightModel` octet pour octet. Dans `Motor`, seuls les
quatre membres ci-dessous disparaissent ; tous les autres champs et toutes les
autres methodes conservent leur bytecode symbolique et leurs metadonnees. Les
266 profils et leurs chemins sont conserves.

| Classe de sortie | Nom libre | Octets | Major Java | SHA-256 |
|---|---|---:|---:|---|
| FlightModelMain | 294ABC86A89FAEB4 | 41045 | 45 | 2C37B2A0D3835BB548A521BB9EF18D990ADA4CBB8BDE455FF0A314E01CD1B583 |
| RealFlightModel | 684916A0E86D1CC8 | 29047 | 47 | 1115B13B81727674B4141D8BA791D1EF919A70BE20C69FB4700AE3F37538C979 |
| Motor | AF5F8A326C3FA53C | 57710 | 45 | 1F200D47D5D62E8D837A1137A06B70116AAC4872FB7190435476E7C8D8AA03AA |

Ancien Motor final : 62121 octets,
`576204B58D11A79751462EBDC18EF84E64001E9C6B3670051E802BC60029337A`.
Nouvelle selection du manifeste : `v1-1a-hsfx4-409m`.

## Sources et transformation minimale

Le dossier `test-assets/aoc-v1.15/base-409m` est une base personnalisee Open
Sturmovik ; son nom ne signifie pas qu'il provient d'une installation stock.
Ses deux premieres classes sont les anciennes fixtures intactes. Le Motor
historique, SHA-256
`C8A1A02BC941E00858F6835A3ECB95DDA5BAD0504B5105A33893AE98F7822E7B`,
devient la fixture
`FD2D4B4F5A975C246E13FA07E5CAD11B39A41C5E08234DC46A6E20187BD0C14E`.

Quatre methodes retirees exactement :

```text
public  zutiMakeEngineBackup()Lcom/maddox/il2/fm/Motor;
public  zutiRestoreMotor(Lcom/maddox/il2/fm/Motor;)V
private zutiCopyFloatArray([F)[F
private zutiCopyBooleanArray([Z)[Z
```

Les deux methodes privees copient les tableaux du mecanisme de sauvegarde.
Aucune instruction des methodes conservees n'appelle ces quatre methodes.
Le retrait s'effectue sur l'arbre ASM puis reecrit le pool de constantes :
aucun nom Zuti ne reste dans la fixture Motor ni dans les trois sorties.
Il ne s'agit pas de conserver des methodes vides ou de renommer le code retire.

Le donneur HSFX 4 et les transformations AOC existantes restent les memes :
temperature/demarrage, qualite du carburant, informations moteur et deux sites
de couple de l'helice. Les dix reglages du manifeste sont toujours consommes.
Le chargeur conserve `_Game_Enhancements/Mod_AOC_Public/` et `Defaut.txt`,
y compris le comportement historique de creation d'une copie du profil par
defaut a la premiere construction d'un avion dont le profil est absent.

Les sources locales et les recherches historiques precedentes sont identifiees
dans `manifests/aoc-v1.15.json` et `docs/AUDIT_RETRAIT_ZUTI_V1.15_20260912.md`.
Aucun nouveau donneur communautaire n'est introduit. Les limites d'acces a AAA,
SAS et les indices Mission4Today restent ceux du rapport precedent ; aucune
compatibilite supplementaire n'est deduite d'une page inaccessible.

## Verification de preservation

L'ancien constructeur a d'abord reproduit les empreintes du manifeste. Un
comparateur utilise ASM `Textifier` methode par methode : les references sont
symboliques et independantes des indices du pool de constantes. Il compare
aussi access, signature, exceptions, champs, superclass, interfaces et version.
Seuls les quatre membres explicitement retires sont exclus de la comparaison.

```text
Fixture Motor : 141 methodes et 234 champs preserves.
Sortie FlightModelMain : 79 methodes et 134 champs preserves.
Sortie RealFlightModel : 15 methodes et 40 champs preserves.
Sortie Motor : 142 methodes et 237 champs preserves.
```

La methode AOC ajoutee et les trois champs AOC expliquent la difference entre
fixture et sortie Motor. Le constructeur execute aussi l'analyse de pile ASM
`BasicInterpreter` de chaque methode et limite le major Java a 47.

Un second controle resout 1026 references de membres `com/maddox/` des trois
candidats contre l'etat actuel, puis contre les familles 4.09m simulees. Il
utilise le `files.SFS` Mods ON dont le SHA-256 est
`5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71`.
Les trois AOC, Controls, Explosions et Config sont explicitement conserves
comme interfaces personnalisees ; 321 classes de la fermeture historique sont
simulees par leur equivalent stock ou leur absence. Resultat : **zero nouvelle
reference manquante**. Le seul membre signale comme deja non resolu est
`RangeRandom.nextFloat()F`, herite de `java.util.Random`, classe JDK hors de
l'inventaire de ce controle ; ce n'est pas une regression du candidat.

**Limites :** cette resolution du pool de constantes est conditionnelle aux
interfaces conservees. Elle ne verifie pas toute l'accessibilite JVM, les
chargements dynamiques, les appels natifs, ni le comportement en vol. La liste
de 321 familles est un modele d'audit, pas une autorisation de remplacement.
Le controle global a ensuite employe les veritables sorties des autres patches
lors de l'integration locale : aucune nouvelle rupture statique sur les trois
versions. Le test en jeu demeure a effectuer ; voir le suivi des retraits.

## Reproduction et archives

Outils utilises : OpenJDK Adoptium 17.0.20, ASM interne au JDK ; Python 3.13 pour
la resolution statique et `tools/Analyze-Sfs.py` pour les classes 4.09m. CWD des
commandes : `C:\Users\Alexis\.codex`.

```powershell
$repo = 'D:\Projets\GITHUB\IL2-1946-Open-Sturmovik'
$out = 'C:\Users\Alexis\.codex\visualizations\2026\09\12\01a094b0-535f-7413-93c1-d5a15ca65ad3\aoc-removal\candidate'
& "$repo\tools\Build-OpenSturmovikAocPatch.ps1" -OutputRoot $out
& "$repo\tools\Test-OpenSturmovikAoc.ps1" -RepositoryRoot $repo -FilesRoot "$out\Files"
```

Resultats observes : constructeur code 0 ; test `PASS`, 3 classes, 266 profils,
extension retiree absente ; aucune utilisation de `-Apply` par cette sous-tache.

Archives externes sous
`D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence\Zuti MDS 1.13` :

- `sauvegarde_partielle_20260912` contient les anciennes fixtures, anciens
  constructeur/patcher et manifeste, avec empreintes verifiees avant retrait.
- `retrait_aoc_20260912` contient l'utilitaire `AocIsolationAudit.java`, les
  trois sorties avant/apres, le controle `check_aoc_linkage.py`, ses resultats
  `linkage.json` et un inventaire SHA-256. Ce sont des pieces partielles
  d'audit, pas un mod MDS original complet.

Pour reproduire l'isolation, compiler l'utilitaire avec les exports JDK
`java.base/jdk.internal.org.objectweb.asm`, `.tree` et `.util` vers
`ALL-UNNAMED`, puis lancer `AocIsolationAudit strip <ancienne-fixture-Motor>
<nouvelle-fixture-Motor>`. L'utilitaire refuse tout autre SHA-256 source. Le
mode `compare <ancienne-sortie.class> <nouvelle-sortie.class>` verifie les
methodes conservees. Les arguments historiques exacts et les entrees sont
identifies par l'inventaire externe ; le script de resolution retrouve les
fixtures `candidate/classes` a cote de lui. Sa comparaison « avant » se
rapporte a l'etat du depot avant l'application du retrait global.
