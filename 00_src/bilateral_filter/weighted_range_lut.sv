//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Weighted Spatial Range Coeffiency LUT
// File            : weighted_range_lut.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 09/09/2026
// Updated date    : 25/10/2026
//=============================================================================================================
import package_param::*;
module weighted_range_lut (
  input  logic [7:0] delta_i,
  output logic [7:0] awr_o
);
  always_comb begin
    awr_o = 8'd0;
    // LUT cho Sigma = 15
    if (SIGMA_R == 5) begin
      if      (delta_i < 8'd2)  awr_o = 8'd64;
      else if (delta_i < 8'd3)  awr_o = 8'd60;
      else if (delta_i < 8'd4)  awr_o = 8'd56;
      else if (delta_i < 8'd5)  awr_o = 8'd48;
      else if (delta_i < 8'd6)  awr_o = 8'd40;
      else if (delta_i < 8'd7)  awr_o = 8'd32;
      else if (delta_i < 8'd8)  awr_o = 8'd24;
      else if (delta_i < 8'd9)  awr_o = 8'd16; // Nhảy vọt qua mức 20 do dốc đứng
      else if (delta_i < 8'd10) awr_o = 8'd12;
      else if (delta_i < 8'd11) awr_o = 8'd8;
      else if (delta_i < 8'd13) awr_o = 8'd4;
      else if (delta_i < 8'd14) awr_o = 8'd2;
      else if (delta_i < 8'd16) awr_o = 8'd1;
      else                      awr_o = 8'd0;
    end 
    
    // LUT cho Sigma = 10
    if (SIGMA_R == 10) begin
      if      (delta_i < 8'd3)  awr_o = 8'd64;
      else if (delta_i < 8'd5)  awr_o = 8'd60;
      else if (delta_i < 8'd7)  awr_o = 8'd56;
      else if (delta_i < 8'd9)  awr_o = 8'd48;
      else if (delta_i < 8'd11) awr_o = 8'd40;
      else if (delta_i < 8'd13) awr_o = 8'd32;
      else if (delta_i < 8'd15) awr_o = 8'd24;
      else if (delta_i < 8'd16) awr_o = 8'd20;
      else if (delta_i < 8'd18) awr_o = 8'd16;
      else if (delta_i < 8'd20) awr_o = 8'd12;
      else if (delta_i < 8'd22) awr_o = 8'd8;
      else if (delta_i < 8'd25) awr_o = 8'd4;
      else if (delta_i < 8'd28) awr_o = 8'd2;
      else if (delta_i < 8'd32) awr_o = 8'd1;
      else                      awr_o = 8'd0;
    end 
    if (SIGMA_R == 15) begin
      if      (delta_i < 8'd4)  awr_o = 8'd64;
      else if (delta_i < 8'd7)  awr_o = 8'd60;
      else if (delta_i < 8'd10) awr_o = 8'd56;
      else if (delta_i < 8'd13) awr_o = 8'd48;
      else if (delta_i < 8'd17) awr_o = 8'd40;
      else if (delta_i < 8'd20) awr_o = 8'd32;
      else if (delta_i < 8'd22) awr_o = 8'd24;
      else if (delta_i < 8'd24) awr_o = 8'd20;
      else if (delta_i < 8'd27) awr_o = 8'd16;
      else if (delta_i < 8'd29) awr_o = 8'd12;
      else if (delta_i < 8'd33) awr_o = 8'd8;
      else if (delta_i < 8'd38) awr_o = 8'd4; 
      else if (delta_i < 8'd40) awr_o = 8'd2;
      else if (delta_i < 8'd44) awr_o = 8'd1;
      else                      awr_o = 8'd0;
    end 
    // LUT cho Sigma = 20
    if (SIGMA_R == 20) begin
      if      (delta_i < 8'd6)  awr_o = 8'd64;
      else if (delta_i < 8'd9)  awr_o = 8'd60;
      else if (delta_i < 8'd13) awr_o = 8'd56;
      else if (delta_i < 8'd18) awr_o = 8'd48;
      else if (delta_i < 8'd22) awr_o = 8'd40;
      else if (delta_i < 8'd26) awr_o = 8'd32;
      else if (delta_i < 8'd30) awr_o = 8'd24;
      else if (delta_i < 8'd32) awr_o = 8'd20;
      else if (delta_i < 8'd35) awr_o = 8'd16;
      else if (delta_i < 8'd39) awr_o = 8'd12;
      else if (delta_i < 8'd44) awr_o = 8'd8;
      else if (delta_i < 8'd50) awr_o = 8'd4; 
      else if (delta_i < 8'd55) awr_o = 8'd2;
      else if (delta_i < 8'd63) awr_o = 8'd1;
      else                      awr_o = 8'd0;
    end
    if (SIGMA_R == 60 ) begin
      if      (delta_i < 8'd16)  awr_o = 8'd64;
      else if (delta_i < 8'd17)  awr_o = 8'd60;
      else if (delta_i < 8'd39)  awr_o = 8'd56;
      else if (delta_i < 8'd52)  awr_o = 8'd48;
      else if (delta_i < 8'd65)  awr_o = 8'd40;
      else if (delta_i < 8'd78)  awr_o = 8'd32;
      else if (delta_i < 8'd88)  awr_o = 8'd24;
      else if (delta_i < 8'd96)  awr_o = 8'd20;
      else if (delta_i < 8'd105) awr_o = 8'd16;
      else if (delta_i < 8'd116) awr_o = 8'd12;
      else if (delta_i < 8'd131) awr_o = 8'd8;
      else if (delta_i < 8'd149) awr_o = 8'd4;
      else if (delta_i < 8'd158) awr_o = 8'd2;
      else if (delta_i < 8'd174) awr_o = 8'd1;
      else                       awr_o = 8'd0;
    end 
    if (SIGMA_R == 90) begin
      if      (delta_i < 8'd23)  awr_o = 8'd64;
      else if (delta_i < 8'd40)  awr_o = 8'd60;
      else if (delta_i < 8'd58)  awr_o = 8'd56;
      else if (delta_i < 8'd78)  awr_o = 8'd48;
      else if (delta_i < 8'd97)  awr_o = 8'd40;
      else if (delta_i < 8'd116) awr_o = 8'd32;
      else if (delta_i < 8'd132) awr_o = 8'd24;
      else if (delta_i < 8'd144) awr_o = 8'd20;
      else if (delta_i < 8'd157) awr_o = 8'd16;
      else if (delta_i < 8'd174) awr_o = 8'd12;
      else if (delta_i < 8'd196) awr_o = 8'd8;
      else if (delta_i < 8'd223) awr_o = 8'd4;
      else if (delta_i < 8'd237) awr_o = 8'd2;
      else                       awr_o = 8'd1;
    end 
    if (SIGMA_R == 180) begin
      if      (delta_i < 8'd46)  awr_o = 8'd64;
      else if (delta_i < 8'd80)  awr_o = 8'd60;
      else if (delta_i < 8'd116) awr_o = 8'd56;
      else if (delta_i < 8'd156) awr_o = 8'd48;
      else if (delta_i < 8'd194) awr_o = 8'd40;
      else if (delta_i < 8'd232) awr_o = 8'd32;
      else                       awr_o = 8'd24;
    end 
  end
endmodule