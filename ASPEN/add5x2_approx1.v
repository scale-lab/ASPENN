module add5x2_approx1(numin, out);
input [9:0] numin;
output [3:0] out;

wire [1:0] sig_0, sig_1, sig_2, sig_3, sig_4, sig_5;

// Approx Method 1: Error(out) = [-1, 0, +1, +2], E(error) = +0.5 Prob(error) = 0.75
fullAdder fa0 (.A(numin[0]), .B(numin[2]), .C(numin[4]), .YC(sig_0[1]), .YS(out[0]));
assign sig_2[1] = numin[6] && numin[8];

fullAdder fa1 (.A(numin[1]), .B(numin[3]), .C(numin[5]), .YC(sig_1[1]), .YS(sig_1[0]));
assign sig_3[0] = ~(numin[7] ^ numin[9]);
assign sig_3[1] = numin[7] || numin[9];

fullAdder fa4 (.A(sig_0[1]), .B(sig_2[1]), .C(sig_3[0]), .YC(sig_4[1]), .YS(out[1]));
fullAdder fa5 (.A(sig_1[1]), .B(sig_3[1]), .C(sig_4[1]), .YC(out[3]), .YS(out[2]));

endmodule