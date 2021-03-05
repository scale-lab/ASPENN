module neuron_tile 
#(
	parameter size_control = 4,
	parameter size_data = 8,
	parameter size_vmem = 16,
	parameter num_counters = 5,
	parameter size_tile = 4
)
(
	// Clock Signal
	input clk, 
	// Messages (Control, Data, Vmem)
	input [(size_control-1):0] msgControl,
	input [(size_data*size_tile-1):0] msgData,
	input [(size_vmem*size_tile-1):0] msgVmem,
	// Outputs
	output spikeBuffer,
	output [(size_vmem*size_tile-1):0] vmemOut
	output [(size_vmem*size_tile-1):0] test_vmem, // Test
	output [2:0] test_state // Test
)
	// Testing
	assign test_state = state;
	assign test_vmem = vmem_cache;

	// Control Signals
	reg counter_reset, counter_enable, ncounter_enable, neuron_reset, neuron_enable, neuron_update;
	parameter size_select = $clog2(size_tile);
	reg [(size_select-1):0] neuron_select;

	// Neuron Counters, one per neuron in tile
	parameter size_compressed = size_data*num_counters;
	wire [size_compressed*size_tile-1:0] data_compressed;
	genvar ii;
	generate
		for (ii = 0; ii < size_tile; ii = ii + 1)
		compressor ci #(size_data, num_counters)
			(clk, counter_reset, counter_enable, msgData[size_data*ii +: size_data], 
			data_compressed[size_compressed*ii +: size_compressed]);
		end
	endgenerate
	
	// Select specific neuron compressor
	reg [(size_tile*size_vmem-1):0] vmem_cache;
	reg [(size_vmem-1):0] vmem_out;
	
	// Vmem Cache Control
	integer jj;
	always @(posedge clk)
	begin
		if (state == st_setup)
		begin
			vmem_cache <= msgVmem;
		end else if (state == st_update || state == st_compute)
		begin
			for (jj = 0; jj < size_tile; jj = jj+1)
			begin
				if (jj == neuron_select)
				begin
					vmem_cache[jj*size_vmem +: size_vmem] <= vmem_out[jj*size_vmem +: size_vmem];
				end
			end
		end else
			vmem_cache <= vmem_cache;
	end
	
	// Select Compressed and Vmem for neuron computation
	reg [(size_compressed-1):0]  compressed_select;
	reg [(size_vmem-1):0] vmem_select;
	
	integer select;
	always @*
	begin
		for (select = 0; select < size_tile; select = select+1)
			if (neuron_select == select) begin
				compressed_select <= data_compressed[select*size_offset +: size_offset];
				vmem_select <= vmem_cache[select*size_vmem +: size_vmem];
			end
		end
		if (neuron_enable == 1) begin
			compressed <= compressed_select;
			vmem <= vmem_select;
		end else begin
			compressed <= 0;
			vmem <= 0;
		end
	end
	
	wire [(size_vmem-1):0] impulse;
	// Send neuron counter offset to skewed adder and neuron update unit
	skew_offset_add_signed #(size_data, size_vmem, num_counters) ao0 ( 
		.offset(compressed), .numin(vmem),
		.out(impulse));
		
	neuron_PIF #(size_data, size_vmem, num_counters) pif0 (
		.clk(clk), .reset(neuron_reset), .update(neuron_update), 
		.impulse(impulse),
		.vmemOut(vmem_out), .spikeBuffer(spikeBuffer));
	
	// State Machine
	// Control Signals
	// State Signals
	reg [2:0] state, next_state;
	parameter st_reset = 0, st_setup = 1, st_count = 2, st_hold = 4, st_compute = 5, st_update = 6, st_store = 7;
	
	reg reset, memReady, memSD, memStop, finished;
	assign reset = msgControl[0];
	assign memReady = msgControl[1];
	assign memSD = msgControl[2];
	assign memStop = ~(msgControl[1] || msgControl[2]);
	assign finished = msgControl[3];
	
	always @(*)
	begin
		if (~reset)
			next_state <= st_reset;
		else
		begin
			case (state)
				st_reset:
					begin
					if (memReady && ~memSD)
						next_state <= st_setup;
					else
						next_state <= st_hold;
					end
				st_setup:
					begin
					if (memReady && memSD)
						next_state <= st_count;
					else
						next_state <= st_hold;
					end	
				st_hold:
					begin
					if (~memReady)
						next_state <= st_hold;
					else begin
						if (memSD)
							next_state <= st_count;
						else
							next_state <= st_setup;
					end
				st_count:
					begin
					if (finished || (count == ~0-1))
						next_state <= st_compute;
					else
						begin
						if (memReady && memSD)
							next_state <= st_count;
						else
							next_state <= st_hold;
						end
					end
				st_compute:
					begin
					if (neuron_select == size_tile)
					begin
						if (finished == 1)
							next_state <= st_update;
						else 
							next_state <= st_hold;
					end
					else 
						next_state <= st_compute;
					end
				st_update:
					begin
					if (neuron_select == size_tile)
						next_state <= st_store;
					else 
						next_state <= st_update;
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
	
	// Count State counter
	wire [(num_counters-1):0] count;
	counters #(num_counters) c_st_count (clk, counter_reset, counter_enable, count);
	counters #(size_select) c_st_compute (clk, neuron_reset, ncouter_enable, neuron_select);
	
	// Signal Controller
	always@(*)
	begin
		case (state)
			st_reset:
			begin
				counter_reset <= 0;
				counter_enable <= 0;
				ncounter_enable <= 0;
				neuron_reset <= 0;
				neuron_enable <= 0;
				neuron_update <= 0;
			end
			st_setup:
			begin
				counter_reset <= 0;
				counter_enable <= 0;
				ncounter_enable <= 0;
				neuron_reset <= 0;
				neuron_enable <= 0;
				neuron_update <= 0;
			end
			st_count:
			begin
				counter_reset <= 1;
				counter_enable <= 1;
				ncounter_enable <= 0;
				neuron_reset <= 0;
				neuron_enable <= 0;
				neuron_update <= 0;
			end
			st_hold:
			begin
				counter_reset <= 1;
				counter_enable <= 0;
				ncounter_enable <= 0;
				neuron_reset <= 0;
				neuron_enable <= 0;
				neuron_update <= 0;
			end
			st_compute:
			begin
				counter_reset <= 1;
				counter_enable <= 0;
				ncounter_enable <= 1;
				neuron_reset <= 1;
				neuron_enable <= 1;
				neuron_update <= 0;
			end
			st_update:
			begin
				counter_reset <= 0;
				counter_enable <= 0;
				ncounter_enable <= 1;
				neuron_reset <= 1;
				neuron_enable <= 0;
				neuron_update <= 1;
			end
			st_store:
			begin
				counter_reset <= 0;
				counter_enable <= 0;
				ncounter_enable <= 0;
				neuron_reset <= 1;
				neuron_enable <= 0;
				neuron_update <= 0;
			end
			default:
			begin
				counter_reset <= counter_reset;
				counter_enable <= counter_enable;
				ncounter_enable <= ncounter_enable;
				neuron_reset <= neuron_reset;
				neuron_enable <= neuron_enable;
				neuron_update <= neuron_update;
			end
		endcase
	end
	
endmodule