/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      FSM for xADD
 * 
*/

/* 
Function: add_and_mul function

Follow the steps below:
def xADD(XP,ZP,XQ,ZQ,xPQ,zPQ):

    t0 = XP+ZP
    t1 = XP-ZP

    t4 = t0
    t5 = t1

    t0 = XQ+ZQ
    t1 = XQ-ZQ  

    t2 = t1*t4          #### parallel1
    t3 = t0*t5          #### parallel1

    t0 = t2-t3
    t1 = t2+t3

    t2 = t1^2           #### parallel2
    t3 = t0^2           #### parallel2
    
    t4 = t2
    t5 = t3

    t2 = zPQ*t4         #### parallel3
    t3 = xPQ*t5         #### parallel3
    
    XQ = t2
    ZQ = t3 
    
    return XQ, ZQ

*/

// Assumption: 
// 1: all of the operands are from GF(p^2)
// 2: inputs XP,ZP,XQ,ZQ,xPQ,zPQ have been initialized before this module is triggered
// 3: when there are parallel add/sub computations, they share the same timing. FIXME, need to double check

module xADD_FSM 
#(
  parameter RADIX = 32,
  parameter WIDTH_REAL = 14,
  parameter SINGLE_MEM_WIDTH = RADIX,
  parameter SINGLE_MEM_DEPTH = WIDTH_REAL,
  parameter SINGLE_MEM_DEPTH_LOG = `CLOG2(SINGLE_MEM_DEPTH),
  parameter DOUBLE_MEM_WIDTH = RADIX*2,
  parameter DOUBLE_MEM_DEPTH = (WIDTH_REAL+1)/2,
  parameter DOUBLE_MEM_DEPTH_LOG = `CLOG2(DOUBLE_MEM_DEPTH),
  parameter FILE_CONST_P_PLUS_ONE = "mem_p_plus_one.mem",
  parameter FILE_CONST_PX2 = "px2.mem",
  parameter FILE_CONST_PX4 = "px4.mem"
)
(
  input wire clk,
  input wire rst,
  input wire start,
  output reg busy,
  output reg done,
  
  input wire xADD_P_newly_loaded,
  output reg xADD_P_can_overwrite,

  // interface with input memory XP
  input wire [SINGLE_MEM_WIDTH-1:0] mem_XP_0_dout,
  output wire mem_XP_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_XP_1_dout,
  output wire mem_XP_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_1_rd_addr,

  // interface with input memory XQ
  input wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_dout,
  output wire mem_XQ_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_dout,
  output wire mem_XQ_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_1_rd_addr,

    // interface with input memory ZP
  input wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_dout,
  output wire mem_ZP_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_dout,
  output wire mem_ZP_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_1_rd_addr,

  // interface with input memory ZQ
  input wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_dout,
  output wire mem_ZQ_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_dout,
  output wire mem_ZQ_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_1_rd_addr,
 
  // interface with input memory xPQ
  input wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_dout,
  output wire mem_xPQ_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_dout,
  output wire mem_xPQ_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_1_rd_addr,

  // interface with input memory zPQ
  input wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_dout,
  output wire mem_zPQ_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_dout,
  output wire mem_zPQ_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_1_rd_addr,

  // interface with intermediate operands t4 
  output reg mem_t4_0_wr_en,
  output reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_0_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_din,
  output wire mem_t4_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_0_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_dout,

  output wire mem_t4_1_wr_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_1_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_din,
  output wire mem_t4_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_1_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_dout,

  // interface with intermediate operands t5 
  output reg mem_t5_0_wr_en,
  output reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_0_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_din,
  output wire mem_t5_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_0_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_dout, 

  output wire mem_t5_1_wr_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_1_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t5_1_din,
  output wire mem_t5_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_1_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t5_1_dout,
  

   // interface to adder A
  output reg add_A_start,
  input wire add_A_busy,
  input wire add_A_done,

  output wire [2:0] add_A_cmd,
  output wire add_A_extension_field_op,

    // input memories
  input wire add_A_mem_a_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_a_0_rd_addr, 
  output wire [RADIX-1:0] add_A_mem_a_0_dout,
  input wire add_A_mem_a_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_a_1_rd_addr, 
  output wire [RADIX-1:0] add_A_mem_a_1_dout,
   
  input wire add_A_mem_b_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_b_0_rd_addr, 
  output wire [RADIX-1:0] add_A_mem_b_0_dout,
   
  input wire add_A_mem_b_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_b_1_rd_addr, 
  output wire [RADIX-1:0] add_A_mem_b_1_dout,
    // result memory
  output wire add_A_mem_c_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_c_0_rd_addr, 
  input wire [RADIX-1:0] add_A_mem_c_0_dout, 

  output wire add_A_mem_c_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_c_1_rd_addr, 
  input wire [RADIX-1:0] add_A_mem_c_1_dout,

    // px2 memory
  input wire add_A_px2_mem_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_px2_mem_rd_addr,

    // px4 memory
  input wire add_A_px4_mem_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_px4_mem_rd_addr,

   // interface to adder B
  output reg add_B_start,
  input wire add_B_busy,
  input wire add_B_done,

  output wire [2:0] add_B_cmd,
  output wire add_B_extension_field_op,
    // input memories
  input wire add_B_mem_a_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_a_0_rd_addr, 
  output wire [RADIX-1:0] add_B_mem_a_0_dout,
   
  input wire add_B_mem_a_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_a_1_rd_addr, 
  output wire [RADIX-1:0] add_B_mem_a_1_dout,
   
  input wire add_B_mem_b_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_b_0_rd_addr, 
  output wire [RADIX-1:0] add_B_mem_b_0_dout,
   
  input wire add_B_mem_b_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_b_1_rd_addr, 
  output wire [RADIX-1:0] add_B_mem_b_1_dout,
    // result memory
  output wire add_B_mem_c_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_c_0_rd_addr, 
  input wire [RADIX-1:0] add_B_mem_c_0_dout, 

  output wire add_B_mem_c_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_c_1_rd_addr, 
  input wire [RADIX-1:0] add_B_mem_c_1_dout,

    // px2 memory
  input wire add_B_px2_mem_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_px2_mem_rd_addr,

    // px4 memory
  input wire add_B_px4_mem_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_px4_mem_rd_addr,

  // interface to multiplier A
  output reg mult_A_start,
  input wire mult_A_done,
  input wire mult_A_busy,

    // input memory
  input wire mult_A_mem_a_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_a_0_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_a_0_dout,
   
  input wire mult_A_mem_a_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_a_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_a_1_dout,
   
  input wire mult_A_mem_b_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_b_0_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_0_dout,

  input wire mult_A_mem_b_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_b_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_1_dout,
   
  input wire mult_A_mem_c_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_c_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_c_1_dout, 
    
    // result memory  
  output wire mult_A_sub_mem_single_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_sub_mem_single_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_A_sub_mem_single_dout,

  output wire mult_A_add_mem_single_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_add_mem_single_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_A_add_mem_single_dout,

  input wire mult_A_px2_mem_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_px2_mem_rd_addr, 

  // interface to multiplier B
  output reg mult_B_start,
  input wire mult_B_done,
  input wire mult_B_busy,

    // input memory
  input wire mult_B_mem_a_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_a_0_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_a_0_dout,
   
  input wire mult_B_mem_a_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_a_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_a_1_dout,
   
  input wire mult_B_mem_b_0_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_b_0_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_0_dout,

  input wire mult_B_mem_b_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_b_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_1_dout,
   
  input wire mult_B_mem_c_1_rd_en, 
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_c_1_rd_addr, 
  output wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_c_1_dout, 
    
    // result memory 
  output wire mult_B_sub_mem_single_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_sub_mem_single_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_B_sub_mem_single_dout,

  output wire mult_B_add_mem_single_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_add_mem_single_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_B_add_mem_single_dout,

  input wire mult_B_px2_mem_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_px2_mem_rd_addr,

  // interface to constants memory
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] p_plus_one_mem_rd_addr,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] px2_mem_rd_addr,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] px4_mem_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] p_plus_one_mem_dout,
  input wire [SINGLE_MEM_WIDTH-1:0] px2_mem_dout,
  input wire [SINGLE_MEM_WIDTH-1:0] px4_mem_dout,

  // specific for squaring logic
  input wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_0_dout_buf,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_1_dout_buf,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_0_dout_buf,
  input wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_1_dout_buf,

  output wire mult_A_used_for_squaring_running,
  output wire mult_B_used_for_squaring_running

);
  
