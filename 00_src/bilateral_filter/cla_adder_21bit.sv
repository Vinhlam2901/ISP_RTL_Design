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
  logic [4:0] prog_temp, gen_ntemp; // Lưu P, G từ 5 khối 4-bit (Bit 0 -> 19)
  logic [2:0] cin_out;              // Carry C1, C2, C3 sinh ra từ Carry Unit cho cla_1, cla_2, cla_3
  logic       p_group, g_group;     // Group Propagate và Generate của toàn bộ 16 bit đầu
  logic       cin_16, cin_20;       // Carry Look-ahead tính tay cho Khối 5 và Bit MSB
  logic       p_msb, g_msb;         // Propagate và Generate cho riêng bit thứ 21 (MSB)
//===============RESULT_PROCESS (20-bit thấp chia thành 5 khối 4-bit) ===========================================
  cla_adder_4bit cla_0 (.a_i(a_i[3:0]),  .b_i(b_i[3:0]),  .cin_i(cin_i),     .prog_o(prog_temp[0]),.gen_no(gen_ntemp[0]),.s_o(result_o[3:0])); 
  cla_adder_4bit cla_1 (.a_i(a_i[7:4]),  .b_i(b_i[7:4]),  .cin_i(cin_out[0]),.prog_o(prog_temp[1]),.gen_no(gen_ntemp[1]),.s_o(result_o[7:4]));
  cla_adder_4bit cla_2 (.a_i(a_i[11:8]), .b_i(b_i[11:8]), .cin_i(cin_out[1]),.prog_o(prog_temp[2]),.gen_no(gen_ntemp[2]),.s_o(result_o[11:8]));
  cla_adder_4bit cla_3 (.a_i(a_i[15:12]),.b_i(b_i[15:12]),.cin_i(cin_out[2]),.prog_o(prog_temp[3]),.gen_no(gen_ntemp[3]),.s_o(result_o[15:12]));
  cla_adder_4bit cla_4 (.a_i(a_i[19:16]),.b_i(b_i[19:16]),.cin_i(cin_16),    .prog_o(prog_temp[4]),.gen_no(gen_ntemp[4]),.s_o(result_o[19:16]));
//===============CARRY_PROCESS (Look-Ahead cho 16 bit đầu) ======================================================
  cla_carry_unit_4bit carry_process_16 (
    .p_i(prog_temp[3:0]),
    .g_ni(gen_ntemp[3:0]),
    .cin_i(cin_i),
    .cin_out(cin_out),
    .p_o(p_group), 
    .g_no(g_group)
  );
//===============MSB & EXTENDED LOOK-AHEAD PROCESS ==============================================================
  always_comb begin : extended_look_ahead_logic
    cin_16 = g_group | (p_group & cin_i);
    cin_20 = gen_ntemp[4] | (prog_temp[4] & cin_16);
    p_msb = a_i[20] ^ b_i[20];
    g_msb = a_i[20] & b_i[20];
    result_o[20] = p_msb ^ cin_20;
    cout_o = g_msb | (p_msb & cin_20);
  end

endmodule