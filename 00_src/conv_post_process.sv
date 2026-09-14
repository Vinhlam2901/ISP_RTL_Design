  
//=============================================================================================================
// Project         : Convolution
// Module          : Convolution Post Processing
// File            : conv_post_processing.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 09/09/2026
//=============================================================================================================
import package_param::*;
module conv_post_processing #(
  parameter WIDTH_PIXEL    = 8,      // 8bit for 1 pixel
  parameter WIDTH_MAC      = 12,
  parameter WIDTH_KERNEL   = 4,      // 4bit for kernel's coefficiency from [-8:7]
  parameter GUARD_BIT      = 3,      // guard bit = log2(WIDTH_MAC)             
  parameter GAUSSIAN_SHIFT = 4,      // sum of coefficiens of gaussian kernel is 16
  parameter WIDTH          = 256,
  parameter LENGTH         = 256
)(
  input  logic                                          mac_valid,
  input  logic        [WIDTH_PIXEL:0][WIDTH_KERNEL-1:0] mac_kernel,
  input  logic signed [(WIDTH_MAC+GUARD_BIT)-1:0]       mac_extended,
  output logic        [(WIDTH_MAC+GUARD_BIT)-1:0]       o_conv
);
//==============DECLARATION=======================================================================================
  logic [(WIDTH_MAC+GUARD_BIT)-1:0] mac_scaled;
  logic [(WIDTH_MAC+GUARD_BIT)-1:0] mac_abs;  
//==============MAC_POST_PROCESSING====================================================================
  always_comb begin : post_processing
    mac_abs    = '0;
    mac_scaled = '0;
    if (mac_kernel[4] == 4'd1) begin                                                                // blur
      // mac_scaled = ((mac_extended << 4) + (mac_extended << 3) + (mac_extended << 2)) >> 8
      // 28/256 =16/256 + 8/256 +4/256 = 1/16 +1/32 +1/64
      mac_scaled = {4'b0, mac_extended[15:4]} + {5'b0, mac_extended[15:5]} + {6'b0, mac_extended[15:6]};  // divided to 9
    end else if (mac_kernel[4] == 4'd4) begin                                                       // gaussian
      mac_scaled = {{GAUSSIAN_SHIFT{mac_extended[15]}}, mac_extended[15:4]};
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
        o_conv = 8'd0;
      end else if (mac_scaled > 20'd255) begin
        o_conv = 8'd255;
      end else begin
        o_conv = mac_scaled[7:0];
      end
    end else begin
      o_conv = 8'd0;
    end
  end
endmodule