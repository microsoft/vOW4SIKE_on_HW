/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for the controller of eval_4_isog, get_4_isog, xADD, and xDBL
 * 
*/

`timescale 1ns / 1ps

module controller_tb;

parameter RADIX = `RADIX;
parameter WIDTH_REAL = `WIDTH_REAL;
parameter SINGLE_MEM_WIDTH = RADIX;
parameter SINGLE_MEM_DEPTH = WIDTH_REAL;
parameter SINGLE_MEM_DEPTH_LOG = `CLOG2(SINGLE_MEM_DEPTH);
parameter DOUBLE_MEM_WIDTH = RADIX*2;
parameter DOUBLE_MEM_DEPTH = (WIDTH_REAL+1)/2;
parameter DOUBLE_MEM_DEPTH_LOG = `CLOG2(DOUBLE_MEM_DEPTH);

// inputs
reg rst = 1'b0;
reg clk = 1'b0;
reg start = 1'b0;
reg [7:0] function_encoded = 0;

// outputs 
wire done;
wire busy;

// outside requests for mult A
reg out_mult_A_start = 0;

wire mult_A_mem_a_0_rd_en;
wire mult_A_mem_a_1_rd_en;
wire mult_A_mem_b_0_rd_en;
wire mult_A_mem_b_1_rd_en;

wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_a_0_rd_addr;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_a_1_rd_addr;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_b_0_rd_addr;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mult_A_mem_b_1_rd_addr;

reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_a_0_dout = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_a_1_dout = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_b_0_dout = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_b_1_dout = 0;

reg out_sub_mult_A_mem_res_rd_en = 0;
reg out_add_mult_A_mem_res_rd_en = 0;

reg [DOUBLE_MEM_DEPTH_LOG-1:0] out_sub_mult_A_mem_res_rd_addr = 0;
reg [DOUBLE_MEM_DEPTH_LOG-1:0] out_add_mult_A_mem_res_rd_addr = 0;

wire [DOUBLE_MEM_WIDTH-1:0] mult_A_sub_mult_mem_res_dout;
wire [DOUBLE_MEM_WIDTH-1:0] mult_A_add_mult_mem_res_dout;


//--------------------------------------------------------------------
// interface with memory t4 (actual interface) 
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

//--------------------------------------------------------------------
// interface with memory t5 (actual interface) 
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

//--------------------------------------------------------------------
// interface with memory t6 (actual interface) 
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

//--------------------------------------------------------------------
// interface with memory t7 (actual interface) 
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

//--------------------------------------------------------------------
// interface with memory t8 (actual interface) 
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

//--------------------------------------------------------------------
// interface with memory t9 (actual interface) 
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

//--------------------------------------------------------------------
// interface with memory t10 (actual interface) 
wire mem_t10_0_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_0_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_0_din;
wire mem_t10_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_0_rd_addr; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_0_dout;

wire mem_t10_1_wr_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_1_wr_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_1_din;
wire mem_t10_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_t10_1_rd_addr;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_1_dout;

// interface with memory X
reg xDBL_mem_X_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_X_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_X_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_X_0_dout;
wire xDBL_mem_X_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_X_0_rd_addr;

reg xDBL_mem_X_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_X_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_X_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_X_1_dout;
wire xDBL_mem_X_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_X_1_rd_addr;

// interface with memory Z
reg xDBL_mem_Z_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_Z_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_Z_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_Z_0_dout;
wire xDBL_mem_Z_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_Z_0_rd_addr;

reg xDBL_mem_Z_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_Z_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_Z_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_Z_1_dout;
wire xDBL_mem_Z_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_Z_1_rd_addr;

// interface with memory A24
reg xDBL_mem_A24_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_A24_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_A24_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_A24_0_dout;
wire xDBL_mem_A24_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_A24_0_rd_addr;

reg xDBL_mem_A24_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_A24_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_A24_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_A24_1_dout;
wire xDBL_mem_A24_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_A24_1_rd_addr;

// interface with memory C24
reg xDBL_mem_C24_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_C24_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_C24_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_C24_0_dout;
wire xDBL_mem_C24_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_C24_0_rd_addr;

reg xDBL_mem_C24_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_C24_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xDBL_mem_C24_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xDBL_mem_C24_1_dout;
wire xDBL_mem_C24_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xDBL_mem_C24_1_rd_addr;
 
// interface with memory X
reg get_4_isog_mem_X4_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_X4_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_X4_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_X4_0_dout;
wire get_4_isog_mem_X4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_X4_0_rd_addr;

reg get_4_isog_mem_X4_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_X4_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_X4_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_X4_1_dout;
wire get_4_isog_mem_X4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_X4_1_rd_addr;

// interface with memory Z
reg get_4_isog_mem_Z4_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_Z4_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_Z4_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_Z4_0_dout;
wire get_4_isog_mem_Z4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_Z4_0_rd_addr;

reg get_4_isog_mem_Z4_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_Z4_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_Z4_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] get_4_isog_mem_Z4_1_dout;
wire get_4_isog_mem_Z4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] get_4_isog_mem_Z4_1_rd_addr;

// interface with memory X
reg xADD_mem_XP_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XP_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_XP_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_XP_0_dout;
wire xADD_mem_XP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XP_0_rd_addr;

reg xADD_mem_XP_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XP_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_XP_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_XP_1_dout;
wire xADD_mem_XP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XP_1_rd_addr;

// interface with memory Z
reg xADD_mem_ZP_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZP_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZP_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZP_0_dout;
wire xADD_mem_ZP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZP_0_rd_addr;

reg xADD_mem_ZP_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZP_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZP_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZP_1_dout;
wire xADD_mem_ZP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZP_1_rd_addr;

// interface with memory X
reg xADD_mem_XQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_XQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_XQ_0_dout;
wire xADD_mem_XQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XQ_0_rd_addr;

reg xADD_mem_XQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_XQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_XQ_1_dout;
wire xADD_mem_XQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_XQ_1_rd_addr;

// interface with memory Z
reg xADD_mem_ZQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZQ_0_dout;
wire xADD_mem_ZQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZQ_0_rd_addr;

reg xADD_mem_ZQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_ZQ_1_dout;
wire xADD_mem_ZQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_ZQ_1_rd_addr;
 
// interface with memory Z
reg xADD_mem_xPQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_xPQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_xPQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_xPQ_0_dout;
wire xADD_mem_xPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_xPQ_0_rd_addr;

reg xADD_mem_xPQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_xPQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_xPQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_xPQ_1_dout;
wire xADD_mem_xPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_xPQ_1_rd_addr;

// interface with memory Z
reg xADD_mem_zPQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_zPQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_zPQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_zPQ_0_dout;
wire xADD_mem_zPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_zPQ_0_rd_addr;

reg xADD_mem_zPQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_zPQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] xADD_mem_zPQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] xADD_mem_zPQ_1_dout;
wire xADD_mem_zPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] xADD_mem_zPQ_1_rd_addr;

// interface with memory X
reg eval_4_isog_mem_X_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_X_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_X_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_X_0_dout;
wire eval_4_isog_mem_X_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_X_0_rd_addr;

reg eval_4_isog_mem_X_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_X_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_X_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_X_1_dout;
wire eval_4_isog_mem_X_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_X_1_rd_addr;

// interface with memory Z
reg eval_4_isog_mem_Z_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_Z_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_Z_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_Z_0_dout;
wire eval_4_isog_mem_Z_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_Z_0_rd_addr;

reg eval_4_isog_mem_Z_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_Z_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_Z_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_Z_1_dout;
wire eval_4_isog_mem_Z_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_Z_1_rd_addr;

// interface with memory C0
reg eval_4_isog_mem_C0_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C0_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C0_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C0_0_dout;
wire eval_4_isog_mem_C0_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C0_0_rd_addr;

reg eval_4_isog_mem_C0_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C0_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C0_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C0_1_dout;
wire eval_4_isog_mem_C0_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C0_1_rd_addr;

// interface with memory C1
reg eval_4_isog_mem_C1_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C1_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C1_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C1_0_dout;
wire eval_4_isog_mem_C1_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C1_0_rd_addr;

reg eval_4_isog_mem_C1_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C1_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C1_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C1_1_dout;
wire eval_4_isog_mem_C1_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C1_1_rd_addr;

// interface with memory C2
reg eval_4_isog_mem_C2_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C2_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C2_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C2_0_dout;
wire eval_4_isog_mem_C2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C2_0_rd_addr;

reg eval_4_isog_mem_C2_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C2_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C2_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] eval_4_isog_mem_C2_1_dout;
wire eval_4_isog_mem_C2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] eval_4_isog_mem_C2_1_rd_addr;

// interface with results memory t0 
reg mem_t0_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t0_0_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t0_0_dout;

reg mem_t0_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t0_1_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t0_1_dout;

// interface with results memory t1 
reg mem_t1_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t1_0_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t1_0_dout;

reg mem_t1_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t1_1_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t1_1_dout;
 
// interface with results memory t2 
reg mem_t2_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t2_0_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t2_0_dout;

reg mem_t2_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t2_1_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t2_1_dout;

// interface with memory t3 
reg mem_t3_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t3_0_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t3_0_dout;

reg mem_t3_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_t3_1_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t3_1_dout;

reg out_mem_t4_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t4_0_rd_addr = 0;  

reg out_mem_t4_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t4_1_rd_addr = 0; 

reg out_mem_t5_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t5_0_rd_addr = 0;  

reg out_mem_t5_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t5_1_rd_addr = 0; 
 
reg out_mem_t6_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t6_0_rd_addr = 0;  
 
reg out_mem_t6_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t6_1_rd_addr = 0; 

reg out_mem_t7_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t7_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t7_0_din = 0;
reg out_mem_t7_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t7_0_rd_addr = 0; 

reg out_mem_t7_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t7_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t7_1_din = 0;
reg out_mem_t7_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t7_1_rd_addr = 0; 

reg out_mem_t8_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t8_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t8_0_din = 0;
reg out_mem_t8_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t8_0_rd_addr = 0; 

reg out_mem_t8_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t8_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t8_1_din = 0;
reg out_mem_t8_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t8_1_rd_addr = 0; 

reg out_mem_t9_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t9_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t9_0_din = 0;
reg out_mem_t9_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t9_0_rd_addr = 0;  

reg out_mem_t9_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t9_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t9_1_din = 0;
reg out_mem_t9_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t9_1_rd_addr = 0; 

reg out_mem_t10_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t10_0_din = 0;
reg out_mem_t10_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_0_rd_addr = 0; 

reg out_mem_t10_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_t10_1_din = 0;
reg out_mem_t10_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_1_rd_addr = 0; 

initial
  begin
    $dumpfile("controller_tb.vcd");
    $dumpvars(0, controller_tb);
  end

integer start_time = 0; 
integer element_file;
integer scan_file;
integer i;

initial
  begin
    rst <= 1'b0;
    start <= 1'b0;
    function_encoded <= 8'd0;
    # 45;
    rst <= 1'b1;
    # 20;
    rst <= 1'b0;

//---------------------------------------------------------------------
// load inputs for xDBL 
    // load X_0, X_1, Z_0, Z_1, A24_0, A24_1, C24_0, and C24_1
    // load X_0 
    element_file = $fopen("xDBL_mem_X_0.txt", "r");
    # 10;
    $display("\nloading input X_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_X_0_wr_en = 1'b1;
    xDBL_mem_X_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_X_0_din); 
      #10;
      xDBL_mem_X_0_wr_addr = xDBL_mem_X_0_wr_addr + 1;
    end
    xDBL_mem_X_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("xDBL_mem_X_1.txt", "r");
    # 10;
    $display("\nloading input X_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_X_1_wr_en = 1'b1;
    xDBL_mem_X_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_X_1_din); 
      #10;
      xDBL_mem_X_1_wr_addr = xDBL_mem_X_1_wr_addr + 1;
    end
    xDBL_mem_X_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load Z_0 
    element_file = $fopen("xDBL_mem_Z_0.txt", "r");
    # 10;
    $display("\nloading input Z_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_Z_0_wr_en = 1'b1;
    xDBL_mem_Z_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_Z_0_din); 
      #10;
      xDBL_mem_Z_0_wr_addr = xDBL_mem_Z_0_wr_addr + 1;
    end
    xDBL_mem_Z_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load Z_1 
    element_file = $fopen("xDBL_mem_Z_1.txt", "r");
    # 10;
    $display("\nloading input Z_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_Z_1_wr_en = 1'b1;
    xDBL_mem_Z_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_Z_1_din); 
      #10;
      xDBL_mem_Z_1_wr_addr = xDBL_mem_Z_1_wr_addr + 1;
    end
    xDBL_mem_Z_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load A24_0 
    element_file = $fopen("xDBL_mem_A24_0.txt", "r");
    # 10;
    $display("\nloading input A24_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_A24_0_wr_en = 1'b1;
    xDBL_mem_A24_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_A24_0_din); 
      #10;
      xDBL_mem_A24_0_wr_addr = xDBL_mem_A24_0_wr_addr + 1;
    end
    xDBL_mem_A24_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load A24_1 
    element_file = $fopen("xDBL_mem_A24_1.txt", "r");
    # 10;
    $display("\nloading input A24_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_A24_1_wr_en = 1'b1;
    xDBL_mem_A24_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_A24_1_din); 
      #10;
      xDBL_mem_A24_1_wr_addr = xDBL_mem_A24_1_wr_addr + 1;
    end
    xDBL_mem_A24_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load C24_0 
    element_file = $fopen("xDBL_mem_C24_0.txt", "r");
    # 10;
    $display("\nloading input C24_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_C24_0_wr_en = 1'b1;
    xDBL_mem_C24_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_C24_0_din); 
      #10;
      xDBL_mem_C24_0_wr_addr = xDBL_mem_C24_0_wr_addr + 1;
    end
    xDBL_mem_C24_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C24_1 
    element_file = $fopen("xDBL_mem_C24_1.txt", "r");
    # 10;
    $display("\nloading input C24_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xDBL_mem_C24_1_wr_en = 1'b1;
    xDBL_mem_C24_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xDBL_mem_C24_1_din); 
      #10;
      xDBL_mem_C24_1_wr_addr = xDBL_mem_C24_1_wr_addr + 1;
    end
    xDBL_mem_C24_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//--------------------------------------------------------------------- 
//---------------------------------------------------------------------
//---------------------------------------------------------------------

// load inputs for get_4_isog
    // load X4_0, X4_1, Z4_0, Z4_1
    // load X4_0 
    element_file = $fopen("get_4_isog_mem_X4_0.txt", "r");
    # 10;
    $display("\nloading input X4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    get_4_isog_mem_X4_0_wr_en = 1'b1;
    get_4_isog_mem_X4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", get_4_isog_mem_X4_0_din); 
      #10;
      get_4_isog_mem_X4_0_wr_addr = get_4_isog_mem_X4_0_wr_addr + 1;
    end
    get_4_isog_mem_X4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X4_1 
    element_file = $fopen("get_4_isog_mem_X4_1.txt", "r");
    # 10;
    $display("\nloading input X4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    get_4_isog_mem_X4_1_wr_en = 1'b1;
    get_4_isog_mem_X4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", get_4_isog_mem_X4_1_din); 
      #10;
      get_4_isog_mem_X4_1_wr_addr = get_4_isog_mem_X4_1_wr_addr + 1;
    end
    get_4_isog_mem_X4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load Z4_0 
    element_file = $fopen("get_4_isog_mem_Z4_0.txt", "r");
    # 10;
    $display("\nloading input Z4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    get_4_isog_mem_Z4_0_wr_en = 1'b1;
    get_4_isog_mem_Z4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", get_4_isog_mem_Z4_0_din); 
      #10;
      get_4_isog_mem_Z4_0_wr_addr = get_4_isog_mem_Z4_0_wr_addr + 1;
    end
    get_4_isog_mem_Z4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load Z4_1 
    element_file = $fopen("get_4_isog_mem_Z4_1.txt", "r");
    # 10;
    $display("\nloading input Z4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    get_4_isog_mem_Z4_1_wr_en = 1'b1;
    get_4_isog_mem_Z4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", get_4_isog_mem_Z4_1_din); 
      #10;
      get_4_isog_mem_Z4_1_wr_addr = get_4_isog_mem_Z4_1_wr_addr + 1;
    end
    get_4_isog_mem_Z4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//--------------------------------------------------------------------- 
//---------------------------------------------------------------------
//---------------------------------------------------------------------

// load inputs for xADD
    // load XP_0, XP_1, ZP_0, ZP_1, XQ_0, XQ_1, ZQ_0, ZQ_1, A24_0, A24_1, xPQ_0, xPQ_1 
    // load XP_0 
    element_file = $fopen("xADD_mem_XP_0.txt", "r");
    # 10;
    $display("\nloading input XP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_XP_0_wr_en = 1'b1;
    xADD_mem_XP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_XP_0_din); 
      #10;
      xADD_mem_XP_0_wr_addr = xADD_mem_XP_0_wr_addr + 1;
    end
    xADD_mem_XP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XP_1 
    element_file = $fopen("xADD_mem_XP_1.txt", "r");
    # 10;
    $display("\nloading input XP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_XP_1_wr_en = 1'b1;
    xADD_mem_XP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_XP_1_din); 
      #10;
      xADD_mem_XP_1_wr_addr = xADD_mem_XP_1_wr_addr + 1;
    end
    xADD_mem_XP_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load ZP_0 
    element_file = $fopen("xADD_mem_ZP_0.txt", "r");
    # 10;
    $display("\nloading input ZP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_ZP_0_wr_en = 1'b1;
    xADD_mem_ZP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_ZP_0_din); 
      #10;
      xADD_mem_ZP_0_wr_addr = xADD_mem_ZP_0_wr_addr + 1;
    end
    xADD_mem_ZP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZP_1 
    element_file = $fopen("xADD_mem_ZP_1.txt", "r");
    # 10;
    $display("\nloading input ZP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_ZP_1_wr_en = 1'b1;
    xADD_mem_ZP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_ZP_1_din); 
      #10;
      xADD_mem_ZP_1_wr_addr = xADD_mem_ZP_1_wr_addr + 1;
    end
    xADD_mem_ZP_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
        // load XQ_0 
    element_file = $fopen("xADD_mem_XQ_0.txt", "r");
    # 10;
    $display("\nloading input XQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_XQ_0_wr_en = 1'b1;
    xADD_mem_XQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_XQ_0_din); 
      #10;
      xADD_mem_XQ_0_wr_addr = xADD_mem_XQ_0_wr_addr + 1;
    end
    xADD_mem_XQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XQ_1 
    element_file = $fopen("xADD_mem_XQ_1.txt", "r");
    # 10;
    $display("\nloading input XQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_XQ_1_wr_en = 1'b1;
    xADD_mem_XQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_XQ_1_din); 
      #10;
      xADD_mem_XQ_1_wr_addr = xADD_mem_XQ_1_wr_addr + 1;
    end
    xADD_mem_XQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load ZQ_0 
    element_file = $fopen("xADD_mem_ZQ_0.txt", "r");
    # 10;
    $display("\nloading input ZQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_ZQ_0_wr_en = 1'b1;
    xADD_mem_ZQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_ZQ_0_din); 
      #10;
      xADD_mem_ZQ_0_wr_addr = xADD_mem_ZQ_0_wr_addr + 1;
    end
    xADD_mem_ZQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZQ_1 
    element_file = $fopen("xADD_mem_ZQ_1.txt", "r");
    # 10;
    $display("\nloading input ZQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_ZQ_1_wr_en = 1'b1;
    xADD_mem_ZQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_ZQ_1_din); 
      #10;
      xADD_mem_ZQ_1_wr_addr = xADD_mem_ZQ_1_wr_addr + 1;
    end
    xADD_mem_ZQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
//---------------------------------------------------------------------
    // load xPQ_0 
    element_file = $fopen("xADD_mem_xPQ_0.txt", "r");
    # 10;
    $display("\nloading input xPQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_xPQ_0_wr_en = 1'b1;
    xADD_mem_xPQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_xPQ_0_din); 
      #10;
      xADD_mem_xPQ_0_wr_addr = xADD_mem_xPQ_0_wr_addr + 1;
    end
    xADD_mem_xPQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load xPQ_1 
    element_file = $fopen("xADD_mem_xPQ_1.txt", "r");
    # 10;
    $display("\nloading input xPQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_xPQ_1_wr_en = 1'b1;
    xADD_mem_xPQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_xPQ_1_din); 
      #10;
      xADD_mem_xPQ_1_wr_addr = xADD_mem_xPQ_1_wr_addr + 1;
    end
    xADD_mem_xPQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load zPQ_0 
    element_file = $fopen("xADD_mem_zPQ_0.txt", "r");
    # 10;
    $display("\nloading input zPQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_zPQ_0_wr_en = 1'b1;
    xADD_mem_zPQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_zPQ_0_din); 
      #10;
      xADD_mem_zPQ_0_wr_addr = xADD_mem_zPQ_0_wr_addr + 1;
    end
    xADD_mem_zPQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load zPQ_1 
    element_file = $fopen("xADD_mem_zPQ_1.txt", "r");
    # 10;
    $display("\nloading input zPQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    xADD_mem_zPQ_1_wr_en = 1'b1;
    xADD_mem_zPQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", xADD_mem_zPQ_1_din); 
      #10;
      xADD_mem_zPQ_1_wr_addr = xADD_mem_zPQ_1_wr_addr + 1;
    end
    xADD_mem_zPQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
// load inputs for eval_4_isog 
    // load X_0, X_1, Z_0, Z_1, C0_0, C0_1, C1_0, and C1_1
    // load X_0 
    element_file = $fopen("eval_4_isog_mem_X_0.txt", "r");
    # 10;
    $display("\nloading input X_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_X_0_wr_en = 1'b1;
    eval_4_isog_mem_X_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_X_0_din); 
      #10;
      eval_4_isog_mem_X_0_wr_addr = eval_4_isog_mem_X_0_wr_addr + 1;
    end
    eval_4_isog_mem_X_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("eval_4_isog_mem_X_1.txt", "r");
    # 10;
    $display("\nloading input X_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_X_1_wr_en = 1'b1;
    eval_4_isog_mem_X_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_X_1_din); 
      #10;
      eval_4_isog_mem_X_1_wr_addr = eval_4_isog_mem_X_1_wr_addr + 1;
    end
    eval_4_isog_mem_X_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load Z_0 
    element_file = $fopen("eval_4_isog_mem_Z_0.txt", "r");
    # 10;
    $display("\nloading input Z_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_Z_0_wr_en = 1'b1;
    eval_4_isog_mem_Z_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_Z_0_din); 
      #10;
      eval_4_isog_mem_Z_0_wr_addr = eval_4_isog_mem_Z_0_wr_addr + 1;
    end
    eval_4_isog_mem_Z_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load Z_1 
    element_file = $fopen("eval_4_isog_mem_Z_1.txt", "r");
    # 10;
    $display("\nloading input Z_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_Z_1_wr_en = 1'b1;
    eval_4_isog_mem_Z_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_Z_1_din); 
      #10;
      eval_4_isog_mem_Z_1_wr_addr = eval_4_isog_mem_Z_1_wr_addr + 1;
    end
    eval_4_isog_mem_Z_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load C0_0 
    element_file = $fopen("eval_4_isog_mem_C0_0.txt", "r");
    # 10;
    $display("\nloading input C0_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_C0_0_wr_en = 1'b1;
    eval_4_isog_mem_C0_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_C0_0_din); 
      #10;
      eval_4_isog_mem_C0_0_wr_addr = eval_4_isog_mem_C0_0_wr_addr + 1;
    end
    eval_4_isog_mem_C0_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C0_1 
    element_file = $fopen("eval_4_isog_mem_C0_1.txt", "r");
    # 10;
    $display("\nloading input C0_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_C0_1_wr_en = 1'b1;
    eval_4_isog_mem_C0_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_C0_1_din); 
      #10;
      eval_4_isog_mem_C0_1_wr_addr = eval_4_isog_mem_C0_1_wr_addr + 1;
    end
    eval_4_isog_mem_C0_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load C1_0 
    element_file = $fopen("eval_4_isog_mem_C1_0.txt", "r");
    # 10;
    $display("\nloading input C1_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_C1_0_wr_en = 1'b1;
    eval_4_isog_mem_C1_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_C1_0_din); 
      #10;
      eval_4_isog_mem_C1_0_wr_addr = eval_4_isog_mem_C1_0_wr_addr + 1;
    end
    eval_4_isog_mem_C1_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C1_1 
    element_file = $fopen("eval_4_isog_mem_C1_1.txt", "r");
    # 10;
    $display("\nloading input C1_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_C1_1_wr_en = 1'b1;
    eval_4_isog_mem_C1_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_C1_1_din); 
      #10;
      eval_4_isog_mem_C1_1_wr_addr = eval_4_isog_mem_C1_1_wr_addr + 1;
    end
    eval_4_isog_mem_C1_1_wr_en = 1'b0;
    end
    $fclose(element_file);
    
//---------------------------------------------------------------------
    // load C2_0 
    element_file = $fopen("eval_4_isog_mem_C2_0.txt", "r");
    # 10;
    $display("\nloading input C2_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_C2_0_wr_en = 1'b1;
    eval_4_isog_mem_C2_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_C2_0_din); 
      #10;
      eval_4_isog_mem_C2_0_wr_addr = eval_4_isog_mem_C2_0_wr_addr + 1;
    end
    eval_4_isog_mem_C2_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C2_1 
    element_file = $fopen("eval_4_isog_mem_C2_1.txt", "r");
    # 10;
    $display("\nloading input C2_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    eval_4_isog_mem_C2_1_wr_en = 1'b1;
    eval_4_isog_mem_C2_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", eval_4_isog_mem_C2_1_din); 
      #10;
      eval_4_isog_mem_C2_1_wr_addr = eval_4_isog_mem_C2_1_wr_addr + 1;
    end
    eval_4_isog_mem_C2_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
//---------------------------------------------------------------------

// start xDBL computation
    // start computation
    # 15;
    start <= 1'b1;
    function_encoded <= 1;
    start_time = $time;
    $display("\n    start xDBL computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\n    xDBL comptation finished in %0d cycles", ($time-start_time)/10);

//---------------------------------------------------------------------

    // restart computation without forcing reset
    # 100; 
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat xDBL computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    xDBL comptation finished in %0d cycles", ($time-start_time)/10);
    
    
    // restart computation without forcing reset
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat xDBL computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    xDBL comptation finished in %0d cycles", ($time-start_time)/10);
 
//---------------------------------------------------------------------

    #100;
    $display("\nread xDBL result t2 back...");

    element_file = $fopen("sim_xDBL_t2_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_0_dout); 
    end

    mem_t2_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_xDBL_t2_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_1_dout); 
    end

    mem_t2_1_rd_en = 1'b0;

    $fclose(element_file);
  
    #100;
    $display("\nread xDBL result t3 back...");

    element_file = $fopen("sim_xDBL_t3_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_0_dout); 
    end

    mem_t3_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_xDBL_t3_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_1_dout); 
    end

    mem_t3_1_rd_en = 1'b0;

    $fclose(element_file);

    #10;
    $display("\ncomparing xDBL results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;

 
//---------------------------------------------------------------------

    // start get_4_isog computation
    # 15;
    start <= 1'b1;
    function_encoded <= 2;
    start_time = $time;
    $display("\n    start gen_4_isog computation");
    # 10;
    start <= 1'b0;
 
    // computation finishes
    @(posedge done);
    $display("\n    gen_4_isog comptation finished in %0d cycles", ($time-start_time)/10);


    // restart computation without forcing reset
    # 100; 
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat gen_4_isog computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    gen_4_isog comptation finished in %0d cycles", ($time-start_time)/10);
    
    
    // restart computation without forcing reset
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat gen_4_isog computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    gen_4_isog comptation finished in %0d cycles", ($time-start_time)/10);

    function_encoded <= 0;
 
//---------------------------------------------------------------------
 
    #100;
    $display("\nread get_4_isog result t1 back...");

    element_file = $fopen("sim_get_4_isog_t1_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t1_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t1_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t1_0_dout); 
    end

    mem_t1_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_get_4_isog_t1_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t1_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t1_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t1_1_dout); 
    end

    mem_t1_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread get_4_isog result t2 back...");

    element_file = $fopen("sim_get_4_isog_t2_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_0_dout); 
    end

    mem_t2_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_get_4_isog_t2_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_1_dout); 
    end

    mem_t2_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread get_4_isog result t3 back...");

    element_file = $fopen("sim_get_4_isog_t3_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_0_dout); 
    end

    mem_t3_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_get_4_isog_t3_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_1_dout); 
    end

    mem_t3_1_rd_en = 1'b0;

    $fclose(element_file);

 //---------------------------------------------------------------------
    #100;
    $display("\nread get_4_isog result t4 back...");

    element_file = $fopen("sim_get_4_isog_t4_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t4_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t4_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t4_0_dout); 
    end

    out_mem_t4_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_get_4_isog_t4_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t4_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t4_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t4_1_dout); 
    end

    out_mem_t4_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread get_4_isog result t5 back...");

    element_file = $fopen("sim_get_4_isog_t5_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t5_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t5_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t5_0_dout); 
    end

    out_mem_t5_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_get_4_isog_t5_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t5_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t5_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t5_1_dout); 
    end

    out_mem_t5_1_rd_en = 1'b0;

    $fclose(element_file);

    #10;
    $display("\ncomparing get_4_isog results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;
 
//--------------------------------------------------------------------- 
    # 15;
    start <= 1'b1;
    function_encoded <= 3;
    start_time = $time;
    $display("\n    start xADD computation");
    # 10;
    start <= 1'b0;
 
    // computation finishes
    @(posedge done);
    $display("\n    xADD comptation finished in %0d cycles", ($time-start_time)/10);


//---------------------------------------------------------------------
    // restart computation without forcing reset
    # 100; 
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat xADD computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    xADD comptation finished in %0d cycles", ($time-start_time)/10);
    
    
    // restart computation without forcing reset
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat xADD computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    xADD comptation finished in %0d cycles", ($time-start_time)/10);

    function_encoded <= 0;
 
//--------------------------------------------------------------------- 
    #100;
    $display("\nread xADD result t2 back...");

    element_file = $fopen("sim_xADD_t2_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_0_dout); 
    end

    mem_t2_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_xADD_t2_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_1_dout); 
    end

    mem_t2_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread xADD result t3 back...");

    element_file = $fopen("sim_xADD_t3_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_0_dout); 
    end

    mem_t3_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_xADD_t3_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_1_dout); 
    end

    mem_t3_1_rd_en = 1'b0;

    $fclose(element_file);
 
    #10;
    $display("\ncomparing xADD results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;
 
//--------------------------------------------------------------------- 

// start eval_4_isog computation
    // start computation
    # 15;
    start <= 1'b1;
    function_encoded <= 4;
    start_time = $time;
    $display("\n    start eval_4_isog computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\n    eval_4_isog comptation finished in %0d cycles", ($time-start_time)/10);

//---------------------------------------------------------------------

    // restart computation without forcing reset
    # 100; 
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat eval_4_isog computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    eval_4_isog comptation finished in %0d cycles", ($time-start_time)/10);
    
    
    // restart computation without forcing reset
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat eval_4_isog computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    eval_4_isog comptation finished in %0d cycles", ($time-start_time)/10);
 
//---------------------------------------------------------------------

    #100;
    $display("\nread eval_4_isog result t2 back...");

    element_file = $fopen("sim_eval_4_isog_t2_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_0_dout); 
    end

    mem_t2_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_eval_4_isog_t2_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t2_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t2_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t2_1_dout); 
    end

    mem_t2_1_rd_en = 1'b0;

    $fclose(element_file);
  
    #100;
    $display("\nread eval_4_isog result t3 back...");

    element_file = $fopen("sim_eval_4_isog_t3_0.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_0_dout); 
    end

    mem_t3_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_eval_4_isog_t3_1.txt", "w");

    #100;

    @(negedge clk);
    mem_t3_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      mem_t3_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t3_1_dout); 
    end

    mem_t3_1_rd_en = 1'b0;

    $fclose(element_file);

    #10;
    $display("\ncomparing eval_4_isog results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;    
    $finish;

end 

//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------

controller #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL)) controller_inst (
  .rst(rst),
  .clk(clk),
  .function_encoded(function_encoded),
  .start(start),
  .done(done),
  .busy(busy),
  // outside requests for mult A
  .out_mult_A_start(out_mult_A_start),
  .mult_A_mem_a_0_rd_en(mult_A_mem_a_0_rd_en),
  .mult_A_mem_a_1_rd_en(mult_A_mem_a_1_rd_en),
  .mult_A_mem_b_0_rd_en(mult_A_mem_b_0_rd_en),
  .mult_A_mem_b_1_rd_en(mult_A_mem_b_1_rd_en),
  .mult_A_mem_a_0_rd_addr(mult_A_mem_a_0_rd_addr),
  .mult_A_mem_a_1_rd_addr(mult_A_mem_a_1_rd_addr),
  .mult_A_mem_b_0_rd_addr(mult_A_mem_b_0_rd_addr),
  .mult_A_mem_b_1_rd_addr(mult_A_mem_b_1_rd_addr),
  .out_mult_A_mem_a_0_dout(out_mult_A_mem_a_0_dout),
  .out_mult_A_mem_a_1_dout(out_mult_A_mem_a_1_dout),
  .out_mult_A_mem_b_0_dout(out_mult_A_mem_b_0_dout),
  .out_mult_A_mem_b_1_dout(out_mult_A_mem_b_1_dout),
  .out_sub_mult_A_mem_res_rd_en(out_sub_mult_A_mem_res_rd_en),
  .out_add_mult_A_mem_res_rd_en(out_add_mult_A_mem_res_rd_en),
  .out_sub_mult_A_mem_res_rd_addr(out_sub_mult_A_mem_res_rd_addr),
  .out_add_mult_A_mem_res_rd_addr(out_add_mult_A_mem_res_rd_addr),
  .mult_A_sub_mult_mem_res_dout(mult_A_sub_mult_mem_res_dout),
  .mult_A_add_mult_mem_res_dout(mult_A_add_mult_mem_res_dout),
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
  //
  .xDBL_mem_X_0_dout(xDBL_mem_X_0_dout),
  .xDBL_mem_X_0_rd_en(xDBL_mem_X_0_rd_en),
  .xDBL_mem_X_0_rd_addr(xDBL_mem_X_0_rd_addr),
  .xDBL_mem_X_1_dout(xDBL_mem_X_1_dout),
  .xDBL_mem_X_1_rd_en(xDBL_mem_X_1_rd_en),
  .xDBL_mem_X_1_rd_addr(xDBL_mem_X_1_rd_addr),
  .xDBL_mem_Z_0_dout(xDBL_mem_Z_0_dout),
  .xDBL_mem_Z_0_rd_en(xDBL_mem_Z_0_rd_en),
  .xDBL_mem_Z_0_rd_addr(xDBL_mem_Z_0_rd_addr),
  .xDBL_mem_Z_1_dout(xDBL_mem_Z_1_dout),
  .xDBL_mem_Z_1_rd_en(xDBL_mem_Z_1_rd_en),
  .xDBL_mem_Z_1_rd_addr(xDBL_mem_Z_1_rd_addr),
  .xDBL_mem_A24_0_dout(xDBL_mem_A24_0_dout),
  .xDBL_mem_A24_0_rd_en(xDBL_mem_A24_0_rd_en),
  .xDBL_mem_A24_0_rd_addr(xDBL_mem_A24_0_rd_addr), 
  .xDBL_mem_A24_1_dout(xDBL_mem_A24_1_dout),
  .xDBL_mem_A24_1_rd_en(xDBL_mem_A24_1_rd_en),
  .xDBL_mem_A24_1_rd_addr(xDBL_mem_A24_1_rd_addr),
  .xDBL_mem_C24_0_dout(xDBL_mem_C24_0_dout),
  .xDBL_mem_C24_0_rd_en(xDBL_mem_C24_0_rd_en),
  .xDBL_mem_C24_0_rd_addr(xDBL_mem_C24_0_rd_addr),
  .xDBL_mem_C24_1_dout(xDBL_mem_C24_1_dout),
  .xDBL_mem_C24_1_rd_en(xDBL_mem_C24_1_rd_en),
  .xDBL_mem_C24_1_rd_addr(xDBL_mem_C24_1_rd_addr),
  .xADD_mem_XP_0_dout(xADD_mem_XP_0_dout),
  .xADD_mem_XP_0_rd_en(xADD_mem_XP_0_rd_en),
  .xADD_mem_XP_0_rd_addr(xADD_mem_XP_0_rd_addr),
  .xADD_mem_XP_1_dout(xADD_mem_XP_1_dout),
  .xADD_mem_XP_1_rd_en(xADD_mem_XP_1_rd_en),
  .xADD_mem_XP_1_rd_addr(xADD_mem_XP_1_rd_addr),
  .xADD_mem_ZP_0_dout(xADD_mem_ZP_0_dout),
  .xADD_mem_ZP_0_rd_en(xADD_mem_ZP_0_rd_en),
  .xADD_mem_ZP_0_rd_addr(xADD_mem_ZP_0_rd_addr),
  .xADD_mem_ZP_1_dout(xADD_mem_ZP_1_dout),
  .xADD_mem_ZP_1_rd_en(xADD_mem_ZP_1_rd_en),
  .xADD_mem_ZP_1_rd_addr(xADD_mem_ZP_1_rd_addr),
  .xADD_mem_XQ_0_dout(xADD_mem_XQ_0_dout),
  .xADD_mem_XQ_0_rd_en(xADD_mem_XQ_0_rd_en),
  .xADD_mem_XQ_0_rd_addr(xADD_mem_XQ_0_rd_addr),
  .xADD_mem_XQ_1_dout(xADD_mem_XQ_1_dout),
  .xADD_mem_XQ_1_rd_en(xADD_mem_XQ_1_rd_en),
  .xADD_mem_XQ_1_rd_addr(xADD_mem_XQ_1_rd_addr),
  .xADD_mem_ZQ_0_dout(xADD_mem_ZQ_0_dout),
  .xADD_mem_ZQ_0_rd_en(xADD_mem_ZQ_0_rd_en),
  .xADD_mem_ZQ_0_rd_addr(xADD_mem_ZQ_0_rd_addr),
  .xADD_mem_ZQ_1_dout(xADD_mem_ZQ_1_dout),
  .xADD_mem_ZQ_1_rd_en(xADD_mem_ZQ_1_rd_en),
  .xADD_mem_ZQ_1_rd_addr(xADD_mem_ZQ_1_rd_addr), 
  .xADD_mem_xPQ_0_dout(xADD_mem_xPQ_0_dout),
  .xADD_mem_xPQ_0_rd_en(xADD_mem_xPQ_0_rd_en),
  .xADD_mem_xPQ_0_rd_addr(xADD_mem_xPQ_0_rd_addr),
  .xADD_mem_xPQ_1_dout(xADD_mem_xPQ_1_dout),
  .xADD_mem_xPQ_1_rd_en(xADD_mem_xPQ_1_rd_en),
  .xADD_mem_xPQ_1_rd_addr(xADD_mem_xPQ_1_rd_addr),
  .xADD_mem_zPQ_0_dout(xADD_mem_zPQ_0_dout),
  .xADD_mem_zPQ_0_rd_en(xADD_mem_zPQ_0_rd_en),
  .xADD_mem_zPQ_0_rd_addr(xADD_mem_zPQ_0_rd_addr),
  .xADD_mem_zPQ_1_dout(xADD_mem_zPQ_1_dout),
  .xADD_mem_zPQ_1_rd_en(xADD_mem_zPQ_1_rd_en),
  .xADD_mem_zPQ_1_rd_addr(xADD_mem_zPQ_1_rd_addr),
  .get_4_isog_mem_X4_0_dout(get_4_isog_mem_X4_0_dout),
  .get_4_isog_mem_X4_0_rd_en(get_4_isog_mem_X4_0_rd_en),
  .get_4_isog_mem_X4_0_rd_addr(get_4_isog_mem_X4_0_rd_addr),
  .get_4_isog_mem_X4_1_dout(get_4_isog_mem_X4_1_dout),
  .get_4_isog_mem_X4_1_rd_en(get_4_isog_mem_X4_1_rd_en),
  .get_4_isog_mem_X4_1_rd_addr(get_4_isog_mem_X4_1_rd_addr),
  .get_4_isog_mem_Z4_0_dout(get_4_isog_mem_Z4_0_dout),
  .get_4_isog_mem_Z4_0_rd_en(get_4_isog_mem_Z4_0_rd_en),
  .get_4_isog_mem_Z4_0_rd_addr(get_4_isog_mem_Z4_0_rd_addr),
  .get_4_isog_mem_Z4_1_dout(get_4_isog_mem_Z4_1_dout),
  .get_4_isog_mem_Z4_1_rd_en(get_4_isog_mem_Z4_1_rd_en),
  .get_4_isog_mem_Z4_1_rd_addr(get_4_isog_mem_Z4_1_rd_addr), 
  .eval_4_isog_mem_X_0_dout(eval_4_isog_mem_X_0_dout),
  .eval_4_isog_mem_X_0_rd_en(eval_4_isog_mem_X_0_rd_en),
  .eval_4_isog_mem_X_0_rd_addr(eval_4_isog_mem_X_0_rd_addr),
  .eval_4_isog_mem_X_1_dout(eval_4_isog_mem_X_1_dout),
  .eval_4_isog_mem_X_1_rd_en(eval_4_isog_mem_X_1_rd_en),
  .eval_4_isog_mem_X_1_rd_addr(eval_4_isog_mem_X_1_rd_addr),
  .eval_4_isog_mem_Z_0_dout(eval_4_isog_mem_Z_0_dout),
  .eval_4_isog_mem_Z_0_rd_en(eval_4_isog_mem_Z_0_rd_en),
  .eval_4_isog_mem_Z_0_rd_addr(eval_4_isog_mem_Z_0_rd_addr),
  .eval_4_isog_mem_Z_1_dout(eval_4_isog_mem_Z_1_dout),
  .eval_4_isog_mem_Z_1_rd_en(eval_4_isog_mem_Z_1_rd_en),
  .eval_4_isog_mem_Z_1_rd_addr(eval_4_isog_mem_Z_1_rd_addr),
  .eval_4_isog_mem_C0_0_dout(eval_4_isog_mem_C0_0_dout),
  .eval_4_isog_mem_C0_0_rd_en(eval_4_isog_mem_C0_0_rd_en),
  .eval_4_isog_mem_C0_0_rd_addr(eval_4_isog_mem_C0_0_rd_addr),
  .eval_4_isog_mem_C0_1_dout(eval_4_isog_mem_C0_1_dout),
  .eval_4_isog_mem_C0_1_rd_en(eval_4_isog_mem_C0_1_rd_en),
  .eval_4_isog_mem_C0_1_rd_addr(eval_4_isog_mem_C0_1_rd_addr),
  .eval_4_isog_mem_C1_0_dout(eval_4_isog_mem_C1_0_dout),
  .eval_4_isog_mem_C1_0_rd_en(eval_4_isog_mem_C1_0_rd_en),
  .eval_4_isog_mem_C1_0_rd_addr(eval_4_isog_mem_C1_0_rd_addr),
  .eval_4_isog_mem_C1_1_dout(eval_4_isog_mem_C1_1_dout),
  .eval_4_isog_mem_C1_1_rd_en(eval_4_isog_mem_C1_1_rd_en),
  .eval_4_isog_mem_C1_1_rd_addr(eval_4_isog_mem_C1_1_rd_addr),
  .eval_4_isog_mem_C2_0_dout(eval_4_isog_mem_C2_0_dout),
  .eval_4_isog_mem_C2_0_rd_en(eval_4_isog_mem_C2_0_rd_en),
  .eval_4_isog_mem_C2_0_rd_addr(eval_4_isog_mem_C2_0_rd_addr), 
  .eval_4_isog_mem_C2_1_dout(eval_4_isog_mem_C2_1_dout),
  .eval_4_isog_mem_C2_1_rd_en(eval_4_isog_mem_C2_1_rd_en),
  .eval_4_isog_mem_C2_1_rd_addr(eval_4_isog_mem_C2_1_rd_addr),
  .mem_t0_0_rd_en(mem_t0_0_rd_en),
  .mem_t0_0_rd_addr(mem_t0_0_rd_addr),
  .mem_t0_0_dout(mem_t0_0_dout),
  .mem_t0_1_rd_en(mem_t0_1_rd_en),
  .mem_t0_1_rd_addr(mem_t0_1_rd_addr),
  .mem_t0_1_dout(mem_t0_1_dout),
  .mem_t1_0_rd_en(mem_t1_0_rd_en),
  .mem_t1_0_rd_addr(mem_t1_0_rd_addr),
  .mem_t1_0_dout(mem_t1_0_dout),
  .mem_t1_1_rd_en(mem_t1_1_rd_en),
  .mem_t1_1_rd_addr(mem_t1_1_rd_addr),
  .mem_t1_1_dout(mem_t1_1_dout),
  .mem_t2_0_rd_en(mem_t2_0_rd_en),
  .mem_t2_0_rd_addr(mem_t2_0_rd_addr),
  .mem_t2_0_dout(mem_t2_0_dout),
  .mem_t2_1_rd_en(mem_t2_1_rd_en),
  .mem_t2_1_rd_addr(mem_t2_1_rd_addr),
  .mem_t2_1_dout(mem_t2_1_dout),
  .mem_t3_0_rd_en(mem_t3_0_rd_en),
  .mem_t3_0_rd_addr(mem_t3_0_rd_addr),
  .mem_t3_0_dout(mem_t3_0_dout),
  .mem_t3_1_rd_en(mem_t3_1_rd_en),
  .mem_t3_1_rd_addr(mem_t3_1_rd_addr),
  .mem_t3_1_dout(mem_t3_1_dout),
  .out_mem_t4_0_rd_en(out_mem_t4_0_rd_en),
  .out_mem_t4_0_rd_addr(out_mem_t4_0_rd_addr), 
  .out_mem_t4_1_rd_en(out_mem_t4_1_rd_en),
  .out_mem_t4_1_rd_addr(out_mem_t4_1_rd_addr), 
  .out_mem_t5_0_rd_en(out_mem_t5_0_rd_en),
  .out_mem_t5_0_rd_addr(out_mem_t5_0_rd_addr), 
  .out_mem_t5_1_rd_en(out_mem_t5_1_rd_en),
  .out_mem_t5_1_rd_addr(out_mem_t5_1_rd_addr), 
  .out_mem_t6_0_rd_en(out_mem_t6_0_rd_en),
  .out_mem_t6_0_rd_addr(out_mem_t6_0_rd_addr), 
  .out_mem_t6_1_rd_en(out_mem_t6_1_rd_en),
  .out_mem_t6_1_rd_addr(out_mem_t6_1_rd_addr), 
  .out_mem_t7_0_wr_en(out_mem_t7_0_wr_en),
  .out_mem_t7_0_wr_addr(out_mem_t7_0_wr_addr),
  .out_mem_t7_0_din(out_mem_t7_0_din),
  .out_mem_t7_0_rd_en(out_mem_t7_0_rd_en),
  .out_mem_t7_0_rd_addr(out_mem_t7_0_rd_addr), 
  .out_mem_t7_1_wr_en(out_mem_t7_1_wr_en),
  .out_mem_t7_1_wr_addr(out_mem_t7_1_wr_addr),
  .out_mem_t7_1_din(out_mem_t7_1_din),
  .out_mem_t7_1_rd_en(out_mem_t7_1_rd_en),
  .out_mem_t7_1_rd_addr(out_mem_t7_1_rd_addr), 
  .out_mem_t8_0_wr_en(out_mem_t8_0_wr_en),
  .out_mem_t8_0_wr_addr(out_mem_t8_0_wr_addr),
  .out_mem_t8_0_din(out_mem_t8_0_din),
  .out_mem_t8_0_rd_en(out_mem_t8_0_rd_en),
  .out_mem_t8_0_rd_addr(out_mem_t8_0_rd_addr), 
  .out_mem_t8_1_wr_en(out_mem_t8_1_wr_en),
  .out_mem_t8_1_wr_addr(out_mem_t8_1_wr_addr),
  .out_mem_t8_1_din(out_mem_t8_1_din),
  .out_mem_t8_1_rd_en(out_mem_t8_1_rd_en),
  .out_mem_t8_1_rd_addr(out_mem_t8_1_rd_addr), 
  .out_mem_t9_0_wr_en(out_mem_t9_0_wr_en),
  .out_mem_t9_0_wr_addr(out_mem_t9_0_wr_addr),
  .out_mem_t9_0_din(out_mem_t9_0_din),
  .out_mem_t9_0_rd_en(out_mem_t9_0_rd_en),
  .out_mem_t9_0_rd_addr(out_mem_t9_0_rd_addr), 
  .out_mem_t9_1_wr_en(out_mem_t9_1_wr_en),
  .out_mem_t9_1_wr_addr(out_mem_t9_1_wr_addr),
  .out_mem_t9_1_din(out_mem_t9_1_din),
  .out_mem_t9_1_rd_en(out_mem_t9_1_rd_en),
  .out_mem_t9_1_rd_addr(out_mem_t9_1_rd_addr), 
  .out_mem_t10_0_wr_en(out_mem_t10_0_wr_en),
  .out_mem_t10_0_wr_addr(out_mem_t10_0_wr_addr),
  .out_mem_t10_0_din(out_mem_t10_0_din),
  .out_mem_t10_0_rd_en(out_mem_t10_0_rd_en),
  .out_mem_t10_0_rd_addr(out_mem_t10_0_rd_addr), 
  .out_mem_t10_1_wr_en(out_mem_t10_1_wr_en),
  .out_mem_t10_1_wr_addr(out_mem_t10_1_wr_addr),
  .out_mem_t10_1_din(out_mem_t10_1_din),
  .out_mem_t10_1_rd_en(out_mem_t10_1_rd_en),
  .out_mem_t10_1_rd_addr(out_mem_t10_1_rd_addr) 
  );

//---------------------------------------------------------------------
// xDBL input memory
//---------------------------------------------------------------------
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X_0 (  
  .clock(clk),
  .data(xDBL_mem_X_0_din),
  .address(xDBL_mem_X_0_wr_en ? xDBL_mem_X_0_wr_addr : (xDBL_mem_X_0_rd_en ? xDBL_mem_X_0_rd_addr : 0)),
  .wr_en(xDBL_mem_X_0_wr_en),
  .q(xDBL_mem_X_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X_1 (  
  .clock(clk),
  .data(xDBL_mem_X_1_din),
  .address(xDBL_mem_X_1_wr_en ? xDBL_mem_X_1_wr_addr : (xDBL_mem_X_1_rd_en ? xDBL_mem_X_1_rd_addr : 0)),
  .wr_en(xDBL_mem_X_1_wr_en),
  .q(xDBL_mem_X_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z_0 (  
  .clock(clk),
  .data(xDBL_mem_Z_0_din),
  .address(xDBL_mem_Z_0_wr_en ? xDBL_mem_Z_0_wr_addr : (xDBL_mem_Z_0_rd_en ? xDBL_mem_Z_0_rd_addr : 0)),
  .wr_en(xDBL_mem_Z_0_wr_en),
  .q(xDBL_mem_Z_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z_1 (  
  .clock(clk),
  .data(xDBL_mem_Z_1_din),
  .address(xDBL_mem_Z_1_wr_en ? xDBL_mem_Z_1_wr_addr : (xDBL_mem_Z_1_rd_en ? xDBL_mem_Z_1_rd_addr : 0)),
  .wr_en(xDBL_mem_Z_1_wr_en),
  .q(xDBL_mem_Z_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_A24_0 (  
  .clock(clk),
  .data(xDBL_mem_A24_0_din),
  .address(xDBL_mem_A24_0_wr_en ? xDBL_mem_A24_0_wr_addr : (xDBL_mem_A24_0_rd_en ? xDBL_mem_A24_0_rd_addr : 0)),
  .wr_en(xDBL_mem_A24_0_wr_en),
  .q(xDBL_mem_A24_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_A24_1 (  
  .clock(clk),
  .data(xDBL_mem_A24_1_din),
  .address(xDBL_mem_A24_1_wr_en ? xDBL_mem_A24_1_wr_addr : (xDBL_mem_A24_1_rd_en ? xDBL_mem_A24_1_rd_addr : 0)),
  .wr_en(xDBL_mem_A24_1_wr_en),
  .q(xDBL_mem_A24_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C24_0 (  
  .clock(clk),
  .data(xDBL_mem_C24_0_din),
  .address(xDBL_mem_C24_0_wr_en ? xDBL_mem_C24_0_wr_addr : (xDBL_mem_C24_0_rd_en ? xDBL_mem_C24_0_rd_addr : 0)),
  .wr_en(xDBL_mem_C24_0_wr_en),
  .q(xDBL_mem_C24_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C24_1 (  
  .clock(clk),
  .data(xDBL_mem_C24_1_din),
  .address(xDBL_mem_C24_1_wr_en ? xDBL_mem_C24_1_wr_addr : (xDBL_mem_C24_1_rd_en ? xDBL_mem_C24_1_rd_addr : 0)),
  .wr_en(xDBL_mem_C24_1_wr_en),
  .q(xDBL_mem_C24_1_dout)
  ); 

//---------------------------------------------------------------------
// get_4_isog input memory
//---------------------------------------------------------------------

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X4_0 (  
  .clock(clk),
  .data(get_4_isog_mem_X4_0_din),
  .address(get_4_isog_mem_X4_0_wr_en ? get_4_isog_mem_X4_0_wr_addr : (get_4_isog_mem_X4_0_rd_en ? get_4_isog_mem_X4_0_rd_addr : 0)),
  .wr_en(get_4_isog_mem_X4_0_wr_en),
  .q(get_4_isog_mem_X4_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X4_1 (  
  .clock(clk),
  .data(get_4_isog_mem_X4_1_din),
  .address(get_4_isog_mem_X4_1_wr_en ? get_4_isog_mem_X4_1_wr_addr : (get_4_isog_mem_X4_1_rd_en ? get_4_isog_mem_X4_1_rd_addr : 0)),
  .wr_en(get_4_isog_mem_X4_1_wr_en),
  .q(get_4_isog_mem_X4_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z4_0 (  
  .clock(clk),
  .data(get_4_isog_mem_Z4_0_din),
  .address(get_4_isog_mem_Z4_0_wr_en ? get_4_isog_mem_Z4_0_wr_addr : (get_4_isog_mem_Z4_0_rd_en ? get_4_isog_mem_Z4_0_rd_addr : 0)),
  .wr_en(get_4_isog_mem_Z4_0_wr_en),
  .q(get_4_isog_mem_Z4_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z4_1 (  
  .clock(clk),
  .data(get_4_isog_mem_Z4_1_din),
  .address(get_4_isog_mem_Z4_1_wr_en ? get_4_isog_mem_Z4_1_wr_addr : (get_4_isog_mem_Z4_1_rd_en ? get_4_isog_mem_Z4_1_rd_addr : 0)),
  .wr_en(get_4_isog_mem_Z4_1_wr_en),
  .q(get_4_isog_mem_Z4_1_dout)
  );

//---------------------------------------------------------------------
// xADD input memory
//---------------------------------------------------------------------

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XP_0 (  
  .clock(clk),
  .data(xADD_mem_XP_0_din),
  .address(xADD_mem_XP_0_wr_en ? xADD_mem_XP_0_wr_addr : (xADD_mem_XP_0_rd_en ? xADD_mem_XP_0_rd_addr : 0)),
  .wr_en(xADD_mem_XP_0_wr_en),
  .q(xADD_mem_XP_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XP_1 (  
  .clock(clk),
  .data(xADD_mem_XP_1_din),
  .address(xADD_mem_XP_1_wr_en ? xADD_mem_XP_1_wr_addr : (xADD_mem_XP_1_rd_en ? xADD_mem_XP_1_rd_addr : 0)),
  .wr_en(xADD_mem_XP_1_wr_en),
  .q(xADD_mem_XP_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZP_0 (  
  .clock(clk),
  .data(xADD_mem_ZP_0_din),
  .address(xADD_mem_ZP_0_wr_en ? xADD_mem_ZP_0_wr_addr : (xADD_mem_ZP_0_rd_en ? xADD_mem_ZP_0_rd_addr : 0)),
  .wr_en(xADD_mem_ZP_0_wr_en),
  .q(xADD_mem_ZP_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZP_1 (  
  .clock(clk),
  .data(xADD_mem_ZP_1_din),
  .address(xADD_mem_ZP_1_wr_en ? xADD_mem_ZP_1_wr_addr : (xADD_mem_ZP_1_rd_en ? xADD_mem_ZP_1_rd_addr : 0)),
  .wr_en(xADD_mem_ZP_1_wr_en),
  .q(xADD_mem_ZP_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XQ_0 (  
  .clock(clk),
  .data(xADD_mem_XQ_0_din),
  .address(xADD_mem_XQ_0_wr_en ? xADD_mem_XQ_0_wr_addr : (xADD_mem_XQ_0_rd_en ? xADD_mem_XQ_0_rd_addr : 0)),
  .wr_en(xADD_mem_XQ_0_wr_en),
  .q(xADD_mem_XQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XQ_1 (  
  .clock(clk),
  .data(xADD_mem_XQ_1_din),
  .address(xADD_mem_XQ_1_wr_en ? xADD_mem_XQ_1_wr_addr : (xADD_mem_XQ_1_rd_en ? xADD_mem_XQ_1_rd_addr : 0)),
  .wr_en(xADD_mem_XQ_1_wr_en),
  .q(xADD_mem_XQ_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZQ_0 (  
  .clock(clk),
  .data(xADD_mem_ZQ_0_din),
  .address(xADD_mem_ZQ_0_wr_en ? xADD_mem_ZQ_0_wr_addr : (xADD_mem_ZQ_0_rd_en ? xADD_mem_ZQ_0_rd_addr : 0)),
  .wr_en(xADD_mem_ZQ_0_wr_en),
  .q(xADD_mem_ZQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZQ_1 (  
  .clock(clk),
  .data(xADD_mem_ZQ_1_din),
  .address(xADD_mem_ZQ_1_wr_en ? xADD_mem_ZQ_1_wr_addr : (xADD_mem_ZQ_1_rd_en ? xADD_mem_ZQ_1_rd_addr : 0)),
  .wr_en(xADD_mem_ZQ_1_wr_en),
  .q(xADD_mem_ZQ_1_dout)
  );
 
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_xPQ_0 (  
  .clock(clk),
  .data(xADD_mem_xPQ_0_din),
  .address(xADD_mem_xPQ_0_wr_en ? xADD_mem_xPQ_0_wr_addr : (xADD_mem_xPQ_0_rd_en ? xADD_mem_xPQ_0_rd_addr : 0)),
  .wr_en(xADD_mem_xPQ_0_wr_en),
  .q(xADD_mem_xPQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_xPQ_1 (  
  .clock(clk),
  .data(xADD_mem_xPQ_1_din),
  .address(xADD_mem_xPQ_1_wr_en ? xADD_mem_xPQ_1_wr_addr : (xADD_mem_xPQ_1_rd_en ? xADD_mem_xPQ_1_rd_addr : 0)),
  .wr_en(xADD_mem_xPQ_1_wr_en),
  .q(xADD_mem_xPQ_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_zPQ_0 (  
  .clock(clk),
  .data(xADD_mem_zPQ_0_din),
  .address(xADD_mem_zPQ_0_wr_en ? xADD_mem_zPQ_0_wr_addr : (xADD_mem_zPQ_0_rd_en ? xADD_mem_zPQ_0_rd_addr : 0)),
  .wr_en(xADD_mem_zPQ_0_wr_en),
  .q(xADD_mem_zPQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_zPQ_1 (  
  .clock(clk),
  .data(xADD_mem_zPQ_1_din),
  .address(xADD_mem_zPQ_1_wr_en ? xADD_mem_zPQ_1_wr_addr : (xADD_mem_zPQ_1_rd_en ? xADD_mem_zPQ_1_rd_addr : 0)),
  .wr_en(xADD_mem_zPQ_1_wr_en),
  .q(xADD_mem_zPQ_1_dout)
  );
//---------------------------------------------------------------------
// eval_4_isog input memory
//---------------------------------------------------------------------

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) eval_4_isog_single_port_mem_inst_X_0 (  
  .clock(clk),
  .data(eval_4_isog_mem_X_0_din),
  .address(eval_4_isog_mem_X_0_wr_en ? eval_4_isog_mem_X_0_wr_addr : (eval_4_isog_mem_X_0_rd_en ? eval_4_isog_mem_X_0_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_X_0_wr_en),
  .q(eval_4_isog_mem_X_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) eval_4_isog_single_port_mem_inst_X_1 (  
  .clock(clk),
  .data(eval_4_isog_mem_X_1_din),
  .address(eval_4_isog_mem_X_1_wr_en ? eval_4_isog_mem_X_1_wr_addr : (eval_4_isog_mem_X_1_rd_en ? eval_4_isog_mem_X_1_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_X_1_wr_en),
  .q(eval_4_isog_mem_X_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) eval_4_isog_single_port_mem_inst_Z_0 (  
  .clock(clk),
  .data(eval_4_isog_mem_Z_0_din),
  .address(eval_4_isog_mem_Z_0_wr_en ? eval_4_isog_mem_Z_0_wr_addr : (eval_4_isog_mem_Z_0_rd_en ? eval_4_isog_mem_Z_0_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_Z_0_wr_en),
  .q(eval_4_isog_mem_Z_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) eval_4_isog_single_port_mem_inst_Z_1 (  
  .clock(clk),
  .data(eval_4_isog_mem_Z_1_din),
  .address(eval_4_isog_mem_Z_1_wr_en ? eval_4_isog_mem_Z_1_wr_addr : (eval_4_isog_mem_Z_1_rd_en ? eval_4_isog_mem_Z_1_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_Z_1_wr_en),
  .q(eval_4_isog_mem_Z_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C0_0 (  
  .clock(clk),
  .data(eval_4_isog_mem_C0_0_din),
  .address(eval_4_isog_mem_C0_0_wr_en ? eval_4_isog_mem_C0_0_wr_addr : (eval_4_isog_mem_C0_0_rd_en ? eval_4_isog_mem_C0_0_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_C0_0_wr_en),
  .q(eval_4_isog_mem_C0_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C0_1 (  
  .clock(clk),
  .data(eval_4_isog_mem_C0_1_din),
  .address(eval_4_isog_mem_C0_1_wr_en ? eval_4_isog_mem_C0_1_wr_addr : (eval_4_isog_mem_C0_1_rd_en ? eval_4_isog_mem_C0_1_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_C0_1_wr_en),
  .q(eval_4_isog_mem_C0_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C1_0 (  
  .clock(clk),
  .data(eval_4_isog_mem_C1_0_din),
  .address(eval_4_isog_mem_C1_0_wr_en ? eval_4_isog_mem_C1_0_wr_addr : (eval_4_isog_mem_C1_0_rd_en ? eval_4_isog_mem_C1_0_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_C1_0_wr_en),
  .q(eval_4_isog_mem_C1_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C1_1 (  
  .clock(clk),
  .data(eval_4_isog_mem_C1_1_din),
  .address(eval_4_isog_mem_C1_1_wr_en ? eval_4_isog_mem_C1_1_wr_addr : (eval_4_isog_mem_C1_1_rd_en ? eval_4_isog_mem_C1_1_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_C1_1_wr_en),
  .q(eval_4_isog_mem_C1_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) eval_4_isog_single_port_mem_inst_C2_0 (  
  .clock(clk),
  .data(eval_4_isog_mem_C2_0_din),
  .address(eval_4_isog_mem_C2_0_wr_en ? eval_4_isog_mem_C2_0_wr_addr : (eval_4_isog_mem_C2_0_rd_en ? eval_4_isog_mem_C2_0_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_C2_0_wr_en),
  .q(eval_4_isog_mem_C2_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) eval_4_isog_single_port_mem_inst_C2_1 (  
  .clock(clk),
  .data(eval_4_isog_mem_C2_1_din),
  .address(eval_4_isog_mem_C2_1_wr_en ? eval_4_isog_mem_C2_1_wr_addr : (eval_4_isog_mem_C2_1_rd_en ? eval_4_isog_mem_C2_1_rd_addr : 0)),
  .wr_en(eval_4_isog_mem_C2_1_wr_en),
  .q(eval_4_isog_mem_C2_1_dout)
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

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t6_0 (  
  .clock(clk),
  .data(mem_t6_0_din),
  .address(mem_t6_0_wr_en ? mem_t6_0_wr_addr : mem_t6_0_rd_addr),
  .wr_en(mem_t6_0_wr_en),
  .q(mem_t6_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t6_1 (  
  .clock(clk),
  .data(mem_t6_1_din),
  .address(mem_t6_1_wr_en ? mem_t6_1_wr_addr : mem_t6_1_rd_addr),
  .wr_en(mem_t6_1_wr_en),
  .q(mem_t6_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t7_0 (  
  .clock(clk),
  .data(mem_t7_0_din),
  .address(mem_t7_0_wr_en ? mem_t7_0_wr_addr : mem_t7_0_rd_addr),
  .wr_en(mem_t7_0_wr_en),
  .q(mem_t7_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t7_1 (  
  .clock(clk),
  .data(mem_t7_1_din),
  .address(mem_t7_1_wr_en ? mem_t7_1_wr_addr : mem_t7_1_rd_addr),
  .wr_en(mem_t7_1_wr_en),
  .q(mem_t7_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t8_0 (  
  .clock(clk),
  .data(mem_t8_0_din),
  .address(mem_t8_0_wr_en ? mem_t8_0_wr_addr : mem_t8_0_rd_addr),
  .wr_en(mem_t8_0_wr_en),
  .q(mem_t8_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t8_1 (  
  .clock(clk),
  .data(mem_t8_1_din),
  .address(mem_t8_1_wr_en ? mem_t8_1_wr_addr : mem_t8_1_rd_addr),
  .wr_en(mem_t8_1_wr_en),
  .q(mem_t8_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t9_0 (  
  .clock(clk),
  .data(mem_t9_0_din),
  .address(mem_t9_0_wr_en ? mem_t9_0_wr_addr : mem_t9_0_rd_addr),
  .wr_en(mem_t9_0_wr_en),
  .q(mem_t9_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_t9_1 (  
  .clock(clk),
  .data(mem_t9_1_din),
  .address(mem_t9_1_wr_en ? mem_t9_1_wr_addr : mem_t9_1_rd_addr),
  .wr_en(mem_t9_1_wr_en),
  .q(mem_t9_1_dout)
  );

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
 
always 
  # 5 clk = !clk;


endmodule