/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      top controller
 * 
*/

/*
Function: hardware acceleration targeting the expensive computation patterns on the 2-side
including:
  1: xDBLe
  2: get_4_isog followed by multiple eval_4_isog
  3: xADD loop (modified xADD, the following mont_mul function call is pushed into it)

Assumptions:
  0: all the operands are from GF(p^2)
  1: all the inputs and outputs of the hardware modules are in range [0, 2*p-1]
  2: input memories have been initialized before the computation is triggered.
  3: contents of the output memories have been read back before any potential memory overwriting happens.
  4: (!!!) given assumption 1, all the add/sub computations by default are assumed to be the regularly 2*p corrected type.
     when there are two addition/subtraction units running in parallel, they are assumed to have exactly the same timing.

Input:
command_encoded
*/
 
module top_controller
#(
  // encoded commands
  parameter XDBLE_COMMAND = 1,
  parameter GET_4_ISOG_AND_EVAL_4_ISOG_COMMAND = 2,
  parameter XADD_LOOP_COMMAND = 3,
  // encoded sub-functions
  parameter XDBL_FUNCTION = 1,
  parameter GET_4_ISOG_FUNCTION = 2,
  parameter XADD_FUNCTION = 3,
  parameter EVAL_4_ISOG_FUNCTION = 4,
  // security and performance parameters
  parameter RADIX = 32,
  parameter WIDTH_REAL = 14,
  // configuration of the secret key (input m of xADD loop)
  parameter SK_MEM_WIDTH = 32,
  parameter SK_MEM_WIDTH_LOG = `CLOG2(SK_MEM_WIDTH),
  parameter SK_MEM_DEPTH = 32,
  parameter SK_MEM_DEPTH_LOG = `CLOG2(SK_MEM_DEPTH),
  // others
  parameter SINGLE_MEM_WIDTH = RADIX,
  parameter SINGLE_MEM_DEPTH = WIDTH_REAL,
  parameter SINGLE_MEM_DEPTH_LOG = `CLOG2(SINGLE_MEM_DEPTH),
  parameter DOUBLE_MEM_WIDTH = RADIX*2,
  parameter DOUBLE_MEM_DEPTH = (WIDTH_REAL+1)/2,
  parameter DOUBLE_MEM_DEPTH_LOG = `CLOG2(DOUBLE_MEM_DEPTH),
  // constant memories
  // p+1
  parameter FILE_CONST_P_PLUS_ONE = "mem_p_plus_one.mem",
  // 2*p
  parameter FILE_CONST_PX2 = "px2.mem",
  // 4*p
  parameter FILE_CONST_PX4 = "px4.mem",
  // pre-loaded secret key (Alice/Bob)
  parameter FILE_SK = "sk.mem"
)
(
  // common input and output signals
  input wire clk,
  input wire rst,
  input wire [7:0] command_encoded, // comes before start; stay high; can change after seeing a done signal
  input wire start, // one clock high signal
  output reg get_4_isog_busy,
  output wire busy,
  output wire xDBL_and_xADD_busy,
  output wire done,

// outside write signal for input memory of fp2_mont_mul
  input wire out_mult_A_rst,
  input wire out_mult_A_start,
  output wire mult_A_done,
  output wire mult_A_busy,

  input wire out_mult_A_mem_a_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_a_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_a_0_din,

  input wire out_mult_A_mem_a_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_a_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_a_1_din,  

  input wire out_mult_A_mem_b_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_b_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_b_0_din,

  input wire out_mult_A_mem_b_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_b_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_b_1_din, 

  input wire out_sub_mult_A_mem_res_rd_en,
  input wire [DOUBLE_MEM_DEPTH_LOG-1:0] out_sub_mult_A_mem_res_rd_addr,
  output wire [DOUBLE_MEM_WIDTH-1:0] sub_mult_A_mem_res_dout,

  input wire out_add_mult_A_mem_res_rd_en,
  input wire [DOUBLE_MEM_DEPTH_LOG-1:0] out_add_mult_A_mem_res_rd_addr,
  output wire [DOUBLE_MEM_WIDTH-1:0] add_mult_A_mem_res_dout,

 // outside write/read signals for input memory of xDBLe
  // interface with input mem X; result of xDBL is written back to input memories X/Z.
  input wire out_mem_X_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_X_0_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_X_0_dout,
  input wire out_mem_X_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_0_rd_addr,

  input wire out_mem_X_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_X_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_X_1_dout,
  input wire out_mem_X_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_1_rd_addr,

  // interface with input mem Z
  input wire out_mem_Z_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_Z_0_din,

  input wire out_mem_Z_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_Z_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_Z_0_dout,
  input wire out_mem_Z_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_Z_1_dout,
  input wire out_mem_Z_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_1_rd_addr,

  // outside write signals for input memory of get_4_isog_and_eval_4_isog
  // interface with input mem X4
  input wire out_mem_X4_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X4_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_X4_0_din,

  input wire out_mem_X4_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X4_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_X4_1_din,
 
  // interface with input mem Z4
  input wire out_mem_Z4_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z4_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_Z4_0_din,

  input wire out_mem_Z4_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z4_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_Z4_1_din,
 
  // outside read signals for result of get_4_isog_and_eval_4_isog from t10 and t11
  // interface with eval_4_isog's output memory t10 
  input wire out_mem_t10_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_0_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t10_0_dout,
 
  input wire out_mem_t10_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t10_1_dout,

    // interface with output memory t11 
  input wire out_mem_t11_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t11_0_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t11_0_dout,
 
  input wire out_mem_t11_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t11_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t11_1_dout,

  // outside write/read signals for input memory of xADD_Loop
  // interface with input mem XP; result of xADD is written back to input memories
  input wire out_mem_XP_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_XP_0_din,

  input wire out_mem_XP_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_XP_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_XP_0_dout,
  input wire out_mem_XP_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_XP_1_dout,
  input wire out_mem_XP_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_1_rd_addr,

  // interface with input mem ZP
  input wire out_mem_ZP_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_ZP_0_din,

  input wire out_mem_ZP_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_ZP_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_dout,
  input wire out_mem_ZP_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_dout,
  input wire out_mem_ZP_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_1_rd_addr,

  // interface with input mem XQ
  input wire out_mem_XQ_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_XQ_0_din,

  input wire out_mem_XQ_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_XQ_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_dout,
  input wire out_mem_XQ_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_dout,
  input wire out_mem_XQ_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_1_rd_addr,

  // interface with input mem ZQ
  input wire out_mem_ZQ_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_ZQ_0_din,

  input wire out_mem_ZQ_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_ZQ_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_dout,
  input wire out_mem_ZQ_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_dout,
  input wire out_mem_ZQ_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_1_rd_addr,

  // interface with input mem xPQ
  input wire out_mem_xPQ_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_xPQ_0_din,

  input wire out_mem_xPQ_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_xPQ_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_dout,
  input wire out_mem_xPQ_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_dout,
  input wire out_mem_xPQ_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_1_rd_addr,

  // interface with input mem zPQ
  input wire out_mem_zPQ_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_zPQ_0_din,

  input wire out_mem_zPQ_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_zPQ_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_dout,
  input wire out_mem_zPQ_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_dout,
  input wire out_mem_zPQ_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_1_rd_addr,

  // outside write/read signals for A24 and C24 constant memories
  // interface with input mem A24; A24/C24 is updated by get_4_isog
  input wire out_mem_A24_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_A24_0_din,

  input wire out_mem_A24_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_A24_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_A24_0_dout,
  input wire out_mem_A24_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_A24_1_dout,
  input wire out_mem_A24_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_1_rd_addr,

  // interface with input mem C24
  input wire out_mem_C24_0_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_0_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_C24_0_din,

  input wire out_mem_C24_1_wr_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_1_wr_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] out_mem_C24_1_din,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_C24_0_dout,
  input wire out_mem_C24_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_0_rd_addr,

  output wire [SINGLE_MEM_WIDTH-1:0] mem_C24_1_dout,
  input wire out_mem_C24_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_1_rd_addr, 

  // interface with secret key memory
  input out_sk_mem_wr_en,
  input wire [SK_MEM_DEPTH_LOG-1:0] out_sk_mem_wr_addr,
  input wire [SK_MEM_WIDTH-1:0] out_sk_mem_din,

  // other signals
  // number of loops in xDBLe function
  input wire [15:0] xDBLe_NUM_LOOPS,
  
  // the input memory X/Z of eval_4_isog is initialized; stay high
  input wire eval_4_isog_XZ_newly_init,
  // the input memory X/Z of eval_4_isog has been read and can be updated with new data; stay high
  output reg eval_4_isog_XZ_can_overwrite, 
  // this is the last input XZ to eval_4_isog; stay high
  input wire last_eval_4_isog,
  // the result for eval_4_isog is ready and can be read; stay high
  output reg eval_4_isog_result_ready,
  // the result for eval_4_isog has been read successfully; stay high
  input wire eval_4_isog_result_can_overwrite,

  // index = xADD_loop_start_index, xADD_loop_start_index+1, ..., xADD_loop_end_index-1, xADD_loop_end_index.
  input wire [15:0] xADD_loop_start_index, // start index of the main loop
  input wire [15:0] xADD_loop_end_index,   // end index of the main loop
  input  wire xADD_P_newly_loaded,
  output wire xADD_P_can_overwrite
);

// interface for controlelr of main sub-modules, including:
// 1: xDBL
// 2: get_4_isog
// 3: eval_4_isog
// 4: xADD

// interface to xDBL
// xDBL specific signals
// interface with memory X 
wire xDBL_mem_X_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_X_0_rd_addr; 
wire xDBL_mem_X_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_X_1_rd_addr;

// interface with memory Z 
wire xDBL_mem_Z_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_Z_0_rd_addr; 
wire xDBL_mem_Z_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_Z_1_rd_addr;

// interface with constant A24 
wire xDBL_mem_A24_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_A24_0_rd_addr; 
wire xDBL_mem_A24_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_A24_1_rd_addr;

// interface with constant C24 
wire xDBL_mem_C24_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_C24_0_rd_addr; 
wire xDBL_mem_C24_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_C24_1_rd_addr;

// interface to get_4_isog
// get_4_isog specific signals
// interface with memory X 
wire get_4_isog_mem_X4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_X4_0_rd_addr; 
wire get_4_isog_mem_X4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_X4_1_rd_addr;

// interface with memory Z 
wire get_4_isog_mem_Z4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_Z4_0_rd_addr; 
wire get_4_isog_mem_Z4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_Z4_1_rd_addr;

// interface to eval_4_isog
// eval_4_isog specific signals
// interface with memory X 
wire eval_4_isog_mem_X4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_X4_0_rd_addr; 
wire eval_4_isog_mem_X4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_X4_1_rd_addr;

// interface with memory Z 
wire eval_4_isog_mem_Z4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_Z4_0_rd_addr; 
wire eval_4_isog_mem_Z4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_Z4_1_rd_addr;

// interface with coeff memories
wire eval_4_isog_mem_C0_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C0_0_rd_addr; 
wire eval_4_isog_mem_C0_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C0_1_rd_addr;

wire eval_4_isog_mem_C1_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C1_0_rd_addr; 
wire eval_4_isog_mem_C1_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C1_1_rd_addr;

wire eval_4_isog_mem_C2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C2_0_rd_addr; 
wire eval_4_isog_mem_C2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C2_1_rd_addr;


// interface to xADD
// interface with  memory XP 
wire xADD_mem_XP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XP_0_rd_addr; 
wire xADD_mem_XP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XP_1_rd_addr; 

// interface with  memory ZP 
wire xADD_mem_ZP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZP_0_rd_addr; 
wire xADD_mem_ZP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZP_1_rd_addr; 

// interface with  memory XQ 
wire xADD_mem_XQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XQ_0_rd_addr; 
wire xADD_mem_XQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XQ_1_rd_addr; 

// interface with  memory ZQ 
wire xADD_mem_ZQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZQ_0_rd_addr; 
wire xADD_mem_ZQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZQ_1_rd_addr; 

// interface with  memory xPQ 
wire xADD_mem_xPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_xPQ_0_rd_addr; 
wire xADD_mem_xPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_xPQ_1_rd_addr; 

// interface with  memory zPQ 
wire xADD_mem_zPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_zPQ_0_rd_addr; 
wire xADD_mem_zPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_zPQ_1_rd_addr; 

 
// input for xADD
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_XQ_0_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_XQ_1_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_ZQ_0_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_ZQ_1_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_xPQ_0_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_xPQ_1_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_zPQ_0_dout;
wire[SINGLE_MEM_WIDTH-1:0] xADD_mem_zPQ_1_dout;

