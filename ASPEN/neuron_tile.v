module neuron_tile 
#(
	parameter size_data = 8,
	parameter size_vmem = 16,
	parameter num_counters = 5,
	parameter size_tile = 4
)
(
	// Clock Signal
	input clk, 
	// Control Signals
	input reset, block_done, update,
	// Data Input
	input [(size_data*size_tile-1):0] in_weight,
	// Outputs
	output reg out_spikeValid,
	output reg [(size_tile-1):0] out_spike
);
	// Control Signals
	reg compressor_reset, compressor_enable, neuron_enable, neuron_update;
	parameter size_select = $clog2(size_tile);
	wire [(size_select-1):0] neuron_select;

	// State Signals
	reg [2:0] state, next_state;
	parameter st_reset = 0, st_count = 1, st_compute = 2, st_update = 3, st_store = 4;

	// Count State counter
	reg counter_reset, counter_enable;
	counters #(size_select) c_st_compute (.clk(clk), .reset(counter_reset), .enable(counter_enable), 
		.bitin(counter_enable), .counter(neuron_select));
		
	// Neuron Counters, one per neuron in tile
	parameter size_compressed = size_data*num_counters;
	wire [size_compressed*size_tile-1:0] data_compressed;
	genvar ii;
	generate
		for (ii = 0; ii < size_tile; ii = ii + 1) begin
		compressor #(size_data, num_counters) cii
			(clk, compressor_reset, compressor_enable, in_weight[size_data*ii +: size_data], 
			data_compressed[size_compressed*ii +: size_compressed]);
		end
	endgenerate
	
	// Select Compressed and Vmem for neuron computation
	reg [(size_compressed-1):0] compressed_select;
	reg [(size_vmem-1):0] vmem_select;
	
	// Vmem Cache and Output Spike Latching
	reg [(size_tile*size_vmem-1):0] vmem_cache, vmem_cache_reg;
	wire [(size_vmem-1):0] vmem_out;
	wire neuron_spike;
	integer jj;
	always @(*)
	begin
		case (state)
			st_reset: vmem_cache_reg <= 0;
			st_update: begin
				for (jj = 0; jj < size_tile; jj = jj+1)
				begin
					if (jj == neuron_select)
					begin
						vmem_cache_reg[jj*size_vmem +: size_vmem] <= vmem_out;
					end
				end
			end
			st_compute: begin
				for (jj = 0; jj < size_tile; jj = jj+1)
				begin
					if (jj == neuron_select)
					begin
						vmem_cache_reg[jj*size_vmem +: size_vmem] <= vmem_out;
					end
				end
			end
			default: vmem_cache_reg <= vmem_cache_reg;
		endcase
	end
	
	always @(posedge clk)
	begin
		vmem_cache <= vmem_cache_reg;
		// Output Spike
		case (state)
			st_reset: out_spike = 0;
			st_update: out_spike[neuron_select] = neuron_spike;
			default: out_spike[neuron_select] = out_spike[neuron_select];
		endcase
	end
	
	
	integer select;
	always @*
	begin
		// Neuron Select
		if (neuron_enable == 1) begin
			compressed_select = data_compressed[neuron_select*size_compressed +: size_compressed];
			vmem_select = vmem_cache[neuron_select*size_vmem +: size_vmem];
		end else begin
			compressed_select = 0;
			vmem_select = 0;
		end
	end
	
	wire [(size_vmem-1):0] impulse;
	// Send neuron counter offset to skewed adder and neuron update unit
	skew_offset_add_signed #(size_data, size_vmem, num_counters) ao0 ( 
		.offset(compressed_select), .numin(vmem_select),
		.out(impulse));
	
	
	threshold_unit #(size_data, size_vmem) thresh0 (
		.update(neuron_update), 
		.impulse(impulse),
		.out_vmem(vmem_out), .out_spike(neuron_spike));
	
	always @*
	begin
		case (state)
			st_store: out_spikeValid = (|out_spike);
			default: out_spikeValid = 0;
		endcase
	end
	
	
	// State Machine
	always @(*)
	begin
		if (~reset)
			next_state <= st_reset;
		else
		begin
			case (state)
				st_reset:
					next_state <= st_count;
				st_count:
					begin
					if (block_done)
						next_state <= st_compute;
					else
						next_state <= st_count;
					end
				st_compute:
					begin
					if (neuron_select == (size_tile-1))
					begin
						if (update)
							next_state <= st_update;
						else 
							next_state <= st_count;
					end
					else 
						next_state <= st_compute;
					end
				st_update:
					begin
					if (neuron_select == (size_tile-1))
						next_state <= st_store;
					else 
						next_state <= st_update;
					end
				st_store:
					next_state <= st_reset;
				default:
					next_state <= st_reset;
			endcase
		end
	end

	 // State Update
	always @(posedge clk)
	begin
		state <= next_state;
	end
	
	// Signal Controller
	reg [5:0] sig_control;
	
	always@(*)
	begin
		compressor_reset <= sig_control[0];
		compressor_enable <= sig_control[1];
		counter_reset <= sig_control[2];
		counter_enable <= sig_control[3];
		neuron_enable <= sig_control[4];
		neuron_update <= sig_control[5];
		case (state)
			st_reset: sig_control 	<= 6'b000000;
			st_count: sig_control 	<= 6'b000011;
			st_compute: sig_control <= 6'b011101;
			st_update: sig_control 	<= 6'b101101;
			st_store: sig_control 	<= 6'b000101;
			default: sig_control 	<= sig_control;
		endcase
	end
	
endmodule