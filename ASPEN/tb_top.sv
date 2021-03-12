`timescale 1ns/10ps
module tb_top

// Data Parameters
parameter size_data = 8;
parameter size_vmem = 16;
parameter num_input = 31;
// Spike Parameters
parameter size_spike = 10;
parameter size_spike_max = 256;
parameter num_timesteps = 8;
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
integer layer_select;

// Top Module Setup
// Clock
reg clk;
// Inputs
reg reset;
reg memReady;
reg [(size_data*size_tile-1):0] data_line;
reg [(size_data*size_tile-1):0] spike_line;

// Outputs
wire data_load;
wire [(size_addr_mem-1):0] data_mem_addr;
wire [(size_addr_data_cache-1):0] data_cache_addr;
wire [(size_addr_spike_cache-1):0] spike_cache_addr;
wire [1:0] layer_addr;
wire spike_buffer_toggle;

snn_top snn0 #(size_data, size_vmem, num_input, num_counters, size_tile, size_matrix) 
(
	// Control Signals
	.clk(clk), .reset(reset), .memReady(memReady),
	// Inputs
	.data_line(data_line),
	.spike_line(spike_line),
	// Outputs
	.data_load(data_load),
	.layer_addr(layer(addr),
	.data_mem_addr(data_mem_addr), .data_cache_addr(data_cache_addr),
	.spike_addr(spike_cache_addr), .spike_buffer_toggle(spike_buffer_toggle),
	.spike_out(spike_out)
);


// Cache Setup and reading
reg [(size_data*size_tile-1):0] data_cache [(size_matrix*1024-1):0];

reg [(size_spike-1):0] spike_count [(num_classes-1):0];
reg [(size_spike-1):0] spike_cache [(size_spike_max*num_timesteps-1):0];
reg [(size_spike-1):0] spike_mem [(size_spike_max*num_timesteps-1):0];
assign data_line = memReady ? data_cache[data_cache_addr] : 0;
assign spike_line = memReady ? spike_cache[spike_cache_addr] : 0;

integer layer1_data_file, layer2_data_file, layer3_data_file, input_spike_file;
integer scan_data_file, scan_spike_file;



// Simulation setup and file opening
reg fileDone;
reg signed [(size_spike-1):0] captured_spike;
integer spload_index, spload_time;
initial
begin
	// Simulation Setup
	layer1_data_file = $fopen("bin_weights_layer1.txt", "r");
	layer2_data_file = $fopen("bin_weights_layer2.txt", "r");
	layer3_data_file = $fopen("bin_weights_layer3.txt", "r");
	input_spike_file = $fopen("bin_input_spike.txt", "r");
	layer_select = 1;
	// Initial Control Parameters
	clk = 0;
	memReady = 0;
	// Initial Messages
	data_line = 0;
	spike_line = 0;
	// Setup Input Spike Memory
	for (spload_time = 0; spload_time < num_timesteps; spload_time = spload_time+1)
	begin
		scan_file = $fscanf(input_spike_file, "%b\n", captured_spike);
		spike_count[spload_time] = captured_spike;
	end
	for (spload_time = 0; spload_time < num_timesteps; spload_time = spload_time+1)
	begin
		for (spload_index = 0; spload_index < spike_count[spload_time]; spload_index = spload_index+1)
		begin
			scan_file = $fscanf(input_spike_file, "%b\n", captured_spike);
			spike_cache[spload_index] = captured_spike;
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
event mem_load_done;
integer scan_data_file;
integer cache_index;
reg [(size_data*size_tile-1):0] captured_data;
always @(posedge data_load)
begin
	for (cache_index = 0; cache_index < (size_matrix*1024); cache_index = cache_index + 1)
	begin
		case(layer_select)
			1: scan_data_file = $fscanf(layer1_data_file, "%b\n", captured_data); 
			2: scan_data_file = $fscanf(layer2_data_file, "%b\n", captured_data); 
			3: scan_data_file = $fscanf(layer3_data_file, "%b\n", captured_data); 
		endcase
		data_cache[cache_index] = captured_data;
	end
	#10 -> mem_load_done;
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

event terminate_sim;  
initial begin  
	@ (terminate_sim); 
	#5 $finish; 
end 

endmodule