# Audit en lecture seule de Buttons et des modeles de vol

L'index du fichier `Files/gui/GAME/buttons` a ete ouvert avec la commande
de liste de NTRK Wizard 0.3, sur une copie temporaire dont l'empreinte a ete
controlee. Aucune extraction, ecriture ou reconstruction de Buttons n'a eu lieu.

## Resultat

- entrees totales de l'archive : **739** ;
- chemins de modeles distincts demandes par `air.ini` : **385** ;
- chemins retrouves dans l'index : **0** ;
- chemins absents prouves : **0** ;
- chemins encore invérifiables : **385** ;
- entrees encore anonymes ou hors perimetre : **739**.

La lecture prouve que la table d'index est accessible et permet d'en mesurer
l'occupation. Elle ne prouve la presence d'un chemin nomme que si le resolveur
le reconnait. L'outil est officiellement etiquete pour le type Buttons 4.10 :
son resolveur ne reconnait pas les empreintes de noms du fichier 4.09m et ses
commandes d'ecriture restent interdites sur la production.

## Modeles absents ou non verifies

Le resolveur de noms 4.10 n'a reconnu aucun chemin 4.09m. Les modeles ci-dessous sont donc **non verifies**, et non declares absents.

- `FlightModels/A-20C.fmd` : A-20C
- `FlightModels/A-20G.fmd` : A-20G
- `FlightModels/A5M4.fmd` : A5M4
- `FlightModels/A6M2-21.fmd` : A6M2-21
- `FlightModels/A6M2.fmd` : A6M2
- `FlightModels/A6M2N.fmd` : A6M2-N
- `FlightModels/A6M3.fmd` : A6M3
- `FlightModels/A6M5a.fmd` : A6M5, A6M5a
- `FlightModels/A6M5b.fmd` : A6M5b
- `FlightModels/A6M5c.fmd` : A6M5c
- `FlightModels/A6M7_Model62.fmd` : A6M7_Model62
- `FlightModels/A6M7_Model63.fmd` : A6M7_Model63
- `FlightModels/Ar-196A-3.fmd` : Ar-196A-3
- `FlightModels/Ar-234B-2.fmd` : Ar-234B-2, Ar-234B-2NJ
- `FlightModels/AviaB-534.fmd` : AviaB534
- `FlightModels/B-17D.fmd` : B-17D
- `FlightModels/B-17E.fmd` : B-17E
- `FlightModels/B-17F.fmd` : B-17F
- `FlightModels/B-17G.fmd` : B-17G
- `FlightModels/B-24J.fmd` : B-24J, B-24J-100-CF
- `FlightModels/B-25C.fmd` : B-25C-25NA
- `FlightModels/B-25G.fmd` : B-25G-1NA
- `FlightModels/B-25H.fmd` : B-25H-1NA
- `FlightModels/B-25J.fmd` : B-25J-1NA
- `FlightModels/B-29.fmd` : B-29, KB_29P
- `FlightModels/B-29SP.fmd` : B-29-SP
- `FlightModels/B5N2.fmd` : B5N2
- `FlightModels/B6N2.fmd` : B6N2
- `FlightModels/BattleMkII.fmd` : FaireyBattle
- `FlightModels/BeaufighterMk1.fmd` : BeaufighterMkI
- `FlightModels/BeaufighterMk21.fmd` : BeaufighterMk21
- `FlightModels/BeaufighterMkX.fmd` : BeaufighterMkX
- `FlightModels/Bf-109B-2.fmd` : Bf-109B-2
- `FlightModels/Bf-109E-4.fmd` : Bf-109E-1, Bf-109E-1_Late, Bf-109E-3, Bf-109E-4
- `FlightModels/Bf-109E-4B.fmd` : Bf-109E-4/B
- `FlightModels/Bf-109E-4N.fmd` : Bf-109E-4N
- `FlightModels/Bf-109E-7.fmd` : Bf-109E-7
- `FlightModels/Bf-109E-7N.fmd` : Bf-109E-7N_Trop
- `FlightModels/Bf-109E-7NZ.fmd` : Bf-109E-7Z
- `FlightModels/Bf-109F-2.fmd` : Bf-109F-1, Bf-109F-2, Bf-109F-2/B, Bf-109F-2/B_Trop, Bf-109F-2_Trop, Bf-109F-2_U1_DZZMod, Bf-109G-4
- `FlightModels/Bf-109F-4.fmd` : Bf-109F-4, Bf-109F-4/B, Bf-109F-4/B_Trop, Bf-109F-4/R1, Bf-109F-4MSTL, Bf-109F-4_Trop, Bf-109F-5_DZZMod, Bf-109F-6_DZZMod
- `FlightModels/Bf-109G-10.fmd` : Bf-109G-10, Bf-109G-10MG, Bf-109G-10_DZZMod, Fabian_Bf-109G-10
- `FlightModels/Bf-109G-10C3.fmd` : Bf-109G-10_ErlaC3_45
- `FlightModels/Bf-109G-10E.fmd` : Bf-109G-10_Erla2
- `FlightModels/Bf-109G-14.fmd` : Bf-109G-14, Bf-109G-14MG
- `FlightModels/Bf-109G-14AS.fmd` : Bf-109G-14AS
- `FlightModels/Bf-109G-2.fmd` : Bf-109G-2, Bf-109G-2T
- `FlightModels/Bf-109G-4.fmd` : Bf-109G-4T
- `FlightModels/Bf-109G-6AS.fmd` : Bf-109G-6AS
- `FlightModels/Bf-109G-6Early.fmd` : Bf-109G-6, Bf-109G-6T, Bf-109G-6_Erla, Graf_Bf-109G-6, Hartmann_Bf-109G-6, Heppes_Bf-109G-6, Kovacs_Bf-109G-6, Molnar_Bf-109G-6
- `FlightModels/Bf-109G-6Late.fmd` : Bf-109G-6_Late, Bf-109G-8_DZZMod
- `FlightModels/Bf-109K-4-C3.fmd` : Bf-109K-4C3
- `FlightModels/Bf-109K-4.fmd` : Bf-109K-4
- `FlightModels/Bf-109Z.fmd` : Bf-109Z
- `FlightModels/Bf-110C-4.fmd` : Bf-110C-4, Bf-110C-4B
- `FlightModels/Bf-110G-2.fmd` : Bf-110G-2, Bf-110G-4R3
- `FlightModels/Bf-110G-4.fmd` : BF-110-G4
- `FlightModels/BI-1.fmd` : BI-1
- `FlightModels/BI-6.fmd` : BI-6
- `FlightModels/Blenheim_MkI.fmd` : BlenheimMkI, BlenheimMkIF
- `FlightModels/Blenheim_MkIV.fmd` : BlenheimMkIV
- `FlightModels/C-47A.fmd` : C-47A
- `FlightModels/C-47B.fmd` : C-47B
- `FlightModels/Cant1007.fmd` : CANT1007, CANT1007t
- `FlightModels/CR32.fmd` : CR-32quater
- `FlightModels/CR42.fmd` : CR_42
- `FlightModels/CW-21.fmd` : CW-21
- `FlightModels/D3A1.fmd` : D3A1
- `FlightModels/DB-3B.fmd` : DB-3b
- `FlightModels/DB-3F.fmd` : DB-3F
- `FlightModels/DB-3M.fmd` : DB-3M
- `FlightModels/DB-3T.fmd` : DB-3T
- `FlightModels/DC-3.fmd` : C-47, L2D
- `FlightModels/Do-335.fmd` : Do-335A-0
- `FlightModels/Do-335V-13.fmd` : Do-335V-13
- `FlightModels/F-86A.fmd` : F-86-A5
- `FlightModels/F-86F1.fmd` : F-86-F1
- `FlightModels/F-86F30.fmd` : F-86-F30
- `FlightModels/F2A-1.fmd` : B-239, BuffaloMkI
- `FlightModels/F2A-2.fmd` : F2A-2
- `FlightModels/F4F-3.fmd` : F4F-3
- `FlightModels/F4F-4.fmd` : F4F-4
- `FlightModels/F4U-1A.fmd` : CorsairMkI, F4U-1A
- `FlightModels/F4U-1Aclipped.fmd` : CorsairMkII
- `FlightModels/F4U-1C.fmd` : F4U-1C, SeaFuryMkX
- `FlightModels/F4U-1D.fmd` : F4U-1D
- `FlightModels/F4U-1Dclipped.fmd` : CorsairMkIV
- `FlightModels/F4U-2.fmd` : F4U-2
- `FlightModels/F4U-5N.fmd` : F4U-5N
- `FlightModels/F51D.fmd` : F51
- `FlightModels/F6F-3.fmd` : F6F-3
- `FlightModels/F6F-5.fmd` : F6F-5
- `FlightModels/F84G.fmd` : F84G3_ThunderJet
- `FlightModels/F9F2.fmd` : F9F2_Panther, XF9F6_Cougar
- `FlightModels/Fi-156B-2.fmd` : Fi-156, RWD_8
- `FlightModels/FM-2.fmd` : FM-2
- `FlightModels/FokkerDK.fmd` : DXXI_DK
- `FlightModels/FokkerDU.fmd` : DXXI_DU
- `FlightModels/FokkerS3Early.fmd` : DXXI_SARJA3_EARLY, Sarvanto_DXXI
- `FlightModels/FokkerS3LATE.fmd` : DXXI_SARJA3_LATE
- `FlightModels/FokkerS4.fmd` : DXXI_SARJA4
- `FlightModels/Fw-189A-2.fmd` : Fw-189A-2
- `FlightModels/Fw-190A-2.fmd` : Fw-190A-2
- `FlightModels/Fw-190A-3.fmd` : Fw-190A-3
- `FlightModels/Fw-190A-4.fmd` : Fw-190A-4
- `FlightModels/Fw-190A-5-165.fmd` : Fw-190A-5165ATA
- `FlightModels/Fw-190A-5.fmd` : Fw-190A-5, Fw-190A-5U14, Fw-190A-6
- `FlightModels/Fw-190A-7sturm.fmd` : Fw-190A-7, Fw-190A-7STURM
- `FlightModels/Fw-190A-8.fmd` : Fw-190A-8, Fw-190A-8Mistel
- `FlightModels/Fw-190A-9.fmd` : Fw-190A-9
- `FlightModels/Fw-190D-11.fmd` : Fw-190D-11
- `FlightModels/Fw-190D-13.fmd` : Fw-190D-13
- `FlightModels/Fw-190D-9.fmd` : Fw-190D-9, Fw-190D-9_DZZMod
- `FlightModels/Fw-190D-9Late.fmd` : Fw-190D-9_Late, Fw-190D-9_Late_DZZMod
- `FlightModels/Fw-190F-8.fmd` : Fw-190F-8, Fw-190F-8U1, Fw-190F-8_DZZMod, Fw-190G-8
- `FlightModels/FW-200C-3U4.fmd` : FW-200C-3U4
- `FlightModels/G-11.fmd` : G-11
- `FlightModels/G-55-late.fmd` : G-55-Late
- `FlightModels/G-55.fmd` : G-55
- `FlightModels/G4M1-11.fmd` : G4M1_11, G4M2E
- `FlightModels/G50.fmd` : G_50
- `FlightModels/GladiatorMkI.fmd` : GladiatorMkI, J8A
- `FlightModels/GladiatorMkII.fmd` : GladiatorMkII
- `FlightModels/H75A2.fmd` : H_75A2
- `FlightModels/H75MO4.fmd` : H75MO4
- `FlightModels/H8K1.fmd` : H8K1
- `FlightModels/HalifaxBMkIII.fmd` : HalifaxBMkIII
- `FlightModels/He-111H-16.fmd` : He-111H-16
- `FlightModels/He-111H-2.fmd` : He-111H-2, He-111H-2N
- `FlightModels/He-111H-21.fmd` : He-111H-21
- `FlightModels/He-111H-6.fmd` : He-111H-6
- `FlightModels/He-111Z.fmd` : He-111Z
- `FlightModels/He-162A-2.fmd` : He-162A-2
- `FlightModels/He-162B.fmd` : He-162B
- `FlightModels/He-162C.fmd` : F84F1_Thunderstreak, F84G1_ThunderJet, He-162C, MiG-15
- `FlightModels/He-LercheIIIB2.fmd` : He-L-IIIB2
- `FlightModels/Ho-229.fmd` : Go-229A-1
- `FlightModels/Hs-129B-2.fmd` : Hs-129B-2, Hs-129B-3/Wa
- `FlightModels/HS123.fmd` : Hs-123
- `FlightModels/HurricaneMkI.fmd` : HurricaneEx, HurricaneMkI, HurricaneMkIaT
- `FlightModels/HurricaneMkIaT.fmd` : HurricaneMkILate
- `FlightModels/HurricaneMkIb.fmd` : HurricaneMkIb, HurricaneMkIbT
- `FlightModels/HurricaneMkII.fmd` : HurricaneMkIIb, HurricaneMkIIbT, HurricaneMkIIc
- `FlightModels/HurricaneMkIIa.fmd` : HurricaneMkIIa
- `FlightModels/HurricaneMkIId.fmd` : HurricaneMkIId
- `FlightModels/HurricaneMkIIMod.fmd` : HurricaneMkIIbMod
- `FlightModels/HurricaneMkIvroeg.fmd` : HurricaneMkIearly
- `FlightModels/I-15-M22.fmd` : I-15_m22
- `FlightModels/I-15-M25.fmd` : I-15_m25
- `FlightModels/I-153-M62.fmd` : I-153M62, I-153P, I-153_2BS, I-153_2SHKAS_BS, I-153_fin
- `FlightModels/I-15bis.fmd` : I-15bis, I-15bis_Skis
- `FlightModels/I-16type10.fmd` : I-16type10
- `FlightModels/I-16type17.fmd` : I-16type17
- `FlightModels/I-16type18.fmd` : I-16type18
- `FlightModels/I-16type24(ofSafonov).fmd` : Safonovs_I-16_24
- `FlightModels/I-16type24.fmd` : I-16type24_SPB, I-16type24orig
- `FlightModels/I-16type27.fmd` : I-16type18-BS, I-16type27
- `FlightModels/I-16type28.fmd` : I-16type24
- `FlightModels/I-16type5.fmd` : I-16type5, I-16type5_SPB
- `FlightModels/I-16type5Skis.fmd` : I-16type5_Skis
- `FlightModels/I-16type6.fmd` : I-16type6
- `FlightModels/I-16type6Skis.fmd` : I-16type6_Skis
- `FlightModels/I-185M-71.fmd` : I-185M-71
- `FlightModels/I-185M-82A.fmd` : I-185M-82A
- `FlightModels/I-250.fmd` : I-250
- `FlightModels/IAR-80.fmd` : IAR80
- `FlightModels/IAR-80A.fmd` : IAR80early
- `FlightModels/IAR-80B.fmd` : IAR80B, IAR80C
- `FlightModels/IAR-80M.fmd` : IAR80M, IAR81Cnew
- `FlightModels/IAR-81a.fmd` : IAR81a, IAR81c
- `FlightModels/Il-10.fmd` : Il-10
- `FlightModels/Il-2-1940.fmd` : Il-2_1940_Early, Il-2_1940_Late
- `FlightModels/Il-2-1941.fmd` : Il-2_1941_Early, Il-2_1941_Late
- `FlightModels/Il-2I.fmd` : Il-2I, Il-2I_DZZMod
- `FlightModels/Il-2M3.fmd` : Il-2T, Il-2T_DZZMod, Il-2_3
- `FlightModels/Il-2M3NS.fmd` : Il-2_M3
- `FlightModels/Il-2MEarly.fmd` : Il-2M_Early
- `FlightModels/Il-2MLate.fmd` : Il-2M_Late
- `FlightModels/Il-4.fmd` : Il-4, Il-4_Late
- `FlightModels/J2M3.fmd` : J2M3
- `FlightModels/J2M5.fmd` : J2M5
- `FlightModels/Ju-52_3mg4e.fmd` : Ju-52/3mg4e
- `FlightModels/Ju-52_3mg5e.fmd` : Ju-52/3mg5e
- `FlightModels/Ju-87B-2.fmd` : Ju-87B-2, Ju-87R-2_DZZMod
- `FlightModels/Ju-87D-3.fmd` : Ju-87D-3
- `FlightModels/Ju-87D-5.fmd` : Ju-87D-5
- `FlightModels/Ju-87G-1.fmd` : Ju-87G-1
- `FlightModels/Ju-87G-2(ofRudel).fmd` : Hans_Rudels_Ju-87G-2
- `FlightModels/Ju-88A-4.fmd` : Ju-88A-4
- `FlightModels/Ju-88A-4Mistel.fmd` : Ju-88Mistel
- `FlightModels/Ki-100-I.fmd` : Ki-100-I-Ko
- `FlightModels/Ki-21-I.fmd` : Ki-21-I
- `FlightModels/Ki-21-II.fmd` : Ki-21-II
- `FlightModels/Ki-27.fmd` : Ki-27-Ko, Ki-27-Otsu, P-26
- `FlightModels/Ki-43-Ia.fmd` : Ki-43-Ia, Ki-43-Ia_DZZMod, Ki-43-Ib, Ki-43-Ib_DZZMod, Ki-43-Ic, Ki-43-Ic_DZZMod
- `FlightModels/Ki-43-II.fmd` : Ki-43-II, Ki-43-II-Kai, Ki-43-II-Kai_DZZMod, Ki-43-II_DZZMod
- `FlightModels/Ki-46-IIIKai.fmd` : Ki-46-Otsu, Ki-46-Otsu-Hei
- `FlightModels/Ki-46-IIIRecce.fmd` : Ki-46-Recce
- `FlightModels/Ki-61-IHei.fmd` : Ki-61-I-Hei
- `FlightModels/Ki-61-IKo.fmd` : Ki-61-I-Ko
- `FlightModels/Ki-61-IOtsu.fmd` : Ki-61-I-Otsu
- `FlightModels/Ki-84-Ia.fmd` : Ki-84-Ia, Ki-84-Ib, Ki-84-Ic
- `FlightModels/La-5.fmd` : La-5
- `FlightModels/La-5F.fmd` : La-5F
- `FlightModels/La-5FEarly.fmd` : La-5F_Early
- `FlightModels/La-5FN.fmd` : La-5FN
- `FlightModels/La-7.fmd` : Kojedubs_La-7, La-7, La-73xB20
- `FlightModels/La-7R.fmd` : La-7R
- `FlightModels/LaGG-3IT.fmd` : LaGG-3IT
- `FlightModels/LaGG-3RD.fmd` : LaGG-3RD
- `FlightModels/LaGG-3series29.fmd` : LaGG-3series29
- `FlightModels/LaGG-3series35.fmd` : LaGG-3series35
- `FlightModels/LaGG-3series4.fmd` : LaGG-3series1, LaGG-3series11, LaGG-3series4
- `FlightModels/LaGG-3series66.fmd` : LaGG-3series66
- `FlightModels/LetovS-328.fmd` : S-328
- `FlightModels/Li-2.fmd` : Li-2
- `FlightModels/MagM14A.fmd` : Magister
- `FlightModels/MartletMkII.fmd` : MartletMkII
- `FlightModels/MBR-2-AM-34.fmd` : MBR-2-AM-34
- `FlightModels/MC-200.fmd` : MC-200series1, MC-200series3, MC-200series7, MC-200series7FB
- `FlightModels/MC-202.fmd` : MC-202, MC-202_III, MC-202_VII, MC-202_XII
- `FlightModels/MC-205.fmd` : MC-205_I, MC-205_III
- `FlightModels/MC-205S.fmd` : MC-205_IIIS
- `FlightModels/MC-205V.fmd` : MC-205_IIIV
- `FlightModels/Me-163B-1a.fmd` : Me-163B-1a
- `FlightModels/Me-210Ca-1.fmd` : Me-210Ca-1, Me-210Ca-1ZSTR
- `FlightModels/Me-262(ofNowotny).fmd` : Nowotnys_Me-262A-1a
- `FlightModels/Me-262A-1a.fmd` : Me-262A-1a, Me-262A-2a
- `FlightModels/Me-262A-1aU4.fmd` : Me-262A-1aU4
- `FlightModels/Me-262HG-II.fmd` : Me-262HG-II
- `FlightModels/Me-321.fmd` : Me-321
- `FlightModels/Me-323.fmd` : Me-323
- `FlightModels/Me-410A.fmd` : ME-410-A
- `FlightModels/Me-410B.fmd` : ME-410-B
- `FlightModels/Me-410D.fmd` : ME-410-D
- `FlightModels/MiG-3(ofPokryshkin).fmd` : Pokryshkins_MiG-3
- `FlightModels/MiG-3.fmd` : MiG-3
- `FlightModels/MiG-3AM-38.fmd` : MiG-3-AM-38
- `FlightModels/MiG-3U.fmd` : MiG-3U
- `FlightModels/MiG-3ud.fmd` : MiG-3-2xShVAK, MiG-3-2xUB, MiG-3ud
- `FlightModels/MiG-3ud_fm.fmd` : MiG-3udfm
- `FlightModels/MiG-9.fmd` : MiG-9FS, MiG-9protoF-2
- `FlightModels/Mosquito-BMkIV.fmd` : MosquitoBMkIV
- `FlightModels/Mosquito-BMkXVI.fmd` : MosquitoBMkXVI
- `FlightModels/Mosquito-FBMkVI.fmd` : MosquitoFBMkVI
- `FlightModels/MS406.fmd` : MS406
- `FlightModels/MS410.fmd` : MS410
- `FlightModels/MSMorko.fmd` : MS-Morko
- `FlightModels/MSMORKO410.fmd` : MsMorko410
- `FlightModels/MXY-7-11.fmd` : MXY-7-11
- `FlightModels/N1K1-J.fmd` : N1K1-J, N1K1-Ja
- `FlightModels/N1K2-Ja.fmd` : N1K2-Ja
- `FlightModels/P-11c.fmd` : P_11c
- `FlightModels/P-24b.fmd` : P_24b
- `FlightModels/P-24e.fmd` : P_24e
- `FlightModels/P-24f.fmd` : P_24f
- `FlightModels/P-24g.fmd` : P_24g
- `FlightModels/P-2V.fmd` : P2V-5
- `FlightModels/P-36A-3.fmd` : P-36A-3
- `FlightModels/P-36A-4.fmd` : P-36A-4
- `FlightModels/P-38J.fmd` : P-38J
- `FlightModels/P-38L.fmd` : P-38L
- `FlightModels/P-38LLate.fmd` : P-38L_Late
- `FlightModels/P-39D.fmd` : P-39D2
- `FlightModels/P-39N(ofPokryshkin).fmd` : Pokryshkins_P-39N1
- `FlightModels/P-39N.fmd` : P-39N1
- `FlightModels/P-39Q-1.fmd` : P-39Q-1
- `FlightModels/P-39Q-10.fmd` : P-39Q-10
- `FlightModels/P-39Q-15(ofRechkalov).fmd` : Rechkalovs_P-39Q15
- `FlightModels/P-400.fmd` : P-39D1, P-400
- `FlightModels/P-40B.fmd` : P-40B, TomahawkMkIIa
- `FlightModels/P-40Breco.fmd` : P-40Breco
- `FlightModels/P-40C.fmd` : Hawk81A-2, P-40C, TomahawkMkIIb
- `FlightModels/P-40E-M-105.fmd` : P-40E-M-105
- `FlightModels/P-40E.fmd` : P-40E
- `FlightModels/P-40M.fmd` : P-40M
- `FlightModels/P-47D-10.fmd` : P-47D-10
- `FlightModels/P-47D-22.fmd` : P-47D-22
- `FlightModels/P-47D-27.fmd` : P-47D-27
- `FlightModels/P-47D-27_late.fmd` : P-47D
- `FlightModels/P-51B.fmd` : P-51B-NA
- `FlightModels/P-51C.fmd` : P-51C-NT
- `FlightModels/P-51CM.fmd` : MustangIII
- `FlightModels/P-51D-20.fmd` : P-51D-20NA, P-51D-5NT
- `FlightModels/P-51D.fmd` : MustangIV, P-51D, P-51D2
- `FlightModels/P-63C.fmd` : P-63C
- `FlightModels/P-80A.fmd` : F-80A, P-80A
- `FlightModels/P-80C.fmd` : RF-80A
- `FlightModels/PBN-1.fmd` : PBN-1
- `FlightModels/PBY.fmd` : PBY-5
- `FlightModels/Pe-2series1.fmd` : Pe-2series1
- `FlightModels/Pe-2series110.fmd` : Pe-2series110
- `FlightModels/Pe-2series359.fmd` : Pe-2series359
- `FlightModels/Pe-2series84.fmd` : Pe-2series84
- `FlightModels/Pe-3bis.fmd` : Pe-3bis
- `FlightModels/Pe-8.fmd` : Pe-8
- `FlightModels/R-10.fmd` : R-10
- `FlightModels/RE-2000.fmd` : RE-2000
- `FlightModels/SB-2M-100A.fmd` : SB_2M-100A
- `FlightModels/SB-2M-103.fmd` : SB_2M-103
- `FlightModels/SBD-3.fmd` : SBD-3
- `FlightModels/SBD-5.fmd` : SBD-5
- `FlightModels/SeafireFMkIII.fmd` : SeafireFMkIII
- `FlightModels/SeafireI.fmd` : SeafireMkI
- `FlightModels/SeafireII.fmd` : SeafireMkII4xH
- `FlightModels/SeafireII45.fmd` : SeafireMkII45
- `FlightModels/SeafireII50.fmd` : SeafireMkII50
- `FlightModels/SeafireIII.fmd` : SeafireMkIII
- `FlightModels/SeaGladiatorMkII.fmd` : SeaGladiatorMkII
- `FlightModels/SeaHurricaneMkI.fmd` : SeaHurricaneMkIbLegacy
- `FlightModels/SeaHurricaneMkIb.fmd` : SeaHurricaneMkIb, SeaHurricaneMkIc
- `FlightModels/SeaHurricaneMkII.fmd` : SeaHurricaneMkIIcLegacy
- `FlightModels/SeaHurricaneMkIIb.fmd` : SeaHurricaneMkIIb, SeaHurricaneMkIIc
- `FlightModels/SM79.fmd` : SM-79
- `FlightModels/SpitfireHF_IXC.fmd` : SpitfireMkIXeHF
- `FlightModels/SpitfireHF_VIII.fmd` : SpitfireMkVIIIHF
- `FlightModels/SpitfireIa.fmd` : SpitfireMk1, SpitfireMkIbFR
- `FlightModels/SpitfireIb.fmd` : SpitfireMkIb
- `FlightModels/SpitfireIIa.fmd` : SpitfireMkIIa
- `FlightModels/SpitfireIIb.fmd` : SpitfireMkIIb
- `FlightModels/SpitfireLF-IX-25.fmd` : SpitfireMkIX25lbs, SpitfireMkIXe25lbs
- `FlightModels/SpitfireLF_IXC.fmd` : SpitfireMkIXc, SpitfireMkIXe
- `FlightModels/SpitfireLF_IXCclipped.fmd` : SpitfireMkIXcCLP, SpitfireMkIXeCLP
- `FlightModels/SpitfireLFVB.fmd` : SpitfireMkVbLF, SpitfireMkVcLF
- `FlightModels/SpitfireLFVBclipped.fmd` : SpitfireMkVbLFCLP, SpitfireMkVcLFCLP
- `FlightModels/SpitfireLFVC.fmd` : SpitfireMkVcLF4xH
- `FlightModels/SpitfireLFXIVE.fmd` : SpitfireMkLFXIVE
- `FlightModels/SpitfireVa.fmd` : SpitfireMkVa
- `FlightModels/SpitfireVB.fmd` : SpitfireMkVb, SpitfireMkVc, SpitfireMkVc4xH, SpitfireMkVcFB
- `FlightModels/SpitfireVBclipped.fmd` : SpitfireMkVbCLP
- `FlightModels/SpitfireVC.fmd` : SpitfireMkVbT, SpitfireMkVcFB4xH
- `FlightModels/SpitfireVIII-25.fmd` : SpitfireMkVIII25lbs
- `FlightModels/SpitfireVIII.fmd` : SpitfireMkIXcLF, SpitfireMkVIII, SpitfireMkVIIIFB
- `FlightModels/SpitfireVIIIclipped.fmd` : SpitfireMkVIIICLP, SpitfireMkVIIICLPFB
- `FlightModels/SpitfireXII.fmd` : SpitfireMkXII
- `FlightModels/SpitfireXIIlate.fmd` : SPITXII
- `FlightModels/SpitfireXIVC.fmd` : SpitfireMkXIVC
- `FlightModels/Su-2.fmd` : Su-2
- `FlightModels/Su-26.fmd` : SU26, Su-26M2
- `FlightModels/Swordfish.fmd` : SwordfishMkI
- `FlightModels/Ta-152C.fmd` : Ta-152C
- `FlightModels/Ta-152C0.fmd` : Ta-152C0
- `FlightModels/Ta-152C1.fmd` : Ta-152C1
- `FlightModels/Ta-152C3.fmd` : Ta-152C3
- `FlightModels/Ta-152H-1.fmd` : Ta-152H-1
- `FlightModels/Ta-183.fmd` : Ta-183
- `FlightModels/TB-3-4M-17.fmd` : TB-3_4M-17, TB-3_4M-17_T_DZZMod
- `FlightModels/TB-3-4M-34R.fmd` : TB-3_4M-34R, TB-3_4M-34R_SPB, TB-3_4M-34R_T_DZZMod
- `FlightModels/TBF-1C.fmd` : TBF-1, TBF-1C
- `FlightModels/TBM-3.fmd` : AvengerMkIII, TBM-3
- `FlightModels/TBM1.fmd` : TBM1
- `FlightModels/TempestMkV.fmd` : TempestMkV
- `FlightModels/TempestMkV11.fmd` : TempestMkV11Lbs
- `FlightModels/TempestMkV13.fmd` : TempestMkV13Lbs
- `FlightModels/Tu-2S.fmd` : Tu-2S
- `FlightModels/Typhoon1B.fmd` : TyphoonMkIB, TyphoonMkIBLate
- `FlightModels/U-2LSH.fmd` : U-2VS(SHKAS)
- `FlightModels/U-2NB.fmd` : U-2NB
- `FlightModels/U-2TM.fmd` : U-2TM
- `FlightModels/U-2UT.fmd` : U-2UT
- `FlightModels/U-2VS.fmd` : U-2VS
- `FlightModels/Yak-1.fmd` : Yak-1
- `FlightModels/Yak-15.fmd` : Yak-15
- `FlightModels/Yak-1B.fmd` : Yak-1B
- `FlightModels/Yak-1BEarly.fmd` : Yak-1B_Early
- `FlightModels/Yak-1PF.fmd` : Yak-1PF
- `FlightModels/Yak-1PF_Light.fmd` : Yak-1PFLight
- `FlightModels/Yak-3.fmd` : Yak-3, Yak-3P
- `FlightModels/Yak-3K.fmd` : Yak-3K
- `FlightModels/Yak-3R.fmd` : Yak-3R
- `FlightModels/Yak-3VK-107.fmd` : Yak-3VK-107, Yak-3VK107(2B20), Yak-3VK107(3B20)
- `FlightModels/Yak-7A.fmd` : Yak-7A, Yak-7UTI
- `FlightModels/Yak-7B.fmd` : Yak-7B
- `FlightModels/Yak-7B_PF.fmd` : Yak-7BPF
- `FlightModels/Yak-9.fmd` : Yak-7B_late, Yak-9
- `FlightModels/Yak-9B.fmd` : Yak-9B
- `FlightModels/Yak-9D.fmd` : Yak-9D, Yak-9RLR_DZZMod
- `FlightModels/Yak-9DD.fmd` : Yak-9DD
- `FlightModels/Yak-9K.fmd` : Yak-9K
- `FlightModels/Yak-9M.fmd` : Yak-9M
- `FlightModels/Yak-9MEarly.fmd` : Yak-9M_Early
- `FlightModels/Yak-9T.fmd` : Durand_Yak-9T, Yak-9T
- `FlightModels/Yak-9U.fmd` : Yak-9U
- `FlightModels/Yak-9UEarly.fmd` : Yak-9U_Early
- `FlightModels/Yak-9UT.fmd` : Yak-9UT

