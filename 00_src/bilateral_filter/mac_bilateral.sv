//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Pixel Intensity and Weighted Coefficiency MAC
// File            : mac_bilateral.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 25/10/2026
//============================================================================================================
import package_param::*;
module mac_bilateral (
  input  logic                          i_clk,
  input  logic                          ni_rst,
  input  logic                          i_mac_en,
  input  logic [8:0][WIDTH_PIXEL-1:0]   i_px,
  input  logic [8:0][WIDTH_WC-1:0]      i_wc,
  output logic                          o_mac_valid,
  output logic      [WIDTH_MUL_MAC-1:0] o_mac_num_out,
  output logic      [WIDTH_WC_MAC-1:0]  o_mac_den_out
);
//========================DECLARATION=======================================================================
  logic [3:0]                    valid_shift_reg;
  logic [8:0][WIDTH_MUL_MAC-1:0] sum_partial;
  logic [8:0][WIDTH_MUL_MAC-1:0] carry_partial;
  logic [8:0][WIDTH_MUL_MAC-1:0] sum_partial_ext;
  logic [8:0][WIDTH_MUL_MAC-1:0] carry_partial_ext;
  logic [5:0][WIDTH_MUL_MAC-1:0] sum1, carry1;
  logic [3:0][WIDTH_MUL_MAC-1:0] sum2, carry2;
  logic [1:0][WIDTH_MUL_MAC-1:0] sum3, carry3;
  logic [1:0][WIDTH_MUL_MAC-1:0] sum4, carry4;
  logic      [WIDTH_MUL_MAC-1:0] sum5, carry5;
  logic      [WIDTH_MUL_MAC-1:0] global_sum_nxt, global_carry_nxt;
  logic      [WIDTH_MUL_MAC-1:0] mac_num_final;
  logic [8:0][WIDTH_WC_MAC-1:0]  wc_ext;
  logic [3:0][WIDTH_WC_MAC-1:0]  den1_nxt;
  logic [1:0][WIDTH_WC_MAC-1:0]  den2_nxt;
  logic      [WIDTH_WC_MAC-1:0]  den3_nxt;
  logic      [WIDTH_WC_MAC-1:0]  mac_den_final;
  package_param::MAC_STAGE1_REG  stage1_reg;
  package_param::MAC_STAGE2_REG  stage2_reg;
  package_param::MAC_STAGE3_REG  stage3_reg;

//========================PIPELINE CONTROL==================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin : valid_tracking_register
    if (~ni_rst) begin
      valid_shift_reg <= 4'b0;
    end else begin
      valid_shift_reg <= {valid_shift_reg[2:0], i_mac_en}; 
    end
  end
  assign o_mac_valid = valid_shift_reg[3];
