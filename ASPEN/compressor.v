module compressor
	#(parameter size_input = 8,
	  parameter size_code = 5)
	(clk, reset, enable, numin, countout);
	
	input clk, reset, enable;
	input [size_input-1:0] numin;
	output [size_input*size_code-1:0] countout;
	
	genvar i;
	generate
	begin
		for (i = 0; i < (size_input-1); i = i + 1)
		begin
			counters #(size_code) ci (clk, reset, enable, numin[i], countout[i*size_code +: size_code]);
		end
		counters_neg #(size_code) cneg (clk, reset, enable, numin[size_input-1], countout[(size_input-1)*size_code +: size_code]);
	end
	endgenerate
	
endmodule
