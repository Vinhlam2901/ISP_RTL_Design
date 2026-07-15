
//===========================================================================
// 2. TESTBENCH CHÍNH
//===========================================================================
`timescale 1ns/1ps
module mac_tb;
  // Parameters
  localparam WIDTH_MAC = 16;
  localparam WIDTH_OPA = 8;
  localparam WIDTH_OPB = 8;
  localparam GUARD_BIT = 4;
  // Tín hiệu Testbench
  logic                             clk;
  logic                             rst_n;
  logic                             mac_en;
  logic [8:0][WIDTH_OPA-1:0]        opa;
  logic [8:0][WIDTH_OPB-1:0]        opb;
  logic                             mac_ready;
  logic                             mac_valid;
  logic [(WIDTH_MAC+GUARD_BIT)-1:0] mac_out;
  // Gọi Module DUT (Device Under Test)
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
    .mac_ready_o(mac_ready),
    .mac_valid_o(mac_valid),
    .mac_out    (mac_out)
  );
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, mac_tb); 
  end
  // Tạo xung Clock (Chu kỳ 10ns -> 100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  // Kịch bản Test
  initial begin
    rst_n   = 0;
    mac_en  = 0;
    for (int i = 0; i < 9; i++) begin
      opa[i] = '0;
      opb[i] = '0;
    end
    #15;
    rst_n = 1;
    #10;
    @(posedge clk);
    mac_en = 1;
    for (int i = 0; i < 9; i++) begin
      opa[i] = i + 1;
      opb[i] = 1;
    end 
    #10;
    @(posedge clk);
    mac_en = 1; 
    for (int i = 0; i < 9; i++) begin
      opa[i] = 2; // Tất cả Pixel = 2
      opb[i] = 2; // Tất cả Trọng số = 2 (Kỳ vọng: 9 * (2*2) = 36)
    end
    @(posedge clk);
    #10;
    mac_en = 0;
    #50;
    $finish;
  end
  always_ff @(posedge clk) begin
    if (mac_valid) begin
      $display("[TIME %0t] MAC VALID = 1 | KẾT QUẢ MAC_OUT = %0d", $time, $signed(mac_out));
    end
  end

endmodule