//=============================================================================================================
// Project         : ISP Sub-block Noise Reduction
// Module          : ISP Sub-block Noise Reduction
// File            : subblock_noise_reduction.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 15/09/2026
//=============================================================================================================
import package_param::*;
module subblock_noise_reduction #(
  parameter WIDTH_PIXEL = 8,      // 8bit for 1 pixel
  parameter WIDTH       = 256,    // Image Width
  parameter LENGTH      = 256     // Image Height
)(
  input  logic                   i_clk,
  input  logic                   ni_rst,
  input  logic                   i_ready,
  input  logic [WIDTH_PIXEL-1:0] threshold_i,
  input  logic [WIDTH_PIXEL-1:0] i_pix,
  output logic                   valid_o,
  output logic [WIDTH_PIXEL-1:0] pix_filt_o
);
  logic                   sm_valid_w;
  logic [WIDTH_PIXEL-1:0] sm_pix_w;
  logic                   bf_ready_w;

  switching_median #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH      (WIDTH),
    .LENGTH     (LENGTH)
  ) u_switching_median (
    .i_clk        (i_clk),
    .ni_rst       (ni_rst),
    .i_ready      (i_ready),
    .i_threshold  (threshold_i),
    .i_pix        (i_pix),
    .o_valid      (sm_valid_w),
    .o_pix_median (sm_pix_w)
  );
  // Điều khiển nhịp: Bilateral Filter chỉ được phép "nuốt" dữ liệu (shift pipeline) 
  // khi hệ thống đang ready VÀ bộ Median đã tính xong pixel hợp lệ.
  assign bf_ready_w = i_ready & sm_valid_w;
  bilateral_filter #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH      (WIDTH),
    .LENGTH     (LENGTH)
  ) u_bilateral_filter (
    .i_clk          (i_clk),
    .ni_rst         (ni_rst),
    .i_ready        (bf_ready_w),
    .i_pix          (sm_pix_w),
    .filter_valid_o (valid_o),
    .o_pix_filter   (pix_filt_o)
  );
endmodule