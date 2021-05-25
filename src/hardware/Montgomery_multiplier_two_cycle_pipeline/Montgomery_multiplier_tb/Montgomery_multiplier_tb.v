/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for F(p^2) multiplier (two-cycle version)
 * 
*/

`timescale 1ns / 1ps

module Montgomery_multiplier_tb;

parameter WIDTH_LOG = `CLOG2(`WIDTH);
parameter FILE_CONST = "mem_c_1.mem";

// inputs
reg rst = 1'b0;
reg clk = 1'b0;
reg start = 1'b0;
reg mult_0_mem_res_rd_en = 1'b0;
reg [WIDTH_LOG-1:0] mult_0_mem_res_rd_addr = 0;
reg mult_1_mem_res_rd_en = 1'b0;
reg [WIDTH_LOG-1:0] mult_1_mem_res_rd_addr = 0;

// outputs 
wire done;
wire [`RADIX-1:0] mult_0_mem_res_dout;
wire [`RADIX-1:0] mult_1_mem_res_dout;

// interface with the memories
reg mult_0_mem_a_0_wr_en = 0;
wire mult_0_mem_a_0_rd_en;
reg [WIDTH_LOG-1:0] mult_0_mem_a_0_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_0_mem_a_0_rd_addr;
reg [`RADIX-1:0] mult_0_mem_a_0_din = 0;
wire [`RADIX-1:0] mult_0_mem_a_0_dout;

reg mult_0_mem_a_1_wr_en = 0;
wire mult_0_mem_a_1_rd_en;
reg [WIDTH_LOG-1:0] mult_0_mem_a_1_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_0_mem_a_1_rd_addr;
reg [`RADIX-1:0] mult_0_mem_a_1_din = 0;
wire [`RADIX-1:0] mult_0_mem_a_1_dout;

reg mult_0_mem_b_0_wr_en = 0;
wire mult_0_mem_b_0_rd_en;
reg [WIDTH_LOG-1:0] mult_0_mem_b_0_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_0_mem_b_0_rd_addr;
reg [`RADIX-1:0] mult_0_mem_b_0_din = 0;
wire [`RADIX-1:0] mult_0_mem_b_0_dout;

reg mult_0_mem_b_1_wr_en = 0;
wire mult_0_mem_b_1_rd_en;
reg [WIDTH_LOG-1:0] mult_0_mem_b_1_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_0_mem_b_1_rd_addr;
reg [`RADIX-1:0] mult_0_mem_b_1_din = 0;
wire [`RADIX-1:0] mult_0_mem_b_1_dout;

reg mult_0_mem_c_1_wr_en = 0;
wire mult_0_mem_c_1_rd_en;
reg [WIDTH_LOG-1:0] mult_0_mem_c_1_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_0_mem_c_1_rd_addr;
reg [`RADIX-1:0] mult_0_mem_c_1_din = 0; 
wire [`RADIX-1:0] mult_0_mem_c_1_dout; 

// multiplication #1
reg mult_1_mem_a_0_wr_en = 0;
wire mult_1_mem_a_0_rd_en;
reg [WIDTH_LOG-1:0] mult_1_mem_a_0_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_1_mem_a_0_rd_addr;
reg [`RADIX-1:0] mult_1_mem_a_0_din = 0;
wire [`RADIX-1:0] mult_1_mem_a_0_dout;

reg mult_1_mem_a_1_wr_en = 0;
wire mult_1_mem_a_1_rd_en;
reg [WIDTH_LOG-1:0] mult_1_mem_a_1_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_1_mem_a_1_rd_addr;
reg [`RADIX-1:0] mult_1_mem_a_1_din = 0;
wire [`RADIX-1:0] mult_1_mem_a_1_dout;

reg mult_1_mem_b_0_wr_en = 0;
wire mult_1_mem_b_0_rd_en;
reg [WIDTH_LOG-1:0] mult_1_mem_b_0_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_1_mem_b_0_rd_addr;
reg [`RADIX-1:0] mult_1_mem_b_0_din = 0;
wire [`RADIX-1:0] mult_1_mem_b_0_dout;

reg mult_1_mem_b_1_wr_en = 0;
wire mult_1_mem_b_1_rd_en;
reg [WIDTH_LOG-1:0] mult_1_mem_b_1_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_1_mem_b_1_rd_addr;
reg [`RADIX-1:0] mult_1_mem_b_1_din = 0;
wire [`RADIX-1:0] mult_1_mem_b_1_dout;

reg mult_1_mem_c_1_wr_en = 0;
wire mult_1_mem_c_1_rd_en;
reg [WIDTH_LOG-1:0] mult_1_mem_c_1_wr_addr = 0;
wire [WIDTH_LOG-1:0] mult_1_mem_c_1_rd_addr;
reg [`RADIX-1:0] mult_1_mem_c_1_din = 0; 
wire [`RADIX-1:0] mult_1_mem_c_1_dout; 

initial
  begin
    $dumpfile("Montgomery_multiplier_tb.vcd");
    $dumpvars(0, Montgomery_multiplier_tb);
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
    mult_0_mem_a_0_wr_en = 1'b1;
    mult_0_mem_a_0_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_0_mem_a_0_din);
      #10;
      mult_0_mem_a_0_wr_addr = mult_0_mem_a_0_wr_addr + 1;
    end
    mult_0_mem_a_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load a_1 
    element_file = $fopen("mult_0_a_1.txt", "r");
    # 10;
    $display("loading input a_1 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_0_mem_a_1_wr_en = 1'b1;
    mult_0_mem_a_1_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_0_mem_a_1_din);
      #10;
      mult_0_mem_a_1_wr_addr = mult_0_mem_a_1_wr_addr + 1;
    end
    mult_0_mem_a_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load b_0 
    element_file = $fopen("mult_0_b_0.txt", "r");
    # 10;
    $display("loading input b_0 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_0_mem_b_0_wr_en = 1'b1;
    mult_0_mem_b_0_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_0_mem_b_0_din);
      #10;
      mult_0_mem_b_0_wr_addr = mult_0_mem_b_0_wr_addr + 1;
    end
    mult_0_mem_b_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load b_1 
    element_file = $fopen("mult_0_b_1.txt", "r");
    # 10;
    $display("loading input b_1 for multiplication 0");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_0_mem_b_1_wr_en = 1'b1;
    mult_0_mem_b_1_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_0_mem_b_1_din);
      #10;
      mult_0_mem_b_1_wr_addr = mult_0_mem_b_1_wr_addr + 1;
    end
    mult_0_mem_b_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
    // mult 1, load a_0, a_1, b_0, b_1, and c_1
    // load a_0 
    element_file = $fopen("mult_1_a_0.txt", "r");
    # 10;
    $display("loading input a_0 for multiplication 1");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_1_mem_a_0_wr_en = 1'b1;
    mult_1_mem_a_0_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_1_mem_a_0_din);
      #10;
      mult_1_mem_a_0_wr_addr = mult_1_mem_a_0_wr_addr + 1;
    end
    mult_1_mem_a_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load a_1 
    element_file = $fopen("mult_1_a_1.txt", "r");
    # 10;
    $display("loading input a_1 for multiplication 1");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_1_mem_a_1_wr_en = 1'b1;
    mult_1_mem_a_1_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_1_mem_a_1_din);
      #10;
      mult_1_mem_a_1_wr_addr = mult_1_mem_a_1_wr_addr + 1;
    end
    mult_1_mem_a_1_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load b_0 
    element_file = $fopen("mult_1_b_0.txt", "r");
    # 10;
    $display("loading input b_0 for multiplication 1");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_1_mem_b_0_wr_en = 1'b1;
    mult_1_mem_b_0_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_1_mem_b_0_din);
      #10;
      mult_1_mem_b_0_wr_addr = mult_1_mem_b_0_wr_addr + 1;
    end
    mult_1_mem_b_0_wr_en = 1'b0;
    end
    $fclose(element_file);

    // load b_1 
    element_file = $fopen("mult_1_b_1.txt", "r");
    # 10;
    $display("loading input b_1 for multiplication 1");
    while (!$feof(element_file)) begin
    @(negedge clk);
    mult_1_mem_b_1_wr_en = 1'b1;
    mult_1_mem_b_1_wr_addr = 0;
    for (i=0; i < `WIDTH; i=i+1) begin
      scan_file = $fscanf(element_file, "%b\n", mult_1_mem_b_1_din);
      #10;
      mult_1_mem_b_1_wr_addr = mult_1_mem_b_1_wr_addr + 1;
    end
    mult_1_mem_b_1_wr_en = 1'b0;
    end
    $fclose(element_file);
 
    // start computation
    # 15;
    start <= 1'b1;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;

    // finishes computation
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);


    // re-start computation
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;

    // finishes computation
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);


    // re-start computation
    # 100;
    start <= 1'b1;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;

    // finishes computation
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);


    #10;
    $display("\nread multiplication results back");

    element_file = $fopen("mult_0_res_sim.txt", "w");

    @(negedge clk);
    mult_0_mem_res_rd_en = 1'b1;

    for (i=0; i<`WIDTH; i=i+1) begin
      mult_0_mem_res_rd_addr = i;
      # 10;
      $fwrite(element_file, "%b\n", mult_0_mem_res_dout);
    end

    mult_0_mem_res_rd_en = 1'b0;

    $fclose(element_file);

    # 10;
    element_file = $fopen("mult_1_res_sim.txt", "w");
    @(negedge clk);
    mult_1_mem_res_rd_en = 1'b1;

    for (i=0; i<`WIDTH; i=i+1) begin
      mult_1_mem_res_rd_addr = i;
      # 10;
      $fwrite(element_file, "%b\n", mult_1_mem_res_dout);
    end

    mult_1_mem_res_rd_en = 1'b0;

    $fclose(element_file);

    #10;
    $display("\ncomparing results from software and hardware simulation by git diff:");
    $display("    DONE! Test Passes!\n"); 

    # 1000;
      
    $finish;

