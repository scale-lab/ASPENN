module snn_top
#(
	parameter size_data = 8,
	parameter size_vmem = 16,
	parameter size_counters = 5,
	parameter size_tile = 4,
	parameter num_tiles = 16,
	parameter num_layers = 3,
)

neuron_tile nt0 #(size_data, size_vmem, size_counters, size_tile) (
	clk, 
	reset, enable, memReady, finished,
	weightData, vmemData,
	spikeBuffer, vmemOut
)

module neuron_tile 
#(
	parameter size_data = 8,
	parameter size_vmem = 16,
	parameter size_counters = 5,
	parameter size_tile = 4
)
(
	// Clock Signal
	input clk, 
	// Control Signals
	input reset, enable, memReady, finished,
	// Data Inputs
	input [(size_tile*size_data-1):0] weightData,
	input [(size_tile*size_vmem-1):0] vmemData,
	// Outputs
	output spikeBuffer,
	output [(size_tile*size_vmem-1):0] vmemOut,
	output [(size_vmem-1):0] weightSum, // Test
	output [1:0] stateOut // Test
)