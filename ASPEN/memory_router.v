module memory_router
#(
	parameter size_address = 4,
	parameter size_weight = 8,
	parameter size


)


module neuron_tile 
#(
	size_data = 8, size_vmem = 16,
	size_counters = 5, size_tile = 4
)
(
	clk, 
	reset, enable, memReady, finished,
	// Data Inputs
	input [(size_tile*size_data-1):0] weightData,
	input [(size_tile*size_vmem-1):0] vmemData,
	// Outputs
	output spikeBuffer,
	output [(size_tile*size_vmem-1):0] vmemOut,
	output [(size_vmem-1):0] weightSum, // Test
	output [1:0] stateOut // Test
)