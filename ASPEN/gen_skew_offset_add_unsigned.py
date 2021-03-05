import argparse
import math
from queue import Queue
from numpy import binary_repr
import random


def gen_skew_offset_add_unsigned(size_input,size_code):
	verilog_code = []
	
	size_skew = size_input + size_code - 1
	size_block = math.ceil(math.log2(size_code-1))
	num_block = math.ceil(size_skew/size_block)
	size_partition = 2*size_block
	num_partition = math.ceil(num_block/2)

	# Module header and initial bit assignment
	verilog_code.append(
	f"""\
module skew_offset_add_unsigned
	(input clk,
	 input [{size_code*size_input-1}:0] offset,
	 output [{size_input+size_code-1}:0] out);
	// Skew the offset code to be significance alligned
	parameter size_input = {size_input};
	parameter size_code = {size_code};
	parameter size_skew = size_input+size_code-1;
	reg [size_skew*size_code-1:0] skewed_offset;
	integer i,j;
	always @*
	begin
		// Skewed offsets
		for (i = 0; i < size_input; i = i + 1)
		begin
			for (j = 0; j < size_code; j = j + 1)
			begin
				skewed_offset[j*size_skew + i + j] <= offset[i*size_code+j];
			end
		end
		// Fill in end bits with zeros
		for (i = 1; i < size_code; i = i + 1)
		begin
			for (j = 0; j < i; j = j + 1)
			begin
				// Right zero end
				skewed_offset[i*size_skew+j] <= 0;
				// Left zero end
				skewed_offset[(size_code-i-1)*size_skew+size_skew-j-1] <= 0;
			end
		end
	end""")
	
	
	
	verilog_code.append(
	f"""\
	parameter size_block = {size_block};
	parameter num_block = {num_block};
	parameter size_partition = {size_partition};
	parameter num_partition = {num_partition};""")
	
	if (num_block % 2) == 0:
		size_add0 = size_partition*num_partition-1
		size_add1 = size_partition*num_partition+size_block-1
	else:
		size_add0 = size_partition*num_partition-1
		size_add1 = size_partition*(num_partition-1)+size_block-1
		
	verilog_code.append(
	f"""\
	reg [{size_add0}:0] add0;
	reg [{size_add1}:0] add1;""")
	
	for ii in range(num_block):
		verilog_code.append(
	f"""\
	reg [size_partition-1:0] acc{ii};""")
	
	verilog_code.append(
	f"""\
	always@*
	begin
		add1[0 +: size_block] = 0;
		// Initialize Sub-Sums""")
		
	for ii in range(num_block):
		verilog_code.append(
		f"""\
		acc{ii} = 0;""")
		
	verilog_code.append(
	f"""\
		// Add up the sub-sums
		for (j = 0; j < size_code; j = j + 1)
		begin""")
	for ii in range(num_block):
		if ii == (num_block-1):
			real_size_block = size_skew-(num_block-1)*(size_block)
		else:
			real_size_block = size_block
		verilog_code.append(
		f"""\
			acc{ii} = acc{ii} + skewed_offset[j*size_skew+{ii}*size_block +: {real_size_block}];""")
	verilog_code.append(
	f"""\
		end
		// Place sub-sums in partitions""")
	for ii in range(num_block):
		if (ii%2) == 0:
			verilog_code.append(
			f"""\
		add0[({ii}/2)*size_partition +: size_partition] = acc{ii};""")
		else:
			verilog_code.append(
			f"""\
		add1[(({ii}-1)/2)*size_partition+size_block +: size_partition] = acc{ii};""")
	
	verilog_code.append(
	f"""\
	end
	assign out = add0 + add1;	
endmodule 
	""")
    
	with open("skew_offset_add_unsigned.v", "w") as outfile:
		outfile.write("\n".join(verilog_code))


def build_arg_parser():
	parser = argparse.ArgumentParser(description='Generates Verilog code for an unsigned skewed offset adder ')
	parser.add_argument("size_input", help="Specify the bitwidth of the operands")
	parser.add_argument("size_code", help="Specify the bit width of the operands")
	return parser


if __name__ == '__main__':
	args = build_arg_parser().parse_args()
	size_input = int(args.size_input)
	size_code = int(args.size_code)
	gen_skew_offset_add_unsigned(size_input,size_code)

