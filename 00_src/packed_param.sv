package package_param;
  parameter WIDTH_PIXEL = 8;
  typedef logic [WIDTH_PIXEL-1:0] pixel_data;
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
//------------------MAC_BILATERAL_STRUCT--------------------------
  typedef struct packed {
    logic [8:0][20:0] op_mul;
    logic      [12:0] den_wc8_delay;
    logic [3:0][12:0] den_accum_lv1;
  } mul_add_bilateral;

  typedef struct packed {
    logic [3:0][20:0] add_out;
    logic      [20:0] op_mul8_delay;
    logic      [12:0] den_wc8_delay;
    logic [1:0][12:0] den_accum_lv2;
  } add_add_bilateral;

  typedef struct packed {
    logic [1:0][20:0] add_final;
    logic      [12:0] den_wc8_delay;
    logic      [12:0] den_accum_lv3;
    logic      [20:0] op_mul8_delay;
  } add_accum_bilateral;
//======================MEDIAN_SWITCHING_STRUCT======================
  typedef struct packed {
    pixel_data vert_abs;
    pixel_data hor_abs;
    pixel_data crossl_abs;
    pixel_data crossr_abs;
    pixel_data center_px;
  } stage1_dev_stage;
  typedef struct packed {
    pixel_data min_all;
    pixel_data center_px;
  } stage2_min_stage;
  typedef struct packed {
    logic                   noise_flag;
    pixel_data center_px;
  } stage3_dec_stage;
//==================MEDIAN_FINDING_STRUCT==================
  typedef struct packed {
    logic [8:0][WIDTH_PIXEL-1:0] px;
  } stage1_cal_stage;
  typedef struct packed {
    pixel_data max_of_mins;
    pixel_data med_of_meds;
    pixel_data min_of_maxs;
  } stage2_cal_stage;
//==================BILATERAL_STRUCT==================
  typedef struct packed {
    logic [8:0][WIDTH_PIXEL-1:0] diff;
    logic [8:0][WIDTH_PIXEL-1:0] pre_px;
  } stage1_lut;
  typedef struct packed {
    logic [20:0] mac_num;
    logic [12:0] mac_den;
  } stage2_mac;
endpackage