## Partages a examiner pour le realisme

Le partage d'un FMD est normal entre variantes proches. Les groupes ci-dessous
sont conserves dans le manifeste afin de reperer les reutilisations entre cellules
tres differentes ; aucune correction automatique n'est appliquee.

| Modele de vol | Nombre | Appareils |
| --- | ---: | --- |
| `FlightModels/Bf-109F-4.fmd` | 8 | Bf-109F-4, Bf-109F-4/B, Bf-109F-4/B_Trop, Bf-109F-4/R1, Bf-109F-4MSTL, Bf-109F-4_Trop, Bf-109F-5_DZZMod, Bf-109F-6_DZZMod |
| `FlightModels/Bf-109G-6Early.fmd` | 8 | Bf-109G-6, Bf-109G-6T, Bf-109G-6_Erla, Graf_Bf-109G-6, Hartmann_Bf-109G-6, Heppes_Bf-109G-6, Kovacs_Bf-109G-6, Molnar_Bf-109G-6 |
| `FlightModels/Bf-109F-2.fmd` | 7 | Bf-109F-1, Bf-109F-2, Bf-109F-2/B, Bf-109F-2/B_Trop, Bf-109F-2_Trop, Bf-109F-2_U1_DZZMod, Bf-109G-4 |
| `FlightModels/Ki-43-Ia.fmd` | 6 | Ki-43-Ia, Ki-43-Ia_DZZMod, Ki-43-Ib, Ki-43-Ib_DZZMod, Ki-43-Ic, Ki-43-Ic_DZZMod |
| `FlightModels/I-153-M62.fmd` | 5 | I-153M62, I-153P, I-153_2BS, I-153_2SHKAS_BS, I-153_fin |
| `FlightModels/Bf-109E-4.fmd` | 4 | Bf-109E-1, Bf-109E-1_Late, Bf-109E-3, Bf-109E-4 |
| `FlightModels/Bf-109G-10.fmd` | 4 | Bf-109G-10, Bf-109G-10MG, Bf-109G-10_DZZMod, Fabian_Bf-109G-10 |
| `FlightModels/Fw-190F-8.fmd` | 4 | Fw-190F-8, Fw-190F-8U1, Fw-190F-8_DZZMod, Fw-190G-8 |
| `FlightModels/He-162C.fmd` | 4 | F84F1_Thunderstreak, F84G1_ThunderJet, He-162C, MiG-15 |
| `FlightModels/Ki-43-II.fmd` | 4 | Ki-43-II, Ki-43-II-Kai, Ki-43-II-Kai_DZZMod, Ki-43-II_DZZMod |
| `FlightModels/MC-200.fmd` | 4 | MC-200series1, MC-200series3, MC-200series7, MC-200series7FB |
| `FlightModels/MC-202.fmd` | 4 | MC-202, MC-202_III, MC-202_VII, MC-202_XII |
| `FlightModels/SpitfireVB.fmd` | 4 | SpitfireMkVb, SpitfireMkVc, SpitfireMkVc4xH, SpitfireMkVcFB |
| `FlightModels/Fw-190A-5.fmd` | 3 | Fw-190A-5, Fw-190A-5U14, Fw-190A-6 |
| `FlightModels/HurricaneMkI.fmd` | 3 | HurricaneEx, HurricaneMkI, HurricaneMkIaT |
| `FlightModels/HurricaneMkII.fmd` | 3 | HurricaneMkIIb, HurricaneMkIIbT, HurricaneMkIIc |
| `FlightModels/Il-2M3.fmd` | 3 | Il-2T, Il-2T_DZZMod, Il-2_3 |
| `FlightModels/Ki-27.fmd` | 3 | Ki-27-Ko, Ki-27-Otsu, P-26 |
| `FlightModels/Ki-84-Ia.fmd` | 3 | Ki-84-Ia, Ki-84-Ib, Ki-84-Ic |
| `FlightModels/La-7.fmd` | 3 | Kojedubs_La-7, La-7, La-73xB20 |
| `FlightModels/LaGG-3series4.fmd` | 3 | LaGG-3series1, LaGG-3series11, LaGG-3series4 |
| `FlightModels/MiG-3ud.fmd` | 3 | MiG-3-2xShVAK, MiG-3-2xUB, MiG-3ud |
| `FlightModels/P-40C.fmd` | 3 | Hawk81A-2, P-40C, TomahawkMkIIb |
| `FlightModels/P-51D.fmd` | 3 | MustangIV, P-51D, P-51D2 |
| `FlightModels/SpitfireVIII.fmd` | 3 | SpitfireMkIXcLF, SpitfireMkVIII, SpitfireMkVIIIFB |
| `FlightModels/TB-3-4M-34R.fmd` | 3 | TB-3_4M-34R, TB-3_4M-34R_SPB, TB-3_4M-34R_T_DZZMod |
| `FlightModels/Yak-3VK-107.fmd` | 3 | Yak-3VK-107, Yak-3VK107(2B20), Yak-3VK107(3B20) |
| `FlightModels/A6M5a.fmd` | 2 | A6M5, A6M5a |
| `FlightModels/Ar-234B-2.fmd` | 2 | Ar-234B-2, Ar-234B-2NJ |
| `FlightModels/B-24J.fmd` | 2 | B-24J, B-24J-100-CF |
| `FlightModels/B-29.fmd` | 2 | B-29, KB_29P |
| `FlightModels/Bf-109G-14.fmd` | 2 | Bf-109G-14, Bf-109G-14MG |
| `FlightModels/Bf-109G-2.fmd` | 2 | Bf-109G-2, Bf-109G-2T |
| `FlightModels/Bf-109G-6Late.fmd` | 2 | Bf-109G-6_Late, Bf-109G-8_DZZMod |
| `FlightModels/Bf-110C-4.fmd` | 2 | Bf-110C-4, Bf-110C-4B |
| `FlightModels/Bf-110G-2.fmd` | 2 | Bf-110G-2, Bf-110G-4R3 |
| `FlightModels/Blenheim_MkI.fmd` | 2 | BlenheimMkI, BlenheimMkIF |
| `FlightModels/Cant1007.fmd` | 2 | CANT1007, CANT1007t |
| `FlightModels/DC-3.fmd` | 2 | C-47, L2D |
| `FlightModels/F2A-1.fmd` | 2 | B-239, BuffaloMkI |

