# Analyse statique de `wrapper.dll`

## Identification

Les six profils modifies 4.08/4.09 contiennent exactement le meme fichier :

- taille : 233 472 octets ;
- SHA-256 : `8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78` ;
- format : PE32 x86 ;
- horodatage PE : janvier 2008 ;
- implementation : conventions et runtime caracteristiques de Delphi/Borland.

L'installation de reference contient le meme binaire. Cela confirme sa provenance communautaire, mais pas sa compatibilite avec toutes les versions officielles ulterieures.

## Interface exportee

| Ordinal | Symbole | Role statiquement observe |
| ---: | --- | --- |
| 1 | `ReadDump` | Point d'entree de compatibilite ; le binaire observe se contente de retourner en nettoyant 8 octets |
| 2 | `__SFS_openf` | Interception principale d'ouverture d'une ressource |
| 3 | `___CPPdebugHook` | Crochet de runtime/debug Borland |

Le wrapper importe en retour `SFS_open` par l'ordinal 7 et `SFS_openf` par
l'ordinal 8. L'une ouvre la surcharge libre choisie ; l'autre reprend le chemin
SFS d'origine lorsqu'aucune surcharge ne correspond. L'EXE 4.09m modifie exporte
egalement ces deux noms. Cette interface explique pourquoi un executable, un
wrapper et une version du jeu doivent etre traites comme un couple ABI indivisible.

## Fonctionnement reconstitue

