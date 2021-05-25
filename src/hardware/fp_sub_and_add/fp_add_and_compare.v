/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testing module for adding and comparing operations
 * 
*/
 
module fp_add_and_compare 
  #(
  parameter RADIX = 32,
  parameter DIGITS = 14,
  parameter FILE_CONST = "px2.mem"
  )
(
  input wire start,
  input wire rst,
  input wire clk,

  // digit_in_valid comes after start signal
  input wire digit_in_valid, // synchronous with input a and b
  // initial carry in, synchronous with start
  input wire carry_in,
  // input value A
  input wire [RADIX-1:0] digit_a,
  // input value B
  input wire [RADIX-1:0] digit_b,

  // output result
  output wire digit_out_valid,
  output wire [RADIX-1:0] digit_res,
  output wire a_plus_b_bigger_than_const,
  output wire done,  // one clock high
  output wire carry_out
);

// interface to fp_adder
wire adder_start;
wire adder_digit_in_valid;
wire adder_carry_in;
wire [RADIX-1:0] adder_digit_a;
wire [RADIX-1:0] adder_digit_b;
wire adder_digit_out_valid;
wire [RADIX-1:0] adder_digit_res;
wire adder_done;
wire adder_carry_out;

// interface to serial_comparator
wire comparator_start;
wire comparator_digit_valid;
wire [RADIX-1:0] comparator_digit_a;
wire [RADIX-1:0] comparator_digit_b;
wire comparator_a_bigger_than_b;
wire comparator_done;

reg [`CLOG2(DIGITS)-1:0] px2_mem_rd_addr;
wire [RADIX-1:0] px2_mem_dout;
reg running;

assign adder_start = start;
assign adder_digit_in_valid = digit_in_valid;
assign adder_carry_in = carry_in;
assign adder_digit_a = digit_a;
assign adder_digit_b = digit_b;

assign digit_out_valid = adder_digit_out_valid;
assign digit_res = adder_digit_res; 

assign comparator_start = start;
assign comparator_digit_valid = adder_digit_out_valid;
assign comparator_digit_a = adder_digit_res;
assign comparator_digit_b = px2_mem_dout;

assign a_bigger_than_b = comparator_a_bigger_than_b;
assign done = comparator_done;
assign carry_out = adder_carry_out;

always @(posedge clk) begin
  if (rst) begin
    running <= 1'b0;
    px2_mem_rd_addr <= {`CLOG2(DIGITS){1'b0}};
  end
  else begin
    running <= done ? 1'b0 :
               start ? 1'b1 :
               running;

    px2_mem_rd_addr <= (start | done) ? {`CLOG2(DIGITS){1'b0}} :
                       adder_digit_in_valid & (px2_mem_rd_addr < (DIGITS-1)) ? px2_mem_rd_addr + 1 :
                       px2_mem_rd_addr;
  end
end


fp_adder #(.RADIX(RADIX), .DIGITS(DIGITS)) fp_adder_inst (
  .start(adder_start),
  .rst(rst),
  .clk(clk),
  .digit_in_valid(adder_digit_in_valid),
  .carry_in(adder_carry_in),
  .digit_a(adder_digit_a),
  .digit_b(adder_digit_b),
  .digit_out_valid(adder_digit_out_valid),
  .digit_res(adder_digit_res),
  .done(adder_done),
  .carry_out(adder_carry_out)
	);

serial_comparator #(.RADIX(RADIX), .DIGITS(DIGITS)) serial_comparator_inst (
  .start(comparator_start),
  .rst(rst),
  .clk(clk),
  .digit_valid(comparator_digit_valid), 
  .digit_a(comparator_digit_a),
  .digit_b(comparator_digit_b), 
  .a_bigger_than_b(comparator_a_bigger_than_b),
  .done(comparator_done)
  );

// memory storing 2*p
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS), .FILE(FILE_CONST)) single_port_mem_inst_px2 (  
  .clock(clk),
  .data(0),
  .address(px2_mem_rd_addr),
  .wr_en(1'b0),
  .q(px2_mem_dout)
  );

endmodule