## Limite d'appareils

Les **739 entrees** mesurees sont l'occupation du Buttons actuel, pas une limite
du moteur. Les retours communautaires decrivent une 'Java Wall' dependante du
nombre, de la taille et surtout de la structure des classes chargees. Les valeurs
observees historiquement variaient suivant les installations ; la limite ne peut
donc pas etre deduite de la taille de Buttons ni fixee a un nombre universel
d'appareils. Open Sturmovik devra la qualifier avec une campagne d'ajout controlee
et des mesures de memoire JVM, sans modifier la version de production.

Le tri retenu pour l'instant est un **manifeste externe alphabetique**. Reordonner
physiquement Buttons n'apporterait aucun gain prouve et restera interdit tant qu'un
aller-retour 4.09m sans perte n'aura pas ete demontre.

## Sources communautaires

- [The BUTTONS file demystified](https://www.sas1946.com/main/index.php?topic=21.0) ;
- [SAS Buttons et derniere base strictement 4.09 (8.7)](https://www.sas1946.com/main/index.php?topic=97.0) ;
- [Discussion Diff-FM et compilation NTRK](https://www.sas1946.com/main/index.php?topic=3988.36) ;
- [Explication de la Java Wall](https://www.sas1946.com/main/index.php?topic=61392.0) ;
- [Retours sur le nombre d'appareils et les classes](https://www.sas1946.com/main/index.php?topic=67329.0) ;
- [Page historique citant les outils QTIM 0.2](https://union.4bb.ru/viewtopic.php?id=370&p=2).
