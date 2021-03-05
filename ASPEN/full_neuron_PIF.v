module full_neuron_PIF
#(
	parameter INTEGER_WIDTH = 16,
	parameter DATA_WIDTH_FRAC = 0,
	parameter DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC,
	parameter num_input = 31
 )

 (
	// Control Signals
	input clk, input reset, input updateEnable,
	// Neuron Parameters
	input [(DATA_WIDTH-1):0] threshold,
	// Weight Sum Inputs
	input [(DATA_WIDTH-1):0] weightData,
	// Outputs
	output spikeBuffer, 
	output [(DATA_WIDTH-1):0] weight,
	output [(DATA_WIDTH-1):0] vmemOut
 );
	
	parameter size_code = $clog2(num_input);
	parameter size_weightSum = DATA_WIDTH + size_code;
	
	wire signed [(size_weightSum-1):0] weightSum;
	
	add_skewed_offset_OAAT #(num_input, DATA_WIDTH) aoff0 (
		.clk(clk), .reset(reset), .numin(weightData), .out(weightSum));
	
	//wire [(DATA_WIDTH-1):0] weight;
	assign weight = weightSum[0 +: DATA_WIDTH];
	
	neuron_PIF #(INTEGER_WIDTH, DATA_WIDTH_FRAC, DATA_WIDTH) np0 (
		.clk(clk), .reset(reset), .updateEnable(updateEnable), 
		.threshold(threshold), .weightSum(weight), 
		.spikeBuffer(spikeBuffer), .vmemOut(vmemOut));

endmodule