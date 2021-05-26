/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for xADD
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

// outputs 
wire done;
wire busy;
 
// interface with memory XP
reg mem_XP_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_XP_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_XP_0_dout;
wire mem_XP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_0_rd_addr;

reg mem_XP_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_XP_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_XP_1_dout;
wire mem_XP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XP_1_rd_addr;

// interface with memory ZP
reg mem_ZP_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_dout;
wire mem_ZP_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_0_rd_addr;

reg mem_ZP_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_dout;
wire mem_ZP_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZP_1_rd_addr;

// interface with memory XQ
reg mem_XQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_dout;
wire mem_XQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_0_rd_addr;

reg mem_XQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_dout;
wire mem_XQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_XQ_1_rd_addr;

// interface with memory ZQ
reg mem_ZQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_dout;
wire mem_ZQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_0_rd_addr;

reg mem_ZQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_dout;
wire mem_ZQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_ZQ_1_rd_addr;
 
// interface with memory xPQ
reg mem_xPQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_dout;
wire mem_xPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_0_rd_addr;

reg mem_xPQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_dout;
wire mem_xPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_xPQ_1_rd_addr;

// interface with memory zPQ
reg mem_zPQ_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_dout;
wire mem_zPQ_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_0_rd_addr;

reg mem_zPQ_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_dout;
wire mem_zPQ_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_zPQ_1_rd_addr;

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
    # 45;
    rst <= 1'b1;
    # 20;
    rst <= 1'b0;

//---------------------------------------------------------------------
    // load XP_0, XP_1, ZP_0, ZP_1, XQ_0, XQ_1, ZQ_0, ZQ_1, A24_0, A24_1, xPQ_0, and xPQ_1
// load XP_0 
    element_file = $fopen("xADD_mem_XP_0.txt", "r");
    # 10;
    $display("\nloading input XP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_XP_0_wr_en = 1'b1;
    mem_XP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_XP_0_din); 
      #10;
      mem_XP_0_wr_addr = mem_XP_0_wr_addr + 1;
    end
    mem_XP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XP_1 
    element_file = $fopen("xADD_mem_XP_1.txt", "r");
    # 10;
    $display("\nloading input XP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_XP_1_wr_en = 1'b1;
    mem_XP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_XP_1_din); 
      #10;
      mem_XP_1_wr_addr = mem_XP_1_wr_addr + 1;
    end
    mem_XP_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load ZP_0 
    element_file = $fopen("xADD_mem_ZP_0.txt", "r");
    # 10;
    $display("\nloading input ZP_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_ZP_0_wr_en = 1'b1;
    mem_ZP_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_ZP_0_din); 
      #10;
      mem_ZP_0_wr_addr = mem_ZP_0_wr_addr + 1;
    end
    mem_ZP_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZP_1 
    element_file = $fopen("xADD_mem_ZP_1.txt", "r");
    # 10;
    $display("\nloading input ZP_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_ZP_1_wr_en = 1'b1;
    mem_ZP_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_ZP_1_din); 
      #10;
      mem_ZP_1_wr_addr = mem_ZP_1_wr_addr + 1;
    end
    mem_ZP_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load XQ_0 
    element_file = $fopen("xADD_mem_XQ_0.txt", "r");
    # 10;
    $display("\nloading input XQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_XQ_0_wr_en = 1'b1;
    mem_XQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_XQ_0_din); 
      #10;
      mem_XQ_0_wr_addr = mem_XQ_0_wr_addr + 1;
    end
    mem_XQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load XQ_1 
    element_file = $fopen("xADD_mem_XQ_1.txt", "r");
    # 10;
    $display("\nloading input XQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_XQ_1_wr_en = 1'b1;
    mem_XQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_XQ_1_din); 
      #10;
      mem_XQ_1_wr_addr = mem_XQ_1_wr_addr + 1;
    end
    mem_XQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load ZQ_0 
    element_file = $fopen("xADD_mem_ZQ_0.txt", "r");
    # 10;
    $display("\nloading input ZQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_ZQ_0_wr_en = 1'b1;
    mem_ZQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_ZQ_0_din); 
      #10;
      mem_ZQ_0_wr_addr = mem_ZQ_0_wr_addr + 1;
    end
    mem_ZQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load ZQ_1 
    element_file = $fopen("xADD_mem_ZQ_1.txt", "r");
    # 10;
    $display("\nloading input ZQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_ZQ_1_wr_en = 1'b1;
    mem_ZQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_ZQ_1_din); 
      #10;
      mem_ZQ_1_wr_addr = mem_ZQ_1_wr_addr + 1;
    end
    mem_ZQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
    // load xPQ_0 
    element_file = $fopen("xADD_mem_xPQ_0.txt", "r");
    # 10;
    $display("\nloading input xPQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_xPQ_0_wr_en = 1'b1;
    mem_xPQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_xPQ_0_din); 
      #10;
      mem_xPQ_0_wr_addr = mem_xPQ_0_wr_addr + 1;
    end
    mem_xPQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load xPQ_1 
    element_file = $fopen("xADD_mem_xPQ_1.txt", "r");
    # 10;
    $display("\nloading input xPQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_xPQ_1_wr_en = 1'b1;
    mem_xPQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_xPQ_1_din); 
      #10;
      mem_xPQ_1_wr_addr = mem_xPQ_1_wr_addr + 1;
    end
    mem_xPQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load zPQ_0 
    element_file = $fopen("xADD_mem_zPQ_0.txt", "r");
    # 10;
    $display("\nloading input zPQ_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_zPQ_0_wr_en = 1'b1;
    mem_zPQ_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_zPQ_0_din); 
      #10;
      mem_zPQ_0_wr_addr = mem_zPQ_0_wr_addr + 1;
    end
    mem_zPQ_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load zPQ_1 
    element_file = $fopen("xADD_mem_zPQ_1.txt", "r");
    # 10;
    $display("\nloading input zPQ_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_zPQ_1_wr_en = 1'b1;
    mem_zPQ_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_zPQ_1_din); 
      #10;
      mem_zPQ_1_wr_addr = mem_zPQ_1_wr_addr + 1;
    end
    mem_zPQ_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
