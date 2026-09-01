# Configurations materielles Open Sturmovik v1.15

## Statut et objectif mesure

Ce document commence l'etablissement des configurations propres a Open
Sturmovik. Les valeurs sont **provisoires** tant que les missions de qualification
n'ont pas ete executees sur plusieurs machines.

La cible demandee est interpretee d'apres sa valeur numerique :
**1 920 x 1 080, 60 images/s, profil graphique maximal Open Sturmovik**. Cette
resolution est du Full HD. Le profil 2 560 x 1 440, souvent appele « 2K » dans le
commerce, sera qualifie separement ; il traite 78 % de pixels supplementaires.

La « configuration minimale qualifiee » de ce document n'est donc pas le minimum
capable d'afficher le menu. C'est la machine la moins puissante qui devra tenir
la cible maximale 1080p60 sans saccade bloquante sur toutes les missions temoin.

## Contrainte fondamentale : jeu x86 et systeme x86 ne donnent pas 4 Gio

`il2fb.exe` reste un programme 32 bits et l'executable v1.15 est marque Large
Address Aware. Microsoft documente toutefois deux plafonds differents :

- sous Windows 32 bits, un processus recoit 2 Gio par defaut et jusqu'a **3 Gio**
  avec LAA et 4GT/`increaseuserva` ;
- sous Windows 64 bits, un processus 32 bits LAA peut recevoir **4 Gio**.

