/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      FSM for get_4_isog
 * 
*/

/* 
Function: 4-ISO function

Follow the steps below:
# 4-ISO function, latency: 2S+5A
def get_4_isog(X4,Z4):

  t0 = X4+Z4
  t1 = X4-Z4

  t4 = t0        
  t5 = t1        
  t2 = X4^2            
  t3 = Z4^2          
   
  t0 = t3+t3
  t1 = t2+t2

  t2 = t1^2           
  t3 = t0^2          

  t1 = t0+t0

  return t2,t3,t1,t5,t4
*/

// Assumption: 
// 1: all of the operands are from GF(p^2)
// 2: inputs X4, Z4 have been initialized before this module is triggered
// 3: when there are parallel add/sub computations, they share the same timing. FIXME, need to double check

module get_4_isog_FSM 
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
  input wire [SINGLE_MEM_WIDTH-1:0] mem_X4_0_dout,
  output wire mem_X4_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_X4_1_dout,
  output wire mem_X4_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_1_rd_addr,

  // interface with input memory Z
  input wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_0_dout,
  output wire mem_Z4_0_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_0_rd_addr,

  input wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_1_dout,
  output wire mem_Z4_1_rd_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_1_rd_addr, 
  
  // interface with output memory t4  
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_dout, 
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_dout,

  // interface with intermediate operands t4 
  output reg mem_t4_0_wr_en,
  output reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_0_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_din, 

  output wire mem_t4_1_wr_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t4_1_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_din,

  // interface with intermediate operands t5 
  output wire mem_t5_0_wr_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_0_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_din, 
  input wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_dout, 

  output wire mem_t5_1_wr_en,
  output wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t5_1_wr_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t5_1_din, 
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
 
          // input: X4, Z4
parameter IDLE                        = 0, 
          // t0 = X4+Z4
          // t1 = X4-Z4
          X4_PLUS_Z4_AND_X4_MINUS_Z4  = IDLE + 1,  
          // t4 = t0
          // t5 = t1
          // t2 = X4*X4
          // t3 = Z4*Z4
          X4_SQUARE_AND_Z4_SQUARE     = X4_PLUS_Z4_AND_X4_MINUS_Z4 + 1,
          // t0 = t3 + t3
          // t1 = t2 + t2
          T3_PLUS_T3_AND_T2_PLUS_T2   = X4_SQUARE_AND_Z4_SQUARE + 1,
          // t2 = t1*t1
          // t3 = t0*t0
          T1_SQUARE_AND_T0_SQUARE     = T3_PLUS_T3_AND_T2_PLUS_T2 + 1,
          // t1 = t0+t0
          T0_PLUS_T0                  = T1_SQUARE_AND_T0_SQUARE + 1, 
          MAX_STATE                   = T0_PLUS_T0 + 1;

