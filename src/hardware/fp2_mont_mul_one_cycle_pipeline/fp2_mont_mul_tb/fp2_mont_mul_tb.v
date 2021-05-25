/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for F(p^2) Montgomery multiplier
 * 
*/

`timescale 1ns / 1ps

module fp2_mont_mul_tb;

parameter WIDTH = ((`WIDTH_REAL+1)/2)*2;
parameter WIDTH_LOG = `CLOG2(WIDTH); 
// parameters for memories holding inputs
parameter INPUT_MEM_WIDTH = `RADIX;
parameter INPUT_MEM_DEPTH = `WIDTH_REAL;
parameter INPUT_MEM_DEPTH_LOG = `CLOG2(INPUT_MEM_DEPTH);
// t[2*i] and t[2*i+1] are stored in one memory entry
parameter RES_MEM_WIDTH = 2*`RADIX;
parameter RES_MEM_DEPTH = WIDTH/2;
parameter RES_MEM_DEPTH_LOG = `CLOG2(RES_MEM_DEPTH);
parameter MULT_FILE_CONST = "mem_c_1.mem";
parameter P2_FILE_CONST = "px2.mem";

// inputs
reg rst = 1'b0;
reg clk = 1'b0;
reg start = 1'b0;

reg sub_mult_mem_res_rd_en = 1'b0;
reg [RES_MEM_DEPTH_LOG-1:0] sub_mult_mem_res_rd_addr = 0; 
wire [RES_MEM_WIDTH-1:0] sub_mult_mem_res_dout; 

reg add_mult_mem_res_rd_en = 1'b0;
reg [RES_MEM_DEPTH_LOG-1:0] add_mult_mem_res_rd_addr = 0; 
wire [RES_MEM_WIDTH-1:0] add_mult_mem_res_dout; 

// outputs 
wire done;
wire busy;

// interface with the memories
reg mem_a_0_wr_en = 0;
wire mem_a_0_rd_en;
reg [INPUT_MEM_DEPTH_LOG-1:0] mem_a_0_wr_addr = 0;
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_a_0_rd_addr;
reg [INPUT_MEM_WIDTH-1:0] mem_a_0_din = 0;
wire [INPUT_MEM_WIDTH-1:0] mem_a_0_dout;

reg mem_a_1_wr_en = 0;
wire mem_a_1_rd_en;
reg [INPUT_MEM_DEPTH_LOG-1:0] mem_a_1_wr_addr = 0;
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_a_1_rd_addr;
reg [INPUT_MEM_WIDTH-1:0] mem_a_1_din = 0;
wire [INPUT_MEM_WIDTH-1:0] mem_a_1_dout;

reg mem_b_0_wr_en = 0;
wire mem_b_0_rd_en;
reg [INPUT_MEM_DEPTH_LOG-1:0] mem_b_0_wr_addr = 0;
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_b_0_rd_addr;
reg [INPUT_MEM_WIDTH-1:0] mem_b_0_din = 0;
wire [INPUT_MEM_WIDTH-1:0] mem_b_0_dout;

reg mem_b_1_wr_en = 0;
wire mem_b_1_rd_en;
reg [INPUT_MEM_DEPTH_LOG-1:0] mem_b_1_wr_addr = 0;
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_b_1_rd_addr;
reg [INPUT_MEM_WIDTH-1:0] mem_b_1_din = 0;
wire [INPUT_MEM_WIDTH-1:0] mem_b_1_dout;

reg mem_c_1_wr_en = 0;
wire mem_c_1_rd_en;
reg [INPUT_MEM_DEPTH_LOG-1:0] mem_c_1_wr_addr = 0;
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_c_1_rd_addr;
reg [INPUT_MEM_WIDTH-1:0] mem_c_1_din = 0; 
wire [INPUT_MEM_WIDTH-1:0] mem_c_1_dout; 
 
wire px2_mem_rd_en;
wire [`CLOG2(`WIDTH_REAL)-1:0] px2_mem_rd_addr;
wire [`RADIX-1:0] px2_mem_dout;

wire width_real_is_odd;
assign width_real_is_odd = (WIDTH > `WIDTH_REAL) ? 1'b1 : 1'b0; 


