# Outils de modding et de diagnostic IL-2 1946

## Perimetre

Cette liste est etablie pour **Open Sturmovik 1.15 sur IL-2 1946 4.09m**.
Le numero de version le plus eleve n'est pas toujours le bon choix : certains
formats proteges, executables et wrappers changent avec la version du jeu.

Les archives recuperees sont conservees hors du depot, dans
`D:\Projets\GITHUB\res\IL2 1946\Outils`. Elles ne sont ni installees dans le
jeu de reference, ni activees par Open Sturmovik. Les executables communautaires
examines ne sont pas signes. Un controle Microsoft Defender realise sur les
archives extraites le 30 aout 2026 n'a signale aucune menace ; ce resultat ne
remplace pas un essai dans une copie jetable du jeu.

## Ensemble minimal recommande pour l'audit 4.09m

| Besoin | Outil retenu | Etat pour 4.09m | Regle d'utilisation |
| --- | --- | --- | --- |
| Extraire une archive SFS connue | SFS Extractor 3.1 + listes 2025-10-31 | Retenu en lecture | Extraire dans un dossier vide ; ne jamais travailler dans le jeu de reference |
| Inspecter une SFS sans ancien executable | `tools/Analyze-Sfs.py` | Retenu en lecture seule | Lit v201/v202, extrait seulement les chemins/classes demandes et ne reecrit jamais l'archive |
| Explorer, extraire et reconstruire un SFS | SFS Manager 4.1 | Retenu sous controle | Pour extraire, employer le bouton `Extract All` en bas a droite ; toute archive reconstruite doit subir un test aller-retour et un lancement du jeu |
| Extraire les SFS recalcitrants | IL-2 Extractor / MikeTool | Laboratoire seulement | Son script remplace temporairement `dinput.dll` et lance un EXE avec `-extract` : uniquement dans un clone jetable, avec restauration transactionnelle |
| Capturer seulement ce que le jeu demande | IL-2 Selector 5.1.2, Dump Mode | Outil prioritaire de diagnostic, pas un remplacement direct | Installer dans un clone dedie ; ne jamais copier son EXE, son `DINPUT.dll` ou son `wrapper.dll` sur le profil 4.09m stable |
| Journaliser l'acces aux SFS | IL-2 Selector 5.1.2, SFS access logging | Outil prioritaire de diagnostic | Correlier les acces et horodatages avec `initlog.lst` et la capture de lancement |
| Lire/reconstruire `buttons` | NTRK/outil Dr. Strangelove compatible 4.09m | **Encore manquant** | L'outil doit etre valide sur une copie du `buttons` actif avant toute reconstruction |
| Verifier les registres d'objets | Universal Static.ini Checker 1.3 | Retenu en lecture | Produit un rapport ; ne modifie pas lui-meme les fichiers |
| Observer fichiers, DLL et erreurs Windows | Process Monitor 4.1 | Retenu comme outil systeme | Filtrer sur `il2fb.exe`, `java.dll`, `wrapper.dll`, `jgl.dll`, `dx8Wrap.dll` et le dossier du jeu |

## Dump Mode du Selector

Le Dump Mode, introduit dans la serie 4 du Selector et present dans la version
5.1.2, ecrit sous `<jeu>\dump` les ressources auxquelles IL-2 accede pendant la
session. Il peut capturer des ressources venant des SFS aussi bien que des
fichiers libres : Java, modeles 3D, textures, sons, effets et modeles de vol.
L'option de journalisation SFS complete cette collecte en indiquant les archives
montees et les ouvertures dans `initlog.lst`.

Ce mode repond exactement au besoin de cartographier le chargement :

1. creer un clone propre du profil a mesurer ;
2. vider uniquement le dossier `dump` de ce clone entre deux essais ;
3. lancer une seule sequence reproductible, par exemple demarrage jusqu'au menu ;
4. conserver le journal, la capture de processus et la liste des fichiers
   nouvellement crees avec leurs horodatages ;
5. recommencer avec une seule action supplementaire, par exemple ouvrir le QMB
   ou charger un avion precis ;
6. comparer les deux inventaires pour isoler les ressources de cette action.

Un passage limite au menu ne peut pas reveler tous les fichiers d'un appareil.
Pour dumper les dependances d'un avion, il faut provoquer son chargement dans
une mission minimale. Le Dump Mode est donc un extracteur **a la demande**, pas
un inventaire exhaustif du contenu SFS.

### Pourquoi le Selector reste isole

L'archive 5.1.2 contient son propre `il2fb.exe`, un `DINPUT.dll` et plusieurs
couples EXE/wrapper. Son wrapper mod porte la version `5.1.2.0` et pese 175 616
octets. Le profil Open Sturmovik historique emploie un autre EXE et un
`wrapper.dll` de 233 472 octets avec une interface binaire differente. Remplacer
directement ce couple pourrait empecher le chargement des mods ou rendre les
resultats incomparables. Le Selector servira donc d'abord dans un clone de
laboratoire construit pour lui.

