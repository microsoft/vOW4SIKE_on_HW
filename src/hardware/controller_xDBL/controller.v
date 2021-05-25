/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testing controller for xDBL
 * 
*/

module controller
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
  output wire busy,
  output wire done,

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

  // interface with output memory t2 
  input wire mem_t2_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t2_0_rd_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t2_0_dout,
 
  input wire mem_t2_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t2_1_rd_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t2_1_dout,

  // interface with output memory t3 
  input wire mem_t3_0_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t3_0_rd_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t3_0_dout,
 
  input wire mem_t3_1_rd_en,
  input wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t3_1_rd_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] mem_t3_1_dout

);

// interface with xDBL_FSM
// interface with intermediate operands t4 
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

// interface with intermediate operands t5 
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

// interface to adder A
wire add_A_start;
wire add_A_busy;
wire add_A_done;

wire [2:0] add_A_cmd;
wire add_A_extension_field_op;

//  memories
wire add_A_mem_a_0_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_a_0_rd_addr; 
wire [RADIX-1:0] add_A_mem_a_0_dout;
wire add_A_mem_a_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_a_1_rd_addr; 
wire [RADIX-1:0] add_A_mem_a_1_dout;

wire add_A_mem_b_0_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_b_0_rd_addr; 
wire [RADIX-1:0] add_A_mem_b_0_dout;

wire add_A_mem_b_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_b_1_rd_addr; 
wire [RADIX-1:0] add_A_mem_b_1_dout;

// result memory
wire add_A_mem_c_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_c_0_rd_addr; 
wire [RADIX-1:0] add_A_mem_c_0_dout; 

wire add_A_mem_c_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_mem_c_1_rd_addr; 
wire [RADIX-1:0] add_A_mem_c_1_dout;

// px2 memory
wire add_A_px2_mem_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_px2_mem_rd_addr;

// px4 memory
wire add_A_px4_mem_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_A_px4_mem_rd_addr;

// interface to adder B
wire add_B_start;
wire add_B_busy;
wire add_B_done;

wire [2:0] add_B_cmd;
wire add_B_extension_field_op;
//  memories
wire add_B_mem_a_0_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_a_0_rd_addr; 
wire [RADIX-1:0] add_B_mem_a_0_dout;

wire add_B_mem_a_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_a_1_rd_addr; 
wire [RADIX-1:0] add_B_mem_a_1_dout;

wire add_B_mem_b_0_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_b_0_rd_addr; 
wire [RADIX-1:0] add_B_mem_b_0_dout;

wire add_B_mem_b_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_b_1_rd_addr; 
wire [RADIX-1:0] add_B_mem_b_1_dout;
// result memory
wire add_B_mem_c_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_c_0_rd_addr; 
wire [RADIX-1:0] add_B_mem_c_0_dout; 

wire add_B_mem_c_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_mem_c_1_rd_addr; 
wire [RADIX-1:0] add_B_mem_c_1_dout;

// px2 memory
wire add_B_px2_mem_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_px2_mem_rd_addr;

// px4 memory
wire add_B_px4_mem_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] add_B_px4_mem_rd_addr;

// interface to multiplier A
wire mult_A_start;
wire mult_A_done;
wire mult_A_busy;

//  memory
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

wire mult_A_mem_c_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_c_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mult_A_mem_c_1_dout; 

// result memory  
wire mult_A_sub_mem_single_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_sub_mem_single_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_A_sub_mem_single_dout;

wire mult_A_add_mem_single_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_add_mem_single_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_A_add_mem_single_dout;

wire mult_A_px2_mem_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_px2_mem_rd_addr; 

// interface to multiplier B
wire mult_B_start;
wire mult_B_done;
wire mult_B_busy;

//  memory
wire mult_B_mem_a_0_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_a_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_a_0_dout;

wire mult_B_mem_a_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_a_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_a_1_dout;

wire mult_B_mem_b_0_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_b_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_0_dout;

wire mult_B_mem_b_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_b_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_1_dout;

wire mult_B_mem_c_1_rd_en; 
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_mem_c_1_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mult_B_mem_c_1_dout; 

// result memory 
wire mult_B_sub_mem_single_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_sub_mem_single_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_B_sub_mem_single_dout;

wire mult_B_add_mem_single_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_add_mem_single_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mult_B_add_mem_single_dout;

wire mult_B_px2_mem_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_B_px2_mem_rd_addr;

