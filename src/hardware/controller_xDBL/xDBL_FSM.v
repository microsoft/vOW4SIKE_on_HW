/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      FSM for xDBL
 * 
*/

/* 
Function: doubling function

Follow the steps below:
# DBL function, latency: 2M+1S+4A
def xDBL(X,Z,A24,C24):
    # A24 = A+2
    # C24 = 4

    t0 = X+Z
    t1 = X-Z

    t2 = t0^2           #### parallel1
    t3 = t1^2           #### parallel1
    
    t4 = t2
    t5 = t3
    t0 = t2-t3

    t2 = C24*t5         #### parallel2
    t3 = A24*t0         #### parallel2
    
    t5 = t2
    t1 = t2+t3

    t2 = t4*t5          #### parallel3
    t3 = t1*t0          #### parallel3

    return t2,t3
*/

// Assumption: 
// 1: all of the operands are from GF(p^2)
// 2: inputs X, Z, A24, C24 have been initialized before this module is triggered
// 3: when there are parallel add/sub computations, they share the same timing. FIXME, need to double check

module xDBL_FSM 
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

  // interface with input memory A24
  input wire [SINGLE_MEM_WIDTH-1:0] mem_A24_0_dout,
  output wire mem_A24_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_A24_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_A24_1_dout,
  output wire mem_A24_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_A24_1_rd_addr,

  // interface with input memory C24
  input wire [SINGLE_MEM_WIDTH-1:0] mem_C24_0_dout,
  output wire mem_C24_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C24_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_C24_1_dout,
  output wire mem_C24_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C24_1_rd_addr,

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
 
wire add_A_running;
wire add_B_running;
wire add_running;
wire mult_running;

reg real_mult_A_start;
reg real_mult_B_start;
 
          // input: X, Z, A24, C24
parameter IDLE                          = 0, 
          // t0 = X + Z
          // t1 = X - Z
          X_PLUS_Z_AND_X_MINUS_Z        = IDLE + 1, 
          // t2 = t0*t0
          // t3 = t1*t1
          T0_SQUARE_AND_T1_SQUARE       = X_PLUS_Z_AND_X_MINUS_Z + 1,
          // t4 = t2
          // t5 = t3
          // t0 = t2 - t3
          T2_MINUS_T3                   = T0_SQUARE_AND_T1_SQUARE + 1,
          // t2 = C24*t5
          // t3 = A24*t0
          C24_TIMES_T5_AND_A24_TIMES_T0 = T2_MINUS_T3 + 1,
          // t5 = t2
          // t1 = t2 + t3
          T2_PLUS_T3                    = C24_TIMES_T5_AND_A24_TIMES_T0 + 1,
          // t2 = t4*t5
          // t3 = t0*t1
          T4_TIMES_T5_AND_T1_TIMES_T0   = T2_PLUS_T3 + 1, 
          MAX_STATE                     = T4_TIMES_T5_AND_T1_TIMES_T0 + 1;

