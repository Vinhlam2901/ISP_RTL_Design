///===========================================================================================================
// Project         : Median Switching
// Module          : Comparator for Median
// File            : compare.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 10/08/2026
// Updated date    : 10/08/2026
//============================================================================================================
module compare (
  input  logic [7:0] a_i,
  input  logic [7:0] b_i,
  input  logic [7:0] c_i,
  output logic [7:0] min_o,
  output logic [7:0] med_o,
  output logic [7:0] max_o
);
//==========================DECLARATION=======================================
  logic a_ge_b, b_ge_c, a_ge_c;
//=========================INSTANTIATION======================================
  tree_comp_8bit comp_ab (.x(a_i), .y(b_i), .ge(a_ge_b));
  tree_comp_8bit comp_bc (.x(b_i), .y(c_i), .ge(b_ge_c));
  tree_comp_8bit comp_ac (.x(a_i), .y(c_i), .ge(a_ge_c));
//====================LOGICAL_COMPARE=========================================
  always_comb begin
    min_o = (~a_ge_b && ~a_ge_c) ? a_i :                          // A < B && A < C
            ( a_ge_b && ~b_ge_c) ? b_i :                          // B <= A && B < C
            c_i;                                                  // C < A && C < B
    max_o = ( a_ge_b &&  a_ge_c) ? a_i :                          // A >= B && A >= C
            (~a_ge_b &&  b_ge_c) ? b_i :                          // B > A && B >= C
            c_i;                                                  // C > A && C > B
    med_o = (( a_ge_b && ~a_ge_c) || (~a_ge_b && a_ge_c)) ? a_i : // B < A <= C  ||  C < A <= B
            ((~a_ge_b && ~b_ge_c) || ( a_ge_b && b_ge_c)) ? b_i : // A <= B < C  ||  C <= B < A
            c_i;                                                  // B < C < A || A < C < A
  end
endmodule