// interface to input memories that are touched in the top controller modules
// input memory of xDBLe, gets updated after every xDBL function call
reg top_mem_X_0_wr_en;
reg [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_X_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_X_0_din;
wire top_mem_X_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_X_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_X_1_din;

wire top_mem_Z_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_Z_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_Z_0_din;
wire top_mem_Z_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_Z_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_Z_1_din;
 
reg top_mem_XADD_wr_en;
reg [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_XADD_wr_addr;

wire top_mem_XQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_XQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_XQ_0_din;
wire top_mem_XQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_XQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_XQ_1_din;

wire top_mem_ZQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_ZQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_ZQ_0_din;
wire top_mem_ZQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_ZQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_ZQ_1_din;

wire top_mem_xPQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_xPQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_xPQ_0_din;
wire top_mem_xPQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_xPQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_xPQ_1_din;

wire top_mem_zPQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_zPQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_zPQ_0_din;
wire top_mem_zPQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_zPQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_zPQ_1_din;

// A24 and C24 are written by get_4_isog
reg top_mem_A24_0_wr_en;
reg [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_A24_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_A24_0_din;
wire top_mem_A24_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_A24_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_A24_1_din;

wire top_mem_C24_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_C24_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_C24_0_din;
wire top_mem_C24_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_C24_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_C24_1_din;

// interface to intermediate variable memories that are touched in the top_controller module
// t2 and t3 are read in xDBLe
wire top_xDBLe_mem_t2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xDBLe_mem_t2_0_rd_addr; 
wire top_xDBLe_mem_t2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xDBLe_mem_t2_1_rd_addr; 

wire top_xDBLe_mem_t3_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xDBLe_mem_t3_0_rd_addr; 
wire top_xDBLe_mem_t3_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xDBLe_mem_t3_1_rd_addr; 

// t1, t2, t3, t4, and t5 are read by get_4_isog 
wire top_get_4_isog_mem_t1_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t1_0_rd_addr; 
wire top_get_4_isog_mem_t1_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t1_1_rd_addr;

wire top_get_4_isog_mem_t2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t2_0_rd_addr; 
wire top_get_4_isog_mem_t2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t2_1_rd_addr; 

wire top_get_4_isog_mem_t3_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t3_0_rd_addr; 
wire top_get_4_isog_mem_t3_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t3_1_rd_addr; 

wire top_get_4_isog_mem_t4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t4_0_rd_addr; 
wire top_get_4_isog_mem_t4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t4_1_rd_addr; 

wire top_get_4_isog_mem_t5_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t5_0_rd_addr; 
wire top_get_4_isog_mem_t5_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_get_4_isog_mem_t5_1_rd_addr;

// t2, t3 and t7, t8, t9 are read by eval_4_isog 
wire top_eval_4_isog_mem_t2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_eval_4_isog_mem_t2_0_rd_addr; 
wire top_eval_4_isog_mem_t2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_eval_4_isog_mem_t2_1_rd_addr; 

wire top_eval_4_isog_mem_t3_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_eval_4_isog_mem_t3_0_rd_addr; 
wire top_eval_4_isog_mem_t3_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_eval_4_isog_mem_t3_1_rd_addr; 
 
// t2, t3, t5, and t10 are read in xADD_loop
wire top_xADD_loop_mem_t2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xADD_loop_mem_t2_0_rd_addr;
wire top_xADD_loop_mem_t2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xADD_loop_mem_t2_1_rd_addr;

wire top_xADD_loop_mem_t3_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xADD_loop_mem_t3_0_rd_addr;
wire top_xADD_loop_mem_t3_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_xADD_loop_mem_t3_1_rd_addr;
 
// general interface to input data memory
// xDBLe
wire mem_X_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_X_0_din;
wire mem_X_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_0_rd_addr; 

wire mem_X_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_X_1_din;
wire mem_X_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_1_rd_addr;

wire mem_Z_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z_0_din;
wire mem_Z_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_0_rd_addr; 

wire mem_Z_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z_1_din;
wire mem_Z_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_1_rd_addr;

// get/eval_4_isog
wire mem_X4_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_X4_0_din;
wire mem_X4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_0_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_X4_0_dout; 

wire mem_X4_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_X4_1_din;
wire mem_X4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_X4_1_dout;

wire mem_Z4_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_0_din;
wire mem_Z4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_0_dout;

wire mem_Z4_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_1_din;
wire mem_Z4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_1_dout;

// xADD loop
wire mem_XP_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_XP_0_din;
wire mem_XP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_0_rd_addr; 

wire mem_XP_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_XP_1_din;
wire mem_XP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_1_rd_addr;

wire mem_ZP_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_din;
wire mem_ZP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_0_rd_addr; 

wire mem_ZP_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_din;
wire mem_ZP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_1_rd_addr;

wire mem_XQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_din;
wire mem_XQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_0_rd_addr; 

wire mem_XQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_din;
wire mem_XQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_1_rd_addr;

wire mem_ZQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_din;
wire mem_ZQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_0_rd_addr; 

wire mem_ZQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_din;
wire mem_ZQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_1_rd_addr;

wire mem_xPQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_din;
wire mem_xPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_0_rd_addr; 

wire mem_xPQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_din;
wire mem_xPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_1_rd_addr;

wire mem_zPQ_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_din;
wire mem_zPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_0_rd_addr; 

wire mem_zPQ_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_din;
wire mem_zPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_1_rd_addr;

// general interface to constant memory
wire mem_A24_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_A24_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_A24_0_din;
wire mem_A24_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_A24_0_rd_addr; 

wire mem_A24_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_A24_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_A24_1_din;
wire mem_A24_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_A24_1_rd_addr;

wire mem_C24_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C24_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_C24_0_din;
wire mem_C24_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C24_0_rd_addr; 

wire mem_C24_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C24_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_C24_1_din;
wire mem_C24_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C24_1_rd_addr;

// general interface to the intermediate variable t memories' data_out
wire [SINGLE_MEM_WIDTH-1:0] mem_t0_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_t0_1_dout;

wire top_mem_t1_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t1_0_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t1_0_dout;
wire top_mem_t1_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t1_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t1_1_dout;

wire top_mem_t2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t2_0_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t2_0_dout;
wire top_mem_t2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t2_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t2_1_dout;

wire top_mem_t3_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t3_0_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t3_0_dout;
wire top_mem_t3_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t3_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t3_1_dout;

wire top_mem_t4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t4_0_rd_addr; 
wire top_mem_t4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t4_1_rd_addr; 

wire top_mem_t5_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t5_0_rd_addr; 
wire top_mem_t5_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t5_1_rd_addr; 

wire top_mem_t7_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t7_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t7_0_din;
wire top_mem_t7_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t7_0_rd_addr; 
wire top_mem_t7_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t7_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t7_1_din;
wire top_mem_t7_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t7_1_rd_addr; 

wire top_mem_t8_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t8_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t8_0_din;
wire top_mem_t8_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t8_0_rd_addr; 
wire top_mem_t8_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t8_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t8_1_din;
wire top_mem_t8_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t8_1_rd_addr; 

wire top_mem_t9_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t9_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t9_0_din;
wire top_mem_t9_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t9_0_rd_addr; 
wire top_mem_t9_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t9_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t9_1_din;
wire top_mem_t9_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t9_1_rd_addr; 

reg top_mem_t10_0_wr_en;
reg [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t10_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t10_0_din;
wire top_mem_t10_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t10_0_rd_addr; 
wire top_mem_t10_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t10_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t10_1_din;
wire top_mem_t10_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t10_1_rd_addr; 

wire top_mem_t11_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t11_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t11_0_din;
wire top_mem_t11_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t11_0_rd_addr; 
wire top_mem_t11_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t11_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] top_mem_t11_1_din;
wire top_mem_t11_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] top_mem_t11_1_rd_addr; 

// t4
wire mem_t4_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_din;
wire mem_t4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_dout;

wire mem_t4_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_din;
wire mem_t4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_dout;

// t5
wire mem_t5_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_din;
wire mem_t5_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_dout;

wire mem_t5_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t5_1_din;
wire mem_t5_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t5_1_dout;

// t6
wire mem_t6_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t6_0_din;
wire mem_t6_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t6_0_dout;

wire mem_t6_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t6_1_din;
wire mem_t6_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t6_1_dout;

// t7
wire mem_t7_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t7_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t7_0_din;
wire mem_t7_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t7_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t7_0_dout;

wire mem_t7_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t7_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t7_1_din;
wire mem_t7_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t7_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t7_1_dout;

// t8
wire mem_t8_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t8_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t8_0_din;
wire mem_t8_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t8_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t8_0_dout;

wire mem_t8_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t8_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t8_1_din;
wire mem_t8_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t8_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t8_1_dout;

  // t9
wire mem_t9_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t9_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t9_0_din;
wire mem_t9_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t9_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t9_0_dout;

wire mem_t9_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t9_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t9_1_din;
wire mem_t9_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t9_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t9_1_dout;


// t10
wire mem_t10_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_0_din;
wire mem_t10_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_0_rd_addr;  

wire mem_t10_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_1_din;
wire mem_t10_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_1_rd_addr;  

// finite state machine related signals
// common signals
reg [7:0] function_encoded;
wire controller_start;
wire controller_busy;
wire controller_done;
reg controller_start_reg;

// signals for result memory copy
reg [SINGLE_MEM_DEPTH_LOG-1:0] copy_counter;
wire last_copy_write;
reg last_copy_write_buf;

// added signal to avoid dead lock in 2-phase handshake
reg last_eval_4_isog_mem_X_0_rd_buf;
reg last_copy_write_buf_buf;

// specific signals for xDBLe
wire xDBLe_start;
reg xDBLe_busy;
reg xDBLe_done;
reg xDBL_start_pre;
reg [15:0] counter_for_loops;

// specific signals for get_4_isog_and_eval_4_isog
wire get_4_isog_and_eval_4_isog_start;
reg get_4_isog_and_eval_4_isog_busy;
reg get_4_isog_and_eval_4_isog_done;
reg eval_4_isog_start_pre;

// specific signals for xADD_Loop
wire xADD_loop_start;
reg xADD_loop_busy;
reg xADD_loop_done;
reg xADD_start_pre;
reg controller_start_pre;
reg [15:0] current_index;
reg message_bit_at_current_index;
wire xADD_controller_start;

// interface with sk memory 
wire [SK_MEM_DEPTH_LOG-1:0] sk_mem_rd_addr;
wire [SK_MEM_WIDTH-1:0] sk_mem_dout;

reg eval_4_isog_res_copy_start_pre;
 
reg xDBL_COMPUTATION_running;
reg xDBL_RES_COPY_running;
reg GET_4_ISOG_COMPUTATION_running;
reg GET_4_ISOG_RES_COPY_running;
reg EVAL_4_ISOG_COMPUTATION_running;
reg EVAL_4_ISOG_RES_COPY_running;
reg xADD_COMPUTATION_running;
reg xADD_RES_COPY_running;

// FSM states
          
parameter IDLE                    = 0,  
          // xDBLe states
          xDBL_COMPUTATION        = IDLE + 1,  
          xDBL_RES_COPY           = xDBL_COMPUTATION + 1,
          // get/eval_4_isog states
          GET_4_ISOG_COMPUTATION  = xDBL_RES_COPY + 1,
          GET_4_ISOG_RES_COPY     = GET_4_ISOG_COMPUTATION + 1,
          EVAL_4_ISOG_COMPUTATION = GET_4_ISOG_RES_COPY + 1,
          EVAL_4_ISOG_RES_COPY    = EVAL_4_ISOG_COMPUTATION + 1,
          // xADD states
          xADD_COMPUTATION     = EVAL_4_ISOG_RES_COPY + 1,
          xADD_RES_COPY        = xADD_COMPUTATION + 1,
          MAX_STATE               = xADD_RES_COPY + 1;

reg [`CLOG2(MAX_STATE)-1:0] state;

// memory wrapper
wire mult_A_mem_a_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_a_0_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_a_0_dout;

wire mult_A_mem_a_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_a_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_a_1_dout;

wire mult_A_mem_b_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_b_0_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_0_dout;

wire mult_A_mem_b_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_b_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_1_dout;

wire [SINGLE_MEM_WIDTH-1:0] memory_A24_X4_X_XP_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_A24_X4_X_XP_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_C24_Z4_Z_ZP_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_C24_Z4_Z_ZP_1_dout; 

assign mem_A24_0_dout = memory_A24_X4_X_XP_0_dout;
assign mem_X4_0_dout = memory_A24_X4_X_XP_0_dout;
assign mem_X_0_dout = memory_A24_X4_X_XP_0_dout;
assign mem_XP_0_dout = memory_A24_X4_X_XP_0_dout;

assign mem_A24_1_dout = memory_A24_X4_X_XP_1_dout;
assign mem_X4_1_dout = memory_A24_X4_X_XP_1_dout;
assign mem_X_1_dout = memory_A24_X4_X_XP_1_dout;
assign mem_XP_1_dout = memory_A24_X4_X_XP_1_dout;

assign mem_C24_0_dout = memory_C24_Z4_Z_ZP_0_dout;
assign mem_Z4_0_dout = memory_C24_Z4_Z_ZP_0_dout;
assign mem_Z_0_dout = memory_C24_Z4_Z_ZP_0_dout;
assign mem_ZP_0_dout = memory_C24_Z4_Z_ZP_0_dout;

assign mem_C24_1_dout = memory_C24_Z4_Z_ZP_1_dout;
assign mem_Z4_1_dout = memory_C24_Z4_Z_ZP_1_dout;
assign mem_Z_1_dout = memory_C24_Z4_Z_ZP_1_dout;
assign mem_ZP_1_dout = memory_C24_Z4_Z_ZP_1_dout; 

wire [SINGLE_MEM_WIDTH-1:0] memory_t6_XQ_a_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t6_XQ_a_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t7_ZQ_b_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t7_ZQ_b_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t8_xPQ_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t8_xPQ_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t9_zPQ_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] memory_t9_zPQ_1_dout;

assign mem_t6_0_dout = memory_t6_XQ_a_0_dout;
assign mem_XQ_0_dout = memory_t6_XQ_a_0_dout;
assign mem_t6_1_dout = memory_t6_XQ_a_1_dout;
assign mem_XQ_1_dout = memory_t6_XQ_a_1_dout;

assign mem_t7_0_dout = memory_t7_ZQ_b_0_dout;
assign mem_ZQ_0_dout = memory_t7_ZQ_b_0_dout;
assign mem_t7_1_dout = memory_t7_ZQ_b_1_dout;
assign mem_ZQ_1_dout = memory_t7_ZQ_b_1_dout;

assign mem_t8_0_dout = memory_t8_xPQ_0_dout;
assign mem_xPQ_0_dout = memory_t8_xPQ_0_dout;
assign mem_t8_1_dout = memory_t8_xPQ_1_dout;
assign mem_xPQ_1_dout = memory_t8_xPQ_1_dout;

assign mem_t9_0_dout = memory_t9_zPQ_0_dout;
assign mem_zPQ_0_dout = memory_t9_zPQ_0_dout;
assign mem_t9_1_dout = memory_t9_zPQ_1_dout;
assign mem_zPQ_1_dout = memory_t9_zPQ_1_dout;


// input memory of xDBL
// X
assign mem_X_0_wr_en = out_mem_X_0_wr_en | top_mem_X_0_wr_en;
assign mem_X_0_wr_addr = out_mem_X_0_wr_en ? out_mem_X_0_wr_addr :
                         top_mem_X_0_wr_en ? top_mem_X_0_wr_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
assign mem_X_0_din = out_mem_X_0_wr_en ? out_mem_X_0_din :
                     top_mem_X_0_wr_en ? top_mem_X_0_din :
                     {SINGLE_MEM_WIDTH{1'b0}}; 
assign mem_X_1_wr_en = out_mem_X_1_wr_en | top_mem_X_1_wr_en;
assign mem_X_1_wr_addr = out_mem_X_1_wr_en ? out_mem_X_1_wr_addr :
                         top_mem_X_1_wr_en ? top_mem_X_1_wr_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_X_1_din = out_mem_X_1_wr_en ? out_mem_X_1_din :
                     top_mem_X_1_wr_en ? top_mem_X_1_din :
                     {SINGLE_MEM_WIDTH{1'b0}}; 
assign mem_X_0_rd_en = out_mem_X_0_rd_en | xDBL_mem_X_0_rd_en;
assign mem_X_0_rd_addr = out_mem_X_0_rd_en ? out_mem_X_0_rd_addr :
                         xDBL_mem_X_0_rd_en ? xDBL_mem_X_0_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_X_1_rd_en = out_mem_X_1_rd_en | xDBL_mem_X_1_rd_en;
assign mem_X_1_rd_addr = out_mem_X_1_rd_en ? out_mem_X_1_rd_addr :
                         xDBL_mem_X_1_rd_en ? xDBL_mem_X_1_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};

// Z
assign mem_Z_0_wr_en = out_mem_Z_0_wr_en | top_mem_Z_0_wr_en;
assign mem_Z_0_wr_addr = out_mem_Z_0_wr_en ? out_mem_Z_0_wr_addr :
                         top_mem_Z_0_wr_en ? top_mem_Z_0_wr_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
assign mem_Z_0_din = out_mem_Z_0_wr_en ? out_mem_Z_0_din :
                     top_mem_Z_0_wr_en ? top_mem_Z_0_din :
                     {SINGLE_MEM_WIDTH{1'b0}}; 
assign mem_Z_1_wr_en = out_mem_Z_1_wr_en | top_mem_Z_1_wr_en;
assign mem_Z_1_wr_addr = out_mem_Z_1_wr_en ? out_mem_Z_1_wr_addr :
                         top_mem_Z_1_wr_en ? top_mem_Z_1_wr_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_Z_1_din = out_mem_Z_1_wr_en ? out_mem_Z_1_din :
                     top_mem_Z_1_wr_en ? top_mem_Z_1_din :
                     {SINGLE_MEM_WIDTH{1'b0}};
assign mem_Z_0_rd_en = out_mem_Z_0_rd_en | xDBL_mem_Z_0_rd_en;
assign mem_Z_0_rd_addr = out_mem_Z_0_rd_en ? out_mem_Z_0_rd_addr :
                         xDBL_mem_Z_0_rd_en ? xDBL_mem_Z_0_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_Z_1_rd_en = out_mem_Z_1_rd_en | xDBL_mem_Z_1_rd_en;
assign mem_Z_1_rd_addr = out_mem_Z_1_rd_en ? out_mem_Z_1_rd_addr :
                         xDBL_mem_Z_1_rd_en ? xDBL_mem_Z_1_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
 


// input memory of get/eval_4_isog
// X4
assign mem_X4_0_wr_en = out_mem_X4_0_wr_en;
assign mem_X4_0_wr_addr = out_mem_X4_0_wr_addr;
assign mem_X4_0_din = out_mem_X4_0_din;
assign mem_X4_1_wr_en = out_mem_X4_1_wr_en;
assign mem_X4_1_wr_addr = out_mem_X4_1_wr_addr;
assign mem_X4_1_din = out_mem_X4_1_din; 
assign mem_X4_0_rd_en = get_4_isog_mem_X4_0_rd_en | eval_4_isog_mem_X4_0_rd_en;
assign mem_X4_0_rd_addr = get_4_isog_mem_X4_0_rd_en ? get_4_isog_mem_X4_0_rd_addr :
                          eval_4_isog_mem_X4_0_rd_en ? eval_4_isog_mem_X4_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_X4_1_rd_en = get_4_isog_mem_X4_1_rd_en | eval_4_isog_mem_X4_1_rd_en;
assign mem_X4_1_rd_addr = get_4_isog_mem_X4_1_rd_en ? get_4_isog_mem_X4_1_rd_addr :
                          eval_4_isog_mem_X4_1_rd_en ? eval_4_isog_mem_X4_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// Z4
assign mem_Z4_0_wr_en = out_mem_Z4_0_wr_en;
assign mem_Z4_0_wr_addr = out_mem_Z4_0_wr_addr;
assign mem_Z4_0_din = out_mem_Z4_0_din;
assign mem_Z4_1_wr_en = out_mem_Z4_1_wr_en;
assign mem_Z4_1_wr_addr = out_mem_Z4_1_wr_addr;
assign mem_Z4_1_din = out_mem_Z4_1_din;
assign mem_Z4_0_rd_en = get_4_isog_mem_Z4_0_rd_en | eval_4_isog_mem_Z4_0_rd_en;
assign mem_Z4_0_rd_addr = get_4_isog_mem_Z4_0_rd_en ? get_4_isog_mem_Z4_0_rd_addr :
                          eval_4_isog_mem_Z4_0_rd_en ? eval_4_isog_mem_Z4_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_Z4_1_rd_en = get_4_isog_mem_Z4_1_rd_en | eval_4_isog_mem_Z4_1_rd_en;
assign mem_Z4_1_rd_addr = get_4_isog_mem_Z4_1_rd_en ? get_4_isog_mem_Z4_1_rd_addr :
                          eval_4_isog_mem_Z4_1_rd_en ? eval_4_isog_mem_Z4_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};



// input memory of xADD
// XP
assign mem_XP_0_wr_en = out_mem_XP_0_wr_en;
assign mem_XP_0_wr_addr = out_mem_XP_0_wr_en ? out_mem_XP_0_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XP_0_din = out_mem_XP_0_wr_en ? out_mem_XP_0_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_XP_1_wr_en = out_mem_XP_1_wr_en;
assign mem_XP_1_wr_addr = out_mem_XP_1_wr_en ? out_mem_XP_1_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XP_1_din = out_mem_XP_1_wr_en ? out_mem_XP_1_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_XP_0_rd_en = out_mem_XP_0_rd_en | xADD_mem_XP_0_rd_en;
assign mem_XP_0_rd_addr = out_mem_XP_0_rd_en ? out_mem_XP_0_rd_addr :
                          xADD_mem_XP_0_rd_en ? xADD_mem_XP_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XP_1_rd_en = out_mem_XP_1_rd_en | xADD_mem_XP_1_rd_en;
assign mem_XP_1_rd_addr = out_mem_XP_1_rd_en ? out_mem_XP_1_rd_addr :
                          xADD_mem_XP_1_rd_en ? xADD_mem_XP_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};


// ZP
assign mem_ZP_0_wr_en = out_mem_ZP_0_wr_en;
assign mem_ZP_0_wr_addr = out_mem_ZP_0_wr_en ? out_mem_ZP_0_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZP_0_din = out_mem_ZP_0_wr_en ? out_mem_ZP_0_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_ZP_1_wr_en = out_mem_ZP_1_wr_en;
assign mem_ZP_1_wr_addr = out_mem_ZP_1_wr_en ? out_mem_ZP_1_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZP_1_din = out_mem_ZP_1_wr_en ? out_mem_ZP_1_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_ZP_0_rd_en = out_mem_ZP_0_rd_en | xADD_mem_ZP_0_rd_en;
assign mem_ZP_0_rd_addr = out_mem_ZP_0_rd_en ? out_mem_ZP_0_rd_addr :
                          xADD_mem_ZP_0_rd_en ? xADD_mem_ZP_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZP_1_rd_en = out_mem_ZP_1_rd_en | xADD_mem_ZP_1_rd_en;
assign mem_ZP_1_rd_addr = out_mem_ZP_1_rd_en ? out_mem_ZP_1_rd_addr :
                          xADD_mem_ZP_1_rd_en ? xADD_mem_ZP_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};


// XQ
assign mem_XQ_0_wr_en = out_mem_XQ_0_wr_en | top_mem_XQ_0_wr_en;
assign mem_XQ_0_wr_addr = out_mem_XQ_0_wr_en ? out_mem_XQ_0_wr_addr :
                          top_mem_XQ_0_wr_en ? top_mem_XQ_0_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XQ_0_din = out_mem_XQ_0_wr_en ? out_mem_XQ_0_din :
                      top_mem_XQ_0_wr_en ? top_mem_XQ_0_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_XQ_1_wr_en = out_mem_XQ_1_wr_en | top_mem_XQ_1_wr_en;
assign mem_XQ_1_wr_addr = out_mem_XQ_1_wr_en ? out_mem_XQ_1_wr_addr :
                          top_mem_XQ_1_wr_en ? top_mem_XQ_1_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XQ_1_din = out_mem_XQ_1_wr_en ? out_mem_XQ_1_din :
                      top_mem_XQ_1_wr_en ? top_mem_XQ_1_din :
                      {SINGLE_MEM_WIDTH{1'b0}};                          
assign mem_XQ_0_rd_en = out_mem_XQ_0_rd_en | (xADD_mem_XQ_0_rd_en & (!message_bit_at_current_index)) | (xADD_mem_xPQ_0_rd_en & message_bit_at_current_index);
assign mem_XQ_0_rd_addr = out_mem_XQ_0_rd_en ? out_mem_XQ_0_rd_addr :
                          xADD_mem_XQ_0_rd_en & (!message_bit_at_current_index) ? xADD_mem_XQ_0_rd_addr :
                          (xADD_mem_xPQ_0_rd_en & message_bit_at_current_index) ? xADD_mem_xPQ_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XQ_1_rd_en = out_mem_XQ_1_rd_en | (xADD_mem_XQ_1_rd_en & (!message_bit_at_current_index)) | (xADD_mem_xPQ_1_rd_en & message_bit_at_current_index);
assign mem_XQ_1_rd_addr = out_mem_XQ_1_rd_en ? out_mem_XQ_1_rd_addr :
                          xADD_mem_XQ_1_rd_en & (!message_bit_at_current_index) ? xADD_mem_XQ_1_rd_addr :
                          (xADD_mem_xPQ_1_rd_en & message_bit_at_current_index) ? xADD_mem_xPQ_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// ZQ
assign mem_ZQ_0_wr_en = out_mem_ZQ_0_wr_en | top_mem_ZQ_0_wr_en;
assign mem_ZQ_0_wr_addr = out_mem_ZQ_0_wr_en ? out_mem_ZQ_0_wr_addr :
                          top_mem_ZQ_0_wr_en ? top_mem_ZQ_0_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZQ_0_din = out_mem_ZQ_0_wr_en ? out_mem_ZQ_0_din :
                      top_mem_ZQ_0_wr_en ? top_mem_ZQ_0_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_ZQ_1_wr_en = out_mem_ZQ_1_wr_en | top_mem_ZQ_1_wr_en;
assign mem_ZQ_1_wr_addr = out_mem_ZQ_1_wr_en ? out_mem_ZQ_1_wr_addr :
                          top_mem_ZQ_1_wr_en ? top_mem_ZQ_1_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZQ_1_din = out_mem_ZQ_1_wr_en ? out_mem_ZQ_1_din :
                      top_mem_ZQ_1_wr_en ? top_mem_ZQ_1_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_ZQ_0_rd_en = out_mem_ZQ_0_rd_en | (xADD_mem_ZQ_0_rd_en & (!message_bit_at_current_index)) | (xADD_mem_zPQ_0_rd_en & message_bit_at_current_index);
assign mem_ZQ_0_rd_addr = out_mem_ZQ_0_rd_en ? out_mem_ZQ_0_rd_addr :
                          xADD_mem_ZQ_0_rd_en & (!message_bit_at_current_index) ? xADD_mem_ZQ_0_rd_addr :
                          (xADD_mem_zPQ_0_rd_en & message_bit_at_current_index) ? xADD_mem_zPQ_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZQ_1_rd_en = out_mem_ZQ_1_rd_en | (xADD_mem_ZQ_1_rd_en & (!message_bit_at_current_index)) | (xADD_mem_zPQ_1_rd_en & message_bit_at_current_index);
assign mem_ZQ_1_rd_addr = out_mem_ZQ_1_rd_en ? out_mem_ZQ_1_rd_addr :
                          xADD_mem_ZQ_1_rd_en & (!message_bit_at_current_index) ? xADD_mem_ZQ_1_rd_addr :
                          (xADD_mem_zPQ_1_rd_en & message_bit_at_current_index) ? xADD_mem_zPQ_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};


// xPQ
assign mem_xPQ_0_wr_en = out_mem_xPQ_0_wr_en | top_mem_xPQ_0_wr_en;
assign mem_xPQ_0_wr_addr = out_mem_xPQ_0_wr_en ? out_mem_xPQ_0_wr_addr :
                          top_mem_xPQ_0_wr_en ? top_mem_xPQ_0_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_xPQ_0_din = out_mem_xPQ_0_wr_en ? out_mem_xPQ_0_din :
                       top_mem_xPQ_0_wr_en ? top_mem_xPQ_0_din :
                       {SINGLE_MEM_WIDTH{1'b0}};
assign mem_xPQ_1_wr_en = out_mem_xPQ_1_wr_en | top_mem_xPQ_1_wr_en;
assign mem_xPQ_1_wr_addr = out_mem_xPQ_1_wr_en ? out_mem_xPQ_1_wr_addr :
                          top_mem_xPQ_1_wr_en ? top_mem_xPQ_1_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_xPQ_1_din = out_mem_xPQ_1_wr_en ? out_mem_xPQ_1_din :
                       top_mem_xPQ_1_wr_en ? top_mem_xPQ_1_din :
                       {SINGLE_MEM_WIDTH{1'b0}};                         
assign mem_xPQ_0_rd_en = out_mem_xPQ_0_rd_en | (xADD_mem_xPQ_0_rd_en & (!message_bit_at_current_index)) | (xADD_mem_XQ_0_rd_en & message_bit_at_current_index);
assign mem_xPQ_0_rd_addr = out_mem_xPQ_0_rd_en ? out_mem_xPQ_0_rd_addr :
                          xADD_mem_xPQ_0_rd_en & (!message_bit_at_current_index) ? xADD_mem_xPQ_0_rd_addr :
                          (xADD_mem_XQ_0_rd_en & message_bit_at_current_index) ? xADD_mem_XQ_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_xPQ_1_rd_en = out_mem_xPQ_1_rd_en | (xADD_mem_xPQ_1_rd_en & (!message_bit_at_current_index)) | (xADD_mem_XQ_1_rd_en & message_bit_at_current_index);
assign mem_xPQ_1_rd_addr = out_mem_xPQ_1_rd_en ? out_mem_xPQ_1_rd_addr :
                          xADD_mem_xPQ_1_rd_en & (!message_bit_at_current_index) ? xADD_mem_xPQ_1_rd_addr :
                          (xADD_mem_XQ_1_rd_en & message_bit_at_current_index) ? xADD_mem_XQ_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// zPQ
assign mem_zPQ_0_wr_en = out_mem_zPQ_0_wr_en | top_mem_zPQ_0_wr_en;
assign mem_zPQ_0_wr_addr = out_mem_zPQ_0_wr_en ? out_mem_zPQ_0_wr_addr :
                          top_mem_zPQ_0_wr_en ? top_mem_zPQ_0_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_zPQ_0_din = out_mem_zPQ_0_wr_en ? out_mem_zPQ_0_din :
                       top_mem_zPQ_0_wr_en ? top_mem_zPQ_0_din :
                       {SINGLE_MEM_WIDTH{1'b0}};
assign mem_zPQ_1_wr_en = out_mem_zPQ_1_wr_en | top_mem_zPQ_1_wr_en;
assign mem_zPQ_1_wr_addr = out_mem_zPQ_1_wr_en ? out_mem_zPQ_1_wr_addr :
                          top_mem_zPQ_1_wr_en ? top_mem_zPQ_1_wr_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_zPQ_1_din = out_mem_zPQ_1_wr_en ? out_mem_zPQ_1_din :
                      top_mem_zPQ_1_wr_en ? top_mem_zPQ_1_din :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_zPQ_0_rd_en = out_mem_zPQ_0_rd_en | (xADD_mem_zPQ_0_rd_en & (!message_bit_at_current_index)) | (xADD_mem_ZQ_0_rd_en & message_bit_at_current_index);
assign mem_zPQ_0_rd_addr = out_mem_zPQ_0_rd_en ? out_mem_zPQ_0_rd_addr :
                          xADD_mem_zPQ_0_rd_en & (!message_bit_at_current_index) ? xADD_mem_zPQ_0_rd_addr :
                          (xADD_mem_ZQ_0_rd_en & message_bit_at_current_index) ? xADD_mem_ZQ_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_zPQ_1_rd_en = out_mem_zPQ_1_rd_en | (xADD_mem_zPQ_1_rd_en & (!message_bit_at_current_index)) | (xADD_mem_ZQ_1_rd_en & message_bit_at_current_index);
assign mem_zPQ_1_rd_addr = out_mem_zPQ_1_rd_en ? out_mem_zPQ_1_rd_addr :
                          xADD_mem_zPQ_1_rd_en & (!message_bit_at_current_index) ? xADD_mem_zPQ_1_rd_addr :
                          (xADD_mem_ZQ_1_rd_en & message_bit_at_current_index) ? xADD_mem_ZQ_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// constant memories
// A24
assign mem_A24_0_wr_en = out_mem_A24_0_wr_en | top_mem_A24_0_wr_en;
assign mem_A24_0_wr_addr = out_mem_A24_0_wr_en ? out_mem_A24_0_wr_addr :
                           top_mem_A24_0_wr_en ? top_mem_A24_0_wr_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_A24_0_din = out_mem_A24_0_wr_en ? out_mem_A24_0_din :
                       top_mem_A24_0_wr_en ? top_mem_A24_0_din :
                       {SINGLE_MEM_WIDTH{1'b0}};
assign mem_A24_1_wr_en = out_mem_A24_1_wr_en | top_mem_A24_1_wr_en;
assign mem_A24_1_wr_addr = out_mem_A24_1_wr_en ? out_mem_A24_1_wr_addr :
                           top_mem_A24_1_wr_en ? top_mem_A24_1_wr_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_A24_1_din = out_mem_A24_1_wr_en ? out_mem_A24_1_din :
                       top_mem_A24_1_wr_en ? top_mem_A24_1_din :
                       {SINGLE_MEM_WIDTH{1'b0}};
assign mem_A24_0_rd_en = out_mem_A24_0_rd_en | xDBL_mem_A24_0_rd_en;
assign mem_A24_0_rd_addr = out_mem_A24_0_rd_en ? out_mem_A24_0_rd_addr :
                           xDBL_mem_A24_0_rd_en ? xDBL_mem_A24_0_rd_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};                                                    
assign mem_A24_1_rd_en = out_mem_A24_1_rd_en | xDBL_mem_A24_1_rd_en;
assign mem_A24_1_rd_addr = out_mem_A24_1_rd_en ? out_mem_A24_1_rd_addr :
                           xDBL_mem_A24_1_rd_en ? xDBL_mem_A24_1_rd_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};

// C24
assign mem_C24_0_wr_en = out_mem_C24_0_wr_en | top_mem_C24_0_wr_en;
assign mem_C24_0_wr_addr = out_mem_C24_0_wr_en ? out_mem_C24_0_wr_addr :
                           top_mem_C24_0_wr_en ? top_mem_C24_0_wr_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C24_0_din = out_mem_C24_0_wr_en ? out_mem_C24_0_din :
                       top_mem_C24_0_wr_en ? top_mem_C24_0_din :
                       {SINGLE_MEM_WIDTH{1'b0}};                
assign mem_C24_1_wr_en = out_mem_C24_1_wr_en | top_mem_C24_1_wr_en;
assign mem_C24_1_wr_addr = out_mem_C24_1_wr_en ? out_mem_C24_1_wr_addr :
                           top_mem_C24_1_wr_en ? top_mem_C24_1_wr_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C24_1_din = out_mem_C24_1_wr_en ? out_mem_C24_1_din :
                       top_mem_C24_1_wr_en ? top_mem_C24_1_din :
                       {SINGLE_MEM_WIDTH{1'b0}};
assign mem_C24_0_rd_en = out_mem_C24_0_rd_en | xDBL_mem_C24_0_rd_en;
assign mem_C24_0_rd_addr = out_mem_C24_0_rd_en ? out_mem_C24_0_rd_addr :
                           xDBL_mem_C24_0_rd_en ? xDBL_mem_C24_0_rd_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C24_1_rd_en = out_mem_C24_1_rd_en | xDBL_mem_C24_1_rd_en;
assign mem_C24_1_rd_addr = out_mem_C24_1_rd_en ? out_mem_C24_1_rd_addr :
                           xDBL_mem_C24_1_rd_en ? xDBL_mem_C24_1_rd_addr :
                           {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to t memories
// t1
assign top_mem_t1_0_rd_en = top_get_4_isog_mem_t1_0_rd_en;
assign top_mem_t1_0_rd_addr = top_get_4_isog_mem_t1_0_rd_addr;
assign top_mem_t1_1_rd_en = top_get_4_isog_mem_t1_1_rd_en;
assign top_mem_t1_1_rd_addr = top_get_4_isog_mem_t1_1_rd_addr;

// t2
assign top_mem_t2_0_rd_en = top_xDBLe_mem_t2_0_rd_en | top_get_4_isog_mem_t2_0_rd_en | top_eval_4_isog_mem_t2_0_rd_en | top_xADD_loop_mem_t2_0_rd_en;
assign top_mem_t2_0_rd_addr = top_xDBLe_mem_t2_0_rd_en ? top_xDBLe_mem_t2_0_rd_addr : 
                              top_get_4_isog_mem_t2_0_rd_en ? top_get_4_isog_mem_t2_0_rd_addr : 
                              top_eval_4_isog_mem_t2_0_rd_en ? top_eval_4_isog_mem_t2_0_rd_addr :
                              top_xADD_loop_mem_t2_0_rd_en ? top_xADD_loop_mem_t2_0_rd_addr :
                              {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign top_mem_t2_1_rd_en = top_xDBLe_mem_t2_1_rd_en | top_get_4_isog_mem_t2_1_rd_en | top_eval_4_isog_mem_t2_1_rd_en | top_xADD_loop_mem_t2_1_rd_en;
assign top_mem_t2_1_rd_addr = top_xDBLe_mem_t2_1_rd_en ? top_xDBLe_mem_t2_1_rd_addr : 
                              top_get_4_isog_mem_t2_1_rd_en ? top_get_4_isog_mem_t2_1_rd_addr : 
                              top_eval_4_isog_mem_t2_1_rd_en ? top_eval_4_isog_mem_t2_1_rd_addr :
                              top_xADD_loop_mem_t2_1_rd_en ? top_xADD_loop_mem_t2_1_rd_addr :
                              {SINGLE_MEM_DEPTH_LOG{1'b0}};   

// t3
assign top_mem_t3_0_rd_en = top_xDBLe_mem_t3_0_rd_en | top_get_4_isog_mem_t3_0_rd_en | top_eval_4_isog_mem_t3_0_rd_en | top_xADD_loop_mem_t3_0_rd_en;
assign top_mem_t3_0_rd_addr = top_xDBLe_mem_t3_0_rd_en ? top_xDBLe_mem_t3_0_rd_addr : 
                              top_get_4_isog_mem_t3_0_rd_en ? top_get_4_isog_mem_t3_0_rd_addr : 
                              top_eval_4_isog_mem_t3_0_rd_en ? top_eval_4_isog_mem_t3_0_rd_addr :
                              top_xADD_loop_mem_t3_0_rd_en ? top_xADD_loop_mem_t3_0_rd_addr :
                              {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign top_mem_t3_1_rd_en = top_xDBLe_mem_t3_1_rd_en | top_get_4_isog_mem_t3_1_rd_en | top_eval_4_isog_mem_t3_1_rd_en | top_xADD_loop_mem_t3_1_rd_en;
assign top_mem_t3_1_rd_addr = top_xDBLe_mem_t3_1_rd_en ? top_xDBLe_mem_t3_1_rd_addr : 
                              top_get_4_isog_mem_t3_1_rd_en ? top_get_4_isog_mem_t3_1_rd_addr : 
                              top_eval_4_isog_mem_t3_1_rd_en ? top_eval_4_isog_mem_t3_1_rd_addr :
                              top_xADD_loop_mem_t3_1_rd_en ? top_xADD_loop_mem_t3_1_rd_addr :
                              {SINGLE_MEM_DEPTH_LOG{1'b0}};

// t4
assign top_mem_t4_0_rd_en = top_get_4_isog_mem_t4_0_rd_en;
assign top_mem_t4_0_rd_addr = top_get_4_isog_mem_t4_0_rd_addr;
assign top_mem_t4_1_rd_en = top_get_4_isog_mem_t4_1_rd_en;
assign top_mem_t4_1_rd_addr = top_get_4_isog_mem_t4_1_rd_addr;

// t5
assign top_mem_t5_0_rd_en = top_get_4_isog_mem_t5_0_rd_en;
assign top_mem_t5_0_rd_addr = top_get_4_isog_mem_t5_0_rd_en ? top_get_4_isog_mem_t5_0_rd_addr :
                              {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
assign top_mem_t5_1_rd_en = top_get_4_isog_mem_t5_1_rd_en;
assign top_mem_t5_1_rd_addr = top_get_4_isog_mem_t5_1_rd_en ? top_get_4_isog_mem_t5_1_rd_addr :
                              {SINGLE_MEM_DEPTH_LOG{1'b0}};

// t6 is not used

// t7
assign top_mem_t7_0_wr_en = top_mem_A24_0_wr_en;
assign top_mem_t7_0_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_t7_0_din = mem_t1_0_dout;
assign top_mem_t7_1_wr_en = top_mem_A24_0_wr_en;
assign top_mem_t7_1_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_t7_1_din = mem_t1_1_dout;
assign top_mem_t7_0_rd_en = eval_4_isog_mem_C0_0_rd_en;
assign top_mem_t7_0_rd_addr = eval_4_isog_mem_C0_0_rd_addr;
assign top_mem_t7_1_rd_en = eval_4_isog_mem_C0_1_rd_en;
assign top_mem_t7_1_rd_addr = eval_4_isog_mem_C0_1_rd_addr;

// t8
assign top_mem_t8_0_wr_en = top_mem_A24_0_wr_en;
assign top_mem_t8_0_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_t8_0_din = mem_t5_0_dout;
assign top_mem_t8_1_wr_en = top_mem_A24_0_wr_en;
assign top_mem_t8_1_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_t8_1_din = mem_t5_1_dout;
assign top_mem_t8_0_rd_en = eval_4_isog_mem_C1_0_rd_en;
assign top_mem_t8_0_rd_addr = eval_4_isog_mem_C1_0_rd_addr;
assign top_mem_t8_1_rd_en = eval_4_isog_mem_C1_1_rd_en;
assign top_mem_t8_1_rd_addr = eval_4_isog_mem_C1_1_rd_addr;

// t9
assign top_mem_t9_0_wr_en = top_mem_A24_0_wr_en;
assign top_mem_t9_0_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_t9_0_din = mem_t4_0_dout;
assign top_mem_t9_1_wr_en = top_mem_A24_0_wr_en;
assign top_mem_t9_1_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_t9_1_din = mem_t4_1_dout;
assign top_mem_t9_0_rd_en = eval_4_isog_mem_C2_0_rd_en;
assign top_mem_t9_0_rd_addr = eval_4_isog_mem_C2_0_rd_addr;
assign top_mem_t9_1_rd_en = eval_4_isog_mem_C2_1_rd_en;
assign top_mem_t9_1_rd_addr = eval_4_isog_mem_C2_1_rd_addr;


// t10
assign top_mem_t10_0_din = mem_t2_0_dout;
assign top_mem_t10_1_wr_en = top_mem_t10_0_wr_en;
assign top_mem_t10_1_wr_addr = top_mem_t10_0_wr_addr;
assign top_mem_t10_1_din = mem_t2_1_dout;
assign top_mem_t10_0_rd_en = out_mem_t10_0_rd_en;
assign top_mem_t10_0_rd_addr = out_mem_t10_0_rd_en ? out_mem_t10_0_rd_addr :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign top_mem_t10_1_rd_en = out_mem_t10_1_rd_en;
assign top_mem_t10_1_rd_addr = out_mem_t10_1_rd_en ? out_mem_t10_1_rd_addr :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// t11 is only accessed by the outside world
assign top_mem_t11_0_wr_en = top_mem_t10_0_wr_en;
assign top_mem_t11_0_wr_addr = top_mem_t10_0_wr_addr;
assign top_mem_t11_0_din = mem_t3_0_dout;
assign top_mem_t11_1_wr_en = top_mem_t10_0_wr_en;
assign top_mem_t11_1_wr_addr = top_mem_t10_0_wr_addr;
assign top_mem_t11_1_din = mem_t3_1_dout;
assign top_mem_t11_0_rd_en = out_mem_t11_0_rd_en;
assign top_mem_t11_0_rd_addr = out_mem_t11_0_rd_addr;
assign top_mem_t11_1_rd_en = out_mem_t11_1_rd_en;
assign top_mem_t11_1_rd_addr = out_mem_t11_1_rd_addr;

assign top_mem_X_0_din = mem_t2_0_dout;
assign top_mem_X_1_wr_en = top_mem_X_0_wr_en;
assign top_mem_X_1_wr_addr = top_mem_X_0_wr_addr;
assign top_mem_X_1_din = mem_t2_1_dout;

assign top_mem_Z_0_wr_en = top_mem_X_0_wr_en;
assign top_mem_Z_0_wr_addr = top_mem_X_0_wr_addr;
assign top_mem_Z_0_din = mem_t3_0_dout;
assign top_mem_Z_1_wr_en = top_mem_X_0_wr_en;
assign top_mem_Z_1_wr_addr = top_mem_X_0_wr_addr;
assign top_mem_Z_1_din = mem_t3_1_dout;
 
assign top_mem_XQ_0_wr_en = top_mem_XADD_wr_en & (!message_bit_at_current_index);
assign top_mem_XQ_0_wr_addr = top_mem_XQ_0_wr_en ? top_mem_XADD_wr_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign top_mem_XQ_0_din = mem_t2_0_dout;
assign top_mem_XQ_1_wr_en = top_mem_XQ_0_wr_en;
assign top_mem_XQ_1_wr_addr = top_mem_XQ_0_wr_addr;
assign top_mem_XQ_1_din = mem_t2_1_dout;

assign top_mem_ZQ_0_wr_en = top_mem_XQ_0_wr_en;
assign top_mem_ZQ_0_wr_addr = top_mem_XQ_0_wr_addr;
assign top_mem_ZQ_0_din = mem_t3_0_dout;
assign top_mem_ZQ_1_wr_en = top_mem_XQ_0_wr_en;
assign top_mem_ZQ_1_wr_addr = top_mem_XQ_0_wr_addr;
assign top_mem_ZQ_1_din = mem_t3_1_dout;

assign top_mem_xPQ_0_wr_en = top_mem_XADD_wr_en & message_bit_at_current_index;
assign top_mem_xPQ_0_wr_addr = top_mem_xPQ_0_wr_en ? top_mem_XADD_wr_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign top_mem_xPQ_0_din = mem_t2_0_dout;
assign top_mem_xPQ_1_wr_en = top_mem_xPQ_0_wr_en;
assign top_mem_xPQ_1_wr_addr = top_mem_xPQ_0_wr_addr;
assign top_mem_xPQ_1_din = mem_t2_1_dout;

assign top_mem_zPQ_0_wr_en = top_mem_xPQ_0_wr_en;
assign top_mem_zPQ_0_wr_addr = top_mem_xPQ_0_wr_addr;
assign top_mem_zPQ_0_din = mem_t3_0_dout;
assign top_mem_zPQ_1_wr_en = top_mem_xPQ_0_wr_en;
assign top_mem_zPQ_1_wr_addr = top_mem_xPQ_0_wr_addr;
assign top_mem_zPQ_1_din = mem_t3_1_dout;

assign xADD_mem_XQ_0_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_XQ_0_dout :
                               xADD_loop_busy ? mem_xPQ_0_dout :
                               {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_XQ_1_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_XQ_1_dout :
                               xADD_loop_busy ? mem_xPQ_1_dout :
                               {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_ZQ_0_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_ZQ_0_dout :
                               xADD_loop_busy ? mem_zPQ_0_dout :
                               {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_ZQ_1_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_ZQ_1_dout :
                               xADD_loop_busy ? mem_zPQ_1_dout :
                               {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_xPQ_0_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_xPQ_0_dout :
                                xADD_loop_busy ? mem_XQ_0_dout :
                                {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_xPQ_1_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_xPQ_1_dout :
                                xADD_loop_busy ? mem_XQ_1_dout :
                                {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_zPQ_0_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_zPQ_0_dout :
                                xADD_loop_busy ? mem_ZQ_0_dout :
                                {SINGLE_MEM_WIDTH{1'b0}};
assign xADD_mem_zPQ_1_dout = xADD_loop_busy & (!message_bit_at_current_index) ? mem_zPQ_1_dout :
                                xADD_loop_busy ? mem_ZQ_1_dout :
                                {SINGLE_MEM_WIDTH{1'b0}};

assign top_mem_A24_0_din = mem_t2_0_dout;
assign top_mem_A24_1_wr_en = top_mem_A24_0_wr_en;
assign top_mem_A24_1_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_A24_1_din = mem_t2_1_dout;

assign top_mem_C24_0_wr_en = top_mem_A24_0_wr_en;
assign top_mem_C24_0_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_C24_0_din = mem_t3_0_dout;
assign top_mem_C24_1_wr_en = top_mem_A24_0_wr_en;
assign top_mem_C24_1_wr_addr = top_mem_A24_0_wr_addr;
assign top_mem_C24_1_din = mem_t3_1_dout;

assign top_xDBLe_mem_t2_0_rd_en = xDBL_RES_COPY_running;
assign top_xDBLe_mem_t2_1_rd_en = xDBL_RES_COPY_running;
assign top_xDBLe_mem_t3_0_rd_en = xDBL_RES_COPY_running;
assign top_xDBLe_mem_t3_1_rd_en = xDBL_RES_COPY_running;
assign top_xDBLe_mem_t2_0_rd_addr = copy_counter;
assign top_xDBLe_mem_t2_1_rd_addr = copy_counter;
assign top_xDBLe_mem_t3_0_rd_addr = copy_counter;
assign top_xDBLe_mem_t3_1_rd_addr = copy_counter;

assign top_xADD_loop_mem_t2_0_rd_en = xADD_RES_COPY_running;
assign top_xADD_loop_mem_t2_1_rd_en = xADD_RES_COPY_running;
assign top_xADD_loop_mem_t3_0_rd_en = xADD_RES_COPY_running;
assign top_xADD_loop_mem_t3_1_rd_en = xADD_RES_COPY_running; 
assign top_xADD_loop_mem_t2_0_rd_addr = copy_counter;
assign top_xADD_loop_mem_t2_1_rd_addr = copy_counter;
assign top_xADD_loop_mem_t3_0_rd_addr = copy_counter;
assign top_xADD_loop_mem_t3_1_rd_addr = copy_counter; 

assign top_get_4_isog_mem_t1_0_rd_en = GET_4_ISOG_RES_COPY_running; 
assign top_get_4_isog_mem_t1_1_rd_en = GET_4_ISOG_RES_COPY_running; 
assign top_get_4_isog_mem_t2_0_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t2_1_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t3_0_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t3_1_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t4_0_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t4_1_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t5_0_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t5_1_rd_en = GET_4_ISOG_RES_COPY_running;
assign top_get_4_isog_mem_t1_0_rd_addr = copy_counter; 
assign top_get_4_isog_mem_t1_1_rd_addr = copy_counter; 
assign top_get_4_isog_mem_t2_0_rd_addr = copy_counter;
assign top_get_4_isog_mem_t2_1_rd_addr = copy_counter;
assign top_get_4_isog_mem_t3_0_rd_addr = copy_counter;
assign top_get_4_isog_mem_t3_1_rd_addr = copy_counter;
assign top_get_4_isog_mem_t4_0_rd_addr = copy_counter;
assign top_get_4_isog_mem_t4_1_rd_addr = copy_counter;
assign top_get_4_isog_mem_t5_0_rd_addr = copy_counter;
assign top_get_4_isog_mem_t5_1_rd_addr = copy_counter;

assign top_eval_4_isog_mem_t2_0_rd_en = EVAL_4_ISOG_RES_COPY_running;
assign top_eval_4_isog_mem_t2_1_rd_en = EVAL_4_ISOG_RES_COPY_running;
assign top_eval_4_isog_mem_t3_0_rd_en = EVAL_4_ISOG_RES_COPY_running;
assign top_eval_4_isog_mem_t3_1_rd_en = EVAL_4_ISOG_RES_COPY_running;
assign top_eval_4_isog_mem_t2_0_rd_addr = copy_counter;
assign top_eval_4_isog_mem_t2_1_rd_addr = copy_counter;
assign top_eval_4_isog_mem_t3_0_rd_addr = copy_counter;
assign top_eval_4_isog_mem_t3_1_rd_addr = copy_counter;


 
assign sk_mem_rd_addr = xADD_loop_busy ? (current_index >> SK_MEM_WIDTH_LOG) : {SINGLE_MEM_DEPTH_LOG{1'b0}};

assign controller_start = controller_start_reg | xADD_controller_start;

assign xDBLe_start = start & (command_encoded == XDBLE_COMMAND);
assign get_4_isog_and_eval_4_isog_start = start & (command_encoded == GET_4_ISOG_AND_EVAL_4_ISOG_COMMAND);
assign xADD_loop_start = start & (command_encoded == XADD_LOOP_COMMAND);

assign last_copy_write = (xDBL_RES_COPY_running | GET_4_ISOG_RES_COPY_running | EVAL_4_ISOG_RES_COPY_running | xADD_RES_COPY_running) & (copy_counter == (SINGLE_MEM_DEPTH-1));

assign xDBL_and_xADD_busy = xDBLe_busy | xADD_loop_busy;
assign busy = xDBLe_busy | get_4_isog_and_eval_4_isog_busy | xADD_loop_busy;
assign done = xDBLe_done | get_4_isog_and_eval_4_isog_done | xADD_loop_done;



always @(posedge clk or posedge rst) begin
  if (rst) begin
    copy_counter <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    top_mem_X_0_wr_en <= 1'b0;
    top_mem_X_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    top_mem_A24_0_wr_en <= 1'b0;
    top_mem_A24_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    top_mem_t10_0_wr_en <= 1'b0;
    top_mem_t10_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    top_mem_XADD_wr_en <= 1'b0;
    top_mem_XADD_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    last_copy_write_buf <= 1'b0;
    last_copy_write_buf_buf <= 1'b0;
    last_eval_4_isog_mem_X_0_rd_buf <= 1'b0;
    eval_4_isog_result_ready <= 1'b0;
  end 
  else begin
    copy_counter <= (start | last_copy_write | last_copy_write_buf) ? {SINGLE_MEM_DEPTH_LOG{1'b0}} :
                    (xDBL_RES_COPY_running | GET_4_ISOG_RES_COPY_running | EVAL_4_ISOG_RES_COPY_running | xADD_RES_COPY_running) ? copy_counter + 1 :
                    copy_counter;

    top_mem_X_0_wr_en <= (start | (top_mem_X_0_wr_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                          xDBL_RES_COPY_running ? 1'b1 :
                          top_mem_X_0_wr_en;
    top_mem_X_0_wr_addr <= xDBL_RES_COPY_running ? copy_counter : top_mem_X_0_wr_addr;

    top_mem_A24_0_wr_en <= (start | (top_mem_A24_0_wr_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                           GET_4_ISOG_RES_COPY_running ? 1'b1 :
                           top_mem_A24_0_wr_en;
    top_mem_A24_0_wr_addr <= GET_4_ISOG_RES_COPY_running ? copy_counter : top_mem_A24_0_wr_addr;

    top_mem_t10_0_wr_en <= (start | (top_mem_t10_0_wr_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                           EVAL_4_ISOG_RES_COPY_running ? 1'b1 :
                           top_mem_t10_0_wr_en;
    top_mem_t10_0_wr_addr <= EVAL_4_ISOG_RES_COPY_running ? copy_counter : top_mem_t10_0_wr_addr;

    top_mem_XADD_wr_en <= (start | (top_mem_XADD_wr_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                           xADD_RES_COPY_running ? 1'b1 :
                           top_mem_XADD_wr_en;
    top_mem_XADD_wr_addr <= xADD_RES_COPY_running ? copy_counter : top_mem_XADD_wr_addr;

    // 2-phase handshake signals
    eval_4_isog_XZ_can_overwrite <= (EVAL_4_ISOG_COMPUTATION_running & (eval_4_isog_mem_X4_0_rd_addr == (SINGLE_MEM_DEPTH-1)) & eval_4_isog_mem_X4_0_rd_en) | last_eval_4_isog_mem_X_0_rd_buf ? 1'b1 : // X has been used already
                                    eval_4_isog_XZ_newly_init ? 1'b0 :
                                    eval_4_isog_XZ_can_overwrite;
    eval_4_isog_result_ready <= (last_copy_write_buf & EVAL_4_ISOG_RES_COPY_running) | last_copy_write_buf_buf ? 1'b1 :
                                eval_4_isog_result_can_overwrite ? 1'b0 :
                                eval_4_isog_result_ready;
    last_copy_write_buf <= last_copy_write;
    last_copy_write_buf_buf <= last_copy_write_buf & EVAL_4_ISOG_RES_COPY_running;
    last_eval_4_isog_mem_X_0_rd_buf <= (EVAL_4_ISOG_COMPUTATION_running & (eval_4_isog_mem_X4_0_rd_addr == (SINGLE_MEM_DEPTH-1)) & eval_4_isog_mem_X4_0_rd_en);
    
  end
end



// finite state machine transitions
always @(posedge clk or posedge rst) begin
  if (rst) begin 
    xDBL_COMPUTATION_running <= 1'b0;
    xDBL_RES_COPY_running <= 1'b0;
    GET_4_ISOG_COMPUTATION_running <= 1'b0;
    GET_4_ISOG_RES_COPY_running <= 1'b0;
    EVAL_4_ISOG_COMPUTATION_running <= 1'b0;
    EVAL_4_ISOG_RES_COPY_running <= 1'b0;
    xADD_COMPUTATION_running <= 1'b0;
    xADD_RES_COPY_running <= 1'b0;       
    state <= IDLE;
    xDBLe_busy <= 1'b0;
    xDBLe_done <= 1'b0;
    get_4_isog_and_eval_4_isog_busy <= 1'b0;
    get_4_isog_and_eval_4_isog_done <= 1'b0;
    xADD_loop_busy <= 1'b0;
    xADD_loop_done <= 1'b0;
    xDBL_start_pre <= 1'b0;
    counter_for_loops <= 16'd0;
    eval_4_isog_start_pre <= 1'b0;
    xADD_start_pre <= 1'b0;
    controller_start_pre <= 1'b0;
    message_bit_at_current_index <= 1'b0;
    current_index <= 16'd0;
    controller_start_reg <= 1'b0;
    get_4_isog_busy <= 1'b0;
    eval_4_isog_res_copy_start_pre <= 1'b0;
  end
  else begin 
    xDBLe_done <= 1'b0;
    get_4_isog_and_eval_4_isog_done <= 1'b0;
    xADD_loop_done <= 1'b0; 
    xDBL_start_pre <= 1'b0;  
    controller_start_pre <= 1'b0; 
    controller_start_reg <= 1'b0;
    message_bit_at_current_index <= sk_mem_dout[current_index%SK_MEM_WIDTH]; // FIXME stay valid 

    // state transitions
    case (state) 
      IDLE: 
        if (xDBLe_start | xDBL_start_pre) begin 
          state <= xDBL_COMPUTATION;
          xDBL_COMPUTATION_running <= 1'b1;
          controller_start_reg <= 1'b1;
          function_encoded <= XDBL_FUNCTION;
          xDBLe_busy <= 1'b1;
        end
        else if (get_4_isog_and_eval_4_isog_start) begin
          state <= GET_4_ISOG_COMPUTATION;
          GET_4_ISOG_COMPUTATION_running <= 1'b1;
          controller_start_reg <= 1'b1;
          function_encoded <= GET_4_ISOG_FUNCTION;
          get_4_isog_and_eval_4_isog_busy <= 1'b1;
          get_4_isog_busy <= 1'b1;
        end
        else if (eval_4_isog_start_pre & eval_4_isog_XZ_newly_init) begin
          state <= EVAL_4_ISOG_COMPUTATION;
          EVAL_4_ISOG_COMPUTATION_running <= 1'b1;
          controller_start_reg <= 1'b1;
          function_encoded <= EVAL_4_ISOG_FUNCTION; 
          eval_4_isog_start_pre <= 1'b0;
        end
        else if (xADD_loop_start | (xADD_start_pre & xADD_P_newly_loaded)) begin
          state <= xADD_COMPUTATION;
          controller_start_pre <= 1'b1;
          xADD_COMPUTATION_running <= 1'b1;
          xADD_loop_busy <= 1'b1;
          current_index <= xADD_loop_start ? xADD_loop_start_index : current_index + 1;
          function_encoded <= XADD_FUNCTION;
          xADD_start_pre <= 1'b0;
        end 
        else if (eval_4_isog_res_copy_start_pre & eval_4_isog_result_can_overwrite) begin
          state <= EVAL_4_ISOG_RES_COPY;
          EVAL_4_ISOG_RES_COPY_running <= 1'b1;
          eval_4_isog_res_copy_start_pre <= 1'b0;
        end
        else begin
          state <= IDLE;
        end

      xDBL_COMPUTATION: 
        if (controller_done) begin
          state <= xDBL_RES_COPY;
          xDBL_COMPUTATION_running <= 1'b0;
          xDBL_RES_COPY_running <= 1'b1;
        end 
        else begin
          state <= xDBL_COMPUTATION;
        end
 
      xDBL_RES_COPY: 
        if (last_copy_write_buf & (counter_for_loops < (xDBLe_NUM_LOOPS-1))) begin
          state <= IDLE;
          xDBL_start_pre <= 1'b1;
          counter_for_loops <= counter_for_loops + 1;
          xDBL_RES_COPY_running <= 1'b0;
        end
        else if (last_copy_write_buf & (counter_for_loops == (xDBLe_NUM_LOOPS-1))) begin
          state <= IDLE;
          counter_for_loops <= 16'd0;
          xDBL_RES_COPY_running <= 1'b0; 
          xDBLe_busy <= 1'b0;
          xDBLe_done <= 1'b1;
          function_encoded <= 8'd0;
        end
        else begin
          state <= xDBL_RES_COPY;
        end

      GET_4_ISOG_COMPUTATION: 
        if (controller_done) begin
          state <= GET_4_ISOG_RES_COPY;
          GET_4_ISOG_COMPUTATION_running <= 1'b0;
          GET_4_ISOG_RES_COPY_running <= 1'b1;
        end
        else begin
          state <= GET_4_ISOG_COMPUTATION;
        end

      GET_4_ISOG_RES_COPY: 
        if (last_copy_write_buf) begin
          state <= IDLE;
          GET_4_ISOG_RES_COPY_running <= 1'b0; 
          eval_4_isog_start_pre <= 1'b1;
          get_4_isog_busy <= 1'b0; 
        end
        else begin
          state <= GET_4_ISOG_RES_COPY;
        end

      EVAL_4_ISOG_COMPUTATION: 
        if (controller_done) begin
          state <= IDLE;
          EVAL_4_ISOG_COMPUTATION_running <= 1'b0;
          eval_4_isog_res_copy_start_pre <= 1'b1;
        end
        else begin
          state <= EVAL_4_ISOG_COMPUTATION;
        end

      EVAL_4_ISOG_RES_COPY: 
        if (last_copy_write_buf & last_eval_4_isog) begin
          state <= IDLE;
          EVAL_4_ISOG_RES_COPY_running <= 1'b0; 
          function_encoded <= 8'd0;
          get_4_isog_and_eval_4_isog_busy <= 1'b0;
          get_4_isog_and_eval_4_isog_done <= 1'b1;
        end
        else if (last_copy_write_buf) begin
          state <= IDLE;
          EVAL_4_ISOG_RES_COPY_running <= 1'b0; 
          eval_4_isog_start_pre <= 1'b1; 
        end
        else begin
          state <= EVAL_4_ISOG_RES_COPY;
        end

      xADD_COMPUTATION: 
        if (controller_done) begin
          state <= xADD_RES_COPY;
          xADD_COMPUTATION_running <= 1'b0;
          xADD_RES_COPY_running <= 1'b1;
        end
        else begin
          state <= xADD_COMPUTATION;
        end

      xADD_RES_COPY: 
        if (last_copy_write_buf & (current_index == xADD_loop_end_index)) begin
          state <= IDLE;
          xADD_RES_COPY_running <= 1'b0;
          xADD_loop_busy <= 1'b0;
          xADD_loop_done <= 1'b1;
          function_encoded <= 8'd0;
        end
        else if (last_copy_write_buf) begin
          state <= IDLE;
          xADD_RES_COPY_running <= 1'b0;
          xADD_start_pre <= 1'b1; 
        end
        else begin
          state <= xADD_RES_COPY;
        end
 
      default: 
        begin
          state <= state;
        end
    endcase
  end 
end


// controller module for handling four isogeny functions, all focused on the 2-side:
// 1: xDBLe
// 2: xADD (revised, one final multiplication gets pushed in)
// 3: get_4_isog
// 4: eval_4_isog
controller #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL)) controller_inst (
  .rst(rst),
  .clk(clk),
  .function_encoded(function_encoded),
  .start(controller_start),
  .done(controller_done),
  .busy(controller_busy),
  .xADD_P_newly_loaded(xADD_P_newly_loaded),
  .xADD_P_can_overwrite(xADD_P_can_overwrite),
  // outside signals for mult A
  .out_mult_A_rst(out_mult_A_rst),
  .out_mult_A_start(out_mult_A_start),
  .mult_A_done(mult_A_done),
  .mult_A_busy(mult_A_busy),
  .mult_A_mem_a_0_rd_en(mult_A_mem_a_0_rd_en),
  .mult_A_mem_a_0_rd_addr(mult_A_mem_a_0_rd_addr),
  .out_mult_A_mem_a_0_dout(memory_t6_XQ_a_0_dout),
  .mult_A_mem_a_1_rd_en(mult_A_mem_a_1_rd_en),
  .mult_A_mem_a_1_rd_addr(mult_A_mem_a_1_rd_addr),
  .out_mult_A_mem_a_1_dout(memory_t6_XQ_a_1_dout),
  .mult_A_mem_b_0_rd_en(mult_A_mem_b_0_rd_en),
  .mult_A_mem_b_0_rd_addr(mult_A_mem_b_0_rd_addr),
  .out_mult_A_mem_b_0_dout(memory_t7_ZQ_b_0_dout),
  .mult_A_mem_b_1_rd_en(mult_A_mem_b_1_rd_en),
  .mult_A_mem_b_1_rd_addr(mult_A_mem_b_1_rd_addr),
  .out_mult_A_mem_b_1_dout(memory_t7_ZQ_b_1_dout),
  .out_sub_mult_A_mem_res_rd_en(out_sub_mult_A_mem_res_rd_en),
  .out_sub_mult_A_mem_res_rd_addr(out_sub_mult_A_mem_res_rd_addr),
  .mult_A_sub_mult_mem_res_dout(sub_mult_A_mem_res_dout),
  .out_add_mult_A_mem_res_rd_en(out_add_mult_A_mem_res_rd_en),
  .out_add_mult_A_mem_res_rd_addr(out_add_mult_A_mem_res_rd_addr),
  .mult_A_add_mult_mem_res_dout(add_mult_A_mem_res_dout),
  // xDBL signals
  .xDBL_mem_X_0_dout(mem_X_0_dout),
  .xDBL_mem_X_0_rd_en(xDBL_mem_X_0_rd_en),
  .xDBL_mem_X_0_rd_addr(xDBL_mem_X_0_rd_addr),
  .xDBL_mem_X_1_dout(mem_X_1_dout),
  .xDBL_mem_X_1_rd_en(xDBL_mem_X_1_rd_en),
  .xDBL_mem_X_1_rd_addr(xDBL_mem_X_1_rd_addr),
  .xDBL_mem_Z_0_dout(mem_Z_0_dout),
  .xDBL_mem_Z_0_rd_en(xDBL_mem_Z_0_rd_en),
  .xDBL_mem_Z_0_rd_addr(xDBL_mem_Z_0_rd_addr),
  .xDBL_mem_Z_1_dout(mem_Z_1_dout),
  .xDBL_mem_Z_1_rd_en(xDBL_mem_Z_1_rd_en),
  .xDBL_mem_Z_1_rd_addr(xDBL_mem_Z_1_rd_addr),
  .xDBL_mem_A24_0_dout(mem_A24_0_dout),
  .xDBL_mem_A24_0_rd_en(xDBL_mem_A24_0_rd_en),
  .xDBL_mem_A24_0_rd_addr(xDBL_mem_A24_0_rd_addr), 
  .xDBL_mem_A24_1_dout(mem_A24_1_dout),
  .xDBL_mem_A24_1_rd_en(xDBL_mem_A24_1_rd_en),
  .xDBL_mem_A24_1_rd_addr(xDBL_mem_A24_1_rd_addr),
  .xDBL_mem_C24_0_dout(mem_C24_0_dout),
  .xDBL_mem_C24_0_rd_en(xDBL_mem_C24_0_rd_en),
  .xDBL_mem_C24_0_rd_addr(xDBL_mem_C24_0_rd_addr),
  .xDBL_mem_C24_1_dout(mem_C24_1_dout),
  .xDBL_mem_C24_1_rd_en(xDBL_mem_C24_1_rd_en),
  .xDBL_mem_C24_1_rd_addr(xDBL_mem_C24_1_rd_addr),
  // xADD signals
  .xADD_mem_XP_0_dout(mem_XP_0_dout),
  .xADD_mem_XP_0_rd_en(xADD_mem_XP_0_rd_en),
  .xADD_mem_XP_0_rd_addr(xADD_mem_XP_0_rd_addr),
  .xADD_mem_XP_1_dout(mem_XP_1_dout),
  .xADD_mem_XP_1_rd_en(xADD_mem_XP_1_rd_en),
  .xADD_mem_XP_1_rd_addr(xADD_mem_XP_1_rd_addr),
  .xADD_mem_ZP_0_dout(mem_ZP_0_dout),
  .xADD_mem_ZP_0_rd_en(xADD_mem_ZP_0_rd_en),
  .xADD_mem_ZP_0_rd_addr(xADD_mem_ZP_0_rd_addr),
  .xADD_mem_ZP_1_dout(mem_ZP_1_dout),
  .xADD_mem_ZP_1_rd_en(xADD_mem_ZP_1_rd_en),
  .xADD_mem_ZP_1_rd_addr(xADD_mem_ZP_1_rd_addr),
  .xADD_mem_XQ_0_dout(xADD_mem_XQ_0_dout), // mux
  .xADD_mem_XQ_0_rd_en(xADD_mem_XQ_0_rd_en),
  .xADD_mem_XQ_0_rd_addr(xADD_mem_XQ_0_rd_addr),
  .xADD_mem_XQ_1_dout(xADD_mem_XQ_1_dout), // mux
  .xADD_mem_XQ_1_rd_en(xADD_mem_XQ_1_rd_en),
  .xADD_mem_XQ_1_rd_addr(xADD_mem_XQ_1_rd_addr),
  .xADD_mem_ZQ_0_dout(xADD_mem_ZQ_0_dout), // mux
  .xADD_mem_ZQ_0_rd_en(xADD_mem_ZQ_0_rd_en),
  .xADD_mem_ZQ_0_rd_addr(xADD_mem_ZQ_0_rd_addr),
  .xADD_mem_ZQ_1_dout(xADD_mem_ZQ_1_dout), // mux
  .xADD_mem_ZQ_1_rd_en(xADD_mem_ZQ_1_rd_en),
  .xADD_mem_ZQ_1_rd_addr(xADD_mem_ZQ_1_rd_addr),
  .xADD_mem_xPQ_0_dout(xADD_mem_xPQ_0_dout), // mux
  .xADD_mem_xPQ_0_rd_en(xADD_mem_xPQ_0_rd_en),
  .xADD_mem_xPQ_0_rd_addr(xADD_mem_xPQ_0_rd_addr),
  .xADD_mem_xPQ_1_dout(xADD_mem_xPQ_1_dout), // mux
  .xADD_mem_xPQ_1_rd_en(xADD_mem_xPQ_1_rd_en),
  .xADD_mem_xPQ_1_rd_addr(xADD_mem_xPQ_1_rd_addr),
  .xADD_mem_zPQ_0_dout(xADD_mem_zPQ_0_dout), // mux
  .xADD_mem_zPQ_0_rd_en(xADD_mem_zPQ_0_rd_en),
  .xADD_mem_zPQ_0_rd_addr(xADD_mem_zPQ_0_rd_addr),
  .xADD_mem_zPQ_1_dout(xADD_mem_zPQ_1_dout), // mux
  .xADD_mem_zPQ_1_rd_en(xADD_mem_zPQ_1_rd_en),
  .xADD_mem_zPQ_1_rd_addr(xADD_mem_zPQ_1_rd_addr), 
  // get_4_isog signals
  .get_4_isog_mem_X4_0_dout(mem_X4_0_dout),
  .get_4_isog_mem_X4_0_rd_en(get_4_isog_mem_X4_0_rd_en),
  .get_4_isog_mem_X4_0_rd_addr(get_4_isog_mem_X4_0_rd_addr),
  .get_4_isog_mem_X4_1_dout(mem_X4_1_dout),
  .get_4_isog_mem_X4_1_rd_en(get_4_isog_mem_X4_1_rd_en),
  .get_4_isog_mem_X4_1_rd_addr(get_4_isog_mem_X4_1_rd_addr),
  .get_4_isog_mem_Z4_0_dout(mem_Z4_0_dout),
  .get_4_isog_mem_Z4_0_rd_en(get_4_isog_mem_Z4_0_rd_en),
  .get_4_isog_mem_Z4_0_rd_addr(get_4_isog_mem_Z4_0_rd_addr),
  .get_4_isog_mem_Z4_1_dout(mem_Z4_1_dout),
  .get_4_isog_mem_Z4_1_rd_en(get_4_isog_mem_Z4_1_rd_en),
  .get_4_isog_mem_Z4_1_rd_addr(get_4_isog_mem_Z4_1_rd_addr), 
  // eval_4_isog signals
  .eval_4_isog_mem_X_0_dout(mem_X4_0_dout),
  .eval_4_isog_mem_X_0_rd_en(eval_4_isog_mem_X4_0_rd_en),
  .eval_4_isog_mem_X_0_rd_addr(eval_4_isog_mem_X4_0_rd_addr),
  .eval_4_isog_mem_X_1_dout(mem_X4_1_dout),
  .eval_4_isog_mem_X_1_rd_en(eval_4_isog_mem_X4_1_rd_en),
  .eval_4_isog_mem_X_1_rd_addr(eval_4_isog_mem_X4_1_rd_addr),
  .eval_4_isog_mem_Z_0_dout(mem_Z4_0_dout),
  .eval_4_isog_mem_Z_0_rd_en(eval_4_isog_mem_Z4_0_rd_en),
  .eval_4_isog_mem_Z_0_rd_addr(eval_4_isog_mem_Z4_0_rd_addr),
  .eval_4_isog_mem_Z_1_dout(mem_Z4_1_dout),
  .eval_4_isog_mem_Z_1_rd_en(eval_4_isog_mem_Z4_1_rd_en),
  .eval_4_isog_mem_Z_1_rd_addr(eval_4_isog_mem_Z4_1_rd_addr),
  .eval_4_isog_mem_C0_0_dout(mem_t7_0_dout),
  .eval_4_isog_mem_C0_0_rd_en(eval_4_isog_mem_C0_0_rd_en),
  .eval_4_isog_mem_C0_0_rd_addr(eval_4_isog_mem_C0_0_rd_addr),
  .eval_4_isog_mem_C0_1_dout(mem_t7_1_dout),
  .eval_4_isog_mem_C0_1_rd_en(eval_4_isog_mem_C0_1_rd_en),
  .eval_4_isog_mem_C0_1_rd_addr(eval_4_isog_mem_C0_1_rd_addr),
  .eval_4_isog_mem_C1_0_dout(mem_t8_0_dout),
  .eval_4_isog_mem_C1_0_rd_en(eval_4_isog_mem_C1_0_rd_en),
  .eval_4_isog_mem_C1_0_rd_addr(eval_4_isog_mem_C1_0_rd_addr),
  .eval_4_isog_mem_C1_1_dout(mem_t8_1_dout),
  .eval_4_isog_mem_C1_1_rd_en(eval_4_isog_mem_C1_1_rd_en),
  .eval_4_isog_mem_C1_1_rd_addr(eval_4_isog_mem_C1_1_rd_addr),
  .eval_4_isog_mem_C2_0_dout(mem_t9_0_dout),
  .eval_4_isog_mem_C2_0_rd_en(eval_4_isog_mem_C2_0_rd_en),
  .eval_4_isog_mem_C2_0_rd_addr(eval_4_isog_mem_C2_0_rd_addr), 
  .eval_4_isog_mem_C2_1_dout(mem_t9_1_dout),
  .eval_4_isog_mem_C2_1_rd_en(eval_4_isog_mem_C2_1_rd_en),
  .eval_4_isog_mem_C2_1_rd_addr(eval_4_isog_mem_C2_1_rd_addr),
  // t0
  .mem_t0_0_rd_en(1'b0),
  .mem_t0_0_rd_addr({SINGLE_MEM_DEPTH_LOG{1'b0}}),
  .mem_t0_0_dout(mem_t0_0_dout),
  .mem_t0_1_rd_en(1'b0),
  .mem_t0_1_rd_addr({SINGLE_MEM_DEPTH_LOG{1'b0}}),
  .mem_t0_1_dout(mem_t0_1_dout),
  // t1
  .mem_t1_0_rd_en(top_mem_t1_0_rd_en),
  .mem_t1_0_rd_addr(top_mem_t1_0_rd_addr),
  .mem_t1_0_dout(mem_t1_0_dout),
  .mem_t1_1_rd_en(top_mem_t1_1_rd_en),
  .mem_t1_1_rd_addr(top_mem_t1_1_rd_addr),
  .mem_t1_1_dout(mem_t1_1_dout),
  // t2
  .mem_t2_0_rd_en(top_mem_t2_0_rd_en),
  .mem_t2_0_rd_addr(top_mem_t2_0_rd_addr),
  .mem_t2_0_dout(mem_t2_0_dout),
  .mem_t2_1_rd_en(top_mem_t2_1_rd_en),
  .mem_t2_1_rd_addr(top_mem_t2_1_rd_addr),
  .mem_t2_1_dout(mem_t2_1_dout),
  // t3
  .mem_t3_0_rd_en(top_mem_t3_0_rd_en),
  .mem_t3_0_rd_addr(top_mem_t3_0_rd_addr),
  .mem_t3_0_dout(mem_t3_0_dout),
  .mem_t3_1_rd_en(top_mem_t3_1_rd_en),
  .mem_t3_1_rd_addr(top_mem_t3_1_rd_addr),
  .mem_t3_1_dout(mem_t3_1_dout),
  // t4
  .mem_t4_0_wr_en(mem_t4_0_wr_en),
  .mem_t4_0_wr_addr(mem_t4_0_wr_addr),
  .mem_t4_0_din(mem_t4_0_din),
  .mem_t4_0_rd_en(mem_t4_0_rd_en),
  .mem_t4_0_rd_addr(mem_t4_0_rd_addr),
  .mem_t4_0_dout(mem_t4_0_dout),
  .mem_t4_1_wr_en(mem_t4_1_wr_en),
  .mem_t4_1_wr_addr(mem_t4_1_wr_addr),
  .mem_t4_1_din(mem_t4_1_din),
  .mem_t4_1_rd_en(mem_t4_1_rd_en),
  .mem_t4_1_rd_addr(mem_t4_1_rd_addr),
  .mem_t4_1_dout(mem_t4_1_dout),
  // t5
  .mem_t5_0_wr_en(mem_t5_0_wr_en),
  .mem_t5_0_wr_addr(mem_t5_0_wr_addr),
  .mem_t5_0_din(mem_t5_0_din),
  .mem_t5_0_rd_en(mem_t5_0_rd_en),
  .mem_t5_0_rd_addr(mem_t5_0_rd_addr),
  .mem_t5_0_dout(mem_t5_0_dout),
  .mem_t5_1_wr_en(mem_t5_1_wr_en),
  .mem_t5_1_wr_addr(mem_t5_1_wr_addr),
  .mem_t5_1_din(mem_t5_1_din),
  .mem_t5_1_rd_en(mem_t5_1_rd_en),
  .mem_t5_1_rd_addr(mem_t5_1_rd_addr),
  .mem_t5_1_dout(mem_t5_1_dout),
  // t6
  .mem_t6_0_wr_en(mem_t6_0_wr_en),
  .mem_t6_0_wr_addr(mem_t6_0_wr_addr),
  .mem_t6_0_din(mem_t6_0_din),
  .mem_t6_0_rd_en(mem_t6_0_rd_en),
  .mem_t6_0_rd_addr(mem_t6_0_rd_addr),
  .mem_t6_0_dout(mem_t6_0_dout),
  .mem_t6_1_wr_en(mem_t6_1_wr_en),
  .mem_t6_1_wr_addr(mem_t6_1_wr_addr),
  .mem_t6_1_din(mem_t6_1_din),
  .mem_t6_1_rd_en(mem_t6_1_rd_en),
  .mem_t6_1_rd_addr(mem_t6_1_rd_addr),
  .mem_t6_1_dout(mem_t6_1_dout),
  // t7
  .mem_t7_0_wr_en(mem_t7_0_wr_en),
  .mem_t7_0_wr_addr(mem_t7_0_wr_addr),
  .mem_t7_0_din(mem_t7_0_din),
  .mem_t7_0_rd_en(mem_t7_0_rd_en),
  .mem_t7_0_rd_addr(mem_t7_0_rd_addr),
  .mem_t7_0_dout(mem_t7_0_dout),
  .mem_t7_1_wr_en(mem_t7_1_wr_en),
  .mem_t7_1_wr_addr(mem_t7_1_wr_addr),
  .mem_t7_1_din(mem_t7_1_din),
  .mem_t7_1_rd_en(mem_t7_1_rd_en),
  .mem_t7_1_rd_addr(mem_t7_1_rd_addr),
  .mem_t7_1_dout(mem_t7_1_dout),  
  // t8
  .mem_t8_0_wr_en(mem_t8_0_wr_en),
  .mem_t8_0_wr_addr(mem_t8_0_wr_addr),
  .mem_t8_0_din(mem_t8_0_din),
  .mem_t8_0_rd_en(mem_t8_0_rd_en),
  .mem_t8_0_rd_addr(mem_t8_0_rd_addr),
  .mem_t8_0_dout(mem_t8_0_dout),
  .mem_t8_1_wr_en(mem_t8_1_wr_en),
  .mem_t8_1_wr_addr(mem_t8_1_wr_addr),
  .mem_t8_1_din(mem_t8_1_din),
  .mem_t8_1_rd_en(mem_t8_1_rd_en),
  .mem_t8_1_rd_addr(mem_t8_1_rd_addr),
  .mem_t8_1_dout(mem_t8_1_dout),
  // t9
  .mem_t9_0_wr_en(mem_t9_0_wr_en),
  .mem_t9_0_wr_addr(mem_t9_0_wr_addr),
  .mem_t9_0_din(mem_t9_0_din),
  .mem_t9_0_rd_en(mem_t9_0_rd_en),
  .mem_t9_0_rd_addr(mem_t9_0_rd_addr),
  .mem_t9_0_dout(mem_t9_0_dout),
  .mem_t9_1_wr_en(mem_t9_1_wr_en),
  .mem_t9_1_wr_addr(mem_t9_1_wr_addr),
  .mem_t9_1_din(mem_t9_1_din),
  .mem_t9_1_rd_en(mem_t9_1_rd_en),
  .mem_t9_1_rd_addr(mem_t9_1_rd_addr),
  .mem_t9_1_dout(mem_t9_1_dout),
  // t10
  .mem_t10_0_wr_en(mem_t10_0_wr_en),
  .mem_t10_0_wr_addr(mem_t10_0_wr_addr),
  .mem_t10_0_din(mem_t10_0_din),
  .mem_t10_0_rd_en(mem_t10_0_rd_en),
  .mem_t10_0_rd_addr(mem_t10_0_rd_addr),
  .mem_t10_0_dout(mem_t10_0_dout),
  .mem_t10_1_wr_en(mem_t10_1_wr_en),
  .mem_t10_1_wr_addr(mem_t10_1_wr_addr),
  .mem_t10_1_din(mem_t10_1_din),
  .mem_t10_1_rd_en(mem_t10_1_rd_en),
  .mem_t10_1_rd_addr(mem_t10_1_rd_addr),
  .mem_t10_1_dout(mem_t10_1_dout),
  // rd t4
  .out_mem_t4_0_rd_en(top_mem_t4_0_rd_en),
  .out_mem_t4_0_rd_addr(top_mem_t4_0_rd_addr), 
  .out_mem_t4_1_rd_en(top_mem_t4_1_rd_en),
  .out_mem_t4_1_rd_addr(top_mem_t4_1_rd_addr), 
  // t5
  .out_mem_t5_0_rd_en(top_mem_t5_0_rd_en),
  .out_mem_t5_0_rd_addr(top_mem_t5_0_rd_addr), 
  .out_mem_t5_1_rd_en(top_mem_t5_1_rd_en),
  .out_mem_t5_1_rd_addr(top_mem_t5_1_rd_addr), 
  // t6
  .out_mem_t6_0_rd_en(1'b0),
  .out_mem_t6_0_rd_addr({SINGLE_MEM_DEPTH_LOG{1'b0}}), 
  .out_mem_t6_1_rd_en(1'b0),
  .out_mem_t6_1_rd_addr({SINGLE_MEM_DEPTH_LOG{1'b0}}), 
  // t7
  .out_mem_t7_0_wr_en(top_mem_t7_0_wr_en),
  .out_mem_t7_0_wr_addr(top_mem_t7_0_wr_addr),
  .out_mem_t7_0_din(top_mem_t7_0_din),
  .out_mem_t7_0_rd_en(top_mem_t7_0_rd_en),
  .out_mem_t7_0_rd_addr(top_mem_t7_0_rd_addr), 
  .out_mem_t7_1_wr_en(top_mem_t7_1_wr_en),
  .out_mem_t7_1_wr_addr(top_mem_t7_1_wr_addr),
  .out_mem_t7_1_din(top_mem_t7_1_din),
  .out_mem_t7_1_rd_en(top_mem_t7_1_rd_en),
  .out_mem_t7_1_rd_addr(top_mem_t7_1_rd_addr), 
  // t8
  .out_mem_t8_0_wr_en(top_mem_t8_0_wr_en),
  .out_mem_t8_0_wr_addr(top_mem_t8_0_wr_addr),
  .out_mem_t8_0_din(top_mem_t8_0_din),
  .out_mem_t8_0_rd_en(top_mem_t8_0_rd_en),
  .out_mem_t8_0_rd_addr(top_mem_t8_0_rd_addr), 
  .out_mem_t8_1_wr_en(top_mem_t8_1_wr_en),
  .out_mem_t8_1_wr_addr(top_mem_t8_1_wr_addr),
  .out_mem_t8_1_din(top_mem_t8_1_din),
  .out_mem_t8_1_rd_en(top_mem_t8_1_rd_en),
  .out_mem_t8_1_rd_addr(top_mem_t8_1_rd_addr), 
  // t9
  .out_mem_t9_0_wr_en(top_mem_t9_0_wr_en),
  .out_mem_t9_0_wr_addr(top_mem_t9_0_wr_addr),
  .out_mem_t9_0_din(top_mem_t9_0_din),
  .out_mem_t9_0_rd_en(top_mem_t9_0_rd_en),
  .out_mem_t9_0_rd_addr(top_mem_t9_0_rd_addr), 
  .out_mem_t9_1_wr_en(top_mem_t9_1_wr_en),
  .out_mem_t9_1_wr_addr(top_mem_t9_1_wr_addr),
  .out_mem_t9_1_din(top_mem_t9_1_din),
  .out_mem_t9_1_rd_en(top_mem_t9_1_rd_en),
  .out_mem_t9_1_rd_addr(top_mem_t9_1_rd_addr), 
  // t10
  .out_mem_t10_0_wr_en(top_mem_t10_0_wr_en),
  .out_mem_t10_0_wr_addr(top_mem_t10_0_wr_addr),
  .out_mem_t10_0_din(top_mem_t10_0_din),
  .out_mem_t10_0_rd_en(top_mem_t10_0_rd_en),
  .out_mem_t10_0_rd_addr(top_mem_t10_0_rd_addr), 
  .out_mem_t10_1_wr_en(top_mem_t10_1_wr_en),
  .out_mem_t10_1_wr_addr(top_mem_t10_1_wr_addr),
  .out_mem_t10_1_din(top_mem_t10_1_din),
  .out_mem_t10_1_rd_en(top_mem_t10_1_rd_en),
  .out_mem_t10_1_rd_addr(top_mem_t10_1_rd_addr) 
  ); 
 
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t4_0 (  
  .clock(clk),
  .data(mem_t4_0_din),
  .address(mem_t4_0_wr_en ? mem_t4_0_wr_addr : mem_t4_0_rd_addr),
  .wr_en(mem_t4_0_wr_en),
  .q(mem_t4_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t4_1 (  
  .clock(clk),
  .data(mem_t4_1_din),
  .address(mem_t4_1_wr_en ? mem_t4_1_wr_addr : mem_t4_1_rd_addr),
  .wr_en(mem_t4_1_wr_en),
  .q(mem_t4_1_dout)
  ); 

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t5_0 (  
  .clock(clk),
  .data(mem_t5_0_din),
  .address(mem_t5_0_wr_en ? mem_t5_0_wr_addr : mem_t5_0_rd_addr),
  .wr_en(mem_t5_0_wr_en),
  .q(mem_t5_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t5_1 (  
  .clock(clk),
  .data(mem_t5_1_din),
  .address(mem_t5_1_wr_en ? mem_t5_1_wr_addr : mem_t5_1_rd_addr),
  .wr_en(mem_t5_1_wr_en),
  .q(mem_t5_1_dout)
  );
 

// t10
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t10_0 (  
  .clock(clk),
  .data(mem_t10_0_din),
  .address(mem_t10_0_wr_en ? mem_t10_0_wr_addr : mem_t10_0_rd_addr),
  .wr_en(mem_t10_0_wr_en),
  .q(mem_t10_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t10_1 (  
  .clock(clk),
  .data(mem_t10_1_din),
  .address(mem_t10_1_wr_en ? mem_t10_1_wr_addr : mem_t10_1_rd_addr),
  .wr_en(mem_t10_1_wr_en),
  .q(mem_t10_1_dout)
  );
 
// t11
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t11_0 (  
  .clock(clk),
  .data(top_mem_t11_0_din),
  .address(top_mem_t11_0_wr_en ? top_mem_t11_0_wr_addr : (out_mem_t11_0_rd_en ? out_mem_t11_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}})),
  .wr_en(top_mem_t11_0_wr_en),
  .q(mem_t11_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t11_1 (  
  .clock(clk),
  .data(top_mem_t11_1_din),
  .address(top_mem_t11_1_wr_en ? top_mem_t11_1_wr_addr : (out_mem_t11_1_rd_en ? out_mem_t11_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}})),
  .wr_en(top_mem_t11_1_wr_en),
  .q(mem_t11_1_dout)
  );

// secret key memory, pre-loaded
single_port_mem #(.FILE(FILE_SK), .WIDTH(SK_MEM_WIDTH), .DEPTH(SK_MEM_DEPTH)) single_port_mem_inst_sk (  
  .clock(clk),
  .data(out_sk_mem_din),
  .address(out_sk_mem_wr_en ? out_sk_mem_wr_addr : sk_mem_rd_addr),
  .wr_en(out_sk_mem_wr_en),
  .q(sk_mem_dout)
  );

delay #(.WIDTH(1), .DELAY(2)) delay_inst (
  .clk(clk),
  .rst(rst),
  .din(controller_start_pre),
  .dout(xADD_controller_start)
  );

memory_4_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_4_to_1_wrapper_A24_X4_X_XP_inst_0 (
  .clk(clk),
  .mem_0_wr_en(mem_A24_0_wr_en),
  .mem_0_wr_addr(mem_A24_0_wr_addr),
  .mem_0_din(mem_A24_0_din),
  .mem_0_rd_en(mem_A24_0_rd_en),
  .mem_0_rd_addr(mem_A24_0_rd_addr),
  .mem_1_wr_en(mem_X4_0_wr_en),
  .mem_1_wr_addr(mem_X4_0_wr_addr),
  .mem_1_din(mem_X4_0_din),
  .mem_1_rd_en(mem_X4_0_rd_en),
  .mem_1_rd_addr(mem_X4_0_rd_addr),  
  .mem_2_wr_en(mem_X_0_wr_en),
  .mem_2_wr_addr(mem_X_0_wr_addr),
  .mem_2_din(mem_X_0_din),
  .mem_2_rd_en(mem_X_0_rd_en),
  .mem_2_rd_addr(mem_X_0_rd_addr),
  .mem_3_wr_en(mem_XP_0_wr_en),
  .mem_3_wr_addr(mem_XP_0_wr_addr),
  .mem_3_din(mem_XP_0_din),
  .mem_3_rd_en(mem_XP_0_rd_en),
  .mem_3_rd_addr(mem_XP_0_rd_addr),
  .mem_dout(memory_A24_X4_X_XP_0_dout)
  );
 
 memory_4_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_4_to_1_wrapper_A24_X4_X_XP_inst_1 (
  .clk(clk),
  .mem_0_wr_en(mem_A24_1_wr_en),
  .mem_0_wr_addr(mem_A24_1_wr_addr),
  .mem_0_din(mem_A24_1_din),
  .mem_0_rd_en(mem_A24_1_rd_en),
  .mem_0_rd_addr(mem_A24_1_rd_addr),
  .mem_1_wr_en(mem_X4_1_wr_en),
  .mem_1_wr_addr(mem_X4_1_wr_addr),
  .mem_1_din(mem_X4_1_din),
  .mem_1_rd_en(mem_X4_1_rd_en),
  .mem_1_rd_addr(mem_X4_1_rd_addr),  
  .mem_2_wr_en(mem_X_1_wr_en),
  .mem_2_wr_addr(mem_X_1_wr_addr),
  .mem_2_din(mem_X_1_din),
  .mem_2_rd_en(mem_X_1_rd_en),
  .mem_2_rd_addr(mem_X_1_rd_addr),
  .mem_3_wr_en(mem_XP_1_wr_en),
  .mem_3_wr_addr(mem_XP_1_wr_addr),
  .mem_3_din(mem_XP_1_din),
  .mem_3_rd_en(mem_XP_1_rd_en),
  .mem_3_rd_addr(mem_XP_1_rd_addr),
  .mem_dout(memory_A24_X4_X_XP_1_dout)
  );

 memory_4_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_4_to_1_wrapper_C24_Z4_Z_ZP_inst_0 (
  .clk(clk),
  .mem_0_wr_en(mem_C24_0_wr_en),
  .mem_0_wr_addr(mem_C24_0_wr_addr),
  .mem_0_din(mem_C24_0_din),
  .mem_0_rd_en(mem_C24_0_rd_en),
  .mem_0_rd_addr(mem_C24_0_rd_addr),
  .mem_1_wr_en(mem_Z4_0_wr_en),
  .mem_1_wr_addr(mem_Z4_0_wr_addr),
  .mem_1_din(mem_Z4_0_din),
  .mem_1_rd_en(mem_Z4_0_rd_en),
  .mem_1_rd_addr(mem_Z4_0_rd_addr),  
  .mem_2_wr_en(mem_Z_0_wr_en),
  .mem_2_wr_addr(mem_Z_0_wr_addr),
  .mem_2_din(mem_Z_0_din),
  .mem_2_rd_en(mem_Z_0_rd_en),
  .mem_2_rd_addr(mem_Z_0_rd_addr),
  .mem_3_wr_en(mem_ZP_0_wr_en),
  .mem_3_wr_addr(mem_ZP_0_wr_addr),
  .mem_3_din(mem_ZP_0_din),
  .mem_3_rd_en(mem_ZP_0_rd_en),
  .mem_3_rd_addr(mem_ZP_0_rd_addr),
  .mem_dout(memory_C24_Z4_Z_ZP_0_dout)
  );
 
 memory_4_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_4_to_1_wrapper_C24_Z4_Z_ZP_inst_1 (
  .clk(clk),
  .mem_0_wr_en(mem_C24_1_wr_en),
  .mem_0_wr_addr(mem_C24_1_wr_addr),
  .mem_0_din(mem_C24_1_din),
  .mem_0_rd_en(mem_C24_1_rd_en),
  .mem_0_rd_addr(mem_C24_1_rd_addr),
  .mem_1_wr_en(mem_Z4_1_wr_en),
  .mem_1_wr_addr(mem_Z4_1_wr_addr),
  .mem_1_din(mem_Z4_1_din),
  .mem_1_rd_en(mem_Z4_1_rd_en),
  .mem_1_rd_addr(mem_Z4_1_rd_addr),  
  .mem_2_wr_en(mem_Z_1_wr_en),
  .mem_2_wr_addr(mem_Z_1_wr_addr),
  .mem_2_din(mem_Z_1_din),
  .mem_2_rd_en(mem_Z_1_rd_en),
  .mem_2_rd_addr(mem_Z_1_rd_addr),
  .mem_3_wr_en(mem_ZP_1_wr_en),
  .mem_3_wr_addr(mem_ZP_1_wr_addr),
  .mem_3_din(mem_ZP_1_din),
  .mem_3_rd_en(mem_ZP_1_rd_en),
  .mem_3_rd_addr(mem_ZP_1_rd_addr),
  .mem_dout(memory_C24_Z4_Z_ZP_1_dout)
  );

memory_3_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_3_to_1_wrapper_t6_XQ_a_inst_0 (
  .clk(clk),
  .mem_0_wr_en(mem_t6_0_wr_en),
  .mem_0_wr_addr(mem_t6_0_wr_addr),
  .mem_0_din(mem_t6_0_din),
  .mem_0_rd_en(mem_t6_0_rd_en),
  .mem_0_rd_addr(mem_t6_0_rd_addr),
  .mem_1_wr_en(mem_XQ_0_wr_en),
  .mem_1_wr_addr(mem_XQ_0_wr_addr),
  .mem_1_din(mem_XQ_0_din),
  .mem_1_rd_en(mem_XQ_0_rd_en),
  .mem_1_rd_addr(mem_XQ_0_rd_addr),
  .mem_2_wr_en(out_mult_A_mem_a_0_wr_en),
  .mem_2_wr_addr(out_mult_A_mem_a_0_wr_addr),
  .mem_2_din(out_mult_A_mem_a_0_din),
  .mem_2_rd_en(mult_A_mem_a_0_rd_en),
  .mem_2_rd_addr(mult_A_mem_a_0_rd_addr), 
  .mem_dout(memory_t6_XQ_a_0_dout)
  );

memory_3_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_3_to_1_wrapper_t6_XQ_inst_1 (
  .clk(clk),
  .mem_0_wr_en(mem_t6_1_wr_en),
  .mem_0_wr_addr(mem_t6_1_wr_addr),
  .mem_0_din(mem_t6_1_din),
  .mem_0_rd_en(mem_t6_1_rd_en),
  .mem_0_rd_addr(mem_t6_1_rd_addr),
  .mem_1_wr_en(mem_XQ_1_wr_en),
  .mem_1_wr_addr(mem_XQ_1_wr_addr),
  .mem_1_din(mem_XQ_1_din),
  .mem_1_rd_en(mem_XQ_1_rd_en),
  .mem_1_rd_addr(mem_XQ_1_rd_addr), 
  .mem_2_wr_en(out_mult_A_mem_a_1_wr_en),
  .mem_2_wr_addr(out_mult_A_mem_a_1_wr_addr),
  .mem_2_din(out_mult_A_mem_a_1_din),
  .mem_2_rd_en(mult_A_mem_a_1_rd_en),
  .mem_2_rd_addr(mult_A_mem_a_1_rd_addr), 
  .mem_dout(memory_t6_XQ_a_1_dout)
  );

memory_3_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_3_to_1_wrapper_t7_ZQ_b_inst_0 (
  .clk(clk),
  .mem_0_wr_en(mem_t7_0_wr_en),
  .mem_0_wr_addr(mem_t7_0_wr_addr),
  .mem_0_din(mem_t7_0_din),
  .mem_0_rd_en(mem_t7_0_rd_en),
  .mem_0_rd_addr(mem_t7_0_rd_addr),
  .mem_1_wr_en(mem_ZQ_0_wr_en),
  .mem_1_wr_addr(mem_ZQ_0_wr_addr),
  .mem_1_din(mem_ZQ_0_din),
  .mem_1_rd_en(mem_ZQ_0_rd_en),
  .mem_1_rd_addr(mem_ZQ_0_rd_addr), 
  .mem_2_wr_en(out_mult_A_mem_b_0_wr_en),
  .mem_2_wr_addr(out_mult_A_mem_b_0_wr_addr),
  .mem_2_din(out_mult_A_mem_b_0_din),
  .mem_2_rd_en(mult_A_mem_b_0_rd_en),
  .mem_2_rd_addr(mult_A_mem_b_0_rd_addr), 
  .mem_dout(memory_t7_ZQ_b_0_dout)
  );

memory_3_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_3_to_1_wrapper_t7_ZQ_inst_1 (
  .clk(clk),
  .mem_0_wr_en(mem_t7_1_wr_en),
  .mem_0_wr_addr(mem_t7_1_wr_addr),
  .mem_0_din(mem_t7_1_din),
  .mem_0_rd_en(mem_t7_1_rd_en),
  .mem_0_rd_addr(mem_t7_1_rd_addr),
  .mem_1_wr_en(mem_ZQ_1_wr_en),
  .mem_1_wr_addr(mem_ZQ_1_wr_addr),
  .mem_1_din(mem_ZQ_1_din),
  .mem_1_rd_en(mem_ZQ_1_rd_en),
  .mem_1_rd_addr(mem_ZQ_1_rd_addr), 
  .mem_2_wr_en(out_mult_A_mem_b_1_wr_en),
  .mem_2_wr_addr(out_mult_A_mem_b_1_wr_addr),
  .mem_2_din(out_mult_A_mem_b_1_din),
  .mem_2_rd_en(mult_A_mem_b_1_rd_en),
  .mem_2_rd_addr(mult_A_mem_b_1_rd_addr), 
  .mem_dout(memory_t7_ZQ_b_1_dout)
  );

memory_2_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_2_to_1_wrapper_t8_xPQ_inst_0 (
  .clk(clk),
  .mem_0_wr_en(mem_t8_0_wr_en),
  .mem_0_wr_addr(mem_t8_0_wr_addr),
  .mem_0_din(mem_t8_0_din),
  .mem_0_rd_en(mem_t8_0_rd_en),
  .mem_0_rd_addr(mem_t8_0_rd_addr),
  .mem_1_wr_en(mem_xPQ_0_wr_en),
  .mem_1_wr_addr(mem_xPQ_0_wr_addr),
  .mem_1_din(mem_xPQ_0_din),
  .mem_1_rd_en(mem_xPQ_0_rd_en),
  .mem_1_rd_addr(mem_xPQ_0_rd_addr), 
  .mem_dout(memory_t8_xPQ_0_dout)
  );

memory_2_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_2_to_1_wrapper_t8_xPQ_inst_1 (
  .clk(clk),
  .mem_0_wr_en(mem_t8_1_wr_en),
  .mem_0_wr_addr(mem_t8_1_wr_addr),
  .mem_0_din(mem_t8_1_din),
  .mem_0_rd_en(mem_t8_1_rd_en),
  .mem_0_rd_addr(mem_t8_1_rd_addr),
  .mem_1_wr_en(mem_xPQ_1_wr_en),
  .mem_1_wr_addr(mem_xPQ_1_wr_addr),
  .mem_1_din(mem_xPQ_1_din),
  .mem_1_rd_en(mem_xPQ_1_rd_en),
  .mem_1_rd_addr(mem_xPQ_1_rd_addr), 
  .mem_dout(memory_t8_xPQ_1_dout)
  );

memory_2_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_2_to_1_wrapper_t9_zPQ_inst_0 (
  .clk(clk),
  .mem_0_wr_en(mem_t9_0_wr_en),
  .mem_0_wr_addr(mem_t9_0_wr_addr),
  .mem_0_din(mem_t9_0_din),
  .mem_0_rd_en(mem_t9_0_rd_en),
  .mem_0_rd_addr(mem_t9_0_rd_addr),
  .mem_1_wr_en(mem_zPQ_0_wr_en),
  .mem_1_wr_addr(mem_zPQ_0_wr_addr),
  .mem_1_din(mem_zPQ_0_din),
  .mem_1_rd_en(mem_zPQ_0_rd_en),
  .mem_1_rd_addr(mem_zPQ_0_rd_addr), 
  .mem_dout(memory_t9_zPQ_0_dout)
  );

memory_2_to_1_wrapper #(.WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) memory_2_to_1_wrapper_t9_zPQ_inst_1 (
  .clk(clk),
  .mem_0_wr_en(mem_t9_1_wr_en),
  .mem_0_wr_addr(mem_t9_1_wr_addr),
  .mem_0_din(mem_t9_1_din),
  .mem_0_rd_en(mem_t9_1_rd_en),
  .mem_0_rd_addr(mem_t9_1_rd_addr),
  .mem_1_wr_en(mem_zPQ_1_wr_en),
  .mem_1_wr_addr(mem_zPQ_1_wr_addr),
  .mem_1_din(mem_zPQ_1_din),
  .mem_1_rd_en(mem_zPQ_1_rd_en),
  .mem_1_rd_addr(mem_zPQ_1_rd_addr), 
  .mem_dout(memory_t9_zPQ_1_dout)
  );
 
endmodule

