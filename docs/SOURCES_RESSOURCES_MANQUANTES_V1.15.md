# Recherche des ressources manquantes de la v1.15

## Regle de selection

Pour AOC comme pour tout autre fichier necessaire a la v1.15, la recherche suit
desormais cet ordre :

1. ressources locales conservees dans `D:\Projets\GITHUB\#res` ;
2. publications originales et captures Wayback Machine, en particulier le
   forum All Aircraft Arcade entre 2006 et 2010 ;
3. paquets historiques complets qui citent leur version cible d'IL-2 ;
4. miroirs encore accessibles, seulement lorsque le nom, la taille, le contenu
   et la provenance permettent de rattacher le fichier a une publication
   identifiee.

Le numero de version le plus eleve n'est pas prioritaire. Un fichier est retenu
si son paquet est complet, s'il vise IL-2 4.09m, si ses dependances sont
presentes et s'il ne supprime pas une fonction deja utilisee par Open Sturmovik.

## Controles obligatoires

- conserver l'URL ou la capture d'origine et la date de recherche ;
- calculer SHA-256 et, lorsqu'elle existe, comparer l'empreinte historique ;
- extraire dans un dossier temporaire, sans lancer l'installateur ni le jeu ;
- comparer l'interface, les dependances et les fichiers prioritaires avec la
  v1.15 ;
- ne jamais inventer un profil physique pour combler un fichier absent ;
- documenter toute fusion necessaire et fournir un constructeur reproductible ;
- reserver la validation en jeu a la campagne de test finale.

## Premier cas applique : AOC

La recherche AAA/Wayback puis les fils historiques CheckSix, Ultrapack et HSFX
a permis de retrouver l'ensemble AOC 1a complet de HSFX 4.0 : trois classes et
267 profils. La v1.15 en distribue 266, le profil specifique du Bf-109G-6 Early
etant volontairement omis pour utiliser `Defaut.txt`. Le paquet HSFX 4.0 cible explicitement IL-2 4.09m. La classe moteur
originale ne contenait toutefois pas les methodes R/R/R de Zuti MDS 1.13 ; la
v1.15 conserve donc la classe Zuti comme base et n'y greffe que les
consommateurs AOC verifies. La provenance, les empreintes et le choix V1/V2/V3
sont detailles dans `manifests/aoc-v1.15.json` et `docs/AUDIT_ZUTI_AOC.md`.
