# Perte de focus sans pause - v1.15

Derniere mise a jour : 2 septembre 2026.

## Conclusion

IL-2 1946 4.09m possede deja un reglage natif pour continuer la simulation
lorsque sa fenetre n'est plus active :

```ini
[window]
DrawIfNotFocused=1
```

Ce reglage est maintenant inclus dans le profil Open Sturmovik. Il reste
reversible : remettre la valeur a `0` restaure le comportement historique.

## Preuve dans le moteur

La classe 4.09m `Main3D` charge `DrawIfNotFocused` depuis la section `window`
de `conf.ini`. La boucle Windows `MainWin3D.checkFocus()` teste ensuite cette
valeur a chaque passage :

- a `0`, la perte de focus appelle `Time.setPause(true)` et masque le rendu ;
- au retour du focus, le moteur appelle `Time.setPause(false)` ;
- a `1`, cette branche est evitee et la boucle de simulation continue.

Le parametre `-NoPause` du script `Open_Sturmovik_Switcher.ps1` est sans rapport
avec ce comportement. Il sert uniquement a fermer le selecteur sans attendre
une pression sur Entree.

## Validation a effectuer

1. Lancer une mission solo avec `DrawIfNotFocused=1`.
2. Stabiliser l'avion et noter l'heure de mission.
3. Basculer pendant trente secondes vers une autre fenetre.
4. Revenir dans IL-2 et verifier que l'heure, l'avion et les autres acteurs ont
   continue a evoluer.
5. Repeter en plein ecran et en mode fenetre.
6. Verifier que le son, le joystick, TrackIR et la souris reprennent sans perte.
7. Repeter avec `DrawIfNotFocused=0` pour confirmer le temoin historique.

La validation des explosions nucleaires avec pause volontaire reste un essai
distinct : ce reglage ne modifie pas la touche Pause et ne doit pas masquer un
defaut de pause/reprise demande par le joueur.

## Decision nucleaire issue du banc A/B

Le controleur courant n'utilise plus `Time.currentReal`, ne cherche plus a
deduire une reprise et ne contient plus de methode de rehydratation. Cette
suppression est volontaire : recreer un `.eff` remet son animation a zero,
alors que la reapparition simultanee des sondes rouge et bleue s'est produite
sans aucune recreation Java (`rehydrates=0`).

La capture `20260903-160537Z` a montre qu'un chevauchement ne suffit pas si
l'origine d'un emetteur deja actif est deplacee : les nouvelles particules
montent avec l'origine, tandis que les anciennes restent dans le monde et
forment une masse basse detachee. Ce candidat est rejete.

Son remplacement n'appelle plus `ActorPos.setAbs` ni `ActorPos.reset`. Dix
couches de tete et cinq couches de tore sont creees a des ages et altitudes
fixes entre 30 et 570 secondes. Chacune emet 60 secondes et conserve 128
secondes de vidange naturelle. La couche stabilisee apparait a 600 secondes ;
les acteurs de montee sont liberes a 728 secondes. La derniere emission
stabilisee finit naturellement a 3 718 secondes et la destruction forcee a
3 728 secondes reste un garde-fou.

Ces changements passent 25/25 controles de cycle de vie et 42/42 controles
nucleaires statiques. Le controle global retourne 19 PASS / 2 WARN / 1 FAIL,
l'unique echec etant la chaine sonore Allison independante. Leur effet reel sur
pause/reprise et demi-tour reste a confirmer en jeu apres la synchronisation
transactionnelle.
