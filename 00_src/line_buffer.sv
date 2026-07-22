module line_buffer #(
  parameter IMAGE_WIDTH = 256
)(
  input  logic       i_clk,
  input  logic       ni_rst,
  input  logic       i_ready,
  input  logic       i_left_align,
  input  logic       i_right_align,
  input  logic       i_top_align,
  input  logic       i_bot_align,
  input  logic       i_rd_en1,
  input  logic       i_rd_en2,
  input  logic [7:0] i_pix,
  output logic       o_cross_err,
  output logic [7:0] window_00, window_01, window_02,   // row 0
  output logic [7:0] window_10, window_11, window_12,   // row 1
  output logic [7:0] window_20, window_21, window_22    // row 2
);
//========================== ĐỊNH NGHĨA THAM SỐ ĐỘNG ==========================
  localparam ADDR_W = $clog2(IMAGE_WIDTH);
//========================== INSTANTIATION ====================================
  logic              rd_en1, rd_en2;
  logic              wr_en2;
  logic [7:0]        pixel_out1, pixel_out2;
  logic [ADDR_W-1:0] cnt_cell; 
  logic [7:0]        o_p00, o_p01, o_p02;  // row 0
  logic [7:0]        o_p10, o_p11, o_p12;  // row 1
  logic [7:0]        o_p20, o_p21, o_p22;  // row 2
//========================== FIFO BỘ ĐỆM DÒNG =================================
  fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(ADDR_W)
  ) line_buffer1 (
    .i_clk  (i_clk),
    .ni_rst (ni_rst),
    .i_wren (i_ready),
    .i_rden (i_rd_en1),
    .wr_data(i_pix),
    .rd_data(pixel_out1)
  );
  fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(ADDR_W)
  ) line_buffer2 (
    .i_clk  (i_clk),
    .ni_rst (ni_rst),
    .i_wren (wr_en2),           // the lb1 can be read in T period but actually the data pushed in T+1 period so we need delay 1 clk 
    .i_rden (i_rd_en2),
    .wr_data(pixel_out1),
    .rd_data(pixel_out2)
  );
//========================== SHIFT REGISTER WINDOW ============================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      wr_en2 <= 1'b0;
    end else if (i_ready) begin
      wr_en2 <= i_rd_en1; 
    end
  end
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
//========================== ZERO PADDING =====================================
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
//========================== CROSS ERROR CHECK ================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      cnt_cell <= '0;
    end else if (i_ready) begin
      // Nâng cấp: Ép kiểu IMAGE_WIDTH về đúng số bit để tránh cảnh báo
      if (cnt_cell == IMAGE_WIDTH - 1) begin
        cnt_cell <= '0;
      end else begin
        cnt_cell <= cnt_cell + 1'b1;
      end
    end
  end
  always_comb begin
    // Nâng cấp: Sử dụng '0 và 'd1 thay vì fix cứng 8'd0 để tương thích mọi kích thước
    o_cross_err = (cnt_cell == '0) | (cnt_cell == 'd1);
  end 
endmodule