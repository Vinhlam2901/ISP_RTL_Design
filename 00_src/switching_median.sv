//=============================================================================================================
// Project         : Switching Median
// Module          : Switching Median
// File            : switching_median.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 07/09/2026
//=============================================================================================================
import package_param::*;
module switching_median #(
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
	input  logic      	           i_clk,
	input  logic      	           ni_rst,
	input  logic      	           i_ready,
  input  logic [WIDTH_PIXEL-1:0] threshold_i,
  output logic                   o_valid,
	input  logic [WIDTH_PIXEL-1:0] i_pix,
	output logic [WIDTH_PIXEL-1:0] o_pix_median
	);
	//==============DECLARATION=======================================================================================
  logic                        compare_start;
  logic [WIDTH_PIXEL-1:0]      median_o;
  //----------------line_buffer_status--------------------------
	logic                        lb1_full;
	logic                        lb2_full;
	logic                        rd_en1;
	logic                        rd_en2;
  //----------------window_coordinate--------------------------
  logic                        i_valid_window;
	logic                        i_left_align;
	logic                        i_right_align;
	logic                        i_top_align;
	logic                        i_bot_align;
	logic                        window_err;
	logic [WIDTH_PIXEL:0]        x_cnt;	
  logic [WIDTH_PIXEL:0]        y_cnt;
	logic [WIDTH_PIXEL:0]        fill_cnt;   
  //----------------window_pixel--------------------------
	logic [WIDTH_PIXEL-1:0]      window_00, window_01, window_02;	// row 0
  logic [WIDTH_PIXEL-1:0]      window_10, window_11, window_12; 	// row 1
  logic [WIDTH_PIXEL-1:0]      window_20, window_21, window_22;	// row 2
	logic [8:0][WIDTH_PIXEL-1:0] compare_pixels;
  //----------------px_deviation--------------------------
	logic                   ge_vh;
	logic                   ge_lr;
	logic                   ge_dev;
  logic                   ge_threshold;
  logic                   is_noise;
  logic [WIDTH_PIXEL-1:0] vert_dev;
  logic [WIDTH_PIXEL-1:0] hor_dev;
  logic [WIDTH_PIXEL-1:0] crossleft_dev;
  logic [WIDTH_PIXEL-1:0] crossright_dev;
  logic [WIDTH_PIXEL-1:0] min_vh;
  logic [WIDTH_PIXEL-1:0] min_lr;
  logic [WIDTH_PIXEL-1:0] min_dev;
  //----------------pipeline--------------------------------
  stage1_dev_stage        stage1_reg, stage1_next;
  stage2_min_stage        stage2_reg, stage2_next;
  stage3_dec_stage        stage3_reg, stage3_next;
  logic [2:0]             valid_shift_reg; 
  logic [WIDTH_PIXEL-1:0] center_px_c1;
  logic [WIDTH_PIXEL-1:0] center_px_c2;
//===================================PIXEL_COORDINATE==================================================================
	always_ff @(posedge i_clk or negedge ni_rst) begin: pixel_coordinate
    if (~ni_rst) begin
      fill_cnt       <= '0;
      i_valid_window <= '0;
      x_cnt          <= '0;
      y_cnt          <= '0;
    end else if (i_ready) begin 
      if (~i_valid_window) begin
        if (fill_cnt == WIDTH + 1) begin // the first window of pixel need W+2 pixel to fullfill the window
          x_cnt          <= '0;
          y_cnt          <= '0;
          i_valid_window <= 1'b1;
        end else begin
          fill_cnt <= fill_cnt + 1'b1;
        end
      end else begin
        if (x_cnt == WIDTH-1) begin
          x_cnt <= '0;
          if (y_cnt == LENGTH - 1) begin
            y_cnt          <= '0;
            i_valid_window <= 1'b0;
            fill_cnt       <= '0;
          end else begin
            y_cnt <= y_cnt + 1'b1;
          end   
        end else begin
          x_cnt <= x_cnt + 1'b1;
        end
      end
    end
  end
  assign i_left_align  = (x_cnt == 0);
  assign i_right_align = (x_cnt == WIDTH - 1);
  assign i_top_align   = (y_cnt == 0);
  assign i_bot_align   = (y_cnt == LENGTH - 1);
	// line buffer read enable
	assign lb1_full      = (~i_valid_window & (fill_cnt >= (WIDTH - 1))) | i_valid_window;
	assign lb2_full      = (y_cnt > 0) | (i_valid_window & (y_cnt == 0) & (x_cnt >= (WIDTH - 3)));
	assign rd_en1        = i_ready & lb1_full;
	assign rd_en2        = i_ready & lb2_full;
	assign compare_start = i_valid_window & i_ready;
