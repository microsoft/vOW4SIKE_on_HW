/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for get_4_isog
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
reg mem_X4_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_X4_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_X4_0_dout;
wire mem_X4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_0_rd_addr;

reg mem_X4_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_X4_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_X4_1_dout;
wire mem_X4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_X4_1_rd_addr;

// interface with memory Z
reg mem_Z4_0_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_0_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_Z4_0_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_0_dout;
wire mem_Z4_0_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_0_rd_addr;

reg mem_Z4_1_wr_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_1_wr_addr = 0;
reg [SINGLE_MEM_WIDTH-1:0] mem_Z4_1_din = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z4_1_dout;
wire mem_Z4_1_rd_en;
wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_Z4_1_rd_addr;
 
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
wire [SINGLE_MEM_WIDTH-1:0] mem_t4_0_dout;

reg out_mem_t4_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t4_1_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t4_1_dout; 

reg out_mem_t5_0_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t5_0_rd_addr = 0; 
wire [SINGLE_MEM_WIDTH-1:0] mem_t5_0_dout;

reg out_mem_t5_1_rd_en = 0;
reg [SINGLE_MEM_DEPTH_LOG-1:0] out_mem_t5_1_rd_addr = 0;
wire [SINGLE_MEM_WIDTH-1:0] mem_t5_1_dout;

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
    // load X4_0, X4_1, Z4_0, Z4_1
    // load X4_0 
    element_file = $fopen("get_4_isog_mem_X4_0.txt", "r");
    # 10;
    $display("\nloading input X4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_X4_0_wr_en = 1'b1;
    mem_X4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_X4_0_din); 
      #10;
      mem_X4_0_wr_addr = mem_X4_0_wr_addr + 1;
    end
    mem_X4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load X4_1 
    element_file = $fopen("get_4_isog_mem_X4_1.txt", "r");
    # 10;
    $display("\nloading input X4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_X4_1_wr_en = 1'b1;
    mem_X4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_X4_1_din); 
      #10;
      mem_X4_1_wr_addr = mem_X4_1_wr_addr + 1;
    end
    mem_X4_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load Z4_0 
    element_file = $fopen("get_4_isog_mem_Z4_0.txt", "r");
    # 10;
    $display("\nloading input Z4_0...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_Z4_0_wr_en = 1'b1;
    mem_Z4_0_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_Z4_0_din); 
      #10;
      mem_Z4_0_wr_addr = mem_Z4_0_wr_addr + 1;
    end
    mem_Z4_0_wr_en = 1'b0;
    end
    $fclose(element_file);
    
    // load Z4_1 
    element_file = $fopen("get_4_isog_mem_Z4_1.txt", "r");
    # 10;
    $display("\nloading input Z4_1...");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_Z4_1_wr_en = 1'b1;
    mem_Z4_1_wr_addr = 0;
    for (i=0; i < SINGLE_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mem_Z4_1_din); 
      #10;
      mem_Z4_1_wr_addr = mem_Z4_1_wr_addr + 1;
    end
    mem_Z4_1_wr_en = 1'b0;
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
    #100;
    $display("\nread result t1 back...");

    element_file = $fopen("sim_t1_0.txt", "w");

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

    element_file = $fopen("sim_t1_1.txt", "w");

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

 //---------------------------------------------------------------------
    #100;
    $display("\nread result t4 back...");

    element_file = $fopen("sim_t4_0.txt", "w");

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

    element_file = $fopen("sim_t4_1.txt", "w");

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
    $display("\nread result t5 back...");

    element_file = $fopen("sim_t5_0.txt", "w");

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

    element_file = $fopen("sim_t5_1.txt", "w");

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
  .mem_X4_0_dout(mem_X4_0_dout),
  .mem_X4_0_rd_en(mem_X4_0_rd_en),
  .mem_X4_0_rd_addr(mem_X4_0_rd_addr),
  .mem_X4_1_dout(mem_X4_1_dout),
  .mem_X4_1_rd_en(mem_X4_1_rd_en),
  .mem_X4_1_rd_addr(mem_X4_1_rd_addr),
  .mem_Z4_0_dout(mem_Z4_0_dout),
  .mem_Z4_0_rd_en(mem_Z4_0_rd_en),
  .mem_Z4_0_rd_addr(mem_Z4_0_rd_addr),
  .mem_Z4_1_dout(mem_Z4_1_dout),
  .mem_Z4_1_rd_en(mem_Z4_1_rd_en),
  .mem_Z4_1_rd_addr(mem_Z4_1_rd_addr), 
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
  .mem_t4_0_dout(mem_t4_0_dout),
  .out_mem_t4_1_rd_en(out_mem_t4_1_rd_en),
  .out_mem_t4_1_rd_addr(out_mem_t4_1_rd_addr),
  .mem_t4_1_dout(mem_t4_1_dout),
  .out_mem_t5_0_rd_en(out_mem_t5_0_rd_en),
  .out_mem_t5_0_rd_addr(out_mem_t5_0_rd_addr),
  .mem_t5_0_dout(mem_t5_0_dout),
  .out_mem_t5_1_rd_en(out_mem_t5_1_rd_en),
  .out_mem_t5_1_rd_addr(out_mem_t5_1_rd_addr),
  .mem_t5_1_dout(mem_t5_1_dout)
  );
 
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X4_0 (  
  .clock(clk),
  .data(mem_X4_0_din),
  .address(mem_X4_0_wr_en ? mem_X4_0_wr_addr : (mem_X4_0_rd_en ? mem_X4_0_rd_addr : 0)),
  .wr_en(mem_X4_0_wr_en),
  .q(mem_X4_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_X4_1 (  
  .clock(clk),
  .data(mem_X4_1_din),
  .address(mem_X4_1_wr_en ? mem_X4_1_wr_addr : (mem_X4_1_rd_en ? mem_X4_1_rd_addr : 0)),
  .wr_en(mem_X4_1_wr_en),
  .q(mem_X4_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z4_0 (  
  .clock(clk),
  .data(mem_Z4_0_din),
  .address(mem_Z4_0_wr_en ? mem_Z4_0_wr_addr : (mem_Z4_0_rd_en ? mem_Z4_0_rd_addr : 0)),
  .wr_en(mem_Z4_0_wr_en),
  .q(mem_Z4_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL)) single_port_mem_inst_Z4_1 (  
  .clock(clk),
  .data(mem_Z4_1_din),
  .address(mem_Z4_1_wr_en ? mem_Z4_1_wr_addr : (mem_Z4_1_rd_en ? mem_Z4_1_rd_addr : 0)),
  .wr_en(mem_Z4_1_wr_en),
  .q(mem_Z4_1_dout)
  );
 

always 
  # 5 clk = !clk;


endmodule