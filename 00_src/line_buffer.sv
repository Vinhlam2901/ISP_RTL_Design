//===========================================================================================================
// Project         : Convolution
// Module          : Line Buffer & Shift Register
// File            : line_buffer.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 11/07/2026
// Updated date    : 11/07/2026
//=============================================================================================================
module line_buffer (
	input  wire       i_clk,
	input  wire       ni_rst,
	input  wire       i_ready,
	input  wire       i_left_align,
	input  wire       i_right_align,
	input  wire       i_top_align,
	input  wire       i_bot_align,
	input  wire       i_rd_en1,
	input  wire       i_rd_en2,
	input  wire [7:0] i_pix,
	output reg        o_cross_err,
	output reg [7:0]  window_00, window_01, window_02,	// row 0
  output reg [7:0]  window_10, window_11, window_12, 	// row 1
  output reg [7:0]  window_20, window_21, window_22 	// row 2
);
//==========================INSTANTIATION==========================================================================
  localparam IMAGE_WIDTH = 256;
	wire       rd_en1, rd_en2;
	wire [7:0] pixel_out1, pixel_out2;
  reg  [7:0] cnt_cell;
	reg  [7:0] o_p00, o_p01, o_p02;		// row 0
  reg  [7:0] o_p10, o_p11, o_p12; 	// row 1
  reg  [7:0] o_p20, o_p21, o_p22; 	// row 2
//==========================INSTANTIATION==========================================================================
	fifo #(
		.DATA_WIDTH(8),
		.ADDR_WIDTH(8)  					// 256x256 image
	)line_buffer1 (
		.i_clk  (i_clk),
		.ni_rst (ni_rst),
		.i_wren (i_ready),
		.i_rden (i_rd_en1),
		.wr_data(i_pix),
		.rd_data(pixel_out1)
	);
	fifo #(
		.DATA_WIDTH(8),
		.ADDR_WIDTH(8)  					// 256x256 image
	)line_buffer2 (
		.i_clk  (i_clk),
		.ni_rst (ni_rst),
		.i_wren (i_rd_en1),				// when rd_en1 = 1 -> line 1 is ready to send data to line 2
		.i_rden (i_rd_en2),
		.wr_data(pixel_out1),
		.rd_data(pixel_out2)
	);
//==========================SHIFT_REGISTER_WINDOW==========================================================================
	always_ff @(posedge i_clk or negedge ni_rst) begin
		if (~ni_rst) begin
			{o_p00, o_p01, o_p02, 
		   o_p10, o_p11, o_p12, 
			 o_p20, o_p21, o_p22} <= '0;
    end else if (i_ready) begin
      o_p00 <= o_p01; o_p01 <= o_p02; o_p02 <= pixel_out2; 
      o_p10 <= o_p11; o_p11 <= o_p12; o_p12 <= pixel_out1;  
      o_p20 <= o_p21; o_p21 <= o_p22; o_p22 <= i_pix;
    end
  end
//==========================ZERO_PADDING=============================================================================
  always_comb begin
    window_00 = (i_top_align | i_left_align)  ? 8'b0 : o_p00;
    window_01 =  i_top_align                  ? 8'b0 : o_p01;
    window_02 = (i_top_align | i_right_align) ? 8'b0 : o_p02;
    window_10 =  i_left_align                 ? 8'b0 : o_p10;
    window_11 =                                        o_p11;
    window_12 =  i_right_align                ? 8'b0 : o_p12;
    window_20 = (i_bot_align | i_left_align)  ? 8'b0 : o_p20;
    window_21 =  i_bot_align                  ? 8'b0 : o_p21;
    window_22 = (i_bot_align | i_right_align) ? 8'b0 : o_p22;
  end
//==================CROSS_ERROR_CHECK==================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      cnt_cell <= 8'b0;
    end else if (i_ready) begin
      if (cnt_cell == IMAGE_WIDTH - 1) begin
        cnt_cell <= 8'b0;
      end else begin
        cnt_cell <= cnt_cell + 1'b1;
      end
    end
  end
  always_comb begin
		o_cross_err = (cnt_cell == 8'd0) | (cnt_cell == 8'd1);
	end 
endmodule