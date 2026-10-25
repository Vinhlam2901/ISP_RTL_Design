import package_param::*;
module cla_nbit #(
  parameter WIDTH_CLA = 5
)(
  input  logic [WIDTH_CLA-1:0] a,
  input  logic [WIDTH_CLA-1:0] b,
  input  logic             cin,
  output logic [WIDTH_CLA-1:0] sum,
  output logic             cout
);
  logic [WIDTH_CLA-1:0] p, g;
  logic [WIDTH_CLA:0]   c;
  assign c[0] = cin;
  genvar i;
  generate
    for (i = 0; i < WIDTH_CLA; i++) begin : gen_cla_chain
      // Tạo tín hiệu Propagate và Generate cho từng bit
      assign p[i] = a[i] ^ b[i];
      assign g[i] = a[i] & b[i];
      // Logic Lookahead
      assign c[i+1] = g[i] | (p[i] & c[i]);
      // Tổng
      assign sum[i] = p[i] ^ c[i];
    end
  endgenerate
  assign cout = c[WIDTH_CLA];
endmodule