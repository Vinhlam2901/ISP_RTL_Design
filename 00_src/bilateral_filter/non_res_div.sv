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
  input  logic [WIDTH_REM-1:0] i_rem,     
  input  logic [WIDTH_OUT-1:0] i_quoti,   
  input  logic [WIDTH_DEN-1:0] i_den,     
  output logic [WIDTH_REM-1:0] o_remain,  
  output logic [WIDTH_OUT-1:0] o_quoti    
);
//========================DECLARATION==============================================
  logic [WIDTH_REM-1:0] rem_shifted;
  logic [WIDTH_REM-1:0] den_padded;
  logic [WIDTH_REM-1:0] add_sub_sel;
  logic                 msb_rem_shifted;
//==========================LOGIC_CONTROL==============================================
  assign den_padded      = {1'b0, i_den};
  assign rem_shifted     = {i_rem[WIDTH_REM-2:0], i_quoti[WIDTH_OUT-1]};
  assign msb_rem_shifted = rem_shifted[WIDTH_REM-1];
  assign add_sub_sel     = msb_rem_shifted ? den_padded : ~den_padded;
//==========================INSTANTIATION==========================================
  cla_adder_14bit adder_subtractor_core (
    .a_i     (rem_shifted),
    .b_i     (add_sub_sel),
    .cin_i   (~msb_rem_shifted),
    .result_o(o_remain), // Đẩy thẳng kết quả ra Output
    .cout_o  ()
  );
//==========================QUOTIENT UPDATE============================================
  assign o_quoti = o_remain[WIDTH_REM-1] ? {i_quoti[WIDTH_OUT-2:0], 1'b0}  
                                         : {i_quoti[WIDTH_OUT-2:0], 1'b1};
endmodule