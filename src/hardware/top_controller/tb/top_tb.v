/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for top controller
 * 
*/
 

`timescale 1ns / 1ps

module top_tb;

parameter RADIX = `RADIX;
parameter WIDTH_REAL = `WIDTH_REAL;
parameter SK_MEM_WIDTH = `SK_WIDTH;
parameter SK_MEM_WIDTH_LOG = `CLOG2(SK_MEM_WIDTH);
parameter SK_MEM_DEPTH = `SK_DEPTH;
parameter SK_MEM_DEPTH_LOG = `CLOG2(SK_MEM_DEPTH);
parameter SINGLE_MEM_WIDTH = RADIX;
parameter SINGLE_MEM_DEPTH = WIDTH_REAL;
parameter SINGLE_MEM_DEPTH_LOG = `CLOG2(SINGLE_MEM_DEPTH);
parameter DOUBLE_MEM_WIDTH = RADIX*2;
parameter DOUBLE_MEM_DEPTH = (WIDTH_REAL+1)/2;
parameter DOUBLE_MEM_DEPTH_LOG = `CLOG2(DOUBLE_MEM_DEPTH); 
parameter START_INDEX = `START_INDEX;
parameter END_INDEX = `END_INDEX;
parameter LOOPS = `LOOPS;

// inputs
reg rst = 1'b0;
reg clk = 1'b0;
reg start = 1'b0;
reg [7:0] command_encoded = 0; 
reg [15:0] xDBLe_NUM_LOOPS = LOOPS;
reg eval_4_isog_XZ_newly_init = 1'b0;
reg last_eval_4_isog = 1'b0;
reg eval_4_isog_result_can_overwrite = 1'b0;
reg [15:0] xADD_loop_start_index = START_INDEX;
reg [15:0] xADD_loop_end_index = END_INDEX;

reg xADD_P_newly_loaded = 1'b0;
wire xADD_P_can_overwrite;

reg out_mult_A_start = 0;
reg out_mult_A_mem_a_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_a_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_a_0_din = 0;

reg out_mult_A_mem_a_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_a_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_a_1_din = 0;  

reg out_mult_A_mem_b_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_b_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_b_0_din = 0;

reg out_mult_A_mem_b_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mult_A_mem_b_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mult_A_mem_b_1_din = 0; 

reg out_sub_mult_A_mem_res_rd_en = 0;
reg [DOUBLE_MEM_DEPTH_LOG-1:0] out_sub_mult_A_mem_res_rd_addr = 0;
wire [DOUBLE_MEM_WIDTH-1:0] sub_mult_A_mem_res_dout;

reg out_add_mult_A_mem_res_rd_en = 0;
reg [DOUBLE_MEM_DEPTH_LOG-1:0] out_add_mult_A_mem_res_rd_addr = 0;
wire [DOUBLE_MEM_WIDTH-1:0] add_mult_A_mem_res_dout;

// outputs 
wire eval_4_isog_XZ_can_overwrite;
wire eval_4_isog_result_ready;
wire done;
wire busy;

reg out_sk_mem_wr_en = 1'b0;
reg [SK_MEM_DEPTH_LOG-1:0] out_sk_mem_wr_addr = 0;
reg [SK_MEM_WIDTH-1:0] out_sk_mem_din = 0;

reg out_mem_X_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_X_0_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_X_0_dout;
reg out_mem_X_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_0_rd_addr = 0;

reg out_mem_X_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_X_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_X_1_dout;
reg out_mem_X_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X_1_rd_addr = 0;

reg out_mem_Z_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_Z_0_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_Z_0_dout;
reg out_mem_Z_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_0_rd_addr = 0;

reg out_mem_Z_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_Z_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_Z_1_dout;
reg out_mem_Z_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z_1_rd_addr = 0;

reg out_mem_X4_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X4_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_X4_0_din = 0;

reg out_mem_X4_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_X4_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_X4_1_din = 0;

// interface with input mem Z4
reg out_mem_Z4_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z4_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_Z4_0_din = 0;

reg out_mem_Z4_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_Z4_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_Z4_1_din = 0;

reg out_mem_t10_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_0_rd_addr = 0; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_0_dout;

reg out_mem_t10_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t10_1_rd_addr = 0; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_1_dout;

// interface with  memory t11 
reg out_mem_t11_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t11_0_rd_addr = 0; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t11_0_dout;

reg out_mem_t11_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t11_1_rd_addr = 0; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t11_1_dout;

// outside write/read signals for input memory of xADD_Loop
// interface with input mem XP; result of xADD is written back to input memories
reg out_mem_XP_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_XP_0_din = 0;

reg out_mem_XP_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_XP_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_XP_0_dout;
reg out_mem_XP_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_XP_1_dout;
reg out_mem_XP_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XP_1_rd_addr = 0;

// interface with input mem ZP
reg out_mem_ZP_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_ZP_0_din = 0;

reg out_mem_ZP_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_ZP_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_dout;
reg out_mem_ZP_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_dout;
reg out_mem_ZP_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZP_1_rd_addr = 0;

// interface with input mem XQ
reg out_mem_XQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_XQ_0_din = 0;

reg out_mem_XQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_XQ_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_dout;
reg out_mem_XQ_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_dout;
reg out_mem_XQ_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_XQ_1_rd_addr = 0;

// interface with input mem ZQ
reg out_mem_ZQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_ZQ_0_din = 0;

reg out_mem_ZQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_ZQ_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_dout;
reg out_mem_ZQ_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_dout;
reg out_mem_ZQ_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_ZQ_1_rd_addr = 0;

// interface with input mem xPQ
reg out_mem_xPQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_xPQ_0_din = 0;

reg out_mem_xPQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_xPQ_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_dout;
reg out_mem_xPQ_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_dout;
reg out_mem_xPQ_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_xPQ_1_rd_addr = 0;

// interface with input mem zPQ
reg out_mem_zPQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_zPQ_0_din = 0;

reg out_mem_zPQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_zPQ_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_dout;
reg out_mem_zPQ_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_dout;
reg out_mem_zPQ_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_zPQ_1_rd_addr = 0;

// outside write/read signals for A24 and C24 constant memories
// interface with input mem A24; A24/C24 is updated by get_4_isog
reg out_mem_A24_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_A24_0_din = 0;

reg out_mem_A24_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_A24_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_A24_0_dout;
reg out_mem_A24_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_A24_1_dout;
reg out_mem_A24_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_A24_1_rd_addr = 0;

