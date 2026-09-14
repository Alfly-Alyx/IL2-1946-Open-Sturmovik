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

Le switcher batch v1.15 ne modifie pas ce comportement et n'ajoute aucun
mecanisme de pause. Le controle depend exclusivement de `DrawIfNotFocused`
dans `conf.ini` et de la logique moteur decrite ci-dessus.

## Validation a effectuer

1. Lancer une mission solo avec `DrawIfNotFocused=1`.
2. Stabiliser l'avion et noter l'heure de mission.
3. Basculer pendant trente secondes vers une autre fenetre.
4. Revenir dans IL-2 et verifier que l'heure, l'avion et les autres acteurs ont
   continue a evoluer.
5. Repeter en plein ecran et en mode fenetre.
6. Verifier que le son, le joystick, TrackIR et la souris reprennent sans perte.
7. Repeter avec `DrawIfNotFocused=0` pour confirmer le temoin historique.

Ce scenario ne modifie pas la touche Pause volontaire : il qualifie uniquement
la reaction automatique du moteur a la perte de focus, conformement au
perimetre v1.15.
