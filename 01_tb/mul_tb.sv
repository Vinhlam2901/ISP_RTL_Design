module mul_tb;
  // Parameters
  localparam int WIDTH_OPA = 12;
  localparam int WIDTH_OPB = 8;
  localparam int WIDTH_MAC = 20;
  // Signals
  logic [WIDTH_OPA-1:0] opa_i;
  logic [WIDTH_OPB-1:0] opb_i;
  logic [WIDTH_MAC-1:0] mul_o;
  // Expected variable for self-checking
  logic signed [WIDTH_MAC-1:0] expected_out;
  // Instantiate the Device Under Test (DUT)
  mul #(
    .WIDTH_OPA(WIDTH_OPA),
    .WIDTH_OPB(WIDTH_OPB),
    .WIDTH_MAC(WIDTH_MAC)
  ) dut (
    .opa_i(opa_i),
    .opb_i(opb_i),
    .mul_o(mul_o)
  );
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, mul_tb); 
  end
  // Stimulus process
  initial begin
    $display("=========================================================");
    $display(" BẮT ĐẦU MÔ PHỎNG: MODULE BOOTH-WALLACE MAC (SIGNED)");
    $display("=========================================================\n");
    // ---------------------------------------------------------
    // Test Case 1: Nhân hai số dương cơ bản
    // ---------------------------------------------------------
    opa_i = 12'd0;
    opb_i = 8'd2;
    #10;
    check_result(opa_i, opb_i, mul_o);
    // ---------------------------------------------------------
    // Test Case 2: Nhân số âm với số dương (A âm, B dương)
    // ---------------------------------------------------------
    opa_i = -12'd25; // 12-bit số âm
    opb_i = 8'd4;
    #10;
    check_result(opa_i, opb_i, mul_o);
    // ---------------------------------------------------------
    // Test Case 3: Nhân số dương với số âm (A dương, B âm)
    // ---------------------------------------------------------
    opa_i = 12'd100; 
    opb_i = -8'd5;
    #10;
    check_result(opa_i, opb_i, mul_o);
    // ---------------------------------------------------------
    // Test Case 4: Nhân hai số âm (Kết quả phải dương)
    // ---------------------------------------------------------
    opa_i = -12'd50; 
    opb_i = -8'd12;
    #10;
    check_result(opa_i, opb_i, mul_o);
    // ---------------------------------------------------------
    // Test Case 5: Biên giới trị số (Maximum Positive/Negative)
    // ---------------------------------------------------------
    opa_i = 12'h7FF; // Max dương của 12-bit (+2047)
    opb_i = 8'h7F;   // Max dương của 8-bit (+127)
    #10;
    check_result(opa_i, opb_i, mul_o);
    opa_i = 12'h800; // Max âm của 12-bit (-2048)
    opb_i = 8'h80;   // Max âm của 8-bit (-128)
    #10;
    check_result(opa_i, opb_i, mul_o);
    // ---------------------------------------------------------
    // Test Case 6: Random Test Vector (10 trường hợp)
    // ---------------------------------------------------------
    $display("--- BẮT ĐẦU CHẠY RANDOM VECTORS ---");
    for (int i = 0; i < 10; i++) begin
      opa_i = $random;
      opb_i = $random;
      #10;
      check_result(opa_i, opb_i, mul_o);
    end

    $display("\n=========================================================");
    $display(" HOÀN TẤT MÔ PHỎNG !");
    $display("=========================================================");
    $finish;
  end
  // Task tự động kiểm tra kết quả
  task check_result(input logic [WIDTH_OPA-1:0] a, input logic [WIDTH_OPB-1:0] b, input logic [WIDTH_MAC-1:0] actual);
    begin
      // Tính toán kết quả thực tế bằng phần mềm (ép kiểu sang số có dấu)
      expected_out = $signed(a) * $signed(b);
      if (actual !== expected_out) begin
        $display("      [FAIL] %0t | A = %0d, B = %0d | Expected: %0d, Got: %0d", 
                 $time, $signed(a), $signed(b), $signed(expected_out), $signed(actual));
      end else begin
        $display("[PASS] %0t | A = %0d, B = %0d | Result: %0d", 
                 $time, $signed(a), $signed(b), $signed(actual));
      end
    end
  endtask

endmodule