// interface with input mem C24
reg out_mem_C24_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_C24_0_din = 0;

reg out_mem_C24_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] out_mem_C24_1_din = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_C24_0_dout;
reg out_mem_C24_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_0_rd_addr = 0;

wire [SINGLE_MEM_WIDTH-1:0] mem_C24_1_dout;
reg out_mem_C24_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_C24_1_rd_addr = 0;

//---------------------------------------------------------------------
    // logic for get_4_isog and eval_4_isog
//---------------------------------------------------------------------
// 2-phase handshake protocol
reg eval_4_isog_XZ_newly_init_pre = 1'b0;
reg eval_4_isog_XZ_newly_init_pre_buf = 1'b0;
reg eval_4_isog_result_can_overwrite_pre = 1'b0;
reg eval_4_isog_result_can_overwrite_pre_buf = 1'b0;

// for xADD 
reg xADD_P_newly_loaded_pre = 1'b0;
reg xADD_P_newly_loaded_pre_buf = 1'b0;

always @(posedge clk or negedge rst) begin
  if (rst) begin
    eval_4_isog_XZ_newly_init_pre_buf <= 1'b0;
    eval_4_isog_result_can_overwrite_pre_buf <= 1'b0;

    eval_4_isog_XZ_newly_init <= 1'b0;
    eval_4_isog_result_can_overwrite <= 1'b1;

    xADD_P_newly_loaded <= 1'b0;
    xADD_P_newly_loaded_pre_buf <= 1'b0;
  end
  else begin
    eval_4_isog_XZ_newly_init_pre_buf <= eval_4_isog_XZ_newly_init_pre;
    eval_4_isog_result_can_overwrite_pre_buf <= eval_4_isog_result_can_overwrite_pre;

    eval_4_isog_XZ_newly_init <= eval_4_isog_XZ_newly_init_pre | eval_4_isog_XZ_newly_init_pre_buf ? 1'b1 : 
                                 eval_4_isog_XZ_can_overwrite ? 1'b0 :
                                 eval_4_isog_XZ_newly_init;

    eval_4_isog_result_can_overwrite <= eval_4_isog_result_can_overwrite_pre | eval_4_isog_result_can_overwrite_pre_buf ? 1'b1 :
                                        eval_4_isog_result_ready ? 1'b0 :
                                        eval_4_isog_result_can_overwrite;

    xADD_P_newly_loaded_pre_buf <= xADD_P_newly_loaded_pre;

    xADD_P_newly_loaded <= xADD_P_newly_loaded_pre | xADD_P_newly_loaded_pre_buf ? 1'b1 :
                           xADD_P_can_overwrite ? 1'b0 :
                           xADD_P_newly_loaded;
  end
end
//---------------------------------------------------------------------

initial
  begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
  end

integer start_time = 0; 
integer element_file;
integer scan_file;
integer i;

initial 
  begin

//---------------------------------------------------------------------
    // load input for xADD loop
//---------------------------------------------------------------------
    rst <= 1'b0;
    start <= 1'b0;
    # 45;
    rst <= 1'b1;
    # 20;
    rst <= 1'b0;

//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
    // load input memory XP 0
    // load XP 0
    element_file = $fopen("mem_XP_0_0.txt", "r");
    # 10;
    $display("\nloading input XP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XP_0_wr_en = 1'b1;
    out_mem_XP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XP_0_din); 
      #10;
      out_mem_XP_0_wr_addr = out_mem_XP_0_wr_addr + 1;
    end
    out_mem_XP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XP 1 
    element_file = $fopen("mem_XP_1_0.txt", "r");
    # 10;
    $display("\nloading input XP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XP_1_wr_en = 1'b1;
    out_mem_XP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XP_1_din); 
      #10;
      out_mem_XP_1_wr_addr = out_mem_XP_1_wr_addr + 1;
    end
    out_mem_XP_1_wr_en = 1'b0;
    end
    $fclose(element_file);     

     // load input memory ZP
    // load ZP 0
    element_file = $fopen("mem_ZP_0_0.txt", "r");
    # 10;
    $display("\nloading input ZP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZP_0_wr_en = 1'b1;
    out_mem_ZP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZP_0_din); 
      #10;
      out_mem_ZP_0_wr_addr = out_mem_ZP_0_wr_addr + 1;
    end
    out_mem_ZP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZP 1 
    element_file = $fopen("mem_ZP_1_0.txt", "r");
    # 10;
    $display("\nloading input ZP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZP_1_wr_en = 1'b1;
    out_mem_ZP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZP_1_din); 
      #10;
      out_mem_ZP_1_wr_addr = out_mem_ZP_1_wr_addr + 1;
    end
    out_mem_ZP_1_wr_en = 1'b0;
    end
    $fclose(element_file); 

//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------

    // load input memory XQ
    // load XQ 0
    element_file = $fopen("mem_XQ_0.txt", "r");
    # 10;
    $display("\nloading input XQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XQ_0_wr_en = 1'b1;
    out_mem_XQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XQ_0_din); 
      #10;
      out_mem_XQ_0_wr_addr = out_mem_XQ_0_wr_addr + 1;
    end
    out_mem_XQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XQ 1 
    element_file = $fopen("mem_XQ_1.txt", "r");
    # 10;
    $display("\nloading input XQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XQ_1_wr_en = 1'b1;
    out_mem_XQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XQ_1_din); 
      #10;
      out_mem_XQ_1_wr_addr = out_mem_XQ_1_wr_addr + 1;
    end
    out_mem_XQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);     

     // load input memory ZQ
    // load ZQ 0
    element_file = $fopen("mem_ZQ_0.txt", "r");
    # 10;
    $display("\nloading input ZQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZQ_0_wr_en = 1'b1;
    out_mem_ZQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZQ_0_din); 
      #10;
      out_mem_ZQ_0_wr_addr = out_mem_ZQ_0_wr_addr + 1;
    end
    out_mem_ZQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZQ 1 
    element_file = $fopen("mem_ZQ_1.txt", "r");
    # 10;
    $display("\nloading input ZQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZQ_1_wr_en = 1'b1;
    out_mem_ZQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZQ_1_din); 
      #10;
      out_mem_ZQ_1_wr_addr = out_mem_ZQ_1_wr_addr + 1;
    end
    out_mem_ZQ_1_wr_en = 1'b0;
    end
    $fclose(element_file); 

