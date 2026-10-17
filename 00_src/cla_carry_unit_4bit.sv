//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : CLA Carry Processing Unit
// File            : cla_carry_unit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 19/06/2026
// Updated date    : 20/06/2026
//============================================================================================================
module cla_carry_unit_4bit (
  input  logic [3:0] p_i,
  input  logic [3:0] g_ni,
  input  logic       cin_i,
  output logic [3:0] cin_out,
  output logic       p_o,
  output logic       g_no
);
//==================DECLARATION=======================================================================
  logic [3:0] cin_temp;
//==================CARRY=============================================================================
  // c[i] = ~(g_n[i] & ~(p[i]cin) -> Tương đương chuẩn xác với G + P*Cin
  always_comb begin : carry_calc
    cin_temp[0] = ~(g_ni[0] & ~(p_i[0] & cin_i));
    
    cin_temp[1] = ~(g_ni[1] & ~(p_i[1]          & ~g_ni[0]) 
                            & ~(p_i[1] & p_i[0] & cin_i   ));
                            
    cin_temp[2] = ~(g_ni[2] & ~(p_i[2]                   & ~g_ni[1]) 
                            & ~(p_i[2] & p_i[1]          & ~g_ni[0]) 
                            & ~(p_i[2] & p_i[1] & p_i[0] & cin_i   ));
                            
    cin_temp[3] = ~(g_ni[3] & ~(p_i[3]                            & ~g_ni[2]) 
                            & ~(p_i[3] & p_i[2]                   & ~g_ni[1]) 
                            & ~(p_i[3] & p_i[2] & p_i[1]          & ~g_ni[0]) 
                            & ~(p_i[3] & p_i[2] & p_i[1] & p_i[0] & cin_i   ));                
  end
//================== DYNAMIC BOUNDARY GATING ========================================================
  always_comb begin : boundary_gating
    cin_out = cin_temp;
  end
  always_comb begin : prog_gen_out
    p_o  = &p_i;
    g_no = ~g_ni[3] & ~(p_i[3]                   & ~g_ni[2]) 
                    & ~(p_i[3] & p_i[2]          & ~g_ni[1]) 
                    & ~(p_i[3] & p_i[2] & p_i[1] & ~g_ni[0]);
  end
endmodule