wire add_running;
wire mult_running;

reg real_mult_A_start;
reg real_mult_B_start;

reg last_ZP_read_buf;
 
          // input: XP,ZP,XQ,ZQ,xPQ,zPQ
parameter IDLE                            = 0, 
          // t0 = XP+ZP
          // t1 = XP-ZP
          XP_PLUS_ZP_AND_XP_MINUS_ZP      = IDLE + 1, 
          // t4 = t0
          // t5 = t1
          T0_COPY_TO_T4_AND_T1_COPY_TO_T5 = XP_PLUS_ZP_AND_XP_MINUS_ZP + 1,
          // t0 = XQ+ZQ
          // t1 = XQ-ZQ
          XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ      = T0_COPY_TO_T4_AND_T1_COPY_TO_T5 + 1, 
          // t2 = t1*t4
          // t3 = t0*t5
          T1_TIMES_T4_AND_T0_TIMES_T5     = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ + 1,
          // t0 = t2-t3
          // t1 = t2+t3
          T2_MINUS_T3_AND_T2_PLUS_T3      = T1_TIMES_T4_AND_T0_TIMES_T5 + 1,
          // t2 = t1^2
          // t3 = t0^2
          T1_SQUARE_AND_T0_SQUARE         = T2_MINUS_T3_AND_T2_PLUS_T3 + 1,
          // t4 = t2 
          // t5 = t3
          T2_COPY_TO_T4_AND_T3_COPY_TO_T5 = T1_SQUARE_AND_T0_SQUARE + 1,  
          // t2 = zPQ*t4
          // t3 = xPQ*t5
          zPQ_TIMES_T4_AND_xPQ_TIMES_T5   = T2_COPY_TO_T4_AND_T3_COPY_TO_T5 + 1, 
          //
          MAX_STATE                       = zPQ_TIMES_T4_AND_xPQ_TIMES_T5 + 1;

