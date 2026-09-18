//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Pixel Intensity and Weighted Coefficiency MAC
// File            : mac_bilateral.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 14/09/2026
//============================================================================================================
import package_param::*;
module mac_bilateral #(
  parameter WIDTH_PX = 8,      // 8bit for 1 pixel
  parameter WIDTH_WC = 9,      // 4bit for kernel's coefficiency from [-8:7]
  parameter GUARD_BIT = 4,     // guard bit = log2(WIDTH_MUL)             
  parameter WIDTH_MUL = 17
)(
  input  logic                             i_clk,
  input  logic                             ni_rst,
  input  logic                             i_mac_en,
  input  logic [8:0][WIDTH_PX-1:0]         i_px,
  input  logic [8:0][WIDTH_WC-1:0]         i_wc,
  output logic                             o_mac_valid,
  output logic [(WIDTH_MUL+GUARD_BIT)-1:0] o_mac_num_out,
  output logic [(WIDTH_WC+GUARD_BIT)-1:0]  o_mac_den_out
);
//========================DECLARATION========================================================================================
  package_param::mul_add_bilateral       mul_add_reg,    mul_add_next;     
  package_param::add_add_bilateral       add_add_reg,    add_add_next;     
  package_param::add_accum_bilateral     add_accum_reg,  add_accum_next;
  logic [3:0]                            valid_shift_reg;
  logic [8:0][WIDTH_MUL-1:0]             mul_result;
  logic [8:0][(WIDTH_MUL+GUARD_BIT)-1:0] op_mul;
  logic [8:0][(WIDTH_WC+GUARD_BIT)-1:0] op_wc;
  logic [7:0][(WIDTH_MUL+GUARD_BIT)-1:0] add_accum;
  logic [7:0][(WIDTH_WC+GUARD_BIT)-1:0]  den_accum;
//========================PIPELINE CONTROL====================================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin : valid_tracking_register
    if (~ni_rst) begin
      valid_shift_reg <= 4'b0;
    end else begin
      valid_shift_reg <= {valid_shift_reg[2:0], i_mac_en}; 
    end
  end
  assign o_mac_valid = valid_shift_reg[3];
