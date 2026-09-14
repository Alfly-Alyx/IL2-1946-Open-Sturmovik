# Profil experimental de cache 4.09m

`wrapper.dll` est construit depuis `native/wrapper-cache-409m`.

- SHA-256 : `EBB5C61C1CDF8132713F51A2CFAA147B7DD4DE0732A148904C436AA1470B4D67`
- architecture : PE32 i386 ;
- exports : `ReadDump` (`ret 8`) et `__SFS_openf` (`ret 12`) ;
- cache : `.open-sturmovik-cache`, avec manifeste de dossiers et ecriture atomique ;
- etat : banc isole valide, essai dans IL-2 encore requis.

Les choix 8 et 9 du selecteur permettent de revenir au wrapper historique.
