module convolution_tb;
  localparam W = 128;
  localparam L = 128;
  localparam TOTAL_PIXELS = W * L;
  logic            clk;
  logic            rst_n;
  logic            ready;
  logic [8:0][3:0] kernel;
  logic [7:0]      pix_in;
  logic [7:0]      pix_out;
  logic            valid_out;
  convolution #(
    .WIDTH_MAC     (12),
    .WIDTH_PIXEL   (8 ),     // 8bit for 1 pixel
    .WIDTH_KERNEL  (4 ),     // 4bit for kernel's coefficiency from [-8:7]
    .GUARD_BIT     (3 ),     // guard bit = log2(WIDTH_MAC)             
	  .WIDTH         (W),
    .LENGTH        (L),
    .GAUSSIAN_SHIFT(4 )     // sum of coefficiens of gaussian kernel is 16
  ) dut (
    .i_clk(clk),
    .ni_rst(rst_n),
    .i_ready(ready),
    .mac_kernel(kernel),
    .i_pix(pix_in),
    .o_pix_conv(pix_out),
    .o_valid(valid_out)
  );
  logic [7:0] img_memory [0:TOTAL_PIXELS-1];
  integer file_out;
  initial begin
    clk = 0;
    forever #10 clk = ~clk; 
  end
  // Tiến trình 1: Bơm dữ liệu vào mạch
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, convolution_tb);
    // Đọc ảnh từ file hex do Python tạo ra
    $readmemh("../02_sim/python_sim/input_img.hex", img_memory);
    rst_n  = 0;
    ready  = 0;
    pix_in = 0;
    // Cấu hình Kernel (VD: Gaussian Blur, Tâm = 4)
    kernel[0] =  -1; kernel[1] = -2; kernel[2] = -1;
    kernel[3] = 0; kernel[4] = 0; kernel[5] = 0;
    kernel[6] =  1; kernel[7] = 2; kernel[8] = 1;
    // for (int i=0; i<9; i++) kernel[i] = 4'd1;
    #25;
    rst_n = 1;
    #20;
    ready = 1;
    // Bơm toàn bộ 65536 pixels vào mạch
    for (int i = 0; i < TOTAL_PIXELS; i++) begin
      @(posedge clk);
      pix_in = img_memory[i];
    end
    for (int i = 0; i < 200; i++) begin
      @(posedge clk);
      pix_in = 8'h00; // Bơm rác hoặc 0 vào, vì i_valid_window sẽ tự động ngắt
    end
    // QUAN TRỌNG: Chờ Line Buffer và Pipeline xả nốt hàng cuối cùng ra ngoài
    // (Line buffer trễ ~258 clock, MAC trễ 3 clock -> Chờ 500 clock là an toàn tuyệt đối)
    $display("Đã bơm xong ảnh và xả xong Pipeline. Kết thúc mô phỏng!");
    // Bắt buộc gọi fclose tại đây để ép Hệ điều hành lưu data xuống ổ cứng
    $fclose(file_out); 
    $finish;
  end
  // Tiến trình 2: Chỉ làm nhiệm vụ Lắng nghe và Ghi file (Không kiểm soát $finish nữa)
  initial begin
    file_out = $fopen("../02_sim/python_sim/output_img.hex", "w");
    if (file_out == 0) begin
      $display("Lỗi: Không thể tạo file output!");
      $finish;
    end
    forever begin
      @(posedge clk);
      // Chỉ bắt những dữ liệu có cờ Valid
      if (valid_out === 1'b1) begin
        $fwrite(file_out, "%02X\n", pix_out);
      end
    end
  end
endmodule