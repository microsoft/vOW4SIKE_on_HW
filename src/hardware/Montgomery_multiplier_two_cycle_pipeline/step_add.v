/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      building block for F(p^2) multiplier
 * 
*/

// two-stage pipelines
// one step in the inner loop (j-loop) of the unified FIOS algorithm for half of Fp^2 mulitplication
// CS = oa0[j]*ob0[i] + oa1[j]*ob1[i] + mm*m[j] + t[j] + C 
// => (carry_out, sum) = a_0*a_1 + b_0*b_1 + c_0*c_1 + d + carry_in
// t[j-1] = S

// all computations in step.v are unsigned
 
module step_add
#(
  // w = 8/16/32/64/128, etc
  parameter RADIX = 32 
  )
(
  input  wire              rst,
  input  wire              clk,
  // a_0, a_1, b_0, b_1, c_0, and c_1 come at cycle k
  input  wire [RADIX-1:0]  a_0,
  input  wire [RADIX-1:0]  a_1,
  input  wire [RADIX-1:0]  b_0,
  input  wire [RADIX-1:0]  b_1,
  input  wire [RADIX-1:0]  c_0,
  input  wire [RADIX-1:0]  c_1,
  // d and carry_in come at cycle (k+1)
  input  wire [RADIX-1:0]  d,
  input  wire              d_last,
  input  wire [RADIX+1:0]  carry_in,
  // results are available at cycles (k+2), buffered
  output wire [RADIX-1:0]  sum_comb,
  output reg  [RADIX-1:0]  sum,
  output reg  [RADIX+1:0]  carry_out
  );

wire [2*RADIX-1:0] a_0_a_1;
wire [2*RADIX-1:0] b_0_b_1;
wire [2*RADIX-1:0] c_0_c_1;

reg [2*RADIX-1:0] a_0_a_1_buf;
reg [2*RADIX-1:0] b_0_b_1_buf;
reg [2*RADIX-1:0] c_0_c_1_buf;
 

wire [2*RADIX+1:0] carry_and_sum;

assign sum_comb = carry_and_sum[RADIX-1:0];
 
assign carry_and_sum = {2'b0, a_0_a_1_buf} + {2'b0, b_0_b_1_buf} + {2'b0, c_0_c_1_buf} + {{(RADIX+2){1'b0}}, d} + {{RADIX{1'b0}}, carry_in};

always @(posedge clk) begin
  if (rst) begin
    a_0_a_1_buf <= {(2*RADIX){1'b0}};
    b_0_b_1_buf <= {(2*RADIX){1'b0}};
    c_0_c_1_buf <= {(2*RADIX){1'b0}};
    sum <= {RADIX{1'b0}};
    carry_out <= {(RADIX+2){1'b0}};
  end
  else begin
    a_0_a_1_buf <= a_0_a_1;
    b_0_b_1_buf <= b_0_b_1;
    c_0_c_1_buf <= c_0_c_1;

    // output
    sum <= carry_and_sum[RADIX-1:0];
    carry_out <= carry_and_sum[2*RADIX+1:RADIX];
  end
end


multiplier #(.WIDTH_IN(RADIX)) multiplier_inst_a_0_a_1 (
  .clk(clk),
  .a(a_0),
  .b(a_1),
  .p(a_0_a_1)
);

multiplier #(.WIDTH_IN(RADIX)) multiplier_inst_b_0_b_1 (
  .clk(clk),
  .a(b_0),
  .b(b_1),
  .p(b_0_b_1)
);

multiplier #(.WIDTH_IN(RADIX)) multiplier_inst_c_0_c_1 (
  .clk(clk),
  .a(c_0),
  .b(c_1),
  .p(c_0_c_1)
);

endmodule