end 
 

Montgomery_multiplier #(.RADIX(`RADIX), .WIDTH(`WIDTH)) DUT (
  .rst(rst),
  .clk(clk),
  .start(start),
  .done(done),
  .mult_0_mem_a_0_rd_en(mult_0_mem_a_0_rd_en),
  .mult_0_mem_a_0_rd_addr(mult_0_mem_a_0_rd_addr),
  .mult_0_mem_a_0_dout(mult_0_mem_a_0_dout),
  .mult_0_mem_a_1_rd_en(mult_0_mem_a_1_rd_en),
  .mult_0_mem_a_1_rd_addr(mult_0_mem_a_1_rd_addr),
  .mult_0_mem_a_1_dout(mult_0_mem_a_1_dout),
  .mult_0_mem_b_0_rd_en(mult_0_mem_b_0_rd_en),
  .mult_0_mem_b_0_rd_addr(mult_0_mem_b_0_rd_addr),
  .mult_0_mem_b_0_dout(mult_0_mem_b_0_dout),
  .mult_0_mem_b_1_rd_en(mult_0_mem_b_1_rd_en),
  .mult_0_mem_b_1_rd_addr(mult_0_mem_b_1_rd_addr),
  .mult_0_mem_b_1_dout(mult_0_mem_b_1_dout),
  .mult_0_mem_c_1_rd_en(mult_0_mem_c_1_rd_en),
  .mult_0_mem_c_1_rd_addr(mult_0_mem_c_1_rd_addr),
  .mult_0_mem_c_1_dout(mult_0_mem_c_1_dout),
  .mult_1_mem_a_0_rd_en(mult_1_mem_a_0_rd_en),
  .mult_1_mem_a_0_rd_addr(mult_1_mem_a_0_rd_addr),
  .mult_1_mem_a_0_dout(mult_1_mem_a_0_dout),
  .mult_1_mem_a_1_rd_en(mult_1_mem_a_1_rd_en),
  .mult_1_mem_a_1_rd_addr(mult_1_mem_a_1_rd_addr),
  .mult_1_mem_a_1_dout(mult_1_mem_a_1_dout),
  .mult_1_mem_b_0_rd_en(mult_1_mem_b_0_rd_en),
  .mult_1_mem_b_0_rd_addr(mult_1_mem_b_0_rd_addr),
  .mult_1_mem_b_0_dout(mult_1_mem_b_0_dout),
  .mult_1_mem_b_1_rd_en(mult_1_mem_b_1_rd_en),
  .mult_1_mem_b_1_rd_addr(mult_1_mem_b_1_rd_addr),
  .mult_1_mem_b_1_dout(mult_1_mem_b_1_dout),
  .mult_1_mem_c_1_rd_en(mult_1_mem_c_1_rd_en),
  .mult_1_mem_c_1_rd_addr(mult_1_mem_c_1_rd_addr),
  .mult_1_mem_c_1_dout(mult_1_mem_c_1_dout),
  .mult_0_mem_res_rd_en(mult_0_mem_res_rd_en),
  .mult_0_mem_res_rd_addr(mult_0_mem_res_rd_addr),
  .mult_0_mem_res_dout(mult_0_mem_res_dout),
  .mult_1_mem_res_rd_en(mult_1_mem_res_rd_en),
  .mult_1_mem_res_rd_addr(mult_1_mem_res_rd_addr),
  .mult_1_mem_res_dout(mult_1_mem_res_dout) 
  );