// interface to constants memory
wire [SINGLE_MEM_DEPTH_LOG-1:0] p_plus_one_mem_rd_addr;
wire [SINGLE_MEM_DEPTH_LOG-1:0] px2_mem_rd_addr;
wire [SINGLE_MEM_DEPTH_LOG-1:0] px4_mem_rd_addr;

wire [SINGLE_MEM_WIDTH-1:0] p_plus_one_mem_dout;
wire [SINGLE_MEM_WIDTH-1:0] px2_mem_dout;
wire [SINGLE_MEM_WIDTH-1:0] px4_mem_dout;

reg real_mult_A_start;
reg real_mult_B_start;

// specific for squaring logic
reg [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_0_dout_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_1_dout_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_0_dout_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_1_dout_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_0_dout_next_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_A_mem_b_1_dout_next_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_0_dout_next_buf;
reg [SINGLE_MEM_WIDTH-1:0] mult_B_mem_b_1_dout_next_buf;

// result memory in multiplier A
wire mult_A_sub_mult_mem_res_rd_en;
wire [DOUBLE_MEM_DEPTH_LOG-1:0] mult_A_sub_mult_mem_res_rd_addr; 
wire [DOUBLE_MEM_WIDTH-1:0] mult_A_sub_mult_mem_res_dout; 

wire mult_A_add_mult_mem_res_rd_en;
wire [DOUBLE_MEM_DEPTH_LOG-1:0] mult_A_add_mult_mem_res_rd_addr; 
wire [DOUBLE_MEM_WIDTH-1:0] mult_A_add_mult_mem_res_dout;

// result memory in multiplier B
wire mult_B_sub_mult_mem_res_rd_en;
wire [DOUBLE_MEM_DEPTH_LOG-1:0] mult_B_sub_mult_mem_res_rd_addr; 
wire [DOUBLE_MEM_WIDTH-1:0] mult_B_sub_mult_mem_res_dout; 

wire mult_B_add_mult_mem_res_rd_en;
wire [DOUBLE_MEM_DEPTH_LOG-1:0] mult_B_add_mult_mem_res_rd_addr; 
wire [DOUBLE_MEM_WIDTH-1:0] mult_B_add_mult_mem_res_dout;

wire mult_A_used_for_squaring_running;
wire mult_B_used_for_squaring_running;

// needed specifically for squaring logic 

wire mult_A_a_addr_is_b_addr_plus_one;
reg mult_A_a_addr_is_b_addr_plus_one_buf;
wire mult_B_a_addr_is_b_addr_plus_one;
reg mult_B_a_addr_is_b_addr_plus_one_buf;

assign mult_A_a_addr_is_b_addr_plus_one = (mult_A_mem_a_0_rd_addr == (mult_A_mem_b_0_rd_addr + 1)) & mult_A_used_for_squaring_running;
assign mult_B_a_addr_is_b_addr_plus_one = (mult_B_mem_a_0_rd_addr == (mult_B_mem_b_0_rd_addr + 1)) & mult_B_used_for_squaring_running;
 
always @(posedge clk or posedge rst) begin
  if (rst) begin
    mult_A_mem_b_0_dout_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_A_mem_b_1_dout_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_B_mem_b_0_dout_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_B_mem_b_1_dout_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_A_mem_b_0_dout_next_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_A_mem_b_1_dout_next_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_B_mem_b_0_dout_next_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_B_mem_b_1_dout_next_buf <= {SINGLE_MEM_WIDTH{1'b0}};
    mult_A_a_addr_is_b_addr_plus_one_buf <= 1'b0;
    mult_B_a_addr_is_b_addr_plus_one_buf <= 1'b0; 
    real_mult_A_start <= 1'b0;
    real_mult_B_start <= 1'b0;
  end 
  else begin
    real_mult_A_start <= mult_A_start;
    real_mult_B_start <= mult_B_start;

    mult_A_mem_b_0_dout_buf <= (real_mult_A_start & mult_A_used_for_squaring_running) ? add_A_mem_c_0_dout :
                               (mult_A_mem_a_0_rd_addr == 0) & mult_A_used_for_squaring_running ? mult_A_mem_b_0_dout_next_buf :
                               mult_A_mem_b_0_dout_buf;

    mult_A_mem_b_1_dout_buf <= (real_mult_A_start & mult_A_used_for_squaring_running) ? add_A_mem_c_1_dout :
                               (mult_A_mem_a_1_rd_addr == 0) & mult_A_used_for_squaring_running ? mult_A_mem_b_1_dout_next_buf :
                               mult_A_mem_b_1_dout_buf;

    mult_B_mem_b_0_dout_buf <= (real_mult_B_start & mult_B_used_for_squaring_running) ? add_B_mem_c_0_dout :
                               (mult_B_mem_a_0_rd_addr == 0) & mult_B_used_for_squaring_running ? mult_B_mem_b_0_dout_next_buf :
                               mult_B_mem_b_0_dout_buf;

    mult_B_mem_b_1_dout_buf <= (real_mult_B_start & mult_B_used_for_squaring_running) ? add_B_mem_c_1_dout :
                               (mult_B_mem_a_1_rd_addr == 0) & mult_B_used_for_squaring_running ? mult_B_mem_b_1_dout_next_buf :
                               mult_B_mem_b_1_dout_buf;

    mult_A_a_addr_is_b_addr_plus_one_buf <= mult_A_a_addr_is_b_addr_plus_one;
    mult_B_a_addr_is_b_addr_plus_one_buf <= mult_B_a_addr_is_b_addr_plus_one;

    mult_A_mem_b_0_dout_next_buf <= mult_A_a_addr_is_b_addr_plus_one_buf ? mult_A_mem_a_0_dout : mult_A_mem_b_0_dout_next_buf;
    mult_A_mem_b_1_dout_next_buf <= mult_A_a_addr_is_b_addr_plus_one_buf ? mult_A_mem_a_1_dout : mult_A_mem_b_1_dout_next_buf;
    mult_B_mem_b_0_dout_next_buf <= mult_B_a_addr_is_b_addr_plus_one_buf ? mult_B_mem_a_0_dout : mult_B_mem_b_0_dout_next_buf;
    mult_B_mem_b_1_dout_next_buf <= mult_B_a_addr_is_b_addr_plus_one_buf ? mult_B_mem_a_1_dout : mult_B_mem_b_1_dout_next_buf;
     
  end
end

// interface to memory t2
assign mem_t2_0_dout = mult_A_sub_mem_single_dout;
assign mem_t2_1_dout = mult_A_add_mem_single_dout;

// interface to memory t3
assign mem_t3_0_dout = mult_B_sub_mem_single_dout;
assign mem_t3_1_dout = mult_B_add_mem_single_dout;

xDBL_FSM #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL)) xDBL_FSM_inst (
  .rst(rst),
  .clk(clk),
  .start(start),
  .done(done),
  .busy(busy),
  .mem_X_0_dout(mem_X_0_dout),
  .mem_X_0_rd_en(mem_X_0_rd_en),
  .mem_X_0_rd_addr(mem_X_0_rd_addr),
  .mem_X_1_dout(mem_X_1_dout),
  .mem_X_1_rd_en(mem_X_1_rd_en),
  .mem_X_1_rd_addr(mem_X_1_rd_addr),
  .mem_Z_0_dout(mem_Z_0_dout),
  .mem_Z_0_rd_en(mem_Z_0_rd_en),
  .mem_Z_0_rd_addr(mem_Z_0_rd_addr),
  .mem_Z_1_dout(mem_Z_1_dout),
  .mem_Z_1_rd_en(mem_Z_1_rd_en),
  .mem_Z_1_rd_addr(mem_Z_1_rd_addr),
  .mem_A24_0_dout(mem_A24_0_dout),
  .mem_A24_0_rd_en(mem_A24_0_rd_en),
  .mem_A24_0_rd_addr(mem_A24_0_rd_addr), 
  .mem_A24_1_dout(mem_A24_1_dout),
  .mem_A24_1_rd_en(mem_A24_1_rd_en),
  .mem_A24_1_rd_addr(mem_A24_1_rd_addr),
  .mem_C24_0_dout(mem_C24_0_dout),
  .mem_C24_0_rd_en(mem_C24_0_rd_en),
  .mem_C24_0_rd_addr(mem_C24_0_rd_addr),
  .mem_C24_1_dout(mem_C24_1_dout),
  .mem_C24_1_rd_en(mem_C24_1_rd_en),
  .mem_C24_1_rd_addr(mem_C24_1_rd_addr), 
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
  .add_A_start(add_A_start),
  .add_A_busy(add_A_busy),
  .add_A_done(add_A_done),
  .add_A_cmd(add_A_cmd),
  .add_A_extension_field_op(add_A_extension_field_op),
  .add_A_mem_a_0_rd_en(add_A_mem_a_0_rd_en),
  .add_A_mem_a_0_rd_addr(add_A_mem_a_0_rd_addr),
  .add_A_mem_a_0_dout(add_A_mem_a_0_dout),
  .add_A_mem_a_1_rd_en(add_A_mem_a_1_rd_en),
  .add_A_mem_a_1_rd_addr(add_A_mem_a_1_rd_addr),
  .add_A_mem_a_1_dout(add_A_mem_a_1_dout),
  .add_A_mem_b_0_rd_en(add_A_mem_b_0_rd_en),
  .add_A_mem_b_0_rd_addr(add_A_mem_b_0_rd_addr),
  .add_A_mem_b_0_dout(add_A_mem_b_0_dout),
  .add_A_mem_b_1_rd_en(add_A_mem_b_1_rd_en),
  .add_A_mem_b_1_rd_addr(add_A_mem_b_1_rd_addr),
  .add_A_mem_b_1_dout(add_A_mem_b_1_dout),  
  .add_A_mem_c_0_rd_en(add_A_mem_c_0_rd_en),
  .add_A_mem_c_0_rd_addr(add_A_mem_c_0_rd_addr),
  .add_A_mem_c_0_dout(add_A_mem_c_0_dout),
  .add_A_mem_c_1_rd_en(add_A_mem_c_1_rd_en),
  .add_A_mem_c_1_rd_addr(add_A_mem_c_1_rd_addr),
  .add_A_mem_c_1_dout(add_A_mem_c_1_dout),
  .add_A_px2_mem_rd_en(add_A_px2_mem_rd_en),
  .add_A_px2_mem_rd_addr(add_A_px2_mem_rd_addr),
  .add_A_px4_mem_rd_en(add_A_px4_mem_rd_en),
  .add_A_px4_mem_rd_addr(add_A_px4_mem_rd_addr),
  .add_B_start(add_B_start),
  .add_B_busy(add_B_busy),
  .add_B_done(add_B_done),
  .add_B_cmd(add_B_cmd),
  .add_B_extension_field_op(add_B_extension_field_op),
  .add_B_mem_a_0_rd_en(add_B_mem_a_0_rd_en),
  .add_B_mem_a_0_rd_addr(add_B_mem_a_0_rd_addr),
  .add_B_mem_a_0_dout(add_B_mem_a_0_dout),
  .add_B_mem_a_1_rd_en(add_B_mem_a_1_rd_en),
  .add_B_mem_a_1_rd_addr(add_B_mem_a_1_rd_addr),
  .add_B_mem_a_1_dout(add_B_mem_a_1_dout),
  .add_B_mem_b_0_rd_en(add_B_mem_b_0_rd_en),
  .add_B_mem_b_0_rd_addr(add_B_mem_b_0_rd_addr),
  .add_B_mem_b_0_dout(add_B_mem_b_0_dout),
  .add_B_mem_b_1_rd_en(add_B_mem_b_1_rd_en),
  .add_B_mem_b_1_rd_addr(add_B_mem_b_1_rd_addr),
  .add_B_mem_b_1_dout(add_B_mem_b_1_dout),  
  .add_B_mem_c_0_rd_en(add_B_mem_c_0_rd_en),
  .add_B_mem_c_0_rd_addr(add_B_mem_c_0_rd_addr),
  .add_B_mem_c_0_dout(add_B_mem_c_0_dout),
  .add_B_mem_c_1_rd_en(add_B_mem_c_1_rd_en),
  .add_B_mem_c_1_rd_addr(add_B_mem_c_1_rd_addr),
  .add_B_mem_c_1_dout(add_B_mem_c_1_dout),
  .add_B_px2_mem_rd_en(add_B_px2_mem_rd_en),
  .add_B_px2_mem_rd_addr(add_B_px2_mem_rd_addr),
  .add_B_px4_mem_rd_en(add_B_px4_mem_rd_en),
  .add_B_px4_mem_rd_addr(add_B_px4_mem_rd_addr),
  .mult_A_start(mult_A_start),
  .mult_A_done(mult_A_done),
  .mult_A_busy(mult_A_busy),
  .mult_A_mem_a_0_rd_en(mult_A_mem_a_0_rd_en),
  .mult_A_mem_a_0_rd_addr(mult_A_mem_a_0_rd_addr),
  .mult_A_mem_a_0_dout(mult_A_mem_a_0_dout),  
  .mult_A_mem_a_1_rd_en(mult_A_mem_a_1_rd_en),
  .mult_A_mem_a_1_rd_addr(mult_A_mem_a_1_rd_addr),
  .mult_A_mem_a_1_dout(mult_A_mem_a_1_dout),
  .mult_A_mem_b_0_rd_en(mult_A_mem_b_0_rd_en),
  .mult_A_mem_b_0_rd_addr(mult_A_mem_b_0_rd_addr),
  .mult_A_mem_b_0_dout(mult_A_mem_b_0_dout),
  .mult_A_mem_b_1_rd_en(mult_A_mem_b_1_rd_en),
  .mult_A_mem_b_1_rd_addr(mult_A_mem_b_1_rd_addr),
  .mult_A_mem_b_1_dout(mult_A_mem_b_1_dout),
  .mult_A_mem_c_1_rd_en(mult_A_mem_c_1_rd_en),
  .mult_A_mem_c_1_rd_addr(mult_A_mem_c_1_rd_addr),
  .mult_A_mem_c_1_dout(mult_A_mem_c_1_dout),
  .mult_A_sub_mem_single_rd_en(mult_A_sub_mem_single_rd_en),
  .mult_A_sub_mem_single_rd_addr(mult_A_sub_mem_single_rd_addr),
  .mult_A_sub_mem_single_dout(mult_A_sub_mem_single_dout),
  .mult_A_add_mem_single_rd_en(mult_A_add_mem_single_rd_en),  
  .mult_A_add_mem_single_rd_addr(mult_A_add_mem_single_rd_addr),
  .mult_A_add_mem_single_dout(mult_A_add_mem_single_dout),
  .mult_A_px2_mem_rd_en(mult_A_px2_mem_rd_en),
  .mult_A_px2_mem_rd_addr(mult_A_px2_mem_rd_addr),
  .mult_B_start(mult_B_start),
  .mult_B_done(mult_B_done),
  .mult_B_busy(mult_B_busy),
  .mult_B_mem_a_0_rd_en(mult_B_mem_a_0_rd_en),
  .mult_B_mem_a_0_rd_addr(mult_B_mem_a_0_rd_addr),
  .mult_B_mem_a_0_dout(mult_B_mem_a_0_dout),  
  .mult_B_mem_a_1_rd_en(mult_B_mem_a_1_rd_en),
  .mult_B_mem_a_1_rd_addr(mult_B_mem_a_1_rd_addr),
  .mult_B_mem_a_1_dout(mult_B_mem_a_1_dout),
  .mult_B_mem_b_0_rd_en(mult_B_mem_b_0_rd_en),
  .mult_B_mem_b_0_rd_addr(mult_B_mem_b_0_rd_addr),
  .mult_B_mem_b_0_dout(mult_B_mem_b_0_dout),
  .mult_B_mem_b_1_rd_en(mult_B_mem_b_1_rd_en),
  .mult_B_mem_b_1_rd_addr(mult_B_mem_b_1_rd_addr),
  .mult_B_mem_b_1_dout(mult_B_mem_b_1_dout),
  .mult_B_mem_c_1_rd_en(mult_B_mem_c_1_rd_en),
  .mult_B_mem_c_1_rd_addr(mult_B_mem_c_1_rd_addr),
  .mult_B_mem_c_1_dout(mult_B_mem_c_1_dout),
  .mult_B_sub_mem_single_rd_en(mult_B_sub_mem_single_rd_en),
  .mult_B_sub_mem_single_rd_addr(mult_B_sub_mem_single_rd_addr),
  .mult_B_sub_mem_single_dout(mult_B_sub_mem_single_dout),
  .mult_B_add_mem_single_rd_en(mult_B_add_mem_single_rd_en),  
  .mult_B_add_mem_single_rd_addr(mult_B_add_mem_single_rd_addr),
  .mult_B_add_mem_single_dout(mult_B_add_mem_single_dout),
  .mult_B_px2_mem_rd_en(mult_B_px2_mem_rd_en),
  .mult_B_px2_mem_rd_addr(mult_B_px2_mem_rd_addr),
  .p_plus_one_mem_rd_addr(p_plus_one_mem_rd_addr),  
  .px2_mem_rd_addr(px2_mem_rd_addr),
  .px4_mem_rd_addr(px4_mem_rd_addr),
  .p_plus_one_mem_dout(p_plus_one_mem_dout),
  .px2_mem_dout(px2_mem_dout),
  .px4_mem_dout(px4_mem_dout),
  .mult_A_mem_b_0_dout_buf(mult_A_mem_b_0_dout_buf),
  .mult_A_mem_b_1_dout_buf(mult_A_mem_b_1_dout_buf),
  .mult_B_mem_b_0_dout_buf(mult_B_mem_b_0_dout_buf),
  .mult_B_mem_b_1_dout_buf(mult_B_mem_b_1_dout_buf),
  .mult_A_used_for_squaring_running(mult_A_used_for_squaring_running),
  .mult_B_used_for_squaring_running(mult_B_used_for_squaring_running)
  ); 

fp2_sub_add_correction #(.RADIX(RADIX), .DIGITS(WIDTH_REAL)) fp2_sub_add_correction_inst_A (
  .start(add_A_start),
  .rst(rst),
  .clk(clk),
  .cmd(add_A_cmd),
  .extension_field_op(add_A_extension_field_op),
  .mem_a_0_rd_en(add_A_mem_a_0_rd_en),
  .mem_a_0_rd_addr(add_A_mem_a_0_rd_addr),
  .mem_a_0_dout(add_A_mem_a_0_dout),
  .mem_a_1_rd_en(add_A_mem_a_1_rd_en),
  .mem_a_1_rd_addr(add_A_mem_a_1_rd_addr),
  .mem_a_1_dout(add_A_mem_a_1_dout),
  .mem_b_0_rd_en(add_A_mem_b_0_rd_en),
  .mem_b_0_rd_addr(add_A_mem_b_0_rd_addr),
  .mem_b_0_dout(add_A_mem_b_0_dout),
  .mem_b_1_rd_en(add_A_mem_b_1_rd_en),
  .mem_b_1_rd_addr(add_A_mem_b_1_rd_addr),
  .mem_b_1_dout(add_A_mem_b_1_dout),
  .mem_c_0_rd_en(add_A_mem_c_0_rd_en),
  .mem_c_0_rd_addr(add_A_mem_c_0_rd_addr),
  .mem_c_0_dout(add_A_mem_c_0_dout), 
  .mem_c_1_rd_en(add_A_mem_c_1_rd_en),
  .mem_c_1_rd_addr(add_A_mem_c_1_rd_addr),
  .mem_c_1_dout(add_A_mem_c_1_dout), 
  .px2_mem_rd_en(add_A_px2_mem_rd_en),
  .px2_mem_rd_addr(add_A_px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout),
  .px4_mem_rd_en(add_A_px4_mem_rd_en),
  .px4_mem_rd_addr(add_A_px4_mem_rd_addr),
  .px4_mem_dout(px4_mem_dout),
  .busy(add_A_busy),
  .done(add_A_done)
  );

fp2_sub_add_correction #(.RADIX(RADIX), .DIGITS(WIDTH_REAL)) fp2_sub_add_correction_inst_B (
  .start(add_B_start),
  .rst(rst),
  .clk(clk),
  .cmd(add_B_cmd),
  .extension_field_op(add_B_extension_field_op),
  .mem_a_0_rd_en(add_B_mem_a_0_rd_en),
  .mem_a_0_rd_addr(add_B_mem_a_0_rd_addr),
  .mem_a_0_dout(add_B_mem_a_0_dout),
  .mem_a_1_rd_en(add_B_mem_a_1_rd_en),
  .mem_a_1_rd_addr(add_B_mem_a_1_rd_addr),
  .mem_a_1_dout(add_B_mem_a_1_dout),
  .mem_b_0_rd_en(add_B_mem_b_0_rd_en),
  .mem_b_0_rd_addr(add_B_mem_b_0_rd_addr),
  .mem_b_0_dout(add_B_mem_b_0_dout),
  .mem_b_1_rd_en(add_B_mem_b_1_rd_en),
  .mem_b_1_rd_addr(add_B_mem_b_1_rd_addr),
  .mem_b_1_dout(add_B_mem_b_1_dout),
  .mem_c_0_rd_en(add_B_mem_c_0_rd_en),
  .mem_c_0_rd_addr(add_B_mem_c_0_rd_addr),
  .mem_c_0_dout(add_B_mem_c_0_dout), 
  .mem_c_1_rd_en(add_B_mem_c_1_rd_en),
  .mem_c_1_rd_addr(add_B_mem_c_1_rd_addr),
  .mem_c_1_dout(add_B_mem_c_1_dout), 
  .px2_mem_rd_en(add_B_px2_mem_rd_en),
  .px2_mem_rd_addr(add_B_px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout),
  .px4_mem_rd_en(add_B_px4_mem_rd_en),
  .px4_mem_rd_addr(add_B_px4_mem_rd_addr),
  .px4_mem_dout(px4_mem_dout),
  .busy(add_B_busy),
  .done(add_B_done)
  );

