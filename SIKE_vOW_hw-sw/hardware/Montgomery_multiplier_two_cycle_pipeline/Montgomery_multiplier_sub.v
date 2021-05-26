/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      multi-precision Montgomery multiplier, half of Fp^2 multiplication
 * 
*/

// multi-precision Montgomery multiplier, half of Fp^2 multiplication
// pipelined, two multiplications can be done in parallel
// Based on unified FIOS algorithm
// Current version only does the subtraction part, can be easily modified to support addition as well // FXIME

// inner loop: (carry_out, sum) = a_0*a_1 + b_0*b_1 + c_0*c_1 + d + carry_in

module Montgomery_multiplier_sub
#(
  // size of one digit
  // w = 8/16/32/64/128, etc
  parameter RADIX = 64,
  // number of digits
  parameter WIDTH = 6,
  parameter WIDTH_LOG = `CLOG2(WIDTH)
  )
( 
  
  input  wire rst,
  input  wire clk,
  input  wire start, // one clock high
  output reg  done, // one clock high
  // memory interface with inputs 
    // multiplication #0
  output wire mult_0_mem_a_0_rd_en,
  output wire [WIDTH_LOG-1:0] mult_0_mem_a_0_rd_addr,
  input  wire [RADIX-1:0] mult_0_mem_a_0_dout,

  output wire mult_0_mem_a_1_rd_en,
  output wire [WIDTH_LOG-1:0] mult_0_mem_a_1_rd_addr,
  input  wire [RADIX-1:0] mult_0_mem_a_1_dout,

  output wire mult_0_mem_b_0_rd_en,
  output wire [WIDTH_LOG-1:0] mult_0_mem_b_0_rd_addr,
  input  wire [RADIX-1:0] mult_0_mem_b_0_dout,

  output wire mult_0_mem_b_1_rd_en,
  output wire [WIDTH_LOG-1:0] mult_0_mem_b_1_rd_addr,
  input  wire [RADIX-1:0] mult_0_mem_b_1_dout,

  output wire mult_0_mem_c_1_rd_en,
  output wire [WIDTH_LOG-1:0] mult_0_mem_c_1_rd_addr,
  input  wire [RADIX-1:0] mult_0_mem_c_1_dout, 

    // multiplication #1
  output wire mult_1_mem_a_0_rd_en,
  output wire [WIDTH_LOG-1:0] mult_1_mem_a_0_rd_addr,
  input  wire [RADIX-1:0] mult_1_mem_a_0_dout,

  output wire mult_1_mem_a_1_rd_en,
  output wire [WIDTH_LOG-1:0] mult_1_mem_a_1_rd_addr,
  input  wire [RADIX-1:0] mult_1_mem_a_1_dout,

  output wire mult_1_mem_b_0_rd_en,
  output wire [WIDTH_LOG-1:0] mult_1_mem_b_0_rd_addr,
  input  wire [RADIX-1:0] mult_1_mem_b_0_dout,

  output wire mult_1_mem_b_1_rd_en,
  output wire [WIDTH_LOG-1:0] mult_1_mem_b_1_rd_addr,
  input  wire [RADIX-1:0] mult_1_mem_b_1_dout,

  output wire mult_1_mem_c_1_rd_en,
  output wire [WIDTH_LOG-1:0] mult_1_mem_c_1_rd_addr,
  input  wire [RADIX-1:0] mult_1_mem_c_1_dout,
  
  // interface with the result memory
  input  wire mult_0_mem_res_rd_en,
  input  wire [WIDTH_LOG-1:0] mult_0_mem_res_rd_addr,  
  output wire [RADIX-1:0] mult_0_mem_res_dout,

  input  wire mult_1_mem_res_rd_en,
  input  wire [WIDTH_LOG-1:0] mult_1_mem_res_rd_addr, 
  output wire [RADIX-1:0] mult_1_mem_res_dout
  );
 
wire step_din_d_last;

reg odd_even_counter;
wire step_din_is_from_mult_0;
wire step_din_is_from_mult_1;
reg running;

reg [WIDTH_LOG-1:0] round_counter;
reg [WIDTH_LOG-1:0] step_counter; 
wire round_done;

// This version separates the logic of memory and computation fully to ensure a high Fmax
// interface with the step module
wire [RADIX-1:0] step_din_a_0;
wire [RADIX-1:0] step_din_a_1;
wire [RADIX-1:0] step_din_b_0;
wire [RADIX-1:0] step_din_b_1; 
wire [RADIX-1:0] step_din_c_0;
wire [RADIX-1:0] step_din_c_1;
reg [RADIX-1:0] step_din_d;
reg [RADIX+1:0] step_din_carry_in;
reg carry_valid;
wire [RADIX-1:0] step_dout_sum_comb; // step_dout_sum <= step_dout_sum_comb;
wire [RADIX-1:0] step_dout_sum;
wire [RADIX+1:0] step_dout_carry_out;
wire [RADIX+1:0] step_dout_carry_out_buf;

reg [RADIX-1:0] mult_0_sum_step_0_buf;
reg [RADIX-1:0] mult_1_sum_step_0_buf;

// valid when step_counter is in [0, WIDTH-1]
reg mem_rd_en; 

// interface to result memories
reg mem_res_0_wr_en_pre_pre;
wire mem_res_0_wr_en;
wire [RADIX-1:0] mem_res_0_din;
reg [WIDTH_LOG-1:0] mem_res_0_wr_addr;
wire [WIDTH_LOG-1:0] mem_res_0_rd_addr;
wire [RADIX-1:0] mem_res_0_dout;

reg mem_res_1_wr_en;
wire [RADIX-1:0] mem_res_1_din;
reg [WIDTH_LOG-1:0] mem_res_1_wr_addr;
wire [WIDTH_LOG-1:0] mem_res_1_rd_addr;
wire [RADIX-1:0] mem_res_1_dout;

reg mem_res_0_dout_valid;
wire mem_res_1_dout_valid;

assign mem_res_0_rd_addr = step_counter; 
assign mem_res_1_rd_addr = step_counter; 

// multiplication #0
// memory interface to a_0
assign mult_0_mem_a_0_rd_en = running;
assign mult_0_mem_a_0_rd_addr = step_counter;
// memory interface to a_1
assign mult_0_mem_a_1_rd_en = running;
assign mult_0_mem_a_1_rd_addr = round_counter;
// memory interface to b_0
assign mult_0_mem_b_0_rd_en = mult_0_mem_a_0_rd_en;
assign mult_0_mem_b_0_rd_addr = mult_0_mem_a_0_rd_addr;
// memory interface to b_1
assign mult_0_mem_b_1_rd_en = mult_0_mem_a_1_rd_en;
assign mult_0_mem_b_1_rd_addr = mult_0_mem_a_1_rd_addr;
// memory interface to c_1
assign mult_0_mem_c_1_rd_en = running;
assign mult_0_mem_c_1_rd_addr = step_counter;

// multiplication #1
// memory interface to a_0
assign mult_1_mem_a_0_rd_en = running;
assign mult_1_mem_a_0_rd_addr = step_counter;
// memory interface to a_1
assign mult_1_mem_a_1_rd_en = running;
assign mult_1_mem_a_1_rd_addr = round_counter;
// memory interface to b_0
assign mult_1_mem_b_0_rd_en = mult_1_mem_a_0_rd_en;
assign mult_1_mem_b_0_rd_addr = mult_1_mem_a_0_rd_addr;
// memory interface to b_1
assign mult_1_mem_b_1_rd_en = mult_1_mem_a_1_rd_en;
assign mult_1_mem_b_1_rd_addr = mult_1_mem_a_1_rd_addr;
// memory interface to c_1
assign mult_1_mem_c_1_rd_en = running;
assign mult_1_mem_c_1_rd_addr = step_counter; 

assign step_din_a_0 = odd_even_counter ? mult_0_mem_a_0_dout :
                      mult_1_mem_a_0_dout;

assign step_din_a_1 = odd_even_counter ? mult_0_mem_a_1_dout :
                      mult_1_mem_a_1_dout;

assign step_din_b_0 = odd_even_counter ? mult_0_mem_b_0_dout :
                      mult_1_mem_b_0_dout;

assign step_din_b_1 = odd_even_counter ? mult_0_mem_b_1_dout :
                      mult_1_mem_b_1_dout;

assign step_din_c_0 = odd_even_counter ? mult_0_sum_step_0_buf :
                      mult_1_sum_step_0_buf;

assign step_din_c_1 = odd_even_counter ? mult_0_mem_c_1_dout :
                      mult_1_mem_c_1_dout;

assign mult_0_mem_res_dout = mem_res_0_dout;
assign mult_1_mem_res_dout = mem_res_1_dout;

assign mem_res_0_din = (mem_res_0_wr_addr == (WIDTH-1)) ? step_dout_carry_out_buf[RADIX-1:0] : 
                        step_dout_sum;

assign mem_res_1_din = (mem_res_1_wr_addr == (WIDTH-1)) ? step_dout_carry_out_buf[RADIX-1:0] : 
                        step_dout_sum;

assign round_done = mem_res_0_wr_en & (mem_res_0_wr_addr == (WIDTH-1));
 
always @(posedge clk) begin
  if (rst) begin
    odd_even_counter <= 1'b0;
    running <= 1'b0;
    round_counter <= {WIDTH_LOG{1'b0}};
    step_counter <= {WIDTH_LOG{1'b0}}; 
    mem_res_0_wr_addr <= {WIDTH_LOG{1'b0}};
    mem_res_1_wr_addr <= {WIDTH_LOG{1'b0}}; 
    step_din_d <= {RADIX{1'b0}};
    step_din_carry_in <= {(RADIX+2){1'b0}};
    mem_res_1_wr_en <= 1'b0;
    mult_0_sum_step_0_buf <= {RADIX{1'b0}};
    mult_1_sum_step_0_buf <= {RADIX{1'b0}};
    mem_rd_en <= 1'b0;
    mem_res_0_wr_en_pre_pre <= 1'b0;
    mem_res_0_dout_valid <= 1'b0;
    carry_valid <= 1'b0; 
    done <= 1'b0;
  end
  else begin
    running <= start ? 1'b1 :
               done ? 1'b0 :
               running;

    done <= round_done & (round_counter == (WIDTH-1)) ? 1'b1 :
             1'b0;

    mem_res_1_wr_en <= mem_res_0_wr_en;
    
    // used to control multiplication 0 or 1
    odd_even_counter <= (start | round_done | done) ? 1'b0 :
                        running ? ~odd_even_counter :
                        odd_even_counter; 

    round_counter <= (start | done) ? {WIDTH_LOG{1'b0}} :
                     round_done ? round_counter + 1 :
                     round_counter;

    mem_rd_en <= (start | round_done) & (round_counter < (WIDTH-1)) ? 1'b1 :
                 ((step_counter == (WIDTH-1)) & odd_even_counter) ? 1'b0 :
                 mem_rd_en;
    
    mem_res_0_wr_en_pre_pre <= mem_rd_en & (((step_counter > {WIDTH_LOG{1'b0}}) & (~odd_even_counter)) | ((step_counter == (WIDTH-1)) & odd_even_counter)) ? 1'b1 :
                               1'b0;

    step_counter <= (start | ((step_counter == (WIDTH-1)) & odd_even_counter) | done) ? {WIDTH_LOG{1'b0}} :
                    mem_rd_en & odd_even_counter ? step_counter + 1 :
                    step_counter; 

    mem_res_0_dout_valid <= mem_rd_en & (~odd_even_counter) & (round_counter > {WIDTH_LOG{1'b0}}); 

    step_din_d <= mem_res_0_dout_valid ? mem_res_0_dout :
                  mem_res_1_dout_valid ? mem_res_1_dout :
                  {RADIX{1'b0}};

    carry_valid <= (step_counter > {WIDTH_LOG{1'b0}}) & mem_rd_en;

    step_din_carry_in <= carry_valid ?  step_dout_carry_out : 
                         {(RADIX+2){1'b0}};

    mult_0_sum_step_0_buf <= (start | round_done | done) ? {RADIX{1'b0}} :
                             (step_counter == 1) & (~odd_even_counter) ?  step_dout_sum_comb :
                             mult_0_sum_step_0_buf;

    mult_1_sum_step_0_buf <= (start | round_done | done) ? {RADIX{1'b0}} :
                             (step_counter == 1) & odd_even_counter ?  step_dout_sum_comb :
                             mult_1_sum_step_0_buf;

    mem_res_0_wr_addr <= (start | (mem_res_0_wr_en & (mem_res_0_wr_addr == (WIDTH-1)))) ? {WIDTH_LOG{1'b0}} :
                         mem_res_0_wr_en ? mem_res_0_wr_addr + 1 :
                         mem_res_0_wr_addr;

    mem_res_1_wr_addr <= mem_res_0_wr_addr;
 
  end
end

 
  
step_sub #(.RADIX(RADIX)) step_inst (
  .rst(rst),
  .clk(clk),
  .a_0(step_din_a_0),
  .a_1(step_din_a_1),
  .b_0(step_din_b_0),
  .b_1(step_din_b_1),
  .c_0(step_din_c_0),
  .c_1(step_din_c_1),
  .d(step_din_d),
  .d_last(step_din_d_last),
  .carry_in(step_din_carry_in),
  .sum_comb(step_dout_sum_comb),
  .sum(step_dout_sum),
  .carry_out(step_dout_carry_out)
  );


// result for multiplication #0
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH)) single_port_mem_inst_res_0 (  
  .clock(clk),
  .data(mem_res_0_din),
  .address(mem_res_0_wr_en ? mem_res_0_wr_addr : (running ? mem_res_0_rd_addr : mult_0_mem_res_rd_addr)),
  .wr_en(mem_res_0_wr_en),
  .q(mem_res_0_dout)
  ); 

// result for mulitplication #1
single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH)) single_port_mem_inst_res_1 (
  .clock(clk),
  .data(mem_res_1_din),
  .address(mem_res_1_wr_en ? mem_res_1_wr_addr : (running ? mem_res_1_rd_addr : mult_1_mem_res_rd_addr)),
  .wr_en(mem_res_1_wr_en),
  .q(mem_res_1_dout)
  );

delay #(.WIDTH(1), .DELAY(2)) delay_inst_mem_res_0_wr_en_pre_pre (
  .clk(clk),
  .rst(rst),
  .din(mem_res_0_wr_en_pre_pre),
  .dout(mem_res_0_wr_en)
  );

delay #(.WIDTH(RADIX+2), .DELAY(1)) delay_inst_step_dout_carry_out (
  .clk(clk),
  .rst(rst),
  .din(step_dout_carry_out),
  .dout(step_dout_carry_out_buf)
  );

delay #(.WIDTH(1), .DELAY(1)) delay_inst_mem_res_0_dout_valid (
  .clk(clk),
  .rst(rst),
  .din(mem_res_0_dout_valid),
  .dout(mem_res_1_dout_valid)
  );

delay #(.WIDTH(1), .DELAY(2)) delay_inst_step_din_d_last (
  .clk(clk),
  .rst(rst),
  .din(step_counter == (WIDTH-1)),
  .dout(step_din_d_last)
  );
 
endmodule