module div_pipeline_tb;
  //========================================================
  // 1. PARAMETERS & SIGNALS
  //========================================================
  parameter WIDTH_PIXEL = 8;      
  parameter WIDTH_DEN   = 13;
  parameter WIDTH_OUT   = 8;
  localparam WIDTH_REM  = WIDTH_DEN + 1; 
  logic                 i_clk;
  logic                 ni_rst;
  logic                 i_ready;
  logic                 i_valid;
  logic [WIDTH_REM-1:0] i_rem;     
  logic [WIDTH_OUT-1:0] i_quoti;   
  logic [WIDTH_DEN-1:0] i_den;     
  logic                 o_valid;
  logic [WIDTH_REM-1:0] o_remain;  
  logic [WIDTH_OUT-1:0] o_quoti; 
  // Bộ đếm thống kê
  int passed_cnt;
  int failed_cnt;
  // Hàng đợi (Queue) để lưu trữ dữ liệu đầu vào cho mục đích kiểm tra chéo (Latency = 1)
  typedef struct {
    logic [WIDTH_REM-1:0] exp_rem;
    logic [WIDTH_OUT-1:0] exp_quoti;
    logic [WIDTH_DEN-1:0] exp_den;
  } data_packet_t;
  data_packet_t check_queue[$];
  //========================================================
  // 2. INSTANTIATE DUT
  //========================================================
  div_pipeline #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH_DEN(WIDTH_DEN),
    .WIDTH_OUT(WIDTH_OUT)
  ) dut (
    .i_clk   (i_clk),
    .ni_rst  (ni_rst),
    .i_ready (i_ready),
    .i_valid (i_valid),
    .i_rem   (i_rem),
    .i_quoti (i_quoti),
    .i_den   (i_den),
    .o_valid (o_valid),
    .o_remain(o_remain),
    .o_quoti (o_quoti)
  );
  //========================================================
  // 3. CLOCK GENERATION
  //========================================================
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, div_pipeline_tb); 
  end
  //========================================================
  // 4. TASKS
  //========================================================
  task send_data(input [WIDTH_REM-1:0] r, input [WIDTH_OUT-1:0] q, input [WIDTH_DEN-1:0] d);
    begin
      @(negedge i_clk);
      i_valid = 1'b1;
      i_rem   = r;
      i_quoti = q;
      i_den   = d;
      // Đợi đến khi mạch chấp nhận dữ liệu (i_ready == 1)
      wait(i_ready == 1'b1);
      // Đẩy dữ liệu vào hàng đợi để bộ Monitor kiểm tra sau 1 nhịp Clock
      check_queue.push_back('{r, q, d});
    end
  endtask
  //========================================================
  // 5. STIMULUS (KỊCH BẢN TEST)
  //========================================================
  initial begin
    ni_rst  = 0;
    i_ready = 0;
    i_valid = 0;
    i_rem   = '0;
    i_quoti = '0;
    i_den   = '0; 
    #25; 
    ni_rst = 1;
    #10;
    $display("\n[INFO] Bắt đầu kiểm chứng bộ chia Non-Restoring Pipeline...");
    // Tình huống 1: Mạch thông suốt, đẩy dữ liệu liên tục
    i_ready = 1'b1;
    // Phép chia 1: Dividend nằm gọn trong i_quoti (i_rem = 0)
    // Ví dụ: 250 / 10 = 25
    send_data(14'd0, 8'd250, 13'd10);
    // Phép chia 2: Tử số cực lớn (255) / Mẫu số nhỏ (2) = 127
    send_data(14'd0, 8'd255, 13'd2);
    // Phép chia 3: Chia cho 1 (Kết quả giữ nguyên)
    send_data(14'd0, 8'd128, 13'd1);
// Tình huống 2: Ép xung tắc nghẽn (Pipeline Stall) an toàn tuyệt đối
    @(negedge i_clk);
    i_valid = 1'b0;
    i_ready = 1'b0; // Khóa van luồng dữ liệu
    
    // Đợi 2 nhịp clock để hệ thống "ngâm" trạng thái stall
    @(negedge i_clk);
    @(negedge i_clk);
    // Bơm dữ liệu 100/25 vào trong khi van vẫn khóa (thay đổi ở sườn âm)
    i_valid = 1'b1;
    i_rem   = 14'd0;
    i_quoti = 8'd100;
    i_den   = 13'd25;
    // Chờ thêm 1 nhịp clock để chắc chắn phần cứng KHÔNG nuốt dữ liệu này
    @(negedge i_clk);
    // Mở van luồng dữ liệu (Ở SƯỜN ÂM) và đẩy vào hàng đợi
    i_ready = 1'b1; 
    check_queue.push_back('{14'd0, 8'd100, 13'd25});
    // Tình huống 3: Rắc dữ liệu ngẫu nhiên (Randomized)
    for (int i = 0; i < 20; i++) begin
      logic [WIDTH_OUT-1:0] rand_q;
      logic [WIDTH_DEN-1:0] rand_d;

      rand_q = $urandom_range(10, 255);
      rand_d = $urandom_range(1, 127); // Tránh chia cho 0
      send_data(14'd0, rand_q, rand_d);
      // Thỉnh thoảng tắt i_ready ngẫu nhiên để test khả năng giữ dữ liệu
      if ($urandom_range(0, 10) > 7) begin
        @(negedge i_clk);
        i_ready = 1'b0;
        #20;
        i_ready = 1'b1;
      end
    end
    // Xả Pipeline
    @(negedge i_clk);
    i_valid = 1'b0;
    #50;
    // IN BÁO CÁO TỔNG KẾT
    $display("\n==================================================");
    $display("           DIVISION PIPELINE TEST REPORT          ");
    $display("==================================================");
    $display(" RESULT: Passed %0d | Failed %0d", passed_cnt, failed_cnt); 
    if (failed_cnt == 0) $display(" -> STATUS: PERFECT SUCCESS!");
    else $display(" -> STATUS: NEEDS DEBUGGING");
    $display("==================================================\n");
    $finish;
  end
 //========================================================
  // 6. SCOREBOARD & MONITOR (SELF-CHECKING)
  //========================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      // Khởi tạo các biến đếm tại đây để đảm bảo Single-Driver
      passed_cnt <= 0;
      failed_cnt <= 0;
    end 
    else if (o_valid && i_ready) begin
      data_packet_t req;
      int expected_q;
      int total_dividend;
      if (check_queue.size() > 0) begin
        req = check_queue.pop_front();
        // Tính toán lại giá trị kỳ vọng
        total_dividend = (req.exp_rem << WIDTH_OUT) | req.exp_quoti;
        expected_q     = total_dividend / req.exp_den;
        // So sánh
        if (o_quoti === expected_q) begin
          $display("[PASS] %4d / %4d = %4d (Rem: %4d)", total_dividend, req.exp_den, o_quoti, o_remain);
          passed_cnt++;
        end else begin
          $display("[FAIL] %4d / %4d | RTL Q = %4d | Expected Q = %4d", total_dividend, req.exp_den, o_quoti, expected_q);
          failed_cnt++;
        end
      end else begin
        $display("[ERROR] o_valid bật lên nhưng không có dữ liệu tương ứng trong Queue!");
        failed_cnt++;
      end
    end
  end
endmodule