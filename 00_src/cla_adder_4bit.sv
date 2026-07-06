//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : CLA 4 bit
// File            : cla_adder_4bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 17/06/2026
// Updated date    : 17/06/2026
//============================================================================================================
module cla_adder_4bit (
	input  wire [3:0] a_i,
	input  wire [3:0] b_i,
	input  wire       cin_i,
	output reg        prog_o,
	output reg        gen_no,
	output reg  [3:0] s_o
);
//==================DECLARATION=============================================================================
	wire [3:0] prog_temp, gen_temp;
	wire [2:0] cin_temp;
//==================CARRY=============================================================================
	// c[1] = g[0] + p[0]cin = ~g.~(p+c)
	assign cin_temp[0] = ~(gen_temp[0] & ~(prog_temp[0] & cin_i));
	// c[2] = g[1] + p[1]c[1] = ~(~g[1] & ~(p[1]g[0]) & ~(p[1]p[0]cin))
	assign cin_temp[1] = ~(gen_temp[1] & ~(prog_temp[1] & ~gen_temp[0])  & ~(prog_temp[1] & prog_temp[0] & cin_i));
	// c[3] = g[2] + p[2]c[2] = g[2] + p[2]g[1] + p[2]p[1]g[0] + p[2]p[1]p[0]cin
	assign cin_temp[2] = ~(gen_temp[2] & ~(prog_temp[2] & ~gen_temp[1])  & ~(prog_temp[2] & prog_temp[1] & ~gen_temp[0]) 
																	    & ~(prog_temp[2] & prog_temp[1] & prog_temp[0] & cin_i));
	always_comb begin : carry_out
		// carry generate when there is 1st: generate carry in cla_3, generate carry in cla_2 and propagate to cla_2, and so on
		gen_no = gen_temp[3] & ~(prog_temp[3] & ~gen_temp[2]) & ~(prog_temp[3] & prog_temp[2] & ~gen_temp[1])
					               & ~(prog_temp[3] & prog_temp[2] &   prog_temp[1] & ~gen_temp[0]);
		prog_o = &prog_temp;
	end
//==================RESULT=============================================================================
	cla_adder cla_0 (
		.a_i   (a_i[0]),
		.b_i   (b_i[0]),
		.cin_i (cin_i),
		.prog_o(prog_temp[0]),
		.gen_no(gen_temp[0]),
		.s_o   (s_o[0])
	);
	cla_adder cla_1 (
		.a_i   (a_i[1]),
		.b_i   (b_i[1]),
		.cin_i (cin_temp[0]),
		.prog_o(prog_temp[1]),
		.gen_no(gen_temp[1]),
		.s_o   (s_o[1])
	);
	cla_adder cla_2 (
		.a_i   (a_i[2]),
		.b_i   (b_i[2]),
		.cin_i (cin_temp[1]),
		.prog_o(prog_temp[2]),
		.gen_no(gen_temp[2]),
		.s_o   (s_o[2])
	);
	cla_adder cla_3 (
		.a_i   (a_i[3]),
		.b_i   (b_i[3]),
		.cin_i (cin_temp[2]),
		.prog_o(prog_temp[3]),
		.gen_no(gen_temp[3]),
		.s_o   (s_o[3])
	);
endmodule