module cla_adder_22bit (
  input  logic [21:0] a_i,
  input  logic [21:0] b_i,
  input  logic        cin_i,
  output logic        cout_o,
  output logic [21:0] result_o 
);
  logic cout_21;
  logic p_21, g_21;
  
  cla_adder_21bit cla_21bit_core (
    .a_i      (a_i[20:0]),
    .b_i      (b_i[20:0]),
    .cin_i    (cin_i),
    .cout_o   (cout_21), 
    .result_o (result_o[20:0])
  );
  always_comb begin
    p_21 = a_i[21] ^ b_i[21];
    g_21 = a_i[21] & b_i[21];
    result_o[21] = p_21 ^ cout_21; 
    cout_o = g_21 | (p_21 & cout_21);
  end
endmodule