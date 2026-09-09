//===========================================================================================================
// Project         : Multiplier Acumulator / Switching Median
// Module          : Carry Look-Ahead 9-bit 
// File            : cla_adder_9bit.sv
// Author          : Chau Tran Vinh Lam
//============================================================================================================
module cla_adder_9bit (
  input  logic [8:0] a_i,
  input  logic [8:0] b_i,
  input  logic       cin_i,
  output logic       cout_o,
  output logic [8:0] result_o 
);
//===============DECLARATION=====================================================================================
  logic [1:0] prog_temp, gen_ntemp;
  logic [1:0] cin_out;
  logic       p_o, g_no;
  logic       p_msb, g_msb; // Propagate và Generate cho bit thứ 9
//===============RESULT_PROCESS (8-bit thấp) ====================================================================
  cla_adder_4bit cla_0 (.a_i(a_i[3:0]),.b_i(b_i[3:0]),.cin_i(cin_i),.prog_o(prog_temp[0]),.gen_no(gen_ntemp[0]),.s_o(result_o[3:0])); 
  cla_adder_4bit cla_1 (.a_i(a_i[7:4]),.b_i(b_i[7:4]),.cin_i(cin_out[0]),.prog_o(prog_temp[1]),.gen_no(gen_ntemp[1]),.s_o(result_o[7:4]));
//===============CARRY_PROCESS (8-bit thấp) =====================================================================
  cla_carry_unit_2bit carry_process (.p_i(prog_temp),.g_ni(gen_ntemp),.cin_i(cin_i),.cin_out(cin_out),.p_o(p_o),.g_no(g_no));
//===============BIT 9 (MSB) PROCESS=============================================================================
  always_comb begin : msb_logic
    p_msb = a_i[8] ^ b_i[8];
    g_msb = a_i[8] & b_i[8];
    result_o[8] = p_msb ^ cin_out[1];
    cout_o = g_msb | (p_msb & cin_out[1]);
  end
endmodule