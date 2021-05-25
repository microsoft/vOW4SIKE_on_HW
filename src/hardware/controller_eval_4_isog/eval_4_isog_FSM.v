/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      FSM for eval_4_isog
 * 
*/

/* 
Function: 4-ISO function

Follow the steps below:
def eval_4_isog(X,Z,C0,C1,C2):

    t0 = X+Z
    t1 = X-Z

    t2 = t0*C0
    t3 = t0*C1

    t4 = t2
    t5 = t3
    
    t2 = t1*t4
    t3 = t1*C2
      
    t4 = t2
    t0 = t3+t5
    t1 = t3-t5 

    t2 = t0^2
    t3 = t1^2

    t6 = t2
    t5 = t3
    t0 = t2+t4
    t1 = t3-t4

    t2 = t0*t6
    t3 = t1*t5

    return t2,t3
*/

// Assumption: 
// 1: all of the operands are from GF(p^2)
// 2: inputs X,Z,C0,C1,C2 have been initialized before this module is triggered
// 3: when there are parallel add/sub computations, they share the same timing. FIXME, need to double check

module eval_4_isog_FSM 
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

  // interface with input memory X
  input wire [SINGLE_MEM_WIDTH-1:0] mem_X_0_dout,
  output wire mem_X_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_X_1_dout,
  output wire mem_X_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_1_rd_addr,

  // interface with input memory Z
  input wire [SINGLE_MEM_WIDTH-1:0] mem_Z_0_dout,
  output wire mem_Z_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_Z_1_dout,
  output wire mem_Z_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_1_rd_addr, 

  // interface with input memory C0
  input wire [SINGLE_MEM_WIDTH-1:0] mem_C0_0_dout,
  output wire mem_C0_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C0_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_C0_1_dout,
  output wire mem_C0_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C0_1_rd_addr,

  // interface with input memory C1
  input wire [SINGLE_MEM_WIDTH-1:0] mem_C1_0_dout,
  output wire mem_C1_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C1_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_C1_1_dout,
  output wire mem_C1_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C1_1_rd_addr,

  // interface with input memory C2
  input wire [SINGLE_MEM_WIDTH-1:0] mem_C2_0_dout,
  output wire mem_C2_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C2_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_C2_1_dout,
  output wire mem_C2_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C2_1_rd_addr, 
  
  // interface with output memory t4 
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

  // interface with output memory t5 
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
 
  // interface with output memory t6 
  output reg mem_t6_0_wr_en,
  output reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_0_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t6_0_din, 
  output wire mem_t6_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_0_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t6_0_dout,

  output wire mem_t6_1_wr_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_1_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t6_1_din, 
  output wire mem_t6_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t6_1_rd_addr,
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t6_1_dout,
 
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
 
          // input: X,Z,C0,C1,C2
parameter IDLE                            = 0, 
          // t0 = X+Z
          // t1 = X-Z
          X_PLUS_Z_AND_X_MINUS_Z          = IDLE + 1,  
          // t2 = t0*C0
          // t3 = t0*C1
          T0_TIMES_C0_AND_T0_TIMES_C1     = X_PLUS_Z_AND_X_MINUS_Z + 1,
          // t4 = t2
          // t5 = t3
          T2_COPY_TO_T4_AND_T3_COPY_TO_T5 = T0_TIMES_C0_AND_T0_TIMES_C1 + 1,
          // t2 = t1*t4
          // t3 = t1*C2
          T1_TIMES_T4_AND_T1_TIMES_C2     = T2_COPY_TO_T4_AND_T3_COPY_TO_T5 + 1,
          // t4 = t2
          // t0 = t3+t5
          // t1 = t3-t5
          T3_PLUS_T5_AND_T3_MINUS_T5      = T1_TIMES_T4_AND_T1_TIMES_C2 + 1, 
          // t2 = t0^2           
          // t3 = t1^2                  
          T0_SQUARE_AND_T1_SUQARE         = T3_PLUS_T5_AND_T3_MINUS_T5 + 1,
          // t6 = t2
          // t5 = t3
          // t0 = t2+t4
          // t1 = t3-t4       
          T2_PLUS_T4_AND_T3_MINUS_T4      = T0_SQUARE_AND_T1_SUQARE + 1,
          // t2 = t0*t6          
          // t3 = t1*t5         
          T0_TIMES_T6_AND_T1_TIMES_T5     = T2_PLUS_T4_AND_T3_MINUS_T4 + 1,
          MAX_STATE                       = T0_TIMES_T6_AND_T1_TIMES_T5 + 1;


