# Préparation de l'installation complète v1.15

La v1.15 sera une réinstallation complète d'Open Sturmovik sur une installation
compatible d'IL-2 Sturmovik 1946. Elle ne sera pas un patch de la v1.10 et
ne devra dépendre d'aucune installation préalable d'Open Sturmovik.

L'ancienne ébauche Inno Setup `Open_Sturmovik_Update_1.15.iss` et ses deux
fonds `OpenSturmovik-Wizard.bmp` et `OpenSturmovik-Wizard.jpg` ont été supprimés
par Alexis le 12 septembre 2026. Aucun script d'installation v1.15 n'est
actuellement fourni. Le futur installateur complet reste à créer et à valider.

Le contenu à préparer pour sa distribution comprend :

```text
Payload/
  LICENSE.md
  docs/
    LICENSING.md
    THIRD_PARTY_NOTICES.md
  ...ensemble complet des fichiers du pack, à leur emplacement dans le jeu...
```

Le dossier `Payload` n'est volontairement pas fabrique avant le gel du contenu
v1.15. Cette separation empeche qu'un ancien test, un fichier WIP ou une
ressource de developpement entre silencieusement dans l'installateur.

## Licence a conserver dans la distribution

Le futur `Payload` doit inclure `LICENSE.md`, `docs/LICENSING.md` et
`docs/THIRD_PARTY_NOTICES.md` depuis le depot, ainsi que les credits et notices
des composants tiers effectivement fournis. Leur présence à la racine Git
ne garantit pas leur inclusion dans l'exécutable : le futur installateur
devra les livrer avec le contenu de `Payload`.

La licence des contributions originales d'Alfly autorise les usages,
modifications, forks et partages non commerciaux. Tout usage commercial de
ces contributions, meme modifiees, est interdit. Le contenu tiers
de l'installateur conserve ses conditions propres ; la licence de la logique
de l'installateur ne concede pas de droits sur tout son contenu.

Ces documents doivent etre controles au meme titre que les autres fichiers
du `Payload` avant compilation. Aucun `Payload` ni nouvel executable n'est
produit par l'ajout de cette licence.

## Compilateur portable prepare

Inno Setup 7.1.0 x64 est prepare en mode portable officiel sous
`WIP/sdk/inno-setup-portable/Inno Setup 7.1.0`. Le compilateur est
`ISCC.exe` dans ce dossier. L'installateur source officiel est conserve sous
`WIP/sdk/inno-setup-portable/downloads` avec sa signature `.issig`.

Contrôles consignés lors de la préparation du compilateur :

- SHA-256 de l'installateur :
  `0362A383ED217D4C4239B5933866DD96D3EB2102737DA92F80F6057A4B40DF2F` ;
- empreinte identique a celle inscrite dans la signature officielle `.issig` ;
- signature Authenticode valide, editeur `Pyrsys B.V.` ;
- `ISCC.exe --version` retourne `7.1.0` ;
- aucun desinstalleur portable n'a ete cree.

Le compilateur ne doit pas etre utilise avant la fin des essais runtime de la
v1.15 et le gel explicite du dossier `Payload`.

## Exigences du futur installateur complet

- reconnaître une installation IL-2 compatible et vérifier ses fichiers
  nécessaires, au-delà de la seule présence d'`il2fb.exe` ;
- remplacer les fichiers seulement lorsque le jeu est fermé ;
- livrer le pack complet depuis `Payload` en conservant son arborescence,
  sans dépendance à une ancienne version d'Open Sturmovik ;
- prévoir une procédure de réinstallation qui assure l'absence des composants
  retirés et préserve les données personnelles du joueur ; toute suppression
  devra reposer sur une liste explicite et vérifiée ;
- créer huit raccourcis sur le Bureau : les sept outils retenus et
  `Open Sturmovik Switcher` ;
- faire lancer par le raccourci `Open Sturmovik Switcher` l'unique BAT avec une console
  masquee ; le BAT reste directement utilisable et ne garde plus la console
  ouverte une fois son interface chargee ;
- utiliser l'initialiseur des utilitaires pour configurer les chemins locaux sans lancer le
  jeu ni les programmes externes ;
- intégrer le diagnostic automatique existant : il active les journaux persistants, configure cinq
  dumps WER au maximum, surveille chaque lancement direct de `il2fb.exe` et met
  en file les anomalies avant leur envoi vers les tickets du depot Open
  Sturmovik.

Lors de cette installation, le moniteur devra être lancé sous le compte Windows
d'origine, puis enregistré dans `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
Ses données locales devront rester
placees sous `%LOCALAPPDATA%\OpenSturmovik\Diagnostics`. Le transport actuel
utilise un service HTTPS public : aucun compte GitHub, jeton ou client Git
n'est requis sur le PC du joueur. Les dumps mémoire bruts restent locaux.

Le fond du switcher retenu le 11 septembre 2026 est la remasterisation de la
jaquette Pacific Fighters Retail, livree sous
`Resources\Backgrounds\Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.png`.
Le dossier `Resources\Icons` contient les deux icones actives.
`Open_Sturmovik_Switcher.ico`, issu du dessin `logo-IL2-B`, est l'icone de la
fenetre et du raccourci. `Open_Sturmovik_Game.ico`, issu du dessin
`avion-ciel`, est reserve aux executables de jeu modifies.

Les observations sur la détection et les suppressions de l'ancienne ébauche
sont conservées comme historique dans
[l'audit de sortie](../docs/AUDIT_SORTIE_V1.15_20260912.md).
Elles ne décrivent pas un installateur actuellement disponible.

## Controle avant compilation

Le futur installateur doit reconnaître une base IL-2 compatible et livrer
le pack complet. La procédure de réinstallation doit garantir l'absence
des anciens composants retirés, notamment MDS, DCG, San et Malta, tout en
préservant les données personnelles du joueur. La copie générique et la
liste de suppressions de l'ancienne ébauche ne suffisaient pas à établir ce résultat.

Avant de compiler, il faudra produire le dossier `Payload`, verifier ses
empreintes, puis executer les controles hors-jeu v1.15. La compilation Inno
Setup doit enfin etre essayee dans une copie jetable du jeu, jamais directement
sur l'installation de reference.

Lowengrin DCG et San FOV Changer ne sont plus fournis : leur redistribution
necessite une autorisation de leur auteur. Leurs fichiers et notices sont
archives localement hors du paquet. L'initialisation des outils restants
conserve les reglages DeviceLink, FOV et SaveAspect du joueur.
