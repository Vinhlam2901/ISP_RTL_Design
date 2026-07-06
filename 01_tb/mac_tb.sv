module mac_tb();
  // Khai báo các tín hiệu kết nối
  logic        clk;
  logic        rst_n;
  logic        mac_en;
  logic        acc_clr;
  logic [11:0] opa;
  logic [7:0]  opb;
  
  logic        mac_ready;
  logic        mac_valid;
  logic [23:0] mac_out;
  // Instantiate khối MAC
  mac dut (
    .i_clk      (clk),
    .ni_rst     (rst_n),
    .mac_en_i   (mac_en),
    .acc_clr_i  (acc_clr),
    .opa_i      (opa),
    .opb_i      (opb),
    .mac_ready_o(mac_ready),
    .mac_valid_o(mac_valid),
    .mac_out    (mac_out)
  );
  // Tạo Clock (Chu kỳ 10ns -> 100MHz)
  always #5 clk = ~clk;
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, mac_tb); 
  end
  // Kịch bản Test
  initial begin
    // 1. Khởi tạo giá trị ban đầu
    clk     = 0;
    rst_n   = 0;
    mac_en  = 0;
    acc_clr = 0;
    opa     = 0;
    opb     = 0;
    // 2. Nhả Reset
    #20;
    rst_n = 1;
    #10;
    $display("=== BAT DAU TEST MAC CHAY CUA SO 3x3 (9 LAN CONG DON) ===");
    // 3. Test Case: Cộng dồn 9 lần giá trị lớn nhất
    // Max positive 12-bit signed = 12'h7FF (2047)
    // Max positive 8-bit signed = 8'h7F (127)
    // Tích kỳ vọng: 2047 * 127 = 259969 (20-bit Hex: 0x3F781)
    for (int i = 0; i < 9; i++) begin
      // Đợi MAC báo ready (IDLE state)
      wait(mac_ready == 1'b1); 
      // Kích hoạt FSM
      @(negedge clk); 
      opa = 12'h7FF;
      opb = 8'h7F;
      mac_en = 1'b1;
      // Ở lần đầu tiên, ra lệnh xóa thanh ghi cũ (Tính A*B + 0)
      // Từ lần thứ 2 trở đi, ra lệnh cộng dồn (Tính A*B + ACC_Q)
      if (i == 0) acc_clr = 1'b1;
      else        acc_clr = 1'b0;
      // Đợi FSM đi qua trạng thái ACC và STOP
      @(negedge clk);
      mac_en = 1'b0; 
      wait(mac_valid == 1'b1);
      $display("Lan cong don %0d: Ket qua hien tai = %0d (Hex: %h)", i+1, $signed(mac_out), mac_out);
    end
    // 4. Kết thúc mô phỏng
    #50;
    $display("=== KET THUC TEST ===");
    $display("Ket qua ly thuyet sau 9 lan: 259969 * 9 = 2339721");
    $display("Ket qua thuc te cua MAC:   %0d", $signed(mac_out));
    if ($signed(mac_out) == 2339721)
      $display("[PASS] 4-bit Guard da hoat dong hoan hao, khong he bi tran so!");
    else
      $display("[FAIL] Phep tinh bi sai hoac tran so!");
      
    $finish;
  end

endmodule