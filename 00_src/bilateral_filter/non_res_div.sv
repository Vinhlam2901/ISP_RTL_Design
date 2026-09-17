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
  localparam WIDTH_REM = WIDTH_DEN + 1 
)(
  input  logic [WIDTH_REM-1:0] rem_i,     // Phần dư từ tầng trước (14-bit)
  input  logic [WIDTH_OUT-1:0] quoti_i,   // Thương số từ tầng trước (8-bit)
  input  logic [WIDTH_DEN-1:0] den_i,     // Mẫu số gốc (13-bit)
  output logic [WIDTH_REM-1:0] remain_o,  // Phần dư tính mới (14-bit)
  output logic [WIDTH_OUT-1:0] quoti_o    // Thương số mới (8-bit)
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
  // 1. Dịch trái {rem_i, quoti_i} 1 bit 
  // Lấy 13 bit thấp của rem_i ghép với bit cao nhất (MSB) của quoti_i
  assign den_padded      = {1'b0, den_i};
  assign rem_shifted     = {rem_i[WIDTH_REM-2:0], quoti_i[WIDTH_OUT-1]};
  assign msb_rem_shifted = rem_shifted[WIDTH_REM-1];
  assign remain_o        = msb_rem_shifted ? remain_add  
                                           : remain_sub;    
  assign quoti_o         = remain_o[WIDTH_REM-1] ? {quoti_i[WIDTH_OUT-2:0], 1'b0}  
                                                 : {quoti_i[WIDTH_OUT-2:0], 1'b1};

endmodule