Sources Microsoft :
[Memory Limits for Windows](https://learn.microsoft.com/en-us/windows/win32/memory/memory-limits-for-windows-releases),
[Virtual Address Space](https://learn.microsoft.com/en-us/windows/win32/memory/virtual-address-space)
et
[64-bit programming for game developers](https://learn.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers).

Sur un systeme x86, accorder 3 Gio au jeu ne laisse qu'environ 1 Gio d'espace
virtuel au noyau. Microsoft avertit que cette reduction peut faire echouer des
pilotes ou services. Le lanceur ne devra donc jamais activer 4GT sans controle,
sauvegarde du demarrage et test du pilote graphique.

## Deux cibles necessaires

### A. Qualification obligatoire Windows 32 bits

Cette cible est un livrable obligatoire de la v1.15, et non une compatibilite
facultative. Elle ne peut toutefois pas etre presentee comme une plateforme
moderne ou securisee en 2026. Windows 10 a atteint sa fin de
support le 14 octobre 2025, hors programme ESU ; Windows 11 exige un processeur et
un systeme 64 bits. Source :
[fin de support de Windows 10](https://support.microsoft.com/en-us/windows/deployment/updates-lifecycle/windows-10-support-has-ended-on-october-14-2025)
et
[exigences Windows 11](https://learn.microsoft.com/en-us/windows/whats-new/windows-11-requirements).

Les pilotes imposent eux aussi une limite historique : NVIDIA a reserve ses
nouveaux pilotes aux systemes 64 bits depuis avril 2018 et AMD a arrete les
pilotes Windows 32 bits apres Adrenalin 18.9.3. Sources :
[plan de support NVIDIA](https://nvidia.custhelp.com/app/answers/detail/a_id/4604/)
et
[plan de support AMD](https://www.amd.com/en/resources/support-articles/faqs/PA-120.html).

Configuration candidate a rechercher pour la qualification x86 :

- Windows 10 32 bits 22H2 conserve hors ligne ou sous protection adaptee ;
- processeur de bureau 4 coeurs rapides, classe Core i7-7700K ou superieure
  compatible avec les pilotes x86 de la carte mere ;
- 4 Gio de RAM installee, fichier d'echange actif et SSD ;
- GeForce GTX 1060 6 Gio avec pilote 391.35 WHQL Windows 10 32 bits, ou une
  Radeon equivalente explicitement validee avec le dernier pilote x86 ;
- OpenGL natif comme repli obligatoire ; chaque wrapper teste individuellement.

Le Core i7-7700K fournit 4 coeurs/8 threads et monte a 4,5 GHz selon
[Intel](https://www.intel.com/content/www/us/en/products/sku/97129/intel-core-i77700k-processor-8m-cache-up-to-4-50-ghz/specifications.html).
La GTX 1060 possede 6 Gio de GDDR5 selon
[NVIDIA](https://www.nvidia.com/en-us/geforce/news/nvidia-geforce-gtx-1060/),
et le pilote
[391.35 Windows 10 32 bits](https://www.nvidia.com/en-us/drivers/details/132932/)
la liste explicitement parmi les cartes prises en charge.

Cette combinaison est un **candidat de laboratoire**, pas encore un minimum
publie. Une machine x86 reelle devra la qualifier avant la sortie. Le test devra
notamment determiner si `increaseuserva=2560` suffit avant d'essayer 3072, car
la stabilite du pilote et du noyau est prioritaire. Sans ce banc reel, la v1.15
ne pourra annoncer qu'un candidat et ne sera pas consideree totalement qualifiee
pour son objectif Windows 32 bits.

### B. Cible moderne recommandee

Cette cible conserve le jeu en 32 bits mais l'execute sur Windows 11 64 bits.
Elle offre au processus LAA son espace de 4 Gio, des pilotes entretenus et le
meilleur terrain pour dgVoodoo2, DXVK, Mesa ou IL2GE.

Premiere configuration candidate 1080p60 maximal :

- Windows 11 64 bits ;
- processeur 4 coeurs physiques minimum avec forte performance par coeur,
  candidat Ryzen 5 5600 ou classe equivalente ;
- 16 Gio de RAM ;
- carte graphique dediee avec 6 Gio de VRAM minimum, 8 Gio conseilles pour les
  textures 2K/4K ; candidat Radeon RX 6600 8 Gio ou classe equivalente ;
- SSD, avec au moins 20 Gio libres pendant l'installation, les caches et les
  captures de diagnostic ;
- ecran 1 920 x 1 080 a 60 Hz ou plus.

Le Ryzen 5 5600 fournit 6 coeurs/12 threads, jusqu'a 4,4 GHz et 32 Mio de cache
L3 selon
[AMD](https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen/ryzen-5000-series/amd-ryzen-5-5600.html).
La RX 6600 fournit 8 Gio de GDDR6 et vise officiellement le jeu 1080p selon
[AMD](https://www.amd.com/en/products/graphics/desktops/radeon/6000-series/amd-radeon-rx-6600.html).
Ces references donnent une classe materielle reproductible ; elles ne constituent
pas encore une preuve de 60 images/s dans Open Sturmovik.

## Borne fournie par le PC de developpement

Le PC mesure le 1er septembre 2026 possede :

- Core i5-8350U, 4 coeurs/8 threads, 1,7 GHz et 3,6 GHz turbo, 15 W ;
- Intel UHD Graphics 620, memoire dediee declaree 1 Gio ;
- 32 Gio de RAM et SSD NVMe WD Blue SN580 ;
- Windows 10 Professionnel 64 bits 22H2.

La fiche
[Intel du i5-8350U](https://www.intel.com/content/www/us/en/products/sku/124969/intel-core-i58350u-processor-6m-cache-up-to-3-60-ghz/specifications.html)
confirme ses 4 coeurs/8 threads et son turbo maximal de 3,6 GHz.

Pendant le vol B-29 + Little Boy de la capture
`20260901-060621Z-profile9-warm-windowed1024-startup`, en 1 024 x 768 et profil
haute qualite x86 securise :

- memoire privee maximale : 643,3 Mio ;
- ensemble de travail maximal : 626,7 Mio ;
- espace virtuel maximal : 1 931,9 Mio ;
- moteur GPU 3D : 24,4 % en moyenne, 46,6 % au 95e percentile et 48,2 % au
  maximum sur la fenetre de mission ;
- la boucle principale approche encore un coeur logique et les chargements de
  terrain restent perceptibles.

Le passage de 1 024 x 768 a 1 920 x 1 080 multiplie le nombre de pixels par
2,64. Une projection purement proportionnelle placerait deja le 95e percentile
GPU au-dessus de 120 %, avant l'anticrenelage maximal, les wrappers et les
textures les plus lourdes. L'UHD 620 est donc une **borne inferieure non
qualifiee** pour l'objectif 1080p60 maximal, meme si elle permet les essais
fonctionnels en profil securise.

## Regles de qualification du minimum final

Chaque combinaison CPU/GPU/pilote/wrapper devra effectuer au moins trois passages
a froid et trois a chaud de ces scenarios :

1. demarrage jusqu'au menu ;
2. petite mission sans IA lourde ;
3. grande carte avec deplacement rapide et chargement du terrain ;
4. mission dense en appareils, objets, Zuti et effets ;
5. session de dix minutes avec explosion nucleaire et pause/reprise.

Le profil ne sera qualifie 1080p60 que s'il respecte simultanement :

- moyenne d'au moins 60 images/s apres la periode de chauffe ;
- percentile bas 1 % d'au moins 50 images/s ;
- 99e percentile du temps d'image inferieur ou egal a 33,3 ms ;
- aucun gel superieur a 100 ms hors chargement annonce ou changement de vue ;
- aucune erreur bloquante, aucun manque de texture et aucun depassement x86 ;
- marge d'au moins 20 % sur la VRAM et l'espace d'adressage du processus ;
- resultat identique apres pause/reprise et acceleration temporelle.

Les mesures de la capture d'ecran ne remplacent pas un compteur de presentations.
Le prochain outil de qualification devra enregistrer les temps d'image reels,
la VRAM locale, les fautes de page, le coeur principal, les lectures de fichiers
et les changements de niveau de detail. Le minimum ne sera fige qu'apres ce test
sur une carte NVIDIA, une AMD et l'OpenGL natif de repli.
