# Audit des classes Java libres

Ce rapport est produit par `tools/Audit-JavaClasses.py`. Il compare les references
des classes libres avec le `rt.jar` Java 1.3.1 livre par le jeu. Il inspecte aussi
le constant pool, les descripteurs et le flux d'opcodes de chaque methode.

Les nombres et la table ci-dessous conservent l'etat **avant correction** afin de
rendre le traitement auditable. L'etat actuel du depot est different : les 56
classes ont ete remplacees par leurs variantes compatibles version 47, aucun
fichier version 50 ne subsiste, les 56 structures sont acceptees par le parseur
interne et par `javap -verbose`, et leurs empreintes avant/apres sont conservees
dans `manifests/java47-1.15.json`. `tools/Test-Java47Manifest.ps1` permet de
controler l'etat installe sans le modifier.

## Instantane avant correction

- classes au-dessus de la version 47 : **56** ;
- admissibles a une mise a niveau descendante statique : **56** ;
- necessitant une correction/recompilation : **0** ;
- entrees de `rt.jar` dont le CRC ZIP est incoherent : **5251** ;
- classes libres non analysees a cause d'une erreur de format : **20** ;
- repartition des classes libres analysables : version 45 = 702, version 46 = 150, version 47 = 1507, version 50 = 56.

Une decision `admissible` signifie qu'aucune API absente, structure recente ou
instruction interdite n'a ete trouvee. Elle ne remplace pas le futur essai avec la
JVM du jeu et une mission qui instancie effectivement la classe.

