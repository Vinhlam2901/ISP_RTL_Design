//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Weighted Spatial Range Coeffiency LUT
// File            : weighted_range_lut.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 09/09/2026
//=============================================================================================================
module weighted_range_lut #(
  parameter SIGMA_R = 15
)(
  input  logic [7:0] delta_i,
  output logic [6:0] awr_o
);
  always_comb begin
    awr_o = 7'd0;
    // LUT cho Sigma = 15
    if (SIGMA_R == 15) begin
      if      (delta_i < 8'd4)  awr_o = 7'd64;
      else if (delta_i < 8'd7)  awr_o = 7'd60;
      else if (delta_i < 8'd10) awr_o = 7'd56;
      else if (delta_i < 8'd13) awr_o = 7'd48;
      else if (delta_i < 8'd17) awr_o = 7'd40;
      else if (delta_i < 8'd20) awr_o = 7'd32;
      else if (delta_i < 8'd22) awr_o = 7'd24;
      else if (delta_i < 8'd24) awr_o = 7'd20;
      else if (delta_i < 8'd27) awr_o = 7'd16;
      else if (delta_i < 8'd29) awr_o = 7'd12;
      else if (delta_i < 8'd33) awr_o = 7'd8;
      else if (delta_i < 8'd38) awr_o = 7'd4; 
      else if (delta_i < 8'd40) awr_o = 7'd2;
      else if (delta_i < 8'd44) awr_o = 7'd1;
      else                      awr_o = 7'd0;
    end 
    if (SIGMA_R == 60 ) begin
      if      (delta_i < 8'd16)  awr_o = 7'd64;
      else if (delta_i < 8'd17)  awr_o = 7'd60;
      else if (delta_i < 8'd39)  awr_o = 7'd56;
      else if (delta_i < 8'd52)  awr_o = 7'd48;
      else if (delta_i < 8'd65)  awr_o = 7'd40;
      else if (delta_i < 8'd78)  awr_o = 7'd32;
      else if (delta_i < 8'd88)  awr_o = 7'd24;
      else if (delta_i < 8'd96)  awr_o = 7'd20;
      else if (delta_i < 8'd105) awr_o = 7'd16;
      else if (delta_i < 8'd116) awr_o = 7'd12;
      else if (delta_i < 8'd131) awr_o = 7'd8;
      else if (delta_i < 8'd149) awr_o = 7'd4;
      else if (delta_i < 8'd158) awr_o = 7'd2;
      else if (delta_i < 8'd174) awr_o = 7'd1;
      else                       awr_o = 7'd0;
    end 
    if (SIGMA_R == 90) begin
      if      (delta_i < 8'd23)  awr_o = 7'd64;
      else if (delta_i < 8'd40)  awr_o = 7'd60;
      else if (delta_i < 8'd58)  awr_o = 7'd56;
      else if (delta_i < 8'd78)  awr_o = 7'd48;
      else if (delta_i < 8'd97)  awr_o = 7'd40;
      else if (delta_i < 8'd116) awr_o = 7'd32;
      else if (delta_i < 8'd132) awr_o = 7'd24;
      else if (delta_i < 8'd144) awr_o = 7'd20;
      else if (delta_i < 8'd157) awr_o = 7'd16;
      else if (delta_i < 8'd174) awr_o = 7'd12;
      else if (delta_i < 8'd196) awr_o = 7'd8;
      else if (delta_i < 8'd223) awr_o = 7'd4;
      else if (delta_i < 8'd237) awr_o = 7'd2;
      else                       awr_o = 7'd1;
    end 
    if (SIGMA_R == 180) begin
      if      (delta_i < 8'd46)  awr_o = 7'd64;
      else if (delta_i < 8'd80)  awr_o = 7'd60;
      else if (delta_i < 8'd116) awr_o = 7'd56;
      else if (delta_i < 8'd156) awr_o = 7'd48;
      else if (delta_i < 8'd194) awr_o = 7'd40;
      else if (delta_i < 8'd232) awr_o = 7'd32;
      else                       awr_o = 7'd24;
    end 
  end
endmodule