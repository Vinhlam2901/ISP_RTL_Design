// Project         : Switching Median
// Module          : Comparing Row
// File            : compare_row.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 24/08/2026
//=============================================================================================================
module compare_row #(
  parameter WIDTH_PIXEL    = 8     // 8bit for 1 pixel
)(
	input  logic [8:0][WIDTH_PIXEL-1:0] compare_pixels,
	output logic [2:0][WIDTH_PIXEL-1:0] min_o, med_o, max_o
);
//==============DECLARATION====================================================================================
  //----------------comparing--------------------------
  logic       ge_01, ge_12, ge_20;
  logic       ge_34, ge_45, ge_53;
  logic       ge_67, ge_78, ge_86;
  logic       ge_67, ge_78, ge_86;
  logic [1:0] min_r1_sel, min_r2_sel, min_r3_sel;
  logic [1:0] med_r1_sel, med_r2_sel, med_r3_sel;
  logic [1:0] max_r1_sel, max_r2_sel, max_r3_sel;
//==============INSTANTIATION====================================================================================
  //------------------FINDING_MAX_MIN_MEDIAN_OF_ROW1----------------------------------------------------
  tree_comp_8bit compare_01 (.x_i(compare_pixels[0]), .y_i(compare_pixels[1]), .ge_o(ge_01));
  tree_comp_8bit compare_12 (.x_i(compare_pixels[1]), .y_i(compare_pixels[2]), .ge_o(ge_12));
  tree_comp_8bit compare_20 (.x_i(compare_pixels[2]), .y_i(compare_pixels[0]), .ge_o(ge_20));
  //------------MUXING_FOR_COMPARING--------------------------------------------------------------------
  always_comb begin : compare_row1
    min_r1_sel = {{ge_12 &  ~ge_20}, {ge_01 & ~ge_12}};
    med_r1_sel = {{(ge_01 ^ ge_12) | ~(ge_12 ^ ge_20)}, {~(ge_01 ^ ge_12) | (ge_12 ^ ge_20)}};
    max_r1_sel = {{~ge_01 & ~ge_12},{~ge_01 & ge_12}};
    case (min_r1_sel)
      2'b00:   min_o[0] = compare_pixels[0]; 
      2'b01:   min_o[0] = compare_pixels[1]; 
      2'b10:   min_o[0] = compare_pixels[2]; 
      default: min_o[0] = 8'b0;
    endcase
    case (med_r1_sel)
      2'b00:   med_o[0] = compare_pixels[0]; 
      2'b01:   med_o[0] = compare_pixels[1]; 
      2'b10:   med_o[0] = compare_pixels[2]; 
      default: med_o[0] = 8'b0;
    endcase
    case (max_r1_sel)
      2'b00:   max_o[0] = compare_pixels[0]; 
      2'b01:   max_o[0] = compare_pixels[1]; 
      2'b10:   max_o[0] = compare_pixels[2]; 
      default: max_o[0] = 8'b0;
    endcase
  end
  //------------------FINDING_MAX_MIN_MEDIAN_OF_ROW2----------------------------------------------------
  tree_comp_8bit compare_34 (.x_i(compare_pixels[3]), .y_i(compare_pixels[4]), .ge_o(ge_34));
  tree_comp_8bit compare_45 (.x_i(compare_pixels[4]), .y_i(compare_pixels[5]), .ge_o(ge_45));
  tree_comp_8bit compare_53 (.x_i(compare_pixels[5]), .y_i(compare_pixels[3]), .ge_o(ge_53));
  //------------MUXING_FOR_COMPARING--------------------------------------------------------------------
  always_comb begin : compare_row2
    min_r2_sel = {{ge_45 &  ~ge_53}, {ge_34 & ~ge_45}};
    med_r2_sel = {{(ge_34 ^ ge_45) | ~(ge_45 ^ ge_53)}, {~(ge_34 ^ ge_45) | (ge_45 ^ ge_53)}};
    max_r2_sel = {{~ge_34 & ~ge_45},{~ge_34 & ge_45}};
    case (min_r2_sel)
      2'b00:   min_o[1] = compare_pixels[3]; 
      2'b01:   min_o[1] = compare_pixels[4]; 
      2'b10:   min_o[1] = compare_pixels[5]; 
      default: min_o[1] = 8'b0;
    endcase
    case (med_r2_sel)
      2'b00:   med_o[1] = compare_pixels[3]; 
      2'b01:   med_o[1] = compare_pixels[4]; 
      2'b10:   med_o[1] = compare_pixels[5]; 
      default: med_o[1] = 8'b0;
    endcase
    case (max_r2_sel)
      2'b00:   max_o[1] = compare_pixels[3]; 
      2'b01:   max_o[1] = compare_pixels[4]; 
      2'b10:   max_o[1] = compare_pixels[5]; 
      default: max_o[1] = 8'b0;
    endcase
  end
  //------------------FINDING_MAX_MIN_MEDIAN_OF_ROW3----------------------------------------------------
  tree_comp_8bit compare_67 (.x_i(compare_pixels[6]), .y_i(compare_pixels[7]), .ge_o(ge_67));
  tree_comp_8bit compare_78 (.x_i(compare_pixels[7]), .y_i(compare_pixels[8]), .ge_o(ge_78));
  tree_comp_8bit compare_86 (.x_i(compare_pixels[8]), .y_i(compare_pixels[6]), .ge_o(ge_86));
  //------------MUXING_FOR_COMPARING--------------------------------------------------------------------
  always_comb begin : compare_row3
    min_r3_sel = {{ge_78 &  ~ge_86}, {ge_67 & ~ge_78}};
    med_r3_sel = {{(ge_67 ^ ge_78) | ~(ge_78 ^ ge_86)}, {~(ge_67 ^ ge_78) | (ge_78 ^ ge_86)}};
    max_r3_sel = {{~ge_67 & ~ge_78},{~ge_67 & ge_78}};
    case (min_r3_sel)
      2'b00:   min_o[2] = compare_pixels[6]; 
      2'b01:   min_o[2] = compare_pixels[7]; 
      2'b10:   min_o[2] = compare_pixels[8]; 
      default: min_o[2] = 8'b0;
    endcase
    case (med_r3_sel)
      2'b00:   med_o[2] = compare_pixels[6]; 
      2'b01:   med_o[2] = compare_pixels[7]; 
      2'b10:   med_o[2] = compare_pixels[8]; 
      default: med_o[2] = 8'b0;
    endcase
    case (max_r3_sel)
      2'b00:   max_o[2] = compare_pixels[6]; 
      2'b01:   max_o[2] = compare_pixels[7]; 
      2'b10:   max_o[2] = compare_pixels[8]; 
      default: max_o[2] = 8'b0;
    endcase
  end
endmodule