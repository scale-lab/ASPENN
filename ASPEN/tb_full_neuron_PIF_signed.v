`timescale 1ns/10ps
module tb_full_neuron_PIF_signed;

parameter INTEGER_WIDTH = 8;
parameter DATA_WIDTH_FRAC = 8;
parameter DATA_WIDTH = INTEGER_WIDTH + DATA_WIDTH_FRAC;
parameter num_input = 31;
parameter size_code = $clog2(num_input);
parameter size_weightData = DATA_WIDTH_FRAC;

reg clk, reset, enable, finished;
reg signed [DATA_WIDTH-1:0] vmemIn;
reg signed [size_weightData-1:0] weightData;
wire SpikeBuffer, readyMem;
wire signed [DATA_WIDTH-1:0] vmemOut, weightSum;
wire [2:0] stateOut;
//wire signed [(DATA_WIDTH-1):0] testOut0, testOut1;

full_neuron_PIF_signed #(INTEGER_WIDTH,DATA_WIDTH_FRAC,DATA_WIDTH,size_code) np0 (
	.clk(clk), .reset(reset), .enable(enable), .finished(finished),
	.readyMem(readyMem),
	.vmemIn(vmemIn), .weightData(weightData),
	.spikeBuffer(spikeBuffer), .vmemOut(vmemOut), .weightSum(weightSum),
	.stateOut(stateOut)
	);

integer data_file ; // file handler
integer scan_file ; // file handler
reg fileDone;
reg signed [size_weightData-1:0] captured_data;
initial
begin
	data_file = $fopen("fp_neuron_100_8.8.txt", "r");
	//data_file = $fopen("fp_test.txt", "r");
	// Initial Control Parameters
	clk = 0;
	reset = 0;
	finished = 0;
	fileDone = 0;
	// Initial Neuron Parameters
	vmemIn = 0;
	weightData = 0;
	#10
	reset = 1;
	// Add up weights
	#1000
	finished = 1;
	#30
	$finish;
end 

always @(*)
begin
	#5
	clk <= !clk;
end

always @(negedge clk)
begin
	if (readyMem)
		scan_file = $fscanf(data_file, "%b\n", captured_data);
		
	if (!$feof(data_file)) begin
		if (readyMem)
			weightData = captured_data;
		else
			weightData = 0;
	end else begin
		if (finished == 0) begin
			$display("End of File");
			weightData = captured_data;
			finished = 1;
		end else begin
			weightData = 0;
		end
		
	end
	$display("*****");
	$display("State: %d", stateOut);
	$display("Weight Data: %d", weightData);
	$display("Weight Sum: %d", weightSum);
	$display("Vmem Out: %d", vmemOut);
	$display("Read Memory: %d", readyMem);
	$display("Finished: %d", finished);
	$display("Spike: %b", spikeBuffer);
end

endmodule