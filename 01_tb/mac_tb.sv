module mac_tb;
  // Parameters
  localparam WIDTH_MAC = 12; 
  localparam WIDTH_OPA = 8;
  localparam WIDTH_OPB = 4; // 4-bit signed: -8 đến +7
  localparam GUARD_BIT = 4;

  // Tín hiệu Testbench
  logic                             clk;
  logic                             rst_n;
  logic                             mac_en;
  logic [8:0][WIDTH_OPA-1:0]        opa;
  logic [8:0][WIDTH_OPB-1:0]        opb;
  logic                             mac_valid;
  logic [(WIDTH_MAC+GUARD_BIT)-1:0] mac_out;

  // Gọi Module DUT
  mac #(
    .WIDTH_MAC(WIDTH_MAC),
    .WIDTH_OPA(WIDTH_OPA),
    .WIDTH_OPB(WIDTH_OPB),
    .GUARD_BIT(GUARD_BIT)
  ) dut (
    .i_clk      (clk),
    .ni_rst     (rst_n),
    .mac_en_i   (mac_en),
    .opa_i      (opa),
    .opb_i      (opb),
    .mac_valid_o(mac_valid),
    .mac_out    (mac_out)
  );

  // Khởi tạo ghi sóng mô phỏng
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, mac_tb); 
  end

  // Tạo xung Clock (10ns -> 100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // =========================================================
  // CẤU TRÚC KIỂM CHỨNG TỰ ĐỘNG (SCOREBOARD CƠ BẢN)
  // =========================================================
  integer expected_queue [$]; 
  // CHỈ KHAI BÁO, KHÔNG GÁN GIÁ TRỊ Ở ĐÂY
  integer pass_cnt;       
  integer fail_cnt;       
  integer test_id;       

  // =========================================================
  // KỊCH BẢN TEST (STIMULUS)
  // =========================================================
  initial begin
    // 1. Khởi tạo giá trị ban đầu cho các biến Testbench
    pass_cnt = 0;
    fail_cnt = 0;
    test_id  = 1;
    
// Khởi tạo giá trị cho phần cứng
    rst_n   = 0;
    mac_en  = 0;
    opa     = '0;
    opb     = '0;

    // BẠN CẦN BỔ SUNG ĐOẠN NÀY ĐỂ MẠCH BẮT ĐẦU CHẠY
    #15;
    rst_n = 1;

    // =========================================================
    // CASE 1: Cửa sổ tăng dần
    // =========================================================
    @(posedge clk); #1;
    mac_en = 1;
    for (int i = 0; i < 9; i++) begin
      opa[i] = i + 1;
      opb[i] = 1;
    end 
    expected_queue.push_back(45); // Nạp kỳ vọng vào Queue

    // =========================================================
    // CASE 2: Cửa sổ đồng nhất
    // =========================================================
    @(posedge clk); #1;
    mac_en = 1; 
    for (int i = 0; i < 9; i++) begin
      opa[i] = 2; 
      opb[i] = 2; 
    end
    expected_queue.push_back(36); // Nạp kỳ vọng vào Queue

    // =========================================================
    // CASE 3: Bộ lọc Dò biên (Laplacian) - TEST SỐ ÂM
    // =========================================================
    @(posedge clk); #1;
    mac_en = 1;
    for (int i = 0; i < 9; i++) begin
      opa[i] = 100;
      opb[i] = -1; 
    end
    opb[0] = 0; opb[2] = 0; opb[6] = 0; opb[8] = 0; 
    opa[4] = 200;
    opb[4] = 4;
    expected_queue.push_back(400); // Nạp kỳ vọng vào Queue

    // =========================================================
    // CASE 4: Xung đột cực đại - TEST TRÀN SỐ (OVERFLOW)
    // =========================================================
    @(posedge clk); #1;
    mac_en = 1;
    for (int i = 0; i < 9; i++) begin
      opa[i] = 255;
      opb[i] = 7;
    end
    expected_queue.push_back(16065); // Nạp kỳ vọng vào Queue

    // =========================================================
    // 3. Đóng van dữ liệu và chờ Pipeline đẩy kết quả ra
    // =========================================================
    @(posedge clk); #1;
    mac_en = 0;
    opa = '0;
    opb = '0;

    // Chờ cho đến khi Hàng đợi trống (tất cả kết quả đã trôi ra)
    wait (expected_queue.size() == 0);
    
    // Chờ thêm một chút cho dạng sóng đẹp rồi in Báo cáo Tổng kết
    #20;
    $display("\n=======================================================");
    $display("               TỔNG KẾT SIMULATION                     ");
    $display("=======================================================");
    $display("  => SỐ LƯỢNG PASS : %0d", pass_cnt);
    $display("  => SỐ LƯỢNG FAIL : %0d", fail_cnt);
    if (fail_cnt == 0)
      $display("  => ĐÁNH GIÁ      : HOÀN HẢO! LÕI MAC CHẠY ĐÚNG 100%");
    else
      $display("  => ĐÁNH GIÁ      : CÓ LỖI! CẦN KIỂM TRA LẠI RTL");
    $display("=======================================================\n");
    $finish;
  end
  // =========================================================
  // BỘ GIÁM SÁT KẾT QUẢ (SCOREBOARD / MONITOR)
  // =========================================================
  // DÙNG always THÔNG THƯỜNG CHO TESTBENCH, BỎ always_ff
  always @(posedge clk) begin
    if (mac_valid) begin
      // Khai báo biến cục bộ (automatic) để chứa giá trị lấy từ Queue
      automatic integer exp_val = expected_queue.pop_front();
      automatic integer act_val = $signed(mac_out);
      
      if (act_val === exp_val) begin
        $display("[TIME %0t] [PASS] TEST %0d | KẾT QUẢ MAC = %0d", $time, test_id, act_val);
        pass_cnt++;
      end else begin
        $display("[TIME %0t] [FAIL] TEST %0d | KẾT QUẢ MAC = %0d (LỖI) | KỲ VỌNG = %0d", $time, test_id, act_val, exp_val);
        fail_cnt++;
      end
      
      test_id++; // Lúc này test_id tăng lên hoàn toàn hợp lệ
    end
  end

endmodule