//========================STAGE 1: MULTIPLIER & CSA LEVEL 1================================================
  genvar i;
  generate
    for (i = 0; i < 9; i++) begin: nine_encode   
      mul_partial_bilateral encode_partial (
        .i_px           (i_px[i]),
        .i_wc           (i_wc[i]),
        .o_sum_partial  (sum_partial_ext[i]),
        .o_carry_partial(carry_partial_ext[i])
      );
      // Weighted Coefficency zero-extend 14bit
      assign wc_ext[i] = {{4{1'b0}}, i_wc[i]};
    end
  endgenerate
  //--------------------WEIGHTED_COEFFICENCY_ACCUMULATE-----------------------------------------------------------------------------
  cla_nbit # (.WIDTH_CLA(14)) adder_den_0 (.a(wc_ext[0]),.b(wc_ext[1]), .cin(1'b0),.sum(den1_nxt[0]),.cout());
  cla_nbit # (.WIDTH_CLA(14)) adder_den_1 (.a(wc_ext[2]),.b(wc_ext[3]), .cin(1'b0),.sum(den1_nxt[1]),.cout());
  cla_nbit # (.WIDTH_CLA(14)) adder_den_2 (.a(wc_ext[4]),.b(wc_ext[5]), .cin(1'b0),.sum(den1_nxt[2]),.cout());
  cla_nbit # (.WIDTH_CLA(14)) adder_den_3 (.a(wc_ext[6]),.b(wc_ext[7]), .cin(1'b0),.sum(den1_nxt[3]),.cout());
  // Tầng 1: Gom 18 vector -> 6 bộ CSA -> 12 vector (6 Sum, 6 Carry)
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl1_0 (.a_i(sum_partial_ext[0]), .b_i(carry_partial_ext[0]), .c_i(sum_partial_ext[1]),   .sum_o(sum1[0]), .carry_o(carry1[0]));
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl1_1 (.a_i(sum_partial_ext[2]), .b_i(carry_partial_ext[1]), .c_i(carry_partial_ext[2]), .sum_o(sum1[1]), .carry_o(carry1[1]));
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl1_2 (.a_i(sum_partial_ext[3]), .b_i(carry_partial_ext[3]), .c_i(sum_partial_ext[4]),   .sum_o(sum1[2]), .carry_o(carry1[2]));
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl1_3 (.a_i(sum_partial_ext[5]), .b_i(carry_partial_ext[4]), .c_i(carry_partial_ext[5]), .sum_o(sum1[3]), .carry_o(carry1[3]));
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl1_4 (.a_i(sum_partial_ext[6]), .b_i(carry_partial_ext[6]), .c_i(sum_partial_ext[7]),   .sum_o(sum1[4]), .carry_o(carry1[4]));
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl1_5 (.a_i(sum_partial_ext[8]), .b_i(carry_partial_ext[7]), .c_i(carry_partial_ext[8]), .sum_o(sum1[5]), .carry_o(carry1[5]));
  //------------------- PIPELINE REGISTER 1 -------------------
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if(!ni_rst) begin
      stage1_reg.sum1      <= '0;
      stage1_reg.carry1    <= '0;
      stage1_reg.den1      <= '0;
      stage1_reg.den_pass1 <= '0;
    end else if (i_mac_en) begin
      stage1_reg.sum1      <= sum1;
      stage1_reg.carry1    <= carry1;
      stage1_reg.den1      <= den1_nxt;
      stage1_reg.den_pass1 <= wc_ext[8];
    end
  end
//========================STAGE 2: CSA LEVEL 2 & 3=========================================================
  // Tầng 2: Gom 12 vector từ Stage 1 -> 4 bộ CSA -> 8 vector
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl2_0 (
    .a_i(stage1_reg.sum1[0]), 
    .b_i({stage1_reg.carry1[0][20:0], 1'b0}), 
    .c_i(stage1_reg.sum1[1]),
    .sum_o(sum2[0]), 
    .carry_o(carry2[0])
  );
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl2_1 (
    .a_i({stage1_reg.carry1[1][20:0], 1'b0}), 
    .b_i(stage1_reg.sum1[2]), 
    .c_i({stage1_reg.carry1[2][20:0], 1'b0}), 
    .sum_o(sum2[1]), .carry_o(carry2[1])
  );
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl2_2 (
    .a_i(stage1_reg.sum1[3]), 
    .b_i({stage1_reg.carry1[3][20:0], 1'b0}), 
    .c_i(stage1_reg.sum1[4]), 
    .sum_o(sum2[2]), 
    .carry_o(carry2[2])
  );
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl2_3 (
    .a_i({stage1_reg.carry1[4][20:0], 1'b0}), 
    .b_i(stage1_reg.sum1[5]), 
    .c_i({stage1_reg.carry1[5][20:0], 1'b0}), 
    .sum_o(sum2[3]), 
    .carry_o(carry2[3])
  );
  // Tầng 3: Gom 8 vector -> 2 bộ CSA (tiêu thụ 6) -> 6 vector (2 Sum, 2 Carry, 2 Bypass)
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl3_0 (
    .a_i(sum2[0]), 
    .b_i({carry2[0][20:0], 1'b0}), 
    .c_i(sum2[1]), 
    .sum_o(sum3[0]), 
    .carry_o(carry3[0])
  );
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl3_1 (
    .a_i({carry2[1][20:0], 1'b0}), 
    .b_i(sum2[2]), 
    .c_i({carry2[2][20:0], 1'b0}), 
    .sum_o(sum3[1]), 
    .carry_o(carry3[1])
  );
  cla_nbit # (.WIDTH_CLA(14)) adder_den_4 (.a(stage1_reg.den1[0]),.b(stage1_reg.den1[1]), .cin(1'b0),.sum(den2_nxt[0]),.cout());
  cla_nbit # (.WIDTH_CLA(14)) adder_den_5 (.a(stage1_reg.den1[2]),.b(stage1_reg.den1[3]), .cin(1'b0),.sum(den2_nxt[1]),.cout());
  // Bypass: sum2[3], carry2[3] xuống Pipeline Reg
  //------------------- PIPELINE REGISTER 2 -------------------
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if(!ni_rst) begin
      stage2_reg.sum2[1:0]   <= '0;
      stage2_reg.carry2[1:0] <= '0;
      stage2_reg.sum2[2]     <= '0; 
      stage2_reg.carry2[2]   <= '0; 
      stage2_reg.den2        <= '0;
      stage2_reg.den_pass2   <= '0;
    end else if (valid_shift_reg[0]) begin
      stage2_reg.sum2[1:0]   <= sum3;
      stage2_reg.carry2[1:0] <= carry3;
      stage2_reg.sum2[2]     <= sum2[3];    // Bypass
      stage2_reg.carry2[2]   <= carry2[3];  // Bypass
      stage2_reg.den2        <= den2_nxt;
      stage2_reg.den_pass2   <= stage1_reg.den_pass1;
    end
  end
//========================STAGE 3: CSA LEVEL 4, 5 & 6======================================================
  // Tầng 4: Gom 6 vector từ Stage 2 -> 2 bộ CSA -> 4 vector (2 Sum, 2 Carry)
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl4_0 (
    .a_i(stage2_reg.sum2[0]),
    .b_i({stage2_reg.carry2[0][20:0], 1'b0}), 
    .c_i(stage2_reg.sum2[1]), 
    .sum_o(sum4[0]), 
    .carry_o(carry4[0])
  );
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl4_1 (
    .a_i({stage2_reg.carry2[1][20:0], 1'b0}), 
    .b_i(stage2_reg.sum2[2]),             
    .c_i({stage2_reg.carry2[2][20:0], 1'b0}), 
    .sum_o(sum4[1]), 
    .carry_o(carry4[1])
  );
  // Tầng 5: Gom 4 vector -> 1 bộ CSA -> 3 vector (1 Sum, 1 Carry, 1 Bypass: carry4[1])
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl5_0 (
    .a_i(sum4[0]), 
    .b_i({carry4[0][20:0], 1'b0}), 
    .c_i(sum4[1]), 
    .sum_o(sum5), 
    .carry_o(carry5)
  );
  // Tầng 6: Gom 3 vector -> 1 bộ CSA -> 2 vector cuối cùng
  csa #(.WIDTH(WIDTH_MUL_MAC)) lvl6_0 (
    .a_i(sum5), 
    .b_i({carry5[20:0], 1'b0}), 
    .c_i({carry4[1][20:0], 1'b0}), 
    .sum_o(global_sum_nxt), 
    .carry_o(global_carry_nxt)
  );
  cla_nbit # (.WIDTH_CLA(14)) adder_den_6 (.a(stage2_reg.den2[0]),.b(stage2_reg.den2[1]), .cin(1'b0),.sum(den3_nxt),.cout());
  //------------------- PIPELINE REGISTER 3 -------------------
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if(!ni_rst) begin
      stage3_reg.sum4[0]   <= '0;
      stage3_reg.carry4[0] <= '0;
      stage3_reg.den3      <= '0;
      stage3_reg.den_pass3 <= '0;
    end else if (valid_shift_reg[1]) begin
      stage3_reg.sum4[0]   <= global_sum_nxt;
      stage3_reg.carry4[0] <= global_carry_nxt;
      stage3_reg.den3      <= den3_nxt;
      stage3_reg.den_pass3 <= stage2_reg.den_pass2;
    end
  end
//========================STAGE 4: FINAL ADDITION(CLA)====================================================
  cla_nbit # (.WIDTH_CLA(22)) final_num_cla (.a(stage3_reg.sum4[0]),.b({stage3_reg.carry4[0][20:0], 1'b0}), .cin(1'b0),.sum(mac_num_final),.cout());
  cla_nbit # (.WIDTH_CLA(14)) final_den_cla (.a(stage3_reg.den3),.b(stage3_reg.den_pass3), .cin(1'b0),.sum(mac_den_final),.cout());
  //------------------- OUTPUT REGISTER (TƯƠNG ĐƯƠNG PIPELINE REG 4) -------------------
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (~ni_rst) begin
      o_mac_num_out <= '0;
      o_mac_den_out <= '0;
    end else if (valid_shift_reg[2]) begin
      o_mac_num_out <= mac_num_final;
      o_mac_den_out <= mac_den_final;
    end
  end
endmodule