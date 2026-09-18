//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Carry Lookahead Adder 10bit 
// File            : cla_adder_10bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 14/09/2026
//============================================================================================================
module cla_adder_13bit (
  input  logic [12:0] a_i,
  input  logic [12:0] b_i,
  input  logic        cin_i,
  output logic        cout_o,
  output logic [12:0] result_o 
);
  //===============DECLARATION=============================================
  logic cout_12;       // Carry out tràn ra từ bộ 12-bit
  logic p_12, ng_12;    // Propagate và Generate cho riêng bit 12 (MSB)
  //===============LÕI 12-BIT==============================================
  // Gọi trực tiếp bộ 12-bit để giải quyết một lúc từ bit 0 đến bit 11
  cla_adder_12bit cla_12_core (
    .a_i      (a_i[11:0]),
    .b_i      (b_i[11:0]),
    .cin_i    (cin_i),
    .cout_o   (cout_12), 
    .result_o (result_o[11:0])
  );
  //===============MỞ RỘNG 1-BIT MSB (BIT THỨ 13)==========================
  always_comb begin : msb_logic
    // Tính P và G cho bit thứ 13 (index 12)
    p_12  = a_i[12] ^ b_i[12];
    ng_12 = ~(a_i[12] & b_i[12]);
    // Tính tổng cho bit 13, lấy trực tiếp cout_12 làm cin
    result_o[12] = p_12 ^ cout_12;
    // Tính Carry Out cuối cùng của toàn mạch 13-bit
    cout_o = ~ng_12 | (p_12 & cout_12);
  end

endmodule