//=============================================================================================================
// Project         : Switching Median
// Module          : Median Finding 
// File            : median_cal.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 28/08/2026
//=============================================================================================================
import package_param::*;
module median_cal #(
  parameter WIDTH_PIXEL    = 8
)(
  input  logic                        i_clk,
  input  logic                        ni_rst,
  input  logic                        i_valid,
	input  logic [8:0][WIDTH_PIXEL-1:0] compare_pixels,
	output logic      [WIDTH_PIXEL-1:0] median_o
);
//==========================DECLARATION=================================================
  //----------------comparing--------------------------
  logic                        ge_m12, ge_m23, ge_m31;
  logic [1:0]                  final_med_sel;
	logic [2:0][WIDTH_PIXEL-1:0] min_stage1_o, med_stage1_o, max_stage1_o;
	logic [2:0][WIDTH_PIXEL-1:0] min_stage2_o, med_stage2_o, max_stage2_o;
	logic [8:0][WIDTH_PIXEL-1:0] compare_stage2;
  logic      [WIDTH_PIXEL-1:0] max_of_mins, med_of_meds, min_of_maxs;
  logic      [WIDTH_PIXEL-1:0] stage3_comb_median;
  //----------------pipeline_registers--------------------------
  logic [2:0]                  valid_shift_reg;
  stage1_cal_stage             stage1_reg, stage1_next;
  stage2_cal_stage             stage2_reg, stage2_next;
//========================PIPELINE CONTROL=====================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin : valid_tracking
    if (~ni_rst) begin
      valid_shift_reg <= 3'b0;
    end else begin
      valid_shift_reg <= {valid_shift_reg[1:0], i_valid}; 
    end
  end
  assign o_valid = valid_shift_reg[2];
//==========================COMPARING=================================================
//------------------STAGE_1_COMPARE-----------------------------------------------------
  compare_row #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) compare_stage1 (
    .compare_pixels(compare_pixels),
    .min_o(min_stage1_o),
    .med_o(med_stage1_o),
    .max_o(max_stage1_o)
  );
  always_comb begin : stage1_comb
    //-----------MIN--------------
    stage1_next.px[0] = min_stage1_o[0];
    stage1_next.px[1] = min_stage1_o[1];
    stage1_next.px[2] = min_stage1_o[2];
    //-----------MED--------------
    stage1_next.px[3] = med_stage1_o[0];
    stage1_next.px[4] = med_stage1_o[1];
    stage1_next.px[5] = med_stage1_o[2];
    //-----------MAX--------------
    stage1_next.px[6] = max_stage1_o[0];
    stage1_next.px[7] = max_stage1_o[1];
    stage1_next.px[8] = max_stage1_o[2];
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : stage1_register_block
    if (~ni_rst) begin
      stage1_reg <= '0;
    end else if (i_valid) begin
      stage1_reg <= stage1_next;
    end
  end
  always_comb begin
    //------------CONCAT_MIN------------------------
    compare_stage2[0] = stage1_reg.px[0];
    compare_stage2[1] = stage1_reg.px[1];
    compare_stage2[2] = stage1_reg.px[2];
    //------------CONCAT_MED------------------------
    compare_stage2[3] = stage1_reg.px[3];
    compare_stage2[4] = stage1_reg.px[4];
    compare_stage2[5] = stage1_reg.px[5];
    //------------CONCAT_MAX------------------------
    compare_stage2[6] = stage1_reg.px[6];
    compare_stage2[7] = stage1_reg.px[7];
    compare_stage2[8] = stage1_reg.px[8];
  end
  //------------------STAGE_2_COMPARE-----------------------------------------------------
  compare_row #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) compare_stage_2 (
    .compare_pixels(compare_stage2),
    .min_o(min_stage2_o),             // MAX of MIN (max_stage2_o[0]) - index 0 has MIN
    .med_o(med_stage2_o),             // MED of MED (med_stage2_o[1]) - index 1 has MED
    .max_o(max_stage2_o)              // MIN of MAX (min_stage2_o[2]) - index 2 has MAX
  );
  always_comb begin : stage2_comb
    stage2_next.max_of_mins = max_stage2_o[0];
    stage2_next.med_of_meds = med_stage2_o[1];
    stage2_next.min_of_maxs = min_stage2_o[2];
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : stage2_register_block
    if (~ni_rst) begin
      stage2_reg <= '0;
    end else if (valid_shift_reg[0]) begin
      stage2_reg <= stage2_next;
    end
  end
//------------------STAGE 3---------------------------------------------------------
  assign max_of_mins = stage2_reg.max_of_mins;
  assign med_of_meds = stage2_reg.med_of_meds;
  assign min_of_maxs = stage2_reg.min_of_maxs;
  tree_comp_8bit comp_m12 (.x_i(max_of_mins), .y_i(med_of_meds), .ge_o(ge_m12));
  tree_comp_8bit comp_m23 (.x_i(med_of_meds), .y_i(min_of_maxs), .ge_o(ge_m23));
  tree_comp_8bit comp_m31 (.x_i(min_of_maxs), .y_i(max_of_mins), .ge_o(ge_m31));
  always_comb begin : stage3_comb
    // 1 là trung vị nếu 1 nằm giữa 2 và 3 -> 2 > 1 > 3 || 2 < 1 < 3 -> ge_m12 và ge_m31 phải cùng đúng hoặc cùng sai.
    // 2 là trung vị nếu 2 nằm giữa 1 và 3 -> 1 > 2 > 3 || 1 < 2 < 3 -> ge_m12 và ge_m23 phải cùng đúng hoặc cùng sai.
    // Nếu không phải A hay B, thì chắc chắn C là trung vị.
    if (~(ge_m12 ^ ge_m31)) begin
      stage3_comb_median = max_of_mins;
    end 
    else if (~(ge_m12 ^ ge_m23)) begin
      stage3_comb_median = med_of_meds;
    end 
    else begin
      stage3_comb_median = min_of_maxs;
    end
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : stage3_register_block
    if (~ni_rst) begin
      median_o <= '0;
    end else if (valid_shift_reg[1]) begin
      median_o <= stage3_comb_median;
    end
  end
endmodule