/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testbench for the unified unit of F(p^2) and F(p) addition and subtraction
 * 
*/

`timescale 1ns / 1ps

module fp2_sub_add_correction_tb;

parameter RADIX = `RADIX;
parameter DIGITS = `DIGITS;
parameter DIGITS_LOG = `CLOG2(DIGITS);
parameter FILE_CONST_PX2 = "px2.mem";
parameter FILE_CONST_PX4 = "px4.mem";
parameter CMD = `CMD;
parameter EXTENSION_FIELD = `EXTENSION_FIELD;

// inputs
reg rst = 1'b0;
reg clk = 1'b0;
reg start = 1'b0;
reg [2:0] cmd = 3'd0;
reg extension_field_op = 1'b0;

// interface with the memories
reg mem_a_0_wr_en = 0;
wire mem_a_0_rd_en;
reg [DIGITS_LOG-1:0] mem_a_0_wr_addr = 0;
wire [DIGITS_LOG-1:0] mem_a_0_rd_addr;
reg [RADIX-1:0] mem_a_0_din = 0;
wire [RADIX-1:0] mem_a_0_dout;

reg mem_a_1_wr_en = 0;
wire mem_a_1_rd_en;
reg [DIGITS_LOG-1:0] mem_a_1_wr_addr = 0;
wire [DIGITS_LOG-1:0] mem_a_1_rd_addr;
reg [RADIX-1:0] mem_a_1_din = 0;
wire [RADIX-1:0] mem_a_1_dout;

reg mem_b_0_wr_en = 0;
wire mem_b_0_rd_en;
reg [DIGITS_LOG-1:0] mem_b_0_wr_addr = 0;
wire [DIGITS_LOG-1:0] mem_b_0_rd_addr;
reg [RADIX-1:0] mem_b_0_din = 0;
wire [RADIX-1:0] mem_b_0_dout;

reg mem_b_1_wr_en = 0;
wire mem_b_1_rd_en;
reg [DIGITS_LOG-1:0] mem_b_1_wr_addr = 0;
wire [DIGITS_LOG-1:0] mem_b_1_rd_addr;
reg [RADIX-1:0] mem_b_1_din = 0;
wire [RADIX-1:0] mem_b_1_dout;

reg mem_c_0_rd_en = 0;
reg [DIGITS_LOG-1:0] mem_c_0_rd_addr = 0; 
wire [RADIX-1:0] mem_c_0_dout; 

reg mem_c_1_rd_en = 0;
reg [DIGITS_LOG-1:0] mem_c_1_rd_addr = 0; 
wire [RADIX-1:0] mem_c_1_dout; 

wire px2_mem_rd_en;
wire [DIGITS_LOG-1:0] px2_mem_rd_addr;
wire [RADIX-1:0] px2_mem_dout;

wire px4_mem_rd_en;
wire [DIGITS_LOG-1:0] px4_mem_rd_addr;
wire [RADIX-1:0] px4_mem_dout;

wire busy;
wire done;

