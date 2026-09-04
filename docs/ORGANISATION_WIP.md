# Organisation du dossier WIP

Derniere mise a jour : 4 septembre 2026.

`WIP/` regroupe les donnees locales et volumineuses necessaires au travail sur
Open Sturmovik. Ce dossier est ignore par Git et ne fait pas partie de
l'add-on distribue.

Organisation retenue :

- `WIP/captures/` : captures, traces, journaux et mesures des essais ;
- `WIP/resources/` : ressources fournies par Alexis, en lecture seule sauf
  autorisation explicite ;
- `WIP/test-installations/` : installations actives servant aux essais ;
- `WIP/test-backups/` : sauvegardes transactionnelles des fichiers modifies ;
- `WIP/labs/` : clones et extractions de laboratoire ;
- `WIP/sdk/` : outils actifs, dependances et sorties de compilation ;
- `WIP/tmp/` : extractions et recherches temporaires encore utiles.

Les sources reproductibles restent a la racine du depot : `tools/`,
`test-assets/`, `manifests/`, `docs/` et `native/`. Les composants livres avec
Open Sturmovik restent eux aussi a la racine.

Le dossier externe
`D:\Projets\GITHUB\#res\IL2 1946\Outils` est uniquement une sauvegarde
patrimoniale des outils de compilation, decompilation, compression et
decompression. Il ne doit pas etre utilise comme repertoire de travail. Les
outils y sont ajoutes sans ecraser une archive existante ; une copie exploitee
pendant le developpement peut etre placee sous `WIP/sdk/`.

Le jeu original de reference reste protege sous
`WIP/resources/IL2/IL 2 Sturmovik 1946`. Il ne doit jamais etre modifie.

Les sauvegardes completes ne doivent pas s'accumuler. Apres verification
SHA-256, elles sont remplacees par un dossier `.delta` contenant uniquement les
fichiers absents ou differents, plus le rapport de redondance et un manifeste
d'empreintes. Une sauvegarde SFS differente n'est jamais supprimee au seul motif
qu'une version plus recente existe.

Les captures brutes restent utiles tant que l'analyse du chargement, des gels
ou du moteur n'est pas close. Les traces surdimensionnees ne sont supprimees
qu'apres conservation des mesures et conclusions et apres autorisation
explicite lorsqu'elles pourraient encore servir a la retro-ingenierie.
