/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for eval_4_isog
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
 
// interface with memory X
reg mem_X_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_X_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_X_0_dout;
wire mem_X_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_0_rd_addr;

reg mem_X_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_X_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_X_1_dout;
wire mem_X_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X_1_rd_addr;

// interface with memory C0
reg mem_C0_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_C0_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_C0_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_C0_0_dout;
wire mem_C0_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C0_0_rd_addr;

reg mem_C0_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_C0_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_C0_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_C0_1_dout;
wire mem_C0_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C0_1_rd_addr;

// interface with memory C1
reg mem_C1_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_C1_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_C1_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_C1_0_dout;
wire mem_C1_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C1_0_rd_addr;

reg mem_C1_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_C1_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_C1_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_C1_1_dout;
wire mem_C1_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C1_1_rd_addr;

// interface with memory C2
reg mem_C2_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_C2_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_C2_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_C2_0_dout;
wire mem_C2_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C2_0_rd_addr;

reg mem_C2_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_C2_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_C2_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_C2_1_dout;
wire mem_C2_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_C2_1_rd_addr;

// interface with memory Z
reg mem_Z_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_Z_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z_0_dout;
wire mem_Z_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_0_rd_addr;

reg mem_Z_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_Z_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z_1_dout;
wire mem_Z_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z_1_rd_addr;
 
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
// load X_0, X_1, Z_0, Z_1, C0_0, C0_1, C1_0, C1_1, C2_0, and C2_1
//---------------------------------------------------------------------
    // load X_0 
    element_file = $fopen("eval_4_isog_mem_X_0.txt", "r");
    # 10;
    $display("\nloading input X_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_X_0_wr_en = 1'b1;
    mem_X_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_X_0_din); 
      #10;
      mem_X_0_wr_addr = mem_X_0_wr_addr + 1;
    end
    mem_X_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X_1 
    element_file = $fopen("eval_4_isog_mem_X_1.txt", "r");
    # 10;
    $display("\nloading input X_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_X_1_wr_en = 1'b1;
    mem_X_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_X_1_din); 
      #10;
      mem_X_1_wr_addr = mem_X_1_wr_addr + 1;
    end
    mem_X_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load Z_0 
    element_file = $fopen("eval_4_isog_mem_Z_0.txt", "r");
    # 10;
    $display("\nloading input Z_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_Z_0_wr_en = 1'b1;
    mem_Z_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_Z_0_din); 
      #10;
      mem_Z_0_wr_addr = mem_Z_0_wr_addr + 1;
    end
    mem_Z_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load Z_1 
    element_file = $fopen("eval_4_isog_mem_Z_1.txt", "r");
    # 10;
    $display("\nloading input Z_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_Z_1_wr_en = 1'b1;
    mem_Z_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_Z_1_din); 
      #10;
      mem_Z_1_wr_addr = mem_Z_1_wr_addr + 1;
    end
    mem_Z_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load C0_0 
    element_file = $fopen("eval_4_isog_mem_C0_0.txt", "r");
    # 10;
    $display("\nloading input C0_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_C0_0_wr_en = 1'b1;
    mem_C0_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_C0_0_din); 
      #10;
      mem_C0_0_wr_addr = mem_C0_0_wr_addr + 1;
    end
    mem_C0_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C0_1 
    element_file = $fopen("eval_4_isog_mem_C0_1.txt", "r");
    # 10;
    $display("\nloading input C0_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_C0_1_wr_en = 1'b1;
    mem_C0_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_C0_1_din); 
      #10;
      mem_C0_1_wr_addr = mem_C0_1_wr_addr + 1;
    end
    mem_C0_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------
    // load C1_0 
    element_file = $fopen("eval_4_isog_mem_C1_0.txt", "r");
    # 10;
    $display("\nloading input C1_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_C1_0_wr_en = 1'b1;
    mem_C1_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_C1_0_din); 
      #10;
      mem_C1_0_wr_addr = mem_C1_0_wr_addr + 1;
    end
    mem_C1_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C1_1 
    element_file = $fopen("eval_4_isog_mem_C1_1.txt", "r");
    # 10;
    $display("\nloading input C1_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_C1_1_wr_en = 1'b1;
    mem_C1_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_C1_1_din); 
      #10;
      mem_C1_1_wr_addr = mem_C1_1_wr_addr + 1;
    end
    mem_C1_1_wr_en = 1'b0;
    end
    $fclose(element_file);

 //---------------------------------------------------------------------
    // load C2_0 
    element_file = $fopen("eval_4_isog_mem_C2_0.txt", "r");
    # 10;
    $display("\nloading input C2_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_C2_0_wr_en = 1'b1;
    mem_C2_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_C2_0_din); 
      #10;
      mem_C2_0_wr_addr = mem_C2_0_wr_addr + 1;
    end
    mem_C2_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load C2_1 
    element_file = $fopen("eval_4_isog_mem_C2_1.txt", "r");
    # 10;
    $display("\nloading input C2_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_C2_1_wr_en = 1'b1;
    mem_C2_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_C2_1_din); 
      #10;
      mem_C2_1_wr_addr = mem_C2_1_wr_addr + 1;
    end
    mem_C2_1_wr_en = 1'b0;
    end
    $fclose(element_file);

