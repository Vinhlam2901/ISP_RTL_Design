//=============================================================================================================
// Project         : Switching Median
// Module          : Median Detection 
// File            : median_detected.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 25/10/2026
//=============================================================================================================
import package_param::*;
module median_detected (
	input  logic [2:0][WIDTH_PIXEL-1:0] compare_pixels,
	output logic      [WIDTH_PIXEL-1:0] px_deviation_abs
);
//=========================DEVIATION_FINDING==================================
	logic                   cout_plus;
	logic                   cout_sub;
	logic [WIDTH_PIXEL-1:0] px_side_plus;
	logic [WIDTH_PIXEL:0]   px_side_plus_ext;
	logic [WIDTH_PIXEL:0]   px_center_sl_ext;
	logic [WIDTH_PIXEL:0]   px_deviation;
	logic [WIDTH_PIXEL+1:0] px_deviation_ext;
  logic [WIDTH_PIXEL+1:0] px_complement;
//=========================DEVIATION_FINDING==================================
  //---------2_SIDES_PX_PLUS---------------------------------------
  cla_nbit # (
    .WIDTH_CLA(8)
  )side_plus (
    .a(compare_pixels[0]),
    .b(compare_pixels[2]), 
    .cin(1'b0),
    .sum(px_side_plus),
    .cout(cout_plus)
  );
  assign px_side_plus_ext = {cout_plus, px_side_plus};
  //--------SHIFT_LEFT_CENTER_PX------------------------------------
  sll_8bit px_center_sl (
    .a_i (compare_pixels[1]),
    .b_i (8'b1),
    .sl_o(px_center_sl_ext)
  );
  //---------------PX_DEVIATION------------------------------------
  cla_nbit # (
    .WIDTH_CLA(9)
  )subtract_side_center (
    .a(px_side_plus_ext),
    .b(~px_center_sl_ext), 
    .cin(1'b1),
    .sum(px_deviation),
    .cout(cout_sub)
  );
  assign px_deviation_ext = {cout_sub, px_deviation};
  //------------PX_ABSOLUTE-----------------------------------------
  assign px_complement    = cout_sub         ? px_deviation_ext : (~px_deviation_ext + 1'b1);
  assign px_deviation_abs = px_complement[9] ? 8'hFF            :   px_complement[7:0];
endmodule