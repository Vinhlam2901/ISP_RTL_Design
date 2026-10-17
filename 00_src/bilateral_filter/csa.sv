//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Carry Save Adder 17bit 
// File            : csa_17bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 14/09/2026
//============================================================================================================
module csa #(
  parameter WIDTH = 23
)(
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  output logic [WIDTH-1:0] sum_o,
  output logic [WIDTH-1:0] carry_o
);
  always_comb begin
    sum_o   = a_i ^ b_i ^ c_i;
    carry_o = (a_i & b_i) | (b_i & c_i) | (a_i & c_i);
  end
endmodule