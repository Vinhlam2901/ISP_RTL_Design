module bilateral_filter_tb;

  //--------------------------------------------------------
  // 1. Tham số hệ thống (Scale down để mô phỏng nhanh)
  //--------------------------------------------------------
  parameter WIDTH_PIXEL = 8;
  parameter TEST_WIDTH  = 32; // Giảm kích thước ảnh xuống 32x32 để test Line Buffer
  parameter TEST_LENGTH = 32;

  //--------------------------------------------------------
  // 2. Khai báo tín hiệu
  //--------------------------------------------------------
  logic                   i_clk;
  logic                   ni_rst;
  logic                   i_ready;
  logic [WIDTH_PIXEL-1:0] i_pix;
  logic                   filter_valid_o;
  logic [WIDTH_PIXEL-1:0] o_pix_filter;

  // Mảng lưu trữ ảnh để test
  logic [7:0] input_image  [0:TEST_LENGTH-1][0:TEST_WIDTH-1];
  
  // Biến đếm monitor
  int rx_count;
  int expected_total = TEST_WIDTH * TEST_LENGTH;

  //--------------------------------------------------------
  // 3. Khởi tạo DUT (Device Under Test)
  //--------------------------------------------------------
  bilateral_filter #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH(TEST_WIDTH),
    .LENGTH(TEST_LENGTH)
  ) dut (
    .i_clk         (i_clk),
    .ni_rst        (ni_rst),
    .i_ready       (i_ready),
    .i_pix         (i_pix),
    .filter_valid_o(filter_valid_o),
    .o_pix_filter  (o_pix_filter)
  );
  //--------------------------------------------------------
  // 4. Tạo Xung Clock (Chu kỳ 10ns -> 100MHz)
  //--------------------------------------------------------
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, bilateral_filter_tb); 
  end
  //--------------------------------------------------------
  // 5. Kịch bản mô phỏng (Stimulus)
  //--------------------------------------------------------
  initial begin
    // Khởi tạo trạng thái an toàn
    ni_rst  = 0;
    i_ready = 0;
    i_pix   = 0; 
    // Tạo một bức ảnh test: Nửa bên trái tối (50), nửa bên phải sáng (200)
    // Có chèn một điểm nhiễu lốm đốm để xem Bilateral làm mượt biên như thế nào
    for (int y = 0; y < TEST_LENGTH; y++) begin
      for (int x = 0; x < TEST_WIDTH; x++) begin
        if (x < TEST_WIDTH/2)
          input_image[y][x] = 8'd50;
        else
          input_image[y][x] = 8'd200;
      end
    end
    input_image[15][15] = 8'd255; // Điểm nhiễu ngay tại biên
    // Reset hệ thống
    #25; 
    ni_rst = 1;
    #10;
    $display("\n[INFO] Bắt đầu đẩy %0d pixels vào bộ lọc Bilateral...", expected_total);
    // Bơm dữ liệu ảnh vào DUT
    for (int y = 0; y < TEST_LENGTH; y++) begin
      for (int x = 0; x < TEST_WIDTH; x++) begin
        @(negedge i_clk);
        i_ready = 1'b1;              // Báo hiệu hệ thống sẵn sàng cấp/nhận data
        i_pix   = input_image[y][x]; // Bơm pixel vào
      end
    end
    // Xả Pipeline: Cấp thêm các chu kỳ rỗng để đẩy hết dữ liệu còn kẹt trong các tầng Pipeline
    // Bilateral Filter có pipeline khá sâu (Line buffer + MAC + Division)
    for (int i = 0; i < (TEST_WIDTH * 3 + 50); i++) begin
      @(negedge i_clk);
      i_pix = 8'd0; 
    end
    i_ready = 1'b0; // Đóng van
    #200;
    $display("\n==================================================");
    $display("           BILATERAL FILTER TEST REPORT           ");
    $display("==================================================");
    if (rx_count == expected_total)
      $display(" [PASS] Hoàn thành! Đã thu thập đủ %0d pixels đầu ra.", rx_count);
    else
      $display(" [FAIL] Mất dữ liệu! Kì vọng %0d pixels, nhưng chỉ nhận được %0d pixels.", expected_total, rx_count);
    $display("==================================================\n");
    $finish;
  end
  //--------------------------------------------------------
  // 6. Monitor thu thập kết quả (Scoreboard)
  //--------------------------------------------------------
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      rx_count <= 0;
    end else if (filter_valid_o && i_ready) begin
      rx_count <= rx_count + 1;
      
      // In log một số pixel đại diện để quan sát sự thay đổi cường độ
      if (rx_count >= 450 && rx_count <= 480) begin
         $display("Pixel nhận tại ngõ ra thứ %4d: %3d", rx_count + 1, o_pix_filter);
      end
      
      // Đóng chốt nghiệm thu: Ngắt mô phỏng ngay khi đủ 1024 pixels
      if (rx_count + 1 == expected_total) begin
        $display("\n==================================================");
        $display("           BILATERAL FILTER TEST REPORT           ");
        $display("==================================================");
        $display(" [PASS] Hoàn thành xuất sắc! Đã thu thập chuẩn xác %0d pixels.", expected_total);
        $display("==================================================\n");
        $finish;
      end
    end
  end
endmodule