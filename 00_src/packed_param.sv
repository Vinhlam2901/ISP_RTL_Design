package package_param;
  typedef struct packed {
    logic [8:0][15:0] op_mul;
  } mul_add_stage;

  typedef struct packed {
    logic [3:0][15:0] add_out;
    logic [15:0]      op_mul8_delay;
  } add_add_stage;

  typedef struct packed {
    logic [1:0][15:0] add_final;
    logic [15:0]      op_mul8_delay;
  } add_accum_stage;

  
endpackage
