//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Booth Encoder & Selector
// File            : booth_encoder.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 26/06/2026
// Updated date    : 26/06/2026
//============================================================================================================
module booth_encoder #(
	parameter WIDTH_OPA = 8,
	parameter WIDTH_OPB = 4
)(
	input	 logic [WIDTH_OPA-1:0]                    opa_i,	// unsign 
	input	 logic [WIDTH_OPB-1:0]                    opb_i,
	output logic [(WIDTH_OPB/2)-1:0]                neg_o,
	output logic [(WIDTH_OPB/2)-1:0][WIDTH_OPA+1:0] pp_o   
);
//====================================DECLARATION==============================================================
	logic [(WIDTH_OPB/2)-1:0] single_o;
	logic [(WIDTH_OPB/2)-1:0] double_o;
	logic [WIDTH_OPB:0]       sel_lines;
	logic [WIDTH_OPA+1:0]     single_ext;
	logic [WIDTH_OPA+1:0]     double_ext;
//====================================CODE=====================================================================
	assign sel_lines = {opb_i, 1'b0};
	always_comb begin : booth_encoder
		for (int i = 0; i < WIDTH_OPB; i += 2) begin
			single_o[i/2] =   sel_lines[i]  ^ sel_lines[i+1];
			double_o[i/2] = ( sel_lines[i]  & sel_lines[i+1] & ~sel_lines[i+2]) | (~sel_lines[i] & ~sel_lines[i+1] & sel_lines[i+2]);
			neg_o[i/2]    = ({sel_lines[i+2], sel_lines[i+1],   sel_lines[i]} == 3'b111) ? 1'b0 : sel_lines[i+2];
		end
	end
	assign single_ext = {1'b0, opa_i}; 
  assign double_ext = {opa_i, 1'b0};
	always_comb begin : booth_selector
		for (int i = 0; i < WIDTH_OPB/2; i += 1 ) begin
			pp_o[i] = ((single_ext & {(WIDTH_OPA+2){single_o[i]}}) | (double_ext & {(WIDTH_OPA+2){double_o[i]}})) ^ {(WIDTH_OPA+2){neg_o[i]}};
		end
	end
endmodule