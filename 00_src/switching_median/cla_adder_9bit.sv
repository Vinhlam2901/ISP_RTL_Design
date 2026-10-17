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
	logic c_inter; 
	logic cout_8; 
	logic g_msb, p_msb; 
//===============RESULT_PROCESS (8-bit thấp) ====================================================================
  cla_adder_8bit adder (
    .a_i(a_i[7:0]),
    .b_i(b_i[7:0]),
    .cin_i(cin_i),
    .cout_o(cout_8),
    .result_o(result_o[7:0])
  );
//===============BIT 9 (MSB) PROCESS=============================================================================
  always_comb begin : msb_logic
    p_msb = a_i[8] ^ b_i[8];
    g_msb = (a_i[8] & b_i[8]);
    result_o[8] = p_msb ^ cout_8;
    cout_o = g_msb | (p_msb & cout_8);
  end
endmodule