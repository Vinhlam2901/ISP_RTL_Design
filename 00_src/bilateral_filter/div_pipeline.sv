//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Non Restoring Division 8 Stage Pipeline
// File            : div_pipeline.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 15/09/2026
// Updated date    : 25/10/2026
//=============================================================================================================
import package_param::*;
module div_pipeline (
  input  logic                   i_clk,
  input  logic                   ni_rst,
  input  logic                   i_ready,
  input  logic                   i_valid,
  input  logic [WIDTH_REM-1:0]   i_rem,     
  input  logic [WIDTH_PIXEL-1:0] i_quoti,   
  input  logic [WIDTH_DEN-1:0]   i_den,     
  output logic                   o_valid,
  output logic [WIDTH_REM-1:0]   o_remain,  
  output logic [WIDTH_PIXEL-1:0] o_quoti    
);
//==============DECLARATION==============================================
  logic                   valid_reg     [0:7];
  logic [WIDTH_REM-1:0]   div_rem_out   [0:7];
  logic [WIDTH_PIXEL-1:0] div_quoti_out [0:7];
  logic [WIDTH_REM-1:0]   rem_reg       [0:7];
  logic [WIDTH_PIXEL-1:0] quoti_reg     [0:7];
  logic [WIDTH_DEN-1:0]   den_reg       [0:7];
//==============8-STAGE PIPELINE GENERATION==============================
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin : gen_div_stages
      logic [WIDTH_REM-1:0]   current_rem_in;
      logic [WIDTH_PIXEL-1:0] current_quoti_in;
      logic [WIDTH_DEN-1:0]   current_den_in;
      // Sử dụng Generate If để tạo 2 kiến trúc phần cứng riêng biệt
      if (i == 0) begin : gen_stage_0
        // Tầng 0: Lấy trực tiếp dữ liệu ngõ vào, hoàn toàn không dính đến [i-1]
        always_comb begin
          current_rem_in   = i_rem;
          current_quoti_in = i_quoti;
          current_den_in   = i_den;
        end
        always_ff @(posedge i_clk or negedge ni_rst) begin
          if (~ni_rst) begin
            rem_reg[i]   <= '0;
            quoti_reg[i] <= '0;
            den_reg[i]   <= '0;
            valid_reg[i] <= 1'b0;
          end else if (i_ready) begin
            rem_reg[i]   <= div_rem_out[i];
            quoti_reg[i] <= div_quoti_out[i];
            den_reg[i]   <= current_den_in;
            valid_reg[i] <= i_valid; // Đọc trực tiếp từ Input
          end
        end
      end else begin : gen_stage_n
        // Tầng 1 đến 7: Lấy dữ liệu từ tầng trước (i-1) an toàn
        always_comb begin
          current_rem_in   = rem_reg[i-1];
          current_quoti_in = quoti_reg[i-1];
          current_den_in   = den_reg[i-1];
        end
        always_ff @(posedge i_clk) begin
          if (~ni_rst) begin
            rem_reg[i]   <= '0;
            quoti_reg[i] <= '0;
            den_reg[i]   <= '0;
            valid_reg[i] <= 1'b0;
          end else if (i_ready) begin
            rem_reg[i]   <= div_rem_out[i];
            quoti_reg[i] <= div_quoti_out[i];
            den_reg[i]   <= current_den_in;
            valid_reg[i] <= valid_reg[i-1]; // Đọc từ thanh ghi Pipeline trước
          end
        end
      end
      // Khối toán học dùng chung cho mọi tầng
      non_res_div div_inst (
        .i_rem    (current_rem_in),
        .i_quoti  (current_quoti_in),
        .i_den    (current_den_in),
        .o_remain (div_rem_out[i]),
        .o_quoti  (div_quoti_out[i])
      );
    end
  endgenerate
//==============OUTPUT ASSIGNMENT========================================
  assign o_valid  = valid_reg[7];
  assign o_remain = rem_reg[7][WIDTH_REM-1] ? (rem_reg[7] + {1'b0, den_reg[7]}) : rem_reg[7];
  assign o_quoti  = quoti_reg[7];
endmodule