initial
  begin
    $dumpfile("fp2_mont_mul_tb.vcd");
    $dumpvars(0, fp2_mont_mul_tb);
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

    // mult 0, load a_0, a_1, b_0, b_1, and c_1
    // load a_0 
    element_file = $fopen("mult_0_a_0.txt", "r");
    # 10;
    $display("\nloading input a_0 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_a_0_wr_en = 1'b1;
    mem_a_0_wr_addr = 0;
    for (i=0; i < INPUT_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%x\n", mem_a_0_din); 
      #10;
      mem_a_0_wr_addr = mem_a_0_wr_addr + 1;
    end
    mem_a_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load a_1 
    element_file = $fopen("mult_0_a_1.txt", "r");
    # 10;
    $display("loading input a_1 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_a_1_wr_en = 1'b1;
    mem_a_1_wr_addr = 0;
    for (i=0; i < INPUT_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%x\n", mem_a_1_din);
      #10;
      mem_a_1_wr_addr = mem_a_1_wr_addr + 1;
    end
    mem_a_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load b_0 
    element_file = $fopen("mult_0_b_0.txt", "r");
    # 10;
    $display("loading input b_0 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_b_0_wr_en = 1'b1;
    mem_b_0_wr_addr = 0;
    for (i=0; i < INPUT_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%x\n", mem_b_0_din);
      #10;
      mem_b_0_wr_addr = mem_b_0_wr_addr + 1;
    end
    mem_b_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load b_1 
    element_file = $fopen("mult_0_b_1.txt", "r");
    # 10;
    $display("loading input b_1 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mem_b_1_wr_en = 1'b1;
    mem_b_1_wr_addr = 0;
    for (i=0; i < INPUT_MEM_DEPTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%x\n", mem_b_1_din);
      #10;
      mem_b_1_wr_addr = mem_b_1_wr_addr + 1;
    end
    mem_b_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
    // start computation
    # 15;
    start <= 1'b1;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);


    // restart computation without forcing reset
    # 100; 
    start <= 1'b1;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);
    
    
    // restart computation without forcing reset
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;
    
    // computation finishes
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);
  

    #10;
    $display("\nread sub part multiplication results back");

    element_file = $fopen("sub_mult_res_sim.txt", "w");

    #100;

    @(negedge clk);
    sub_mult_mem_res_rd_en = 1'b1;

    for (i=0; i<RES_MEM_DEPTH; i=i+1) begin
      sub_mult_mem_res_rd_addr = i;
      # 10;
      // skip the appended last element if n is odd
      if (width_real_is_odd & (i == (RES_MEM_DEPTH-1))) begin
        $fwrite(element_file, "%x\n", sub_mult_mem_res_dout[2*`RADIX-1:`RADIX]); 
      end
      else begin
        $fwrite(element_file, "%x\n", sub_mult_mem_res_dout[2*`RADIX-1:`RADIX]); 
        $fwrite(element_file, "%x\n", sub_mult_mem_res_dout[`RADIX-1:0]);
      end
    end

    sub_mult_mem_res_rd_en = 1'b0;

    $fclose(element_file);
 
 /////////////////////////////////////////////////////////////////////////
    #100;
    $display("\nread add part multiplication results back");

    element_file = $fopen("add_mult_res_sim.txt", "w");

    #100;

    @(negedge clk);
    add_mult_mem_res_rd_en = 1'b1;

    for (i=0; i<RES_MEM_DEPTH; i=i+1) begin
      add_mult_mem_res_rd_addr = i;
      # 10;
      // skip the appended last element if n is odd
      if (width_real_is_odd & (i == (RES_MEM_DEPTH-1))) begin
        $fwrite(element_file, "%x\n", add_mult_mem_res_dout[2*`RADIX-1:`RADIX]); 
      end
      else begin
        $fwrite(element_file, "%x\n", add_mult_mem_res_dout[2*`RADIX-1:`RADIX]); 
        $fwrite(element_file, "%x\n", add_mult_mem_res_dout[`RADIX-1:0]);
      end
    end

    add_mult_mem_res_rd_en = 1'b0;

    $fclose(element_file);

    #10;
    $display("\ncomparing results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;
      
    $finish;

end 

fp2_mont_mul #(.RADIX(`RADIX), .WIDTH_REAL(INPUT_MEM_DEPTH)) DUT (
  .rst(rst),
  .clk(clk),
  .start(start),
  .done(done),
  .busy(busy),
  .mem_a_0_rd_en(mem_a_0_rd_en),
  .mem_a_0_rd_addr(mem_a_0_rd_addr),
  .mem_a_0_dout(mem_a_0_dout),
  .mem_a_1_rd_en(mem_a_1_rd_en),
  .mem_a_1_rd_addr(mem_a_1_rd_addr),
  .mem_a_1_dout(mem_a_1_dout),
  .mem_b_0_rd_en(mem_b_0_rd_en),
  .mem_b_0_rd_addr(mem_b_0_rd_addr),
  .mem_b_0_dout(mem_b_0_dout),
  .mem_b_1_rd_en(mem_b_1_rd_en),
  .mem_b_1_rd_addr(mem_b_1_rd_addr),
  .mem_b_1_dout(mem_b_1_dout),
  .mem_c_1_rd_en(mem_c_1_rd_en),
  .mem_c_1_rd_addr(mem_c_1_rd_addr),
  .mem_c_1_dout(mem_c_1_dout), 
  .sub_mult_mem_res_rd_en(sub_mult_mem_res_rd_en),
  .sub_mult_mem_res_rd_addr(sub_mult_mem_res_rd_addr),
  .sub_mult_mem_res_dout(sub_mult_mem_res_dout),
  .add_mult_mem_res_rd_en(add_mult_mem_res_rd_en),
  .add_mult_mem_res_rd_addr(add_mult_mem_res_rd_addr),
  .add_mult_mem_res_dout(add_mult_mem_res_dout),
  .px2_mem_rd_en(px2_mem_rd_en),
  .px2_mem_rd_addr(px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout)
  );
 
single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH_REAL), .FILE(P2_FILE_CONST)) single_port_mem_inst_px2 (  
  .clock(clk),
  .data(0),
  .address(px2_mem_rd_addr),
  .wr_en(1'b0),
  .q(px2_mem_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_a_0 (
  .clock(clk),
  .data(mem_a_0_din),
  .address(mem_a_0_wr_en ? mem_a_0_wr_addr : mem_a_0_rd_addr),
  .wr_en(mem_a_0_wr_en),
  .q(mem_a_0_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_a_1 (
  .clock(clk),
  .data(mem_a_1_din),
  // .address(mem_a_1_wr_en ? mem_a_1_wr_addr : mem_a_1_rd_addr),
  .address(mem_a_1_wr_en ? mem_a_1_wr_addr : (mem_a_1_rd_en ? mem_a_1_rd_addr : 0)),
  .wr_en(mem_a_1_wr_en),
  .q(mem_a_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_b_0 (
  .clock(clk),
  .data(mem_b_0_din),
  .address(mem_b_0_wr_en ? mem_b_0_wr_addr : (mem_b_0_rd_en ? mem_b_0_rd_addr : 0)),
  .wr_en(mem_b_0_wr_en),
  .q(mem_b_0_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_b_1 (
  .clock(clk),
  .data(mem_b_1_din),
  .address(mem_b_1_wr_en ? mem_b_1_wr_addr : mem_b_1_rd_addr),
  .wr_en(mem_b_1_wr_en),
  .q(mem_b_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(INPUT_MEM_DEPTH), .FILE(MULT_FILE_CONST)) single_port_mem_inst_c_1 (
  .clock(clk),
  .data(mem_c_1_din),
  .address(mem_c_1_wr_en ? mem_c_1_wr_addr : mem_c_1_rd_addr),
  .wr_en(mem_c_1_wr_en),
  .q(mem_c_1_dout)
  );

always 
  # 5 clk = !clk;


endmodule