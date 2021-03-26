module snn_top
#(	
	// Network Parameters
	parameter num_layers = 4,
	parameter size_max_layer = 1024, 
	parameter num_timesteps = 10,
	// Neuron Parameters
	parameter num_counters = 5, 
	parameter size_tile = 4, 
	parameter size_matrix = 8,
	parameter size_spike_max = 512,
	// Data Parameters
	parameter size_data = 8, 
	parameter size_vmem = 16, 
	parameter size_spike = 10,
	// Address Parameters
	parameter size_addr_data_cache = 10,
	parameter size_addr_mem = 4,
	parameter size_addr_spike_cache = 8,
	parameter size_index_layer = $clog2(num_layers),
	parameter size_index_page = $clog2(size_max_layer/(size_matrix*size_tile)),
	parameter size_index_time = $clog2(num_timesteps)
)(
	// Inputs
	//  Clock 
	input clk,
	//  Control Signals
	input reset, memReady,
	// Data Cache
	input [(size_data*size_tile-1):0] in_data_cache,
	input [(size_index_page-1):0] in_page_limit,
	input [(size_addr_data_cache-1):0] size_spiking_layer,
	output reg sig_load_data_cache,
	output reg [(size_index_layer-1):0] addr_layer,
	output reg [(size_index_page-1):0] addr_page,
	output reg [(size_addr_data_cache-1):0] addr_data_cache,
	// Spike Cache
	input [(size_spike-1):0] in_spike_cache,
	input [(size_spike-1):0] in_spike_limit,
	output reg sig_load_spike_cache,
	output reg [(size_index_time-1):0] addr_time,
	output reg [(size_addr_spike_cache-1):0] addr_spike_cache,
	// Spike Mem
	output reg sig_load_spike_mem,
	output reg [(size_spike*size_tile-1):0] out_spike_mem,
	
	output [($clog2(size_matrix)-1):0] test
);

parameter size_addr_matrix = $clog2(size_matrix);
parameter size_index_spike = $clog2(size_spike_max);
parameter size_matrix_neurons = size_matrix*size_tile;

// Neuron Matrix
reg nm_reset, nm_enable, nm_block_done, nm_update;
reg [(size_data*size_tile-1):0]nm_weight;
reg [(size_addr_matrix-1):0] nm_addr;
wire nm_spikeValid;
wire [(size_tile-1):0] nm_spike;
wire [(size_addr_matrix-1):0] nm_spikeAddress;

neuron_matrix
#(size_data, size_vmem, num_counters, size_tile, size_matrix, size_addr_matrix) nm (
	.clk(clk),
	.reset(nm_reset), .enable(nm_enable), .block_done(nm_block_done), .update(nm_update),
	.in_weight(nm_weight), .in_addr(nm_addr),
	.out_spikeValid(nm_spikeValid), .out_spike(nm_spike), .out_spikeAddress(nm_spikeAddress)
);
assign test = nm_spikeAddress;

// Memory Control
// Index Dimensions
parameter size_index_tile = $clog2(size_matrix);
// Index Maximums
parameter max_index_layer = num_layers-2;
parameter max_index_time = num_timesteps-1;
parameter max_index_tile = size_matrix-1;

wire [(size_index_page-1):0] max_index_page;
assign max_index_page = in_page_limit;
wire [(size_spike-1):0] max_index_spike;
assign max_index_spike = in_spike_limit;

// Index Declarations
reg [(size_index_layer-1):0] index_layer, next_index_layer;
reg [(size_index_page-1):0] index_page, next_index_page;
reg [(size_index_time-1):0] index_time, next_index_time;
reg [(size_index_spike-1):0] index_spike, next_index_spike;
reg [(size_index_tile-1):0] index_tile, next_index_tile;

// State declarations
reg [2:0] state, next_state;
parameter st_reset=0, st_loadSpikes=1, st_loadData=2, st_readSpike=3, st_readData=4, st_addData=5, st_writeSpike=6;

// Control Logic
// Data Cache
always @(posedge clk)
begin
	case (state)
		st_loadData: sig_load_data_cache <= 1;
		default: sig_load_data_cache <= 0;
	endcase
	addr_layer <= index_layer;
	addr_page <= index_page;
	addr_data_cache <= index_tile*size_spiking_layer + in_spike_cache;
end

// Spike Cache
always @(posedge clk)
begin
	case (state)
		st_loadSpikes: sig_load_spike_cache <= 1;
		default: sig_load_spike_cache <= 0;
	endcase
	addr_time <= index_time;
	addr_spike_cache <= index_time*size_spike_max + index_spike;
end


// Block Counter
reg bc_reset, bc_enable;
wire [(num_counters-1):0] block_counter;

always @*
begin
	case (state)
		st_readSpike: begin
			bc_reset <= 1;
			bc_enable <= 1;
		end
		default: begin
			bc_reset <= 0;
			bc_enable <= 0;
		end
	endcase
end
counters #(num_counters) bcount (clk, bc_reset, bc_enable, bc_enable, block_counter);

