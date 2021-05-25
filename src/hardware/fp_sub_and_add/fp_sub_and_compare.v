/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      testing module for subtracting and comparing operations
 * 
*/
 
// idea: A - B = A + ~(B) + 1'b1 (initial carry_in)

module fp_sub_and_compare 
  #(
  parameter RADIX = 32,
  parameter DIGITS = 14,
  parameter FILE_CONST = "zero.mem"
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
  output reg a_minus_b_bigger_than_const,
  output reg done,  // one clock high
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
 
reg [`CLOG2(DIGITS)-1:0] zero_mem_rd_addr;
wire [RADIX-1:0] zero_mem_dout;
reg running;

assign adder_start = start;
assign adder_digit_in_valid = digit_in_valid;
assign adder_carry_in = carry_in;
assign adder_digit_a = digit_a;
assign adder_digit_b = ~(digit_b);

assign digit_out_valid = adder_digit_out_valid;
assign digit_res = adder_digit_res; 
   
assign carry_out = adder_carry_out;

always @(posedge clk) begin
  if (rst) begin
    running <= 1'b0;
    zero_mem_rd_addr <= {`CLOG2(DIGITS){1'b0}};
    a_minus_b_bigger_than_const <= 1'b0;
    done <= 1'b0;
  end
  else begin
    running <= done ? 1'b0 :
               start ? 1'b1 :
               running;

    zero_mem_rd_addr <= (start | done) ? {`CLOG2(DIGITS){1'b0}} :
                       adder_digit_in_valid & (zero_mem_rd_addr < (DIGITS-1)) ? zero_mem_rd_addr + 1 :
                       zero_mem_rd_addr;

    a_minus_b_bigger_than_const <= start ? 1'b0 :
                                   adder_done ? !adder_digit_res[RADIX-1] :
                                   a_minus_b_bigger_than_const;


    done <= adder_done;
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

// memory storing 2*p
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS), .FILE(FILE_CONST)) single_port_mem_inst_px2 (  
  .clock(clk),
  .data(0),
  .address(zero_mem_rd_addr),
  .wr_en(1'b0),
  .q(zero_mem_dout)
  );

endmodule