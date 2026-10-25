//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Multiplier Booth - Wallace - CLA
// File            : mac.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 02/07/2026
// Updated date    : 02/07/2026
//============================================================================================================
import package_param::*;
module mul (
	input  logic [WIDTH_PIXEL-1:0]  opa_i,
	input  logic [WIDTH_KERNEL-1:0] opb_i,
	output logic [WIDTH_MAC-1:0]    mul_o       // 15bit
);
//===========================DECLARATION=======================================
  localparam int WIDTH_MUL_CORE = WIDTH_PIXEL + WIDTH_KERNEL;
	logic                                            cout_o;
	logic [(WIDTH_KERNEL/2)-1:0][WIDTH_PIXEL+1:0]    pp_o;
  logic [(WIDTH_KERNEL/2)-1:0][WIDTH_MUL_CORE-1:0] concat_pp;
	logic [(WIDTH_KERNEL/2)-1:0]                     neg_o;
	logic [WIDTH_MUL_CORE-1:0]                       mul_out;
	logic [WIDTH_MUL_CORE-1:0]                       sum_partial;
	logic [WIDTH_MUL_CORE-1:0]                       carry_partial;
//===========================INSTANTIATION=======================================
	booth_encoder booth (
		.opa_i(opa_i),
		.opb_i(opb_i),
		.neg_o(neg_o),
		.pp_o(pp_o)     // 10bit
	);
  //---------------CONCATENATION_PARTIAL-------------------------
	always_comb begin : concat_partial
		concat_pp[0] = {{(WIDTH_MUL_CORE-(WIDTH_PIXEL+2)){pp_o[0][WIDTH_PIXEL+1]}}, pp_o[0]};
		concat_pp[1] = {pp_o[1], 2'b0};
	end
	always_comb begin : carry_save_stage
    //-------------- BIT 0: HALF_ADDER -------------------
    sum_partial[0]   = concat_pp[0][0] ^ neg_o[0];
    carry_partial[0] = concat_pp[0][0] & neg_o[0];
    //-------------- BIT 1: STRAIGHT FORWARD -------------
    // Vì concat_pp[1][1:0] luôn là 2'b00 do dịch trái 2 bit
    sum_partial[1]   = concat_pp[0][1];
    carry_partial[1] = 1'b0;
    //-------------- BIT 2: FULL_ADDER -------------------
    // Cộng pp0[2], pp1[2], và neg_o[1]
    sum_partial[2]   = concat_pp[0][2] ^ concat_pp[1][2] ^ neg_o[1];
    carry_partial[2] = (concat_pp[0][2] & concat_pp[1][2]) | 
                       (concat_pp[0][2] & neg_o[1])        | 
                       (concat_pp[1][2] & neg_o[1]);
    //-------------- BIT 3: HALF_ADDER -------------------
    sum_partial[3]   = concat_pp[0][3] ^ concat_pp[1][3];
    carry_partial[3] = concat_pp[0][3] & concat_pp[1][3];
    //-------------- BIT 11:4 : ARRAY OF HALF_ADDERS -----
    sum_partial[11:4]   = concat_pp[0][11:4] ^ concat_pp[1][11:4];
    carry_partial[11:4] = concat_pp[0][11:4] & concat_pp[1][11:4];
  end
  cla_nbit # (.WIDTH_CLA(WIDTH_MUL_CORE)) final_cla (
    .a(sum_partial),
    .b({carry_partial[WIDTH_MUL_CORE-2:0], 1'b0}), 
    .cin(1'b0),
    .sum(mul_out),
    .cout(cout_o)
  );
  assign mul_o = {{(WIDTH_MAC - WIDTH_MUL_CORE){mul_out[WIDTH_MUL_CORE-1]}}, mul_out};
endmodule