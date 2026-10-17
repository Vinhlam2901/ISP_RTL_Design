module cla_tb;
  
  //=============================================================================
  // PARAMETERS
  // Thay đổi WIDTH tại đây để test cho bộ cộng 4-bit, 16-bit, 21-bit hoặc 64-bit
  //=============================================================================
  parameter int WIDTH = 14; 
  parameter int NUM_TESTS = 200; // Số lượng test case ngẫu nhiên
  //=============================================================================
  // SIGNALS
  //=============================================================================
  logic [WIDTH-1:0] a_i;
  logic [WIDTH-1:0] b_i;
  logic             cin_i;
  logic [WIDTH-1:0] result_o;
  logic             cout_o;
  logic [WIDTH:0]   expected_val; // Chứa tổng Sum và bit Carry Out (Rộng hơn 1 bit)
  int               error_count;
  logic             prog_o; // Dây nhận Propagate
  logic             gen_o; // Dây nhận Generate
  //=============================================================================
  // DEVICE UNDER TEST (DUT)
  //=============================================================================
  // Lưu ý: Nếu module RTL của bạn không dùng parameter, hãy bỏ dòng .WIDTH(WIDTH) 
  // và đổi tên module (ví dụ: cla_adder_21bit) cho khớp với thiết kế của bạn.
  cla_adder_14bit dut (
    .a_i     (a_i),
    .b_i     (b_i),
    .cin_i   (cin_i),
    .result_o(result_o),
    .cout_o  (cout_o)
  );

  //=============================================================================
  // VERIFICATION TASK
  //=============================================================================
  task check_result();
    #5; // Chờ mạch tổ hợp (Combinational Logic) giải quyết xong độ trễ
    // Golden Model: Phép cộng chuẩn của SystemVerilog
    expected_val = a_i + b_i + cin_i;
    // So sánh ngõ ra của RTL với Golden Model
    if ({cout_o, result_o} !== expected_val) begin
      $display("---------------------------------------------------------");
      $error("[FAIL] Time: %0t", $time);
      $display("   A_i   = 0x%0h", a_i);
      $display("   B_i   = 0x%0h", b_i);
      $display("   Cin_i = %0b", cin_i);
      $display("   EXPECTED : Cout = %0b, Sum = 0x%0h", expected_val[WIDTH], expected_val[WIDTH-1:0]);
      $display("   ACTUAL   : Cout = %0b, Sum = 0x%0h", cout_o, result_o);
      error_count++;
    end
  endtask
  //=============================================================================
  // STIMULUS GENERATION
  //=============================================================================
  initial begin
    $display("=========================================================");
    $display("Bắt đầu mô phỏng CLA Adder với độ rộng %0d-bit", WIDTH);
    $display("=========================================================");
    error_count = 0;
    // 1. Kiểm tra các Corner Cases (Trường hợp cực hạn)
    $display("[INFO] Chạy Corner Cases...");
    
    // Trắng toàn bộ (All Zeros)
    a_i = '0; b_i = '0; cin_i = 1'b0; check_result();
    
    // Đầy toàn bộ (All Ones) gây tràn Carry liên tục
    a_i = '1; b_i = '1; cin_i = 1'b1; check_result();
    a_i = '1; b_i = '1; cin_i = 1'b0; check_result();
    
    // Mẫu so le (Checkerboard) để kiểm tra Ripple Carry
    a_i = {{(WIDTH/2){2'b10}}, 1'b1}; // VD: 101010...
    b_i = {{(WIDTH/2){2'b01}}, 1'b0}; // VD: 010101...
    cin_i = 1'b1; check_result();

    // 2. Kiểm tra bằng Random Stimulus (Monte Carlo)
    $display("[INFO] Chạy %0d Random Cases...", NUM_TESTS);
    for (int i = 0; i < NUM_TESTS; i++) begin
      // Sử dụng std::randomize để tạo ngẫu nhiên trên mọi kích thước WIDTH (vượt qua giới hạn 32-bit của $urandom)
      if (!std::randomize(a_i, b_i, cin_i)) begin
        $fatal("Lỗi sinh dữ liệu ngẫu nhiên (Randomization failed)!");
      end
      check_result();
    end

    // 3. Kết luận
    $display("=========================================================");
    if (error_count == 0) begin
      $display("[PASS] Thiết kế hoàn hảo! 0 lỗi tìm thấy.");
    end else begin
      $display("[FAIL] Phát hiện %0d lỗi trong thiết kế.", error_count);
    end
    $display("=========================================================");
    
    $finish; // Kết thúc mô phỏng (dành cho Xcelium / VCS)
  end

endmodule