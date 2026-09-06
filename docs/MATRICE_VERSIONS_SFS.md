# Matrice des versions, archives SFS et profils Open Sturmovik

La cible finale d'Open Sturmovik est la 4.09m. Les couches 4.08m et 4.09b
presentes dans l'add-on sont des etapes de mise a niveau et des profils de
compatibilite serveur historiques ; aucun patch officiel posterieur a 4.09m ne
doit etre inclus. La reconstruction de reference part du DVD 4.07m, puis verifie
que la superposition de l'add-on produit elle-meme les etats 4.08m, 4.09b et
4.09m attendus. Les archives officielles servent d'oracle de comparaison, pas de
dependance pour l'utilisateur final.

## Objectif du projet

Open Sturmovik n'est pas un simple changement de version d'IL-2 1946. La
version 1.15 doit reunir les meilleurs apports de la communaute afin de rendre le
jeu plus realiste, plus coherent historiquement et aussi beau que le permet son
moteur. Les remplacements haute definition, notamment les textures 2K et 4K,
sont donc des contenus fonctionnels du mod et non des doublons a supprimer.

Le profil par defaut vise l'integration complete : tous les mods retenus doivent
etre actifs ensemble. Un composant n'est active par defaut qu'apres validation de
sa compatibilite avec le reste de l'ensemble. Les programmes historiques deja
classes incompatibles restent archives et desactives jusqu'a leur correction.

La reconstruction stock 4.08m sert uniquement de reference. Elle permet de
separer une erreur du jeu d'origine d'une erreur introduite par le chargeur, un
registre ou un contenu libre d'Open Sturmovik.

## Couches de versions observees

| Couche | Archives et binaires determinants | Interpretation |
| --- | --- | --- |
| 4.07m DVD | Archives `fb_3do*` jusqu'a `fb_3do17.SFS`, `fb_maps*` jusqu'a `fb_maps13.SFS`, `fb_sound.SFS` a `fb_sound05.SFS` | Base proprietaire necessaire aux patchs suivants |
| patch officiel 4.08m | Ajoute `fb_3do18.SFS` et `fb_maps14.SFS`, remplace `files.SFS` | Le patch ne contient pas la base 4.07m |
| profil historique 4.09b | Utilise des variantes beta de `fb_3do19.SFS`, `fb_maps15.SFS`, `files.SFS` et des DLL de coeur anterieures a la finale | Profil conserve pour compatibilite historique, non recommande |
| patch officiel 4.09m | Ajoute ou remplace `fb_3do19.SFS`, `fb_3do20.SFS`, `fb_maps15.SFS`, `files.SFS`, `il2_core*.dll` et `mg_snd*.dll` | Base officielle du profil modifie Open Sturmovik 1.15 |
| installation locale 4.14.1m | Consolide ou remplace plusieurs anciennes archives, ajoute les SFS 4.10+ et un `fb_sounds.SFS` unique | Ne peut pas etre transformee en 4.08m par le seul remplacement de `files.SFS` |

Cette matrice decrit les fichiers observes localement. Elle ne suppose pas que
toutes les distributions commerciales d'IL-2 1946 possedent exactement la meme
organisation avant l'application des patchs.

## Delta officiel 4.08m

Les fichiers determinants extraits sans modification de l'installateur local
`client-4.08.exe` correspondent exactement a ceux actives dans le profil stock
4.08m :

| Fichier | Taille | SHA-256 |
| --- | ---: | --- |
| `fb_3do18.SFS` | 15 954 060 | `AFD482C2BECB39BC4E88C8CCA30E367A5261B06C5059A29E2D467CDDDD8163C0` |
| `fb_maps14.SFS` | 70 234 937 | `9AFA2CB3670224185B693788F3D9196C971CA25AE5A6064C8F4710B3AB95F1FC` |
| `files.SFS` | 22 448 651 | `7F872ADAB1845E2837A2EE43FD378372B9DBAF01819C8F3BA7413B04BEFEAFD0` |

Le patch contient aussi des missions, des skins et ses notices. Il ne fournit
pas les grosses archives 4.07m et ne permet donc pas, seul, de recreer le jeu.

## Delta officiel 4.09m