single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_0_a_0 (
  .clock(clk),
  .data(mult_0_mem_a_0_din),
  .address(mult_0_mem_a_0_wr_en ? mult_0_mem_a_0_wr_addr : mult_0_mem_a_0_rd_addr),
  .wr_en(mult_0_mem_a_0_wr_en),
  .q(mult_0_mem_a_0_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_0_a_1 (
  .clock(clk),
  .data(mult_0_mem_a_1_din),
  .address(mult_0_mem_a_1_wr_en ? mult_0_mem_a_1_wr_addr : mult_0_mem_a_1_rd_addr),
  .wr_en(mult_0_mem_a_1_wr_en),
  .q(mult_0_mem_a_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_0_b_0 (
  .clock(clk),
  .data(mult_0_mem_b_0_din),
  .address(mult_0_mem_b_0_wr_en ? mult_0_mem_b_0_wr_addr : mult_0_mem_b_0_rd_addr),
  .wr_en(mult_0_mem_b_0_wr_en),
  .q(mult_0_mem_b_0_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_0_b_1 (
  .clock(clk),
  .data(mult_0_mem_b_1_din),
  .address(mult_0_mem_b_1_wr_en ? mult_0_mem_b_1_wr_addr : mult_0_mem_b_1_rd_addr),
  .wr_en(mult_0_mem_b_1_wr_en),
  .q(mult_0_mem_b_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH), .FILE(FILE_CONST)) single_port_mem_inst_mult_0_c_1 (
  .clock(clk),
  .data(mult_0_mem_c_1_din),
  .address(mult_0_mem_c_1_wr_en ? mult_0_mem_c_1_wr_addr : mult_0_mem_c_1_rd_addr),
  .wr_en(mult_0_mem_c_1_wr_en),
  .q(mult_0_mem_c_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_1_a_0 (
  .clock(clk),
  .data(mult_1_mem_a_0_din),
  .address(mult_1_mem_a_0_wr_en ? mult_1_mem_a_0_wr_addr : mult_1_mem_a_0_rd_addr),
  .wr_en(mult_1_mem_a_0_wr_en),
  .q(mult_1_mem_a_0_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_1_a_1 (
  .clock(clk),
  .data(mult_1_mem_a_1_din),
  .address(mult_1_mem_a_1_wr_en ? mult_1_mem_a_1_wr_addr : mult_1_mem_a_1_rd_addr),
  .wr_en(mult_1_mem_a_1_wr_en),
  .q(mult_1_mem_a_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_1_b_0 (
  .clock(clk),
  .data(mult_1_mem_b_0_din),
  .address(mult_1_mem_b_0_wr_en ? mult_1_mem_b_0_wr_addr : mult_1_mem_b_0_rd_addr),
  .wr_en(mult_1_mem_b_0_wr_en),
  .q(mult_1_mem_b_0_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH)) single_port_mem_inst_mult_1_b_1 (
  .clock(clk),
  .data(mult_1_mem_b_1_din),
  .address(mult_1_mem_b_1_wr_en ? mult_1_mem_b_1_wr_addr : mult_1_mem_b_1_rd_addr),
  .wr_en(mult_1_mem_b_1_wr_en),
  .q(mult_1_mem_b_1_dout)
  );

single_port_mem #(.WIDTH(`RADIX), .DEPTH(`WIDTH), .FILE(FILE_CONST)) single_port_mem_inst_mult_1_c_1 (
  .clock(clk),
  .data(mult_1_mem_c_1_din),
  .address(mult_1_mem_c_1_wr_en ? mult_1_mem_c_1_wr_addr : mult_1_mem_c_1_rd_addr),
  .wr_en(mult_1_mem_c_1_wr_en),
  .q(mult_1_mem_c_1_dout)
  );

always 
  # 5 clk = !clk;


endmodule