Le cache `~wrapper.cache` du Selector doit lui aussi rester experimental : un
cache perime peut masquer un fichier ajoute ou continuer a referencer un fichier
supprime. Le futur lanceur devra invalider le cache lorsque le manifeste des
dossiers `Files`/`MODS` change.

Le clone de laboratoire construit le 30 aout 2026 utilise `DumpMode=3` : le bit
1 journalise les ouvertures SFS et le bit 2 copie les ressources. `InstantDump=1`
force l'ecriture immediate de la liste, tandis que le cache reste desactive. Le
script reproductible est `tools/Install-IL2SelectorDumpLab.ps1`; la validation et
la capture passent par `tools/Start-OpenSturmovikSelectorDumpCapture.ps1`.

Sources : [fil de publication du Selector](https://www.sas1946.com/main/index.php?topic=16403.0),
[manuel officiel du Selector](https://www.sas1946.com/downloads/essentialsas/selector/IL-2_Selector_Manual.pdf),
[exemple de Dump Mode cible sur un avion](https://www.sas1946.com/main/index.php?topic=69015.36).

## SFS : roles et precautions

### SFS Extractor 3.1

`SFSExtractV31.rar` contient `SFSExtract.dll` 3.1.0.1. La liste historique
incluse ne suffit plus pour tous les contenus communautaires ; l'archive
`SFS_filelists_2025-10-31.7z` ajoute un `filelist.txt` de 1 811 845 lignes et un
`SFSExtract.lst` de 1 866 924 lignes. Ces listes font correspondre des empreintes
aux noms connus ; un nom absent peut donc rester numerique sans que l'archive
soit corrompue.

Pour `tools/Analyze-Sfs.py list`, il faut fournir **`SFSExtract.lst`**, dont les
lignes ont la forme `empreinte?chemin`. `filelist.txt` est un dictionnaire de
noms et d'empreintes non apparies ; l'utiliser comme table de correspondance
produirait zero resultat et une conclusion fausse.

Le lecteur Python derive des algorithmes d'
[OpenIL2](https://github.com/DavidGregory084/OpenIL2), sous licence
BSD-2-Clause-Patent conservee dans `docs/THIRD_PARTY_NOTICES.md`. Il gere la cle
specifique des tables v201 (empreinte de l'en-tete brut) et la cle v202
(empreinte du nom d'archive). Exemple en lecture seule :

```powershell
python .\tools\Analyze-Sfs.py list C:\jeu\fb_3do08p.SFS `
  --file-list C:\outils\SFSExtract.lst --match 'TBF-1'
```

Il ne remplace pas SFS Extractor/Manager pour une extraction exhaustive : la
liste actuelle resout entre 83,84 % et 95,66 % des grosses archives examinees.
Une entree numerique non resolue doit etre preservee telle quelle.

### SFS Manager 4.1

L'archive est publiee comme 4.1, alors que `SFSManager.dll` expose la version
interne 4.0.0.169. Le retour communautaire signale que la commande du menu peut
ne rien faire pour l'extraction ; le bouton `Extract All` en bas a droite est la
voie a employer. La reconstruction d'un SFS n'est jamais validee par la seule
reouverture dans l'outil : il faut comparer la liste et les empreintes des
fichiers, puis faire demarrer le clone du jeu.

### SFSA 1.1.0.1

`SFS packer SFSA_v1.1.0.1.rar` reste disponible pour reproduire une ancienne
chaine, mais ce n'est plus le packer principal. SFS Manager/Total MODder est
plus adapte aux gros ensembles modernes. SFSA ne sera utilise que pour comparer
un resultat ou reproduire une archive historique.

### IL-2 Extractor / MikeTool

Cet outil sait extraire des SFS que les extracteurs usuels ne traitent pas. Son
script renomme le `dinput.dll` du jeu, place temporairement `dinput.dump` sous ce
nom, puis lance `il2fb.exe -extract=extract -jvmargs=args.txt`. Une interruption
au mauvais moment peut laisser le jeu dans un etat incoherent. Avant usage, nous
en ferons une variante transactionnelle qui verifie les empreintes et restaure
la DLL meme en cas d'echec.

Sources : [SFS Extractor 3.1](https://www.sas1946.com/main/index.php?topic=16581.96),
[SFS Manager 4.1 et retour d'utilisation](https://www.sas1946.com/main/index.php?topic=63325.12),
[comparaison des packers SFS](https://www.sas1946.com/main/index.php?topic=66480.0).

## `buttons`, modeles de vol et `air.ini`

Le fichier actif `Files\gui\GAME\buttons` est un conteneur protege de modeles de
vol et d'autres donnees. `air.ini` enregistre les appareils et les classes qu'ils
doivent charger. Un avion declare sans modele de vol compatible dans `buttons`,
ou un registre prevu pour une autre generation de Buttons, peut bloquer le
demarrage vers 60 %.

L'archive locale `NTRKwizard_for410buttons.7z` contient NTRK Wizard 0.3, mais son
propre lisez-moi indique explicitement `For 4.10 buttons type`. Elle ne sera donc
pas utilisee pour reconstruire le Buttons de production 4.09m. Le `cmd.exe`
Windows XP fourni dans cette archive est inutile et ne doit jamais etre lance ;
le fichier JAR peut etre inspecte avec le JDK moderne deja installe.

La commande de liste du JAR a ete testee le 1er septembre 2026 uniquement sur
une copie temporaire du Buttons actif. Elle ouvre bien sa table et compte **739
entrees** : `desktop.ini` et 738 noms numeriques. Une liste candidate contenant
les 385 chemins FMD distincts demandes par les 536 lignes de `air.ini` n'en
resout cependant aucun. Cela confirme que le resolveur de noms 4.10 (`d2wO` dans
le bytecode de NTRK 0.3) n'est pas compatible avec ce Buttons 4.09m. Ce resultat
ne prouve aucun FMD absent. L'ancien NTRK Wizard 0.2 et Class Resolver 0.2 de QTIM,
documentes en 2009, deviennent les candidats prioritaires a retrouver.

La derniere base Buttons annoncee comme strictement 4.09 est la 8.7. Elle est
une **reference de comparaison**, pas un remplacement automatique : Open
Sturmovik contient des avions communautaires qui peuvent exiger d'autres modeles
de vol. L'outil Dr. Strangelove/FreeIL2Modding a ete retrouve dans des mentions
et exemples recents, mais aucun paquet d'outil avec provenance et compatibilite
4.09m suffisamment verifiables n'a encore ete localise. Il reste donc inscrit
comme manque reel, plutot que de substituer un packer Diff-FM moderne non teste.

Lorsqu'un candidat sera trouve, la validation sera :

1. extraire une **copie** du Buttons actif sans modification ;
2. inventorier les chemins `FlightModels` et leurs empreintes ;
3. reconstruire sans changement dans un nouveau fichier ;
4. verifier que l'outil peut relire sa sortie ;
5. comparer les inventaires logique et binaire ;
6. tester le demarrage, puis un petit echantillon d'appareils ;
7. seulement ensuite comparer chaque ligne de `air.ini` aux modeles disponibles.

Sources : [explication communautaire du fichier Buttons](https://www.sas1946.com/main/index.php?topic=21.0),
[versions SAS Buttons et derniere base 4.09](https://www.sas1946.com/main/index.php?topic=97.0),
[discussion NTRK et outils de compilation](https://www.sas1946.com/main/index.php?topic=3988.36),
[archive FreeIL2Modding](https://archive.org/details/@freeil2modding).

Rapports reproductibles : [audit des 536 appareils](AUDIT_APPAREILS_AIR_INI.md)
et [lecture de l'index Buttons](AUDIT_BUTTONS_MODELES_DE_VOL.md). Le nombre de
739 entrees est une occupation mesuree, pas une limite moteur. Les retours sur
la « Java Wall » indiquent une limite dependant de toutes les classes chargees
et de leur structure, avec environ 600 avions comme ancien point de stabilite
empirique et non comme plafond universel. Open Sturmovik en declare 536 ; la
marge devra etre qualifiee par paliers et mesures JVM, pas devinee.

## Outils de contenu a conserver pour les phases suivantes

| Outil | Usage | Decision |
| --- | --- | --- |
| Msh Viewer 64e 1.2.0.311 | Visualiser les 38 043 fichiers `.msh` du depot | Bon outil x64 de poste de travail ; ne pas distribuer dans le jeu |
| Msh ConverterEx | Conversion de modeles 3D | Conserver en quarantaine ; ne jamais lancer ses anciens installateurs .NET 2.0/Windows Installer/VC++ 2005 |
| Actors Tool 1.5 | Lire et ecrire `actors.static` pour les cartes | A utiliser plus tard sur des copies de cartes |
| ViewIMF 1.0 | Examiner les images IMF historiques | Optionnel |
| HEdit v2 | Editeur hexadecimal historique | Secours seulement ; preferer un editeur moderne |
| OpenIL2 | Comprendre des formats et un chargeur moderne | Source d'etude, pas un outil a deposer dans la 4.09m |

Le Msh ConverterEx ne justifie pas l'installation des prerequis obsoletes livres
dans son archive. Si une conversion devient necessaire, utiliser la fonctionnalite
Windows .NET Framework 3.5 encore prise en charge et une copie jetable de
l'outil, ou remplacer la chaine par un convertisseur maintenu.

## Outils modernes de poste de travail

- **7-Zip 26.02** : version officielle courante au 30 aout 2026. La machine a
  encore 24.09 ; une mise a jour est recommandee mais n'a pas ete imposee.
- **Process Monitor 4.1** : reference pour voir les acces fichiers, les DLL et les
  echecs `NAME NOT FOUND` pendant le chargement.
- **JDK 17** : deja disponible pour `jar`, `javap` et l'analyse des classes. Il ne
  remplace pas la JVM embarquee du jeu lors de l'execution.
- **Vineflower** : decompilateur Java moderne a ajouter lorsque commencera la
  revue source des classes ; il ne doit jamais reecrire directement les classes.
- **Ghidra 12.1.3** : a ajouter pour l'analyse approfondie de `il2fb.exe`, des DLL
  et du `wrapper.dll`. Il n'est pas necessaire au premier essai Dump Mode et n'a
  donc pas ete telecharge pour l'instant.

Liens officiels : [7-Zip](https://www.7-zip.org/),
[Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon),
[Ghidra](https://github.com/NationalSecurityAgency/ghidra/releases),
[Vineflower](https://github.com/Vineflower/vineflower/releases),
[OpenIL2](https://github.com/DavidGregory084/OpenIL2).

## Archives controlees

| Archive | Taille | SHA-256 |
| --- | ---: | --- |
| `SFSExtractV31.rar` | 7 457 030 | `A4AF8FA4DED6BE1D8AC34EAE5A2014E19531A3CDC5715773974C263DB959CB95` |
| `SFSManager V4.1.rar` | 38 415 001 | `D30676013BFD497B2E70A6819C2179D296BDE128B69D87E774EA4963EC1BB751` |
| `SFS packer SFSA_v1.1.0.1.rar` | 656 646 | `20860FF878629FA668B34433D8ED14A03D9D34D1BE24BF2333CABF0A913F9F19` |
| `SFS_filelists_2025-10-31.7z` | 32 150 408 | `E524511FD019FD61924C83276ADBA697E81CFB7AD2FD94747278C07CCD8D75AF` |
| `IL-2_Extractor_MikeTool.7z` | 19 674 | `1488677EBAA4CB9F4425D1A97AA14439A4B49FE79710593434C2372C6C69DE10` |
| `IL-2_Selector_5.1.2.zip` | 7 750 929 | `0F1A8C6DDB4D6062DE84F99583B932C1DE429E1D2D7119DCA8EE69EB7817C7D4` |
| `IL-2_Selector_Manual.pdf` | 1 057 731 | `CB2765E113D4B46701F4989ECBC859459AE36D3E66407CC15576B4D70CD13F36` |
| `IL-2_Selector_4.0.2_Server.zip` | 541 507 | `6E2B01261DBF06C9686FEAA8FF74B28FAD965431D38BED5E2D5F389E9B585219` |
| `NTRKwizard_for410buttons.7z` | 121 179 | `748188B9E0DD9A89CC125E035830E475A86773A58DB4573A80384C817E69728A` |
| `Universal_Static.ini_Checker_v1.3.7z` | 81 133 | `FB834AC869CBDBAD92CC216B74DDC35B8BE28CB847BEAC8263B6251A2828947A` |
| `Actors_Tool_v1.5.7z` | 46 902 | `7FE7F477A9ABB600F1395CA73554939CFA344F8EB2D922AD01C889B82DF95ECA` |
| `Msh_Viewer_64e.7z` | 1 341 824 | `4000ECC980E89B02271B43E2A85AAF074B735EB946EE391BC18F6657EA7B72E7` |
| `Msh_ConverterEx.7z` | 35 956 773 | `D5924F71D979222ACBFE04A65B3A4C9D8EDC628C553EE692E4E2D00ABC7693E7` |
| `ViewIMF.7z` | 18 080 | `618A07034052E376C9665A9697CB6DBB2564308ECDFE8EDF4834F226133E78D3` |
| `HEdit_v2.zip` | 164 805 | `73651BA4D8AF84CF4782361F799D3C93C0A4561DEA172B05D912E4EAEF997361` |

## Decision de travail

Pour la prochaine capture, la voie la plus sure reste le profil Open Sturmovik
4.09m stable avec les outils de capture deja prepares. En parallele, un **clone
Selector/Dump** sera construit pour attribuer les ressources aux phases de
chargement. Aucun `buttons` ne sera reconstruit avant d'avoir retrouve et valide
un outil compatible 4.09m.
