module add_skewed_offset_OAAT_signed
#(parameter size_code = 5,
  parameter size_weight = 8,
  parameter size_mem = 16)
(
  input clk, reset,
  input [(size_weight-1):0] weightIn,
  input [(size_mem-1):0] numin,
  output [(size_mem-1):0] out
  );
		
	// Find Offsets
	wire [(size_weight*size_code-1):0] offset;
	find_offset_OAAT #(size_weight, size_code) fe0 (
		.clk(clk), .reset(reset), 
		.numin(weightIn), .offset(offset));

	// Add Offsets
	skew_offset_add_signed #(size_weight, size_mem, size_code) ao0 ( 
		.offset(offset), .numin(numin),
		.out(out));

endmodule