//========================STAGE 1: MULTIPLIER==================================================================================
  genvar i;
  generate
    for (i = 0; i < 9 ; i++) begin: nine_mul
      mul_bilateral #(
        .WIDTH_PX(WIDTH_PX),
        .WIDTH_WC(WIDTH_WC),
        .WIDTH_MUL(WIDTH_MUL)
    ) multiplier (
        .i_px(i_px[i]),
        .i_wc(i_wc[i]),
        .o_mul(mul_result[i])
      );
      assign op_mul[i] = {{GUARD_BIT{1'b0}}, mul_result[i]};    // unsign 
      assign op_wc[i]  = {{GUARD_BIT{1'b0}}, i_wc[i]}; 
    end
  endgenerate
  //--------------------WEIGHTED_COEFFICENCY_ACCUMULATE-----------------------------------------------------------------------------
  cla_adder_13bit adder_den_0 (.a_i(op_wc[0]),.b_i(op_wc[1]),.cin_i(1'b0),.result_o(den_accum[0]),.cout_o());
  cla_adder_13bit adder_den_1 (.a_i(op_wc[2]),.b_i(op_wc[3]),.cin_i(1'b0),.result_o(den_accum[1]),.cout_o());
  cla_adder_13bit adder_den_2 (.a_i(op_wc[4]),.b_i(op_wc[5]),.cin_i(1'b0),.result_o(den_accum[2]),.cout_o());
  cla_adder_13bit adder_den_3 (.a_i(op_wc[6]),.b_i(op_wc[7]),.cin_i(1'b0),.result_o(den_accum[3]),.cout_o());
  always_comb begin: mul_stage
    mul_add_next.op_mul           = op_mul;
    mul_add_next.den_wc8_delay    = op_wc[8];
    mul_add_next.den_accum_lv1    = den_accum[3:0];
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : mul_add_register
    if(~ni_rst) begin
      mul_add_reg <= '0;
    end else if (i_mac_en) begin
      mul_add_reg <= mul_add_next;
    end
  end
//========================STAGE 2: ADDER LEVEL 1========================================================================================
  //--------------------MUL_ACCUMULATE---------------------------------------------------------------------------------------------
  cla_adder_21bit adder_num_0 (.a_i(mul_add_reg.op_mul[0]),.b_i(mul_add_reg.op_mul[1]),.cin_i(1'b0),.result_o(add_accum[0]),.cout_o());
  cla_adder_21bit adder_num_1 (.a_i(mul_add_reg.op_mul[2]),.b_i(mul_add_reg.op_mul[3]),.cin_i(1'b0),.result_o(add_accum[1]),.cout_o());
  cla_adder_21bit adder_num_2 (.a_i(mul_add_reg.op_mul[4]),.b_i(mul_add_reg.op_mul[5]),.cin_i(1'b0),.result_o(add_accum[2]),.cout_o());
  cla_adder_21bit adder_num_3 (.a_i(mul_add_reg.op_mul[6]),.b_i(mul_add_reg.op_mul[7]),.cin_i(1'b0),.result_o(add_accum[3]),.cout_o());
  //--------------------WEIGHTED_COEFFICENCY_ACCUMULATE-----------------------------------------------------------------------------
  cla_adder_13bit adder_den_4 (.a_i(mul_add_reg.den_accum_lv1[0]),.b_i(mul_add_reg.den_accum_lv1[1]),.cin_i(1'b0),.result_o(den_accum[4]),.cout_o());
  cla_adder_13bit adder_den_5 (.a_i(mul_add_reg.den_accum_lv1[2]),.b_i(mul_add_reg.den_accum_lv1[3]),.cin_i(1'b0),.result_o(den_accum[5]),.cout_o());
  always_comb begin: add_stage
    add_add_next.add_out       = add_accum[3:0];
    add_add_next.den_wc8_delay = mul_add_reg.den_wc8_delay;
    add_add_next.den_accum_lv2 = den_accum[5:4];
    add_add_next.op_mul8_delay = mul_add_reg.op_mul[8];
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : add_add_register
    if(~ni_rst) begin
      add_add_reg <= '0;
    end else if (valid_shift_reg[0]) begin
      add_add_reg <= add_add_next;
    end
  end
//========================STAGE 3: ACCUMULATOR=============================================================================================
  //--------------------MUL_ACCUMULATE---------------------------------------------------------------------------------------------
  cla_adder_21bit adder4 (.a_i(add_add_reg.add_out[0]), .b_i(add_add_reg.add_out[1]), .cin_i(1'b0), .result_o(add_accum[4]), .cout_o());
  cla_adder_21bit adder5 (.a_i(add_add_reg.add_out[2]), .b_i(add_add_reg.add_out[3]), .cin_i(1'b0), .result_o(add_accum[5]), .cout_o());  
  //--------------------WEIGHTED_COEFFICENCY_ACCUMULATE-----------------------------------------------------------------------------
  cla_adder_13bit adder_den_6 (.a_i(add_add_reg.den_accum_lv2[0]),.b_i(add_add_reg.den_accum_lv2[1]),.cin_i(1'b0),.result_o(den_accum[6]),.cout_o());
  always_comb begin: add_accum_stage
    add_accum_next.add_final       = add_accum[5:4];
    add_accum_next.den_accum_lv3   = den_accum[6];
    add_accum_next.den_wc8_delay     = add_add_reg.den_wc8_delay;
    add_accum_next.op_mul8_delay   = add_add_reg.op_mul8_delay;
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin : add_accum_register
    if(~ni_rst) begin
      add_accum_reg <= '0;
    end else if (valid_shift_reg[1]) begin
      add_accum_reg <= add_accum_next;
    end
  end  
//========================STAGE 4: FINAL RESULT========================
  //--------------------MUL_ACCUMULATE---------------------------------------------------------------------------------------------
  cla_adder_21bit adder6 (.a_i(add_accum_reg.add_final[0]), .b_i(add_accum_reg.add_final[1]), .cin_i(1'b0), .result_o(add_accum[6]), .cout_o());
  cla_adder_21bit adder7 (.a_i(add_accum_reg.op_mul8_delay), .b_i(add_accum[6]), .cin_i(1'b0), .result_o(add_accum[7]), .cout_o());
  //--------------------WEIGHTED_COEFFICENCY_ACCUMULATE-----------------------------------------------------------------------------
  cla_adder_13bit adder_den_7 (.a_i(add_accum_reg.den_accum_lv3[0]),.b_i(add_accum_reg.den_wc8_delay),.cin_i(1'b0),.result_o(den_accum[7]),.cout_o());
  always_ff @(posedge i_clk or negedge ni_rst) begin : final_out_register
    if (~ni_rst) begin
      o_mac_num_out <= '0;
      o_mac_den_out <= '0;
    end else if (valid_shift_reg[2]) begin
    o_mac_num_out <= add_accum[7];
    o_mac_den_out <= den_accum[7];
    end
  end
endmodule