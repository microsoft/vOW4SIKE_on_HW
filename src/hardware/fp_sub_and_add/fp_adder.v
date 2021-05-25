/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      F(p) adder
 * 
*/

// Function: add two large input values 
// inputs: A, B, both are positive values
// output:
//  C = A + B (not corrected) 

module fp_adder 
  #(
  parameter RADIX = 32,
  parameter DIGITS = 14
  )
(
  input wire start, // one clock high
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
  output reg digit_out_valid,
  output reg [RADIX-1:0] digit_res,
  output reg done,  // one clock high
  output reg carry_out
	);
 
reg running;
reg [`CLOG2(DIGITS)-1:0] counter;

// interface to adder
wire [RADIX-1:0] adder_din_a;
wire [RADIX-1:0] adder_din_b;
wire [RADIX-1:0] adder_dout;
reg adder_carry_in;
wire adder_carry_out;

assign adder_din_a = digit_in_valid ? digit_a : {RADIX{1'b0}};
assign adder_din_b = digit_in_valid ? digit_b : {RADIX{1'b0}}; 

always @(posedge clk) begin
  if (rst) begin
    running <= 1'b0;
    adder_carry_in <= 1'b0;
    counter <= {`CLOG2(DIGITS){1'b0}};
    digit_out_valid <= 1'b0;
    done <= 1'b0;
    carry_out <= 1'b0;
    digit_res <= {DIGITS{1'b0}};
  end 
  else begin
    running <= done ? 1'b0 :
               start ? 1'b1 :
               running;

    adder_carry_in <= start ? carry_in :
                      digit_in_valid ?  adder_carry_out :
                      adder_carry_in;

    counter <= done ? {`CLOG2(DIGITS){1'b0}} :
               running & digit_in_valid ? counter + 1 :
               counter;

    digit_out_valid <= digit_in_valid;

    digit_res <= digit_in_valid ? adder_dout : digit_res;

    done <= digit_in_valid & (counter == (DIGITS-1));

    carry_out <= digit_in_valid & (counter == (DIGITS-1)) ? adder_carry_out : carry_out;
  end
end

unit_adder #(.RADIX(RADIX)) unit_adder_inst (
  .din_a(adder_din_a),
  .din_b(adder_din_b),
  .carry_in(adder_carry_in),
  .carry_out(adder_carry_out),
  .dout(adder_dout)
  );

endmodule