// memory storing (p+1)
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL), .FILE(FILE_CONST_P_PLUS_ONE)) single_port_mem_inst_p_plus_one (  
  .clock(clk),
  .data(0),
  .address(p_plus_one_mem_rd_addr),
  .wr_en(0),
  .q(p_plus_one_mem_dout)
  ); 

// memory storing 2*p
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL), .FILE(FILE_CONST_PX2)) single_port_mem_inst_px2 (  
  .clock(clk),
  .data(0),
  .address(px2_mem_rd_addr),
  .wr_en(0),
  .q(px2_mem_dout)
  ); 

// memory storing 4*p
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL), .FILE(FILE_CONST_PX4)) single_port_mem_inst_px4 (  
  .clock(clk),
  .data(0),
  .address(px4_mem_rd_addr),
  .wr_en(1'b0),
  .q(px4_mem_dout)
  );
          
fp2_mont_mul #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL)) fp2_mont_mul_inst_A (
  .rst(rst),
  .clk(clk),
  .start(mult_A_start),
  .done(mult_A_done),
  .busy(mult_A_busy),
  .mem_a_0_rd_en(mult_A_mem_a_0_rd_en),
  .mem_a_0_rd_addr(mult_A_mem_a_0_rd_addr),
  .mem_a_0_dout(mult_A_mem_a_0_dout),
  .mem_a_1_rd_en(mult_A_mem_a_1_rd_en),
  .mem_a_1_rd_addr(mult_A_mem_a_1_rd_addr),
  .mem_a_1_dout(mult_A_mem_a_1_dout),
  .mem_b_0_rd_en(mult_A_mem_b_0_rd_en),
  .mem_b_0_rd_addr(mult_A_mem_b_0_rd_addr),
  .mem_b_0_dout(mult_A_mem_b_0_dout),
  .mem_b_1_rd_en(mult_A_mem_b_1_rd_en),
  .mem_b_1_rd_addr(mult_A_mem_b_1_rd_addr),
  .mem_b_1_dout(mult_A_mem_b_1_dout),
  .mem_c_1_rd_en(mult_A_mem_c_1_rd_en),
  .mem_c_1_rd_addr(mult_A_mem_c_1_rd_addr),
  .mem_c_1_dout(mult_A_mem_c_1_dout), 
  .sub_mult_mem_res_rd_en(mult_A_sub_mult_mem_res_rd_en),
  .sub_mult_mem_res_rd_addr(mult_A_sub_mult_mem_res_rd_addr),
  .sub_mult_mem_res_dout(mult_A_sub_mult_mem_res_dout),
  .add_mult_mem_res_rd_en(mult_A_add_mult_mem_res_rd_en),
  .add_mult_mem_res_rd_addr(mult_A_add_mult_mem_res_rd_addr),
  .add_mult_mem_res_dout(mult_A_add_mult_mem_res_dout),
  .px2_mem_rd_en(mult_A_px2_mem_rd_en),
  .px2_mem_rd_addr(mult_A_px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout)
);

