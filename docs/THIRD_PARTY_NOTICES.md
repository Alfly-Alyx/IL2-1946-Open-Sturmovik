# Notices des composants tiers

## Zuti MDS v1.13 STD — autorisation a clarifier

Le fichier historique `Files/$ReadMe$.txt` attribue MDS a `|ZUTI|` et demande
explicitement de contacter l'auteur avant toute inclusion dans un pack. Le depot
ne contient actuellement aucune preuve d'autorisation accordee a Open Sturmovik.

La presence et la modification technique de classes Zuti ne constituent pas une
autorisation de redistribution. Ce composant reste donc marque
`redistribution_authorized: false` dans
`manifests/mods/zuti-mds-1.13-static.json` jusqu'a obtention d'une permission ou
identification de conditions de licence publiées. Cette question doit etre
resolue avant une diffusion publique de la v1.15.

## B-29 Silverplate v1.2 / Little Boy / Fat Man — aucune licence publiee

Le paquet historique Silverplate v1.2 fournit le B-29 Silverplate, les classes
Little Boy et Fat Man, leurs modeles et les effets nucleaires de base. Le seul
fichier d'instructions retrouve, `To Add.txt`, enumere les lignes `air.ini` et
les traductions d'armement ; il ne contient ni licence, ni auteur, ni condition
de redistribution. Le mainteneur confirme que le paquet n'a pas de licence
publiee. Ce composant doit donc etre traite comme non autorise a la
redistribution tant qu'une permission explicite n'a pas ete obtenue.

Open Sturmovik conserve les huit ressources de modele de bombe identiques au
paquet historique, mais fusionne et corrige plusieurs classes Java pour assurer
la compatibilite avec Zuti et le moteur 4.09m. La presence ancienne de ces
fichiers dans l'add-on ne prouve pas une autorisation de redistribution ou de
modification. Une diffusion publique de la v1.15 exige donc une permission
explicite de l'auteur ; a defaut, Silverplate devra rester un composant externe
installe par l'utilisateur ou etre remplace par des ressources dont la licence
autorise clairement la redistribution et la modification.

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
