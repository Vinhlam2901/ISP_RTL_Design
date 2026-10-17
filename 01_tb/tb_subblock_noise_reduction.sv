module tb_subblock_noise_reduction();

  // Khai báo parameters
  parameter WIDTH_PIXEL = 8;
  parameter WIDTH       = 256;
  parameter LENGTH      = 256;
  parameter TOTAL_PIXELS = WIDTH * LENGTH;

  // Khai báo tín hiệu
  logic                   i_clk;
  logic                   ni_rst;
  logic                   i_ready;
  logic [WIDTH_PIXEL-1:0] threshold_i;
  logic [WIDTH_PIXEL-1:0] i_pix;
  logic                   valid_o;
  logic [WIDTH_PIXEL-1:0] pix_filt_o;

  // ROM ảo chứa ảnh đầu vào
  logic [7:0] img_rom [0:TOTAL_PIXELS-1];
  
  // File handler để ghi ảnh đầu ra
  integer file_out;

  // Gọi (Instantiate) Mạch Design của bạn
  subblock_noise_reduction #(
    .WIDTH_PIXEL(WIDTH_PIXEL),
    .WIDTH(WIDTH),
    .LENGTH(LENGTH)
  ) dut (
    .i_clk(i_clk),
    .ni_rst(ni_rst),
    .i_ready(i_ready),
    .threshold_i(threshold_i),
    .i_pix(i_pix),
    .valid_o(valid_o),
    .pix_filt_o(pix_filt_o)
  );

  // Tạo Clock (100MHz)
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk; 
  end
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_subblock_noise_reduction); 
  end
  // Khối đẩy dữ liệu đầu vào (Stimulus)
  initial begin
    // 1. Nạp ảnh từ file hex vào ROM ảo trong Testbench
    $readmemh("../02_sim/python_sim/image_in.hex", img_rom);
    // 2. Mở file để chuẩn bị ghi kết quả
    file_out = $fopen("../02_sim/python_sim/image_out.hex", "w");
    if (!file_out) begin
      $display("LỖI: Không thể tạo file image_out.hex");
      $finish;
    end
    // 3. Khởi tạo tín hiệu và Reset mạch
    ni_rst = 0;
    i_ready = 0;
    i_pix = 0;
    threshold_i = 8'd50; // Đặt ngưỡng nhiễu muối tiêu (tùy bạn tinh chỉnh)
    #20;
    ni_rst = 1; // Nhả reset
    #20;

// Bơm 65536 pixel thực của ảnh
    i_ready = 1;
    for (int i = 0; i < TOTAL_PIXELS; i++) begin
      i_pix = img_rom[i];
      @(posedge i_clk);
    end
    
    // KỸ THUẬT FLUSH: Bơm thêm 34 pixel rác (0x00) để đẩy dữ liệu cũ ra
    i_pix = 8'h00;
    for (int i = 0; i < 34; i++) begin
      @(posedge i_clk);
    end
    
    i_ready = 0; // Lúc này toàn bộ dữ liệu hợp lệ đã thoát ra an toàn
    
    #5000; 
    $fclose(file_out);
    $display("MÔ PHỎNG HOÀN TẤT. Hãy dùng Python để xem image_out.hex");
    $finish;
  end

  // Khối hứng dữ liệu đầu ra (Monitor)
  always @(posedge i_clk) begin
    if (valid_o) begin
      // Cứ mỗi khi mạch nhả valid_o = 1, ghi pixel đó vào file hex
      $fdisplay(file_out, "%02x", pix_filt_o);
    end
  end

endmodule