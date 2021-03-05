`timescale 1ns/10ps
module tb_neuron_tile;

parameter size_data = 8;
parameter size_vmem = 16;
parameter num_input = 31;
parameter size_tile = 4;
parameter size_counters = $clog2(num_input);
parameter size_weightData = size_data;
parameter size_control = 4;

// Clock
reg clk;
// Inputs
reg [(size_control-1):0] msgControl;
reg [(size_data*size_tile-1):0] msgData;
reg [(size_vmem*size_tile-1):0] msgVmem;
// Outputs
wire SpikeBuffer;
wire signed [(size_tile*size_vmem-1):0] vmemOut;
// Testing
reg [(size_vmem*size_tile-1):0] test_vmem;
reg [2:0] test_state;

neuron_tile nt0 #(size_control, size_data, size_vmem, num_counters, size_tile = 4)
(	.clk(clk), 
	.msgControl(msgControl), .msgData(msgData), .msgVmem(msgVmem),
	.spikeBuffer(SpikeBuffer), .vmemOut(vmemOut),
	.test_vmem(test_vmem), .test_state(test_state));
	
parameter control_reset = 4'b0001;
parameter control_memSetup = 4'b0010;
parameter control_memData = 4'b0110;
parameter control_memStop = 4'b0000;
parameter control_finished = 4'b1000;	
reg memReady;

integer data_file ; // file handler
integer scan_file ; // file handler
reg fileDone;
reg signed [size_weightData-1:0] captured_data;
initial
begin
	data_file = $fopen("fp_neuron_100_8.8.txt", "r");
	fileDone = 0;
	// Initial Control Parameters
	clk = 1;
	memReady = 0;
	// Initial Messages
	msgControl = control_reset;
	msgData = 0;
	msgVmem = 0;
	// Setup
	#11 msgControl = control_memSetup;
	// 
	#10 msgControl = control_memData
	#10 memReady = 1
	// Add up weights
	#1000
	msgControl = control_finished;
	#30
	$finish;
end 

always @(*)
begin
	#5
	clk <= !clk;
end

wire [(size_data-1):0] data0, data1, data2, data3;
assign data0 = msgData[0 +: size_data];
assign data0 = msgData[size_data +: size_data];
assign data0 = msgData[2*size_data +: size_data];
assign data0 = msgData[3*size_data +: size_data];

always @(negedge clk)
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

endmodule