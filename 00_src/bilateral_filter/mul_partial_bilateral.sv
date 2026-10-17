//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Multiplier Booth - Wallace - CLA
// File            : mul_bilateral.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 02/07/2026
// Updated date    : 04/10/2026
//============================================================================================================
module mul_partial_bilateral #(
  parameter WIDTH_PX  = 8,
  parameter WIDTH_WC  = 10,
  parameter WIDTH_MUL = 22
)(
  input  logic [WIDTH_PX-1:0]  i_px,
  input  logic [WIDTH_WC-1:0]  i_wc,
  output logic [WIDTH_MUL-1:0] o_sum_partial,
  output logic [WIDTH_MUL-1:0] o_carry_partial
);
//===========================DECLARATION=======================================
  logic [((WIDTH_WC+1)/2)-1:0]                neg_o;
  logic [((WIDTH_WC+1)/2)-1:0][WIDTH_PX+1:0]  pp_o;
  logic [((WIDTH_WC+1)/2)-1:0][WIDTH_MUL-1:0] concat_pp;
  logic                       [WIDTH_MUL-1:0] neg_vector;
  logic                       [WIDTH_MUL-1:0] sum1, carry1;
  logic                       [WIDTH_MUL-1:0] sum2, carry2;
  logic                       [WIDTH_MUL-1:0] sum3, carry3;
  logic                       [WIDTH_MUL-1:0] sum4, carry4;
//===========================INSTANTIATION=======================================
  booth_encoder #(
    .WIDTH_OPA(WIDTH_PX),
    .WIDTH_OPB(WIDTH_WC)
  ) booth_encoder (
    .opa_i(i_px),
    .opb_i(i_wc),
    .neg_o(neg_o),
    .pp_o(pp_o)
  );
  //---------------CONCATENATION_PARTIAL-------------------------
  always_comb begin : concat_partial
    concat_pp[0] = {{12{pp_o[0][9]}}, pp_o[0]           }; // 11 + 10 = 21 bit
    concat_pp[1] = {{10{pp_o[1][9]}}, pp_o[1], {2{1'b0}}}; // 10 + 10 + 2 = 21 bit
    concat_pp[2] = {{8{pp_o[2][9]}},  pp_o[2], {4{1'b0}}}; // 8 + 10 + 4 = 21 bit
    concat_pp[3] = {{6{pp_o[3][9]}},  pp_o[3], {6{1'b0}}}; // 6 + 10 + 6 = 21 bit
    concat_pp[4] = {{4{pp_o[4][9]}},  pp_o[4], {8{1'b0}}}; // 4 + 10 + 8 = 21 bit
    // Căn chỉnh Vector bù 2 (neg_o) cho hệ 21-bit
    neg_vector   = {13'b0, neg_o[4], 1'b0, neg_o[3], 1'b0, neg_o[2], 1'b0, neg_o[1], 1'b0, neg_o[0]};
  end
  //---------------LOCAL COMPRESSOR TREE-------------------------
  csa #(.WIDTH(22)) level1 (.a_i(concat_pp[0]),.b_i(concat_pp[1]),        .c_i(concat_pp[2]),.sum_o(sum1),.carry_o(carry1));
  csa #(.WIDTH(22)) level2 (.a_i(sum1),        .b_i({carry1[20:0], 1'b0}),.c_i(concat_pp[3]),.sum_o(sum2),.carry_o(carry2));
  csa #(.WIDTH(22)) level3 (.a_i(sum2),        .b_i({carry2[20:0], 1'b0}),.c_i(concat_pp[4]),.sum_o(sum3),.carry_o(carry3));
  csa #(.WIDTH(22)) level4 (.a_i(sum3),        .b_i({carry3[20:0], 1'b0}),.c_i(neg_vector),  .sum_o(sum4),.carry_o(carry4));
  //---------------OUTPUT ASSIGNMENT-------------------
  assign o_sum_partial   = sum4;
  assign o_carry_partial = {carry4[20:0], 1'b0};
endmodule