fp2_mont_mul #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL)) fp2_mont_mul_inst_B (
  .rst(rst),
  .clk(clk),
  .start(mult_A_start),
  .done(mult_B_done),
  .busy(mult_B_busy),
  .mem_a_0_rd_en(mult_B_mem_a_0_rd_en),
  .mem_a_0_rd_addr(mult_B_mem_a_0_rd_addr),
  .mem_a_0_dout(mult_B_mem_a_0_dout),
  .mem_a_1_rd_en(mult_B_mem_a_1_rd_en),
  .mem_a_1_rd_addr(mult_B_mem_a_1_rd_addr),
  .mem_a_1_dout(mult_B_mem_a_1_dout),
  .mem_b_0_rd_en(mult_B_mem_b_0_rd_en),
  .mem_b_0_rd_addr(mult_B_mem_b_0_rd_addr),
  .mem_b_0_dout(mult_B_mem_b_0_dout),
  .mem_b_1_rd_en(mult_B_mem_b_1_rd_en),
  .mem_b_1_rd_addr(mult_B_mem_b_1_rd_addr),
  .mem_b_1_dout(mult_B_mem_b_1_dout),
  .mem_c_1_rd_en(mult_B_mem_c_1_rd_en),
  .mem_c_1_rd_addr(mult_B_mem_c_1_rd_addr),
  .mem_c_1_dout(mult_B_mem_c_1_dout), 
  .sub_mult_mem_res_rd_en(mult_B_sub_mult_mem_res_rd_en),
  .sub_mult_mem_res_rd_addr(mult_B_sub_mult_mem_res_rd_addr),
  .sub_mult_mem_res_dout(mult_B_sub_mult_mem_res_dout),
  .add_mult_mem_res_rd_en(mult_B_add_mult_mem_res_rd_en),
  .add_mult_mem_res_rd_addr(mult_B_add_mult_mem_res_rd_addr),
  .add_mult_mem_res_dout(mult_B_add_mult_mem_res_dout),
  .px2_mem_rd_en(mult_B_px2_mem_rd_en),
  .px2_mem_rd_addr(mult_B_px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout)
);