//---------------------------------------------------------------------   
//---------------------------------------------------------------------
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
    // restart computation without forcing reset
    # 100; 
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    comptation finished in %0d cycles", ($time-start_time)/10);
    
    
    // restart computation without forcing reset
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\n\n    repeat computation without resetting");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\n    comptation finished in %0d cycles", ($time-start_time)/10);

//--------------------------------------------------------------------- 
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

    #100;
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
  .mem_C0_0_dout(mem_C0_0_dout),
  .mem_C0_0_rd_en(mem_C0_0_rd_en),
  .mem_C0_0_rd_addr(mem_C0_0_rd_addr),
  .mem_C0_1_dout(mem_C0_1_dout),
  .mem_C0_1_rd_en(mem_C0_1_rd_en),
  .mem_C0_1_rd_addr(mem_C0_1_rd_addr),
  .mem_C1_0_dout(mem_C1_0_dout),
  .mem_C1_0_rd_en(mem_C1_0_rd_en),
  .mem_C1_0_rd_addr(mem_C1_0_rd_addr),
  .mem_C1_1_dout(mem_C1_1_dout),
  .mem_C1_1_rd_en(mem_C1_1_rd_en),
  .mem_C1_1_rd_addr(mem_C1_1_rd_addr),
  .mem_C2_0_dout(mem_C2_0_dout),
  .mem_C2_0_rd_en(mem_C2_0_rd_en),
  .mem_C2_0_rd_addr(mem_C2_0_rd_addr),
  .mem_C2_1_dout(mem_C2_1_dout),
  .mem_C2_1_rd_en(mem_C2_1_rd_en),
  .mem_C2_1_rd_addr(mem_C2_1_rd_addr), 
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
 
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X_0 (  
  .clock(clk),
  .data(mem_X_0_din),
  .address(mem_X_0_wr_en ? mem_X_0_wr_addr : (mem_X_0_rd_en ? mem_X_0_rd_addr : 0)),
  .wr_en(mem_X_0_wr_en),
  .q(mem_X_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X_1 (  
  .clock(clk),
  .data(mem_X_1_din),
  .address(mem_X_1_wr_en ? mem_X_1_wr_addr : (mem_X_1_rd_en ? mem_X_1_rd_addr : 0)),
  .wr_en(mem_X_1_wr_en),
  .q(mem_X_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z_0 (  
  .clock(clk),
  .data(mem_Z_0_din),
  .address(mem_Z_0_wr_en ? mem_Z_0_wr_addr : (mem_Z_0_rd_en ? mem_Z_0_rd_addr : 0)),
  .wr_en(mem_Z_0_wr_en),
  .q(mem_Z_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z_1 (  
  .clock(clk),
  .data(mem_Z_1_din),
  .address(mem_Z_1_wr_en ? mem_Z_1_wr_addr : (mem_Z_1_rd_en ? mem_Z_1_rd_addr : 0)),
  .wr_en(mem_Z_1_wr_en),
  .q(mem_Z_1_dout)
  );
 
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C0_0 (  
  .clock(clk),
  .data(mem_C0_0_din),
  .address(mem_C0_0_wr_en ? mem_C0_0_wr_addr : (mem_C0_0_rd_en ? mem_C0_0_rd_addr : 0)),
  .wr_en(mem_C0_0_wr_en),
  .q(mem_C0_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C0_1 (  
  .clock(clk),
  .data(mem_C0_1_din),
  .address(mem_C0_1_wr_en ? mem_C0_1_wr_addr : (mem_C0_1_rd_en ? mem_C0_1_rd_addr : 0)),
  .wr_en(mem_C0_1_wr_en),
  .q(mem_C0_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C1_0 (  
  .clock(clk),
  .data(mem_C1_0_din),
  .address(mem_C1_0_wr_en ? mem_C1_0_wr_addr : (mem_C1_0_rd_en ? mem_C1_0_rd_addr : 0)),
  .wr_en(mem_C1_0_wr_en),
  .q(mem_C1_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C1_1 (  
  .clock(clk),
  .data(mem_C1_1_din),
  .address(mem_C1_1_wr_en ? mem_C1_1_wr_addr : (mem_C1_1_rd_en ? mem_C1_1_rd_addr : 0)),
  .wr_en(mem_C1_1_wr_en),
  .q(mem_C1_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C2_0 (  
  .clock(clk),
  .data(mem_C2_0_din),
  .address(mem_C2_0_wr_en ? mem_C2_0_wr_addr : (mem_C2_0_rd_en ? mem_C2_0_rd_addr : 0)),
  .wr_en(mem_C2_0_wr_en),
  .q(mem_C2_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_C2_1 (  
  .clock(clk),
  .data(mem_C2_1_din),
  .address(mem_C2_1_wr_en ? mem_C2_1_wr_addr : (mem_C2_1_rd_en ? mem_C2_1_rd_addr : 0)),
  .wr_en(mem_C2_1_wr_en),
  .q(mem_C2_1_dout)
  );


always 
  # 5 clk = !clk;


endmodule