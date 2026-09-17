//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Carry Lookahead Adder 14bit 
// File            : cla_adder_14bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 15/09/2026
// Updated date    : 15/09/2026
//============================================================================================================
module cla_adder_14bit (
  input  logic [13:0] a_i,
  input  logic [13:0] b_i,
  input  logic        cin_i,
  output logic        cout_o,
  output logic [13:0] result_o 
);
  //===============DECLARATION=============================================
  logic cout_13;       // Carry out tràn ra từ bộ 13-bit
  logic p_13, g_13;    // Propagate và Generate cho riêng bit 13 (MSB)
  //===============LÕI 12-BIT==============================================
  // Gọi trực tiếp bộ 12-bit để giải quyết một lúc từ bit 0 đến bit 11
  cla_adder_13bit cla_13bit (
    .a_i      (a_i[12:0]),
    .b_i      (b_i[12:0]),
    .cin_i    (cin_i),
    .cout_o   (cout_13), 
    .result_o (result_o[12:0])
  );
  //===============MỞ RỘNG 1-BIT MSB (BIT THỨ 13)==========================
  always_comb begin : msb_logic
    p_13 = a_i[13] ^ b_i[13];
    g_13 = a_i[13] & b_i[13];
    result_o[13] = p_13 ^ cout_13; 
    cout_o = g_13 | (p_13 & cout_13);
  end

endmodule