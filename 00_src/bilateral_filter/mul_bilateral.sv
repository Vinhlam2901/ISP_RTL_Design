//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Multiplier Booth - Wallace - CLA
// File            : mul_bilateral.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 02/07/2026
// Updated date    : 02/07/2026
//============================================================================================================
module mul_bilateral #(
	parameter WIDTH_PX  = 8,
	parameter WIDTH_WC  = 9,
	parameter WIDTH_MUL = 17
)(
	input  logic [WIDTH_PX-1:0]  px_i,
	input  logic [WIDTH_WC-1:0]  wc_i,
	output logic [WIDTH_MUL-1:0] mul_o
);
//===========================DECLARATION=======================================
	logic                                   cout_o;
  logic [WIDTH_MUL-1:0]                   neg_vector;
	logic [(WIDTH_WC/2)-1:0][WIDTH_PX+1:0]  pp_o;
  logic [(WIDTH_WC/2)-1:0][WIDTH_MUL-1:0] concat_pp;
	logic [(WIDTH_WC/2)-1:0]                neg_o;
	logic [WIDTH_MUL-1:0]                   sum_partial;
	logic [WIDTH_MUL-1:0]                   carry_partial;
  logic [WIDTH_MUL-1:0]                   sum1, carry1;
  logic [WIDTH_MUL-1:0]                   sum2, carry2;
  logic [WIDTH_MUL-1:0]                   sum3, carry3;
  logic [WIDTH_MUL-1:0]                   sum4, carry4;
//===========================INSTANTIATION=======================================
  booth_encoder #(
    .WIDTH_PX(WIDTH_PX),
    .WIDTH_WC(WIDTH_WC+1)
  ) booth_encoder (
    .opa_i(px_i),
    .opb_i({1'b0, wc_i}),
		.neg_o(neg_o),
		.pp_o(pp_o)
	);
  //---------------CONCATENATION_PARTIAL-------------------------
	always_comb begin : concat_partial
    concat_pp[0] = {{7{pp_o[0][9]}}, pp_o[0]           }; 
    concat_pp[1] = {{5{pp_o[1][9]}}, pp_o[1], {2{1'b0}}}; 
    concat_pp[2] = {{3{pp_o[2][9]}}, pp_o[2], {4{1'b0}}}; 
    concat_pp[3] = {{1{pp_o[3][9]}}, pp_o[3], {6{1'b0}}}; 
    concat_pp[4] = {   pp_o[4][8:0],          {8{1'b0}}};
    neg_vector   = {8'b0, neg_o[4], 1'b0, neg_o[3], 1'b0, neg_o[2], 1'b0, neg_o[1], 1'b0, neg_o[0]};
	end
  csa_17bit level1 (
    .a_i    (concat_pp[0]), 
    .b_i    (concat_pp[1]), 
    .c_i    (concat_pp[2]),
    .sum_o  (sum1), 
    .carry_o(carry1)
  );
  csa_17bit level2 (
    .a_i    (sum1), 
    .b_i    ({carry1[15:0], 1'b0}), 
    .c_i    (concat_pp[3]),
    .sum_o  (sum2), 
    .carry_o(carry2)
  );
  csa_17bit level3 (
    .a_i    (sum2), 
    .b_i    ({carry2[15:0], 1'b0}), 
    .c_i    (concat_pp[4]),
    .sum_o  (sum3), 
    .carry_o(carry3)
  );
  csa_17bit level4 (
    .a_i    (sum3), 
    .b_i    ({carry3[15:0], 1'b0}), 
    .c_i    (neg_vector),
    .sum_o  (sum4), 
    .carry_o(carry4)
  );
  //---------------FINAL_ADDITION-------------------
  cla_adder_17bit final_cla (
    .a_i     (sum4),
    .b_i     ({carry4[15:0], 1'b0}),
    .cin_i   (1'b0),
    .cout_o  (cout_o),
    .result_o(mul_o)
  );

endmodule