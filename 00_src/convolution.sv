// Project         : Convolution
// Module          : Convolution
// File            : convolution.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 11/07/2026
// Updated date    : 11/07/2026
//=============================================================================================================
module convolution (
	input  logic      	i_clk,
	input  logic      	ni_rst,
	input  logic      	i_ready,
	input  logic [7:0] i_pix,
	output logic [7:0] o_pix_conv
	);
	//==============DECLARATION=======================================================================================
	localparam WIDTH = 256;
  localparam LENGTH = 256;
  logic            mac_enb;
  logic            i_valid_window;
	logic            i_left_align;
	logic            i_right_align;
	logic            i_top_align;
	logic            i_bot_align;
	logic            window_err;
	logic            lb1_full;
	logic            lb2_full;
  logic            mac_valid;
	logic [19:0]     mac_result;
	logic [8:0]      x_cnt;	
  logic [8:0]      y_cnt;
	logic [8:0]      fill_cnt;   
	logic [8:0][7:0] mac_pixels;
  logic [8:0][7:0] mac_kernel;
	logic [7:0]      window_00, window_01, window_02;	// row 0
  logic [7:0]      window_10, window_11, window_12; 	// row 1
  logic [7:0]      window_20, window_21, window_22;	// row 2
//===================================PIXEL_COORDINATE==================================================================
	always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      fill_cnt       <= '0;
      i_valid_window <= 1'b0;
      x_cnt          <= '0;
      y_cnt          <= '0;
    end else if (i_ready) begin 
      if (~i_valid_window) begin
        if (fill_cnt == WIDTH + 1) begin // Khi đếm từ 0 đến W là đủ W+2 nhịp
          i_valid_window <= 1'b1;
          x_cnt          <= '0;
          y_cnt          <= '0;
        end else begin
          fill_cnt <= fill_cnt + 1'b1;
        end
      end else begin
        if (x_cnt == WIDTH - 1) begin
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
	assign lb1_full = i_valid_window;
	assign lb2_full = (y_cnt > 0) & i_valid_window;
	assign rd_en1 = i_ready & lb1_full;
	assign rd_en2 = i_ready & lb2_full;
	assign mac_enb = i_valid_window & i_ready & (~window_err);
//==============MAC_INPUT====================================================================================
  always_comb begin
    mac_pixels[0] = window_00; mac_pixels[1] = window_01; mac_pixels[2] = window_02;
    mac_pixels[3] = window_10; mac_pixels[4] = window_11; mac_pixels[5] = window_12;
    mac_pixels[6] = window_20; mac_pixels[7] = window_21; mac_pixels[8] = window_22;
  end
	// opb is a kernel 3x3
  always_comb begin
    mac_kernel[0] = 8'd1; mac_kernel[1] = 8'd1; mac_kernel[2] = 8'd1;
    mac_kernel[3] = 8'd1; mac_kernel[4] = 8'd1; mac_kernel[5] = 8'd1;
    mac_kernel[6] = 8'd1; mac_kernel[7] = 8'd1; mac_kernel[8] = 8'd1;
  end
//==============MAC_OUTPUT====================================================================================

//==============INSTANTIATION====================================================================================
	line_buffer image_storage (
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

	mac mac (
		.i_clk (i_clk),
		.ni_rst(ni_rst),
		.mac_en_i(mac_enb),
		.opa_i(mac_pixels),
		.opb_i(mac_kernel),	
		.mac_valid_o(mac_valid),
		.mac_out(mac_result)
	);
endmodule