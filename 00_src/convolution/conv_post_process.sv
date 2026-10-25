  
//=============================================================================================================
// Project         : Convolution
// Module          : Convolution Post Processing
// File            : conv_post_processing.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 09/09/2026
//=============================================================================================================
import package_param::*;
module conv_post_processing (
  input  logic                                mac_valid,         
  input  logic        [8:0][WIDTH_KERNEL-1:0] mac_kernel,          
  input  logic signed      [WIDTH_MAC-1:0]    mac_extended,            
  output logic             [WIDTH_PIXEL-1:0]  o_conv               
);
//==============DECLARATION=======================================================================================
  logic [WIDTH_MAC-1:0] mac_scaled;
  
//==============MAC_POST_PROCESSING===============================================================================
  always_comb begin : post_processing_sharpening
    mac_scaled = '0;
    
    // 1. SHARPENING CLAMPING: Cắt phần âm về 0, giữ nguyên phần dương
    if (mac_extended < 0) begin
      mac_scaled = '0;
    end else begin
      mac_scaled = mac_extended;
    end
    
    // 2. SATURATION: Giới hạn ngưỡng tối đa là 255
    if (mac_valid) begin
      if (mac_scaled >= 15'd255) begin   // Đã sửa thành >= và dùng 15-bit cho khớp WIDTH_MAC
        o_conv = 8'd255;
      end else begin
        o_conv = mac_scaled[7:0];
      end
    end else begin
      o_conv = 8'd0;
    end
  end
endmodule