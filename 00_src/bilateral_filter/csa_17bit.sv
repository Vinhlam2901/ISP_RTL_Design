//===========================================================================================================
// Project         : Bilateral Filter
// Module          : Carry Save Adder 17bit 
// File            : csa_17bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 14/09/2026
// Updated date    : 14/09/2026
//============================================================================================================
module csa_17bit (
  input  logic [16:0] a_i,
  input  logic [16:0] b_i,
  input  logic [16:0] c_i,
  output logic [16:0] sum_o,
  output logic [16:0] carry_o
);
  always_comb begin
    // Phép tính Full Adder song song cho 17 bit
    sum_o   = a_i ^ b_i ^ c_i;
    carry_o = (a_i & b_i) | (b_i & c_i) | (a_i & c_i);
  end
endmodule