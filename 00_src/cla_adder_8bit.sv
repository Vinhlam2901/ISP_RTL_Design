//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Carry Looking Ahead 8bit 
// File            : cla_adder_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 20/06/2026
// Updated date    : 20/06/2026
//============================================================================================================
module cla_adder_8bit (
	input  logic [7:0] a_i,
	input  logic [7:0] b_i,
	input  logic       cin_i,
	output logic       cout_o,
	output logic [7:0] result_o 
);
//===============DECLARATION=====================================================================================
	logic c_inter; 
//===============RESUTL_PROCESS==================================================================================
	cla_adder_4bit cla_0 (
		.a_i     (a_i[3:0]),
		.b_i     (b_i[3:0]),
		.cin_i   (cin_i),
		.cout_o  (c_inter),
		.result_o(result_o[3:0])
	);
	cla_adder_4bit cla_1 (
		.a_i     (a_i[7:4]),
		.b_i     (b_i[7:4]),
		.cin_i   (c_inter),
		.cout_o  (cout_o),
		.result_o(result_o[7:4])
	);
endmodule