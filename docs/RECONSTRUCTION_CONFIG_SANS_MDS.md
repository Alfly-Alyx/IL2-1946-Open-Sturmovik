# Config sans MDS — vérification indépendante du 12 septembre 2026

La classe reconstruite `com.maddox.il2.engine.Config` retire l'historique de
serveurs ajouté par MDS tout en conservant les réglages réseau ordinaires et
le titre Open Sturmovik. Cette vérification porte sur le candidat ; elle ne
remplace pas les essais complets du moteur et du réseau en jeu.

## Sources locales et empreintes

| Classe | SHA-256 |
| --- | --- |
| Config initiale du pack, `Files/5D18E55E5DF1D418` | `8CEF8D5EC9EAAAC27D2797462E33B9FC5EED4506C3B8B273B4553292CBA20A94` |
| Config reconstruite | `FE230776544C329C68E658EC6E293936F31116508D42F7BE43FF5EC68EDCBB5B` |
| Config de référence 4.09m Mods ON | `EC3B4B3B4E03336378883DA41412DAF7BACE6675B04032D2A8C53E7AD13E44ED` |

La référence vient du SFS `_Game Switcher/4.09 final Mods ON (NO 6DOF)/files.SFS`
contrôlé dans [l'audit initial](AUDIT_RETRAIT_ZUTI_V1.15_20260912.md). La variante
Config du SFS Mods OFF n'est pas interchangeable avec celle-ci. Aucune classe
issue des forums ou d'un autre pack n'a été intégrée par cette vérification.
Les limites d'accès aux sources historiques sont consignées dans cet audit.

## Résultats vérifiés — confiance élevée

La comparaison CFR 0.152 de l'original et du candidat montre uniquement le
retrait du champ `zutiServerNames`, de ses deux initialisations, de
`zutiLoadServers`, `zutiGetServerNames`, `zutiAddServerName`, de l'appel depuis
`loadNet` et de la boucle de sauvegarde des clés `remoteHost_000` à la suite.
Le constructeur, `loadNet` et `saveNet` sont les trois méthodes modifiées.
Les 31 autres méthodes sont conservées par comparaison ASM.

Le candidat conserve les deux affectations du titre « Open Sturmovik » :
valeur initiale du constructeur et affectation effective dans
`createGlContext(String)`. La seule modification du titre initial ne suffirait
pas à préserver le titre lors du démarrage normal.

Les méthodes `loadNet` et `saveNet` du candidat et de la référence 4.09m ON
produisent le même texte décompilé. Les ports, la vitesse réseau, l'hôte
distant, les canaux, le téléchargement des habillages, le nom et la
description du serveur, les contrôles de vitesse du temps et le proxy SOCKS
restent présents. Le plafond de canaux est toujours 31 avec affichage et
128 sans affichage. Aucun champ ou appel interne devenu introuvable ne reste
dans le candidat ; toutes ses méthodes passent ASM `BasicVerifier`.

La sortie conserve la version ClassFile 45.3, compatible Java 1.3. Son pool
de constantes ne contient plus `Zuti`, sans distinction de casse.

## Test JVM indépendant

[`TestConfigWithoutMds.java`](../tools/java/TestConfigWithoutMds.java) exécute
le vrai bytecode du constructeur, de `loadNet`, de `saveNet` et de
`isUSE_RENDER`, dans une classe isolée. Seuls l'initialisation native et
`Config.load` sont neutralisés dans cette classe de test. Les dépendances
IniFile, SOCKS, UnicodeTo8bit et NetChannel sont remplacées par des doubles
en mémoire ; leurs signatures correspondent aux appels du bytecode réel.
La valeur `localHost` reste nulle, donc la branche d'ouverture d'une socket
n'est pas exécutée. Aucun fichier de réglages ni processus du jeu n'est utilisé.

Quatre scénarios ont réussi : affichage activé/désactivé, chacun avec proxy
configuré ou paramètres de proxy par défaut. Pour chaque scénario, le
candidat et la référence stock donnent les mêmes champs réseau, les mêmes
valeurs INI et la même suite d'accès INI. Les assertions contrôlent également
les limites de canaux, les ports, la vitesse, le téléchargement des habillages
et le nom du serveur. Une clé historique MDS préexistante reste inchangée et
n'est jamais lue ni écrite.

Ces doubles ne testent pas le réseau réel, la résolution de noms, le codage
Unicode, le stockage disque ni l'initialisation native. Les appels vers ces
fonctions sont conservés ; leur fonctionnement complet reste à qualifier.

## Reproduction

Depuis un dossier de tâche sous `C:\Users\Alexis\.codex`, avec un JDK 17,
compiler les sources
[`OpenSturmovikConfigWithoutMds.java`](../tools/java/OpenSturmovikConfigWithoutMds.java)
et `TestConfigWithoutMds.java` vers un dossier de classes de travail.
Pour `javac` et `java`, exporter vers `ALL-UNNAMED` les quatre modules internes
`java.base/jdk.internal.org.objectweb.asm`, `.asm.tree`, `.asm.tree.analysis`
et `.asm.util`, à l'aide de paires d'arguments `--add-exports`.

1. Exécuter `OpenSturmovikConfigWithoutMds` avec le chemin du Config original
   puis le chemin de sortie du candidat. Le constructeur refuse toute entrée
   dont l'empreinte diffère de la source du tableau.
2. Exécuter `TestConfigWithoutMds` avec le chemin du candidat puis celui du
   Config stock ON extrait. Le test ne modifie aucune de ces classes.
3. Vérifier l'empreinte `FE230776...` de la sortie. Une compilation et une
   reconstruction indépendantes ont reproduit exactement cette empreinte.

Le constructeur de marquage `Build-OpenSturmovikBranding.ps1` a aussi été relu :
il accepte directement le candidat propre. Pour une version historique
reconnue, il applique d'abord le marquage, vérifie l'empreinte intermédiaire,
retire l'historique MDS puis exige l'empreinte finale avant de remplacer le
Config actif. Cette revue n'a pas exécuté ce constructeur sur le jeu.
