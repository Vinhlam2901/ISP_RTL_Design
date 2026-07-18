package package_param;
  typedef struct packed {
    logic [8:0][14:0] op_mul;
  } mul_add_stage;

  typedef struct packed {
    logic [3:0][14:0] add_out;
    logic [14:0]      op_mul8_delay;
  } add_add_stage;

  typedef struct packed {
    logic [14:0]      final_mac;
  } add_accum_stage;
endpackage