| Fichier | Classe interne | Taille | Decision |
| --- | --- | ---: | --- |
| `005E548034BFD25C` | `com/maddox/il2/objects/air/BF_109E7NZ` | 5615 | version 47 admissible |
| `052B50F61671A6EC` | `com/maddox/il2/objects/air/CockpitBF_109G14$Interpolater` | 2596 | version 47 admissible |
| `05735C3CEADD3C4E` | `com/maddox/il2/objects/air/BF_109G2` | 7296 | version 47 admissible |
| `07C60BF4B578A772` | `com/maddox/il2/objects/air/CockpitBF_109G2` | 12070 | version 47 admissible |
| `20E1DC664A3A9490` | `com/maddox/il2/objects/air/CockpitBF_109K4$Interpolater` | 2680 | version 47 admissible |
| `2463EDBC7CB2B750` | `com/maddox/il2/objects/air/CockpitBF_109G14` | 12100 | version 47 admissible |
| `25D214FAAF0AFDE4` | `com/maddox/il2/objects/air/CockpitBF_109G2$Variables` | 799 | version 47 admissible |
| `2AC6C812A43EE582` | `com/maddox/il2/objects/air/CockpitBF_109Ex` | 13137 | version 47 admissible |
| `30AC45E439796AAE` | `com/maddox/il2/objects/air/BF_109G6Late` | 7344 | version 47 admissible |
| `38B7CFB2F9370BAE` | `com/maddox/il2/objects/air/CockpitBF_109G6` | 12050 | version 47 admissible |
| `4071ADD0B4EEDBB2` | `com/maddox/il2/objects/air/CockpitBF_109Z$1` | 247 | version 47 admissible |
| `42224DA8EF411028` | `com/maddox/il2/objects/air/CockpitBF_109G6$Variables` | 799 | version 47 admissible |
| `441FC026134C1C8E` | `com/maddox/il2/objects/air/CockpitBF_109G10$Variables` | 807 | version 47 admissible |
| `46CB1A2A75B8EFBA` | `com/maddox/il2/objects/air/CockpitBF_109G6LATE` | 12099 | version 47 admissible |
| `4F08C24852D0F64A` | `com/maddox/il2/ai/ground/NearestEnemies` | 5148 | version 47 admissible |
| `5533DD60B939E278` | `com/maddox/il2/objects/air/CockpitBF_109K4$1` | 250 | version 47 admissible |
| `57ED128E6F50CFC0` | `com/maddox/il2/objects/air/BF_109E4B` | 6000 | version 47 admissible |
| `5E8FFDC47EE75102` | `com/maddox/il2/objects/air/BF_109Z` | 8328 | version 47 admissible |
| `6071C94CC2FF4DC2` | `com/maddox/il2/objects/air/CockpitBF_109G14$1` | 253 | version 47 admissible |
| `62F859481286E098` | `com/maddox/il2/objects/air/BF_109F4` | 14162 | StringBuilder -> StringBuffer, puis version 47 |
| `6ABA8518B0F0793C` | `com/maddox/il2/objects/air/CockpitBF_109F2$1` | 250 | version 47 admissible |
| `6AEDC4300AC40298` | `com/maddox/il2/objects/air/BF_109K4` | 7251 | version 47 admissible |
| `6E59C106E890E628` | `com/maddox/il2/objects/air/BF_109G6` | 7838 | version 47 admissible |
| `6F612F749A9258E8` | `com/maddox/il2/objects/air/CockpitBF_109G6$Interpolater` | 2585 | version 47 admissible |
| `74A6A932FF85CD48` | `com/maddox/il2/objects/air/CockpitBF_109G10` | 12100 | version 47 admissible |
| `78E669485124D492` | `com/maddox/il2/objects/air/CockpitBF_109G2$Interpolater` | 2585 | version 47 admissible |
| `7F438A781F8F9DE8` | `com/maddox/il2/objects/air/CockpitBF_109G2$1` | 250 | version 47 admissible |
| `816A2D266339BA6A` | `com/maddox/il2/objects/air/CockpitBF_109G6LATE$Variables` | 831 | version 47 admissible |
| `8323F3BC7814F910` | `com/maddox/il2/objects/air/CockpitBF_109G10$1` | 253 | version 47 admissible |
| `872B6526ACD155EE` | `com/maddox/il2/objects/air/CockpitBF_109F2$Interpolater` | 2800 | version 47 admissible |
| `8C80DAF2184E7BEE` | `com/maddox/il2/objects/air/BF_109G10` | 6047 | version 47 admissible |
| `92D4E616DDB9ED7C` | `com/maddox/il2/objects/air/CockpitBF_109Z$Variables` | 828 | version 47 admissible |
| `991719F2D15DC0B6` | `com/maddox/il2/objects/air/CockpitBF_109G6$1` | 250 | version 47 admissible |
| `A2DC6214E05E72FE` | `com/maddox/il2/objects/air/CockpitBF_109Ex$Variables` | 799 | version 47 admissible |
| `A32F32DE9015709E` | `com/maddox/il2/objects/air/CockpitBF_109G6LATE$1` | 262 | version 47 admissible |
| `A61FD3F22142D746` | `com/maddox/il2/objects/air/BF_109G6AS` | 7332 | version 47 admissible |
| `A625270295EC4BC8` | `com/maddox/il2/objects/air/CockpitBF_109Ex$Interpolater` | 2800 | version 47 admissible |
| `B28B584A3626552E` | `com/maddox/il2/objects/air/BF_109K4C3` | 7197 | version 47 admissible |
| `B7C44484A8F7BD14` | `com/maddox/il2/objects/air/CockpitBF_109G14$Variables` | 807 | version 47 admissible |
| `BA5A457ED6AB846C` | `com/maddox/il2/objects/air/CockpitBF_109G6LATE$Interpolater` | 2629 | version 47 admissible |
| `C389CF24F173C884` | `com/maddox/il2/objects/air/CockpitBF_109G10$Interpolater` | 2596 | version 47 admissible |
| `C46C2F6E2D96CF14` | `com/maddox/il2/objects/air/BF_109F4$1` | 646 | version 47 admissible |
| `C8C8404AB8EFEC46` | `com/maddox/il2/objects/air/CockpitBF_109K4` | 12549 | version 47 admissible |
| `CBED1E32E34B7564` | `com/maddox/il2/objects/air/GLADIATOR1` | 2661 | version 47 admissible |
| `CE35B05A7CCF0F8E` | `com/maddox/il2/objects/air/SB_2M103` | 7155 | version 47 admissible |
| `D73F306C23F3CF3E` | `com/maddox/il2/objects/air/BF_109G14` | 6831 | version 47 admissible |
| `DBCEB09699B20C10` | `com/maddox/il2/objects/air/CockpitBF_109Z` | 12798 | version 47 admissible |
| `E1D669FC512B93CE` | `com/maddox/il2/objects/air/BF_109E4` | 5707 | version 47 admissible |
| `E39ACD08B95EF27C` | `com/maddox/il2/objects/air/BF_109F2` | 5780 | version 47 admissible |
| `EF7DACF24A9DAA92` | `com/maddox/il2/objects/air/SB_2M100A` | 7011 | version 47 admissible |
| `EF98B7E659118DDE` | `com/maddox/il2/objects/air/BF_109E7` | 6254 | version 47 admissible |
| `F1E88256AAABC17C` | `com/maddox/il2/objects/air/CockpitBF_109F2$Variables` | 799 | version 47 admissible |
| `F24CD3928A3C42AC` | `com/maddox/il2/objects/air/CockpitBF_109Ex$1` | 250 | version 47 admissible |
| `F511DB262375CB62` | `com/maddox/il2/objects/air/CockpitBF_109K4$Variables` | 816 | version 47 admissible |
| `F5AE4818D1B6A386` | `com/maddox/il2/objects/air/CockpitBF_109F2` | 12319 | version 47 admissible |
| `FF9CB7946CCBACCC` | `com/maddox/il2/objects/air/CockpitBF_109Z$Interpolater` | 2734 | version 47 admissible |
## Regle de conversion

