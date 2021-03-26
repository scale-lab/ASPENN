module threshold_unit
#( 
	parameter size_data = 8,
	parameter size_vmem = 16
  )
(
	// Control Signals
	input wire update,
	// Weight Sum Inputs
	input wire [(size_vmem-1):0] impulse,
	// Outputs
	output reg out_spike,
	output reg [(size_vmem-1):0] out_vmem
);
	// Threshold boolean
	wire thresholded;
	assign thresholded = ~impulse[size_vmem-1] && |impulse[size_data +: (size_vmem-size_data-1)];
	always@*
	begin
		if (update)
		begin
			if (thresholded) begin
				out_vmem <= 0;
				out_spike <= 1'b1;
			end else begin
				out_vmem <= impulse;
				out_spike <= 1'b0;
			end
		end else begin
			out_vmem <= 0;
			out_spike <= 0;
		end
	end
endmodule

