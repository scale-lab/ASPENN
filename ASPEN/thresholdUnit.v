/*
-----------------------------------------------------
| Created on: 12.07.2018		            						
| Author: Saunak Saha				    
|                                                   
| Department of Electrical and Computer Engineering 
| Iowa State University                             
-----------------------------------------------------
*/

module thresholdUnit
#(
	parameter INTEGER_WIDTH = 8, 
	parameter DATA_WIDTH_FRAC = 0,
	parameter DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC
)
(
	input wire clk,
	// Neuron Parameters
	input wire signed [(DATA_WIDTH-1):0] vth,
	// Membrane Potential
	input wire signed [(DATA_WIDTH-1):0] vmem,
	// Outputs
	output reg signed [(DATA_WIDTH-1):0] vmemOut,
	output reg spikeOut 
);

	always @*
	begin
		if (vmem >= vth) // Spike and reset
		begin
			spikeOut <= 1'b1;
			vmemOut <= 0;
		end
		else // Accumulate potential
		begin
			spikeOut <= 1'b0;
			vmemOut <= vmem;
		end
			
	end

endmodule
