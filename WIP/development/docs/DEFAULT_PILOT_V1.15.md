# Pilote par defaut et preservation des profils — v1.15

## Demande et etat au 6 septembre 2026

Open Sturmovik est une conversion complete appliquee sur une installation
deja complete d'IL-2, et non un standalone. La conversion des fichiers du jeu
ne doit pas etre confondue avec le remplacement des donnees personnelles.
Le jeu de base peut deja fournir `Users/all.ini` avant le premier vol : la
simple presence d'un fichier ne prouve donc pas qu'un joueur a deja joue.

Alexis a choisi **Jack "Hawk" Miller** pour le nouveau pilote par defaut,
puis precise qu'un joueur ayant deja joue et cree son profil ne doit pas etre
renomme. Un nom d'origine ne prouve pas qu'un profil est inutilise.

La mise a jour ne doit donc modifier **aucun** profil existant : identite,
identifiant du dossier, ordre de la liste, pilote selectionne, commandes,
reglages et progression. Les noms russes ou John / Mad / Doe sont proteges
comme les noms personnalises. Un registre absent, vide ou incomplet ne donne
pas a l'installeur l'autorisation de reconstruire les profils.

Mesures appliquees : suppression du script de migration
`tools/Set-OpenSturmovikDefaultPilot.ps1`, de ses tests de renommage et de ses
appels dans Inno et dans la finalisation de la mise a jour ; exclusion ancree
`\Users\*` sur la copie recursive du payload Inno.

Le changement du nom code en dur **n'est pas encore integre**. Il devra viser
la creation initiale, sans migrer les profils sauvegardes. La compatibilite
de toute classe remplacee devra etre verifiee par version avant integration.
La proposition d'Alexis de ne pas ecraser `UserCfg` si present ne doit pas etre
confondue avec la protection des donnees : cette classe est du code partage,
et non un fichier personnel cree lorsqu'un joueur configure son profil.

## Faits observes dans les ressources locales

Source prioritaire lue :
`D:\Projets\GITHUB\#res\IL2 1946\0 - ORIGINAL GAMES DO NOT USE\Il-2 Sturmovik 1946 _4.09m\Users\all.ini`.
Elle contient `[list]`, l'entree `doe John Mad Doe`, puis `[current]` avec `0`.
Le nom affiche n'est donc pas le nom du dossier : `doe` est l'identifiant
de profil, `John Mad Doe` son identite, et `0` l'index selectionne.

Analyse locale de la classe du dump 4.09m :
`WIP/analyses/labs/IL 2 Sturmovik 1946 Selector Dump/dump/com/maddox/il2/ai/UserCfg.class`.
Lecture avec CFR 0.152 ; sortie de travail :
`build/default-pilot-audit/com/maddox/il2/ai/UserCfg.java`.

Faits tires de la decompilation, confiance elevee pour cette classe, sans
validation d'execution de ce comportement lors de ce controle :

- l'initialiseur statique de `com.maddox.il2.ai.UserCfg` definit `defName`,
  `defCallsign`, `defSurname` selon `Config.LOCALE` : Ivan / Vanya / Ivanov
  pour RU, John / Mad / Doe autrement ;
- `loadCurrent()` lit les champs du pilote selectionne dans `users/all.ini`.
  Les valeurs par defaut servent aussi de repli si un champ manque. Modifier
  globalement ces constantes aurait donc un effet plus large que la seule
  creation initiale : ce point doit etre traite avant un correctif interne ;
- `createDefault()` est appele si le registre est absent, si `[list]` ou
  `[current]` manque, ou si la liste est vide. Il reecrit le registre et cree
  le dossier et les reglages du nouveau pilote ;
- `createUserDir()` comporte une suppression de dossier existant. Aucun de
  ces chemins de controle n'a ete modifie. La mise a jour ne doit pas les
  appeler pour imposer une nouvelle identite.

Pour reproduire l'analyse sans lancer le jeu :

```powershell
java -jar WIP/dependances/sdk/test-tools/cfr-0.152.jar "WIP/analyses/labs/IL 2 Sturmovik 1946 Selector Dump/dump/com/maddox/il2/ai/UserCfg.class" --outputdir build/default-pilot-audit --silent true
```

## Copie de test : exception deja autorisee

Avant cette precision, le registre de la copie de test avait ete renomme
avec l'accord d'Alexis. `Users/all.ini` contient maintenant
`0 Jack Hawk Miller`, avec le meme index courant `0`. Le dossier `Users/0`
n'a pas ete renomme et l'empreinte de `Users/0/settings.ini` etait inchangee.
Sauvegarde du registre initial :
`WIP/tests/installations/IL 2 Sturmovik 1946 test/Users/all.before-hawk-f05761338b5048a69e186f7330b7912f.ini`.
Cette operation de test n'est pas une migration a distribuer. Aucun nouveau
changement de ce registre n'est effectue pour cette correction.

## Verification et limites

Controles statiques : exclusion de Users et absence de migration appelee dans
Inno, absence de chemin de profil dans les etapes de finalisation, syntaxe
PowerShell des etapes conservees : controles passes le 6 septembre 2026.
Ces controles ne constituent pas un essai
du futur installeur compile ni un test en jeu.

Avant diffusion, tester sur des copies jetables : registre personnalise,
ancien nom russe, ancien nom anglais, plusieurs pilotes avec selection non
nulle, registre absent avec dossiers existants et registre incomplet.
Comparer tous les chemins et empreintes sous Users avant/apres installation :
ils doivent etre identiques, y compris sans renommage des profils d'origine.
La creation du nouveau pilote demandera un essai distinct apres integration
du defaut interne, sans reutiliser ni supprimer un profil joueur existant.

## Sources externes consultees

- AAA / All Aircraft Arcade via Wayback, prioritaire : tentative de lecture
  de `https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/`
  en echec d'acces ; aucun contenu suppose.
- [Mission4Today : profils dans all.ini](https://www.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&printertopic=1&start=0&t=13876)
  et [conservation des reglages/progression](https://www.mission4today.com/index.php?file=viewtopic&finish=15&name=ForumsPro&printertopic=1&start=0&t=4401).
  Corroboration communautaire du role du dossier Users, pas preuve des
  instructions exactes du moteur 4.09m.
- SAS : recherches ciblees `Users/all.ini` et `all.ini pilot`, sans resultat
  pertinent exploitable ; pas de corroboration revendiquee.
- [Documentation officielle Inno, section Files / Excludes](https://jrsoftware.org/ishelp/topic_filessection.htm) :
  le prefixe `\` ancre le motif a la racine source et `*` exclut son contenu
  lors de la copie recursive.
