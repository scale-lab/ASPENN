module full_neuron_PIF_signed
#(
	parameter INTEGER_WIDTH = 8,
	parameter FRACTION_WIDTH = 8,
	parameter DATA_WIDTH = INTEGER_WIDTH + FRACTION_WIDTH,
	parameter size_code = 5
 )

 (
	// Clock Signal
	input clk, 
	// Control Signals
	input reset, enable, finished,
	output reg readyMem,
	// Data Inputs
	input [(DATA_WIDTH-1):0] vmemIn,
	input [(FRACTION_WIDTH-1):0] weightData,
	// Outputs
	output spikeBuffer,
	output [(DATA_WIDTH-1):0] vmemOut
	// Test Declarations
	//output [(DATA_WIDTH-1):0] weightSum, // Test
	//output [2:0] stateOut // Test
 );
	// State Variable Declaration
	reg [2:0] state, next_state;
	// Test Declarations
	reg [2:0] stateOut;
	reg [(DATA_WIDTH-1):0] weightSum
	parameter st_reset = 0, st_inBlock = 1, st_blockDone = 2, st_blockReset = 3, st_finished = 4;
	// Control Signal Declaration
	reg neurReset, neurEnable, weightReset, firstBlock, next_firstBlock;
	wire [(DATA_WIDTH-1):0] numin, partImpulse;
	reg [(DATA_WIDTH-1):0] impulse;
	
	assign numin = firstBlock ? vmemIn : impulse;
	add_skewed_offset_OAAT_signed #(size_code, FRACTION_WIDTH, DATA_WIDTH) aoff0 (
		.clk(clk), .reset(weightReset), 
		.weightIn(weightData), .numin(numin), 
		.out(partImpulse));
		
	assign weightSum = partImpulse;
	assign stateOut = state;
	
	always @(posedge clk)
	begin
		if (state == st_blockDone)
			impulse <= partImpulse;
		else
			impulse <= impulse;
	end
	
	neuron_PIF #(INTEGER_WIDTH, FRACTION_WIDTH, DATA_WIDTH, size_code) pif0 (
		.clk(clk), .reset(neurReset), .update(neurEnable), 
		.impulse(impulse), 
		.vmemOut(vmemOut), .spikeBuffer(spikeBuffer));

	// State Machine
	// State transition logic
	
	// Check if the maximum number of weights has been reached
	wire [(size_code-1):0] count;
	wire blockDone;
	counters #(size_code) c0 (clk, weightReset, 1'b1, count);
	assign blockDone = &count[1 +: (size_code-1)];
	
	always @(*)
	 begin
		if (~reset)
			next_state <= st_reset;
		else
		begin
			case (state)
				st_reset:
				begin
					next_state <= st_inBlock;
					next_firstBlock <= 1;
				end
				st_inBlock:
				begin
					if (finished || (blockDone))
						next_state <= st_blockDone;
					else
						next_state <= st_inBlock;
					next_firstBlock <= firstBlock;
				end
				st_blockDone:
				begin
					next_state <= st_blockReset;
					next_firstBlock <= 0;
				end
				st_blockReset:
				begin
					if (finished)
						next_state <= st_finished;
					else
						next_state <= st_inBlock;
					next_firstBlock <= 0;
				end
				st_finished:
				begin
					if (finished)
						next_state <= st_finished;
					else
						next_state <= st_reset;
					next_firstBlock <= 0;
				end
			endcase
		end
	 end
	 // State Update
	always @(posedge clk)
	begin
		state <= next_state;
		firstBlock = next_firstBlock;
	end
	
	// Signal Controller
	always@(*)
	begin
		case (state)
			st_reset:
			begin
				neurReset <= 0;
				neurEnable <= 0;
				weightReset <= 0;
				readyMem <= 0;
			end
			st_inBlock:
			begin
				neurReset <= 1;
				neurEnable <= 0;
				weightReset <= 1;
				readyMem <= 1;
			end
			st_blockDone:
			begin
				neurReset <= 1;
				neurEnable <= 0;
				weightReset <= 1;
				readyMem <= 0;
			end
			st_blockReset:
			begin
				neurReset <= 1;
				neurEnable <= 0;
				weightReset <= 0;
				readyMem <= 0;
			end
			st_finished:
			begin
				neurReset <= 1;
				neurEnable <= 1;
				weightReset <= 0;
				readyMem <= 0;
			end
		endcase
	end

endmodule