single_to_double_memory_wrapper #(.SINGLE_MEM_WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) single_to_double_memory_wrapper_inst_sub_A (
  .rst(rst),
  .clk(clk),
  .single_mem_rd_en(mem_t2_0_rd_en | mult_A_sub_mem_single_rd_en),
  .single_mem_rd_addr(mem_t2_0_rd_en ? mem_t2_0_rd_addr : mult_A_sub_mem_single_rd_addr),
  .single_mem_dout(mult_A_sub_mem_single_dout),
  .double_mem_rd_en(mult_A_sub_mult_mem_res_rd_en),
  .double_mem_rd_addr(mult_A_sub_mult_mem_res_rd_addr),
  .double_mem_dout(mult_A_sub_mult_mem_res_dout)
  );

single_to_double_memory_wrapper #(.SINGLE_MEM_WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) single_to_double_memory_wrapper_inst_add_A (
  .rst(rst),
  .clk(clk),
  .single_mem_rd_en(mem_t2_1_rd_en | mult_A_add_mem_single_rd_en),
  .single_mem_rd_addr(mem_t2_1_rd_en ? mem_t2_1_rd_addr : mult_A_add_mem_single_rd_addr),
  .single_mem_dout(mult_A_add_mem_single_dout),
  .double_mem_rd_en(mult_A_add_mult_mem_res_rd_en),
  .double_mem_rd_addr(mult_A_add_mult_mem_res_rd_addr),
  .double_mem_dout(mult_A_add_mult_mem_res_dout)
  );
 
 single_to_double_memory_wrapper #(.SINGLE_MEM_WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) single_to_double_memory_wrapper_inst_sub_B (
  .rst(rst),
  .clk(clk),
  .single_mem_rd_en(mem_t3_0_rd_en | mult_B_sub_mem_single_rd_en),
  .single_mem_rd_addr(mem_t3_0_rd_en ? mem_t3_0_rd_addr : mult_B_sub_mem_single_rd_addr),
  .single_mem_dout(mult_B_sub_mem_single_dout),
  .double_mem_rd_en(mult_B_sub_mult_mem_res_rd_en),
  .double_mem_rd_addr(mult_B_sub_mult_mem_res_rd_addr),
  .double_mem_dout(mult_B_sub_mult_mem_res_dout)
  );

single_to_double_memory_wrapper #(.SINGLE_MEM_WIDTH(RADIX), .SINGLE_MEM_DEPTH(WIDTH_REAL)) single_to_double_memory_wrapper_inst_add_B (
  .rst(rst),
  .clk(clk),
  .single_mem_rd_en(mem_t3_1_rd_en | mult_B_add_mem_single_rd_en),
  .single_mem_rd_addr(mem_t3_1_rd_en ? mem_t3_1_rd_addr : mult_B_add_mem_single_rd_addr),
  .single_mem_dout(mult_B_add_mem_single_dout),
  .double_mem_rd_en(mult_B_add_mult_mem_res_rd_en),
  .double_mem_rd_addr(mult_B_add_mult_mem_res_rd_addr),
  .double_mem_dout(mult_B_add_mult_mem_res_dout)
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

endmodule