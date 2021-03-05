`timescale 1ns/10ps
module tb_full_neuron_PIF;

parameter INTEGER_WIDTH = 16;
parameter DATA_WIDTH_FRAC = 0;
parameter DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC;

reg clk, reset, enable;
reg [DATA_WIDTH-1:0] threshold, weightData;
reg [7:0] weightRand;
wire SpikeBuffer;
wire [DATA_WIDTH-1:0] vmemOut, weightSum;

full_neuron_PIF #(INTEGER_WIDTH,DATA_WIDTH_FRAC,DATA_WIDTH,num_input) np0 (
	.clk(clk), .reset(reset), .updateEnable(enable),
	.threshold(threshold), .weightData(weightData),
	.spikeBuffer(spikeBuffer), .weight(weightSum), .vmemOut(vmemOut));

reg memEnable;
initial
begin
	// Initial Control Parameters
	clk = 0;
	reset = 0;
	enable = 0;
	memEnable = 0;
	// Initial Neuron Parameters
	threshold = 1000;
	weightData = 0;
	#10
	reset = 1;
	memEnable = 1;
	// Add up weights
	#100
	enable = 1;
	memEnable = 0;
	#10
	enable = 0;
	memEnable = 0;
	#10
	reset = 0;
	#10
	reset = 1;
	memEnable = 1;
	#100
	enable = 1;
	memEnable = 0;
	#10
	enable = 0;
	memEnable = 0;
	// Update neuron
	#10 $finish;
end

always @(*)
begin
	#5
	clk <= !clk;
end

always @(negedge clk)
begin
	$display("*****");
	$display("Weight Data: %d", weightData);
	$display("Weight Sum: %d", weightSum);
	$display("Spike: %b", spikeBuffer);
	if (memEnable == 1)
	begin
		weightRand = $random;
		weightData = {8'b0, weightRand};
	end
	else
		weightData = 0;
end

endmodule