Au chargement, le binaire contient les chemins `mods\*.*`, `mods\` et `files\`. Il enumere les arborescences, calcule l'empreinte 64 bits utilisee par le systeme de fichiers IL-2 et construit une table en memoire. Le calcul s'appuie sur deux tables de 256 valeurs de type CRC.

Lors d'un appel a `__SFS_openf` :

1. le wrapper normalise ou derive l'empreinte de la ressource demandee ;
2. il cherche cette empreinte dans sa table de fichiers libres ;
3. une correspondance est ouverte comme fichier libre par la fonction de l'executable ;
4. sans correspondance, les arguments d'origine sont transmis a la fonction SFS native.

Cette priorite explique pourquoi les 2 028 fichiers differents trouves a la fois dans `Files` et les archives SFS sont des remplacements effectifs du mod. Elle explique aussi pourquoi les supprimer ou changer arbitrairement l'ordre de recherche peut casser le jeu.

Le dechiffrement eventuel des classes et la reconstruction d'un en-tete de classe
version 47 ne sont pas realises par ce DLL : ce traitement se trouve dans l'EXE
modifie. Cette separation a permis de diagnostiquer les 56 classes version 50 ;
elles sont maintenant traitees et suivies dans `AUDIT_CLASSES_JAVA.md`.

Le binaire reference egalement `runtimedump.bin`. Ce fichier n'est pas present dans le depot. Sa relation exacte avec `ReadDump`, la table de noms et les modes de diagnostic doit encore etre observee avec le journal SFS d'un environnement de test.

## Limites importantes

- aucune signature ou information de version exploitable ne permet d'associer automatiquement ce wrapper a une ABI autre que celle des EXE fournis ;
- les variantes « 6DOF » et « sans 6DOF » ne different actuellement ni par l'EXE, ni par le wrapper, ni par `files.SFS` ;
- aucun cache persistant tel que `~wrapper.cache` n'est visible dans le depot et aucune chaine correspondante n'apparait dans ce vieux binaire ;
- l'indexation semble reconstruite a partir des arborescences libres, ce qui rend le nombre de fichiers et dossiers plus important que leur seule taille ;
- remplacer ce fichier par un wrapper graphique detruirait le chargement du mod.

## Comparaison avec le code source du Selector SAS 3.3

Le code source public du Selector 3.3.0 a ete exporte depuis le depot SVN
SourceForge, sans installer ni executer le programme. Il confirme les signatures
`ReadDump(void *, unsigned)` et `__SFS_openf(unsigned __int64, int)`, ainsi que
l'algorithme general de surcharge.

Le diagnostic initial fonde seulement sur les ordinaux `0x87` et `0x88` etait
incomplet : ce ne sont que les replis du source recent. Il cherche d'abord
`SFS_open` et `SFS_openf` par nom, que notre EXE 4.09m exporte bien. Le veritable
ecart ABI se situe dans les exports du wrapper : le source 3.3.0 les declare
`__cdecl`, tandis que l'EXE fourni pousse respectivement 8 et 12 octets et attend
que le DLL les retire, donc `__stdcall`. Le binaire recent ne doit toujours pas
etre copie tel quel, mais il est possible de porter le DLL seul pour cette ABI,
sans imposer sa couche de lancement `dinput`.

Le source precise aussi l'ordre de resolution : il ajoute d'abord `MODS`, puis `FILES`, trie par empreinte et conserve la premiere entree lors de la suppression des doublons. A empreinte identique, `MODS` a donc priorite sur `FILES`, puis l'absence de surcharge renvoie vers le SFS d'origine.

### Cache du wrapper recent

Avec `UseCachedFileLists=1` ou l'option `/cache`, un fichier texte `~wrapper.cache` est place dans chaque arborescence `MODS` et `FILES`. Chaque ligne contient l'empreinte hexadecimale sur 16 caracteres et le chemin relatif. Si ce fichier existe, cette version du source le lit directement : elle ne compare ni dates, ni tailles, ni contenu des dossiers. Un cache ancien peut donc masquer un ajout ou continuer a referencer un fichier supprime.

La variante Open Sturmovik corrige ce point. Elle place ses fichiers sous
`.open-sturmovik-cache`, hors des arborescences indexees, et associe chaque liste
a un manifeste de tous les dossiers rencontres. Au chargement, elle controle :

1. l'identifiant et la version du format ;
2. le marqueur de fin et le nombre d'entrees ;
3. l'existence et l'horodatage de chaque dossier ;
4. la syntaxe et la relativite de chaque chemin ;
5. le retour a une enumeration complete des qu'une verification echoue.

Ajouter, retirer ou renommer une entree change l'horodatage du dossier parent et
invalide le manifeste. Remplacer seulement le contenu d'un fichier ne change pas
son chemin ni son empreinte SFS : l'index reste alors valable. Les deux fichiers
temporaires sont vidanges puis publies avec `MoveFileEx(...,
MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)`, dont les garanties sont
decrites par [Microsoft](https://learn.microsoft.com/fr-fr/windows/win32/api/winbase/nf-winbase-movefileexa).

Le lecteur de cache de ce source merite egalement une correction defensive : il inspecte le dernier caractere de la ligne avant d'avoir exclu une ligne vide. Cette version source ne doit donc pas etre compilee et distribuee telle quelle sans revue et tests.

## Variante cache 4.09m de la version 1.15

Le port se trouve dans `native/wrapper-cache-409m`. La DLL reproductible livree
dans `_Game Switchers/Wrapper Cache 4.09m (Experimental)` est PE32 i386, importe
seulement les DLL systeme Windows et exporte exactement :

- `ReadDump`, qui termine par `ret 8` ;
- `__SFS_openf`, qui termine par `ret 12`.

Son SHA-256 est
`EBB5C61C1CDF8132713F51A2CFAA147B7DD4DE0732A148904C436AA1470B4D67`.
L'initialisation a ete retiree de `DllMain` et differee jusqu'au premier appel.
Le banc 32 bits isole valide la construction a froid, le cache chaud, son
invalidation apres ajout de fichier et la recuperation apres corruption. Les
choix 11/12 l'activent ; 8/9 restaurent le wrapper historique. Un lancement IL-2
et une mission temoin restent obligatoires avant de le promouvoir comme profil
stable.

Source historique de la composition d'un chargeur de mods 4.09 : [guide SAS Mod Activator](https://www.sas1946.com/main/index.php?topic=5310.0). Le manuel du selecteur SAS documente le fichier `~wrapper.cache` : [IL-2 Selector Manual](https://www.sas1946.com/downloads/essentialsas/selector/IL-2_Selector_2.3.0_Manual.pdf). Le [depot source Selector 3.3.0](https://sourceforge.net/p/il2selector/code/HEAD/tree/trunk/3.3.0/) et les [archives publiees](https://sourceforge.net/projects/il2selector/files/) sont conserves sur SourceForge.
