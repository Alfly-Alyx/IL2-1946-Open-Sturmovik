# Notices des composants tiers

La [licence de partage non commercial d'Open Sturmovik](../LICENSE.md)
couvre les contributions originales d'Alfly, dans le périmètre décrit par
[LICENSING.md](LICENSING.md). Elle ne remplace ni ne restreint les licences
des composants tiers ci-dessous et ne fournit aucune autorisation supplémentaire
sur les éléments d'IL-2 ou les mods de leurs auteurs.

## Retraits du 12 septembre 2026

Lowengrin DCG 3.43, San FOV Changer 1.0 et Malta de 6S.Maraz ont ete retires
du pack sur demande d'Alexis. Leurs notices demandent une permission pour
la redistribution ou l'inclusion dans un pack ; aucune preuve correspondante
n'a ete retrouvee dans les ressources examinees. Cela ne signifie pas qu'une
licence payante etait exigee pour leur utilisation personnelle.

Les fichiers, notices et recherches de contact sont conserves hors du depot,
dans `D:\Projets\GITHUB\#res\IL2 1946\Mods\Retirés\besoin_licence`.
Voir [le perimetre exact des retraits](RETRAIT_COMPOSANTS_V1.15.md).
Zuti MDS est retire du contenu local ; la section suivante conserve
la raison historique du retrait, sans annoncer une autorisation acquise.

## Zuti MDS v1.13 STD — retire du contenu local

Le fichier historique
`Lisez-moi - Zuti MDS 1.13.txt`, conserve avec les notices archivees sous
`Mods/Retirés/besoin_licence/Zuti MDS 1.13`,
attribue MDS a `|ZUTI|` et demande explicitement de contacter l'auteur avant
toute inclusion dans un pack. Le depot ne contient actuellement aucune preuve
d'autorisation accordee a Open Sturmovik.

Les classes conservees sont reconstruites sans MDS et ses ressources sont
retirees. Les controles statiques du retrait et les tests cibles passent.
Les vrais essais en jeu et la validation de l'installateur restent a refaire
avant de qualifier la sortie. Voir
[le suivi effectif](RETRAIT_COMPOSANTS_V1.15.md) et
[la reconstruction AOC](AUDIT_AOC_SANS_MDS_20260912.md).

## B-29 Silverplate v1.2 / Little Boy / Fat Man — crédits retrouvés, permission non établie

Le paquet historique Silverplate v1.2 fournit le B-29 Silverplate, les classes
Little Boy et Fat Man, leurs modeles et les effets nucleaires de base. Le seul
fichier d'instructions local, `To Add.txt`, enumere les lignes `air.ini` et les
traductions d'armement sans indiquer d'auteur ni de licence. La
[publication SAS du paquet v1.2](https://www.sas1946.com/main/index.php?topic=7894.0)
conserve toutefois les credits suivants : 1C/Maddox, O_Magpie, Fireball,
SAS~Cirx, MrJolly, Lt.Wolf, Fat Duck, VC-81_BOLTER, O_Leigh, Max_Thehitman,
Ranwers, Wolfighter et Twister. Santobr y est cite pour des effets additionnels,
dont la presence exacte dans Open Sturmovik reste a verifier.

Aucune permission applicable à la redistribution et aux adaptations présentes
dans Open Sturmovik n'a été retrouvée dans les éléments examinés. Ces éléments
ne permettent pas de certifier les droits de distribution de Silverplate ;
ils ne documentent pas non plus une interdiction particulière de son auteur.

Open Sturmovik conserve les huit ressources de modele de bombe identiques au
paquet historique, mais fusionne et corrige plusieurs classes Java pour assurer
la compatibilite avec le moteur 4.09m. La verification statique de leur preservation
lors du retrait MDS passe ; les essais en jeu restent a refaire. La presence ancienne de ces
fichiers dans l'add-on ne prouve pas une autorisation de redistribution ou de
modification. La présente notice conserve cette limite de preuve ; elle ne
constitue ni une autorisation supplémentaire ni une décision de retrait.

## OpenIL2

`tools/Analyze-Sfs.py` derive des algorithmes de lecture SFS et de calcul
d'empreinte publies par le projet [OpenIL2](https://github.com/DavidGregory084/OpenIL2),
revision `63031643bd14c0f89255b97a9e954b552ed215f1` consultee le 31 aout 2026.

Copyright (c) 2021 David Gregory

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

Subject to the terms and conditions of this license, each copyright holder and
contributor hereby grants to those receiving rights under this license a
perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable
(except for failure to satisfy the conditions of this license) patent license to
make, have made, use, offer to sell, sell, import, and otherwise transfer this
software, where such license applies only to those patent claims, already
acquired or hereafter acquired, licensable by such copyright holder or
contributor that are necessarily infringed by:

(a) their Contribution(s) (the licensed copyrights of copyright holders and
non-copyrightable additions of contributors, in source or binary form) alone; or

(b) combination of their Contribution(s) with the work of authorship to which
such Contribution(s) was added by such copyright holder or contributor, if, at
the time the Contribution is added, such addition causes such combination to be
necessarily infringed. The patent license shall not apply to any other
combinations which include the Contribution.

Except as expressly stated above, no rights or licenses from any copyright
holder or contributor is granted under this license, whether expressly, by
implication, estoppel or otherwise.

DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
