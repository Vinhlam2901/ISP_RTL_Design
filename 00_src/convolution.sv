// Project         : Convolution with 4 kernels Sobel, Sharpen, Blur and Gaussian
// Module          : Convolution 
// File            : convolution.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 11/07/2026
// Updated date    : 11/09/2026
//=============================================================================================================
module convolution #(
  parameter WIDTH_MAC      = 12,
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH_KERNEL   = 4,      // 4bit for kernel's coefficiency from [-8:7]
  parameter GUARD_BIT      = 3,      // guard bit = log2(WIDTH_MAC)             
	parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
	input  logic                                    i_clk,
	input  logic                                    ni_rst,
	input  logic                                    i_ready,
  input  logic  [WIDTH_PIXEL:0][WIDTH_KERNEL-1:0] mac_kernel,
	input  logic  [WIDTH_PIXEL-1:0]                 i_pix,
	output logic  [(WIDTH_MAC+GUARD_BIT)-1:0]       convolution_raw,
	output logic                                    o_valid
);
	//==============DECLARATION=======================================================================================
  logic                                    mac_enb;
  logic                                    mac_valid; 
	logic [WIDTH_PIXEL:0][7:0]               mac_pixels;
	logic [WIDTH_PIXEL-1:0]                  window_00, window_01, window_02;	// row 0
  logic [WIDTH_PIXEL-1:0]                  window_10, window_11, window_12; 	// row 1
  logic [WIDTH_PIXEL-1:0]                  window_20, window_21, window_22;	// row 2
	logic [(WIDTH_MAC+GUARD_BIT)-1:0]        mac_result;
  logic [(WIDTH_MAC+GUARD_BIT)-1:0]        mac_abs;  
  logic [(WIDTH_MAC+GUARD_BIT)-1:0]        mac_scaled;
  
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
//==============MAC_INPUT====================================================================================
  always_comb begin
    mac_pixels[0] = window_00; mac_pixels[1] = window_01; mac_pixels[2] = window_02;
    mac_pixels[3] = window_10; mac_pixels[4] = window_11; mac_pixels[5] = window_12;
    mac_pixels[6] = window_20; mac_pixels[7] = window_21; mac_pixels[8] = window_22;
  end
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
  assign convolution_raw = $signed(mac_result);
  assign o_valid = mac_valid;
endmodule