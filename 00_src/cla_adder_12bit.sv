//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Carry Looking Ahead 32bit 
// File            : cla_adder_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 20/06/2026
// Updated date    : 20/06/2026
//============================================================================================================
module cla_adder_12bit (
	input  wire [11:0] a_i,
	input  wire [11:0] b_i,
	input  wire        cin_i,
	output reg         cout_o,
	output reg  [11:0] result_o 
);
//===============DECLARATION=====================================================================================
  wire [2:0] prog_temp, gen_ntemp;
	wire [2:0] cin_out;
	wire       p_o, g_no;
//===============RESUTL_PROCESS==========================================================================================
	cla_adder_4bit cla_0 (.a_i(a_i[3:0]  ),.b_i(b_i[3:0]  ),.cin_i(cin_i     ),.prog_o(prog_temp[0]),.gen_no(gen_ntemp[0]),.s_o(result_o[3:0] ));
	cla_adder_4bit cla_1 (.a_i(a_i[7:4]  ),.b_i(b_i[7:4]  ),.cin_i(cin_out[0]),.prog_o(prog_temp[1]),.gen_no(gen_ntemp[1]),.s_o(result_o[7:4] ));
	cla_adder_4bit cla_2 (.a_i(a_i[11:8] ),.b_i(b_i[11:8] ),.cin_i(cin_out[1]),.prog_o(prog_temp[2]),.gen_no(gen_ntemp[2]),.s_o(result_o[11:8]));
//===============CARRY_PROCESS==========================================================================================
	cla_carry_unit_3bit carry_process (.p_i(prog_temp),.g_ni(gen_ntemp),.cin_i(cin_i),.cin_out(cin_out),.p_o(p_o),.g_no(g_no));
	always_comb begin : carry_out
		cout_o = cin_out[2];
	end
endmodule