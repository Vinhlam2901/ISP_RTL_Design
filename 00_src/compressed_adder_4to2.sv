module compressed_adder_4to2 (
	input  wire x1_i, x2_i, x3_i, x4_i,
	input  wire cin_i,
	output reg  sum_o,
	output reg  carry_o,
	output reg  cout_o
);
	wire s_temp;
	assign s_temp   = x1_i ^ x2_i ^ x3_i;
	assign cout_o   = (x1_i & x2_i) | (x2_i & x3_i) | (x1_i & x3_i);
	assign sum_o    = s_temp ^ x4_i ^ cin_i;
	assign carry_o  = (s_temp & x4_i) | (x4_i & cin_i) | (s_temp & cin_i);

endmodule