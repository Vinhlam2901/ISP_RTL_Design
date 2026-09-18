//=============================================================================================================
// Project         : Switching Median
// Module          : Switching Median
// File            : switching_median.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 10/09/2026
//=============================================================================================================
import package_param::*;
module switching_median #(
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
  input  logic                   i_clk,
  input  logic                   ni_rst,
  input  logic                   i_ready,
  input  logic [WIDTH_PIXEL-1:0] i_threshold,
  input  logic [WIDTH_PIXEL-1:0] i_pix,
  output logic                   o_valid,
  output logic [WIDTH_PIXEL-1:0] o_pix_median
);
  //==============DECLARATION=======================================================================================
  logic                        compare_start;
  logic [WIDTH_PIXEL-1:0]      median_o;
  //----------------window_pixel--------------------------
  logic [WIDTH_PIXEL-1:0]      window_00, window_01, window_02; // row 0
  logic [WIDTH_PIXEL-1:0]      window_10, window_11, window_12; // row 1
  logic [WIDTH_PIXEL-1:0]      window_20, window_21, window_22; // row 2
  logic [8:0][WIDTH_PIXEL-1:0] compare_pixels;
  //----------------px_deviation--------------------------
  logic                   ge_vh, ge_lr, ge_dev, ge_threshold;
  logic                   is_noise;
  logic [WIDTH_PIXEL-1:0] vert_dev, hor_dev, crossleft_dev, crossright_dev;
  logic [WIDTH_PIXEL-1:0] min_vh, min_lr, min_dev;
  //----------------pipeline--------------------------------
  logic            [2:0]  valid_shift_reg; 
  stage1_dev_stage        stage1_reg, stage1_next;
  stage2_min_stage        stage2_reg, stage2_next;
  stage3_dec_stage        stage3_reg, stage3_next;
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
    .window_00      (window_00), .window_01(window_01), .window_02(window_02),
    .window_10      (window_10), .window_11(window_11), .window_12(window_12),
    .window_20      (window_20), .window_21(window_21), .window_22(window_22)
  );
//==============PIXELS_WINDOW==================================================================
  always_comb begin
    compare_pixels[0] = window_00; compare_pixels[1] = window_01; compare_pixels[2] = window_02;
    compare_pixels[3] = window_10; compare_pixels[4] = window_11; compare_pixels[5] = window_12;
    compare_pixels[6] = window_20; compare_pixels[7] = window_21; compare_pixels[8] = window_22;
  end
//==============MEDIAN_CALCULATED==================================================================
  median_cal #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) median_finding (
    .i_clk         (i_clk),
    .ni_rst        (ni_rst),
    .i_ready       (i_ready),
    .i_valid       (compare_start),
    .o_compare_pixels(compare_pixels),
    .o_valid       (),
    .o_median      (median_o)
  );
//========================PIPELINE CONTROL========================================================================
  always_ff @(posedge i_clk) begin : valid_tracking_register
    if (~ni_rst) begin
      valid_shift_reg <= 3'b0;
    end else if (i_ready) begin
      valid_shift_reg <= {valid_shift_reg[1:0], compare_start}; 
    end
  end
  assign o_valid = valid_shift_reg[2];
  //------------DEVIATION_DETECTION-------------------------------------------
  median_detected #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) vertical_deviation (
    .compare_pixels  ({window_21, window_11, window_01}),
    .px_deviation_abs(vert_dev)
  );
  median_detected #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) horizon_deviation (
    .compare_pixels  ({window_12, window_11, window_10}),
    .px_deviation_abs(hor_dev)
);
  median_detected #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) crossleft_deviation (
    .compare_pixels  ({window_22, window_11, window_00}),
    .px_deviation_abs(crossleft_dev)
  );
  median_detected #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) crossright_deviation (
    .compare_pixels  ({window_20, window_11, window_02}),
    .px_deviation_abs(crossright_dev)
  );
  //========================STAGE 1: LƯU ĐỘ LỆCH VÀ PIXEL GỐC=======================================================
  always_comb begin : stage1_comb
    stage1_next.vert_abs   = vert_dev;
    stage1_next.hor_abs    = hor_dev;
    stage1_next.crossl_abs = crossleft_dev;
    stage1_next.crossr_abs = crossright_dev;
    stage1_next.center_px  = window_11;
  end
  always_ff @(posedge i_clk) begin : stage1_register
    if(~ni_rst) begin
      stage1_reg <= '0;
    end else if (compare_start & i_ready) begin
      stage1_reg <= stage1_next;
    end
  end
  //------------MINIMUM_DEVIATION-------------------------------------------
  tree_comp_8bit comp_vert_hor (
    .x_i (stage1_reg.vert_abs), 
    .y_i (stage1_reg.hor_abs), 
    .ge_o(ge_vh)
  );
  assign min_vh = ge_vh ? stage1_reg.hor_abs : stage1_reg.vert_abs;
  tree_comp_8bit comp_cross_leftright (
    .x_i (stage1_reg.crossl_abs), 
    .y_i (stage1_reg.crossr_abs), 
    .ge_o(ge_lr)
  );
  assign min_lr = ge_lr ? stage1_reg.crossr_abs : stage1_reg.crossl_abs;
  tree_comp_8bit min_deviation (
    .x_i (min_vh), 
    .y_i (min_lr), 
    .ge_o(ge_dev)
  );
  assign min_dev = ge_dev ? min_lr : min_vh;
  always_comb begin : stage2_comb
    stage2_next.min_all   = min_dev;
    stage2_next.center_px = stage1_reg.center_px;
  end
  always_ff @(posedge i_clk) begin : stage2_register
    if(~ni_rst) begin
      stage2_reg <= '0;
    end else if (valid_shift_reg[0] & i_ready) begin
      stage2_reg <= stage2_next;
    end
  end
  //-------------THRESHOLD_COMPARE--------------------------------
  tree_comp_8bit compare_threshold (
    .x_i (stage2_reg.min_all), 
    .y_i (i_threshold), 
    .ge_o(ge_threshold)
  );
  assign is_noise = ge_threshold ? 1'b1 : 1'b0;
  always_comb begin : stage3_comb
    stage3_next.noise_flag = is_noise;
    stage3_next.center_px  = stage2_reg.center_px;
  end
  always_ff @(posedge i_clk) begin : stage3_register
    if(~ni_rst) begin
      stage3_reg <= '0;
    end else if (valid_shift_reg[1] & i_ready) begin
      stage3_reg <= stage3_next;
    end
  end
  //--------------MEDIAN_SWITCHING---------------------------------
  assign o_pix_median = stage3_reg.noise_flag ? median_o : stage3_reg.center_px;
endmodule