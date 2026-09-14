//=============================================================================================================
// Project         : ISP SUB-BLOCK IMAGE DENOISE
// Module          : Window Generator 3x3
// File            : window_generator_3x3.sv
// Author          : Chau Tran Vinh Lam
// Create date     : 09/09/2026
// Updated date    : 10/09/2026
//=============================================================================================================
import package_param::*;

module window_generator_3x3 #(
  parameter WIDTH_PIXEL    = 8,
  parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
  input  logic                   i_clk,
  input  logic                   ni_rst,
  input  logic                   i_ready,
  input  logic [WIDTH_PIXEL-1:0] i_pix,
  output logic                   o_valid_window,
  output logic [WIDTH_PIXEL-1:0] window_00, window_01, window_02,
  output logic [WIDTH_PIXEL-1:0] window_10, window_11, window_12,
  output logic [WIDTH_PIXEL-1:0] window_20, window_21, window_22
);
//==============DECLARATION====================================================
  logic                   lb1_full, lb2_full;
  logic                   rd_en1, rd_en2;
  logic                   i_valid_window;
  logic                   i_left_align, i_right_align, i_top_align, i_bot_align;
  logic                   window_err;
  logic [WIDTH_PIXEL:0]   x_cnt, y_cnt, fill_cnt;   

//==============PIXEL COORDINATE LOGIC=========================================
  always_ff @(posedge i_clk or negedge ni_rst) begin: pixel_coordinate
    if (~ni_rst) begin
      fill_cnt       <= '0;
      i_valid_window <= '0;
      x_cnt          <= '0;
      y_cnt          <= '0;
    end else if (i_ready) begin 
      if (~i_valid_window) begin
        if (fill_cnt == WIDTH + 1) begin
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
  assign o_valid_window = i_valid_window & i_ready;
  // Line buffer read enable)
  assign lb1_full = (~i_valid_window & (fill_cnt >= (WIDTH - 1))) | i_valid_window;
  assign lb2_full = (y_cnt > 0) | (i_valid_window & (y_cnt == 0) & (x_cnt >= (WIDTH - 3)));
  assign rd_en1   = i_ready & lb1_full;
  assign rd_en2   = i_ready & lb2_full;
//==============LINE_BUFFER_INSTANTIATION======================================
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
endmodule