Pour 55 classes, la conversion stagee ne modifie que les octets 6 et 7 de
l'en-tete `ClassFile`. Pour `BF_109F4`, elle remplace aussi la constante
`java/lang/StringBuilder` par `java/lang/StringBuffer`, API equivalente disponible
dans Java 1.3.1. Les originaux ne sont jamais ecrases par cet outil. Le format est decrit par la
[specification JVM Oracle](https://docs.oracle.com/javase/specs/jvms/se6/html/ClassFile.doc.html).

## Anomalies de conditionnement du runtime

Les donnees de ces classes sont decompressables, mais leur CRC central ne correspond pas :

- `com/sun/corba/se/internal/CosNaming/BindingIteratorImpl.class`
- `com/sun/corba/se/internal/CosNaming/BootstrapRequestHandler.class`
- `com/sun/corba/se/internal/CosNaming/BootstrapServer.class`
- `com/sun/corba/se/internal/CosNaming/BootstrapServiceProperties.class`
- `com/sun/corba/se/internal/CosNaming/InternalBindingKey.class`
- `com/sun/corba/se/internal/CosNaming/InternalBindingValue.class`
- `com/sun/corba/se/internal/CosNaming/MinorCodes.class`
- `com/sun/corba/se/internal/CosNaming/NamingContextDataStore.class`
- `com/sun/corba/se/internal/CosNaming/NamingContextImpl.class`
- `com/sun/corba/se/internal/CosNaming/NamingUtils.class`
- `com/sun/corba/se/internal/CosNaming/TransientBindingIterator.class`
- `com/sun/corba/se/internal/CosNaming/TransientNameServer.class`
- `com/sun/corba/se/internal/CosNaming/TransientNameService.class`
- `com/sun/corba/se/internal/CosNaming/TransientNamingContext.class`
- `com/sun/corba/se/internal/corba/AnyImpl.class`
- `com/sun/corba/se/internal/corba/AnyImplHelper.class`
- `com/sun/corba/se/internal/corba/AnyInputStream.class`
- `com/sun/corba/se/internal/corba/AnyOutputStream.class`
- `com/sun/corba/se/internal/corba/AsynchInvoke.class`
- `com/sun/corba/se/internal/corba/CORBAObjectImpl.class`
- ... et 5231 autres entrees.

## Erreurs de lecture des classes libres

- `005AC2886D69B262: lecture hors limites a 0x1FC8`
- `093A4A561ACF3C4C: 2 octets residuels`
- `0A4F63CE6A8870DC: 2 octets residuels`
- `12D86A2CB38BC338: 2 octets residuels`
- `2863B0ECB6C16C1C: lecture hors limites a 0x2E37`
- `410F6CD0EC255D6A: 2 octets residuels`
- `4BB1F1603385B61E: 2 octets residuels`
- `4D23DE507C38D67C: 2 octets residuels`
- `59AE3E28B45C97F6: 2 octets residuels`
- `681E97769782837C: 2 octets residuels`
- `6893B99C2D962470: 2 octets residuels`
- `6E5A6F7299D8DF56: lecture hors limites a 0xE70`
- `7C05C9042502DDD6: 2 octets residuels`
- `8C0550DA3ED22832: 2 octets residuels`
- `A76E244A38A423A4: 2 octets residuels`
- `CA4AB258B52F907E: 2 octets residuels`
- `CC2EBD8E39A9E12A: 2 octets residuels`
- `EC0DA5E423CDC674: 2 octets residuels`
- `F83620787F680B3C: 2 octets residuels`
- `FA003A8809273DBE: lecture hors limites a 0x2ABE`
