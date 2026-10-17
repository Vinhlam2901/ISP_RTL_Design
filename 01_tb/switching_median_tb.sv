module switching_median_tb;
  //========================================================
  // 1. PARAMETERS & SIGNALS
  //========================================================
  parameter WIDTH_PIXEL = 8;
  parameter TEST_WIDTH  = 64; // Kích thước đủ lớn để test Line Buffer
  parameter TEST_LENGTH = 64;

  logic                   clk;
  logic                   rst_n;
  logic                   ready_i;
  logic [WIDTH_PIXEL-1:0] threshold;
  logic [WIDTH_PIXEL-1:0] pixel_in;
  
  logic                   valid_out;
  logic [WIDTH_PIXEL-1:0] pixel_out;
  
  int out_x, out_y;
  int error_cnt, valid_rx_cnt;

  // Khai báo 2 mảng: 1 mảng chứa ảnh gốc (Golden), 1 mảng chứa ảnh đã bị chèn nhiễu
  logic [7:0] golden_image [0:TEST_LENGTH-1][0:TEST_WIDTH-1];
  logic [7:0] noisy_image  [0:TEST_LENGTH-1][0:TEST_WIDTH-1];

  //========================================================
  // 2. INSTANTIATE DUT
  //========================================================
  switching_median #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH(TEST_WIDTH),
    .LENGTH(TEST_LENGTH)
  ) dut (
    .i_clk       (clk),
    .ni_rst      (rst_n),
    .i_ready     (ready_i),
    .i_threshold (threshold),
    .i_pix       (pixel_in),
    .o_valid     (valid_out),
    .o_pix_median(pixel_out)
  );

  //========================================================
  // 3. CLOCK GENERATION
  //========================================================
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, switching_median_tb); 
  end
  //========================================================
  // 4. MAIN STIMULUS (KỊCH BẢN TEST)
  //========================================================
  initial begin
    // Khởi tạo các tín hiệu
    rst_n     = 0;
    ready_i   = 0;
    threshold = 8'd100; // Ngưỡng 40 để an toàn với Gradient (độ chênh lệch giữa các hàng)
    pixel_in  = 0;
    #25; 
    rst_n = 1;
    #10;
//---------------------------------------------------------
    // TESTCASE: REALISTIC RANDOM SALT & PEPPER NOISE (10% DENSITY)
    //---------------------------------------------------------
    $display("\n[INFO] Khởi tạo Testcase: Rắc nhiễu muối tiêu ngẫu nhiên (10%%)...");
    for (int y = 0; y < TEST_LENGTH; y++) begin
      for (int x = 0; x < TEST_WIDTH; x++) begin
        int rand_val;
        // 1. Tạo nền ảnh (Dùng nền trơn 100 để dễ quan sát nhiễu)
        golden_image[y][x] = 8'd100; 
        // 2. Quay xổ số ngẫu nhiên từ 0 đến 99
        rand_val = $urandom_range(0, 99);     
        // 3. Rắc nhiễu theo xác suất
        if (rand_val < 30) begin
          noisy_image[y][x] = 8'd255; // 5% xác suất dính Salt (Muối trắng)
        end 
        else if (rand_val < 30) begin
          noisy_image[y][x] = 8'd0;   // 5% xác suất dính Pepper (Tiêu đen)
        end 
        else begin
          noisy_image[y][x] = golden_image[y][x]; // 90% pixel sạch
        end
      end
    end
    // Đẩy ảnh vào DUT
    @(negedge clk);
    ready_i = 1;
    for (int y = 0; y < TEST_LENGTH; y++) begin
      for (int x = 0; x < TEST_WIDTH; x++) begin
        pixel_in = noisy_image[y][x];
        @(negedge clk); 
      end
    end
    // Xả Pipeline (Bơm pixel rác để ép dữ liệu cuối cùng rơi ra ngoài)
    pixel_in = 8'd0;
    for (int i = 0; i < (TEST_WIDTH * 3 + 10); i++) begin
      @(negedge clk);
    end
    // Dừng hệ thống
    ready_i = 0;
    #100;
    // IN BÁO CÁO TỔNG KẾT
    $display("\n==================================================");
    $display("           HARDWARE VERIFICATION REPORT           ");
    $display("==================================================");
    if (valid_rx_cnt !== (TEST_WIDTH * TEST_LENGTH)) begin
      $display(" [FATAL] Mất dữ liệu! Đợi %0d pixel, chỉ nhận được %0d", (TEST_WIDTH*TEST_LENGTH), valid_rx_cnt);
      $display(" RESULT: FAIL");
    end else if (error_cnt == 0) begin
      $display(" RESULT: PASS (0 Errors) - Edge-Padding & Spatial Routing chuẩn xác 100%%!"); 
    end else begin
      $display(" RESULT: FAIL (%0d Errors found) - Vui lòng kiểm tra lại Waveform", error_cnt); 
    end
    $display("==================================================\n");
    $finish;
  end
  //========================================================
  // 5. SCOREBOARD & SELF-CHECKING (MONITOR)
  //========================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      out_x        <= 0;
      out_y        <= 0;
      error_cnt    <= 0;
      valid_rx_cnt <= 0;
    end 
    else if (valid_out && out_y < TEST_LENGTH) begin
      logic [WIDTH_PIXEL-1:0] expected_val;
      logic [WIDTH_PIXEL-1:0] original_noise_val;
      
      valid_rx_cnt <= valid_rx_cnt + 1;

      // Lấy giá trị chuẩn từ Golden Image và giá trị đã bị nhiễu để in log
      expected_val       = golden_image[out_y][out_x];
      original_noise_val = noisy_image[out_y][out_x];

      // 1. Bắt bệnh lỗi xuất ra 'X'
      if (pixel_out === 8'hx || pixel_out === 8'hX) begin
        $display("\n[FATAL] Output bị 'X' tại Tọa độ (X:%0d, Y:%0d)!", out_x, out_y);
        error_cnt <= error_cnt + 1;
      end 
      // 2. Kiểm tra logic so với Golden Image
      // Lưu ý: Đối với ảnh Gradient, Edge-padding có thể làm pixel ở rìa bị lệch nhẹ 
      // do việc copy điểm sát vách vào làm tính toán trung vị. Ta cho phép sai số nhỏ (tolerance = 1 hoặc 2) 
      // ở vùng không có nhiễu để tránh báo lỗi giả.
      else if ( (pixel_out > expected_val + 2) || (pixel_out < expected_val - 2) ) begin
        $display("[FAIL] Lỗi tại (X:%0d, Y:%0d) | Out RTL = %3d | Expected Golden = %3d", out_x, out_y, pixel_out, expected_val);
        error_cnt <= error_cnt + 1;
      end
      // 3. Log lại các điểm nhiễu đã được cứu thành công
      else if (original_noise_val !== expected_val) begin
        $display("[PASS] Đã khử nhiễu tại (X:%2d, Y:%2d) | Khôi phục %3d về %3d", out_x, out_y, original_noise_val, pixel_out);
      end

      // Cập nhật tọa độ quét (Quét hết cột X rồi mới xuống hàng Y)
      if (out_x == TEST_WIDTH - 1) begin
        out_x <= 0;
        out_y <= out_y + 1;
      end else begin
        out_x <= out_x + 1;
      end
    end
  end
endmodule