| Fichier | Taille | SHA-256 |
| --- | ---: | --- |
| `fb_3do19.SFS` | 187 104 836 | `4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670` |
| `fb_3do20.SFS` | 2 020 049 | `02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283` |
| `fb_maps15.SFS` | 343 180 796 | `AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9` |
| `files.SFS` | 25 111 885 | `9F7D136C586EB3FCD258C5C000F34951D410A0236934F22ABA2516637874B095` |
| `il2_core.dll` | 1 552 384 | `3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3` |
| `il2_corep4.dll` | 1 634 304 | `0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979` |
| `mg_snd.dll` | 380 928 | `2FBE1180129806CC978A48879969E592918EA26C42EB235D62FC874BAD886421` |
| `mg_snd_sse.dll` | 380 928 | `FDDD6924853306C94C9B8844703D4718F45CF22828975406E3C67DE40DFDE1C4` |

Les quatre DLL montrent qu'un changement de version fiable ne doit pas gerer
uniquement `il2fb.exe` et `files.SFS`. Le manifeste transactionnel du futur
lanceur devra aussi verifier et restaurer les DLL et les SFS propres a la
version demandee.

## Profils historiques du selecteur

| Version et mode | `files.SFS` | EXE | Wrapper | Etat |
| --- | --- | --- | --- | --- |
| 4.08m stock | 22 448 651 octets, SHA-256 `7F872A...AFD0` | EXE stock commun de 4 548 608 octets | absent | Reference stock |
| 4.08m modifie | 21 449 752 octets, SHA-256 `D8A7DA...9986` | EXE 348 160 octets, empreinte distincte avec/sans 6DOF | historique | Couple 6DOF restaure statiquement |
| 4.09b stock | 22 447 129 octets, SHA-256 `DD9A1C...CFA8` | EXE stock commun | absent | Historique |
| 4.09b modifie | 21 453 950 octets, SHA-256 `99CF13...9D17` | EXE 348 160 octets, empreinte distincte avec/sans 6DOF | historique | Couple 6DOF restaure statiquement |
| 4.09m stock | 25 111 885 octets, SHA-256 `9F7D13...B095` | EXE stock commun | absent | Reference officielle finale |
| 4.09m modifie | 24 126 259 octets, SHA-256 `18F3C5...B05A` | avec 6DOF `68C78F...65584`, sans 6DOF `622CFD...BCC0F` | historique | Cible 1.15 ; distinction restauree, validation TrackIR requise |

Le profil Open Sturmovik complet doit devenir le choix par defaut du futur
lanceur. Les profils stock restent disponibles pour le diagnostic et le retour
arriere, pas comme configuration normale de l'add-on.

## Reconstruction locale du test 4.08m du 30 aout 2026

### Base DVD 4.07m authentique

L'ISO historique conserve dans `res` a ete exploite en lecture seule. Les deux
archives CAB ont fourni 19 474 fichiers ; leurs noms et dossiers ont ete
reconstruits depuis les tables `Directory`, `Component` et `File` du MSI avec
`tools\Reconstruct-IL2Retail407.ps1`. Le MSI contient volontairement un
`il2fb.exe` vide : le script le remplace explicitement par l'executable de
3 833 856 octets place a la racine du DVD.

La base temporaire obtenue contient exactement 19 474 fichiers et
4 575 508 511 octets. Les 47 SFS 4.07m attendus sont presents. Aucun chemin MSI
n'est absent, duplique, hors du dossier du jeu ou de taille incorrecte.

| Fichier 4.07m | Taille | SHA-256 |
| --- | ---: | --- |
| `files.SFS` | 22 406 460 | `AED995F360086F1B669983A8E7DA253EB08C92B57D969F33DCE09A8B4123BB33` |
| `il2fb.exe` | 3 833 856 | `0A0F478994455A4AF2C9942F64DFAC6769885C2512795D48ED09E0A216D16EC7` |
| `il2_core.dll` | 1 388 544 | `AE1B06F2D4F6CC14A535FC47DF66D53A3DB1AE2BBA49A20F94BD109A03E6CE9C` |
| `il2_corep4.dll` | 1 470 464 | `9D7D89C664D490EDBED97836FA810BB88BBAFA7D37A7B8D1DC76D15050F79A15` |
| `mg_snd.dll` | 311 296 | `A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C` |
| `mg_snd_sse.dll` | 356 352 | `3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F` |

Cette reconstruction confirme aussi que les dix SFS recuperes dans l'ancienne
sauvegarde UP ont les tailles du DVD. La base authentique devient desormais
l'oracle local pour verifier l'installation de l'add-on ; elle reste hors de
Git et hors des ressources protegees.

### Ancienne copie de test hybride

La copie de test provenait d'une installation 4.14.1m sur laquelle le profil
4.08m n'avait remplace que quelques fichiers. La comparaison avec une ancienne
sauvegarde UP a donne :

