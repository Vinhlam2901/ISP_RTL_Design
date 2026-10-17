//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Carry Lookahead Adder 21bit 
// File            : cla_adder_21bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 14/09/2026
//============================================================================================================
module cla_adder_21bit (
  input  logic [20:0] a_i,
  input  logic [20:0] b_i,
  input  logic        cin_i,
  output logic        cout_o,
  output logic [20:0] result_o 
);
//===============DECLARATION=====================================================================================
  logic [4:0] cin_out;        // C1, C2, C3, C4 (chính là C4, C8, C12, C16) từ Carry Unit
  logic       cin_20; // Carry đi vào khối 5 và đi vào bit MSB (bit 20)
  logic       p_msb, g_msb;   // Propagate và Generate cho riêng bit thứ 21 (MSB)

//===============RESULT_PROCESS (20-bit thấp chia thành 5 khối 4-bit) ===========================================
  cla_adder_4bit cla_0 (.a_i(a_i[3:0]),   .b_i(b_i[3:0]),   .cin_i(cin_i),     .cout_o(cin_out[0]), .result_o(result_o[3:0])); 
  cla_adder_4bit cla_1 (.a_i(a_i[7:4]),   .b_i(b_i[7:4]),   .cin_i(cin_out[0]),.cout_o(cin_out[1]), .result_o(result_o[7:4]));
  cla_adder_4bit cla_2 (.a_i(a_i[11:8]),  .b_i(b_i[11:8]),  .cin_i(cin_out[1]),.cout_o(cin_out[2]), .result_o(result_o[11:8]));
  cla_adder_4bit cla_3 (.a_i(a_i[15:12]), .b_i(b_i[15:12]), .cin_i(cin_out[2]),.cout_o(cin_out[3]), .result_o(result_o[15:12]));
  cla_adder_4bit cla_4 (.a_i(a_i[19:16]), .b_i(b_i[19:16]), .cin_i(cin_out[3]),.cout_o(cin_out[4]), .result_o(result_o[19:16]));
//===============MSB & EXTENDED LOOK-AHEAD PROCESS ==============================================================
  always_comb begin : extended_look_ahead_logic
    cin_20       = cin_out[4];
    p_msb        = a_i[20] ^ b_i[20];
    g_msb        = a_i[20] & b_i[20];
    result_o[20] = p_msb ^ cin_20;
    cout_o       = g_msb | (p_msb & cin_20);
  end
endmodule