reg [`CLOG2(MAX_STATE)-1:0] state; 
 
reg X_PLUS_Z_AND_X_MINUS_Z_running;
reg T0_SQUARE_AND_T1_SQUARE_running;
reg T2_MINUS_T3_running;
reg C24_TIMES_T5_AND_A24_TIMES_T0_running;
reg T2_PLUS_T3_running;
reg T4_TIMES_T5_AND_T1_TIMES_T0_running;

assign mult_A_used_for_squaring_running = T0_SQUARE_AND_T1_SQUARE_running;
assign mult_B_used_for_squaring_running = T0_SQUARE_AND_T1_SQUARE_running;

// interface to memory X
// here it requires that add_A and add_B have exactly the same timing sequence
// X is read at :
// t0 = X+Z
// t1 = X-Z
assign mem_X_0_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_a_0_rd_en;
assign mem_X_0_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_X_1_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_a_1_rd_en;
assign mem_X_1_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory Z
// Z is read at :
// t0 = X+Z
// t1 = X-Z
assign mem_Z_0_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_b_0_rd_en;
assign mem_Z_0_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_b_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_Z_1_rd_en = X_PLUS_Z_AND_X_MINUS_Z_running & add_A_mem_b_1_rd_en;
assign mem_Z_1_rd_addr = X_PLUS_Z_AND_X_MINUS_Z_running ? add_A_mem_b_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory C24
// C24 is read at :
// t2 = C24*t5 
assign mem_C24_0_rd_en = C24_TIMES_T5_AND_A24_TIMES_T0_running & mult_A_mem_a_0_rd_en;
assign mem_C24_0_rd_addr = C24_TIMES_T5_AND_A24_TIMES_T0_running ? mult_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_C24_1_rd_en = C24_TIMES_T5_AND_A24_TIMES_T0_running & mult_A_mem_a_1_rd_en;
assign mem_C24_1_rd_addr = C24_TIMES_T5_AND_A24_TIMES_T0_running ? mult_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory A24
// C24 is read at :
// t3 = A24*t0
assign mem_A24_0_rd_en = C24_TIMES_T5_AND_A24_TIMES_T0_running & mult_B_mem_a_0_rd_en;
assign mem_A24_0_rd_addr = C24_TIMES_T5_AND_A24_TIMES_T0_running ? mult_B_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_A24_1_rd_en = C24_TIMES_T5_AND_A24_TIMES_T0_running & mult_B_mem_a_1_rd_en;
assign mem_A24_1_rd_addr = C24_TIMES_T5_AND_A24_TIMES_T0_running ? mult_B_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to memory t4
// t4 is written at:
// t4 = t2
assign mem_t4_0_din = T2_MINUS_T3_running ? mult_A_sub_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t4_1_wr_en = mem_t4_0_wr_en;
assign mem_t4_1_wr_addr = mem_t4_0_wr_addr;
assign mem_t4_1_din = T2_MINUS_T3_running ? mult_A_add_mem_single_dout : {SINGLE_MEM_WIDTH{1'b0}};
// t4 is read at:
// t2 = t4*t5
assign mem_t4_0_rd_en = T4_TIMES_T5_AND_T1_TIMES_T0_running & mult_A_mem_a_0_rd_en;
assign mem_t4_0_rd_addr = T4_TIMES_T5_AND_T1_TIMES_T0_running ? mult_A_mem_a_0_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t4_1_rd_en = T4_TIMES_T5_AND_T1_TIMES_T0_running & mult_A_mem_a_1_rd_en;
assign mem_t4_1_rd_addr = T4_TIMES_T5_AND_T1_TIMES_T0_running ? mult_A_mem_a_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};


// interface to memory t5
// t5 is written at:
// t5 = t3, and
// t5 = t2
assign mem_t5_0_din = T2_MINUS_T3_running ? mult_B_sub_mem_single_dout :
                      T2_PLUS_T3_running ? mult_A_sub_mem_single_dout :
                      {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t5_1_wr_en = mem_t5_0_wr_en;
assign mem_t5_1_wr_addr = mem_t5_0_wr_addr;
assign mem_t5_1_din = T2_MINUS_T3_running ?  mult_B_add_mem_single_dout :
                      T2_PLUS_T3_running ? mult_A_add_mem_single_dout :
                      {SINGLE_MEM_WIDTH{1'b0}};
// t5 is read at:
// t2 = C24*t5, and
// t2 = t4*t5                   
assign mem_t5_0_rd_en = (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) & mult_A_mem_b_0_rd_en;
assign mem_t5_0_rd_addr = (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_A_mem_b_0_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_t5_1_rd_en = (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) & mult_A_mem_b_1_rd_en;
assign mem_t5_1_rd_addr = (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_A_mem_b_1_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
 

// interface to adder A:  
// the memories within the adder is READ only to the outside world
assign add_A_cmd = X_PLUS_Z_AND_X_MINUS_Z_running ? 3'd1 :
                   T2_MINUS_T3_running ? 3'd2 : 
                   3'd0;
assign add_A_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_A_mem_a_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_0_dout : 
                            T2_MINUS_T3_running ? mult_A_sub_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_a_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_1_dout : 
                            T2_MINUS_T3_running ? mult_A_add_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_0_dout : 
                            T2_MINUS_T3_running ? mult_B_sub_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_1_dout : 
                            T2_MINUS_T3_running ? mult_B_add_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
// t0 is read at:
// t2 = t0^2, and
// t3 = A24*t0
// t3 = t1*t0
assign add_A_mem_c_0_rd_en = T0_SQUARE_AND_T1_SQUARE_running ? mult_A_mem_a_0_rd_en : 
                             (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_B_mem_b_0_rd_en :
                             1'b0;
assign add_A_mem_c_0_rd_addr = T0_SQUARE_AND_T1_SQUARE_running ? mult_A_mem_a_0_rd_addr : 
                               (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_B_mem_b_0_rd_addr : 
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_A_mem_c_1_rd_en = T0_SQUARE_AND_T1_SQUARE_running ? mult_A_mem_a_1_rd_en : 
                             (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_B_mem_b_1_rd_en : 
                             1'b0;
assign add_A_mem_c_1_rd_addr = T0_SQUARE_AND_T1_SQUARE_running ? mult_A_mem_a_1_rd_addr : 
                               (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_B_mem_b_1_rd_addr : 
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to adder B 
// the memories within the adder is READ only to the outside world 
assign add_B_cmd = X_PLUS_Z_AND_X_MINUS_Z_running ? 3'd2 :
                   T2_PLUS_T3_running ? 3'd1 :
                   3'd0;
assign add_B_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_B_mem_a_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_0_dout : 
                            T2_PLUS_T3_running ? mult_A_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_a_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_X_1_dout : 
                            T2_PLUS_T3_running ? mult_A_add_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_0_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_0_dout : 
                            T2_PLUS_T3_running ? mult_B_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_1_dout = X_PLUS_Z_AND_X_MINUS_Z_running ? mem_Z_1_dout : 
                            T2_PLUS_T3_running ? mult_B_add_mem_single_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
// t1 is read at:
// t3 = t1^2
// t3 = t1*t0
assign add_B_mem_c_0_rd_en = (T0_SQUARE_AND_T1_SQUARE_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) & mult_B_mem_a_0_rd_en;
assign add_B_mem_c_0_rd_addr = (T0_SQUARE_AND_T1_SQUARE_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_B_mem_a_0_rd_addr : 
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_B_mem_c_1_rd_en = (T0_SQUARE_AND_T1_SQUARE_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) & mult_B_mem_a_1_rd_en;
assign add_B_mem_c_1_rd_addr = (T0_SQUARE_AND_T1_SQUARE_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mult_B_mem_a_1_rd_addr : 
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to multiplier A 
assign mult_A_mem_a_0_dout = T0_SQUARE_AND_T1_SQUARE_running ? add_A_mem_c_0_dout : 
                             C24_TIMES_T5_AND_A24_TIMES_T0_running ? mem_C24_0_dout :
                             T4_TIMES_T5_AND_T1_TIMES_T0_running ? mem_t4_0_dout :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_a_1_dout = T0_SQUARE_AND_T1_SQUARE_running ? add_A_mem_c_1_dout : 
                             C24_TIMES_T5_AND_A24_TIMES_T0_running ? mem_C24_1_dout : 
                             T4_TIMES_T5_AND_T1_TIMES_T0_running ? mem_t4_1_dout :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_0_dout = real_mult_A_start & T0_SQUARE_AND_T1_SQUARE_running ? add_A_mem_c_0_dout :
                             T0_SQUARE_AND_T1_SQUARE_running ? mult_A_mem_b_0_dout_buf : 
                             (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mem_t5_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_1_dout = real_mult_A_start & T0_SQUARE_AND_T1_SQUARE_running ? add_A_mem_c_1_dout :
                             T0_SQUARE_AND_T1_SQUARE_running ? mult_A_mem_b_1_dout_buf : 
                             (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? mem_t5_1_dout :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_c_1_dout = mult_running ? p_plus_one_mem_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t2 is read at:
// t0 = t2-t3
// t1 = t2+t3
assign mult_A_sub_mem_single_rd_en = T2_MINUS_T3_running ? add_A_mem_a_0_rd_en : 
                                     T2_PLUS_T3_running ? add_B_mem_a_0_rd_en : 
                                     1'b0;
assign mult_A_sub_mem_single_rd_addr = T2_MINUS_T3_running ? add_A_mem_a_0_rd_addr : 
                                       T2_PLUS_T3_running ? add_B_mem_a_0_rd_addr :
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_A_add_mem_single_rd_en = T2_MINUS_T3_running ? add_A_mem_a_1_rd_en : 
                                     T2_PLUS_T3_running ? add_B_mem_a_1_rd_en : 
                                     1'b0;
assign mult_A_add_mem_single_rd_addr = T2_MINUS_T3_running ? add_A_mem_a_1_rd_addr : 
                                       T2_PLUS_T3_running ? add_B_mem_a_1_rd_addr :
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};


// interface to multiplier B
assign mult_B_mem_a_0_dout = (T0_SQUARE_AND_T1_SQUARE_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? add_B_mem_c_0_dout : 
                             C24_TIMES_T5_AND_A24_TIMES_T0_running ? mem_A24_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_a_1_dout = (T0_SQUARE_AND_T1_SQUARE_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? add_B_mem_c_1_dout : 
                             C24_TIMES_T5_AND_A24_TIMES_T0_running ? mem_A24_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_0_dout = real_mult_A_start & T0_SQUARE_AND_T1_SQUARE_running ? add_B_mem_c_0_dout :
                             T0_SQUARE_AND_T1_SQUARE_running ? mult_B_mem_b_0_dout_buf : 
                             (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? add_A_mem_c_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_1_dout = real_mult_A_start & T0_SQUARE_AND_T1_SQUARE_running ? add_B_mem_c_1_dout :
                             T0_SQUARE_AND_T1_SQUARE_running ? mult_B_mem_b_1_dout_buf : 
                             (C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running) ? add_A_mem_c_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_c_1_dout = mult_A_mem_c_1_dout;

// t3 is read at:
// t0 = t2-t3
// t1 = t2+t3
assign mult_B_sub_mem_single_rd_en = T2_MINUS_T3_running ? add_A_mem_b_0_rd_en : 
                                     T2_PLUS_T3_running ? add_B_mem_b_0_rd_en : 
                                     1'b0;
assign mult_B_sub_mem_single_rd_addr = T2_MINUS_T3_running ? add_A_mem_b_0_rd_addr : 
                                       T2_PLUS_T3_running ? add_B_mem_b_0_rd_addr :
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_B_add_mem_single_rd_en = T2_MINUS_T3_running ? add_A_mem_b_1_rd_en : 
                                     T2_PLUS_T3_running ? add_B_mem_b_1_rd_en : 
                                     1'b0;
assign mult_B_add_mem_single_rd_addr = T2_MINUS_T3_running ? add_A_mem_b_1_rd_addr : 
                                       T2_PLUS_T3_running ? add_B_mem_b_1_rd_addr :
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to constant memories
assign add_A_running = X_PLUS_Z_AND_X_MINUS_Z_running | T2_MINUS_T3_running;
assign add_B_running = X_PLUS_Z_AND_X_MINUS_Z_running | T2_PLUS_T3_running;
assign add_running = add_A_running | add_B_running;
assign mult_running = T0_SQUARE_AND_T1_SQUARE_running | C24_TIMES_T5_AND_A24_TIMES_T0_running | T4_TIMES_T5_AND_T1_TIMES_T0_running;

assign p_plus_one_mem_rd_addr = mult_running ? mult_A_mem_c_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px2_mem_rd_addr = add_A_running ? add_A_px2_mem_rd_addr :
                         add_B_running ? add_B_px2_mem_rd_addr :
                         mult_running ? mult_A_px2_mem_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px4_mem_rd_addr = add_A_running ? add_A_px4_mem_rd_addr : 
                         add_B_running ? add_B_px4_mem_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
  
// write signals for intermediate operands t4 and t5
always @(posedge clk or posedge rst) begin
  if (rst) begin
    mem_t4_0_wr_en <= 1'b0;
    mem_t4_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    mem_t5_0_wr_en <= 1'b0;
    mem_t5_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    real_mult_A_start <= 1'b0;
    real_mult_B_start <= 1'b0;
  end
  else begin
    real_mult_A_start <= mult_A_start;
    real_mult_B_start <= mult_B_start;

    mem_t4_0_wr_en <= T2_MINUS_T3_running & mult_A_sub_mem_single_rd_en;
    mem_t4_0_wr_addr <= T2_MINUS_T3_running ? mult_A_sub_mem_single_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    mem_t5_0_wr_en <= T2_MINUS_T3_running ? mult_B_sub_mem_single_rd_en :
                      T2_PLUS_T3_running ? mult_A_sub_mem_single_rd_en :
                      1'b0;
    mem_t5_0_wr_addr <= T2_MINUS_T3_running ? mult_B_sub_mem_single_rd_addr : 
                        T2_PLUS_T3_running ? mult_A_sub_mem_single_rd_addr : 
                        {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
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
    T0_SQUARE_AND_T1_SQUARE_running <= 1'b0;
    T2_MINUS_T3_running <= 1'b0;
    C24_TIMES_T5_AND_A24_TIMES_T0_running <= 1'b0;
    T2_PLUS_T3_running <= 1'b0;
    T4_TIMES_T5_AND_T1_TIMES_T0_running <= 1'b0;
  end
  else begin 
    add_A_start <= 1'b0;
    add_B_start <= 1'b0;
    mult_A_start <= 1'b0;
    mult_B_start <= 1'b0;
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
        if (add_A_done) begin
          state <= T0_SQUARE_AND_T1_SQUARE;
          X_PLUS_Z_AND_X_MINUS_Z_running <= 1'b0;
          T0_SQUARE_AND_T1_SQUARE_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= X_PLUS_Z_AND_X_MINUS_Z;
        end

      T0_SQUARE_AND_T1_SQUARE: 
        if (mult_A_done) begin
          state <= T2_MINUS_T3;
          T0_SQUARE_AND_T1_SQUARE_running <= 1'b0;
          T2_MINUS_T3_running <= 1'b1; 
          add_A_start <= 1'b1;
        end
        else begin
          state <= state;
        end

      T2_MINUS_T3: 
        if (add_A_done) begin
          state <= C24_TIMES_T5_AND_A24_TIMES_T0;
          T2_MINUS_T3_running <= 1'b0;
          C24_TIMES_T5_AND_A24_TIMES_T0_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= state;
        end

      C24_TIMES_T5_AND_A24_TIMES_T0: 
        if (mult_A_done) begin
          state <= T2_PLUS_T3;
          C24_TIMES_T5_AND_A24_TIMES_T0_running <= 1'b0;
          T2_PLUS_T3_running <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= state;
        end

      T2_PLUS_T3:  
        if (add_B_done) begin
          state <= T4_TIMES_T5_AND_T1_TIMES_T0;
          T2_PLUS_T3_running <= 1'b0;
          T4_TIMES_T5_AND_T1_TIMES_T0_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= state;
        end
      
      T4_TIMES_T5_AND_T1_TIMES_T0: 
        if (mult_A_done) begin
          state <= IDLE;
          T4_TIMES_T5_AND_T1_TIMES_T0_running <= 1'b0;
          busy <= 1'b0;
          done <= 1'b1;
        end
        else begin
          state <= state;
        end

      default: 
        begin
          state <= state;
        end
    endcase
  end 
end
 
endmodule