fp2_sub_add_correction #(.RADIX(RADIX), .DIGITS(DIGITS)) DUT (
  .start(start),
  .rst(rst),
  .clk(clk),
  .cmd(cmd),
  .extension_field_op(extension_field_op),
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
  .mem_c_0_rd_en(mem_c_0_rd_en),
  .mem_c_0_rd_addr(mem_c_0_rd_addr),
  .mem_c_0_dout(mem_c_0_dout), 
  .mem_c_1_rd_en(mem_c_1_rd_en),
  .mem_c_1_rd_addr(mem_c_1_rd_addr),
  .mem_c_1_dout(mem_c_1_dout), 
  .px2_mem_rd_en(px2_mem_rd_en),
  .px2_mem_rd_addr(px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout),
  .px4_mem_rd_en(px4_mem_rd_en),
  .px4_mem_rd_addr(px4_mem_rd_addr),
  .px4_mem_dout(px4_mem_dout),
  .busy(busy),
  .done(done)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_a_0 (
  .clock(clk),
  .data(mem_a_0_din),
  .address(mem_a_0_wr_en ? mem_a_0_wr_addr : mem_a_0_rd_addr),
  .wr_en(mem_a_0_wr_en),
  .q(mem_a_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_b_0 (
  .clock(clk),
  .data(mem_b_0_din),
  .address(mem_b_0_wr_en ? mem_b_0_wr_addr : mem_b_0_rd_addr),
  .wr_en(mem_b_0_wr_en),
  .q(mem_b_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_a_1 (
  .clock(clk),
  .data(mem_a_1_din),
  .address(mem_a_1_wr_en ? mem_a_1_wr_addr : mem_a_1_rd_addr),
  .wr_en(mem_a_1_wr_en),
  .q(mem_a_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_b_1(
  .clock(clk),
  .data(mem_b_1_din),
  .address(mem_b_1_wr_en ? mem_b_1_wr_addr : mem_b_1_rd_addr),
  .wr_en(mem_b_1_wr_en),
  .q(mem_b_1_dout)
  );

// memory storing 2*p
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS), .FILE(FILE_CONST_PX2)) single_port_mem_inst_px2 (  
  .clock(clk),
  .data(0),
  .address(px2_mem_rd_en ? px2_mem_rd_addr : 0),
  .wr_en(1'b0),
  .q(px2_mem_dout)
  );

// memory storing 2*p
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS), .FILE(FILE_CONST_PX4)) single_port_mem_inst_px4 (  
  .clock(clk),
  .data(0),
  .address(px4_mem_rd_en ? px4_mem_rd_addr : 0),
  .wr_en(1'b0),
  .q(px4_mem_dout)
  );

initial
  begin
    $dumpfile("fp2_sub_add_correction_tb.vcd");
    $dumpvars(0, fp2_sub_add_correction_tb);
  end

integer start_time = 0; 
integer i;

integer file_a_0;
integer file_b_0;
integer scan_file_a_0;
integer scan_file_b_0;
integer file_c_0; 

integer file_a_1;
integer file_b_1;
integer scan_file_a_1;
integer scan_file_b_1;
integer file_c_1;

initial
  begin
    rst <= 1'b0;
    start <= 1'b0;
    cmd <= 3'd0; 
    extension_field_op <= EXTENSION_FIELD;
    # 45;
    rst <= 1'b1;
    # 20;
    rst <= 1'b0; 

    # 10;
    $display("\nloading inputs a and b");

    // load element a
    file_a_0 = $fopen("Sage_mem_a_0.txt", "r");
    // load element b
    file_b_0 = $fopen("Sage_mem_b_0.txt", "r"); 

    if (extension_field_op) begin
      // load element a
      file_a_1 = $fopen("Sage_mem_a_1.txt", "r");
      // load element b
      file_b_1 = $fopen("Sage_mem_b_1.txt", "r"); 
    end

    mem_a_0_wr_addr <= 0;
    mem_b_0_wr_addr <= 0;
    mem_a_0_wr_en <= 1'b1;
    mem_b_0_wr_en <= 1'b1;
    
    if (extension_field_op) begin
      mem_a_1_wr_addr <= 0;
      mem_b_1_wr_addr <= 0;
      mem_a_1_wr_en <= 1'b1;
      mem_b_1_wr_en <= 1'b1;
    end

    while (!$feof(file_a_0)) begin
      @(negedge clk);
      for (i=0; i < DIGITS; i=i+1) begin
        mem_a_0_wr_addr = i; 
        mem_b_0_wr_addr = i;
        scan_file_a_0 = $fscanf(file_a_0, "%x\n", mem_a_0_din); 
        scan_file_b_0 = $fscanf(file_b_0, "%x\n", mem_b_0_din);
        if (extension_field_op) begin
          mem_a_1_wr_addr = i; 
          mem_b_1_wr_addr = i; 
          scan_file_a_1 = $fscanf(file_a_1, "%x\n", mem_a_1_din); 
          scan_file_b_1 = $fscanf(file_b_1, "%x\n", mem_b_1_din);
        end 
        #10; 
      end 
    end

    mem_a_0_wr_en <= 1'b0;
    mem_b_0_wr_en <= 1'b0;
    if (extension_field_op) begin
      mem_a_1_wr_en <= 1'b0;
      mem_b_1_wr_en <= 1'b0; 
    end

    $fclose(file_a_0);
    $fclose(file_b_0);

    if (extension_field_op) begin
      $fclose(file_a_1);
      $fclose(file_b_1);
    end  

    # 10;
    start <= 1'b1;
    cmd <= CMD;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);

    // restart without reset testing

    # 10;
    start <= 1'b1;
    cmd <= CMD;
    start_time = $time;
    $display("\nstart computation");
    # 10;
    start <= 1'b0;

    // computation finishes
    @(posedge done);
    $display("\ncomptation finished in %0d cycles", ($time-start_time)/10);
 
    # 10;
    // write to result memory
    file_c_0 = $fopen("Simulation_c_0.txt", "w");

    @(negedge clk);
    mem_c_0_rd_en = 1'b1;

    for (i=0; i<DIGITS; i=i+1) begin
      mem_c_0_rd_addr = i;
      # 10; 
      $fwrite(file_c_0, "%x\n", mem_c_0_dout); 
    end

    mem_c_0_rd_en = 1'b0;
    
    $fclose(file_c_0); 

    if (extension_field_op) begin
      # 10;
      // write to result memory
      file_c_1 = $fopen("Simulation_c_1.txt", "w");

      @(negedge clk);
      mem_c_1_rd_en = 1'b1;

      for (i=0; i<DIGITS; i=i+1) begin
        mem_c_1_rd_addr = i;
        # 10; 
        $fwrite(file_c_1, "%x\n", mem_c_1_dout); 
      end

      mem_c_1_rd_en = 1'b0;
      
      $fclose(file_c_1); 
    end

    #10;
    $finish;
end
 

always 
  # 5 clk = !clk;
 
endmodule 