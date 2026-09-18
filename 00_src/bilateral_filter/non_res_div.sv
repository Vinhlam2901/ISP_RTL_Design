//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Non Restoring Division
// File            : non_res_div.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 15/09/2026
// Updated date    : 15/09/2026
//=============================================================================================================
module non_res_div #(
  parameter WIDTH_DEN = 13,
  parameter WIDTH_OUT = 8,
  parameter WIDTH_REM = 14
)(
  input  logic [WIDTH_REM-1:0] i_rem,     // Phần dư từ tầng trước (14-bit)
  input  logic [WIDTH_OUT-1:0] i_quoti,   // Thương số từ tầng trước (8-bit)
  input  logic [WIDTH_DEN-1:0] i_den,     // Mẫu số gốc (13-bit)
  output logic [WIDTH_REM-1:0] o_remain,  // Phần dư tính mới (14-bit)
  output logic [WIDTH_OUT-1:0] o_quoti    // Thương số mới (8-bit)
);
//========================DECLARATION==============================================
  logic [WIDTH_REM-1:0] rem_shifted;
  logic [WIDTH_REM-1:0] den_padded;
  logic [WIDTH_REM-1:0] remain_add;
  logic [WIDTH_REM-1:0] remain_sub;
  logic                 msb_rem_shifted;
//==========================INSTANTIATION==========================================
  cla_adder_14bit adder_14bit (
    .a_i(rem_shifted),
    .b_i(den_padded),
    .cin_i(1'b0),
    .result_o(remain_add),
    .cout_o()
  );
  cla_adder_14bit subtracter_14bit (
    .a_i(rem_shifted),
    .b_i(~den_padded),
    .cin_i(1'b1),
    .result_o(remain_sub),
    .cout_o()
  );
//==========================LOGIC_CONTROL==============================================
  // 1. Dịch trái {i_rem, i_quoti} 1 bit 
  // Lấy 13 bit thấp của i_rem ghép với bit cao nhất (MSB) của i_quoti
  assign den_padded      = {1'b0, i_den};
  assign rem_shifted     = {i_rem[WIDTH_REM-2:0], i_quoti[WIDTH_OUT-1]};
  assign msb_rem_shifted = rem_shifted[WIDTH_REM-1];
  assign o_remain        = msb_rem_shifted ? remain_add  
                                           : remain_sub;    
  assign o_quoti         = o_remain[WIDTH_REM-1] ? {i_quoti[WIDTH_OUT-2:0], 1'b0}  
                                                 : {i_quoti[WIDTH_OUT-2:0], 1'b1};

endmodule