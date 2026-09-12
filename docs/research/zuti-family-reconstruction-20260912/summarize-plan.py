"""Make a bounded file plan and narrative from a successful preflight audit."""
from pathlib import Path
import argparse
import hashlib
import json


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repository-root', type=Path, required=True)
    args = ap.parse_args()
    root = args.repository_root.resolve()
    folder = root/'docs/research/zuti-family-reconstruction-20260912'
    source = folder/'qualified-inventory.json'
    data = json.loads(source.read_text(encoding='utf-8'))
    checks = ('new_linkage_failures', 'missing_changed_classes', 'new_member_access_failures',
              'changed_static_instance_members', 'effective_zuti_class_strings')
    assert set(data['profiles']) == {'4.08m', '4.09b', '4.09m'}
    for version, profile in data['profiles'].items():
        assert all(not profile[k] for k in checks), version
    lookup = {v: {x['class']: x for x in p['changes']} for v, p in data['profiles'].items()}
    files = []
    for item in data['fallback_files']:
        files.append({**item, 'action': 'archive_exact_bytes_then_remove_loose_override',
            'profile_fallback': {v: {'class_present_in_sfs': lookup[v][item['class']]['donor_exists'],
                'class_sha256': lookup[v][item['class']]['donor_sha256']}
                for v in lookup}})
    plan = {'schema': 'open-sturmovik-mds-family-preflight-v1', 'date': '2026-09-12',
        'branch': 'v1.15', 'repository_root': str(root),
        'scope': 'Exact Java loose files only; no command is executed by this plan. Runtime validation remains separate.',
        'evidence': str(source.relative_to(root)),
        'evidence_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'unique_classes': data['family_fallback_count'], 'file_count': len(files),
        'excluded_roots': data['excluded_roots'], 'rebuilt_overlays': data['rebuilt_overlays'],
        'source_archives': {v: {k: p[k] for k in ('archive', 'archive_sha256', 'original_archive', 'original_sha256')}
            for v, p in data['profiles'].items()},
        'preconditions': ['Archive and compare SHA-256 for every exact input before removal.',
            'Recheck current branch, root, tracked status and absence of unexpected reparse points.',
            'Install all four qualified rebuilt overlays in the same transaction.',
            'Never replace the profile-specific SFS with one common donor.',
            'Do not alter independent aircraft, cockpit, 6DOF, registry, map or asset files.'],
        'files': files}
    (folder/'retirement-plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    rows = []
    for family in data['families']:
        if 'zuti' in family['family'].lower():
            continue
        names = family['direct']+family['companions']
        donors = sum(lookup['4.09m'][n]['donor_exists'] for n in names)
        rows.append('| '+family['family'].replace('com/maddox/il2/', '')+' | '+str(len(family['direct']))+' | '
                    +str(len(family['companions']))+' | '+str(donors)+' | '
                    +('Reconstruction deleguee' if family['delegated'] else 'Famille SFS du profil')+' |')
    text = '''# Reconstruction du moteur sans MDS — v1.15, 12 septembre 2026

## Resultat et perimetre

Cet examen prepare le retrait demande par Alexis. Il conserve l'audit historique
`AUDIT_RETRAIT_ZUTI_V1.15_20260912.md`. Il ne modifie aucun fichier actif du moteur.
Le plan exact est `research/zuti-family-reconstruction-20260912/retirement-plan.json`.

Le retour coherent aux familles d'origine concerne **543 classes uniques dans
544 fichiers loose**. Le doublon est `ZutiTimer_ExtendPlanesWings`, present a
l'adresse hachee et au chemin Java explicite. La liste comprend les classes
MDS et les compagnons de leurs familles, meme sans chaine Zuti.
`Config`, `Controls`, `Motor` et toute la famille `Explosions` restent hors du
retrait automatique ; leurs quatre reconstructions propres sont simulees ici.
`FlightModelMain` et `RealFlightModel` sont aussi hors de ce plan.

Dans les trois profils **4.08m, 4.09b et 4.09m**, la simulation complete avec les
quatre candidats a trouve **zero nouvelle reference de membre introuvable,
zero classe retiree encore referencee, zero nouvelle restriction d'acces,
zero changement statique/instance et zero chaine Zuti dans les classes
effectives inspectees**. Ce sont des resultats statiques, pas une validation en vol.

## Pourquoi 322 classes ne suffisent pas

Le premier audit comptait 253 classes directement marquees et 308 compagnons.
Une fermeture des seuls appels manquants donnait 322 candidats provisoires.
Elle ne detectait pas un appel restant valide mais changeant de sens.
La comparaison du bytecode resout les constantes et normalise les cibles de
branche. Elle trouve 28 methodes `access$` dont la signature reste identique
mais dont le corps change de cible dans chaque version :

- `Gear.access$200()` lit `corn` avant retrait et `corn1` dans le SFS.
- `Gear.access$402(boolean)` ecrit `bPlateExist` avant et `bPlateGround` apres.
- `GUIAirArming.access$1000()` appelle `prepareWeapons` avant et `prepareSkin` apres.
- `GUIPad.access$300()` appelle `zutiDrawBornPlaces` avant et `drawChiefs` apres.
- `NetServerParams.access$702(...)` ecrit `difficulty` avant et `autoLogDetail` apres.
- `NetAircraft.access$500()` lit `corn` avant et `pship` apres.
- La famille `BigshipGeneric` contient plusieurs autres changements de cible.

Les classes anonymes et les accesseurs synthetiques doivent donc venir de la
meme compilation que leur classe englobante. Sur 308 compagnons, 297 existent
dans les SFS, 11 sont propres a la famille modifiee. Parmi les 297, 89 ont des
corps normalises et des declarations identiques ; les 208 autres different.
Une difference de corps normalise peut aussi provenir du compilateur : elle
ne prouve pas a elle seule une nouvelle fonction. Aucun des fichiers loose
ne possede exactement le SHA du donateur, d'ou l'insuffisance d'un simple hash.

## Choix des donateurs et familles

Les SFS sources sont ceux des profils modifies sans 6DOF du depot. Leur SHA-256
et celui du profil Original correspondant sont imposes par le reproducer.
Sur 561 classes directement marquees ou compagnons, 361 existent dans chaque
SFS et aucune de ces classes sources ne contient Zuti. Toutes sont identiques
a leur equivalente Original, sauf `Config`, reconstruite separement.
Les cinq noms dont les donateurs changent entre versions sont `Maneuver`,
`Config`, `Motor`, `NetServerParams` et `NetServerParams$CheckUser`.
Le retrait d'overrides laisse chaque profil charger sa propre version SFS ;
aucun fichier moteur 4.09m commun n'est injecte dans les anciens profils.

Dans le tableau, D = directement marque, C = compagnon non marque, SFS = nombre
de classes de la famille presentes dans chaque SFS. Toutes les familles
nommees `Zuti...` sont listees separement et integralement dans le JSON.

| Famille sous com/maddox/il2 | D | C | SFS | Traitement |
| --- | ---: | ---: | ---: | --- |
TABLE

## Apports independants et fonctions retirees

- **6DOF** : les cinq classes `TrackIR`, `TrackIRWin`, `HookPilot` et ses deux
  compagnons, identifiees par `manifests/profiles-6dof-v1.15.json`, sont hors
  de la liste. Les executables distincts et les ressources associees sont conserves.
- **HUD immersion** : `HUD_Log-IMMERSION.bat` et `HUD_Log-REGULAR.bat` ne copient
  que `hud_log_ru.properties`. Ces catalogues restent presents. Les extensions
  de HUD propres a MDS disparaissent avec ses menus de rearmement et ses reglages.
- **Avions/cockpits** : CW-21, KB-29P, Silverplate, leurs cockpits specialises,
  maillages et registres `air.ini` restent hors du plan. Les API utilisees par
  leurs classes survivantes resolvent dans la simulation. Le contrat CW-21
  a ete execute contre l'Aircraft stock SHA-256
  `079760CADF85DA3CB26856C0D5B541EBC51E017A450F1648B27426D8E00D7BE3`, commun
  aux trois profils : PASS, trois armements uniques, quatre emplacements,
  calibres/munitions exacts et imports tardifs repetes sans doublon. Il utilise
  des doubles API/entrees et ne remplace pas le controle de tir en jeu.
- **AOC, branding, portes/soutes, effets Silverplate** : preserves par les quatre
  reconstructions deleguees. Leurs empreintes exactes figurent dans
  `qualified-inventory.json`, avec leurs sources de staging. Ce plan ne les remplace
  pas par les versions stock.
- **AI et porte-avions incorpores a MDS** : Certificates AI v3 et Fireball CTO
  v5.3.x peuvent disparaitre avec ce composant selon le perimetre donne par Alexis.
  La notice locale MDS 1.13, lignes 181-182, confirme leur incorporation.
  Les familles `AirGroup`, `Maneuver`, `Pilot`, `Gear` et `BigshipGeneric`
  reviennent aux comportements du profil stock : pas de promesse de garder
  ces ameliorations MDS d'IA, catapulte, ravitaillement, reparations ou capture.
- **Cartes Slovenia** : aucun fichier de carte n'est vise. Un nom d'auteur
  identique n'etablit pas une dependance au moteur MDS.

## Format des missions BornPlace

La classe `Mission` stock est identique dans les trois profils, SHA-256
`E6E493EBC15893FB499C76BB02104DF4F5E335022A35AE323E8102A69127EDC4`.
Sa methode `loadBornPlaces(SectFile)` lit cinq valeurs de chaque ligne
`[BornPlace]` : armee, rayon, x, y, parachute. Elle ne teste pas les tokens
restants ; les colonnes MDS ajoutees sont ignorees par cette methode.
Les sections `[BornPlace0]`, `[BornPlace1]`, etc. sont **stock**. Le lecteur
utilise `sectionIndex("BornPlace" + index)` puis `SectFile.var` pour les noms
d'avions, sans exploiter leurs valeurs additionnelles. Conserver ces sections
et les cinq premieres colonnes ; nettoyer seulement les champs MDS distincts.
Le corps normalise du lecteur est conserve dans les trois rapports de profil.

## Reproduction et limites

Depuis un dossier de travail sous `C:/Users/Alexis/.codex`, executer
`analyze-families.py --repository-root <snapshot-v1.15-avant-retrait> --output <json>`.
Ajouter quatre options `--overlay classe=chemin` pour Config, Controls, Motor
et Explosions, avec les chemins et SHA conserves dans `rebuilt_overlays` du
rapport qualifie. `summarize-plan.py --repository-root <depot>` produit ce texte
et le plan seulement si les cinq controles sont vides dans les trois profils.
La garde d'entree refuse un candidat direct manquant ou dont l'empreinte a change.
Apres application, utiliser une copie inerte du snapshot archive pour reproduire
la transition ; ne pas restaurer temporairement le moteur dans le jeu actif.

Le parcours inspecte 5101 classes effectives en 4.08m/4.09b et 5103 en 4.09m,
incluant les donnees SFS atteintes par les references de classes. Il controle
les deux directions : overrides survivants vers donateurs et donateurs exposes
vers overrides survivants. La resolution parcourt superclasses et interfaces,
traite les constructeurs sans heritage et compare les droits public/protected/
package/private ainsi que statique/instance.

Limites : ce n'est pas un verificateur JVM complet ; la contrainte protected
sur le type du receveur, le dispatch dynamique, la reflexion, les noms construits,
le code natif et les classes des autres SFS ne sont pas prouves par ce controle.
Sept noms Maddox restent absents de Files + files.SFS 4.09m dans l'etat initial
et simule : `CockpitYAK_3P$1/$Interpolater/$Variables`, `MIG_15SV`, `P_51Mustang`,
`SEAFIRE2`, `SEAFIRE2L`. Les anciens profils ajoutent `CW21xyz` et
`PaintSchemeFMPar00du`. Ces absences preexistantes ne sont pas creees par le retrait
et demandent une recherche dans les autres SFS/payloads si ces appareils sont utilises.
Vingt classes loose conservees ont des attributs terminaux malformes/non standards,
deja presents avant le retrait ; **aucune ne figure dans les 543 classes retirees**.
Elles sont identifiees exactement dans `terminal_attributes_anomalies`.

Les forums ne constituent pas une preuve d'execution de ce pack fusionne.
Sources communautaires consultees dans l'audit historique : AAA/Wayback inaccessible,
Mission4Today pour l'ordre 4.08/4.09, SAS pour les modules independants. Le present
resultat vient des archives locales exactes, de la notice locale et des tests
reproductibles. Restent les lancements, missions representatives, multijoueur,
FMB, selection/tirs des avions et controle 6DOF dans les profils proposes.
'''.replace('TABLE', '\n'.join(rows))
    (root/'docs/RECONSTRUCTION_MOTEUR_SANS_MDS_V1.15_20260912.md').write_text(text, encoding='utf-8')
    print('PLAN='+str(folder/'retirement-plan.json'))
    print('FILES='+str(len(files)))


if __name__ == '__main__':
    main()
