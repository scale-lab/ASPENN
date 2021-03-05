/***
* This code is a part of EvoApproxLib library (ehw.fit.vutbr.cz/approxlib) distributed under The MIT License.
* When used, please cite the following article(s):  
* This file contains a circuit from a sub-set of pareto optimal circuits with respect to the pwr and wce parameters
***/
// MAE% = 0.046 %
// MAE = 30 
// WCE% = 0.13 %
// WCE = 86 
// WCRE% = 6300.00 %
// EP% = 99.02 %
// MRE% = 0.96 %
// MSE = 1281 
// PDK45_PWR = 0.043 mW
// PDK45_AREA = 85.9 um2
// PDK45_DELAY = 0.76 ns

module add2x16_approx (
    A,
    B,
    O
);

input [15:0] A;
input [15:0] B;
output [15:0] O;

wire sig_34,sig_37,sig_44,sig_45,sig_46,sig_47,sig_48,sig_49,sig_50,sig_51,sig_52,sig_53,sig_54,sig_55,sig_56,sig_57,sig_58,sig_59,sig_60,sig_61;
wire sig_62,sig_63,sig_64,sig_65,sig_66,sig_67,sig_68,sig_69,sig_70,sig_71,sig_72,sig_73,sig_74,sig_75,sig_76,sig_77,sig_78,sig_79,sig_80,sig_81;
wire sig_82,sig_83,sig_84,sig_85,sig_86,sig_87,sig_88,sig_89,sig_90,sig_91,sig_92,sig_93,sig_94,sig_95,sig_96,sig_97,sig_98,sig_99,sig_100,sig_101;
wire sig_102,sig_103,sig_104,sig_105,sig_106,sig_107;

assign sig_34 = ~(B[1] & B[1]);
assign sig_37 = ~sig_34;
assign sig_44 = A[3] ^ B[3];
assign sig_45 = A[3] & B[3];
assign sig_46 = sig_44 & A[2];
assign sig_47 = sig_44 ^ A[2];
assign sig_48 = sig_45 | sig_46;
assign sig_49 = A[4] ^ B[4];
assign sig_50 = A[4] & B[4];
assign sig_51 = sig_49 & sig_48;
assign sig_52 = sig_49 ^ sig_48;
assign sig_53 = sig_50 | sig_51;
assign sig_54 = A[5] ^ B[5];
assign sig_55 = A[5] & B[5];
assign sig_56 = sig_54 & sig_53;
assign sig_57 = sig_54 ^ sig_53;
assign sig_58 = sig_55 | sig_56;
assign sig_59 = A[6] ^ B[6];
assign sig_60 = A[6] & B[6];
assign sig_61 = sig_59 & sig_58;
assign sig_62 = sig_59 ^ sig_58;
assign sig_63 = sig_60 | sig_61;
assign sig_64 = A[7] ^ B[7];
assign sig_65 = A[7] & B[7];
assign sig_66 = sig_64 & sig_63;
assign sig_67 = sig_64 ^ sig_63;
assign sig_68 = sig_65 | sig_66;
assign sig_69 = A[8] ^ B[8];
assign sig_70 = A[8] & B[8];
assign sig_71 = sig_69 & sig_68;
assign sig_72 = sig_69 ^ sig_68;
assign sig_73 = sig_70 | sig_71;
assign sig_74 = A[9] ^ B[9];
assign sig_75 = A[9] & B[9];
assign sig_76 = sig_74 & sig_73;
assign sig_77 = sig_74 ^ sig_73;
assign sig_78 = sig_75 | sig_76;
assign sig_79 = A[10] ^ B[10];
assign sig_80 = A[10] & B[10];
assign sig_81 = sig_79 & sig_78;
assign sig_82 = sig_79 ^ sig_78;
assign sig_83 = sig_80 | sig_81;
assign sig_84 = A[11] ^ B[11];
assign sig_85 = A[11] & B[11];
assign sig_86 = sig_84 & sig_83;
assign sig_87 = sig_84 ^ sig_83;
assign sig_88 = sig_85 | sig_86;
assign sig_89 = A[12] ^ B[12];
assign sig_90 = A[12] & B[12];
assign sig_91 = sig_89 & sig_88;
assign sig_92 = sig_89 ^ sig_88;
assign sig_93 = sig_90 | sig_91;
assign sig_94 = A[13] ^ B[13];
assign sig_95 = A[13] & B[13];
assign sig_96 = sig_94 & sig_93;
assign sig_97 = sig_94 ^ sig_93;
assign sig_98 = sig_95 | sig_96;
assign sig_99 = A[14] ^ B[14];
assign sig_100 = A[14] & B[14];
assign sig_101 = sig_99 & sig_98;
assign sig_102 = sig_99 ^ sig_98;
assign sig_103 = sig_100 | sig_101;
assign sig_104 = A[15] ^ B[15];
assign sig_105 = A[15] & B[15];
assign sig_106 = sig_104 & sig_103;
assign sig_107 = sig_104 ^ sig_103;

assign O[15] = sig_107;
assign O[14] = sig_102;
assign O[13] = sig_97;
assign O[12] = sig_92;
assign O[11] = sig_87;
assign O[10] = sig_82;
assign O[9] = sig_77;
assign O[8] = sig_72;
assign O[7] = sig_67;
assign O[6] = sig_62;
assign O[5] = sig_57;
assign O[4] = sig_52;
assign O[3] = sig_47;
assign O[2] = B[2];
assign O[1] = sig_37;
assign O[0] = B[0];


endmodule


