//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Non Restoring Division
// File            : non_res_div.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 15/09/2026
// Updated date    : 25/10/2026
//=============================================================================================================
import package_param::*;
module non_res_div (
  input  logic [WIDTH_REM-1:0]   i_rem,     
  input  logic [WIDTH_PIXEL-1:0] i_quoti,   
  input  logic [WIDTH_DEN-1:0]   i_den,     
  output logic [WIDTH_REM-1:0]   o_remain,  
  output logic [WIDTH_PIXEL-1:0] o_quoti    
);
//========================DECLARATION==============================================
  logic [WIDTH_REM-1:0] rem_shifted;
  logic [WIDTH_REM-1:0] den_padded;
  logic [WIDTH_REM-1:0] add_sub_sel;
  logic                 msb_rem_shifted;
//==========================LOGIC_CONTROL==============================================
  assign den_padded      = {1'b0, i_den};
  assign rem_shifted     = {i_rem[WIDTH_REM-2:0], i_quoti[WIDTH_PIXEL-1]};
  assign msb_rem_shifted = rem_shifted[WIDTH_REM-1];
  assign add_sub_sel     = msb_rem_shifted ? den_padded : ~den_padded;
//==========================INSTANTIATION==========================================
  cla_nbit # (.WIDTH_CLA(14)) adder_subtractor_core (.a(rem_shifted),.b(add_sub_sel), .cin(~msb_rem_shifted),.sum(o_remain),.cout());
//==========================QUOTIENT UPDATE============================================
  assign o_quoti = o_remain[WIDTH_REM-1] ? {i_quoti[WIDTH_PIXEL-2:0], 1'b0}  
                                         : {i_quoti[WIDTH_PIXEL-2:0], 1'b1};
endmodule