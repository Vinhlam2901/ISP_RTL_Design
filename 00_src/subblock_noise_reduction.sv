// Project         : Sub Block ISP - Noise Reduction
// Module          : Noise Reduction 
// File            : subblock_noise_reduction.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 25/10/2026
// Updated date    : 25/10/2026
//=============================================================================================================
import package_param::*;

module subblock_noise_reduction (
  input  logic                   i_clk,
  input  logic                   ni_rst,
  input  logic                   i_ready,
  input  logic [WIDTH_PIXEL-1:0] threshold_i,
  input  logic [WIDTH_PIXEL-1:0] i_pix,
  output logic                   valid_o,
  output logic [WIDTH_PIXEL-1:0] pix_filt_o
);
//===============DECLARATION=======================
  // Kernel Sharpening cố định {0, -1, 0, -1, 5, -1, 0, -1, 0}
  // Dùng 4-bit (có dấu) tương ứng: 0 = 4'b0000, -1 = 4'b1111, 5 = 4'b0101
  localparam logic [8:0][WIDTH_KERNEL-1:0] SHARPEN_KERNEL = {
    4'b0000, 4'b1111, 4'b0000,
    4'b1111, 4'b0101, 4'b1111,
    4'b0000, 4'b1111, 4'b0000
  };
//===============INSTANTITATION========================
  logic                   sm_valid_w;
  logic [WIDTH_PIXEL-1:0] sm_pix_w;
  logic                   bf_ready_w;
  logic                   bf_valid_w;
  logic [WIDTH_PIXEL-1:0] bf_pix_w;
  logic                   conv_ready_w;
  logic [WIDTH_MAC:0]     conv_raw_w;
  logic                   conv_valid_w;
//===============1. MEDIAN FILTER=======================
  switching_median u_switching_median (
    .i_clk        (i_clk),
    .ni_rst       (ni_rst),
    .i_ready      (i_ready),
    .i_threshold  (threshold_i),
    .i_pix        (i_pix),
    .o_valid      (sm_valid_w),
    .o_pix_median (sm_pix_w)
  );
//===============2. BILATERAL FILTER====================
  // Bilateral chỉ nhận dữ liệu khi Median đã xuất ra hợp lệ
  assign bf_ready_w = i_ready & sm_valid_w;
  bilateral_filter u_bilateral_filter (
    .i_clk          (i_clk),
    .ni_rst         (ni_rst),
    .i_ready        (bf_ready_w),
    .i_pix          (sm_pix_w),
    .filter_valid_o (bf_valid_w),
    .o_pix_filter   (bf_pix_w)
  );
//===============3. CONVOLUTION (SHARPENING)============
  // Convolution chỉ chạy khi Bilateral đã xuất dữ liệu hợp lệ
  assign conv_ready_w = i_ready & bf_valid_w;
  convolution u_convolution (
    .i_clk           (i_clk),
    .ni_rst          (ni_rst),
    .i_ready         (conv_ready_w),
    .mac_kernel      (SHARPEN_KERNEL),  // Truyền cứng kernel Sharpening vào
    .i_pix           (bf_pix_w),        // Lấy ảnh đã lọc từ Bilateral
    .convolution_raw (conv_raw_w),      // Dữ liệu thô 15-bit (có dấu)
    .o_valid         (conv_valid_w)
  );
//===============4. POST PROCESSING ====================
  conv_post_processing u_post_processing (
    .mac_valid       (conv_valid_w),
    .mac_kernel      (SHARPEN_KERNEL),
    .mac_extended    (conv_raw_w),
    .o_conv          (pix_filt_o)       // Ngõ ra cuối cùng 8-bit của toàn bộ module
  );
  // Tín hiệu valid cuối cùng của toàn bộ block
  assign valid_o = conv_valid_w;
endmodule