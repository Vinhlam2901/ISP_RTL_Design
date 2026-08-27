module tree_comp_8bit (
  input  logic [7:0] x_i,
  input  logic [7:0] y_i,
  output logic ge_o
);
//===========DECLARATION================================================
  logic [7:0] g1, e1;
  logic [3:0] g2, e2;
  logic [1:0] g3, e3;
  logic       g4, e4;
//===========LOGIC_STAGE1================================================
  assign g1    = x_i & ~y_i;        // check if y_i < x_i or not
  assign e1    = ~(x_i ^ y_i);      // Cờ Equal (x_i == y_i)
//===========LOGIC_STAGE2================================================
  assign g2[3] = g1[7] | (e1[7] & g1[6]); assign e2[3] = e1[7] & e1[6];
  assign g2[2] = g1[5] | (e1[5] & g1[4]); assign e2[2] = e1[5] & e1[4];
  assign g2[1] = g1[3] | (e1[3] & g1[2]); assign e2[1] = e1[3] & e1[2];
  assign g2[0] = g1[1] | (e1[1] & g1[0]); assign e2[0] = e1[1] & e1[0];
//===========LOGIC_STAGE3===============================================
  assign g3[1] = g2[3] | (e2[3] & g2[2]); assign e3[1] = e2[3] & e2[2];
  assign g3[0] = g2[1] | (e2[1] & g2[0]); assign e3[0] = e2[1] & e2[0];
//===========LOGIC_STAGE4===============================================
  assign g4    = g3[1] | (e3[1] & g3[0]);
  assign e4    = e3[1] & e3[0];
  assign ge_o    = g4 | e4;

endmodule