//==============MEDIAN_FINDING_INPUT====================================================================================
  always_comb begin
    compare_pixels[0] = window_00; compare_pixels[1] = window_01; compare_pixels[2] = window_02;
    compare_pixels[3] = window_10; compare_pixels[4] = window_11; compare_pixels[5] = window_12;
    compare_pixels[6] = window_20; compare_pixels[7] = window_21; compare_pixels[8] = window_22;
  end
//==============INSTANTIATION====================================================================================
	line_buffer #(
    .IMAGE_WIDTH(WIDTH)
  )image_storage (
		.i_clk        (i_clk),
		.ni_rst       (ni_rst),
		.i_ready      (i_ready),
		.i_left_align (i_left_align),
		.i_right_align(i_right_align),
		.i_top_align  (i_top_align),
		.i_bot_align  (i_bot_align),
		.i_pix        (i_pix),
		.o_cross_err  (window_err),
		.i_rd_en1     (rd_en1),
		.i_rd_en2     (rd_en2),
	  .window_00    (window_00), .window_01(window_01), .window_02(window_02),
    .window_10    (window_10), .window_11(window_11), .window_12(window_12),
    .window_20    (window_20), .window_21(window_21), .window_22(window_22) 
	);
  //------------MEDIAN_CALCULATED-------------------------------------------
  median_cal #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) median_finding (
    .i_clk         (i_clk),
    .ni_rst        (ni_rst),
    .i_valid       (compare_start),
    .compare_pixels(compare_pixels),
    .median_o      (median_o)
  );
//========================PIPELINE CONTROL====================================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin : valid_tracking_register
    if (~ni_rst) begin
      valid_shift_reg <= 3'b0;
    end else if (i_ready) begin
      valid_shift_reg <= {valid_shift_reg[1:0], compare_start}; 
    end
  end
  assign o_valid = valid_shift_reg[2]; // Ngõ ra Valid cuối cùng
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
//========================STAGE 1: LƯU ĐỘ LỆCH VÀ PIXEL GỐC================================================================
  always_comb begin : stage1_comb
    stage1_next.vert_abs   = vert_dev;
    stage1_next.hor_abs    = hor_dev;
    stage1_next.crossl_abs = crossleft_dev;
    stage1_next.crossr_abs = crossright_dev;
    stage1_next.center_px  = window_11;
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : stage1_register
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

  always_ff @(posedge i_clk or negedge ni_rst) begin : stage2_register
    if(~ni_rst) begin
      stage2_reg <= '0;
    end else if (valid_shift_reg[0] & i_ready) begin
      stage2_reg <= stage2_next;
    end
  end
  //-------------THRESHOLD_COMPARE--------------------------------
  tree_comp_8bit compare_threshold (
    .x_i (stage2_reg.min_all), 
    .y_i (threshold_i), 
    .ge_o(ge_threshold)
  );
  assign is_noise = ge_threshold ? 1'b1 : 1'b0;
  always_comb begin : stage3_comb
    stage3_next.noise_flag = is_noise;
    stage3_next.center_px  = stage2_reg.center_px;
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : stage3_register
    if(~ni_rst) begin
      stage3_reg <= '0;
    end else if (valid_shift_reg[1] & i_ready) begin
      stage3_reg <= stage3_next;
    end
  end
  //--------------MEDIAN_SWITCHING---------------------------------
  assign o_pix_median = stage3_reg.noise_flag ? median_o : stage3_reg.center_px;
endmodule