// Project         : Convolution with 4 kernels Sobel, Sharpen, Blur and Gaussian
// Module          : Convolution 
// File            : convolution.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 11/07/2026
// Updated date    : 25/10/2026
//=============================================================================================================
import package_param::*;
module convolution (
	input  logic                          i_clk,
	input  logic                          ni_rst,
	input  logic                          i_ready,
  input  logic  [8:0][WIDTH_KERNEL-1:0] mac_kernel,
	input  logic       [WIDTH_PIXEL-1:0]  i_pix,
	output logic       [WIDTH_MAC:0]      convolution_raw,          // 15bit
	output logic                          o_valid
);
	//==============DECLARATION=======================================================================================
  logic                        mac_enb;
  logic                        compare_start;
  logic                        mac_valid; 
	logic [8:0][WIDTH_PIXEL-1:0] mac_pixels;
	logic      [WIDTH_PIXEL-1:0] window_00, window_01, window_02;	// row 0
  logic      [WIDTH_PIXEL-1:0] window_10, window_11, window_12; // row 1
  logic      [WIDTH_PIXEL-1:0] window_20, window_21, window_22;	// row 2
	logic      [WIDTH_MAC:0]     mac_result;
  logic      [WIDTH_MAC:0]     mac_abs;  
  
//==============INSTANTIATION WINDOW GENERATOR====================================================================
  window_generator_3x3 image_coordinated (
    .i_clk          (i_clk),
    .ni_rst         (ni_rst),
    .i_ready        (i_ready),
    .i_pix          (i_pix),
    .o_valid_window (compare_start),
    .window_00      (window_00), .window_01(window_01), .window_02(window_02),
    .window_10      (window_10), .window_11(window_11), .window_12(window_12),
    .window_20      (window_20), .window_21(window_21), .window_22(window_22)
  );
//==============MAC_INPUT====================================================================================
  always_comb begin
    mac_pixels[0] = window_00; mac_pixels[1] = window_01; mac_pixels[2] = window_02;
    mac_pixels[3] = window_10; mac_pixels[4] = window_11; mac_pixels[5] = window_12;
    mac_pixels[6] = window_20; mac_pixels[7] = window_21; mac_pixels[8] = window_22;
  end
  mac mac (
    .i_clk      (i_clk),
    .ni_rst     (ni_rst),
    .mac_en_i   (compare_start),
    .opa_i      (mac_pixels),
    .opb_i      (mac_kernel),	
    .mac_valid_o(mac_valid),
    .mac_out    (mac_result)
	);
  assign convolution_raw = $signed(mac_result);
  assign o_valid = mac_valid;
endmodule