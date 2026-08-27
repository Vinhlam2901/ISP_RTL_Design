// Project         : Switching Median
// Module          : Median Finding 
// File            : finding_median.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/08/2026
// Updated date    : 24/08/2026
//=============================================================================================================
module finding_median #(
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
	input  logic      	           i_clk,
	input  logic      	           ni_rst,
	input  logic      	           i_ready,
	input  logic [WIDTH_PIXEL-1:0] i_pix,
	output logic [WIDTH_PIXEL-1:0] o_pix_median
	);
	//==============DECLARATION=======================================================================================
  logic                        compare_start;
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
  //----------------comparing--------------------------
  logic                        ge_m12, ge_m23, ge_m31;
  logic [1:0]                  final_med_sel;
	logic [2:0][WIDTH_PIXEL-1:0] min_stage1_o, med_stage1_o, max_stage1_o;
	logic [2:0][WIDTH_PIXEL-1:0] min_stage2_o, med_stage2_o, max_stage2_o;
	logic [8:0][WIDTH_PIXEL-1:0] compare_stage2;
  logic [WIDTH_PIXEL-1:0]      max_of_mins, med_of_meds, min_of_maxs;
//===================================PIXEL_COORDINATE==================================================================
	always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      fill_cnt       <= '0;
      i_valid_window <= 1'b0;
      x_cnt          <= '0;
      y_cnt          <= '0;
    end else if (i_ready) begin 
      if (~i_valid_window) begin
        if (fill_cnt == WIDTH + 1) begin // the first window of pixel need W+2 pixel to fullfill the window
          i_valid_window <= 1'b1;
          x_cnt          <= '0;
          y_cnt          <= '0;
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
  //------------------STAGE_1_COMPARE-----------------------------------------------------
  compare_row #(
    .WIDTH_PIXEL(WIDTH_PIXEL)
  ) compare_stage1 (
    .compare_pixels(compare_pixels),
    .min_o(min_stage1_o),
    .med_o(med_stage1_o),
    .max_o(max_stage1_o)
  );
  always_comb begin
    //------------CONCAT_MIN------------------------
    compare_stage2[0] = min_stage1_o[0];
    compare_stage2[1] = min_stage1_o[1];
    compare_stage2[2] = min_stage1_o[2];
    //------------CONCAT_MED------------------------
    compare_stage2[3] = med_stage1_o[0];
    compare_stage2[4] = med_stage1_o[1];
    compare_stage2[5] = med_stage1_o[2];
    //------------CONCAT_MAX------------------------
    compare_stage2[6] = max_stage1_o[0];
    compare_stage2[7] = max_stage1_o[1];
    compare_stage2[8] = max_stage1_o[2];
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
//------------------STAGE 3---------------------------------------------------------
  assign max_of_mins = max_stage2_o[0];
  assign med_of_meds = med_stage2_o[1];
  assign min_of_maxs = min_stage2_o[2];
  tree_comp_8bit comp_m12 (.x_i(max_of_mins), .y_i(med_of_meds), .ge_o(ge_m12));
  tree_comp_8bit comp_m23 (.x_i(med_of_meds), .y_i(min_of_maxs), .ge_o(ge_m23));
  tree_comp_8bit comp_m31 (.x_i(min_of_maxs), .y_i(max_of_mins), .ge_o(ge_m31));
  always_comb begin
    final_med_sel = {{(ge_m12 ^ ge_m23) | ~(ge_m23 ^ ge_m31)}, {~(ge_m12 ^ ge_m23) | (ge_m23 ^ ge_m31)}};
    case (final_med_sel)
      2'b00:   o_pix_median = max_of_mins; 
      2'b01:   o_pix_median = med_of_meds; 
      2'b10:   o_pix_median = min_of_maxs; 
      default: o_pix_median = '0;
    endcase
  end
endmodule