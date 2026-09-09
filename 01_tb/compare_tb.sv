module compare_tb;

  // 1. Khai báo tín hiệu kết nối với DUT
  logic [7:0] a, b, c;
  logic [7:0] min_o, med_o, max_o;

  // Tín hiệu dùng để lưu kết quả mong đợi (Golden Model)
  logic [7:0] exp_min, exp_med, exp_max;

  // 2. Khởi tạo thiết kế cần kiểm tra (DUT)
  compare dut (
    .a_i(a),
    .b_i(b),
    .c_i(c),
    .min_o(min_o),
    .med_o(med_o),
    .max_o(max_o)
  );

  // 3. Task tự động kiểm tra kết quả (Self-checking)
  task check_results(input logic [7:0] test_a, test_b, test_c);
    begin
      // Cấp giá trị đầu vào
      a = test_a; 
      b = test_b; 
      c = test_c;
      
      // Chờ 10 đơn vị thời gian để mạch tổ hợp lan truyền tín hiệu (Propagation Delay)
      #10; 

      // Mô hình phần mềm tính toán kết quả chuẩn (Behavioral Sorting)
      if (a <= b && a <= c) begin
        exp_min = a;
        if (b <= c) begin exp_med = b; exp_max = c; end
        else        begin exp_med = c; exp_max = b; end
      end else if (b <= a && b <= c) begin
        exp_min = b;
        if (a <= c) begin exp_med = a; exp_max = c; end
        else        begin exp_med = c; exp_max = a; end
      end else begin
        exp_min = c;
        if (a <= b) begin exp_med = a; exp_max = b; end
        else        begin exp_med = b; exp_max = a; end
      end

      // Đối chiếu kết quả ngõ ra của RTL với Golden Model
      if (min_o !== exp_min || med_o !== exp_med || max_o !== exp_max) begin
        $display("[FAIL] Tại t=%0t: a=%0d, b=%0d, c=%0d", $time, a, b, c);
        $display("  -> (Expected): min=%0d, med=%0d, max=%0d", exp_min, exp_med, exp_max);
        $display("  -> (DUT)     : min=%0d, med=%0d, max=%0d", min_o, med_o, max_o);
      end else begin
        $display("[PASS] a=%0d, b=%0d, c=%0d -> min=%0d, med=%0d, max=%0d", a, b, c, min_o, med_o, max_o);
      end
    end
  endtask

  // 4. Kịch bản mô phỏng (Stimulus)
  initial begin
    // Bật xuất file waveform để xem sóng trên gtkwave hoặc ModelSim
    $dumpfile("dump.vcd");
    $dumpvars(0, compare_tb);

    $display("=== BẮT ĐẦU MÔ PHỎNG ===");

    // Kịch bản 1: Các trường hợp góc (Corner Cases)
    check_results(8'd10, 8'd50, 8'd90);   // Tăng dần
    check_results(8'd120, 8'd80, 8'd30);  // Giảm dần
    check_results(8'd50, 8'd50, 8'd50);   // Bằng nhau tất cả
    check_results(8'd200, 8'd50, 8'd200); // 2 số bằng nhau ở biên
    check_results(8'd255, 8'd0, 8'd127);  // Các giá trị min, max, mid của 8-bit

    // Kịch bản 2: Bơm dữ liệu ngẫu nhiên (Randomized Tests)
    $display("--- CHẠY TEST NGẪU NHIÊN ---");
    for (int i = 0; i < 10; i++) begin
      check_results($urandom_range(0, 255), $urandom_range(0, 255), $urandom_range(0, 255));
    end

    $display("=== HOÀN THÀNH MÔ PHỎNG ===");
    $finish;
  end

endmodule