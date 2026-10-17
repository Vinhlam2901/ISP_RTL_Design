//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Carry Looking Ahead 32bit 
// File            : cla_adder_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 20/06/2026
// Updated date    : 20/06/2026
//============================================================================================================
module cla_adder_16bit (
	input  logic [15:0] a_i,
	input  logic [15:0] b_i,
	input  logic        cin_i,
	output logic        cout_o,
	output logic [15:0] result_o 
);
//===============DECLARATION=====================================================================================
  logic [3:0] prog_temp, gen_ntemp;
	logic [3:0] cin_out;
	logic       p_o, g_no;
//===============RESUTL_PROCESS==========================================================================================
	cla_adder_4bit cla_0 (.a_i(a_i[3:0]  ),.b_i(b_i[3:0]  ),.cin_i(cin_i     ),.cout_o(cin_out[0]),.result_o(result_o[3:0] ));
	cla_adder_4bit cla_1 (.a_i(a_i[7:4]  ),.b_i(b_i[7:4]  ),.cin_i(cin_out[0]),.cout_o(cin_out[1]),.result_o(result_o[7:4] ));
	cla_adder_4bit cla_2 (.a_i(a_i[11:8] ),.b_i(b_i[11:8] ),.cin_i(cin_out[1]),.cout_o(cin_out[2]),.result_o(result_o[11:8]));
	cla_adder_4bit cla_3 (.a_i(a_i[15:12]),.b_i(b_i[15:12]),.cin_i(cin_out[2]),.cout_o(cin_out[3]),.result_o(result_o[15:12]));
	always_comb begin : carry_out
		cout_o = cin_out[3];
	end
endmodule