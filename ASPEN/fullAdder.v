module fullAdder(A, B, C, YS, YC);
	input A,B,C;
	output YS, YC;
	assign YS = A ^ B ^ C;
	assign YC = (A && B) || (C && (A || B));
endmodule