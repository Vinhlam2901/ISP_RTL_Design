//===========================================================================================================
// Project         : Convolution with 3 kernels Sobel, Blur and Sharpening
// Module          : Multiplier Acumulator
// File            : cla_adder_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 07/07/2026
// Updated date    : 16/07/2026
//============================================================================================================
import package_param::*;
module mac #(
  parameter WIDTH_MAC = 12,
  parameter WIDTH_OPA = 8,      // 8bit for 1 pixel
  parameter WIDTH_OPB = 4,      // 4bit for kernel's coefficiency from [-8:7]
  parameter GUARD_BIT = 4       // guard bit = log2(WIDTH_MAC)             
)(
  input  logic                             i_clk,
  input  logic                             ni_rst,
  input  logic                             mac_en_i,
  input  logic [8:0][WIDTH_OPA-1:0]        opa_i,
  input  logic [8:0][WIDTH_OPB-1:0]        opb_i,
  output logic                             mac_valid_o,
  output logic [(WIDTH_MAC+GUARD_BIT)-1:0] mac_out
);
//========================DECLARATION========================================================================================
  package_param::mul_add_stage    mul_add_reg,    mul_add_next;     
  package_param::add_add_stage    add_add_reg,    add_add_next;     
  package_param::add_accum_stage  add_accum_reg,  add_accum_next;
  logic [3:0]                            valid_shift_reg;
  logic [8:0][WIDTH_MAC-1:0]             mul_result;
  logic [8:0][(WIDTH_MAC+GUARD_BIT)-1:0] op_mul;
  logic [7:0][(WIDTH_MAC+GUARD_BIT)-1:0] add_accum;
//========================PIPELINE CONTROL====================================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin : valid_tracking_register
    if (~ni_rst) begin
      valid_shift_reg <= 4'b0;
    end else begin
      // Dịch 3 bit cũ và nạp bit mới vào
      valid_shift_reg <= {valid_shift_reg[2:0], mac_en_i}; 
    end
  end
  assign mac_valid_o = valid_shift_reg[3];
//========================STAGE 1: MULTIPLIER==================================================================================
  genvar i;
  generate
    for (i = 0; i < 9 ; i++) begin: nine_mul
      mul multiplier (
        .opa_i(opa_i[i]),
        .opb_i(opb_i[i]),
        .mul_o(mul_result[i])
      );
      assign op_mul[i] = {{GUARD_BIT{mul_result[i][WIDTH_MAC-1]}}, mul_result[i]};
    end
  endgenerate
  always_comb begin: mul_stage
    mul_add_next.op_mul = op_mul;
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : mul_add_register
    if(~ni_rst) begin
      mul_add_reg.op_mul <= '0;
    // Tầng 1: Sử dụng tín hiệu Enable ngõ vào làm cờ Clock Enable
    end else if (mac_en_i) begin
      mul_add_reg.op_mul <= mul_add_next.op_mul;
    end
  end
//========================STAGE 2: ADDER LEVEL 1========================================================================================
  cla_adder_16bit adder0 (.a_i(mul_add_reg.op_mul[0]),.b_i(mul_add_reg.op_mul[1]),.cin_i(1'b0),.result_o(add_accum[0]),.cout_o());
  cla_adder_16bit adder1 (.a_i(mul_add_reg.op_mul[2]),.b_i(mul_add_reg.op_mul[3]),.cin_i(1'b0),.result_o(add_accum[1]),.cout_o());
  cla_adder_16bit adder2 (.a_i(mul_add_reg.op_mul[4]),.b_i(mul_add_reg.op_mul[5]),.cin_i(1'b0),.result_o(add_accum[2]),.cout_o());
  cla_adder_16bit adder3 (.a_i(mul_add_reg.op_mul[6]),.b_i(mul_add_reg.op_mul[7]),.cin_i(1'b0),.result_o(add_accum[3]),.cout_o());
  always_comb begin: add_stage
    add_add_next.add_out       = add_accum[3:0];
    add_add_next.op_mul8_delay = mul_add_reg.op_mul[8];
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : add_add_register
    if(~ni_rst) begin
      add_add_reg <= '0;
    // Tầng 2: Sử dụng cờ Valid của tầng trước làm Clock Enable
    end else if (valid_shift_reg[0]) begin
      add_add_reg <= add_add_next;
    end
  end
//========================STAGE 3: ACCUMULATOR========================
  cla_adder_16bit adder4 (.a_i(add_add_reg.add_out[0]), .b_i(add_add_reg.add_out[1]), .cin_i(1'b0), .result_o(add_accum[4]), .cout_o());
  cla_adder_16bit adder5 (.a_i(add_add_reg.add_out[2]), .b_i(add_add_reg.add_out[3]), .cin_i(1'b0), .result_o(add_accum[5]), .cout_o());  
  always_comb begin: add_accum_stage
    add_accum_next.add_final[0]    = add_accum[4];
    add_accum_next.add_final[1]    = add_accum[5];
    add_accum_next.op_mul8_delay = add_add_reg.op_mul8_delay;
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : add_accum_register
    if(~ni_rst) begin
      add_accum_reg <= '0;
    end else if (valid_shift_reg[1]) begin
      add_accum_reg <= add_accum_next;
    end
  end  
//========================STAGE 4: FINAL RESULT========================
  cla_adder_16bit adder6 (.a_i(add_accum_reg.add_final[0]), .b_i(add_accum_reg.add_final[1]), .cin_i(1'b0), .result_o(add_accum[6]), .cout_o());
  cla_adder_16bit adder7 (.a_i(add_accum_reg.op_mul8_delay), .b_i(add_accum[6]), .cin_i(1'b0), .result_o(add_accum[7]), .cout_o());
  always_ff @(posedge i_clk or negedge ni_rst) begin : final_out_register
    if (~ni_rst) begin
      mac_out <= '0;
    end else if (valid_shift_reg[2]) begin
    mac_out <= add_accum[7];
    end
  end
endmodule