# GUI du lanceur v1.15 — 8 septembre 2026

Le lanceur sépare désormais la transaction BAT de l’interface HTA permanente. La refonte remplace son CSS et
réorganise les blocs HTML existants : panneau translucide riveté, barre haute
étroite, séparations fines, police Arial de poids normal, boutons ronds à
cerclage métallique avec lentilles ambrées/vertes, bouton Quitter rouge.
Les cinq SVG décoratifs sont incorporés au CSS, sans dépendance distribuée.
Le fond et les icônes existants sont conservés. Les SVG sont redessinés à partir
du menu de référence, sans prétendre être des sprites extraits du jeu.

Le BAT reste le seul composant qui applique les profils. Le HTA appelle ce BAT avec les mêmes paramètres contrôlés. Les contrôles gardent leurs noms, valeurs, états initiaux et gestionnaires.
Les corrections antérieures du lanceur sont décrites dans
[CORRECTION_SWITCHER_V1.15.md](CORRECTION_SWITCHER_V1.15.md) ; elles préexistaient
à cette refonte et sont incluses dans le commit à la demande d'Alexis.

## Vérifications

- node tools/Test-SwitcherGui.cjs : neuf correspondances de profils,
  dix-huit appels profil/HUD, dix-huit restaurations d'état, garde HUD stock,
  cohérence du raccourci et de l'installateur. Seules trois attentes de dimensions
  de ce test ont changé pour la refonte.
- Aperçu inerte Edge/Chromium : aucun chevauchement, aucune erreur JavaScript,
  écran d'erreur et retour vérifiés. Aucun accès au jeu dans cet aperçu.
- Test HTA indépendant : mode IE=edge, cinq SVG chargés sans erreur, résumé et
  configuration active sans débordement, action visible dans la fenêtre.
- Rapport : [switcher-gui-style-v1.15.json](../manifests/test/switcher-gui-style-v1.15.json).

Les captures de vérification sont issues de l'aperçu Chromium. La capture native
Windows a échoué ; le rapport HTA vérifie les chargements et dimensions mais
n'est pas une capture. Aucun jeu ni transaction de profil n'a été lancé pour
cette refonte. Les anciens rapports de transactions gardent leur date et portée.

## Sources

Priorité aux ressources locales sous D:\Projets\GITHUB\#res\IL2 1946 et
au fond déjà livré sous _Game Switcher/Resources.

