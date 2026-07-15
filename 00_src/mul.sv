//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Multiplier Booth - Wallace - CLA
// File            : mac.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 02/07/2026
// Updated date    : 02/07/2026
//============================================================================================================
module mul #(
	parameter WIDTH_OPA = 8,
	parameter WIDTH_OPB = 8,
	parameter WIDTH_MAC = 16
)(
	input  logic [WIDTH_OPA-1:0] opa_i,
	input  logic [WIDTH_OPB-1:0] opb_i,
	output logic [WIDTH_MAC-1:0] mul_o
);
//===========================DECLARATION=======================================
	logic                                    cout_o;
	logic [(WIDTH_OPB/2)-1:0][WIDTH_OPA:0]   pp_o;
	logic [(WIDTH_OPB/2)-1:0][WIDTH_MAC-1:0] concat_pp;
	logic [(WIDTH_OPB/2)-1:0]                neg_o;
	logic [WIDTH_MAC-1:0]                    sum_partial;
	logic [WIDTH_MAC-1:0]                    carry_partial;
//===========================INSTANTIATION=======================================
	booth_encoder #(
		.WIDTH_OPA(WIDTH_OPA),
		.WIDTH_OPB(WIDTH_OPB)
	) booth (
		.opa_i(opa_i),
		.opb_i(opb_i),
		.neg_o(neg_o),
		.pp_o(pp_o)
	);
	//---------------CONCATENATION_PARTIAL-------------------------
	always_comb begin : concat_partial
		concat_pp[0] = {{(WIDTH_MAC-WIDTH_OPA-1){pp_o[0][WIDTH_OPA]}}, pp_o[0]};
		concat_pp[1] = {{(WIDTH_MAC-WIDTH_OPA-3){pp_o[1][WIDTH_OPA]}}, pp_o[1], 2'b0};
		concat_pp[2] = {{(WIDTH_MAC-WIDTH_OPA-5){pp_o[2][WIDTH_OPA]}}, pp_o[2], 4'b0};
		concat_pp[3] = {{(WIDTH_MAC-WIDTH_OPA-7){pp_o[3][WIDTH_OPA]}}, pp_o[3], 6'b0};
	end
	wallace_partial #(
		.WIDTH_RESULT(WIDTH_MAC),
		.PARTIAL_NUM(WIDTH_OPB/2)
	) wallace (
		.pal_i(concat_pp),
		.cin_i(neg_o),
		.sum_o(sum_partial),
		.cout_o(carry_partial)
	);
	cla_adder_16bit cla (
		.a_i(sum_partial),
		.b_i({carry_partial[WIDTH_MAC-2:0], 1'b0}),
		.cin_i(1'b0),
		.cout_o(cout_o),
		.result_o(mul_o)
	);
endmodule