reg [`CLOG2(MAX_STATE)-1:0] state; 
 
reg X_PLUS_Z_AND_X_MINUS_Z_running;
reg T0_TIMES_C0_AND_T0_TIMES_C1_running;
reg T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running;
reg T1_TIMES_T4_AND_T1_TIMES_C2_running;
reg T3_PLUS_T5_AND_T3_MINUS_T5_running;
reg T0_SQUARE_AND_T1_SUQARE_running;
reg T2_PLUS_T4_AND_T3_MINUS_T4_running;
reg T0_TIMES_T6_AND_T1_TIMES_T5_running;

reg [SINGLE_MEM_DEPTH_LOG-1:0] counter; 


reg copy_start_pre; 
wire copy_start; 

wire last_copy_write;
reg last_copy_write_buf;
reg last_copy_write_buf_2;
wire add_A_done_buf;

assign mult_A_used_for_squaring_running = T0_SQUARE_AND_T1_SUQARE_running;
assign mult_B_used_for_squaring_running = T0_SQUARE_AND_T1_SUQARE_running;

// interface to input memory X
// here it requires that add_A and add_B have exactly the same timing sequence
// X is read at :
// t0 = X+Z
// t1 = X-Z 
assign mem_X_0_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_a_0_rd_en;
assign mem_X_0_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_X_1_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_a_1_rd_en;
assign mem_X_1_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to input memory Z
// Z is read at :
// t0 = X+Z   
// t1 = X-Z   
assign mem_Z_0_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_b_0_rd_en;
assign mem_Z_0_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_Z_1_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_b_1_rd_en;
assign mem_Z_1_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}}; 

// interface to input memory C0
// C0 is read at :
// t2 = t0*C0  
assign mem_C0_0_rd_en = T0_TIMES_C0_AND_T0_TIMES_C1_running & mult_A_mem_b_0_rd_en;
assign mem_C0_0_rd_addr = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mult_A_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C0_1_rd_en = T0_TIMES_C0_AND_T0_TIMES_C1_running & mult_A_mem_b_1_rd_en;
assign mem_C0_1_rd_addr = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mult_A_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to input memory C1
// C1 is read at :
// t3 = t0*C1  
assign mem_C1_0_rd_en = T0_TIMES_C0_AND_T0_TIMES_C1_running & mult_B_mem_b_0_rd_en;
assign mem_C1_0_rd_addr = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mult_B_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C1_1_rd_en = T0_TIMES_C0_AND_T0_TIMES_C1_running & mult_B_mem_b_1_rd_en;
assign mem_C1_1_rd_addr = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mult_B_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to input memory C2
// C2 is read at :
// t3 = t1*C2 
assign mem_C2_0_rd_en = T1_TIMES_T4_AND_T1_TIMES_C2_running & mult_B_mem_b_0_rd_en;
assign mem_C2_0_rd_addr = T1_TIMES_T4_AND_T1_TIMES_C2_running ? mult_B_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C2_1_rd_en = T1_TIMES_T4_AND_T1_TIMES_C2_running & mult_B_mem_b_1_rd_en;
assign mem_C2_1_rd_addr = T1_TIMES_T4_AND_T1_TIMES_C2_running ? mult_B_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to temporary data memory t4
// t4 is written at:
// t4 = t2   T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running
// t4 = t2   T3_PLUS_T5_AND_T3_MINUS_T5_running

assign mem_t4_0_din = (T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running | T3_PLUS_T5_AND_T3_MINUS_T5_running) ? mult_A_sub_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t4_1_wr_en = mem_t4_0_wr_en;
assign mem_t4_1_wr_addr = mem_t4_0_wr_addr;
assign mem_t4_1_din = (T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running | T3_PLUS_T5_AND_T3_MINUS_T5_running) ? mult_A_add_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t4 is read at:
// t2 = t1*t4   T1_TIMES_T4_AND_T1_TIMES_C2_running
// t0 = t2+t4   T2_PLUS_T4_AND_T3_MINUS_T4_running
// t1 = t3-t4   T2_PLUS_T4_AND_T3_MINUS_T4_running
assign mem_t4_0_rd_en = T1_TIMES_T4_AND_T1_TIMES_C2_running ? mult_A_mem_b_0_rd_en :
                        T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_b_0_rd_en :
                        1'b0;
assign mem_t4_0_rd_addr = T1_TIMES_T4_AND_T1_TIMES_C2_running ? mult_A_mem_b_0_rd_addr :
                          T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_b_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t4_1_rd_en = T1_TIMES_T4_AND_T1_TIMES_C2_running ? mult_A_mem_b_1_rd_en :
                        T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_b_1_rd_en :
                        1'b0;
assign mem_t4_1_rd_addr = T1_TIMES_T4_AND_T1_TIMES_C2_running ? mult_A_mem_b_1_rd_addr :
                          T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_b_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to temporary data memory t5
// t5 is written at:
// t5 = t3   T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running
// t5 = t3   T2_PLUS_T4_AND_T3_MINUS_T4_running

assign mem_t5_0_din = (T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running) ? mult_B_sub_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t5_1_wr_en = mem_t5_0_wr_en;
assign mem_t5_1_wr_addr = mem_t5_0_wr_addr;
assign mem_t5_1_din = (T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running) ? mult_B_add_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t5 is read at:
// t0 = t3+t5   T3_PLUS_T5_AND_T3_MINUS_T5_running
// t1 = t3-t5   T3_PLUS_T5_AND_T3_MINUS_T5_running
// t3 = t1*t5   T0_TIMES_T6_AND_T1_TIMES_T5_running
assign mem_t5_0_rd_en = T3_PLUS_T5_AND_T3_MINUS_T5_running ? add_A_mem_b_0_rd_en :
                        T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_B_mem_b_0_rd_en :
                        1'b0;
assign mem_t5_0_rd_addr = T3_PLUS_T5_AND_T3_MINUS_T5_running ? add_A_mem_b_0_rd_addr :
                          T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_B_mem_b_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t5_1_rd_en = T3_PLUS_T5_AND_T3_MINUS_T5_running ? add_A_mem_b_1_rd_en :
                        T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_B_mem_b_1_rd_en :
                        1'b0;
assign mem_t5_1_rd_addr = T3_PLUS_T5_AND_T3_MINUS_T5_running ? add_A_mem_b_1_rd_addr :
                          T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_B_mem_b_1_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to temporary data memory t6
// t6 is written at: 
// t6 = t2   T2_PLUS_T4_AND_T3_MINUS_T4_running

assign mem_t6_0_din = T2_PLUS_T4_AND_T3_MINUS_T4_running ? mult_A_sub_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t6_1_wr_en = mem_t6_0_wr_en;
assign mem_t6_1_wr_addr = mem_t6_0_wr_addr;
assign mem_t6_1_din = T2_PLUS_T4_AND_T3_MINUS_T4_running ? mult_A_add_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t6 is read at: 
// t2 = t0*t6   T0_TIMES_T6_AND_T1_TIMES_T5_running
assign mem_t6_0_rd_en = T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_A_mem_b_0_rd_en : 1'b0;
assign mem_t6_0_rd_addr = T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_A_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t6_1_rd_en = T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_A_mem_b_1_rd_en : 1'b0;
assign mem_t6_1_rd_addr = T0_TIMES_T6_AND_T1_TIMES_T5_running ? mult_A_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

 
// interface to adder A:  
// the memories within the adder is READ only to the outside world
assign add_A_cmd = (X_PLUS_Z_AND_X_MINUS_Z_running | T3_PLUS_T5_AND_T3_MINUS_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running ) ? 3'd1 : 3'd0;
assign add_A_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_A_mem_a_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_0_dout : 
                            T3_PLUS_T5_AND_T3_MINUS_T5_running ? mult_B_sub_mem_single_dout :
                            T2_PLUS_T4_AND_T3_MINUS_T4_running ? mult_A_sub_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_a_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_1_dout : 
                            T3_PLUS_T5_AND_T3_MINUS_T5_running ? mult_B_add_mem_single_dout :
                            T2_PLUS_T4_AND_T3_MINUS_T4_running ? mult_A_add_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_0_dout : 
                            T3_PLUS_T5_AND_T3_MINUS_T5_running ? mem_t5_0_dout :
                            T2_PLUS_T4_AND_T3_MINUS_T4_running ? mem_t4_0_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_1_dout : 
                            T3_PLUS_T5_AND_T3_MINUS_T5_running ? mem_t5_1_dout :
                            T2_PLUS_T4_AND_T3_MINUS_T4_running ? mem_t4_1_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
// t0 is read at:
// t2 = t0*C0   T0_TIMES_C0_AND_T0_TIMES_C1_running
// t3 = t0*C1   T0_TIMES_C0_AND_T0_TIMES_C1_running
// t2 = t0^2    T0_SQUARE_AND_T1_SUQARE_running
// t2 = t0*t6   T0_TIMES_T6_AND_T1_TIMES_T5_running
assign add_A_mem_c_0_rd_en = (T0_TIMES_C0_AND_T0_TIMES_C1_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_A_mem_a_0_rd_en : 1'b0;
assign add_A_mem_c_0_rd_addr = (T0_TIMES_C0_AND_T0_TIMES_C1_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_A_mem_c_1_rd_en = (T0_TIMES_C0_AND_T0_TIMES_C1_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_A_mem_a_1_rd_en : 1'b0;
assign add_A_mem_c_1_rd_addr = (T0_TIMES_C0_AND_T0_TIMES_C1_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};


// interface to adder B:  
// the memories within the adder is READ only to the outside world
assign add_B_cmd = (X_PLUS_Z_AND_X_MINUS_Z_running | T2_PLUS_T4_AND_T3_MINUS_T4_running | T3_PLUS_T5_AND_T3_MINUS_T5_running) ? 3'd2 : 3'd0;
assign add_B_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_B_mem_a_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_0_dout : 
                            (T2_PLUS_T4_AND_T3_MINUS_T4_running | T3_PLUS_T5_AND_T3_MINUS_T5_running) ? mult_B_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_a_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_1_dout : 
                            (T2_PLUS_T4_AND_T3_MINUS_T4_running | T3_PLUS_T5_AND_T3_MINUS_T5_running) ? mult_B_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_0_dout :
                            T3_PLUS_T5_AND_T3_MINUS_T5_running ? mem_t5_0_dout : 
                            T2_PLUS_T4_AND_T3_MINUS_T4_running ? mem_t4_0_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_1_dout : 
                            T3_PLUS_T5_AND_T3_MINUS_T5_running ? mem_t5_1_dout :
                            T2_PLUS_T4_AND_T3_MINUS_T4_running ? mem_t4_1_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
// t1 is read at:
// t2 = t1*t4   T1_TIMES_T4_AND_T1_TIMES_C2_running
// t3 = t1*C2   T1_TIMES_T4_AND_T1_TIMES_C2_running
// t3 = t1^2    T0_SQUARE_AND_T1_SUQARE_running
// t3 = t1*t5   T0_TIMES_T6_AND_T1_TIMES_T5_running
assign add_B_mem_c_0_rd_en = (T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_B_mem_a_0_rd_en : 1'b0;
assign add_B_mem_c_0_rd_addr = (T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_B_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_B_mem_c_1_rd_en = (T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_B_mem_a_1_rd_en : 1'b0;
assign add_B_mem_c_1_rd_addr = (T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? mult_B_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};


// interface to multiplier A 
assign mult_A_mem_a_0_dout = (T0_TIMES_C0_AND_T0_TIMES_C1_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? add_A_mem_c_0_dout : 
                             T1_TIMES_T4_AND_T1_TIMES_C2_running ? add_B_mem_c_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_a_1_dout = (T0_TIMES_C0_AND_T0_TIMES_C1_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? add_A_mem_c_1_dout : 
                             T1_TIMES_T4_AND_T1_TIMES_C2_running ? add_B_mem_c_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_0_dout = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mem_C0_0_dout :
                             T1_TIMES_T4_AND_T1_TIMES_C2_running ? mem_t4_0_dout : 
                             T0_TIMES_T6_AND_T1_TIMES_T5_running ? mem_t6_0_dout :
                             real_mult_A_start & T0_SQUARE_AND_T1_SUQARE_running ? add_A_mem_c_0_dout :
                             T0_SQUARE_AND_T1_SUQARE_running ? mult_A_mem_b_0_dout_buf :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_1_dout = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mem_C0_1_dout :
                             T1_TIMES_T4_AND_T1_TIMES_C2_running ? mem_t4_1_dout : 
                             T0_TIMES_T6_AND_T1_TIMES_T5_running ? mem_t6_1_dout :
                             real_mult_A_start & T0_SQUARE_AND_T1_SUQARE_running ? add_A_mem_c_1_dout :
                             T0_SQUARE_AND_T1_SUQARE_running ? mult_A_mem_b_1_dout_buf :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_c_1_dout = mult_running ? p_plus_one_mem_dout : {SINGLE_MEM_WIDTH{1'b0}};

      
// t2 is read at: 
// t4 = t2     T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running
// t4 = t2     T3_PLUS_T5_AND_T3_MINUS_T5_running
// t0 = t2+t4  T2_PLUS_T4_AND_T3_MINUS_T4_running
assign mult_A_sub_mem_single_rd_en = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running | T3_PLUS_T5_AND_T3_MINUS_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running; 
assign mult_A_sub_mem_single_rd_addr = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? counter :
                                       (T3_PLUS_T5_AND_T3_MINUS_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running) ? add_A_mem_a_0_rd_addr : 
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_A_add_mem_single_rd_en = mult_A_sub_mem_single_rd_en;
assign mult_A_add_mem_single_rd_addr = mult_A_sub_mem_single_rd_addr;


// interface to multiplier B 
assign mult_B_mem_a_0_dout = (T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? add_B_mem_c_0_dout : 
                             T0_TIMES_C0_AND_T0_TIMES_C1_running ? add_A_mem_c_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_a_1_dout = (T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running) ? add_B_mem_c_1_dout : 
                             T0_TIMES_C0_AND_T0_TIMES_C1_running ? add_A_mem_c_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_0_dout = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mem_C1_0_dout :
                             T1_TIMES_T4_AND_T1_TIMES_C2_running ? mem_C2_0_dout :
                             T0_TIMES_T6_AND_T1_TIMES_T5_running ? mem_t5_0_dout :
                             real_mult_B_start & T0_SQUARE_AND_T1_SUQARE_running ? add_B_mem_c_0_dout :
                             T0_SQUARE_AND_T1_SUQARE_running ? mult_B_mem_b_0_dout_buf :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_1_dout = T0_TIMES_C0_AND_T0_TIMES_C1_running ? mem_C1_1_dout :
                             T1_TIMES_T4_AND_T1_TIMES_C2_running ? mem_C2_1_dout :
                             T0_TIMES_T6_AND_T1_TIMES_T5_running ? mem_t5_1_dout :
                             real_mult_B_start & T0_SQUARE_AND_T1_SUQARE_running ? add_B_mem_c_1_dout :
                             T0_SQUARE_AND_T1_SUQARE_running ? mult_B_mem_b_1_dout_buf :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_c_1_dout = mult_running ? p_plus_one_mem_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t3 is read at: 
// t5 = t3        T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running
// t0 = t3+t5     T3_PLUS_T5_AND_T3_MINUS_T5_running
// t1 = t3-t5     T3_PLUS_T5_AND_T3_MINUS_T5_running
// t1 = t3-t4     T2_PLUS_T4_AND_T3_MINUS_T4_running
assign mult_B_sub_mem_single_rd_en = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running | T3_PLUS_T5_AND_T3_MINUS_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running; 
assign mult_B_sub_mem_single_rd_addr = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running ? counter :
                                       (T3_PLUS_T5_AND_T3_MINUS_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running) ? add_B_mem_a_0_rd_addr :
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_B_add_mem_single_rd_en = mult_B_sub_mem_single_rd_en;
assign mult_B_add_mem_single_rd_addr = mult_B_sub_mem_single_rd_addr;

// interface to constant memories 
assign add_running = X_PLUS_Z_AND_X_MINUS_Z_running | T3_PLUS_T5_AND_T3_MINUS_T5_running | T2_PLUS_T4_AND_T3_MINUS_T4_running;
assign mult_running = T0_TIMES_C0_AND_T0_TIMES_C1_running | T1_TIMES_T4_AND_T1_TIMES_C2_running | T0_SQUARE_AND_T1_SUQARE_running | T0_TIMES_T6_AND_T1_TIMES_T5_running;

assign p_plus_one_mem_rd_addr = mult_running ? mult_A_mem_c_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px2_mem_rd_addr = add_running ? add_A_px2_mem_rd_addr : 
                         mult_running ? mult_A_px2_mem_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px4_mem_rd_addr = add_running ? add_A_px4_mem_rd_addr : 
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};


assign last_copy_write = T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running & (counter == (SINGLE_MEM_DEPTH-1));

  
always @(posedge clk or posedge rst) begin
  if (rst) begin
    counter <= {SINGLE_MEM_DEPTH_LOG{1'b0}};  
    mem_t4_0_wr_en <= 1'b0;
    mem_t4_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};  
    mem_t5_0_wr_en <= 1'b0;
    mem_t5_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    mem_t6_0_wr_en <= 1'b0;
    mem_t6_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
    real_mult_A_start <= 1'b0;
    real_mult_B_start <= 1'b0;
  end
  else begin 
    real_mult_A_start <= mult_A_start;
    real_mult_B_start <= mult_B_start;
    
    counter <= (start | (counter == (SINGLE_MEM_DEPTH-1))) ? {SINGLE_MEM_DEPTH_LOG{1'b0}} :
               (copy_start | (counter > {SINGLE_MEM_DEPTH_LOG{1'b0}})) ? counter + 1 :
               counter;
    mem_t4_0_wr_en <= T3_PLUS_T5_AND_T3_MINUS_T5_running ? add_A_mem_a_0_rd_en :
                      copy_start ? 1'b1 :
                      start | (mem_t4_0_wr_en & (counter == {SINGLE_MEM_DEPTH_LOG{1'b0}})) ? 1'b0 : 
                      mem_t4_0_wr_en;
    mem_t4_0_wr_addr <= T3_PLUS_T5_AND_T3_MINUS_T5_running ? add_A_mem_a_0_rd_addr : counter; 

    mem_t5_0_wr_en <= T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_a_0_rd_en :
                      copy_start ? 1'b1 :
                      start | (mem_t5_0_wr_en & (counter == {SINGLE_MEM_DEPTH_LOG{1'b0}})) ? 1'b0 :
                      mem_t5_0_wr_en;
    mem_t5_0_wr_addr <= T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_a_0_rd_addr : counter;

    mem_t6_0_wr_en <= T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_a_0_rd_en : 1'b0;
    mem_t6_0_wr_addr <= T2_PLUS_T4_AND_T3_MINUS_T4_running ? add_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
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
    X_PLUS_Z_AND_X_MINUS_Z_running <= 1'b0;
    T0_TIMES_C0_AND_T0_TIMES_C1_running <= 1'b0;
    T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running <= 1'b0;
    T1_TIMES_T4_AND_T1_TIMES_C2_running <= 1'b0;
    T3_PLUS_T5_AND_T3_MINUS_T5_running <= 1'b0; 
    T0_SQUARE_AND_T1_SUQARE_running <= 1'b0;
    T2_PLUS_T4_AND_T3_MINUS_T4_running <= 1'b0;
    T0_TIMES_T6_AND_T1_TIMES_T5_running <= 1'b0;
    copy_start_pre <= 1'b0;
    last_copy_write_buf <= 1'b0;
    last_copy_write_buf_2 <= 1'b0;
  end
  else begin 
    add_A_start <= 1'b0;
    add_B_start <= 1'b0;
    mult_A_start <= 1'b0;
    mult_B_start <= 1'b0; 
    copy_start_pre <= 1'b0;
    last_copy_write_buf <= last_copy_write;
    last_copy_write_buf_2 <= last_copy_write_buf;
    done <= 1'b0; 
    case (state) 
      IDLE: 
        if (start) begin
          state <= X_PLUS_Z_AND_X_MINUS_Z;
          X_PLUS_Z_AND_X_MINUS_Z_running <= 1'b1;
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
          busy <= 1'b1;
        end
        else begin
          state <= IDLE;
        end

      X_PLUS_Z_AND_X_MINUS_Z: 
        if (add_A_done_buf) begin
          state <= T0_TIMES_C0_AND_T0_TIMES_C1;
          X_PLUS_Z_AND_X_MINUS_Z_running <= 1'b0;
          T0_TIMES_C0_AND_T0_TIMES_C1_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= X_PLUS_Z_AND_X_MINUS_Z;
        end

      T0_TIMES_C0_AND_T0_TIMES_C1: 
        if (mult_A_done) begin
          copy_start_pre <= 1'b1;
          state <= T2_COPY_TO_T4_AND_T3_COPY_TO_T5;
          T0_TIMES_C0_AND_T0_TIMES_C1_running <= 1'b0;
          T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running <= 1'b1; 
        end
        else begin
          state <= T0_TIMES_C0_AND_T0_TIMES_C1;
        end

      T2_COPY_TO_T4_AND_T3_COPY_TO_T5: 
        if (last_copy_write_buf_2) begin
          state <= T1_TIMES_T4_AND_T1_TIMES_C2;
          T2_COPY_TO_T4_AND_T3_COPY_TO_T5_running <= 1'b0;
          T1_TIMES_T4_AND_T1_TIMES_C2_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= T2_COPY_TO_T4_AND_T3_COPY_TO_T5;
        end

      T1_TIMES_T4_AND_T1_TIMES_C2: 
        if (mult_A_done) begin
          state <= T3_PLUS_T5_AND_T3_MINUS_T5;
          T1_TIMES_T4_AND_T1_TIMES_C2_running <= 1'b0;
          T3_PLUS_T5_AND_T3_MINUS_T5_running <= 1'b1;
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= T1_TIMES_T4_AND_T1_TIMES_C2;
        end

      T3_PLUS_T5_AND_T3_MINUS_T5:  
        if (add_A_done_buf) begin
          state <= T0_SQUARE_AND_T1_SUQARE;
          T3_PLUS_T5_AND_T3_MINUS_T5_running <= 1'b0; 
          T0_SQUARE_AND_T1_SUQARE_running <= 1'b1; 
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= T3_PLUS_T5_AND_T3_MINUS_T5;
        end

      T0_SQUARE_AND_T1_SUQARE:
        if (mult_A_done) begin
          state <= T2_PLUS_T4_AND_T3_MINUS_T4;
          T0_SQUARE_AND_T1_SUQARE_running <= 1'b0;
          T2_PLUS_T4_AND_T3_MINUS_T4_running <= 1'b1;
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= T0_SQUARE_AND_T1_SUQARE;
        end

      T2_PLUS_T4_AND_T3_MINUS_T4:
        if (add_A_done_buf) begin
          state <= T0_TIMES_T6_AND_T1_TIMES_T5;
          T2_PLUS_T4_AND_T3_MINUS_T4_running <= 1'b0;
          T0_TIMES_T6_AND_T1_TIMES_T5_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= T2_PLUS_T4_AND_T3_MINUS_T4;
        end

      T0_TIMES_T6_AND_T1_TIMES_T5:
        if (mult_A_done) begin
          state <= IDLE;
          T0_TIMES_T6_AND_T1_TIMES_T5_running <= 1'b0;
          busy <= 1'b0;
          done <= 1'b1;
        end
        else begin
          state <= T0_TIMES_T6_AND_T1_TIMES_T5;
        end
       

      default: 
        begin
          state <= state;
        end
    endcase
  end 
end

delay #(.WIDTH(1), .DELAY(2)) delay_inst_copy_start (
  .clk(clk),
  .rst(rst),
  .din(copy_start_pre),
  .dout(copy_start)
  );

delay #(.WIDTH(1), .DELAY(1)) delay_inst_add_A_done_buf (
  .clk(clk),
  .rst(rst),
  .din(add_A_done),
  .dout(add_A_done_buf)
  );

endmodule