reg [`CLOG2(MAX_STATE)-1:0] state; 
 
reg X4_PLUS_Z4_AND_X4_MINUS_Z4_running;
reg X4_SQUARE_AND_Z4_SQUARE_running;
reg T3_PLUS_T3_AND_T2_PLUS_T2_running;
reg T1_SQUARE_AND_T0_SQUARE_running;
reg T0_PLUS_T0_running; 

reg [SINGLE_MEM_DEPTH_LOG-1:0] counter;

reg copy_start_pre; 
wire copy_start;

assign mult_A_used_for_squaring_running = X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running;
assign mult_B_used_for_squaring_running = mult_A_used_for_squaring_running;

// interface to input memory X4
// here it requires that add_A and add_B have exactly the same timing sequence
// X4 is read at :
// t0 = X4+Z4
// t1 = X4-Z4
// t2 = X4*X4
assign mem_X4_0_rd_en = (X4_PLUS_Z4_AND_X4_MINUS_Z4_running & add_A_mem_a_0_rd_en) | (X4_SQUARE_AND_Z4_SQUARE_running & mult_A_mem_a_0_rd_en);
assign mem_X4_0_rd_addr = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? add_A_mem_a_0_rd_addr : 
                          X4_SQUARE_AND_Z4_SQUARE_running ? mult_A_mem_a_0_rd_addr :
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_X4_1_rd_en = (X4_PLUS_Z4_AND_X4_MINUS_Z4_running & add_A_mem_a_1_rd_en) | (X4_SQUARE_AND_Z4_SQUARE_running & mult_A_mem_a_1_rd_en);
assign mem_X4_1_rd_addr = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? add_A_mem_a_1_rd_addr : 
                          X4_SQUARE_AND_Z4_SQUARE_running ? mult_A_mem_a_1_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to input memory Z4
// Z4 is read at :
// t0 = X4+Z4
// t1 = X4-Z4
// t3 = Z4*Z4
assign mem_Z4_0_rd_en = (X4_PLUS_Z4_AND_X4_MINUS_Z4_running & add_A_mem_b_0_rd_en) | (X4_SQUARE_AND_Z4_SQUARE_running & mult_B_mem_a_0_rd_en);
assign mem_Z4_0_rd_addr = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? add_A_mem_b_0_rd_addr : 
                          X4_SQUARE_AND_Z4_SQUARE_running ? mult_B_mem_a_0_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mem_Z4_1_rd_en = (X4_PLUS_Z4_AND_X4_MINUS_Z4_running & add_A_mem_b_1_rd_en) | (X4_SQUARE_AND_Z4_SQUARE_running & mult_B_mem_a_1_rd_en);
assign mem_Z4_1_rd_addr = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? add_A_mem_b_1_rd_addr : 
                          X4_SQUARE_AND_Z4_SQUARE_running ? mult_B_mem_a_1_rd_addr : 
                          {SINGLE_MEM_DEPTH_LOG{1'b0}}; 

// interface to temporary data memory t4
// t4 is written at:
// t4 = t0
  
assign mem_t4_0_din = mem_t4_0_wr_en ? add_A_mem_c_0_dout : {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t4_1_wr_en = mem_t4_0_wr_en;
assign mem_t4_1_wr_addr = mem_t4_0_wr_addr;
assign mem_t4_1_din = mem_t4_1_wr_en ? add_A_mem_c_1_dout : {SINGLE_MEM_WIDTH{1'b0}};

// interface to temporary data memory t5
// t5 is written at:
// t5 = t0  

assign mem_t5_0_din = mem_t5_0_wr_en ? add_B_mem_c_0_dout : {SINGLE_MEM_WIDTH{1'b0}};
assign mem_t5_0_wr_en = mem_t4_0_wr_en;
assign mem_t5_0_wr_addr = mem_t4_0_wr_addr;
assign mem_t5_1_wr_en = mem_t5_0_wr_en;
assign mem_t5_1_wr_addr = mem_t5_0_wr_addr;
assign mem_t5_1_din = mem_t5_1_wr_en ? add_B_mem_c_1_dout : {SINGLE_MEM_WIDTH{1'b0}};
 
 
// interface to adder A:  
// the memories within the adder is READ only to the outside world
assign add_A_cmd = (X4_PLUS_Z4_AND_X4_MINUS_Z4_running | T3_PLUS_T3_AND_T2_PLUS_T2) ? 3'd1 : 3'd0;
assign add_A_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_A_mem_a_0_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_X4_0_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_B_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_a_1_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_X4_1_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_B_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_0_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_Z4_0_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_B_sub_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_A_mem_b_1_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_Z4_1_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_B_add_mem_single_dout : 
                            {SINGLE_MEM_WIDTH{1'b0}};
// t0 is read at:
// t4 = t0    X4_SQUARE_AND_Z4_SQUARE_running
// t3 = t0^2  T1_SQUARE_AND_T0_SQUARE_running
// t1 = t0+t0 T0_PLUS_T0_running
assign add_A_mem_c_0_rd_en = X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running | T0_PLUS_T0_running;  
assign add_A_mem_c_0_rd_addr = X4_SQUARE_AND_Z4_SQUARE_running ? counter : 
                               T1_SQUARE_AND_T0_SQUARE_running ? mult_B_mem_a_0_rd_addr :
                               T0_PLUS_T0_running ? add_B_mem_a_0_rd_addr :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_A_mem_c_1_rd_en = add_A_mem_c_0_rd_en;
assign add_A_mem_c_1_rd_addr = X4_SQUARE_AND_Z4_SQUARE_running ? counter : 
                               T1_SQUARE_AND_T0_SQUARE_running ? mult_B_mem_a_1_rd_addr :
                               T0_PLUS_T0_running ? add_B_mem_a_1_rd_addr :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to adder B 
// the memories within the adder is READ only to the outside world 
assign add_B_cmd = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? 3'd2 :
                   (T3_PLUS_T3_AND_T2_PLUS_T2_running | T0_PLUS_T0_running) ? 3'd1 :
                   3'd0;
assign add_B_extension_field_op = 1'b1; // always doing GF(p^2) operation
assign add_B_mem_a_0_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_X4_0_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_A_sub_mem_single_dout : 
                            T0_PLUS_T0_running ? add_A_mem_c_0_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_a_1_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_X4_1_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_A_add_mem_single_dout : 
                            T0_PLUS_T0_running ? add_A_mem_c_1_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_0_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_Z4_0_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_A_sub_mem_single_dout : 
                            T0_PLUS_T0_running ? add_A_mem_c_0_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
assign add_B_mem_b_1_dout = X4_PLUS_Z4_AND_X4_MINUS_Z4_running ? mem_Z4_1_dout : 
                            T3_PLUS_T3_AND_T2_PLUS_T2_running ? mult_A_add_mem_single_dout :
                            T0_PLUS_T0_running ? add_A_mem_c_1_dout :
                            {SINGLE_MEM_WIDTH{1'b0}};
// t1 is read at:
// t5 = t1
// t2 = t1^2 
assign add_B_mem_c_0_rd_en = X4_SQUARE_AND_Z4_SQUARE_running | (T1_SQUARE_AND_T0_SQUARE_running & mult_A_mem_a_0_rd_en);
assign add_B_mem_c_0_rd_addr = T1_SQUARE_AND_T0_SQUARE_running ? mult_A_mem_a_0_rd_addr : 
                               X4_SQUARE_AND_Z4_SQUARE_running ? counter :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign add_B_mem_c_1_rd_en = X4_SQUARE_AND_Z4_SQUARE_running | (T1_SQUARE_AND_T0_SQUARE_running & mult_A_mem_a_1_rd_en);
assign add_B_mem_c_1_rd_addr = T1_SQUARE_AND_T0_SQUARE_running ? mult_A_mem_a_1_rd_addr : 
                               X4_SQUARE_AND_Z4_SQUARE_running ? counter :
                               {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to multiplier A 
assign mult_A_mem_a_0_dout = X4_SQUARE_AND_Z4_SQUARE_running ? mem_X4_0_dout : 
                             T1_SQUARE_AND_T0_SQUARE_running ? add_B_mem_c_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_a_1_dout = X4_SQUARE_AND_Z4_SQUARE_running ? mem_X4_1_dout : 
                             T1_SQUARE_AND_T0_SQUARE_running ? add_B_mem_c_1_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_0_dout = real_mult_A_start & X4_SQUARE_AND_Z4_SQUARE_running ? mem_X4_0_dout :
                             real_mult_A_start & T1_SQUARE_AND_T0_SQUARE_running ? add_B_mem_c_0_dout : 
                             (X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_A_mem_b_0_dout_buf :  
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_b_1_dout = real_mult_A_start & X4_SQUARE_AND_Z4_SQUARE_running ? mem_X4_1_dout :
                             real_mult_A_start & T1_SQUARE_AND_T0_SQUARE_running ? add_B_mem_c_1_dout : 
                             (X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_A_mem_b_1_dout_buf :  
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_A_mem_c_1_dout = mult_running ? p_plus_one_mem_dout : {SINGLE_MEM_WIDTH{1'b0}};

// t2 is read at: 
// t1 = t2+t2
assign mult_A_sub_mem_single_rd_en = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_B_mem_a_0_rd_en :  
                                     1'b0;
assign mult_A_sub_mem_single_rd_addr = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_B_mem_a_0_rd_addr :  
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_A_add_mem_single_rd_en = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_B_mem_a_1_rd_en :  
                                     1'b0;
assign mult_A_add_mem_single_rd_addr = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_B_mem_a_1_rd_addr : 
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};


// interface to multiplier B
assign mult_B_mem_a_0_dout = X4_SQUARE_AND_Z4_SQUARE_running ? mem_Z4_0_dout : 
                             T1_SQUARE_AND_T0_SQUARE_running ? add_A_mem_c_0_dout : 
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_a_1_dout = X4_SQUARE_AND_Z4_SQUARE_running ? mem_Z4_1_dout : 
                             T1_SQUARE_AND_T0_SQUARE_running ? add_A_mem_c_1_dout :
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_0_dout = real_mult_B_start & X4_SQUARE_AND_Z4_SQUARE_running ? mem_Z4_0_dout :
                             real_mult_B_start & T1_SQUARE_AND_T0_SQUARE_running ? add_A_mem_c_0_dout : 
                             (X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_B_mem_b_0_dout_buf :  
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_b_1_dout = real_mult_B_start & X4_SQUARE_AND_Z4_SQUARE_running ? mem_Z4_1_dout :
                             real_mult_B_start & T1_SQUARE_AND_T0_SQUARE_running ? add_A_mem_c_1_dout : 
                             (X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running) ? mult_B_mem_b_1_dout_buf :  
                             {SINGLE_MEM_WIDTH{1'b0}};
assign mult_B_mem_c_1_dout = mult_A_mem_c_1_dout;

// t3 is read at:
// t0 = t3+t3 
assign mult_B_sub_mem_single_rd_en = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_A_mem_a_0_rd_en :  
                                     1'b0;
assign mult_B_sub_mem_single_rd_addr = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_A_mem_a_0_rd_addr :  
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign mult_B_add_mem_single_rd_en = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_A_mem_a_1_rd_en : 
                                     1'b0;
assign mult_B_add_mem_single_rd_addr = T3_PLUS_T3_AND_T2_PLUS_T2_running ? add_A_mem_a_1_rd_addr :  
                                       {SINGLE_MEM_DEPTH_LOG{1'b0}};

// interface to constant memories
assign add_A_running = X4_PLUS_Z4_AND_X4_MINUS_Z4_running | T3_PLUS_T3_AND_T2_PLUS_T2_running;
assign add_B_running = X4_PLUS_Z4_AND_X4_MINUS_Z4_running | T3_PLUS_T3_AND_T2_PLUS_T2_running | T0_PLUS_T0_running;
assign add_running = add_A_running | add_B_running;
assign mult_running = X4_SQUARE_AND_Z4_SQUARE_running | T1_SQUARE_AND_T0_SQUARE_running;

assign p_plus_one_mem_rd_addr = mult_running ? mult_A_mem_c_1_rd_addr : {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px2_mem_rd_addr = add_A_running ? add_A_px2_mem_rd_addr :
                         add_B_running ? add_B_px2_mem_rd_addr :
                         mult_running ? mult_A_px2_mem_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
assign px4_mem_rd_addr = add_A_running ? add_A_px4_mem_rd_addr : 
                         add_B_running ? add_B_px4_mem_rd_addr :
                         {SINGLE_MEM_DEPTH_LOG{1'b0}};
 
// write signals for intermediate operands t4 
always @(posedge clk or posedge rst) begin
  if (rst) begin
    counter <= {SINGLE_MEM_DEPTH_LOG{1'b0}};  
    mem_t4_0_wr_en <= 1'b0;
    mem_t4_0_wr_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}}; 
    real_mult_A_start <= 1'b0;
    real_mult_B_start <= 1'b0; 
  end
  else begin
    real_mult_A_start <= mult_A_start;
    real_mult_B_start <= mult_B_start;

    counter <= (start | (counter == (SINGLE_MEM_DEPTH-1))) ? {SINGLE_MEM_DEPTH_LOG{1'b0}} :
               (copy_start | (counter > {SINGLE_MEM_DEPTH_LOG{1'b0}})) ? counter + 1 :
               counter;
    mem_t4_0_wr_en <= copy_start ? 1'b1 :
                      start | (mem_t4_0_wr_en & (counter == {SINGLE_MEM_DEPTH_LOG{1'b0}})) ? 1'b0 :
                      mem_t4_0_wr_en;
    mem_t4_0_wr_addr <= counter; 
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
    copy_start_pre <= 1'b0;
    X4_PLUS_Z4_AND_X4_MINUS_Z4_running <= 1'b0;
    X4_SQUARE_AND_Z4_SQUARE_running <= 1'b0;
    T3_PLUS_T3_AND_T2_PLUS_T2_running <= 1'b0;
    T1_SQUARE_AND_T0_SQUARE_running <= 1'b0;
    T0_PLUS_T0_running <= 1'b0; 
  end
  else begin 
    copy_start_pre <= 1'b0; 
    add_A_start <= 1'b0;
    add_B_start <= 1'b0;
    mult_A_start <= 1'b0;
    mult_B_start <= 1'b0; 
    done <= 1'b0; 
    case (state) 
      IDLE: 
        if (start) begin
          state <= X4_PLUS_Z4_AND_X4_MINUS_Z4;
          X4_PLUS_Z4_AND_X4_MINUS_Z4_running <= 1'b1;
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
          busy <= 1'b1;
        end
        else begin
          state <= IDLE;
        end

      X4_PLUS_Z4_AND_X4_MINUS_Z4: 
        if (add_A_done) begin
          copy_start_pre <= 1'b1;
          state <= X4_SQUARE_AND_Z4_SQUARE;
          X4_PLUS_Z4_AND_X4_MINUS_Z4_running <= 1'b0;
          X4_SQUARE_AND_Z4_SQUARE_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= X4_PLUS_Z4_AND_X4_MINUS_Z4;
        end

      X4_SQUARE_AND_Z4_SQUARE: 
        if (mult_A_done) begin
          state <= T3_PLUS_T3_AND_T2_PLUS_T2;
          X4_SQUARE_AND_Z4_SQUARE_running <= 1'b0;
          T3_PLUS_T3_AND_T2_PLUS_T2_running <= 1'b1; 
          add_A_start <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= state;
        end

      T3_PLUS_T3_AND_T2_PLUS_T2: 
        if (add_A_done) begin
          state <= T1_SQUARE_AND_T0_SQUARE;
          T3_PLUS_T3_AND_T2_PLUS_T2_running <= 1'b0;
          T1_SQUARE_AND_T0_SQUARE_running <= 1'b1;
          mult_A_start <= 1'b1;
          mult_B_start <= 1'b1;
        end
        else begin
          state <= state;
        end

      T1_SQUARE_AND_T0_SQUARE: 
        if (mult_A_done) begin
          state <= T0_PLUS_T0;
          T1_SQUARE_AND_T0_SQUARE_running <= 1'b0;
          T0_PLUS_T0_running <= 1'b1;
          add_B_start <= 1'b1;
        end
        else begin
          state <= state;
        end

      T0_PLUS_T0:  
        if (add_B_done) begin
          state <= IDLE;
          T0_PLUS_T0_running <= 1'b0;  
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


delay #(.WIDTH(1), .DELAY(2)) delay_inst_copy_start (
  .clk(clk),
  .rst(rst),
  .din(copy_start_pre),
  .dout(copy_start)
  );
 
endmodule