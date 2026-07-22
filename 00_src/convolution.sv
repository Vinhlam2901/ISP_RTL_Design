// Project         : Convolution with 4 kernels Sobel, Sharpen, Blur and Gaussian
// Module          : Convolution 
// File            : convolution.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 11/07/2026
// Updated date    : 18/07/2026
//=============================================================================================================
module convolution #(
  parameter WIDTH_MAC      = 12,
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH_KERNEL   = 4,      // 4bit for kernel's coefficiency from [-8:7]
  parameter GUARD_BIT      = 3,      // guard bit = log2(WIDTH_MAC)             
	parameter WIDTH          = 256,
  parameter LENGTH         = 256,
  parameter GAUSSIAN_SHIFT = 4       // sum of coefficiens of gaussian kernel is 16
)(
	input  logic      	                           i_clk,
	input  logic      	                           ni_rst,
	input  logic      	                           i_ready,
  input  logic [WIDTH_PIXEL:0][WIDTH_KERNEL-1:0] mac_kernel,
	input  logic [WIDTH_PIXEL-1:0]                 i_pix,
	output logic [WIDTH_PIXEL-1:0]                 o_pix_conv,
	output                                         o_valid
	);
	//==============DECLARATION=======================================================================================
  logic                                    mac_enb;
  logic                                    i_valid_window;
	logic                                    i_left_align;
	logic                                    i_right_align;
	logic                                    i_top_align;
	logic                                    i_bot_align;
	logic                                    window_err;
	logic                                    lb1_full;
	logic                                    lb2_full;
	logic                                    rd_en1;
	logic                                    rd_en2;
  logic                                    mac_valid;
	logic [WIDTH_PIXEL:0]                    x_cnt;	
  logic [WIDTH_PIXEL:0]                    y_cnt;
	logic [WIDTH_PIXEL:0]                    fill_cnt;   
	logic [WIDTH_PIXEL:0][7:0]               mac_pixels;
	logic [WIDTH_PIXEL-1:0]                  window_00, window_01, window_02;	// row 0
  logic [WIDTH_PIXEL-1:0]                  window_10, window_11, window_12; 	// row 1
  logic [WIDTH_PIXEL-1:0]                  window_20, window_21, window_22;	// row 2
	logic [(WIDTH_MAC+GUARD_BIT)-1:0]        mac_result;
  logic [(WIDTH_MAC+GUARD_BIT)-1:0]        mac_abs;  
  logic [(WIDTH_MAC+GUARD_BIT)-1:0]        mac_scaled;
  logic signed [(WIDTH_MAC+GUARD_BIT)-1:0] mac_extended;
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
	assign mac_enb       = i_valid_window & i_ready;
//==============MAC_INPUT====================================================================================
  always_comb begin
    mac_pixels[0] = window_00; mac_pixels[1] = window_01; mac_pixels[2] = window_02;
    mac_pixels[3] = window_10; mac_pixels[4] = window_11; mac_pixels[5] = window_12;
    mac_pixels[6] = window_20; mac_pixels[7] = window_21; mac_pixels[8] = window_22;
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
	mac #(
    .WIDTH_MAC(WIDTH_MAC),
    .WIDTH_OPA(WIDTH_PIXEL),
    .WIDTH_OPB(WIDTH_KERNEL),
    .GUARD_BIT(GUARD_BIT)
  ) mac (
		.i_clk      (i_clk),
		.ni_rst     (ni_rst),
		.mac_en_i   (mac_enb),
		.opa_i      (mac_pixels),
		.opb_i      (mac_kernel),	
		.mac_valid_o(mac_valid),
		.mac_out    (mac_result)
	);
  assign mac_extended = $signed(mac_result);
  always_comb begin : post_processing
    mac_abs    = '0;
    mac_scaled = '0;
    o_pix_conv = '0;
    if (mac_kernel[4] == 4'd1) begin                                                                // blur
      // mac_scaled = ((mac_extended << 4) + (mac_extended << 3) + (mac_extended << 2)) >> 8
      // 28/256 =16/256 + 8/256 +4/256 = 1/16 +1/32 +1/64
      mac_scaled = {4'b0, mac_result[14:4]} + {5'b0, mac_result[14:5]} + {6'b0, mac_result[14:6]};  // divided to 9
    end else if (mac_kernel[4] == 4'd4) begin                                                       // gaussian
      mac_scaled = {{GAUSSIAN_SHIFT{mac_result[14]}}, mac_result[14:4]};
    end else begin
      if (mac_extended < 0) begin
        mac_abs = (~mac_extended + 1);
      end else begin
        mac_abs = mac_extended;
      end
      mac_scaled = mac_abs;
    end
    if (mac_valid) begin                    // saturation
      if (^mac_scaled === 1'bx) begin
        o_pix_conv = 8'd0;
      end else if (mac_scaled > 20'd255) begin
        o_pix_conv = 8'd255;
      end else begin
        o_pix_conv = mac_scaled[7:0];
      end
    end else begin
      o_pix_conv = 8'd0;
    end
  end
  assign o_valid = mac_valid;
endmodule