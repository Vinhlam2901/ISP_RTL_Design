//===========================================================================================================
// Project         : UART & RVV
// Module          : Shift Left Logic 8bit for VALU
// File            : sll_8bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 04/09/2025
// Updated date    : 04/09/2026
//============================================================================================================
module sll_8bit (
  input  wire [7:0] a_i,
  input  wire [7:0] b_i,
  output wire [8:0] sl_o
);
//chi dich 3 bit thap nhat cua b_i
//dich trai zero extend
  wire [7:0] s0, s1;
  wire [8:0] a_ext;
  assign a_ext = {1'b0, a_i};
  assign s0   = b_i[0] ? {a_ext[6:0], 1'b0} : a_ext; //dich phai 1 bit hoac 0 dich
  assign s1   = b_i[1] ? {   s0[5:0], 2'b0} : s0;    //dich phai 2 bit hoac 0 dich
  assign sl_o = b_i[2] ? {   s1[2:0], 4'b0} : s1;    //dich phai 4 bit hoac 0 dich
endmodule
