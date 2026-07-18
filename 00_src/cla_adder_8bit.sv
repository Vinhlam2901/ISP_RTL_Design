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
	input  logic        cin_i,
	output logic        cout_o,
	output logic [7:0] result_o 
);
//===============DECLARATION=====================================================================================
  logic [1:0] prog_temp, gen_ntemp;
	logic [1:0] cin_out;
	logic       p_o, g_no;
//===============RESUTL_PROCESS==========================================================================================
	cla_adder_4bit cla_0 (.a_i(a_i[3:0]  ),.b_i(b_i[3:0]  ),.cin_i(cin_i     ),.prog_o(prog_temp[0]),.gen_no(gen_ntemp[0]),.s_o(result_o[3:0] ));
	cla_adder_4bit cla_1 (.a_i(a_i[7:4]  ),.b_i(b_i[7:4]  ),.cin_i(cin_out[0]),.prog_o(prog_temp[1]),.gen_no(gen_ntemp[1]),.s_o(result_o[7:4] ));
//===============CARRY_PROCESS==========================================================================================
	cla_carry_unit_2bit carry_process (.p_i(prog_temp),.g_ni(gen_ntemp),.cin_i(cin_i),.cin_out(cin_out),.p_o(p_o),.g_no(g_no));
	always_comb begin : carry_out
		cout_o = cin_out[1];
	end
endmodule