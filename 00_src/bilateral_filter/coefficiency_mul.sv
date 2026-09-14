//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Weighted Spatial & Weighted Intensity Range Coefficiecy Multiplication
// File            : coefficiency_mul.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 14/09/2026
//=============================================================================================================
module coefficiency_mul (
  input  logic [6:0] awr_00, awr_01, awr_02, 
  input  logic [6:0] awr_10, awr_11, awr_12,
  input  logic [6:0] awr_20, awr_21, awr_22,
  output logic [8:0] wmul_00, wmul_01, wmul_02,
  output logic [8:0] wmul_10, wmul_11, wmul_12,
  output logic [8:0] wmul_20, wmul_21, wmul_22
);
  always_comb begin
    wmul_00 = {{2{1'b0}}, awr_00};  wmul_01 = {1'b0, awr_01, 1'b0}; wmul_02 = {{2{1'b0}}, awr_02};
    wmul_10 = {1'b0, awr_10, 1'b0}; wmul_11 = {awr_11, {2{1'b0}}};  wmul_12 = {1'b0, awr_12, 1'b0};
    wmul_20 = {{2{1'b0}}, awr_20};  wmul_21 = {1'b0, awr_21, 1'b0}; wmul_22 = {{2{1'b0}}, awr_22};
  end
endmodule