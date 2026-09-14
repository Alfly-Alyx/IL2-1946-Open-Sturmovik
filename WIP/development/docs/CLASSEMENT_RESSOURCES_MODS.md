# Classement des ressources de mods

Regle demandee par Alexis le 6 septembre 2026.

Racine : `D:\Projets\GITHUB\#res\IL2 1946\Mods`.

- `Retirés` : sources et sauvegardes de mods retires du jeu.
- `Utilisés` : sources des mods dont tout ou partie est integre au jeu.
- `Reserve` : sources conservees sans integration actuelle.

Ce classement ne deplace ni ne supprime les fichiers actifs du jeu. Un mod
integre n'est pas necessairement valide en jeu. Les versions, les dependances
et le perimetre d'integration restent documentes dans les manifestes.

## Classement du 6 septembre

Mise a jour du 12 septembre 2026 : DCG 3.43, San FOV 1.0 et Malta de
6S.Maraz sont retires du contenu distribue et sauvegardes dans
`Retirés\besoin_licence`, avec un sous-dossier par composant. Il s'agit
d'un seul dossier `besoin_licence`, selon la confirmation d'Alexis.
Les inventaires distinguent fichiers retires, configurations avant modification
et sources historiques. Le dossier Zuti y conserve la recherche de contact ;
sa presence dans ce classement ne signifie pas que le retrait du code est fini.
Voir [le detail et les limites](RETRAIT_COMPOSANTS_V1.15.md).

| Ressource | Dossier | Justification |
| --- | --- | --- |
| Tiger33 Ultimate Sound Mod V3 | Utilisés | Sons/presets partiellement integres ; les SFS sources ne sont pas montes en bloc. |
| B29 Silverplate v1.2 | Utilisés | Des ressources sont deja integrees, notamment le cockpit B-29-SP. Le report du chantier nucleaire ne signifie pas leur desinstallation. |
| Cockpit_CW-21_for409.zip | Utilisés | Cockpit integre apres audit des dependances 4.09m ; deux armements au choix, validation en jeu encore requise. |
| RMP3_Atmosphere_nuages_avant_WxTech_PARTIEL.zip | Retirés | Sauvegarde des sept anciennes ressources de nuages issues de Git, avec notice. Ce n'est pas l'archive complete de RMP3 Atmosphere. |

Le fichier original du cockpit dans Telechargements est conserve.

L'archive CW-21 a pour SHA-256
`CB6FC40E2ACEFC8F479B00AC5E07FCFAF400633B3882B155AFE7736C6C451DB3`.
Elle correspond a la publication
[Cockpit CW-21 4.09 sur SAS](https://www.sas1946.com/main/index.php?topic=49201.0).

Pour RMP3, voir [l'audit de preservation](RMP3_ATMOSPHERE_PRESERVATION.md).
L'inventaire complet des autres mods du jeu n'est pas constitue par cette
premiere operation de classement.