reg [`CLOG2(MAX_STATE)-1:0] state; 
 
reg XP_PLUS_ZP_AND_XP_MINUS_ZP_running;
reg T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running;
reg XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running;
reg T1_TIMES_T4_AND_T0_TIMES_T5_running;
reg T2_MINUS_T3_AND_T2_PLUS_T3_running;
reg T1_SQUARE_AND_T0_SQUARE_running;
reg T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running;
reg zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running;  

reg [SINGLE_MEM_DEPTH_LOG-1:0] counter; 
reg [SINGLE_MEM_DEPTH_LOG-1:0] counter_buf; 
wire last_copy_write;
reg last_copy_write_buf;
reg last_copy_write_buf_2;
assign last_copy_write = (T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running | T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running) & (counter == (SINGLE_MEM_DEPTH-1));


assign mult_A_used_for_squaring_running = T1_SQUARE_AND_T0_SQUARE_running;
assign mult_B_used_for_squaring_running = mult_A_used_for_squaring_running;

// interface to memory XP
// here it requires that add_A and add_B have exactly the same timing sequence
// XP is read at :
// t0 = XP+ZP
// t1 = XP-ZP
assign mem_XP_0_rd_en = XP_PLUS_ZP_AND_XP_MINUS_ZP_running & add_A_mem_a_0_rd_en;
assign mem_XP_0_rd_addr = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? add_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XP_1_rd_en = XP_PLUS_ZP_AND_XP_MINUS_ZP_running & add_A_mem_a_1_rd_en;
assign mem_XP_1_rd_addr = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? add_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory ZP
// ZP is read at :
// t0 = XP+ZP
// t1 = XP-ZP
assign mem_ZP_0_rd_en = XP_PLUS_ZP_AND_XP_MINUS_ZP_running & add_A_mem_b_0_rd_en;
assign mem_ZP_0_rd_addr = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? add_A_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZP_1_rd_en = XP_PLUS_ZP_AND_XP_MINUS_ZP_running & add_A_mem_b_1_rd_en;
assign mem_ZP_1_rd_addr = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? add_A_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory XQ
// here it requires that add_A and add_B have exactly the same timing sequence
// XQ is read at :
// t0 = XQ+ZQ
// t1 = XQ-ZQ
assign mem_XQ_0_rd_en = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running & add_A_mem_a_0_rd_en;
assign mem_XQ_0_rd_addr = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? add_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_XQ_1_rd_en = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running & add_A_mem_a_1_rd_en;
assign mem_XQ_1_rd_addr = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? add_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory ZQ
// ZQ is read at :
// t0 = XQ+ZQ
// t1 = XQ-ZQ
assign mem_ZQ_0_rd_en = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running & add_A_mem_b_0_rd_en;
assign mem_ZQ_0_rd_addr = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? add_A_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_ZQ_1_rd_en = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running & add_A_mem_b_1_rd_en;
assign mem_ZQ_1_rd_addr = XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? add_A_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory xPQ
// xPQ is read at :
// t2 = zPQ*t4
// t3 = xPQ*t5 
assign mem_xPQ_0_rd_en = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running & mult_B_mem_a_0_rd_en;
assign mem_xPQ_0_rd_addr = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mult_B_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_xPQ_1_rd_en = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running & mult_B_mem_a_1_rd_en;
assign mem_xPQ_1_rd_addr = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mult_B_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory zPQ
// zPQ is read at :
// t2 = zPQ*t4
// t3 = xPQ*t5
assign mem_zPQ_0_rd_en = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running & mult_A_mem_a_0_rd_en;
assign mem_zPQ_0_rd_addr = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mult_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_zPQ_1_rd_en = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running & mult_A_mem_a_1_rd_en;
assign mem_zPQ_1_rd_addr = zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mult_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
 
// interface to memory t4
// t4 is written at:
// t4 = t0   T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running
// t4 = t2   T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running 
assign mem_t4_0_din = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? add_A_mem_c_0_dout : 
                      T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? mult_A_sub_mem_single_dout :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t4_1_wr_en = mem_t4_0_wr_en;
assign mem_t4_1_wr_addr = mem_t4_0_wr_addr;
assign mem_t4_1_din = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? add_A_mem_c_1_dout : 
                      T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? mult_A_add_mem_single_dout :
                      {SINGLE_MEM_WIDTH{1'b0}};

// t4 is read at:
// t2 = t1*t4    mult_A    T1_TIMES_T4_AND_T0_TIMES_T5_running
// t2 = zPQ*t4   mult_A    zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running 
assign mem_t4_0_rd_en = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_A_mem_b_0_rd_en :
                        1'b0;
assign mem_t4_0_rd_addr = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_A_mem_b_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t4_1_rd_en = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_A_mem_b_1_rd_en :
                        1'b0;
assign mem_t4_1_rd_addr = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_A_mem_b_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};


// interface to memory t5
// t5 is written at:
// t5 = t1   T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running
// t5 = t3   T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running 
assign mem_t5_0_din = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? add_B_mem_c_0_dout :
                      T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? mult_B_sub_mem_single_dout :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t5_1_wr_en = mem_t5_0_wr_en;
assign mem_t5_1_wr_addr = mem_t5_0_wr_addr;
assign mem_t5_1_din = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? add_B_mem_c_1_dout :
                      T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? mult_B_add_mem_single_dout :
                      {SINGLE_MEM_WIDTH{1'b0}};

// t5 is read at:
// t3 = t0*t5    mult_B    T1_TIMES_T4_AND_T0_TIMES_T5_running
// t3 = xPQ*t5   mult_B    zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running   
assign mem_t5_0_rd_en = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_B_mem_b_0_rd_en : 
                        1'b0;
assign mem_t5_0_rd_addr = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_B_mem_b_0_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t5_1_rd_en = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_B_mem_b_1_rd_en : 
                        1'b0;
assign mem_t5_1_rd_addr = (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mult_B_mem_b_1_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}}; 


// interface to adder A:  
// the memories within the adder is READ only to the outside world
assign add_A_cmd = (XP_PLUS_ZP_AND_XP_MINUS_ZP_running | XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running) ? 3'd1 :
                   T2_MINUS_T3_AND_T2_PLUS_T3_running ? 3'd2 : 
                   3'd0;
assign add_A_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_A_mem_a_0_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_XP_0_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_XQ_0_dout : 
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_A_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_a_1_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_XP_1_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_XQ_1_dout : 
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_A_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_0_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_ZP_0_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_ZQ_0_dout : 
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_B_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_1_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_ZP_1_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_ZQ_1_dout : 
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_B_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};

// t0 is read at:
// t4 = t0              T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running
// t3 = t0*t5  mult_B   T1_TIMES_T4_AND_T0_TIMES_T5_running
// t3 = t0^2   mult_B   T1_SQUARE_AND_T0_SQUARE_running 
assign add_A_mem_c_0_rd_en = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? 1'b1 : 
                             (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_B_mem_a_0_rd_en : 
                             1'b0; 
assign add_A_mem_c_0_rd_addr = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? counter : 
                               (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_B_mem_a_0_rd_addr : 
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_A_mem_c_1_rd_en = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? 1'b1 : 
                             (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_B_mem_a_1_rd_en : 
                             1'b0; 
assign add_A_mem_c_1_rd_addr = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? counter : 
                               (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_B_mem_a_1_rd_addr : 
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to adder B 
// the memories within the adder is READ only to the outside world  
assign add_B_cmd = T2_MINUS_T3_AND_T2_PLUS_T3_running ? 3'd1 :
                   (XP_PLUS_ZP_AND_XP_MINUS_ZP_running | XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running) ? 3'd2 :
                   3'd0;
assign add_B_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_B_mem_a_0_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_XP_0_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_XQ_0_dout :
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_A_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_a_1_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_XP_1_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_XQ_1_dout :
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_A_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_0_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_ZP_0_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_ZQ_0_dout :
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_B_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_1_dout = XP_PLUS_ZP_AND_XP_MINUS_ZP_running ? mem_ZP_1_dout : 
                            XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running ? mem_ZQ_1_dout :
                            T2_MINUS_T3_AND_T2_PLUS_T3_running ? mult_B_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};

// t1 is read at:
// t5 = t1               T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running 
// t2 = t1*t4   mult_A   T1_TIMES_T4_AND_T0_TIMES_T5_running 
// t2 = t1^2    mult_A   T1_SQUARE_AND_T0_SQUARE_running
assign add_B_mem_c_0_rd_en = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? 1'b1 : 
                             (T1_SQUARE_AND_T0_SQUARE_running | T1_TIMES_T4_AND_T0_TIMES_T5_running) ? mult_A_mem_a_0_rd_en :
                             1'b0;
assign add_B_mem_c_0_rd_addr = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? counter : 
                               (T1_SQUARE_AND_T0_SQUARE_running | T1_TIMES_T4_AND_T0_TIMES_T5_running) ? mult_A_mem_a_0_rd_addr :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_B_mem_c_1_rd_en = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? 1'b1 : 
                             (T1_SQUARE_AND_T0_SQUARE_running | T1_TIMES_T4_AND_T0_TIMES_T5_running) ? mult_A_mem_a_1_rd_en :
                             1'b0;
assign add_B_mem_c_1_rd_addr = T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running ? counter : 
                               (T1_SQUARE_AND_T0_SQUARE_running | T1_TIMES_T4_AND_T0_TIMES_T5_running) ? mult_A_mem_a_1_rd_addr :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to multiplier A 
assign mult_A_mem_a_0_dout = (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? add_B_mem_c_0_dout : 
                             zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mem_zPQ_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_a_1_dout = (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? add_B_mem_c_1_dout : 
                             zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mem_zPQ_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_0_dout = real_mult_A_start & T1_SQUARE_AND_T0_SQUARE_running ? add_B_mem_c_0_dout : 
                             T1_SQUARE_AND_T0_SQUARE_running ? mult_A_mem_b_0_dout_buf :
                             (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mem_t4_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_1_dout = real_mult_A_start & T1_SQUARE_AND_T0_SQUARE_running ? add_B_mem_c_1_dout : 
                             T1_SQUARE_AND_T0_SQUARE_running ? mult_A_mem_b_1_dout_buf :
                             (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mem_t4_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_c_1_dout = mult_running ? p_plus_one_mem_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t2 is read at: 
// t0 = t2-t3  T2_MINUS_T3_AND_T2_PLUS_T3_running 
// t4 = t2     T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running 
assign mult_A_sub_mem_single_rd_en = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? 1'b1 : 
                                     T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_a_0_rd_en : 
                                     1'b0;
assign mult_A_sub_mem_single_rd_addr = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? counter : 
                                       T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_a_0_rd_addr : 
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_A_add_mem_single_rd_en = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? 1'b1 : 
                                     T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_a_1_rd_en : 
                                     1'b0;
assign mult_A_add_mem_single_rd_addr = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? counter : 
                                       T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_a_1_rd_addr : 
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
  

// interface to multiplier B
assign mult_B_mem_a_0_dout = (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? add_A_mem_c_0_dout :
                             zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mem_xPQ_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_a_1_dout = (T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running) ? add_A_mem_c_1_dout :
                             zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running ? mem_xPQ_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_0_dout = real_mult_B_start & T1_SQUARE_AND_T0_SQUARE_running ? add_A_mem_c_0_dout :
                             T1_SQUARE_AND_T0_SQUARE_running ? mult_B_mem_b_0_dout_buf :
                             (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mem_t5_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_1_dout = real_mult_B_start & T1_SQUARE_AND_T0_SQUARE_running ? add_A_mem_c_1_dout :
                             T1_SQUARE_AND_T0_SQUARE_running ? mult_B_mem_b_1_dout_buf :
                             (T1_TIMES_T4_AND_T0_TIMES_T5_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running) ? mem_t5_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_c_1_dout = mult_A_mem_c_1_dout;
 
// t3 is read at: 
// t0 = t2-t3     T2_MINUS_T3_AND_T2_PLUS_T3_running 
// t5 = t3        T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running
assign mult_B_sub_mem_single_rd_en = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? 1'b1 :
                                     T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_b_0_rd_en : 
                                     1'b0;
assign mult_B_sub_mem_single_rd_addr = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? counter :
                                       T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_b_0_rd_addr : 
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_B_add_mem_single_rd_en = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? 1'b1 :
                                     T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_b_1_rd_en : 
                                     1'b0;
assign mult_B_add_mem_single_rd_addr = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? counter :
                                       T2_MINUS_T3_AND_T2_PLUS_T3_running ? add_A_mem_b_1_rd_addr : 
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to constant memories 
assign add_running = XP_PLUS_ZP_AND_XP_MINUS_ZP_running | XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running | T2_MINUS_T3_AND_T2_PLUS_T3_running;
assign mult_running = T1_TIMES_T4_AND_T0_TIMES_T5_running | T1_SQUARE_AND_T0_SQUARE_running | zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running;

assign p_plus_one_mem_rd_addr = mult_running ? mult_A_mem_c_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px2_mem_rd_addr = add_running ? add_A_px2_mem_rd_addr : 
                         mult_running ? mult_A_px2_mem_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px4_mem_rd_addr = add_running ? add_A_px4_mem_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

 
// write signals for intermediate operands t4, t5
always @(posedge clk or posedge rst) begin
  if (rst) begin
    counter <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    counter_buf <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    mem_t4_0_wr_en <= 1'b0;
    mem_t4_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    mem_t5_0_wr_en <= 1'b0;
    mem_t5_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    last_copy_write_buf <= 1'b0;
    last_copy_write_buf_2 <= 1'b0;
    real_mult_A_start <= 1'b0;
    real_mult_B_start <= 1'b0;
  end
  else begin
    real_mult_A_start <= mult_A_start;
    real_mult_B_start <= mult_B_start;
    counter_buf <= counter;
    counter <= (start | last_copy_write | last_copy_write_buf | done) ? {SINGLE_MEM_DEPTH_LOG{1'b0}} : 
               (T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running | T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running) ? counter + 1 :
               counter;
    mem_t4_0_wr_en <= (mem_t4_0_wr_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b0 :
                      (T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running | T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running) ? 1'b1 : 
                      mem_t4_0_wr_en;
    mem_t4_0_wr_addr <= (T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running | T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running) ? counter : 
                        {SINGLE_MEM_DEPTH_LOG{1'b0}};
    mem_t5_0_wr_en <= (mem_t5_0_wr_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b0 :
                      (T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running | T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running) ? 1'b1 : 
                      mem_t5_0_wr_en;
    mem_t5_0_wr_addr <= (T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running | T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running) ? counter : 
                        {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    last_copy_write_buf <= last_copy_write;
    last_copy_write_buf_2 <= last_copy_write_buf;
 
  end
end

// finite state machine transitions
always @(posedge clk or posedge rst) begin
  if (rst) begin
    add_A_start <= 1'b0;
    add_B_start <= 1'b0;
    mult_A_start <= 1'b0;
    mult_B_start <= 1'b0;
    busy <= 1'b0;
    done <= 1'b0;
    state <= IDLE;
    XP_PLUS_ZP_AND_XP_MINUS_ZP_running <= 1'b0;
    T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running <= 1'b0;
    XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running <= 1'b0;
    T1_TIMES_T4_AND_T0_TIMES_T5_running <= 1'b0;
    T2_MINUS_T3_AND_T2_PLUS_T3_running <= 1'b0;
    T1_SQUARE_AND_T0_SQUARE_running <= 1'b0;
    T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running <= 1'b0;
    zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running <= 1'b0; 
    xADD_P_can_overwrite <= 1'b0;
    last_ZP_read_buf <= 1'b0;
  end
  else begin 
    add_A_start <= 1'b0;
    add_B_start <= 1'b0;
    mult_A_start <= 1'b0;
    mult_B_start <= 1'b0; 
    done <= 1'b0; 
    last_ZP_read_buf <= 1'b0;
    xADD_P_can_overwrite <= last_ZP_read_buf ? 1'b1 :
                            xADD_P_newly_loaded ? 1'b0 : 
                            xADD_P_can_overwrite;
    case (state) 
      IDLE: 
        if (start) begin
          state <= XP_PLUS_ZP_AND_XP_MINUS_ZP;
          XP_PLUS_ZP_AND_XP_MINUS_ZP_running <= 1'b1;
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
          busy <= 1'b1;
        end
        else begin
          state <= IDLE;
        end

      XP_PLUS_ZP_AND_XP_MINUS_ZP: 
        if (add_A_done) begin
          state <= T0_COPY_TO_T4_AND_T1_COPY_TO_T5;
          XP_PLUS_ZP_AND_XP_MINUS_ZP_running <= 1'b0;
          T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running <= 1'b1; 
          xADD_P_can_overwrite <= 1'b1; 
          last_ZP_read_buf <= 1'b1;
        end
        else begin
          state <= XP_PLUS_ZP_AND_XP_MINUS_ZP;
        end

      T0_COPY_TO_T4_AND_T1_COPY_TO_T5:
        if (last_copy_write_buf) begin
          state <= XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ;
          T0_COPY_TO_T4_AND_T1_COPY_TO_T5_running <= 1'b0;
          XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running <= 1'b1;
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= T0_COPY_TO_T4_AND_T1_COPY_TO_T5;
        end

      XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ: 
        if (add_A_done) begin
          state <= T1_TIMES_T4_AND_T0_TIMES_T5;
          XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ_running <= 1'b0;
          T1_TIMES_T4_AND_T0_TIMES_T5_running <= 1'b1; 
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= XQ_PLUS_ZQ_AND_XQ_MINUS_ZQ;
        end

      T1_TIMES_T4_AND_T0_TIMES_T5: 
        if (mult_A_done) begin
          state <= T2_MINUS_T3_AND_T2_PLUS_T3;
          T1_TIMES_T4_AND_T0_TIMES_T5_running <= 1'b0;
          T2_MINUS_T3_AND_T2_PLUS_T3_running <= 1'b1; 
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= T1_TIMES_T4_AND_T0_TIMES_T5;
        end

      T2_MINUS_T3_AND_T2_PLUS_T3:
        if (add_A_done) begin
          state <= T1_SQUARE_AND_T0_SQUARE;
          T2_MINUS_T3_AND_T2_PLUS_T3_running <= 1'b0;
          T1_SQUARE_AND_T0_SQUARE_running <= 1'b1; 
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= T2_MINUS_T3_AND_T2_PLUS_T3;
        end

      T1_SQUARE_AND_T0_SQUARE: 
        if (mult_A_done) begin
          state <= T2_COPY_TO_T4_AND_T3_COPY_TO_T5;
          T1_SQUARE_AND_T0_SQUARE_running <= 1'b0;
          T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running <= 1'b1; 
        end
        else begin
          state <= T1_SQUARE_AND_T0_SQUARE;
        end

      T2_COPY_TO_T4_AND_T3_COPY_TO_T5:  
        if (last_copy_write_buf) begin
          state <= zPQ_TIMES_T4_AND_xPQ_TIMES_T5;
          T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running <= 1'b0;
          zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running <= 1'b1; 
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1; 
        end
        else begin
          state <= T2_COPY_TO_T4_AND_T3_COPY_TO_T5;
        end

      zPQ_TIMES_T4_AND_xPQ_TIMES_T5:
        if (mult_A_done) begin
          state <= IDLE;
          busy <= 1'b0;
          done <= 1'b1;
          zPQ_TIMES_T4_AND_xPQ_TIMES_T5_running <= 1'b0; 
        end
        else begin
          state <= zPQ_TIMES_T4_AND_xPQ_TIMES_T5;
        end
       

      default: 
        begin
          state <= state;
        end

    endcase
  end 
end

// define states here 

endmodule