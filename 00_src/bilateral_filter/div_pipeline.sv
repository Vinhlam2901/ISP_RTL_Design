//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Non Restoring Division 8 Stage Pipeline
// File            : div_pipeline.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 15/09/2026
// Updated date    : 15/09/2026
//=============================================================================================================
import package_param::*;
module div_pipeline #(
  parameter WIDTH_PIXEL = 8,      
  parameter WIDTH_DEN   = 13,
  parameter WIDTH_OUT   = 8,
  parameter WIDTH_REM   = 14
)(
  input  logic                 i_clk,
  input  logic                 ni_rst,
  input  logic                 i_ready,
  input  logic                 i_valid,
  input  logic [WIDTH_REM-1:0] i_rem,     
  input  logic [WIDTH_OUT-1:0] i_quoti,   
  input  logic [WIDTH_DEN-1:0] i_den,     
  output logic                 o_valid,
  output logic [WIDTH_REM-1:0] o_remain,  
  output logic [WIDTH_OUT-1:0] o_quoti    
);
//==============DECLARATION==============================================
  logic [WIDTH_REM-1:0] o_remain0, o_remain1, o_remain2, o_remain3,
                        o_remain4, o_remain5, o_remain6, o_remain7;
  logic [WIDTH_OUT-1:0] o_quoti0, o_quoti1, o_quoti2, o_quoti3,
                        o_quoti4, o_quoti5, o_quoti6, o_quoti7;
  //----------------pipeline-------------------------------------
  next_div_stage stage1_reg, stage1_next;
  logic          valid_stage1_reg;
//==============INSTANTIATION=========================================================
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div0 (.i_rem(i_rem), .i_quoti(i_quoti), .i_den(i_den), .o_remain(o_remain0), .o_quoti(o_quoti0));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div1 (.i_rem(o_remain0), .i_quoti(o_quoti0), .i_den(i_den), .o_remain(o_remain1), .o_quoti(o_quoti1));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div2 (.i_rem(o_remain1), .i_quoti(o_quoti1), .i_den(i_den), .o_remain(o_remain2), .o_quoti(o_quoti2));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div3 (.i_rem(o_remain2), .i_quoti(o_quoti2), .i_den(i_den), .o_remain(o_remain3), .o_quoti(o_quoti3));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div4 (.i_rem(o_remain3), .i_quoti(o_quoti3), .i_den(i_den), .o_remain(o_remain4), .o_quoti(o_quoti4)); 
//========================PIPELINE_STAGE_1================================================
  always_comb begin
    stage1_next.o_remain4 = o_remain4;
    stage1_next.i_den     = i_den;
    stage1_next.o_quoti4  = o_quoti4;
  end
  always_ff @(posedge i_clk) begin : stage1_register
    if(~ni_rst) begin
      stage1_reg       <= '0;
      valid_stage1_reg <= 1'b0;
    end else if (i_ready) begin
        stage1_reg <= stage1_next;
        valid_stage1_reg <= i_valid; 
    end
  end
  assign o_valid = valid_stage1_reg;
//================NEXT_4_DIV==============================================================
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div5 (.i_rem(stage1_reg.o_remain4), .i_quoti(stage1_reg.o_quoti4), .i_den(stage1_reg.i_den), .o_remain(o_remain5), .o_quoti(o_quoti5));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div6 (.i_rem(o_remain5), .i_quoti(o_quoti5), .i_den(stage1_reg.i_den), .o_remain(o_remain6), .o_quoti(o_quoti6));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL), .WIDTH_REM(WIDTH_REM)
  ) div7 (.i_rem(o_remain6), .i_quoti(o_quoti6), .i_den(stage1_reg.i_den), .o_remain(o_remain), .o_quoti(o_quoti));
endmodule