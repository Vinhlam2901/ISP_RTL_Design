//=============================================================================================================
// Project         : Bilateral Filter
// Module          : Non Restoring Division 8 Stage Pipeline
// File            : div_pipeline.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 15/09/2026
// Updated date    : 15/09/2026
//=============================================================================================================
module div_pipeline #(
  parameter WIDTH_PIXEL = 8,      
  parameter WIDTH_DEN   = 13,
  parameter WIDTH_OUT   = 8,
  localparam WIDTH_REM  = WIDTH_DEN + 1 
)(
  input  logic                 i_clk,
  input  logic                 ni_rst,
  input  logic                 ready_i,
  input  logic [WIDTH_REM-1:0] rem_i,     
  input  logic [WIDTH_OUT-1:0] quoti_i,   
  input  logic [WIDTH_DEN-1:0] den_i,     
  output logic                 valid_o,
  output logic [WIDTH_REM-1:0] remain_o,  
  output logic [WIDTH_OUT-1:0] quoti_o    
);
//==============DECLARATION==============================================
  logic [WIDTH_REM-1:0] remain_o0, remain_o1, remain_o2, remain_o3,
                        remain_o4, remain_o5, remain_o6, remain_o7;
  logic [WIDTH_OUT-1:0] quoti_o0, quoti_o1, quoti_o2, quoti_o3,
                        quoti_o4, quoti_o5, quoti_o6, quoti_o7;
  //----------------pipeline--------------------------------
  next_div_stage stage1_reg, stage1_next;
  logic          valid_stage1_reg;
//==============INSTANTIATION============================================
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div0 (.rem_i(rem_i), .quoti_i(quoti_i), .den_i(den_i), .remain_o(remain_o0), .quoti_o(quoti_o0));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div1 (.rem_i(remain_o0), .quoti_i(quoti_o0), .den_i(den_i), .remain_o(remain_o1), .quoti_o(quoti_o1));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div2 (.rem_i(remain_o1), .quoti_i(quoti_o1), .den_i(den_i), .remain_o(remain_o2), .quoti_o(quoti_o2));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div3 (.rem_i(remain_o2), .quoti_i(quoti_o2), .den_i(den_i), .remain_o(remain_o3), .quoti_o(quoti_o3));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div4 (.rem_i(remain_o3), .quoti_i(quoti_o3), .den_i(den_i), .remain_o(remain_o4), .quoti_o(quoti_o4)); 
//========================PIPELINE_STAGE_1================================================
  always_comb begin
    stage1_next.remain_o4 = remain_o4;
    stage1_next.den_i     = den_i;
    stage1_next.quoti_o4  = quoti_o4;
  end
  always_ff @(posedge i_clk) begin : stage1_register
    if(~ni_rst) begin
      stage1_reg       <= '0;
      valid_stage1_reg <= 1'b0;
    end else begin
      if (ready_i) begin
        stage1_reg <= stage1_next;
      end
      valid_stage1_reg <= ready_i; 
    end
  end
  assign valid_o = valid_stage1_reg;
//================NEXT_4_DIV==============================================================
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div5 (.rem_i(stage1_reg.remain_o4), .quoti_i(stage1_reg.quoti_o4), .den_i(stage1_reg.den_i), .remain_o(remain_o5), .quoti_o(quoti_o5));

  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div6 (.rem_i(remain_o5), .quoti_i(quoti_o5), .den_i(stage1_reg.den_i), .remain_o(remain_o6), .quoti_o(quoti_o6));
  non_res_div #(
    .WIDTH_DEN(13), .WIDTH_OUT(WIDTH_PIXEL)
  ) div7 (.rem_i(remain_o6), .quoti_i(quoti_o6), .den_i(stage1_reg.den_i), .remain_o(remain_o), .quoti_o(quoti_o));
endmodule