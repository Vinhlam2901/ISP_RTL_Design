//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Bilateral Filter
// File            : bilateral_filter.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 14/09/2026
//=============================================================================================================
import package_param::*;
module bilateral_filter #(
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
	input  logic      	           i_clk,
	input  logic      	           ni_rst,
	input  logic      	           i_ready,
	input  logic [WIDTH_PIXEL-1:0] i_pix,
  output logic                   o_valid,
	output logic [WIDTH_PIXEL-1:0] o_pix_filter
);
	//==============DECLARATION=======================================================================================
  logic                        compute_start;
  //----------------window_pixel--------------------------
	logic [8:0][WIDTH_PIXEL-1:0] compute_pixels;
  //---------------compute_intensity_difference------------
  logic [7:0]                  cout_diff;
  logic [WIDTH_PIXEL-1:0]      diff_center_00, diff_center_01, diff_center_02;
  logic [WIDTH_PIXEL-1:0]      diff_center_10, diff_center_12;
  logic [WIDTH_PIXEL-1:0]      diff_center_20, diff_center_21, diff_center_22;
  logic [WIDTH_PIXEL:0]        abs_diff_00, abs_diff_01, abs_diff_02;
  logic [WIDTH_PIXEL:0]        abs_diff_10, abs_diff_12;
  logic [WIDTH_PIXEL:0]        abs_diff_20, abs_diff_21, abs_diff_22;
  //---------------ws_lut----------------------------------
  logic [6:0]                  awr_00, awr_01, awr_02;
  logic [6:0]                  awr_10, awr_11, awr_12;
  logic [6:0]                  awr_20, awr_21, awr_22;
  logic [8:0]                  wmul_00, wmul_01, wmul_02;
  logic [8:0]                  wmul_10, wmul_11, wmul_12;
  logic [8:0]                  wmul_20, wmul_21, wmul_22;
  logic [8:0][8:0]             mac_wc_array;
  logic [20:0]                 mac_num_out;
  logic [12:0]                 mac_den_out;
  //----------------pipeline--------------------------------
  logic            [2:0]       valid_shift_reg; 
  stage1_lut                   stage1_reg, stage1_next;
  stage2_mac                   stage2_reg, stage2_next;
  // stage3_dec_stage             stage3_reg, stage3_next;
  //==============INSTANTIATION WINDOW GENERATOR====================================================================
  window_generator_3x3 #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH(WIDTH),
    .LENGTH(LENGTH)
  ) image_coordinated (
    .i_clk          (i_clk),
    .ni_rst         (ni_rst),
    .i_ready        (i_ready),
    .i_pix          (i_pix),
    .o_valid_window (compare_start),
    .window_00      (compute_pixels[0]), .window_01(compute_pixels[1]), .window_02(compute_pixels[2]),
    .window_10      (compute_pixels[3]), .window_11(compute_pixels[4]), .window_12(compute_pixels[5]),
    .window_20      (compute_pixels[6]), .window_21(compute_pixels[7]), .window_22(compute_pixels[8])
  );