- [Menu IL-2 1946 de référence](https://aiss.stars.ne.jp/il2-1946/index.html)
  et [capture inspectée](https://aiss.stars.ne.jp/pf/main.jpg).
- [Mission4Today : fonds IL-2 1946](https://www.mission4today.com/index.php?c=65&name=Downloads).
- [SAS : IMF Converter](https://www.sas1946.com/main/index.php?topic=71961.36).
- [AAA via Wayback](https://web.archive.org/web/20100101000000/http://allaircraftarcade.com/forum/) :
  inaccessible, aucun contenu supposé.

## Langues, progression et disposition — 13 septembre 2026

Le sélecteur propose sept langues dans une liste déroulante compacte : `Français`, `English`, `Deutsch`, `Русский`, `Čeština`, `Magyar` et `Polski`. Les codes écrits pour IL-2 sont respectivement `fr`, `us`, `de`, `ru`, `cs`, `hu` et `pl`. La valeur historique `en` est reconnue à la lecture comme un alias de l’anglais, puis normalisée en `us`.

Au clic sur `Appliquer`, `_Game Switcher/Set-OpenSturmovikLanguage.ps1` ne remplace que `locale=` dans la section `[rts]` du `conf.ini` actif. L’encodage, les fins de ligne et toutes les autres préférences sont conservés. La langue choisie est également mémorisée dans `active-profile.txt`, puis le jeu la charge à son prochain démarrage.

Les six catalogues dont le contenu varie selon le moteur (`gui`, `maps`, `plane`, `regInfo`, `regShort` et `weapons`) sont copiés depuis `_Game Switcher/Languages/<version>/i18n`. Les autres catalogues libres communs restent dans `Files/i18n`. Le HUD standard ou immersion est installé sous le nom correspondant à la langue active. Les clés HUD absentes d’une traduction locale gardent explicitement leur texte anglais vérifié.

L’application du profil est lancée en arrière-plan. Le BAT publie les étapes réelles de sa transaction dans un fichier temporaire : vérification 5–35 %, préparation 45–60 %, sauvegarde 72 %, copie 88 %, état 96 %, fin 100 %. La fenêtre affiche ces valeurs et le message courant, puis présente le journal complet.

Le fond Pacific Fighters Retail actif est un JPEG de qualité 92 de 627 063 octets, aux mêmes dimensions 1586 × 992 que la source PNG de 4 634 420 octets conservée. Il est lu directement depuis `_Game Switcher/Resources` sans copie temporaire. La capture `19.png` a révélé un chevauchement vertical entre la liste des langues et `Crédits`. Le bouton a été descendu de 12 pixels, reste centré dans la colonne gauche et conserve une marge avec les actions. La fenêtre reste haute de 760 pixels afin de tenir sur les écrans de 768 pixels.

Le fond de menu libre `Files/gui/Background.tga` est installé uniquement pour les six profils moddés. Les trois profils stock le retirent et laissent le `files.SFS` sélectionné fournir son menu d’origine. Les libellés du chargement initial sont propres à chaque profil ; la bêta stock affiche `V 4.09b` au lieu du texte historique `V 4.09b1m`.

La logique d’interface a validé 126 combinaisons profil/HUD/langue et 126 restaurations d’état. Les transactions réelles ont validé les neuf profils, les sept langues en HUD standard et les sept en HUD immersion. Ces essais vérifient les fichiers copiés et l’état final ; l’aspect de chaque traduction dans les menus reste à confirmer lors d’un lancement visuel par Alexis. L’analyse détaillée se trouve dans `WIP/analyses/langues-il2/README.md`.


### Temps d’ouverture du sélecteur

L’ancienne extraction temporaire du HTA prenait environ 38 ms à elle seule dans le jeu de test. Le raccourci VBS attendait en revanche le démarrage de PowerShell et la détection de résolution avant d’ouvrir le sélecteur, soit environ 483 ms mesurées à chaud et davantage lors d’un premier démarrage Windows. Cette étape a été retirée du raccourci du sélecteur. Elle reste présente dans `Open_Sturmovik_Game.vbs`, où elle est nécessaire juste avant le lancement d’IL-2. Le passage du fond actif de 4,63 Mo à 627 Ko réduit aussi la lecture et le décodage par `mshta`. Après le signalement d’un délai proche de dix secondes, l’interface a été sortie du BAT : `_Game Switcher/Open_Sturmovik_Switcher.hta` est maintenant un fichier permanent lancé directement par le VBS. La fenêtre Windows apparaît en 258 ms lors de la mesure locale à chaud ; le délai perçu complet reste à confirmer par Alexis.

## HTA permanent et icônes

Le HTA permanent doit commencer directement par la déclaration doctype. Une
première extraction avait conservé 34 lignes du BAT en tête du fichier, ce qui
affichait le code du lanceur derrière les contrôles. Les tests refusent
désormais les marqueurs %~f0, SWITCHER_GUI_LINE et SWITCHER_GUI_TEMP dans les
512 premiers caractères du HTA.

Le raccourci Bureau Open Sturmovik lance toujours
Open_Sturmovik_Game.vbs afin d’adapter la résolution, mais son IconFilename
pointe sur il2fb.exe à la racine du jeu. Après chaque bascule, le script
Refresh-OpenSturmovikIconCache.ps1 réenregistre cette IconLocation et envoie à
Explorer une notification ciblée SHCNE_UPDATEITEM avec SHCNF_FLUSHNOWAIT pour
l’exécutable et le raccourci. Le raccourci du switcheur conserve son icône
propre. Un raccourci temporaire a confirmé la mise à jour en 399 ms sans changer
sa cible.


La flèche de la liste des langues est alignée contre son bord droit. Son fond gris-vert, sa bordure métallique et sa couleur claire reprennent le panneau du sélecteur au lieu du bouton blanc Windows.


La fleche de la liste des langues est maintenant collee au bord droit. Son degrade gris-vert, son double relief metallique et sa fleche blanche lumineuse reprennent le style du selecteur ; le survol eclaircit le bouton. Le mode de rendu IE=edge permet au HTA de prendre en charge ce style avec le moteur Windows disponible.

## Boutons Retour distincts (13 septembre 2026)

Les deux boutons Retour, dans la page Credits et dans l'ecran de resultat, utilisent une teinte bleu acier (#315f79) avec un relief metallique. Ils restent ainsi clairement visibles sur le fond gris-vert et se distinguent des actions Appliquer (verte) et Quitter (rouge).