// Neuron Matrix Control
always @*
begin
	case (state)
		st_loadData: nm_reset <= 0;
		default: nm_reset <= 1;
	endcase
	
	case (state)
		st_addData: nm_enable <= 1;
		default: nm_enable <= 0;
	endcase
	
	nm_block_done <= !(|block_counter);
	
	if (index_spike == in_spike_limit) nm_update <= 1;
	else nm_update <= 0;
	
	case (state)
		st_addData: nm_weight <= in_data_cache;
		default: nm_weight <= 0;
	endcase
	
	nm_addr <= index_tile;
end

reg sig_load_spike_mem_reg;
reg [(size_spike*size_tile-1):0] out_spike_mem_reg;
// Spike Buffer
integer i;
always @(*)
begin
	if (nm_spikeValid == 1) begin
		sig_load_spike_mem_reg <= 1;
		for (i = 0; i < size_tile; i=i+1)
		begin
			if (nm_spike[i]) begin
				out_spike_mem_reg[i*size_spike +: size_spike] <= index_page*size_matrix_neurons + nm_spikeAddress*size_tile + i;
			end else begin
				out_spike_mem_reg[i*size_spike +: size_spike] <= 0;
			end
		end
	end else begin
		sig_load_spike_mem_reg <= 0;
		out_spike_mem_reg <= 0;
	end
end

always @(posedge clk)
begin
	sig_load_spike_mem <= sig_load_spike_mem_reg;
	out_spike_mem <= out_spike_mem_reg;
end

// Next State Logic
always @*
begin
	if (~reset) begin
		next_state <= st_reset;
		next_index_layer <= 0;
		next_index_page <= 0;
		next_index_time <= 0;
		next_index_spike <= 0;
		next_index_tile <= 0;
	end else begin
		case (state)
		st_reset: begin
			next_state <= st_reset;
			next_index_layer <= 0;
			next_index_page <= 0;
			next_index_time <= 0;
			next_index_spike <= 0;
			next_index_tile <= 0;
		end
		st_loadSpikes: begin
			if (memReady) begin
				next_state <= st_loadData;
				next_index_page <= 0;
			end else begin
				next_state <= st_loadSpikes;
				next_index_page <= next_index_page;
			end
			next_index_layer <= next_index_layer;
			next_index_time <= next_index_time;
			next_index_spike <= next_index_spike;
			next_index_tile <= next_index_tile;
		end
		st_loadData: begin
			if (memReady) begin
				next_state <= st_readSpike;
				next_index_time <= 0;
				next_index_spike <= 0;
			end else begin
				next_state <= st_loadData;
				next_index_time <= next_index_time;
				next_index_spike <= next_index_spike;
			end
			next_index_layer <= next_index_layer;
			next_index_page <= next_index_page;
			next_index_tile <= next_index_tile;
		end
		st_readSpike: begin
			next_state <= st_readData;
			next_index_layer <= next_index_layer;
			next_index_page <= next_index_page;
			next_index_time <= next_index_time;
			next_index_spike <= next_index_spike;
			next_index_tile <= 0;
		end
		st_readData: begin
			next_state <= st_addData;
			next_index_layer <= next_index_layer;
			next_index_page <= next_index_page;
			next_index_time <= next_index_time;
			next_index_spike <= next_index_spike;
			next_index_tile <= next_index_tile;
		end
		st_addData: begin
			if (index_tile != max_index_tile) begin
				next_state <= st_readData;
				next_index_tile <= next_index_tile + 1;
				next_index_spike <= next_index_spike;
			end else begin
				if (index_spike != max_index_spike) begin
					next_state <= st_readSpike;
					next_index_tile <= next_index_tile;
					next_index_spike <= next_index_spike + 1;
				end else begin
					next_state <= st_writeSpike;
					next_index_tile <= next_index_tile;
					next_index_spike <= next_index_spike;
				end
			end
			next_index_layer <= next_index_layer;
			next_index_page <= next_index_page;
			next_index_time <= next_index_time;
		end
		st_writeSpike: begin
			if (index_time != max_index_time) begin
				next_state <= st_readSpike;
				next_index_layer <= next_index_layer;
				next_index_page <= next_index_page;
				next_index_time <= next_index_time+1;
				next_index_spike <= 0;
			end else begin
				if (index_page != max_index_page) begin
					next_state <= st_loadData;
					next_index_layer <= next_index_layer;
					next_index_page <= next_index_page+1;
					next_index_time <= next_index_time;
					next_index_spike <= next_index_spike;
				end else begin
					next_state <= st_loadSpikes;
					next_index_layer <= next_index_layer+1;
					next_index_page <= next_index_page;
					next_index_time <= next_index_time;
					next_index_spike <= next_index_spike;
				end
			end
			next_index_tile <= next_index_tile;
		end
		default:  begin
			next_state <= st_reset;
			next_index_layer <= next_index_layer;
			next_index_page <= next_index_page;
			next_index_time <= next_index_time;
			next_index_spike <= next_index_spike;
			next_index_tile <= next_index_tile;
		end
		endcase
	
	end
end

// Update State Variables and Indices
always @(posedge clk)
begin
	state <= next_state;
	index_layer <= next_index_layer;
	index_page <= next_index_page;
	index_time <= next_index_time;
	index_spike <= next_index_spike;
	index_tile <= next_index_tile;
end

endmodule
