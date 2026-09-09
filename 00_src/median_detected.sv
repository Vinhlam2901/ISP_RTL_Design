//=============================================================================================================
// Project         : Switching Median
// Module          : Median Detection 
// File            : median_detected.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 28/08/2026
//=============================================================================================================
module median_detected #(
  parameter WIDTH_PIXEL = 8
)(
	input  logic [2:0][WIDTH_PIXEL-1:0] compare_pixels,
	output logic [WIDTH_PIXEL-1:0]      px_deviation_abs
);
//=========================DEVIATION_FINDING==================================
	logic                   cout_plus;
	logic                   cout_sub;
	logic [WIDTH_PIXEL-1:0] px_side_plus;
	logic [WIDTH_PIXEL:0]   px_side_plus_ext;
	logic [WIDTH_PIXEL:0]   px_center_sl_ext;
	logic [WIDTH_PIXEL:0]   px_deviation;
  logic [WIDTH_PIXEL:0]   px_complement;
//=========================DEVIATION_FINDING==================================
  //---------2_SIDES_PX_PLUS---------------------------------------
  cla_adder_8bit side_plus (
    .a_i(compare_pixels[0]),
    .b_i(compare_pixels[2]),
    .cin_i(1'b0),
    .cout_o(cout_plus),
    .result_o(px_side_plus)
  );
  assign px_side_plus_ext = {cout_plus, px_side_plus};
  //--------SHIFT_LEFT_CENTER_PX------------------------------------
  sll_8bit px_center_sl (
    .a_i(compare_pixels[1]),
    .b_i(8'b1),
    .sl_o(px_center_sl_ext)
  );
  //---------------PX_DEVIATION------------------------------------
  cla_adder_9bit subtract_side_center (
    .a_i(px_side_plus_ext),
    .b_i(~px_center_sl_ext),
    .cin_i(1'b1),
    .cout_o(cout_sub),
    .result_o(px_deviation)
  );
  //------------PX_ABSOLUTE-----------------------------------------
  assign px_complement = cout_sub ? px_deviation : (~px_deviation + 1'b1);
  assign px_deviation_abs = px_complement[8] ? 8'hFF : px_complement[7:0];
endmodule