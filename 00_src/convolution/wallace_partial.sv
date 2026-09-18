//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Wallace Tree for Reducing Partial Product
// File            : wallace_partial.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 01/07/2026
// Updated date    : 01/07/2026
//============================================================================================================
module wallace_partial #(
	parameter int WIDTH_RESULT = 12,
	parameter int PARTIAL_NUM = 4
)(
	input  logic [PARTIAL_NUM-1:0][WIDTH_RESULT-1:0] pal_i,
	input  logic [PARTIAL_NUM-1:0]                   cin_i,
	output logic [WIDTH_RESULT-1:0]                  sum_o,
	output logic [WIDTH_RESULT-1:0]                  cout_o                                 
);
//==================DECLARATION==============================================
	logic [WIDTH_RESULT-1:4] cout_net;
	logic [WIDTH_RESULT-1:6] pre_sum;
	logic [WIDTH_RESULT-1:6] extra_c;
//==================EXECUTE==============================================
	always_comb begin : sum_result
		//-------------- HALF_ADDER -------------------
		sum_o[0]  = pal_i[0][0] ^ cin_i[0];
		cout_o[0] = pal_i[0][0] & cin_i[0];
		//---------------STRAIGHT FORWARD---------------
		sum_o[1]  = pal_i[0][1];
		cout_o[1] = 1'b0;
		//-------------- FULL_ADDER -------------------
		sum_o[2]  = pal_i[0][2] ^ pal_i[1][2] ^ cin_i[1];
		cout_o[2] = (pal_i[0][2] & pal_i[1][2]) | (pal_i[0][2] & cin_i[1]) | (pal_i[1][2] & cin_i[1]);
		//-------------- HALF_ADDER -------------------
		sum_o[3]  = pal_i[0][3] ^ pal_i[1][3];
		cout_o[3] = pal_i[0][3] & pal_i[1][3];
	end
	//-------------- COMPRESSOR CHAIN -----------------
	compressed_adder_4to2 com4 (
		.x1_i   (pal_i[0][4]),
		.x2_i   (pal_i[1][4]),
		.x3_i   (pal_i[2][4]),
		.x4_i   (cin_i[2]),
		.cin_i  (1'b0),
		.sum_o  (sum_o[4]),
		.carry_o(cout_o[4]),
		.cout_o (cout_net[4])
	);
	compressed_adder_4to2 com5 (
		.x1_i   (pal_i[0][5]),
		.x2_i   (pal_i[1][5]),
		.x3_i   (pal_i[2][5]),
		.x4_i   (1'b0),
		.cin_i  (cout_net[4]),
		.sum_o  (sum_o[5]),
		.carry_o(cout_o[5]),
		.cout_o (cout_net[5])
	);
	genvar i;
	generate
		for (i = 6; i < WIDTH_RESULT; i++) begin : comp_loop
			compressed_adder_4to2 com (
				.x1_i   (pal_i[0][i]),
				.x2_i   (pal_i[1][i]),
				.x3_i   (pal_i[2][i]),
				.x4_i   (pal_i[3][i]),
				.cin_i  (cout_net[i-1]),
				.sum_o  (pre_sum[i]),
				.carry_o(cout_o[i]),
				.cout_o (cout_net[i])
			);
			if (i == 6) begin
				// col 6 has pal[0][0], pal[0][1], pal[0][2]. pal[0][3], cout from col5 anh cin[3]
				assign sum_o[i]   = pre_sum[i] ^ cin_i[3];
				assign extra_c[i] = pre_sum[i] & cin_i[3];
			end else begin
				// must be ripple
				assign sum_o[i]   = pre_sum[i] ^ extra_c[i-1];
				assign extra_c[i] = pre_sum[i] & extra_c[i-1];
			end
		end
	endgenerate

endmodule