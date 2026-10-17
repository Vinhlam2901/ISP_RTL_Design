package package_param;
  parameter WIDTH_PIXEL = 8;
  typedef logic [WIDTH_PIXEL-1:0] PIXEL_DATA;
//------------------MAC_STRUCT--------------------------
  typedef struct packed {
    logic [8:0][15:0] op_mul;
  } MUL_ADD_STAGE;

  typedef struct packed {
    logic [3:0][15:0] add_out;
    logic [15:0]      op_mul8_delay;
  } ADD_ADD_STAGE;

  typedef struct packed {
    logic [1:0][15:0] add_final;
    logic [15:0]      op_mul8_delay;
  } ADD_ACCUM_STAGE;
//------------------MAC_BILATERAL_STRUCT--------------------------
  // Stage 1 -> 2: Chứa 12 vector (6 sum, 6 carry) cho tử số và các tổng mẫu số tạm
  typedef struct packed {
    logic [5:0][21:0] sum1;
    logic [5:0][21:0] carry1;
    logic [3:0][12:0] den1;
    logic      [12:0] den_pass1;
  } MAC_STAGE1_REG;
  // Stage 2 -> 3: Chứa 8 vector (4 sum, 4 carry) cho tử số và các tổng mẫu số tiếp theo
  typedef struct packed {
    logic [2:0][21:0] sum2;
    logic [2:0][21:0] carry2;
    logic [1:0][12:0] den2;
    logic      [12:0] den_pass2;
  } MAC_STAGE2_REG;
  // Stage 3 -> 4: Chứa 4 vector (2 sum, 2 carry) cho tử số và tổng mẫu số gần cuối
  typedef struct packed {
    logic [1:0][21:0] sum4;
    logic [1:0][21:0] carry4;
    logic      [12:0] den3;
    logic      [12:0] den_pass3;
  } MAC_STAGE3_REG;
//======================MEDIAN_SWITCHING_STRUCT======================
  typedef struct packed {
    PIXEL_DATA vert_abs;
    PIXEL_DATA hor_abs;
    PIXEL_DATA crossl_abs;
    PIXEL_DATA crossr_abs;
    PIXEL_DATA center_px;
  } STAGE1_DEV_STAGE;
  typedef struct packed {
    PIXEL_DATA min_all;
    PIXEL_DATA center_px;
  } STAGE2_MIN_STAGE;
  typedef struct packed {
    logic                   noise_flag;
    PIXEL_DATA center_px;
  } STAGE3_DEC_STAGE;
//==================MEDIAN_FINDING_STRUCT==================
  typedef struct packed {
    logic [8:0][WIDTH_PIXEL-1:0] px;
  } STAGE1_CAL_STAGE;
  typedef struct packed {
    PIXEL_DATA max_of_mins;
    PIXEL_DATA med_of_meds;
    PIXEL_DATA min_of_maxs;
  } STAGE2_CAL_STAGE;
//==================BILATERAL_STRUCT==================
  typedef struct packed {
    logic [8:0][WIDTH_PIXEL-1:0] diff;
    logic [8:0][WIDTH_PIXEL-1:0] pre_px;
    logic [7:0]                  cout_diff;
  } STAGE1_ABS;
  typedef struct packed {
    logic [8:0][WIDTH_PIXEL-1:0] abs_diff;
    logic [8:0][WIDTH_PIXEL-1:0] pre_px;
  } STAGE2_LUT;
//==================DIVISION_STRUCT==================
  typedef struct packed {
    logic [13:0] o_remain4;
    logic [12:0] i_den;
    logic [7:0]  o_quoti4;
  } NEXT_DIV_STAGE;
endpackage
