# Audit des executables, DLL, memoire x86 et affinite CPU

Derniere mise a jour : 12 septembre 2026.

## Perimetre et resultat

`tools/Audit-PeBinaries.ps1` inventorie les en-tetes PE sans charger ni executer
les fichiers. Le rapport reproductible est
`manifests/binaries/pe-audit.json`.

| Controle | Resultat |
|---|---:|
| EXE/DLL trouves | 65 |
| En-tetes PE valides | 65 |
| PE32 i386 | 65 |
| PE32+ amd64 / arm64 | 0 / 0 |
| PE32 i386 Large Address Aware | 6 |
| PE32 i386 non Large Address Aware | 59 |

Les six PE32 marques Large Address Aware sont exactement les six copies de
`il2fb.exe` des profils **moddes**. Elles ont le meme format, mais le
differentiel historique 6DOF est maintenant restaure :

- taille : 274 432 octets ;
- trois profils avec 6DOF, SHA-256
  `7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21` ;
- trois profils sans 6DOF, SHA-256
  `BA1C702C1FC0DCC3D760FAEE46F74AD8BDF3D8CB5CE44B2CA40DAA3F75343C80` ;
- architecture : i386 / PE32 ;
- drapeau `IMAGE_FILE_LARGE_ADDRESS_AWARE` present ;
- `FileDescription` et `ProductName` Windows : `Open Sturmovik`.
- icone Windows : dessin `avion-ciel` multiresolution, reserve aux six EXE
  modifies.

La ressource `VERSIONINFO` permet au volet **Processus** du Gestionnaire des
taches d'afficher `Open Sturmovik`. Le nom d'image technique reste `il2fb.exe`
dans le volet **Details**, car le fichier actif conserve ce nom necessaire a la
chaine historique. L'ajout est reproductible par
`tools/Set-OpenSturmovikExeBranding.ps1`. Le meme outil remplace le groupe
`IL2ICON`, ajoute le groupe numerique `0x7F00` et corrige les deux appels
`LoadIconA` qui demandaient auparavant l'icone generique Windows. Seuls les
octets d'argument documentes aux RVA `0xD820` et `0xD88E` changent dans la
section `.text` ; le differentiel 6DOF reste intact.

Les ressources PE et les ajustements v1.15 sont conserves dans les deux
variantes. Le detail des offsets et des classes TrackIR est consigne dans
`manifests/profiles-6dof-v1.15.json`.

Les trois profils originaux et l'EXE racine emploient tous l'executable stock :

- taille : 4 548 608 octets ;
- SHA-256 :
  `9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C` ;
- architecture : i386 / PE32 ;
- Large Address Aware absent.

Cette separation est volontaire. Les profils originaux doivent rester stock et
ne demandent aucun `wrapper.dll`. Les utilitaires et DLL ne doivent pas etre
marques LAA en bloc : ce drapeau n'augmente pas la memoire d'une DLL et peut
masquer des hypotheses de pointeurs signes dans un ancien programme.

## Limite exacte sur Windows 32 bits

Un processus x86 dispose par defaut de **2 Gio d'espace d'adressage utilisateur**.
Sur un Windows 32 bits, Large Address Aware ne suffit pas a obtenir 4 Gio : le
demarrage du systeme avec 4GT (`increaseuserva`) permet au maximum **3 Gio pour
le processus** et laisse environ 1 Gio au noyau. Microsoft borne
`increaseuserva` a 3072 Mio. Les 4 Gio utilisateur pour un processus x86 LAA ne
sont possibles que sous Windows 64 bits.

Sources Microsoft : [limites memoire des versions Windows](https://learn.microsoft.com/en-us/windows/win32/memory/memory-limits-for-windows-releases),
[espace d'adressage virtuel](https://learn.microsoft.com/en-us/windows/win32/memory/virtual-address-space).

La cible realiste Open Sturmovik sur l'OS 32 bits demande par Alexis est donc :

1. EXE modde LAA ;
2. Windows 32 bits configure explicitement pour un partage utilisateur/noyau
   allant jusqu'a 3 Gio ;
3. tas Java conserve provisoirement a `-Xmx1G` ;
4. marge mesuree pour les allocations natives, textures, sons, DLL et pilotes ;
5. refus d'un profil « qualite maximale » si la memoire privee approche la limite
   avant le chargement d'une mission.

Le dernier Dump instrumente a deja atteint environ 1 598,8 Mio de memoire privee.
Augmenter aveuglement `-Xmx` risquerait donc d'affamer la partie native du moteur.
Le futur lanceur devra choisir une strategie a partir de l'OS, de la RAM physique
et de mesures, pas seulement de la quantite de RAM installee.

## Quatre coeurs physiques

Le selecteur interroge `GetLogicalProcessorInformation`, regroupe les processeurs
logiques par coeur physique, puis choisit le premier bit logique de quatre coeurs
au maximum. Il applique ensuite ce masque au processus avec
`ProcessorAffinityMask`. Le repli historique reste `0xF` si la topologie ne peut
pas etre lue.

Cette methode evite de supposer que les bits 0 a 3 representent quatre coeurs
physiques sur une machine avec Hyper-Threading. Elle est compatible avec le masque
32 bits d'un processus x86. Elle autorise IL-2 et ses services a utiliser jusqu'a
quatre coeurs, mais ne transforme pas le moteur principal en moteur quatre fois
plus parallele : les chemins historiques qui sont sequentiels le restent.

Sources Microsoft : [SetProcessAffinityMask](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setprocessaffinitymask),
[groupes et affinite processeur](https://learn.microsoft.com/en-us/windows/winprog64/processor-affinity).

## Wrappers identifies

| Famille | Taille | SHA-256 | Etat |
|---|---:|---|---|
| `wrapper.dll` historique, six profils | 233 472 | `8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78` | Chargeur de mods 4.08/4.09 a conserver pour le profil stable |
| wrapper cache 4.09m experimental | 45 056 | `EBB5C61C1CDF8132713F51A2CFAA147B7DD4DE0732A148904C436AA1470B4D67` | Cache manifeste, banc isole valide, test jeu requis |

`wrapper.dll` n'est pas un wrapper graphique. Il sert au chargement des ressources
libres et des classes moddees. Les futurs dgVoodoo2, DXVK, Mesa et IL2GE doivent
etre des profils graphiques separes, reversibles, avec uniquement des DLL x86.
L'analyse detaillee du chargeur historique est dans `docs/ANALYSE_WRAPPER_DLL.md`.

## Binaires inattendus dans le contenu

L'inventaire a trouve deux copies identiques de `cmd.exe` Windows XP SP2 sous des
dossiers de cockpits Tempest et deux copies de `ChangeMap.exe` sous les cockpits
P-24/RWD-8. Leur simple presence ne prouve aucune execution. Elles sont toutefois
indexees comme contenu, inutiles au moteur pendant le jeu et posent un probleme
de surface d'attaque et de redistribution.

Decision actuelle : ne pas les executer et ne pas les supprimer au milieu de la
passe P0. Avant la sortie 1.15, une trace d'acces doit confirmer qu'ils ne sont
jamais ouverts ; ils pourront alors etre retires du paquet distribue, avec test de
non-regression des cockpits concernes.

## Reproduction

```powershell
.\tools\Audit-PeBinaries.ps1
```

Le rapport JSON doit rester versionne. Toute modification d'un EXE, d'une DLL ou
d'un wrapper doit changer son empreinte attendue, etre expliquee ici et subir un
nouvel essai dans une copie de test.
