//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : CLA Carry Processing Unit
// File            : cla_carry_unit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 19/06/2026
// Updated date    : 20/06/2026
//============================================================================================================
module cla_carry_unit_5bit (
	input  wire [4:0] p_i,
	input  wire [4:0] g_ni,
	input  wire       cin_i,
	output reg  [4:0] cin_out,
	output reg        p_o,
	output reg        g_no
);
//==================DECLARATION=======================================================================
	reg [4:0] cin_temp;
//==================CARRY=============================================================================
	// c[i] = ~(g_n[i] & ~(p[i]cin)
	always_comb begin : carry_calc
		//--------------------cin[0]---------------------------------------------------------
		cin_temp[0] = ~(g_ni[0] & ~(p_i[0] & cin_i) );
		//--------------------cin[1]---------------------------------------------------------
		cin_temp[1] = ~(g_ni[1] & ~(p_i[1]          & ~g_ni[0]) 
													  & ~(p_i[1] & p_i[0] & cin_i)  );
		//--------------------cin[2]---------------------------------------------------------
		cin_temp[2] = ~(g_ni[2] & ~(p_i[2]                   & ~g_ni[1]) 
													  & ~(p_i[2] & p_i[1]          & ~g_ni[0]) 
													  & ~(p_i[2] & p_i[1] & p_i[0] & cin_i   ));
		//--------------------cin[3]---------------------------------------------------------
		cin_temp[3] = ~(g_ni[3] & ~(p_i[3]                            & ~g_ni[2]) 
													  & ~(p_i[3] & p_i[2]                   & ~g_ni[1]) 
													  & ~(p_i[3] & p_i[2] & p_i[1]          & ~g_ni[0]) 
													  & ~(p_i[3] & p_i[2] & p_i[1] & p_i[0] & cin_i   ));
		//--------------------cin[4]---------------------------------------------------------
		cin_temp[4] = ~(g_ni[4] & ~(p_i[4]                                     & ~g_ni[3]) 
													  & ~(p_i[4] & p_i[3] 									         & ~g_ni[2])
													  & ~(p_i[4] & p_i[3] & p_i[2]                   & ~g_ni[1]) 
													  & ~(p_i[4] & p_i[3] & p_i[2] & p_i[1]          & ~g_ni[0]) 
													  & ~(p_i[4] & p_i[3] & p_i[2] & p_i[1] & p_i[0] & cin_i   ));											 											 
	end
//================== DYNAMIC BOUNDARY GATING FOR RVV ====================================
  always_comb begin : boundary_gating
    cin_out = cin_temp;
  end
	// p_o = p[n-1].p[n-2].p_n[n]
	always_comb begin : prog_gen_out
		p_o  = &p_i;
		g_no = g_ni[4] & ~(p_i[4]                            & ~g_ni[4]) 
									 & ~(p_i[4] & p_i[3]                   & ~g_ni[3]) 
									 & ~(p_i[4] & p_i[3] & p_i[2]          & ~g_ni[1]) 
									 & ~(p_i[4] & p_i[3] & p_i[2] & p_i[1] & ~g_ni[0]);
	end
	
endmodule