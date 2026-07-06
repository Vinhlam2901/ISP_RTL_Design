//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Multiplier Acumulator
// File            : mac.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 04/07/2026
// Updated date    : 06/07/2026
//=============================================================================================================
module mac #(
	parameter WIDTH_MAC = 20,
	parameter WIDTH_OPA = 12,
	parameter WIDTH_OPB = 8,
	parameter GUARD_BIT = 4  						
	/* imagine we have 3x3 window for mac, so we need 9 times to acc 
	-> the guard bit of acc_reg is log2(9) = 4 bit */
)(
  input  wire                             i_clk,
  input  wire                             ni_rst,
  input  wire                             mac_en_i,
  input  wire                             acc_clr_i,
  input  wire [WIDTH_OPA-1:0]             opa_i,
	input  wire [WIDTH_OPB-1:0]             opb_i,
  output reg                              mac_ready_o,
  output reg                              mac_valid_o,
	output reg  [(WIDTH_MAC+GUARD_BIT)-1:0] mac_out
);
//========================DECLEARATION===============================================================================
  typedef enum {IDLE, ACC, STOP} state_type;
  state_type state, next_state;
	reg                             cout_acc;
	reg [WIDTH_MAC-1:0]             mul_result;
	reg [(WIDTH_MAC+GUARD_BIT)-1:0] op_mul;
	reg [(WIDTH_MAC+GUARD_BIT)-1:0] op_acc;
	reg [(WIDTH_MAC+GUARD_BIT)-1:0] acc_out;
//========================INSTANTIAION===============================================================================
	mul multiplier (
		.opa_i(opa_i),
		.opb_i(opb_i),
		.mul_o(mul_result)
	);
	assign op_mul = {{4{mul_result[19]}}, mul_result};
	assign op_acc = acc_clr_i ? 24'd0 : mac_out;
	cla_adder_24bit adder (
		.a_i     (op_mul),
		.b_i     (op_acc),
		.cin_i   (1'b0),
		.cout_o  (cout_acc),
		.result_o(acc_out)
	);
//===========================================================================
// KHỐI 1: STATE REGISTER (Sequential)
//===========================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst)
      state <= IDLE;
    else
      state <= next_state;
  end
//===========================================================================
// KHỐI 2: NEXT STATE LOGIC (Combinational)
//===========================================================================
  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
				if (mac_en_i) begin
					next_state = ACC;
				end
      end
      ACC: begin
				next_state = STOP;
      end 
      STOP: begin
				next_state = IDLE;
      end
      default: next_state = IDLE;
    endcase
  end
//===========================================================================
// KHỐI 3: DATAPATH LOGIC (Sequential)
//===========================================================================
always_ff @(posedge i_clk or negedge ni_rst) begin
	if (~ni_rst) begin
		mac_out     <= '0;
		mac_ready_o <= 1'b0;
		mac_valid_o <= 1'b0;
	end else begin
		case (state)
			IDLE: begin
				mac_ready_o <= 1'b1;
				mac_valid_o <= 1'b0;
				if (mac_en_i) begin
					mac_ready_o <= 1'b0;
				end
			end
			ACC: begin
				mac_out     <= acc_out; 
				mac_ready_o <= 1'b0;
				mac_valid_o <= 1'b1;
			end
			STOP: begin
				mac_ready_o <= 1'b0;
				mac_valid_o <= 1'b0;
			end
			default: begin
				mac_ready_o <= 1'b0;
				mac_valid_o <= 1'b0;
			end
		endcase
	end
end
endmodule