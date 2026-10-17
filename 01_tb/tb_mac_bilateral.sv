module tb_mac_bilateral();

  // Khai báo Parameters chuẩn theo thiết kế
  parameter WIDTH_PX  = 8;
  parameter WIDTH_WC  = 9;
  parameter GUARD_BIT = 4;
  parameter WIDTH_MUL = 18;

  // Khai báo tín hiệu giao tiếp
  logic                             i_clk;
  logic                             ni_rst;
  logic                             i_mac_en;
  logic [8:0][WIDTH_PX-1:0]         i_px;
  logic [8:0][WIDTH_WC-1:0]         i_wc;
  logic                             o_mac_valid;
  logic [(WIDTH_MUL+GUARD_BIT)-1:0] o_mac_num_out;
  logic [(WIDTH_WC+GUARD_BIT)-1:0]  o_mac_den_out;

  // Gọi Module DUT (Device Under Test)
  mac_bilateral #(
    .WIDTH_PX (WIDTH_PX),
    .WIDTH_WC (WIDTH_WC),
    .GUARD_BIT(GUARD_BIT),
    .WIDTH_MUL(WIDTH_MUL)
  ) dut (
    .i_clk        (i_clk),
    .ni_rst       (ni_rst),
    .i_mac_en     (i_mac_en),
    .i_px         (i_px),
    .i_wc         (i_wc),
    .o_mac_valid  (o_mac_valid),
    .o_mac_num_out(o_mac_num_out),
    .o_mac_den_out(o_mac_den_out)
  );
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_mac_bilateral); 
  end
  // Tạo xung Clock (Chu kỳ 10ns -> 100MHz)
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end

  // Khối Stimulus (Bơm dữ liệu thử nghiệm)
  initial begin
    // 1. Khởi tạo
    ni_rst   = 0;
    i_mac_en = 0;
    for(int i = 0; i < 9; i++) begin
      i_px[i] = '0;
      i_wc[i] = '0;
    end

    // 2. Nhả Reset
    #25;
    ni_rst = 1;
    #10;

    // =========================================================================
    // TEST CASE 1
    // =========================================================================
    @(posedge i_clk);
    #1; // <--- THÊM DÒNG NÀY (Đợi 1ns sau sườn clock để mạch ổn định)
    i_mac_en = 1;
    for(int i = 0; i < 9; i++) begin
      i_px[i] = 8'd10;
      i_wc[i] = 9'd2;
    end
    $display("-> [T= %0t] Đã đưa Test Case 1 vào Pipeline...", $time);

    // =========================================================================
    // TEST CASE 2
    // =========================================================================
    @(posedge i_clk);
    #1; // <--- THÊM DÒNG NÀY
    i_mac_en = 1;
    for(int i = 0; i < 9; i++) begin
      i_px[i] = i + 1; 
      i_wc[i] = 9'd10; 
    end
    $display("-> [T= %0t] Đã đưa Test Case 2 vào Pipeline...", $time);

    // =========================================================================
    // TEST CASE 3: STRESS TEST
    // =========================================================================
    @(posedge i_clk);
    #1; // <--- THÊM DÒNG NÀY
    i_mac_en = 1;
    for(int i = 0; i < 9; i++) begin
      i_px[i] = 8'd255;
      i_wc[i] = 9'd508;
    end
    $display("-> [T= %0t] Đã đưa Test Case 3 (Max Stress) vào Pipeline...", $time);
    
    // Ngắt tín hiệu nạp dữ liệu
    @(posedge i_clk);
    #1; // <--- THÊM DÒNG NÀY
    i_mac_en = 0;
    
    #100;
    $display("---------------------------------------------------------");
    $display("Hoàn tất mô phỏng. Hãy kiểm tra kết quả Monitor bên dưới.");
    $finish;
  end

  // Khối Monitor (Giám sát và in kết quả)
  // Vì mạch có 4 tầng pipeline register nên kết quả sẽ trễ 4 nhịp clock.
  initial begin
    $display("================== KẾT QUẢ MÔ PHỎNG =====================");
  end

  always @(posedge i_clk) begin
    if (o_mac_valid) begin
      $display("[T= %0t] Output Valid! Tử số (Num) = %0d | Mẫu số (Den) = %0d", 
                $time, o_mac_num_out, o_mac_den_out);
    end
  end

endmodule