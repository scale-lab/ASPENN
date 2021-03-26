`timescale 1ns/10ps
module tb_top

// Data Parameters
parameter size_data = 8;
parameter size_vmem = 16;
parameter num_input = 31;
// Spike Parameters
parameter size_spike = 10;
parameter size_spike_max = 512;
parameter num_timesteps = 10;
// Neuron Parameters
parameter num_counters = $clog2(num_input);
parameter size_tile = 4;
parameter size_matrix = 16;
parameter num_classes = 10;
// Address Parameters
parameter size_addr_data_cache = 10;
parameter size_addr_mem = 4;
parameter size_addr_spike_cache = 8;
// Layer Dimensions
integer layer_size[0:3] = {784, 1024, 1024, 10};
parameter size_layer_0 = 784;
parameter size_layer_2 = 1024;
parameter size_layer_3 = 1024;
parameter size_layer_4 = 10;
parameter size_max_layer = 1024;
integer layer_select;

// Top Module Setup
// Clock
reg clk;
// Inputs
reg reset;
reg memReady;
reg [(size_data*size_tile-1):0] data_line;
reg [(size_spike-1):0] spike_line;

// Outputs
wire sig_load_data_cache, sig_load_spike_cache, sig_load_spike_mem;
wire [(size_addr_mem-1):0] data_mem_addr;
wire [(size_addr_data_cache-1):0] data_cache_addr;
wire [(size_addr_spike_cache-1):0] spike_cache_addr;
wire [1:0] layer_addr;
wire spike_buffer_toggle;


snn_top snn0 
#(	
	// Data Parameters
	size_data, size_vmem, 
	// Neuron Parameters
	num_counters, size_tile, size_matrix, size_spike_max,
	// Network Parameters
	size_layer_0, size_layer_1, size_layer_2, size_layer_3, size_max_layer, num_timesteps 
)(
	// Inputs
	//  Clock 
	.clk(clk),
	//  Control Signals
	.reset(reset), .memReady(memReady),
	//  Data and Spikes
	.in_data_cache(in_data_cache),
	.in_spike_cache(in_spike_cache),
	// Outputs
	//  Data Cache
	.sig_load_data_cache(sig_load_data_cache),
	.addr_data_cache(addr_data_cache),
	//  Spike Cache
	.sig_load_spike_cache(sig_load_spike_cache),
	.addr_spike_cache(addr_spike_cache),
	//  Spike Memory
	.sig_load_spike_mem(sig_load_spike_mem),
	.addr_spike_mem(add_spike_mem),
	.out_spike_mem(out_spike_mem)
);


// Cache Setup and reading
reg [(size_data*size_tile-1):0] data_cache [(size_matrix*max_layer_size-1):0];

reg [(size_spike-1):0] spike_count [(num_classes-1):0];
reg [(size_spike-1):0] spike_cache [(size_spike_max*num_timesteps-1):0];
reg [(size_spike-1):0] spike_mem [(size_spike_max*num_timesteps-1):0];
assign data_line = memReady ? data_cache[addr_data_cache] : 0;
assign spike_line = memReady ? spike_cache[spike_cache_addr] : 0;

integer layer1_data_file, layer2_data_file, layer3_data_file, input_spike_file;
integer scan_data_file, scan_spike_file;
// Simulation setup and file opening
reg fileDone;
reg signed [(size_spike-1):0] captured_spike;
integer spload_index, spload_time;
initial
begin
	// Simulation File Setup
	layer1_data_file = $fopen("weightsLayer_1.txt", "r");
	layer2_data_file = $fopen("weightsLayer_1.txt", "r");
	layer3_data_file = $fopen("weightsLayer_1.txt", "r");
	input_spike_file = $fopen("./sim/spikeImage_1.txt", "r");
	layer_select = 1;
	// Initial Control Parameters
	clk = 0;
	memReady = 0;
	// Initial Messages
	data_line = 0;
	spike_line = 0;
	
	// Setup Input Spike Memory
	// Spike count header
	for (spload_time = 0; spload_time < num_timesteps; spload_time = spload_time+1)
	begin
		scan_spike_file = $fscanf(input_spike_file, "%b\n", captured_spike);
		spike_count[spload_time] = captured_spike;
	end
	// Initialize Spike Memory to Zero
	for (spload_index = 0; spload_index < (size_spike_max*num_timesteps-1); spload_index=spload_index+1) 
		spike_mem[spload_index] = 0;
	// Read and load input spike file data
	for (spload_time = 0; spload_time < num_timesteps; spload_time = spload_time+1)
	begin
		for (spload_index = 0; spload_index < spike_count[spload_time]; spload_index = spload_index+1)
		begin
			scan_spike_file = $fscanf(input_spike_file, "%b\n", captured_spike);
			spike_mem[spload_time*size_spike_max+spload_index] = captured_spike;
		end
	end
end 

// Clock Generator
always @(*)
begin
	#5
	clk <= !clk;
end

// Data Cache Loading
event data_cache_load_done;
integer scan_data_file;
integer cache_index;
reg [(size_data*size_tile-1):0] captured_data;
always @(posedge sig_load_data_cache)
begin
	case(layer_select)
		1: begin
			for (cache_index = 0; cache_index < (size_matrix*1024); cache_index = cache_index + 1)
			begin
				scan_data_file = $fscanf(layer1_data_file, "%b\n", captured_data); 
				data_cache[cache_index] = captured_data;
			end
		end
		2: begin
			for (cache_index = 0; cache_index < (size_matrix*1024); cache_index = cache_index + 1)
			begin
				scan_data_file = $fscanf(layer2_data_file, "%b\n", captured_data); 
				data_cache[cache_index] = captured_data;
			end
		end
		3: begin
			for (cache_index = 0; cache_index < (size_matrix*1024); cache_index = cache_index + 1)
			begin
				scan_data_file = $fscanf(layer3_data_file, "%b\n", captured_data); 
				data_cache[cache_index] = captured_data;
			end
		end
	endcase
	#10 -> data_cache_load_done;
end

// Spike Cache Load
event spike_cache_load_done;
integer spike_cache_index;
always @(posedge sig_load_spike_cache)
begin
	for (spike_cache_index = 0; spike_cache_index < size_spike_max*num_timesteps; spike_cache_index = spike_cache_index+1)
	begin
		spike_cache[spike_cache_index] = spike_mem[spike_cache_index];
	end
	#10 -> spike_cache_load_done;
end


always @(posedge clk)
begin
	if ~reset
	begin
		if (readyMem)
			scan_file = $fscanf(data_file, "%b\n", captured_data);
			
		if (!$feof(data_file)) begin
			if (readyMem)
				msgData = captured_data;
			else
				msgData = 0;
		end else begin
			if (msgControl != control_finished) begin
				$display("End of File");
				msgData = captured_data;
				msgControl = control_finished;
			end else begin
				msgData = 0;
			end
			
		end
		$display("*****");
		$display("State: %d", stateOut);
		$display("Control: %b", msgControl);
		$display("Weight Sum: %d", weightSum);
		$display("Vmem Out: %d", vmemOut);
		$display("Read Memory: %d", readyMem);
		$display("Finished: %d", finished);
		$display("Spike: %b", spikeBuffer);
	end	
end

// Termination Condition
event terminate_sim;  
always begin  
	@ (terminate_sim); 
	#5 $finish; 
end 

endmodule