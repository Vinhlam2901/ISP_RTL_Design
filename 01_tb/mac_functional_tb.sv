module mac_functional_tb();
  // Khai báo tín hiệu
  logic        clk;
  logic        rst_n;
  logic        mac_en;
  logic [11:0] opa;
  logic [7:0]  opb;
  logic        mac_valid;
  logic [23:0] mac_out;
  // Khởi tạo DUT (Device Under Test)
  mac dut (
    .i_clk      (clk),
    .ni_rst     (rst_n),
    .mac_en_i   (mac_en),
    .opa_i      (opa),
    .opb_i      (opb),
    .mac_valid_o(mac_valid),
    .mac_out    (mac_out)
  );
  // Tạo Clock (Chu kỳ 10ns -> 100MHz)
  always #1 clk = ~clk;
  // Tạo mảng dữ liệu Test Vectors (Pixel và Trọng số bộ lọc)
  // Dùng kiểu logic có dấu (signed) để dễ gán số âm
  logic signed [11:0] test_pixels  [0:2] = '{ 12'sd100, 12'sd50, -12'sd20 }; 
  logic signed [7:0]  test_weights [0:2] = '{ 8'sd2,   -8'sd1,   -8'sd3  };
  // Kết quả kỳ vọng: 
  // Lần 1: 100 * 2 = 200
  // Lần 2: 200 + (50 * -1) = 150
  // Lần 3: 150 + (-20 * -3) = 210
  initial begin
    // 1. Khởi tạo
    clk     = 0;
    rst_n   = 0;
    mac_en  = 0;
    opa     = 0;
    opb     = 0;
    // 2. Nhả Reset
    #20;
    rst_n = 1;
    #10;
    $display("=== BAT DAU FUNCTIONAL TEST: TINH TONG 3 CAP DU LIEU ===");
    // 3. Vòng lặp nạp dữ liệu
    for (int i = 0; i < 3; i++) begin
      // Nạp dữ liệu mới tại sườn xuống (để setup time an toàn cho sườn lên tiếp theo)
      @(negedge clk); 
      opa = test_pixels[i];
      opb = test_weights[i];
      mac_en = 1'b1;
      $display("Nap du lieu %0d: A = %0d, B = %0d", i+1, $signed(opa), $signed(opb));
      // Kéo enable xuống sau 1 chu kỳ, nhường chỗ cho FSM xử lý
      @(negedge clk);
      mac_en  = 1'b0; 
      
      // Chờ cờ valid bật lên để chốt kết quả
      wait(mac_valid == 1'b1);
      $display("-> Ket qua ACC hien tai: %0d", $signed(mac_out));
    end

    // 4. Kiểm tra kết quả cuối cùng tự động (Self-checking)
    #20;
    $display("=== KET THUC TEST ===");
    if ($signed(mac_out) == 210)
      $display("[PASS] MAC tinh toan dung voi du lieu bien thien (Co dau)!");
    else
      $display("[FAIL] Ket qua ky vong la 210, nhung MAC tinh ra %0d", $signed(mac_out));
      
    $finish;
  end

endmodule