//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------

    // load input memory xPQ
    // load xPQ 0
    element_file = $fopen("mem_xPQ_0.txt", "r");
    # 10;
    $display("\nloading input xPQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_xPQ_0_wr_en = 1'b1;
    out_mem_xPQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_xPQ_0_din); 
      #10;
      out_mem_xPQ_0_wr_addr = out_mem_xPQ_0_wr_addr + 1;
    end
    out_mem_xPQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load xPQ 1 
    element_file = $fopen("mem_xPQ_1.txt", "r");
    # 10;
    $display("\nloading input xPQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_xPQ_1_wr_en = 1'b1;
    out_mem_xPQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_xPQ_1_din); 
      #10;
      out_mem_xPQ_1_wr_addr = out_mem_xPQ_1_wr_addr + 1;
    end
    out_mem_xPQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);     

     // load input memory zPQ
    // load zPQ 0
    element_file = $fopen("mem_zPQ_0.txt", "r");
    # 10;
    $display("\nloading input zPQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_zPQ_0_wr_en = 1'b1;
    out_mem_zPQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_zPQ_0_din); 
      #10;
      out_mem_zPQ_0_wr_addr = out_mem_zPQ_0_wr_addr + 1;
    end
    out_mem_zPQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load zPQ 1 
    element_file = $fopen("mem_zPQ_1.txt", "r");
    # 10;
    $display("\nloading input zPQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_zPQ_1_wr_en = 1'b1;
    out_mem_zPQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_zPQ_1_din); 
      #10;
      out_mem_zPQ_1_wr_addr = out_mem_zPQ_1_wr_addr + 1;
    end
    out_mem_zPQ_1_wr_en = 1'b0;
    end
    $fclose(element_file); 
    
    
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
    // start computation
    # 15;
    start <= 1'b1;
    command_encoded <= 3;
    start_time = $time;
    $display("\n    xADD start computation");
    # 10;
    start <= 1'b0;

// P is already read out and processed
    @(posedge xADD_P_can_overwrite);

//---------------------------------------------------------------------
    // load input memory XP 1
    // load XP 0
    element_file = $fopen("mem_XP_0_1.txt", "r");
    # 10;
    $display("\nloading input XP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XP_0_wr_en = 1'b1;
    out_mem_XP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XP_0_din); 
      #10;
      out_mem_XP_0_wr_addr = out_mem_XP_0_wr_addr + 1;
    end
    out_mem_XP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XP 1 
    element_file = $fopen("mem_XP_1_1.txt", "r");
    # 10;
    $display("\nloading input XP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XP_1_wr_en = 1'b1;
    out_mem_XP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XP_1_din); 
      #10;
      out_mem_XP_1_wr_addr = out_mem_XP_1_wr_addr + 1;
    end
    out_mem_XP_1_wr_en = 1'b0;
    end
    $fclose(element_file);     

     // load input memory ZP
    // load ZP 0
    element_file = $fopen("mem_ZP_0_1.txt", "r");
    # 10;
    $display("\nloading input ZP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZP_0_wr_en = 1'b1;
    out_mem_ZP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZP_0_din); 
      #10;
      out_mem_ZP_0_wr_addr = out_mem_ZP_0_wr_addr + 1;
    end
    out_mem_ZP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZP 1 
    element_file = $fopen("mem_ZP_1_1.txt", "r");
    # 10;
    $display("\nloading input ZP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZP_1_wr_en = 1'b1;
    out_mem_ZP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZP_1_din); 
      #10;
      out_mem_ZP_1_wr_addr = out_mem_ZP_1_wr_addr + 1;
    end
    out_mem_ZP_1_wr_en = 1'b0;
    end
    $fclose(element_file); 

    xADD_P_newly_loaded_pre = 1'b1;
    # 10;
    xADD_P_newly_loaded_pre = 1'b0;


// P is already read out and processed
    @(posedge xADD_P_can_overwrite);

//---------------------------------------------------------------------
    // load input memory XP 2
    // load XP 0
    element_file = $fopen("mem_XP_0_2.txt", "r");
    # 10;
    $display("\nloading input XP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XP_0_wr_en = 1'b1;
    out_mem_XP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XP_0_din); 
      #10;
      out_mem_XP_0_wr_addr = out_mem_XP_0_wr_addr + 1;
    end
    out_mem_XP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XP 1 
    element_file = $fopen("mem_XP_1_2.txt", "r");
    # 10;
    $display("\nloading input XP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_XP_1_wr_en = 1'b1;
    out_mem_XP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_XP_1_din); 
      #10;
      out_mem_XP_1_wr_addr = out_mem_XP_1_wr_addr + 1;
    end
    out_mem_XP_1_wr_en = 1'b0;
    end
    $fclose(element_file);     

     // load input memory ZP
    // load ZP 0
    element_file = $fopen("mem_ZP_0_2.txt", "r");
    # 10;
    $display("\nloading input ZP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZP_0_wr_en = 1'b1;
    out_mem_ZP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZP_0_din); 
      #10;
      out_mem_ZP_0_wr_addr = out_mem_ZP_0_wr_addr + 1;
    end
    out_mem_ZP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZP 1 
    element_file = $fopen("mem_ZP_1_2.txt", "r");
    # 10;
    $display("\nloading input ZP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_ZP_1_wr_en = 1'b1;
    out_mem_ZP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_ZP_1_din); 
      #10;
      out_mem_ZP_1_wr_addr = out_mem_ZP_1_wr_addr + 1;
    end
    out_mem_ZP_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    xADD_P_newly_loaded_pre = 1'b1;
    # 10;
    xADD_P_newly_loaded_pre = 1'b0; 


// wait for computation done
    // computation finishes
    @(posedge done);
    $display("\n    xADD computation finished in %0d cycles", ($time-start_time)/10);
 
    command_encoded <= 0;

