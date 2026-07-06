//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : CLA 1 bit
// File            : cla_adder.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 17/06/2026
// Updated date    : 17/06/2026
//============================================================================================================
module cla_adder (
	input  wire a_i,
	input  wire b_i,
	input  wire cin_i,
	output reg  prog_o,
	output reg  gen_no,
	output reg  s_o
);
	always_comb begin : carry_dectect
		prog_o = a_i ^ b_i;								// if a or b is 1 --> can be generate carry
		gen_no = ~(a_i & b_i);								// if a and b is 1 --> must be generate carry
		// cout_o = gen_o | prog_o & cin_i;	there are 2 case for genrate carry. 1st is both a and b is 1, 2nd is a or b is 1 and have cin
	end
	
	always_comb begin : result_adder
		s_o    = prog_o ^ cin_i;			  	// normally result of adder
	end
endmodule