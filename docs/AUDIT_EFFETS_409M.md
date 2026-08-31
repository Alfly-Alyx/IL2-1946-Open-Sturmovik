# Audit des effets et limites du moteur 4.09m

Derniere mise a jour : 31 aout 2026.

## Origine du diagnostic

Le lancement Selector/Dump du 30 aout 2026 a produit 63 messages
`Str2FloatClamp`. Le journal associe ces messages au prechargement des effets et
indique pour chacun la valeur demandee, la valeur retenue et la borne du moteur.
Le profil stock n'en a produit aucun.

Les fichiers ne provoquaient pas un plantage : le moteur les corrigeait en
memoire. Ils etaient tout de meme defectueux pour la cible 4.09m, generaient du
bruit dans les journaux et demandaient au moteur de parser des intentions qu'il
ne pouvait pas appliquer.

## Bornes observees

| Parametre | Minimum | Maximum |
|---|---:|---:|
| `nParticles` | 1 | 512 |
| `FinishTime` | -1 | 10 000 |
| `MaxR` | 0 | 32 |
| `PhiN` | 0 | 32 |
| `PsiN` | 0 | 32 |
| `LiveTime` | 0,01 | 128 |
| `TranspTransitionTime` | 0 | `LiveTime` apres bridage |
| `Wind` | 0 | 100 |
| `Rnd` | 0 | 0,95 |

Ces valeurs ne sont pas des recommandations visuelles : ce sont les intervalles
affiches par le moteur 4.09m lui-meme. Une valeur placee exactement a la borne
produit donc le meme resultat que l'ancienne valeur hors limite apres bridage.

Exemple : `BlackHeavyGND.eff` demandait 1 024 particules ; le moteur en utilisait
512. Le fichier normalise demande directement 512. L'effet visuel reel ne perd
aucune particule par rapport au comportement observe.

## Correction appliquee

`tools/Normalize-EffectLimits.py` analyse seulement les fichiers dont la classe
est `TParticlesSystemParams` ou `TSmokeSpiralParams`. Il ignore les autres types
et les champs dont la borne n'a pas ete observee. Il ecrit chaque fichier de
maniere atomique uniquement avec `--apply`.

| Resultat | Nombre |
|---|---:|
| Fichiers `.eff` libres analyses | 298 |
| Fichiers libres normalises | 168 |
| Valeurs libres normalisees | 179 |
| Valeurs `nParticles` normalisees | 138 |

Le manifeste `manifests/effects/effect-limit-audit.json` conserve pour chaque
changement : chemin, ligne, classe, champ, ancienne valeur, nouvelle valeur,
bornes et empreintes SHA-256 avant/apres.

Une 180e valeur se trouvait dans les `files.SFS` stock et modde 4.09m :
`Effects/Smokes/SmokeBoiling.eff` demandait 2 000 particules. L'extraction
ciblee confirme dans les deux archives le meme contenu de 378 octets et la meme
empreinte `F1D6845FCC6232F0C0FB43AB134CB647ADDFBEA1F7F27AE9ACC8788872D94216`.
Plutot que de
repaqueter l'archive, une surcharge libre identique a l'effet effectif a ete
ajoutee avec `nParticles 512`. La provenance et les empreintes sont dans
`manifests/effects/sfs-effect-overrides.json`.

## Reproduction et retour arriere

Audit seul :

```powershell
python .\tools\Normalize-EffectLimits.py
```

Appliquer et produire le manifeste :

```powershell
python .\tools\Normalize-EffectLimits.py --apply `
  --report manifests\effects\effect-limit-audit.json
```

Apres application, l'audit seul doit retourner zero fichier et zero valeur a
normaliser. Le validateur general controle en plus les 168 empreintes finales et
la surcharge issue du SFS.

Le retour arriere se fait par Git pour les fichiers libres ; le `files.SFS`
d'origine n'a jamais ete modifie.

## Validation runtime encore requise

Le prochain demarrage doit produire zero `Str2FloatClamp` pendant le prechargement.
Les missions de test devront ensuite charger les effets A5M, grandes explosions,
navires, vehicules et epaves afin de couvrir aussi les 116 valeurs qui n'avaient
pas encore ete sollicitees lors du passage limite au menu.
