module neuron_matrix
#(
	parameter size_data = 8,
	parameter size_vmem = 16,
	parameter num_counters = 5,
	parameter size_tile = 4,
	parameter size_matrix = 16,
	parameter size_addr_matrix = $clog2(size_matrix)
)
(
	// Clock Signal
	input clk,
	// Control Signals
	input reset, enable, block_done, update,
	// Data Input
	input [(size_data*size_tile-1):0] in_weight,
	input [(size_addr_matrix-1):0] in_addr,
	// Outputs
	output reg out_spikeValid,
	output reg [(size_tile-1):0] out_spike,
	output reg [(size_addr_matrix-1):0] out_spikeAddress

);
	
	parameter size_weight = size_data*size_tile;
	reg [(size_matrix*size_weight-1):0] tile_weight;
	wire [(size_matrix*size_tile-1):0] tile_spike;
	wire [(size_matrix-1):0] tile_spikeValid;
	
	// Matrix Tiles
	genvar tile_i;
	generate
		for (tile_i = 0; tile_i < size_matrix; tile_i = tile_i + 1)
		begin
			neuron_tile #(size_data, size_vmem, num_counters, size_tile) nti
			(
				.clk(clk), .reset(reset), .block_done(tile_block_done[tile_i]), .update(tile_update[tile_i]),
				.in_weight(tile_weight[tile_i*size_weight +: size_weight]), // [(size_data*size_tile-1):0] in_weight,
				.out_spikeValid(tile_spikeValid[tile_i]),
				.out_spike(tile_spike[tile_i*size_tile +: size_tile])  // [size_tile:0] out_spike,
			);
		end
	endgenerate
	
	// Tile I/O
	reg [(size_matrix-1):0] tile_block_done, tile_update;
	integer ii;
	always@*
	begin
		// Weight Writing
		if (enable)
		begin
			// Tile Spiking Check
			for (ii = 0; ii < size_matrix; ii=ii+1)
			begin
				// Tile Weight Input Select
				if (in_addr == ii) begin
					tile_weight[ii*size_weight +: size_weight] = in_weight;
					tile_block_done[ii] = block_done;
					tile_update[ii] = update;
				end else begin
					tile_weight[ii*size_weight +: size_weight] = 0;
					tile_block_done[ii] = 0;
					tile_update[ii] = 0;
				end
			end
		end else begin
			tile_weight = 0;
			tile_block_done = 0;
			tile_update = 0;
		end
		
		// Spike Reading
		out_spikeValid = |tile_spikeValid;
		// Tile Spike Output Address
		if (out_spikeValid) begin
			for (ii = 0; ii < size_matrix; ii=ii+1)
			begin
				if (tile_spikeValid[ii]) begin
					out_spikeAddress = ii;
				end
			end
			out_spike = tile_spike[out_spikeAddress*size_tile +: size_tile];
		end else begin
			out_spikeAddress = 0;
			out_spike = 0;
		end
	end

endmodule