//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------


    #100;
    $display("\nread result zPQ back...");

    element_file = $fopen("sim_zPQ_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_zPQ_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_zPQ_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_zPQ_0_dout); 
    end

    out_mem_zPQ_0_rd_en = 1'b0;

    $fclose(element_file);


    element_file = $fopen("sim_zPQ_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_zPQ_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_zPQ_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_zPQ_1_dout); 
    end

    out_mem_zPQ_1_rd_en = 1'b0;

    $fclose(element_file);
 
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------

    #100;
    $display("\nread result XQ back...");

    element_file = $fopen("sim_XQ_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_XQ_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_XQ_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_XQ_0_dout); 
    end

    out_mem_XQ_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_XQ_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_XQ_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_XQ_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_XQ_1_dout); 
    end

    out_mem_XQ_1_rd_en = 1'b0;

    $fclose(element_file);

    #100;
    $display("\nread result ZQ back...");

    element_file = $fopen("sim_ZQ_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_ZQ_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_ZQ_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_ZQ_0_dout); 
    end

    out_mem_ZQ_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_ZQ_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_ZQ_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_ZQ_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_ZQ_1_dout); 
    end

    out_mem_ZQ_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------

    #100;
    $display("\nread result xPQ back...");

    element_file = $fopen("sim_xPQ_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_xPQ_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_xPQ_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_xPQ_0_dout); 
    end

    out_mem_xPQ_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_xPQ_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_xPQ_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_xPQ_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_xPQ_1_dout); 
    end

    out_mem_xPQ_1_rd_en = 1'b0;

    $fclose(element_file);




//---------------------------------------------------------------------
    // load input for xDBLe
//---------------------------------------------------------------------
    rst <= 1'b0;
    start <= 1'b0;
    # 45;
    rst <= 1'b1;
    # 20;
    rst <= 1'b0;
    // load X
    element_file = $fopen("mem_X_0.txt", "r");
    # 10;
    $display("\nloading input for xDBLe...");
    $display("\nloading input X_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X_0_wr_en = 1'b1;
    out_mem_X_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X_0_din); 
      #10;
      out_mem_X_0_wr_addr = out_mem_X_0_wr_addr + 1;
    end
    out_mem_X_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    element_file = $fopen("mem_X_1.txt", "r");
    # 10;
    $display("\nloading input X_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X_1_wr_en = 1'b1;
    out_mem_X_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X_1_din); 
      #10;
      out_mem_X_1_wr_addr = out_mem_X_1_wr_addr + 1;
    end
    out_mem_X_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load X
    element_file = $fopen("mem_Z_0.txt", "r");
    # 10;
    $display("\nloading input Z_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z_0_wr_en = 1'b1;
    out_mem_Z_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z_0_din); 
      #10;
      out_mem_Z_0_wr_addr = out_mem_Z_0_wr_addr + 1;
    end
    out_mem_Z_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    element_file = $fopen("mem_Z_1.txt", "r");
    # 10;
    $display("\nloading input Z_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z_1_wr_en = 1'b1;
    out_mem_Z_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z_1_din); 
      #10;
      out_mem_Z_1_wr_addr = out_mem_Z_1_wr_addr + 1;
    end
    out_mem_Z_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load A24
    element_file = $fopen("mem_A24_0.txt", "r");
    # 10;
    $display("\nloading input A24_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_A24_0_wr_en = 1'b1;
    out_mem_A24_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_A24_0_din); 
      #10;
      out_mem_A24_0_wr_addr = out_mem_A24_0_wr_addr + 1;
    end
    out_mem_A24_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    element_file = $fopen("mem_A24_1.txt", "r");
    # 10;
    $display("\nloading input A24_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_A24_1_wr_en = 1'b1;
    out_mem_A24_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_A24_1_din); 
      #10;
      out_mem_A24_1_wr_addr = out_mem_A24_1_wr_addr + 1;
    end
    out_mem_A24_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load C24
    element_file = $fopen("mem_C24_0.txt", "r");
    # 10;
    $display("\nloading input C24_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_C24_0_wr_en = 1'b1;
    out_mem_C24_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_C24_0_din); 
      #10;
      out_mem_C24_0_wr_addr = out_mem_C24_0_wr_addr + 1;
    end
    out_mem_C24_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    element_file = $fopen("mem_C24_1.txt", "r");
    # 10;
    $display("\nloading input C24_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_C24_1_wr_en = 1'b1;
    out_mem_C24_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_C24_1_din); 
      #10;
      out_mem_C24_1_wr_addr = out_mem_C24_1_wr_addr + 1;
    end
    out_mem_C24_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // start computation
//---------------------------------------------------------------------
    # 15;
    start <= 1'b1;
    command_encoded <= 1;
    start_time = $time;
    $display("\n    start computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\n    computation finished in %0d cycles", ($time-start_time)/10);

//---------------------------------------------------------------------
    // return xDBLe result back
//---------------------------------------------------------------------
    #100;
    $display("\nread result X back...");

    element_file = $fopen("sim_X_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_X_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_X_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_X_0_dout); 
    end

    out_mem_X_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_X_1.txt", "w");
 
    #100;

    @(negedge clk);
    out_mem_X_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_X_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_X_1_dout); 
    end

    out_mem_X_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------

     #100;
    $display("\nread result Z back...");

    element_file = $fopen("sim_Z_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_Z_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_Z_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_Z_0_dout); 
    end

    out_mem_Z_0_rd_en = 1'b0;

    $fclose(element_file);
 
    element_file = $fopen("sim_Z_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_Z_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_Z_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_Z_1_dout); 
    end

    out_mem_Z_1_rd_en = 1'b0;

    $fclose(element_file);

    command_encoded <= 0;



//---------------------------------------------------------------------
    // load input for get_4_isog
//---------------------------------------------------------------------

    rst <= 1'b0;
    start <= 1'b0; 
    # 45;
    rst <= 1'b1;
    # 20;
    rst <= 1'b0;
 
//---------------------------------------------------------------------
    // load X4 and Z4 for get_4_isog 
    element_file = $fopen("get_4_isog_mem_X4_0.txt", "r");
    # 10;
    $display("\n\n\nloading input for get_4_isog...");
    $display("\nloading input X4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_0_wr_en = 1'b1;
    out_mem_X4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_0_din); 
      #10;
      out_mem_X4_0_wr_addr = out_mem_X4_0_wr_addr + 1;
    end
    out_mem_X4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X4_1 
    element_file = $fopen("get_4_isog_mem_X4_1.txt", "r");
    # 10;
    $display("\nloading input X4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_1_wr_en = 1'b1;
    out_mem_X4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_1_din); 
      #10;
      out_mem_X4_1_wr_addr = out_mem_X4_1_wr_addr + 1;
    end
    out_mem_X4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------

    element_file = $fopen("get_4_isog_mem_Z4_0.txt", "r");
    # 10;
    $display("\nloading input Z4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_0_wr_en = 1'b1;
    out_mem_Z4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_0_din); 
      #10;
      out_mem_Z4_0_wr_addr = out_mem_Z4_0_wr_addr + 1;
    end
    out_mem_Z4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load Z4_1 
    element_file = $fopen("get_4_isog_mem_Z4_1.txt", "r");
    # 10;
    $display("\nloading input Z4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_1_wr_en = 1'b1;
    out_mem_Z4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_1_din); 
      #10;
      out_mem_Z4_1_wr_addr = out_mem_Z4_1_wr_addr + 1;
    end
    out_mem_Z4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // start computation
//---------------------------------------------------------------------
    # 15;
    start <= 1'b1;
    command_encoded <= 2;
    start_time = $time;
    $display("\n    start get_4_isog computation");
    # 10;
    start <= 1'b0;  

//---------------------------------------------------------------------
    // load 1st input for eval_4_isog
//---------------------------------------------------------------------
    @(DUT.controller_done);
    # 1000; 
    $display("\nread get_4_isog result A24 back...");

    element_file = $fopen("sim_A24_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_A24_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_A24_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_A24_0_dout); 
    end

    out_mem_A24_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_A24_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_A24_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_A24_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_A24_1_dout); 
    end

    out_mem_A24_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread get_4_isog result C24 back...");

    element_file = $fopen("sim_C24_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_C24_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_C24_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_C24_0_dout); 
    end

    out_mem_C24_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("sim_C24_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_C24_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_C24_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_C24_1_dout); 
    end

    out_mem_C24_1_rd_en = 1'b0;
 
    # 10; 
    $fclose(element_file); 

//---------------------------------------------------------------------

    // load X_0 
    element_file = $fopen("0-sage_eval_4_isog_mem_X4_0.txt", "r");
    # 10;
    $display("\nloading 1st input for eval_4_isog...");
    $display("\nloading input X4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_0_wr_en = 1'b1;
    out_mem_X4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_0_din); 
      #10;
      out_mem_X4_0_wr_addr = out_mem_X4_0_wr_addr + 1;
    end
    out_mem_X4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("0-sage_eval_4_isog_mem_X4_1.txt", "r");
    # 10;
    $display("\nloading input X4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_1_wr_en = 1'b1;
    out_mem_X4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_1_din); 
      #10;
      out_mem_X4_1_wr_addr = out_mem_X4_1_wr_addr + 1;
    end
    out_mem_X4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------

    // load X_0 
    # 10;
    element_file = $fopen("0-sage_eval_4_isog_mem_Z4_0.txt", "r");
    # 10;
    $display("\nloading input Z4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_0_wr_en = 1'b1;
    out_mem_Z4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_0_din); 
      #10;
      out_mem_Z4_0_wr_addr = out_mem_Z4_0_wr_addr + 1;
    end
    out_mem_Z4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("0-sage_eval_4_isog_mem_Z4_1.txt", "r");
    # 10;
    $display("\nloading input Z4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_1_wr_en = 1'b1;
    out_mem_Z4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_1_din); 
      #10;
      out_mem_Z4_1_wr_addr = out_mem_Z4_1_wr_addr + 1;
    end
    out_mem_Z4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    eval_4_isog_XZ_newly_init_pre = 1'b1;
    # 10;
    eval_4_isog_XZ_newly_init_pre = 1'b0;

//---------------------------------------------------------------------
//---------- read back eval_4_isog result  ----------------------------
//---------------------------------------------------------------------

    @(posedge eval_4_isog_result_ready); 
    #100;
    $display("\nread back 1st result of eval_4_isog...");
    $display("\nread result t10 back...");

    element_file = $fopen("0-sim_t10_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t10_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t10_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t10_0_dout); 
    end

    out_mem_t10_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("0-sim_t10_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t10_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t10_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t10_1_dout); 
    end

    out_mem_t10_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread result t11 back...");

    element_file = $fopen("0-sim_t11_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t11_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t11_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t11_0_dout); 
    end

    out_mem_t11_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("0-sim_t11_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t11_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t11_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t11_1_dout); 
    end

    out_mem_t11_1_rd_en = 1'b0;

    eval_4_isog_result_can_overwrite_pre = 1'b1;
    # 10;
    eval_4_isog_result_can_overwrite_pre = 1'b0;

    $fclose(element_file); 


//---------------------------------------------------------------------
    // load 2nd input for eval_4_isog
//---------------------------------------------------------------------
    // load X_0 
    # 10;
    element_file = $fopen("1-sage_eval_4_isog_mem_X4_0.txt", "r");
    # 10;
    $display("\nloading 2nd input for eval_4_isog...");
    $display("\nloading input X4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_0_wr_en = 1'b1;
    out_mem_X4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_0_din); 
      #10;
      out_mem_X4_0_wr_addr = out_mem_X4_0_wr_addr + 1;
    end
    out_mem_X4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("1-sage_eval_4_isog_mem_X4_1.txt", "r");
    # 10;
    $display("\nloading input X4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_1_wr_en = 1'b1;
    out_mem_X4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_1_din); 
      #10;
      out_mem_X4_1_wr_addr = out_mem_X4_1_wr_addr + 1;
    end
    out_mem_X4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------

    // load X_0 
    # 10;
    element_file = $fopen("1-sage_eval_4_isog_mem_Z4_0.txt", "r");
    # 10;
    $display("\nloading input Z4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_0_wr_en = 1'b1;
    out_mem_Z4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_0_din); 
      #10;
      out_mem_Z4_0_wr_addr = out_mem_Z4_0_wr_addr + 1;
    end
    out_mem_Z4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("1-sage_eval_4_isog_mem_Z4_1.txt", "r");
    # 10;
    $display("\nloading input Z4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_1_wr_en = 1'b1;
    out_mem_Z4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_1_din); 
      #10;
      out_mem_Z4_1_wr_addr = out_mem_Z4_1_wr_addr + 1;
    end
    out_mem_Z4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    eval_4_isog_XZ_newly_init_pre = 1'b1;
    # 10;
    eval_4_isog_XZ_newly_init_pre = 1'b0;

//---------------------------------------------------------------------
//---------- read back eval_4_isog result  ----------------------------
//---------------------------------------------------------------------

    @(posedge eval_4_isog_result_ready); 
    #100;
    $display("\nread back 2nd result of eval_4_isog...");
    $display("\nread result t10 back...");

    element_file = $fopen("1-sim_t10_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t10_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t10_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t10_0_dout); 
    end

    out_mem_t10_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("1-sim_t10_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t10_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t10_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t10_1_dout); 
    end

    out_mem_t10_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread result t11 back...");

    element_file = $fopen("1-sim_t11_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t11_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t11_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t11_0_dout); 
    end

    out_mem_t11_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("1-sim_t11_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t11_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t11_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t11_1_dout); 
    end

    out_mem_t11_1_rd_en = 1'b0;

    eval_4_isog_result_can_overwrite_pre = 1'b1;
    # 10;
    eval_4_isog_result_can_overwrite_pre = 1'b0;

    $fclose(element_file); 
 
//---------------------------------------------------------------------
    // load 3rd input for eval_4_isog
//---------------------------------------------------------------------
    // load X_0 
    # 10;
    last_eval_4_isog <= 1'b1;
    element_file = $fopen("2-sage_eval_4_isog_mem_X4_0.txt", "r");
    # 10;
    $display("\nloading 3rd input for eval_4_isog...");
    $display("\nloading input X4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_0_wr_en = 1'b1;
    out_mem_X4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_0_din); 
      #10;
      out_mem_X4_0_wr_addr = out_mem_X4_0_wr_addr + 1;
    end
    out_mem_X4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("2-sage_eval_4_isog_mem_X4_1.txt", "r");
    # 10;
    $display("\nloading input X4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_X4_1_wr_en = 1'b1;
    out_mem_X4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_X4_1_din); 
      #10;
      out_mem_X4_1_wr_addr = out_mem_X4_1_wr_addr + 1;
    end
    out_mem_X4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------

    // load X_0 
    # 10;
    element_file = $fopen("2-sage_eval_4_isog_mem_Z4_0.txt", "r");
    # 10;
    $display("\nloading input Z4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_0_wr_en = 1'b1;
    out_mem_Z4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_0_din); 
      #10;
      out_mem_Z4_0_wr_addr = out_mem_Z4_0_wr_addr + 1;
    end
    out_mem_Z4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("2-sage_eval_4_isog_mem_Z4_1.txt", "r");
    # 10;
    $display("\nloading input Z4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    out_mem_Z4_1_wr_en = 1'b1;
    out_mem_Z4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", out_mem_Z4_1_din); 
      #10;
      out_mem_Z4_1_wr_addr = out_mem_Z4_1_wr_addr + 1;
    end
    out_mem_Z4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    eval_4_isog_XZ_newly_init_pre = 1'b1;
    # 10;
    eval_4_isog_XZ_newly_init_pre = 1'b0; 
//---------------------------------------------------------------------
    // computation finishes
//---------------------------------------------------------------------
    @(posedge done);
    $display("\n    computation finished in %0d cycles", ($time-start_time)/10);

//---------------------------------------------------------------------
//---------- read back eval_4_isog result  ----------------------------
//---------------------------------------------------------------------
 
    #100;
    $display("\nread back 3rd result of eval_4_isog...");
    $display("\nread result t10 back...");

    element_file = $fopen("2-sim_t10_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t10_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t10_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t10_0_dout); 
    end

    out_mem_t10_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("2-sim_t10_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t10_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t10_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t10_1_dout); 
    end

    out_mem_t10_1_rd_en = 1'b0;

    $fclose(element_file);

//---------------------------------------------------------------------
    #100;
    $display("\nread result t11 back...");

    element_file = $fopen("2-sim_t11_0.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t11_0_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t11_0_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t11_0_dout); 
    end

    out_mem_t11_0_rd_en = 1'b0;

    $fclose(element_file);

    element_file = $fopen("2-sim_t11_1.txt", "w");

    #100;

    @(negedge clk);
    out_mem_t11_1_rd_en = 1'b1;

    for (i=0; i<SINGLE_MEM_DEPTH; i=i+1) begin
      out_mem_t11_1_rd_addr = i;
      # 10; 
      $fwrite(element_file, "%b\n", mem_t11_1_dout); 
    end

    out_mem_t11_1_rd_en = 1'b0;

    eval_4_isog_result_can_overwrite_pre = 1'b1;
    # 10;
    eval_4_isog_result_can_overwrite_pre = 1'b0;

    $fclose(element_file); 


    #1000;
    $finish;
  end



top_controller #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL), .SK_MEM_WIDTH(SK_MEM_WIDTH), .SK_MEM_DEPTH(SK_MEM_DEPTH)) DUT (
  .rst(rst),
  .clk(clk),
  .start(start),
  .xADD_P_newly_loaded(xADD_P_newly_loaded),
  .xADD_P_can_overwrite(xADD_P_can_overwrite),
  //
  .out_mult_A_start(out_mult_A_start),
  .out_mult_A_mem_a_0_wr_en(out_mult_A_mem_a_0_wr_en),
  .out_mult_A_mem_a_0_wr_addr(out_mult_A_mem_a_0_wr_addr),
  .out_mult_A_mem_a_0_din(out_mult_A_mem_a_0_din),
  .out_mult_A_mem_a_1_wr_en(out_mult_A_mem_a_1_wr_en),
  .out_mult_A_mem_a_1_wr_addr(out_mult_A_mem_a_1_wr_addr),
  .out_mult_A_mem_a_1_din(out_mult_A_mem_a_1_din),
  .out_mult_A_mem_b_0_wr_en(out_mult_A_mem_b_0_wr_en),
  .out_mult_A_mem_b_0_wr_addr(out_mult_A_mem_b_0_wr_addr),
  .out_mult_A_mem_b_0_din(out_mult_A_mem_b_0_din),
  .out_mult_A_mem_b_1_wr_en(out_mult_A_mem_b_1_wr_en),
  .out_mult_A_mem_b_1_wr_addr(out_mult_A_mem_b_1_wr_addr),
  .out_mult_A_mem_b_1_din(out_mult_A_mem_b_1_din),
  .out_sub_mult_A_mem_res_rd_en(out_sub_mult_A_mem_res_rd_en),
  .out_sub_mult_A_mem_res_rd_addr(out_sub_mult_A_mem_res_rd_addr),
  .sub_mult_A_mem_res_dout(sub_mult_A_mem_res_dout),
  .out_add_mult_A_mem_res_rd_en(out_add_mult_A_mem_res_rd_en),
  .out_add_mult_A_mem_res_rd_addr(out_add_mult_A_mem_res_rd_addr),
  .add_mult_A_mem_res_dout(add_mult_A_mem_res_dout),
  //
  .command_encoded(command_encoded), 
  .xDBLe_NUM_LOOPS(xDBLe_NUM_LOOPS),
  .eval_4_isog_XZ_newly_init(eval_4_isog_XZ_newly_init),
  .last_eval_4_isog(last_eval_4_isog),
  .eval_4_isog_result_can_overwrite(eval_4_isog_result_can_overwrite),
  .eval_4_isog_XZ_can_overwrite(eval_4_isog_XZ_can_overwrite),
  .eval_4_isog_result_ready(eval_4_isog_result_ready),
  .xADD_loop_start_index(xADD_loop_start_index),
  .xADD_loop_end_index(xADD_loop_end_index), 
  .done(done),
  .busy(busy), 
  .out_mem_X_0_wr_en(out_mem_X_0_wr_en),
  .out_mem_X_0_wr_addr(out_mem_X_0_wr_addr),
  .out_mem_X_0_din(out_mem_X_0_din), 
  .mem_X_0_dout(mem_X_0_dout),
  .out_mem_X_0_rd_en(out_mem_X_0_rd_en),
  .out_mem_X_0_rd_addr(out_mem_X_0_rd_addr), 
  .out_mem_X_1_wr_en(out_mem_X_1_wr_en),
  .out_mem_X_1_wr_addr(out_mem_X_1_wr_addr),
  .out_mem_X_1_din(out_mem_X_1_din), 
  .mem_X_1_dout(mem_X_1_dout),
  .out_mem_X_1_rd_en(out_mem_X_1_rd_en),
  .out_mem_X_1_rd_addr(out_mem_X_1_rd_addr), 
  .out_mem_Z_0_wr_en(out_mem_Z_0_wr_en),
  .out_mem_Z_0_wr_addr(out_mem_Z_0_wr_addr),
  .out_mem_Z_0_din(out_mem_Z_0_din), 
  .mem_Z_0_dout(mem_Z_0_dout),
  .out_mem_Z_0_rd_en(out_mem_Z_0_rd_en),
  .out_mem_Z_0_rd_addr(out_mem_Z_0_rd_addr), 
  .out_mem_Z_1_wr_en(out_mem_Z_1_wr_en),
  .out_mem_Z_1_wr_addr(out_mem_Z_1_wr_addr),
  .out_mem_Z_1_din(out_mem_Z_1_din), 
  .mem_Z_1_dout(mem_Z_1_dout),
  .out_mem_Z_1_rd_en(out_mem_Z_1_rd_en),
  .out_mem_Z_1_rd_addr(out_mem_Z_1_rd_addr), 
  .out_mem_X4_0_wr_en(out_mem_X4_0_wr_en),
  .out_mem_X4_0_wr_addr(out_mem_X4_0_wr_addr),
  .out_mem_X4_0_din(out_mem_X4_0_din), 
  .out_mem_X4_1_wr_en(out_mem_X4_1_wr_en),
  .out_mem_X4_1_wr_addr(out_mem_X4_1_wr_addr),
  .out_mem_X4_1_din(out_mem_X4_1_din), 
  .out_mem_Z4_0_wr_en(out_mem_Z4_0_wr_en),
  .out_mem_Z4_0_wr_addr(out_mem_Z4_0_wr_addr),
  .out_mem_Z4_0_din(out_mem_Z4_0_din), 
  .out_mem_Z4_1_wr_en(out_mem_Z4_1_wr_en),
  .out_mem_Z4_1_wr_addr(out_mem_Z4_1_wr_addr),
  .out_mem_Z4_1_din(out_mem_Z4_1_din), 
  .out_mem_t10_0_rd_en(out_mem_t10_0_rd_en),
  .out_mem_t10_0_rd_addr(out_mem_t10_0_rd_addr), 
  .mem_t10_0_dout(mem_t10_0_dout), 
  .out_mem_t10_1_rd_en(out_mem_t10_1_rd_en),
  .out_mem_t10_1_rd_addr(out_mem_t10_1_rd_addr), 
  .mem_t10_1_dout(mem_t10_1_dout), 
  .out_mem_t11_0_rd_en(out_mem_t11_0_rd_en),
  .out_mem_t11_0_rd_addr(out_mem_t11_0_rd_addr), 
  .mem_t11_0_dout(mem_t11_0_dout), 
  .out_mem_t11_1_rd_en(out_mem_t11_1_rd_en),
  .out_mem_t11_1_rd_addr(out_mem_t11_1_rd_addr), 
  .mem_t11_1_dout(mem_t11_1_dout), 
  .out_mem_XP_0_wr_en(out_mem_XP_0_wr_en),
  .out_mem_XP_0_wr_addr(out_mem_XP_0_wr_addr),
  .out_mem_XP_0_din(out_mem_XP_0_din), 
  .out_mem_XP_1_wr_en(out_mem_XP_1_wr_en),
  .out_mem_XP_1_wr_addr(out_mem_XP_1_wr_addr),
  .out_mem_XP_1_din(out_mem_XP_1_din), 
  .mem_XP_0_dout(mem_XP_0_dout),
  .out_mem_XP_0_rd_en(out_mem_XP_0_rd_en),
  .out_mem_XP_0_rd_addr(out_mem_XP_0_rd_addr), 
  .mem_XP_1_dout(mem_XP_1_dout),
  .out_mem_XP_1_rd_en(out_mem_XP_1_rd_en),
  .out_mem_XP_1_rd_addr(out_mem_XP_1_rd_addr), 
  .out_mem_ZP_0_wr_en(out_mem_ZP_0_wr_en),
  .out_mem_ZP_0_wr_addr(out_mem_ZP_0_wr_addr),
  .out_mem_ZP_0_din(out_mem_ZP_0_din), 
  .out_mem_ZP_1_wr_en(out_mem_ZP_1_wr_en),
  .out_mem_ZP_1_wr_addr(out_mem_ZP_1_wr_addr),
  .out_mem_ZP_1_din(out_mem_ZP_1_din), 
  .mem_ZP_0_dout(mem_ZP_0_dout),
  .out_mem_ZP_0_rd_en(out_mem_ZP_0_rd_en),
  .out_mem_ZP_0_rd_addr(out_mem_ZP_0_rd_addr), 
  .mem_ZP_1_dout(mem_ZP_1_dout),
  .out_mem_ZP_1_rd_en(out_mem_ZP_1_rd_en),
  .out_mem_ZP_1_rd_addr(out_mem_ZP_1_rd_addr), 
  .out_mem_XQ_0_wr_en(out_mem_XQ_0_wr_en),
  .out_mem_XQ_0_wr_addr(out_mem_XQ_0_wr_addr),
  .out_mem_XQ_0_din(out_mem_XQ_0_din), 
  .out_mem_XQ_1_wr_en(out_mem_XQ_1_wr_en),
  .out_mem_XQ_1_wr_addr(out_mem_XQ_1_wr_addr),
  .out_mem_XQ_1_din(out_mem_XQ_1_din), 
  .mem_XQ_0_dout(mem_XQ_0_dout),
  .out_mem_XQ_0_rd_en(out_mem_XQ_0_rd_en),
  .out_mem_XQ_0_rd_addr(out_mem_XQ_0_rd_addr), 
  .mem_XQ_1_dout(mem_XQ_1_dout),
  .out_mem_XQ_1_rd_en(out_mem_XQ_1_rd_en),
  .out_mem_XQ_1_rd_addr(out_mem_XQ_1_rd_addr), 
  .out_mem_ZQ_0_wr_en(out_mem_ZQ_0_wr_en),
  .out_mem_ZQ_0_wr_addr(out_mem_ZQ_0_wr_addr),
  .out_mem_ZQ_0_din(out_mem_ZQ_0_din), 
  .out_mem_ZQ_1_wr_en(out_mem_ZQ_1_wr_en),
  .out_mem_ZQ_1_wr_addr(out_mem_ZQ_1_wr_addr),
  .out_mem_ZQ_1_din(out_mem_ZQ_1_din), 
  .mem_ZQ_0_dout(mem_ZQ_0_dout),
  .out_mem_ZQ_0_rd_en(out_mem_ZQ_0_rd_en),
  .out_mem_ZQ_0_rd_addr(out_mem_ZQ_0_rd_addr), 
  .mem_ZQ_1_dout(mem_ZQ_1_dout),
  .out_mem_ZQ_1_rd_en(out_mem_ZQ_1_rd_en),
  .out_mem_ZQ_1_rd_addr(out_mem_ZQ_1_rd_addr), 
  .out_mem_xPQ_0_wr_en(out_mem_xPQ_0_wr_en),
  .out_mem_xPQ_0_wr_addr(out_mem_xPQ_0_wr_addr),
  .out_mem_xPQ_0_din(out_mem_xPQ_0_din), 
  .out_mem_xPQ_1_wr_en(out_mem_xPQ_1_wr_en),
  .out_mem_xPQ_1_wr_addr(out_mem_xPQ_1_wr_addr),
  .out_mem_xPQ_1_din(out_mem_xPQ_1_din),  
  .mem_xPQ_0_dout(mem_xPQ_0_dout),
  .out_mem_xPQ_0_rd_en(out_mem_xPQ_0_rd_en),
  .out_mem_xPQ_0_rd_addr(out_mem_xPQ_0_rd_addr), 
  .mem_xPQ_1_dout(mem_xPQ_1_dout),
  .out_mem_xPQ_1_rd_en(out_mem_xPQ_1_rd_en),
  .out_mem_xPQ_1_rd_addr(out_mem_xPQ_1_rd_addr), 
  .out_mem_zPQ_0_wr_en(out_mem_zPQ_0_wr_en),
  .out_mem_zPQ_0_wr_addr(out_mem_zPQ_0_wr_addr),
  .out_mem_zPQ_0_din(out_mem_zPQ_0_din), 
  .out_mem_zPQ_1_wr_en(out_mem_zPQ_1_wr_en),
  .out_mem_zPQ_1_wr_addr(out_mem_zPQ_1_wr_addr),
  .out_mem_zPQ_1_din(out_mem_zPQ_1_din), 
  .out_mem_zPQ_0_rd_en(out_mem_zPQ_0_rd_en),
  .out_mem_zPQ_0_rd_addr(out_mem_zPQ_0_rd_addr), 
  .mem_zPQ_1_dout(mem_zPQ_1_dout),
  .out_mem_zPQ_1_rd_en(out_mem_zPQ_1_rd_en),
  .out_mem_zPQ_1_rd_addr(out_mem_zPQ_1_rd_addr), 
  .out_mem_A24_0_wr_en(out_mem_A24_0_wr_en),
  .out_mem_A24_0_wr_addr(out_mem_A24_0_wr_addr),
  .out_mem_A24_0_din(out_mem_A24_0_din), 
  .out_mem_A24_1_wr_en(out_mem_A24_1_wr_en),
  .out_mem_A24_1_wr_addr(out_mem_A24_1_wr_addr),
  .out_mem_A24_1_din(out_mem_A24_1_din), 
  .mem_A24_0_dout(mem_A24_0_dout),
  .out_mem_A24_0_rd_en(out_mem_A24_0_rd_en),
  .out_mem_A24_0_rd_addr(out_mem_A24_0_rd_addr), 
  .mem_A24_1_dout(mem_A24_1_dout),
  .out_mem_A24_1_rd_en(out_mem_A24_1_rd_en),
  .out_mem_A24_1_rd_addr(out_mem_A24_1_rd_addr), 
  .out_mem_C24_0_wr_en(out_mem_C24_0_wr_en),
  .out_mem_C24_0_wr_addr(out_mem_C24_0_wr_addr),
  .out_mem_C24_0_din(out_mem_C24_0_din), 
  .out_mem_C24_1_wr_en(out_mem_C24_1_wr_en),
  .out_mem_C24_1_wr_addr(out_mem_C24_1_wr_addr),
  .out_mem_C24_1_din(out_mem_C24_1_din), 
  .mem_C24_0_dout(mem_C24_0_dout),
  .out_mem_C24_0_rd_en(out_mem_C24_0_rd_en),
  .out_mem_C24_0_rd_addr(out_mem_C24_0_rd_addr), 
  .mem_C24_1_dout(mem_C24_1_dout),
  .out_mem_C24_1_rd_en(out_mem_C24_1_rd_en),
  .out_mem_C24_1_rd_addr(out_mem_C24_1_rd_addr),
  .out_sk_mem_wr_en(out_sk_mem_wr_en),
  .out_sk_mem_wr_addr(out_sk_mem_wr_addr),
  .out_sk_mem_din(out_sk_mem_din)
);

always 
  # 5 clk = !clk;
  
endmodule
