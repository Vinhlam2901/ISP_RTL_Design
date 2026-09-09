module switching_median_tb;
  // Khai báo tham số (Thu nhỏ kích thước ảnh để test nhanh)
  parameter WIDTH_PIXEL = 8;
  parameter TEST_WIDTH  = 20;
  parameter TEST_LENGTH = 20;
  // Khai báo tín hiệu
  logic                   clk;
  logic                   rst_n;
  logic                   ready_i;
  logic [WIDTH_PIXEL-1:0] threshold;
  logic [WIDTH_PIXEL-1:0] pixel_in;
  logic [WIDTH_PIXEL-1:0] pixel_out;
  logic                   valid_out;
  int out_x;
  int out_y;
  int error_cnt;
  // Instantiate module Switching Median
  switching_median #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH(TEST_WIDTH),
    .LENGTH(TEST_LENGTH)
  ) dut (
    .i_clk(clk),
    .ni_rst(rst_n),
    .i_ready(ready_i),
    .threshold_i(threshold),
    .i_pix(pixel_in),
    .o_pix_median(pixel_out),
    .o_valid(valid_out)
  );
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, switching_median_tb); 
  end
  //========================================================
  // 1. Tạo xung nhịp Clock (100MHz -> Chu kỳ 10ns)
  //========================================================
  initial begin
    clk = 0;
    forever #5 clk = ~clk; 
  end
 //========================================================
  // 2. Kịch bản Mô phỏng (Stimulus)
  //========================================================
  initial begin
    rst_n     = 0;
    ready_i   = 0;
    threshold = 8'd30; // Ngưỡng phát hiện nhiễu
    pixel_in  = 0;
    #20;
    rst_n = 1;
    #10;
    ready_i = 1;
for (int y = 0; y < TEST_LENGTH; y++) begin
      for (int x = 0; x < TEST_WIDTH; x++) begin
        @(posedge clk); 
        // ---------------------------------------------------
        // CÁC TESTCASE NHIỄU (GÓC CHẾT VÀ DÍNH CHÙM)
        // ---------------------------------------------------
        // 1. Nhiễu đơn lẻ (Isolated Noise)
        if      (x == 2 && y == 2) pixel_in = 8'd255; 
        else if (x == 5 && y == 5) pixel_in = 8'd0;   
        // 2. Nhiễu đôi nằm ngang (Horizontal Pair)
        else if (x == 7 && y == 8) pixel_in = 8'd255;
        else if (x == 8 && y == 8) pixel_in = 8'd255;
        // 3. Nhiễu đôi nằm dọc (Vertical Pair)
        else if (x == 12 && y == 10) pixel_in = 8'd0;
        else if (x == 12 && y == 11) pixel_in = 8'd0;
        // 4. Nhiễu đôi chéo nhau - Trộn Muối & Tiêu (Diagonal Mixed Pair)
        else if (x == 15 && y == 4) pixel_in = 8'd255;
        else if (x == 16 && y == 5) pixel_in = 8'd0;
        // 5. Nhiễu chùm 3 điểm hình chữ L (L-shape Cluster 3 pixels)
        // Cụm này sẽ ép mạng sắp xếp 9 phần tử của bạn hoạt động tối đa công suất!
        else if (x == 16 && y == 16) pixel_in = 8'd255;
        else if (x == 17 && y == 16) pixel_in = 8'd255;
        else if (x == 16 && y == 17) pixel_in = 8'd255;
        
        // Nền chuẩn
        else pixel_in = 8'd100; 
      end
    end
    // Bơm pixel rác để xả Pipeline
    for (int i = 0; i < 20; i++) begin
      @(posedge clk);
      pixel_in = 8'd0;
    end
    #50;
    $display("\n========================================");
    $display("           SIMULATION REPORT            ");
    $display("========================================");
    if (error_cnt == 0)
      $display(" RESULT: PASS (0 Errors found)"); 
    else
      $display(" RESULT: FAIL (%0d Errors found)", error_cnt); 
    $display("========================================\n");
    $finish;
  end
//========================================================
  // 3. Monitor & Tự động kiểm tra (Self-checking)
  //========================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      out_x     <= 0;
      out_y     <= 0;
      error_cnt <= 0;
    end 
    else if (valid_out && out_y < TEST_LENGTH) begin
      logic is_noisy_px;
      logic [WIDTH_PIXEL-1:0] original_noise;
      
      // Khởi tạo mặc định
      is_noisy_px = 1'b0;
      original_noise = 8'd0;

      // 1. Nhiễu đơn lẻ
      if      (out_x == 2 && out_y == 2)   {is_noisy_px, original_noise} = {1'b1, 8'd255};
      else if (out_x == 5 && out_y == 5)   {is_noisy_px, original_noise} = {1'b1, 8'd0};
      
      // 2. Nhiễu đôi nằm ngang
      else if (out_x == 7 && out_y == 8)   {is_noisy_px, original_noise} = {1'b1, 8'd255};
      else if (out_x == 8 && out_y == 8)   {is_noisy_px, original_noise} = {1'b1, 8'd255};
      
      // 3. Nhiễu đôi nằm dọc
      else if (out_x == 12 && out_y == 10) {is_noisy_px, original_noise} = {1'b1, 8'd0};
      else if (out_x == 12 && out_y == 11) {is_noisy_px, original_noise} = {1'b1, 8'd0};
      
      // 4. Nhiễu đôi chéo nhau
      else if (out_x == 15 && out_y == 4)  {is_noisy_px, original_noise} = {1'b1, 8'd255};
      else if (out_x == 16 && out_y == 5)  {is_noisy_px, original_noise} = {1'b1, 8'd0};
      
      // 5. Nhiễu chùm 3 điểm hình chữ L
      else if (out_x == 16 && out_y == 16) {is_noisy_px, original_noise} = {1'b1, 8'd255};
      else if (out_x == 17 && out_y == 16) {is_noisy_px, original_noise} = {1'b1, 8'd255};
      else if (out_x == 16 && out_y == 17) {is_noisy_px, original_noise} = {1'b1, 8'd255};

      // In Log và đếm lỗi
      if (is_noisy_px) begin
        if (out_x == 0 || out_x == TEST_WIDTH-1 || out_y == 0 || out_y == TEST_LENGTH-1) begin
           $display("[WARN] Time: %0t | Coord (%0d,%0d) | Noise = %3d | Output = %3d (Ignored - Border)", 
                    $time, out_x, out_y, original_noise, pixel_out);
        end 
        else begin
          if (pixel_out !== 8'd100) begin
            $display("[FAIL] Time: %0t | Coord (%0d,%0d) | Noise = %3d -> Output = %3d (EXPECTED 100)", 
                     $time, out_x, out_y, original_noise, pixel_out);
            error_cnt <= error_cnt + 1;
          end else begin
            $display("[PASS] Time: %0t | Coord (%0d,%0d) | Noise = %3d -> Output = %3d (Recovered)", 
                     $time, out_x, out_y, original_noise, pixel_out);
          end
        end
      end

      // Cập nhật tọa độ
      if (out_x == TEST_WIDTH - 1) begin
        out_x <= 0;
        out_y <= out_y + 1;
      end else begin
        out_x <= out_x + 1;
      end
    end
  end
endmodule