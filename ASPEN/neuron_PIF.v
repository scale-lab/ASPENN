module neuron_PIF
#( 
	parameter size_data = 8,
	parameter size_vmem = 16,
	parameter size_code = 5
  )
(
	// Control Signals
	input wire clk,
	input wire reset,
	input wire update,
	// Weight Sum Inputs
	input wire [(size_vmem-1):0] impulse,
	// Outputs
	output reg spikeBuffer,
	output reg [(size_vmem-1):0] vmemOut
);
	// Threshold boolean
	wire thresholded;
	assign thresholded = ~impulse[size_vmem-1] && |impulse[size_data +: (size_vmem-size_data-1)];
	always @(posedge clk) begin
		if (~reset) begin
			//Outputs reset
			vmemOut <= 0;
			spikeBuffer <= 0;
		end
		else if (update) begin 
			// Update vmem and spike Buffer
			if (thresholded)
				begin
					vmemOut <= 0;
					spikeBuffer <= 1'b1;
				end
			else
				begin
					vmemOut <= impulse;
					spikeBuffer <= 1'b0;
				end
		end
		else begin
			// Hold neuron value
			vmemOut <= vmemOut;
			spikeBuffer <= spikeBuffer;
		end			
	end	

	

endmodule