//---------------------------------------------------------------------
    // start computation
    # 15;
    start <= 1'b1;
    start_time = $time;
    $display("\n    start computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\n    comptation finished in %0d cycles", ($time-start_time)/10);
 
//---------------------------------------------------------------------

    #100;
    $display("\nread result t2 back...");

    element_file = $fopen("sim_t2_0.txt", "w");

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

    element_file = $fopen("sim_t2_1.txt", "w");

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
    $display("\nread result t3 back...");

    element_file = $fopen("sim_t3_0.txt", "w");

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

    element_file = $fopen("sim_t3_1.txt", "w");

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
    $display("\ncomparing results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;
      
    $finish;

end 

controller #(.RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL)) controller_inst (
  .rst(rst),
  .clk(clk),
  .start(start),
  .done(done),
  .busy(busy),
  .mem_XP_0_dout(mem_XP_0_dout),
  .mem_XP_0_rd_en(mem_XP_0_rd_en),
  .mem_XP_0_rd_addr(mem_XP_0_rd_addr),
  .mem_XP_1_dout(mem_XP_1_dout),
  .mem_XP_1_rd_en(mem_XP_1_rd_en),
  .mem_XP_1_rd_addr(mem_XP_1_rd_addr),
  .mem_ZP_0_dout(mem_ZP_0_dout),
  .mem_ZP_0_rd_en(mem_ZP_0_rd_en),
  .mem_ZP_0_rd_addr(mem_ZP_0_rd_addr),
  .mem_ZP_1_dout(mem_ZP_1_dout),
  .mem_ZP_1_rd_en(mem_ZP_1_rd_en),
  .mem_ZP_1_rd_addr(mem_ZP_1_rd_addr),
  .mem_XQ_0_dout(mem_XQ_0_dout),
  .mem_XQ_0_rd_en(mem_XQ_0_rd_en),
  .mem_XQ_0_rd_addr(mem_XQ_0_rd_addr),
  .mem_XQ_1_dout(mem_XQ_1_dout),
  .mem_XQ_1_rd_en(mem_XQ_1_rd_en),
  .mem_XQ_1_rd_addr(mem_XQ_1_rd_addr),
  .mem_ZQ_0_dout(mem_ZQ_0_dout),
  .mem_ZQ_0_rd_en(mem_ZQ_0_rd_en),
  .mem_ZQ_0_rd_addr(mem_ZQ_0_rd_addr),
  .mem_ZQ_1_dout(mem_ZQ_1_dout),
  .mem_ZQ_1_rd_en(mem_ZQ_1_rd_en),
  .mem_ZQ_1_rd_addr(mem_ZQ_1_rd_addr), 
  .mem_xPQ_0_dout(mem_xPQ_0_dout),
  .mem_xPQ_0_rd_en(mem_xPQ_0_rd_en),
  .mem_xPQ_0_rd_addr(mem_xPQ_0_rd_addr),
  .mem_xPQ_1_dout(mem_xPQ_1_dout),
  .mem_xPQ_1_rd_en(mem_xPQ_1_rd_en),
  .mem_xPQ_1_rd_addr(mem_xPQ_1_rd_addr),
  .mem_zPQ_0_dout(mem_zPQ_0_dout),
  .mem_zPQ_0_rd_en(mem_zPQ_0_rd_en),
  .mem_zPQ_0_rd_addr(mem_zPQ_0_rd_addr),
  .mem_zPQ_1_dout(mem_zPQ_1_dout),
  .mem_zPQ_1_rd_en(mem_zPQ_1_rd_en),
  .mem_zPQ_1_rd_addr(mem_zPQ_1_rd_addr),
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
  .mem_t3_1_dout(mem_t3_1_dout) 
  );
 
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XP_0 (  
  .clock(clk),
  .data(mem_XP_0_din),
  .address(mem_XP_0_wr_en ? mem_XP_0_wr_addr : (mem_XP_0_rd_en ? mem_XP_0_rd_addr : 0)),
  .wr_en(mem_XP_0_wr_en),
  .q(mem_XP_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XP_1 (  
  .clock(clk),
  .data(mem_XP_1_din),
  .address(mem_XP_1_wr_en ? mem_XP_1_wr_addr : (mem_XP_1_rd_en ? mem_XP_1_rd_addr : 0)),
  .wr_en(mem_XP_1_wr_en),
  .q(mem_XP_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZP_0 (  
  .clock(clk),
  .data(mem_ZP_0_din),
  .address(mem_ZP_0_wr_en ? mem_ZP_0_wr_addr : (mem_ZP_0_rd_en ? mem_ZP_0_rd_addr : 0)),
  .wr_en(mem_ZP_0_wr_en),
  .q(mem_ZP_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZP_1 (  
  .clock(clk),
  .data(mem_ZP_1_din),
  .address(mem_ZP_1_wr_en ? mem_ZP_1_wr_addr : (mem_ZP_1_rd_en ? mem_ZP_1_rd_addr : 0)),
  .wr_en(mem_ZP_1_wr_en),
  .q(mem_ZP_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XQ_0 (  
  .clock(clk),
  .data(mem_XQ_0_din),
  .address(mem_XQ_0_wr_en ? mem_XQ_0_wr_addr : (mem_XQ_0_rd_en ? mem_XQ_0_rd_addr : 0)),
  .wr_en(mem_XQ_0_wr_en),
  .q(mem_XQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_XQ_1 (  
  .clock(clk),
  .data(mem_XQ_1_din),
  .address(mem_XQ_1_wr_en ? mem_XQ_1_wr_addr : (mem_XQ_1_rd_en ? mem_XQ_1_rd_addr : 0)),
  .wr_en(mem_XQ_1_wr_en),
  .q(mem_XQ_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZQ_0 (  
  .clock(clk),
  .data(mem_ZQ_0_din),
  .address(mem_ZQ_0_wr_en ? mem_ZQ_0_wr_addr : (mem_ZQ_0_rd_en ? mem_ZQ_0_rd_addr : 0)),
  .wr_en(mem_ZQ_0_wr_en),
  .q(mem_ZQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_ZQ_1 (  
  .clock(clk),
  .data(mem_ZQ_1_din),
  .address(mem_ZQ_1_wr_en ? mem_ZQ_1_wr_addr : (mem_ZQ_1_rd_en ? mem_ZQ_1_rd_addr : 0)),
  .wr_en(mem_ZQ_1_wr_en),
  .q(mem_ZQ_1_dout)
  );
 

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_xPQ_0 (  
  .clock(clk),
  .data(mem_xPQ_0_din),
  .address(mem_xPQ_0_wr_en ? mem_xPQ_0_wr_addr : (mem_xPQ_0_rd_en ? mem_xPQ_0_rd_addr : 0)),
  .wr_en(mem_xPQ_0_wr_en),
  .q(mem_xPQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_xPQ_1 (  
  .clock(clk),
  .data(mem_xPQ_1_din),
  .address(mem_xPQ_1_wr_en ? mem_xPQ_1_wr_addr : (mem_xPQ_1_rd_en ? mem_xPQ_1_rd_addr : 0)),
  .wr_en(mem_xPQ_1_wr_en),
  .q(mem_xPQ_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_zPQ_0 (  
  .clock(clk),
  .data(mem_zPQ_0_din),
  .address(mem_zPQ_0_wr_en ? mem_zPQ_0_wr_addr : (mem_zPQ_0_rd_en ? mem_zPQ_0_rd_addr : 0)),
  .wr_en(mem_zPQ_0_wr_en),
  .q(mem_zPQ_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_zPQ_1 (  
  .clock(clk),
  .data(mem_zPQ_1_din),
  .address(mem_zPQ_1_wr_en ? mem_zPQ_1_wr_addr : (mem_zPQ_1_rd_en ? mem_zPQ_1_rd_addr : 0)),
  .wr_en(mem_zPQ_1_wr_en),
  .q(mem_zPQ_1_dout)
  );

always 
  # 5 clk = !clk;


endmodule