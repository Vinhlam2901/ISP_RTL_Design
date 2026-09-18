//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Carry Lookahead Adder 17bit 
// File            : cla_adder_17bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 14/09/2026
//============================================================================================================
module cla_adder_17bit (
  input  logic [16:0] a_i,
  input  logic [16:0] b_i,
  input  logic        cin_i,
  output logic        cout_o,
  output logic [16:0] result_o 
);
//===============DECLARATION=====================================================================================
  logic [3:0] prog_temp, gen_ntemp;    // 4 khối 4-bit (Bit 0 -> 15)
  logic [2:0] cin_out;                 // Chứa C4, C8, C12 từ Carry Unit
  logic       p_group_16, ng_group_16; // Trạng thái P/G tổng của toàn bộ 16 bit đầu
  logic       cin_16;                  // Carry Look-ahead tính tay cho bit MSB
  logic       p_msb, g_msb;            // Propagate và Generate cho riêng bit thứ 17 (MSB - index 16)
//===============RESULT_PROCESS (16-bit thấp chia thành 4 khối 4-bit) ===========================================
  cla_adder_4bit cla_0 (.a_i(a_i[3:0]),  .b_i(b_i[3:0]),  .cin_i(cin_i),      .prog_o(prog_temp[0]),.gen_no(gen_ntemp[0]),.s_o(result_o[3:0])); 
  cla_adder_4bit cla_1 (.a_i(a_i[7:4]),  .b_i(b_i[7:4]),  .cin_i(cin_out[0]), .prog_o(prog_temp[1]),.gen_no(gen_ntemp[1]),.s_o(result_o[7:4]));
  cla_adder_4bit cla_2 (.a_i(a_i[11:8]), .b_i(b_i[11:8]), .cin_i(cin_out[1]), .prog_o(prog_temp[2]),.gen_no(gen_ntemp[2]),.s_o(result_o[11:8]));
  cla_adder_4bit cla_3 (.a_i(a_i[15:12]),.b_i(b_i[15:12]),.cin_i(cin_out[2]), .prog_o(prog_temp[3]),.gen_no(gen_ntemp[3]),.s_o(result_o[15:12]));
//===============CARRY_PROCESS (Sử dụng khối 4-bit để bao phủ trọn vẹn 16 bit) =================================
  cla_carry_unit_4bit carry_process_16 (
    .p_i    (prog_temp),
    .g_ni   (gen_ntemp),
    .cin_i  (cin_i),
    .cin_out(cin_out),
    .p_o    (p_group_16),
    .g_no   (ng_group_16)
  );
//===============MSB & EXTENDED LOOK-AHEAD PROCESS ==============================================================
  always_comb begin : extended_look_ahead_logic
    cin_16 = ~ng_group_16 | (p_group_16 & cin_i);
    p_msb = a_i[16] ^ b_i[16];
    g_msb = ~(a_i[16] & b_i[16]);
    result_o[16] = p_msb ^ cin_16;
    cout_o = ~g_msb | (p_msb & cin_16);
  end

endmodule