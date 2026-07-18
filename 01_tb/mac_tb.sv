module mac_tb;
  // Parameters
  localparam WIDTH_MAC = 12; 
  localparam WIDTH_OPA = 8;
  localparam WIDTH_OPB = 4; // Lưu ý: 4-bit signed có dải giá trị từ -8 đến +7
  localparam GUARD_BIT = 3;

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

  // Tạo xung Clock (Chu kỳ 10ns -> 100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Kịch bản Test (Stimulus)
  initial begin
    // 1. Khởi tạo giá trị ban đầu
    rst_n   = 0;
    mac_en  = 0;
    opa     = '0;
    opb     = '0;

    // 2. Reset hệ thống
    #15;
    rst_n = 1;

    // =========================================================
    // CASE 1: Cửa sổ tăng dần
    // Pixel: 1->9 | Trọng số: 1
    // Kỳ vọng: 45
    // =========================================================
    @(posedge clk);
    #1; // Delay #1 để ngõ vào thay đổi sau sườn Clock (tránh Race Condition)
    mac_en = 1;
    for (int i = 0; i < 9; i++) begin
      opa[i] = i + 1;
      opb[i] = 1;
    end 

    // =========================================================
    // CASE 2: Cửa sổ đồng nhất
    // Pixel: 2 | Trọng số: 2
    // Kỳ vọng: 9 * (2 * 2) = 36
    // =========================================================
    @(posedge clk);
    #1;
    mac_en = 1; 
    for (int i = 0; i < 9; i++) begin
      opa[i] = 2; 
      opb[i] = 2; 
    end

    // =========================================================
    // CASE 3: Bộ lọc Dò biên (Laplacian) - TEST SỐ ÂM
    // Điểm ảnh ở giữa cực sáng (200), xung quanh tối (100).
    // Trọng số tâm = 4, xung quanh (trên, dưới, trái, phải) = -1. Góc = 0.
    // Kỳ vọng: (200 * 4) + 4 * (100 * -1) = 800 - 400 = 400
    // =========================================================
    @(posedge clk);
    #1;
    mac_en = 1;
    // Gán nền trước (trọng số góc = 0, viền = -1)
    for (int i = 0; i < 9; i++) begin
      opa[i] = 100;
      opb[i] = -1; // Sẽ tự động chuyển thành hệ bù 2 của 4-bit
    end
    opb[0] = 0; opb[2] = 0; opb[6] = 0; opb[8] = 0; // 4 góc bằng 0
    // Gán tâm
    opa[4] = 200;
    opb[4] = 4;

    // =========================================================
    // CASE 4: Xung đột cực đại - TEST TRÀN SỐ (OVERFLOW)
    // Pixel kịch trần = 255.
    // Trọng số kịch trần dương của 4-bit = 7.
    // Kỳ vọng: 9 * (255 * 7) = 16065
    // =========================================================
    @(posedge clk);
    #1;
    mac_en = 1;
    for (int i = 0; i < 9; i++) begin
      opa[i] = 255;
      opb[i] = 7;
    end

    // =========================================================
    // 3. Đóng van dữ liệu và chờ Pipeline đẩy kết quả ra
    // =========================================================
    @(posedge clk);
    #1;
    mac_en = 0;
    opa = '0;
    opb = '0;

    // Chờ thêm 5 nhịp Clock (50ns) để quan sát hết các kết quả trôi ra
    #50;
    $finish;
  end

  // =========================================================
  // BỘ GIÁM SÁT KẾT QUẢ (Monitor)
  // =========================================================
  always_ff @(posedge clk) begin
    if (mac_valid) begin
      $display("[TIME %0t] MAC VALID = 1 | KẾT QUẢ MAC_OUT = %0d", $time, $signed(mac_out));
    end
  end

endmodule