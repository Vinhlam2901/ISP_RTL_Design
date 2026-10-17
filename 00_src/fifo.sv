//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : First In First Out Register
// File            : fifo.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 07/07/2026
// Updated date    : 07/07/2026
//=============================================================================================================
// import package_param::*;
module fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4  // 2^4 = 16 phần tử (Depth)
)(
  input  logic                  i_clk,
  input  logic                  ni_rst,
  input  logic                  i_wren,
  input  logic                  i_rden,
  input  logic [DATA_WIDTH-1:0] wr_data,
  output logic                  o_empty,
  output logic                  o_full,
  output logic [DATA_WIDTH-1:0] rd_data
);
//===============DECLARATION===========================================================================
  logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
  logic [ADDR_WIDTH:0]   wr_ptr, rd_ptr, ptr_wraddr, ptr_rdaddr;             // 1 extend bit to check the phase of ptr
  logic                  wr_en, rd_en;
//===============EXECUTION===========================================================================
  // logic combination for checking i_wren
  always_comb begin
    o_full        = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                    (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    o_empty       = (rd_ptr == wr_ptr);
    wr_en         = i_wren && ~o_full;
    rd_en         = i_rden && ~o_empty;
    ptr_wraddr    = (wr_en) ? (wr_ptr + 1) : wr_ptr;
    ptr_rdaddr    = (rd_en) ? (rd_ptr + 1) : rd_ptr;
  end
//===============POINTER_UPDATED===========================================================================
  always_ff @( posedge i_clk) begin: write_data
    if(~ni_rst) begin
        wr_ptr <= '0;
        rd_ptr <= '0;
    end else begin
        wr_ptr <= ptr_wraddr;
        rd_ptr <= ptr_rdaddr;
    end
  end
//===============READ_WRITE_SYNC===========================================================================
  always_ff @(posedge i_clk) begin
    if (wr_en) begin
      mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data; 
    end
    if (rd_en) begin
      rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
    end
  end
endmodule