//===========================COMPUTE_INTENSITY_DIFFERENCE==============================================
  cla_adder_8bit  diff_11_00 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[0]),.cin_i(1'b1),.cout_o(cout_diff[0]),.result_o(diff_center_00));
  cla_adder_8bit  diff_11_01 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[1]),.cin_i(1'b1),.cout_o(cout_diff[1]),.result_o(diff_center_01));
  cla_adder_8bit  diff_11_02 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[2]),.cin_i(1'b1),.cout_o(cout_diff[2]),.result_o(diff_center_02));
  cla_adder_8bit  diff_11_10 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[3]),.cin_i(1'b1),.cout_o(cout_diff[3]),.result_o(diff_center_10));
  cla_adder_8bit  diff_11_12 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[5]),.cin_i(1'b1),.cout_o(cout_diff[4]),.result_o(diff_center_12));
  cla_adder_8bit  diff_11_20 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[6]),.cin_i(1'b1),.cout_o(cout_diff[5]),.result_o(diff_center_20));
  cla_adder_8bit  diff_11_21 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[7]),.cin_i(1'b1),.cout_o(cout_diff[6]),.result_o(diff_center_21));
  cla_adder_8bit  diff_11_22 (.a_i(compute_pixels[4]),.b_i(~compute_pixels[8]),.cin_i(1'b1),.cout_o(cout_diff[7]),.result_o(diff_center_22));
  //------------------ABSOLUTE VALUE LOGIC--------------------------------------
  always_comb begin
    abs_diff_00 = (cout_diff[0]) ? (~{cout_diff[0], diff_center_00} + 1'b1) : {cout_diff[0], diff_center_00};
    abs_diff_01 = (cout_diff[1]) ? (~{cout_diff[1], diff_center_01} + 1'b1) : {cout_diff[1], diff_center_01};
    abs_diff_02 = (cout_diff[2]) ? (~{cout_diff[2], diff_center_02} + 1'b1) : {cout_diff[2], diff_center_02};
    abs_diff_10 = (cout_diff[3]) ? (~{cout_diff[3], diff_center_10} + 1'b1) : {cout_diff[3], diff_center_10};
    abs_diff_12 = (cout_diff[4]) ? (~{cout_diff[4], diff_center_12} + 1'b1) : {cout_diff[4], diff_center_12};
    abs_diff_20 = (cout_diff[5]) ? (~{cout_diff[5], diff_center_20} + 1'b1) : {cout_diff[5], diff_center_20};
    abs_diff_21 = (cout_diff[6]) ? (~{cout_diff[6], diff_center_21} + 1'b1) : {cout_diff[6], diff_center_21};
    abs_diff_22 = (cout_diff[7]) ? (~{cout_diff[7], diff_center_22} + 1'b1) : {cout_diff[7], diff_center_22};
  end
//========================PIPELINE CONTROL========================================================================
  always_ff @(posedge i_clk ) begin : valid_tracking_register
    if (~ni_rst) begin
      valid_shift_reg <= 3'b0;
    end else if (i_ready) begin
      valid_shift_reg <= {valid_shift_reg[1:0], compare_start}; 
    end
  end
  assign o_valid = valid_shift_reg[2];
  //========================STAGE 1:LUT=======================================================
  always_comb begin : stage1_comb
    //-------------INTENSITY_DIFFERENCE------------------------
    stage1_next.diff[0]   = abs_diff_00;
    stage1_next.diff[1]   = abs_diff_01;
    stage1_next.diff[2]   = abs_diff_02;
    stage1_next.diff[3]   = abs_diff_10;
    stage1_next.diff[4]   = 8'd0;
    stage1_next.diff[5]   = abs_diff_12;
    stage1_next.diff[6]   = abs_diff_20;
    stage1_next.diff[7]   = abs_diff_21;
    stage1_next.diff[8]   = abs_diff_22;
    //-------------PREVIOUS_PIXEL_COMPUTE------------------------
    stage1_next.pre_px[0] = compute_pixels[0];
    stage1_next.pre_px[1] = compute_pixels[1];
    stage1_next.pre_px[2] = compute_pixels[2];
    stage1_next.pre_px[3] = compute_pixels[3];
    stage1_next.pre_px[4] = compute_pixels[4];
    stage1_next.pre_px[5] = compute_pixels[5];
    stage1_next.pre_px[6] = compute_pixels[6];
    stage1_next.pre_px[7] = compute_pixels[7];
    stage1_next.pre_px[8] = compute_pixels[8];
  end
  
  always_ff @(posedge i_clk) begin : stage1_register
    if(~ni_rst) begin
      stage1_reg <= '0;
    end else if (compare_start & i_ready) begin
      stage1_reg <= stage1_next;
    end
  end
//======================WEIGHTED_INTENSITY_RANGE_LUT========= ========================================================================
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_00 (.delta_i(stage1_reg.diff[0]),.awr_o(awr_00));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_01 (.delta_i(stage1_reg.diff[1]),.awr_o(awr_01));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_02 (.delta_i(stage1_reg.diff[2]),.awr_o(awr_02));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_10 (.delta_i(stage1_reg.diff[3]),.awr_o(awr_10));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_11 (.delta_i(stage1_reg.diff[4]),.awr_o(awr_11));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_12 (.delta_i(stage1_reg.diff[5]),.awr_o(awr_12));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_20 (.delta_i(stage1_reg.diff[6]),.awr_o(awr_20));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_21 (.delta_i(stage1_reg.diff[7]),.awr_o(awr_21));
  weighted_range_lut #(.SIGMA_R(15)) ws_lut_22 (.delta_i(stage1_reg.diff[8]),.awr_o(awr_22));
//=====================WS_WP_CONVOLUTION=============================================================================
  coefficiency_mul ws_wp_mul (
    .awr_00 (awr_00),  .awr_01 (awr_01),  .awr_02 (awr_02), 
    .awr_10 (awr_10),  .awr_11 (awr_11),  .awr_12 (awr_12),
    .awr_20 (awr_20),  .awr_21 (awr_21),  .awr_22 (awr_22),
    .wmul_00(wmul_00), .wmul_01(wmul_01), .wmul_02(wmul_02),
    .wmul_10(wmul_10), .wmul_11(wmul_11), .wmul_12(wmul_12),
    .wmul_20(wmul_20), .wmul_21(wmul_21), .wmul_22(wmul_22)
  );
  always_comb begin : pack_weights
    mac_wc_array[0] = wmul_00; mac_wc_array[1] = wmul_01; mac_wc_array[2] = wmul_02;
    mac_wc_array[3] = wmul_10; mac_wc_array[4] = wmul_11; mac_wc_array[5] = wmul_12;
    mac_wc_array[6] = wmul_20; mac_wc_array[7] = wmul_21; mac_wc_array[8] = wmul_22;
  end
//========================STAGE 2:COMPUTE_MAC_NUMERATOR_DENOMINATOR=======================================================
  mac_bilateral #(
  .WIDTH_PX (WIDTH_PIXEL),
  .WIDTH_WC (9),
  .GUARD_BIT(4),
  .WIDTH_MUL(17)
  ) mac_bilateral (
    .i_clk(i_clk),
    .ni_rst(ni_rst),
    .mac_en_i(valid_shift_reg[0]),
    .px_i(stage1_reg.pre_px),
    .wc_i(mac_wc_array),
    .mac_valid_o(),
    .mac_num_out(mac_num_out),
    .mac_den_out(mac_den_out)
  );
  always_comb begin : stage2_comb
    stage2_next.mac_num = mac_num_out;
    stage2_next.mac_den = mac_den_out;
  end
  
  always_ff @(posedge i_clk) begin : stage2_register
    if(~ni_rst) begin
      stage2_reg <= '0;
    end else if (valid_shift_reg[0]) begin
      stage2_reg <= stage1_next;
    end
  end
//========================STAGE 3:DIVISION=======================================================

endmodule