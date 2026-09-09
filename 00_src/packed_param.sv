package package_param;
  parameter WIDTH_PIXEL = 8;
//------------------MAC_STRUCT--------------------------
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
//-----------------MEDIAN_SWITCHING_STRUCT---------------
  typedef struct packed {
    logic [WIDTH_PIXEL-1:0] vert_abs;
    logic [WIDTH_PIXEL-1:0] hor_abs;
    logic [WIDTH_PIXEL-1:0] crossl_abs;
    logic [WIDTH_PIXEL-1:0] crossr_abs;
    logic [WIDTH_PIXEL-1:0] center_px;
  } stage1_dev_stage;
  typedef struct packed {
    logic [WIDTH_PIXEL-1:0] min_all;
    logic [WIDTH_PIXEL-1:0] center_px;
  } stage2_min_stage;
  typedef struct packed {
    logic                   noise_flag;
    logic [WIDTH_PIXEL-1:0] center_px;
  } stage3_dec_stage;
//--------------MEDIAN_FINDING_STRUCT-------------------
  typedef struct packed {
    logic [8:0][WIDTH_PIXEL-1:0] px;
  } stage1_cal_stage;
  typedef struct packed {
    logic [WIDTH_PIXEL-1:0] max_of_mins;
    logic [WIDTH_PIXEL-1:0] med_of_meds;
    logic [WIDTH_PIXEL-1:0] min_of_maxs;
  } stage2_cal_stage;
endpackage
