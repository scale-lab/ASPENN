module counters
	#(parameter size_code)
	 (clk, reset, enable, bitin, counter);

	input clk, reset, enable, bitin;
	output wire [size_code-1:0] counter;
	wire [size_code-1:0] mid;
	assign mid = ~counter;
	
	wire activate, data0;
	assign activate = enable && bitin;
	assign data0 = activate ? mid[0] : counter[0];
	DFFSR d0(.R (reset), .S (1'b1), .CLK (clk), .D (data0), .Q (counter[0]));
	generate 
		genvar i;
		for (i = 1; i < size_code; i = i + 1)
		begin
			DFFSR di(.R (reset), .S (1'b1), .CLK (mid[i-1]), .D (mid[i]), .Q (counter[i]));
		end
	endgenerate
endmodule