- 36 SFS de base presents avec la taille historique attendue ;
- huit SFS 4.07m absents ;
- `fb_3do08p.SFS` remplace par une variante plus recente de 565 138 741 octets ;
- `fb_3do10p.SFS` remplace par un fichier bouchon de 934 octets.

Les dix fichiers suivants ont ete restaures localement dans le seul dossier de
test. Ils restent hors de Git et ne doivent pas etre distribues avec le depot :

| Fichier | Taille | SHA-256 |
| --- | ---: | --- |
| `fb_3do08p.SFS` | 538 161 306 | `537C6F2618730530B1E40124D4D38BD34BF5C96C9F52015776596FBDE306363E` |
| `fb_3do09p.SFS` | 26 904 733 | `07EAB7DF33FFE889DBCFF710286DB275F4EBEFE95EEB5EEC5732D2424457AE7B` |
| `fb_3do10p.SFS` | 40 172 384 | `F7EF82FCD0925B8145A3248E9D587B6DE270FC55D6D49AB54AE2E3237BECA993` |
| `fb_maps02.SFS` | 1 610 461 | `4D890F153672C5800E53D4822E31155EFF137BC9225B36669BE91615D15EE02D` |
| `fb_sound.SFS` | 29 092 461 | `D01DDE5DF1485E5784AF297131C8E5BF2E1493B713819096BD6DEF173E66C276` |
| `fb_sound01.SFS` | 1 243 147 | `0256238B4E00EA1F94F99E0EA5942245C41E7F461B0163F0FF03FDD32DAE2C3E` |
| `fb_sound02.SFS` | 410 119 | `C98646927A977A91842D172F8F2AC69C231D94E57EF4C413AC9952E38D1C3EDE` |
| `fb_sound03.SFS` | 1 040 922 | `2C1F7F3C8E853E22C00C8C258E475E6B53C5723ECC6918487F712C48EC058FE9` |
| `fb_sound04.SFS` | 856 449 | `23125A90DC7E37375816BC27C1EA095806FBF8BDA56CB67B8CD3A61B14B59FEB` |
| `fb_sound05.SFS` | 886 957 | `FE73C921401756FDDCE341D14F875CF6AB8FC7B0F030447BD40F165E276B8366` |

Vingt-huit SFS et 4 076 332 857 octets etrangers a la 4.08m ont ete supprimes
du dossier de test :

```text
fb_3do19.SFS, fb_3do20.SFS,
fb_3do21.SFS, fb_3do21server.SFS,
fb_3do22.SFS, fb_3do22server.SFS,
fb_3do23.SFS, fb_3do23server.SFS,
fb_3do24.SFS, fb_3do24server.SFS,
fb_3do25.SFS, fb_3do26.SFS, fb_3do27.SFS, fb_3do28.SFS,
fb_3do29.SFS, fb_3do30.SFS, fb_3do31.SFS, fb_3do32.SFS,
fb_maps15.SFS, fb_maps16.SFS, fb_maps17.SFS, fb_maps18.SFS,
fb_maps19.SFS, fb_maps21.SFS, fb_maps22.SFS, fb_maps23.SFS,
fb_sounds.SFS, filesserver.SFS
```

Le resultat contient 49 SFS : la base historique jusqu'a 4.07m, le delta
4.08m et son `files.SFS` officiel. Les SFS supprimes restent recuperables depuis
l'installation originale 4.14.1m en lecture seule et les archives de sauvegarde.

## Regles pour le lanceur et l'installation

1. Une installation 4.07m validee est le point de depart normal de la 1.15.
2. Chaque version possede un manifeste exhaustif de fichiers requis, interdits
   et remplaces ; la presence d'un fichier du mauvais millesime fait echouer la
   validation.
3. Un changement de profil est transactionnel : SFS, DLL, EXE, `files.SFS`,
   `air.ini`, `stationary.ini` et wrapper sont verifies comme un seul ensemble.
4. Le profil par defaut est Open Sturmovik 4.09m complet. Les contenus libres du
   dossier `Files` et leurs textures 2K/4K y sont actifs par le wrapper.
5. La compatibilite entre mods est validee par registres, chemins remplaces,
   classes Java, journaux de chargement et essais en jeu. Un conflit connu doit
   etre resolu ou le composant mis en quarantaine avant activation par defaut.
6. Une installation 4.14.1m ne doit jamais etre « retrogradee » en ne copiant
   que les anciens fichiers du selecteur.

Pour l'ordre officiel des patchs, voir le
[guide de mise a jour IL-2 1946 de Mission4Today](https://www.mission4today.com/index.php?file=print&kid=584&name=Knowledge_Base&page=1).
