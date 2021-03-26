module skew_offset_add_signed
#(parameter size_input = 8,
  parameter size_output = 16,
  parameter size_code = 5)
(
  input [(size_input*size_code-1):0] offset,
  input [(size_output-1):0] numin,
  output reg [(size_output-1):0] out
);
	// Skew the offset code to be significance alligned
	parameter size_skew = size_input+size_code-1;
	
	reg [size_skew*size_code-1:0] skewed_offset;
	//reg [size_code-1:0] signed_offset_msb;
	reg msbSign;
	integer i,j;
	always @*
	begin
		for (i = 0; i < size_input; i = i + 1)
		begin
			for (j = 0; j < size_code; j = j + 1)
			begin
				skewed_offset[j*size_skew + i + j] <= offset[i*size_code+j];
			end
		end
		// Get sign of MSB counters
		msbSign <= |offset[(size_input-1)*size_code +: size_code];
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
	end

	parameter size_block = 2;
	parameter num_block = 6;
	parameter size_partition = 4;
	parameter num_partition = 3;
	reg [(size_output-1):0] add0;
	reg [(size_output-1):0] add1;
	reg [size_partition-1:0] acc0;
	reg [size_partition-1:0] acc1;
	reg [size_partition-1:0] acc2;
	reg [size_partition-1:0] acc3;
	reg [size_partition-1:0] acc4;
	reg [size_partition-1:0] acc5;
	
	always@*
	begin
		add1[0 +: size_block] = 0;
		// Initialize Sub-Sums
		acc0 = 0;
		acc1 = 0;
		acc2 = 0;
		acc3 = 0;
		acc4 = 0;
		acc5 = 0;
		// Add up the sub-sums
		for (j = 0; j < size_code; j = j + 1)
		begin
			acc0 = acc0 + skewed_offset[j*size_skew+0*size_block +: 2];
			acc1 = acc1 + skewed_offset[j*size_skew+1*size_block +: 2];
			acc2 = acc2 + skewed_offset[j*size_skew+2*size_block +: 2];
			acc3 = acc3 + skewed_offset[j*size_skew+3*size_block +: 2];
			acc4 = acc4 + skewed_offset[j*size_skew+4*size_block +: 2];
			acc5 = acc5 + skewed_offset[j*size_skew+5*size_block +: 2];
		end
		// Place sub-sums in partitions
		add0[(0/2)*size_partition +: size_partition] = acc0;
		add1[((1-1)/2)*size_partition+size_block +: size_partition] = acc1;
		add0[(2/2)*size_partition +: size_partition] = acc2;
		add1[((3-1)/2)*size_partition+size_block +: size_partition] = acc3;
		add0[(4/2)*size_partition +: size_partition] = acc4;
		add1[((5-1)/2)*size_partition+size_block +: size_partition] = acc5;
		for (i = 0; i < size_block; i = i + 1)
		begin
			add0[size_partition*num_partition+i] = msbSign;
		end
		for (i = size_partition*num_partition+size_block; i < size_output; i = i + 1)
		begin
			add0[i] = msbSign;
			add1[i] = 0;
		end
	end
	
	wire [(size_output-1):0] sum, carry;
	genvar k;
	generate
		HAX1 h0 (.A(add0[0]), .B(numin[0]), .YS(sum[0]), .YC(carry[0]));
		HAX1 h1 (.A(add0[1]), .B(numin[1]), .YS(sum[1]), .YC(carry[1]));
		for (k = 2; k < (size_output-2); k = k + 1)
		begin
			FAX1 fk (.A(add0[k]), .B(add1[k]), .C(numin[k]), .YS(sum[k]), .YC(carry[k]));
		end	
		HAX1 h2 (.A(add0[size_output-2]), .B(numin[size_output-2]), .YS(sum[size_output-2]), .YC(carry[size_output-2]));
		HAX1 h3 (.A(add0[size_output-1]), .B(numin[size_output-1]), .YS(sum[size_output-1]), .YC(carry[size_output-1]));
	endgenerate
	
	wire [(size_output-1):0] res;
	reg [(size_output-1):0] carry_shift;
	always @*
	begin
		carry_shift = carry << 1;
		out = sum + carry_shift; 
	end
	
	//add2x16_approx aapx0 (.A(sum), .B(carry_shift), .O(out));
	//always @(posedge clk)
		//out <= res;
	
endmodule 
	