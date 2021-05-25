/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      F(p^2) Montgomery multiplier
 * 
*/

// F(p^2) Montgomery multiplier, sub and add parts are closely coupled 
// inputs a = a0 + a1*i; b = b0 + b1*i
// outputs c = a*b = sub_res + i*add_part
// sub part has pattern: a0[j]*b0[i] - a1[j]*b1[i]
// add part has pattern: a0[j]*a1[i] - b0[j]*b1[i]

module fp2_mont_mul 
#(
  // size of one digit
  // w = 8/16/32/64/128, etc
  parameter RADIX = 32,
  // number of digits
  // WIDTH has to be a multiple of 2
  parameter WIDTH_REAL = 14,
  parameter WIDTH = ((WIDTH_REAL+1)/2)*2, 
  parameter WIDTH_LOG = `CLOG2(WIDTH),
  // parameter WIDTH_REAL_IS_ODD = (WIDTH > WIDTH_REAL) ? 1 : 0, 
  // parameters for memories holding inputs
  parameter INPUT_MEM_WIDTH = RADIX,
  parameter INPUT_MEM_DEPTH = WIDTH_REAL,
  parameter INPUT_MEM_DEPTH_LOG = `CLOG2(INPUT_MEM_DEPTH),
  // t[2*i] and t[2*i+1] are stored in one memory entry
  parameter RES_MEM_WIDTH = 2*RADIX,
  parameter RES_MEM_DEPTH = WIDTH/2,
  parameter RES_MEM_DEPTH_LOG = `CLOG2(RES_MEM_DEPTH)	
)
(
	input wire rst,
  input wire clk,
  input wire start,
  output wire done,
  output wire busy,

  // memory interface with inputs a0, a1, b0, and b1; a = a0 + i*a1; b = b0 + i*b1
    // a0
  output wire mem_a_0_rd_en,
  output reg [INPUT_MEM_DEPTH_LOG-1:0] mem_a_0_rd_addr,
  input  wire [INPUT_MEM_WIDTH-1:0] mem_a_0_dout,
    // a1
  output wire mem_a_1_rd_en,
  output wire [INPUT_MEM_DEPTH_LOG-1:0] mem_a_1_rd_addr,
  input  wire [INPUT_MEM_WIDTH-1:0] mem_a_1_dout,
    // b0
  output wire mem_b_0_rd_en,
  output wire [INPUT_MEM_DEPTH_LOG-1:0] mem_b_0_rd_addr,
  input  wire [INPUT_MEM_WIDTH-1:0] mem_b_0_dout,
    // b1
  output wire mem_b_1_rd_en,
  output reg [INPUT_MEM_DEPTH_LOG-1:0] mem_b_1_rd_addr,
  input  wire [INPUT_MEM_WIDTH-1:0] mem_b_1_dout,
    // c1 # this port may not be needed if mem_c_1 is initialized as ROM
  output wire mem_c_1_rd_en,
  output wire [INPUT_MEM_DEPTH_LOG-1:0] mem_c_1_rd_addr,
  input  wire [INPUT_MEM_WIDTH-1:0] mem_c_1_dout, 

  // interface to consts memory storing 2*p
  output wire px2_mem_rd_en,
  output wire [`CLOG2(WIDTH_REAL)-1:0] px2_mem_rd_addr,
  input wire [RADIX-1:0] px2_mem_dout,

  // memory interface with the results
    // sub result
  input  wire sub_mult_mem_res_rd_en,
  input  wire [RES_MEM_DEPTH_LOG-1:0] sub_mult_mem_res_rd_addr,  
  output wire [RES_MEM_WIDTH-1:0] sub_mult_mem_res_dout,

    // add result
  input  wire add_mult_mem_res_rd_en,
  input  wire [RES_MEM_DEPTH_LOG-1:0] add_mult_mem_res_rd_addr,  
  output wire [RES_MEM_WIDTH-1:0] add_mult_mem_res_dout
);

wire width_real_is_odd;
wire mult_done;

reg real_start;

// last step_din_d
reg step_din_d_last;

reg odd_even_counter; 
reg running;
reg mult_running;

reg [WIDTH_LOG-1:0] round_counter;
reg [`CLOG2(WIDTH+2)-1:0] step_counter; 
reg round_done;

// This version separates the logic of memory and computation fully to ensure a high Fmax
// since step modules are independent, they will have separate signals
// interface with the step_sub module
wire [RADIX-1:0] sub_step_din_a_0;
wire [RADIX-1:0] sub_step_din_a_1;
wire [RADIX-1:0] sub_step_din_b_0;
wire [RADIX-1:0] sub_step_din_b_1; 
wire [RADIX-1:0] sub_step_din_c_0;
wire [RADIX-1:0] sub_step_din_c_1;
wire [RADIX-1:0] sub_step_din_d;
wire [RADIX+1:0] sub_step_din_carry_in;
wire [RADIX-1:0] sub_step_dout_sum;
wire [RADIX+1:0] sub_step_dout_carry_out;

wire [RADIX-1:0] sub_step_dout_sum_comb; // step_dout_sum <= step_dout_sum_comb;
wire [RADIX-1:0] sub_step_dout_sum_buf;
reg [RADIX-1:0] sub_sum_step_0_buf;
wire [RADIX+1:0] sub_step_dout_carry_out_buf;
wire [RADIX+1:0] sub_step_dout_carry_out_buf_buf;

// interface with the step_add module
wire [RADIX-1:0] add_step_din_a_0;
wire [RADIX-1:0] add_step_din_a_1;
wire [RADIX-1:0] add_step_din_b_0;
wire [RADIX-1:0] add_step_din_b_1; 
wire [RADIX-1:0] add_step_din_c_0;
wire [RADIX-1:0] add_step_din_c_1;
wire [RADIX-1:0] add_step_din_d;
wire [RADIX+1:0] add_step_din_carry_in;
wire [RADIX-1:0] add_step_dout_sum;
wire [RADIX+1:0] add_step_dout_carry_out;

wire [RADIX-1:0] add_step_dout_sum_comb; // step_dout_sum <= step_dout_sum_comb;
wire [RADIX-1:0] add_step_dout_sum_buf;
reg [RADIX-1:0] add_sum_step_0_buf;
wire [RADIX+1:0] add_step_dout_carry_out_buf;
wire [RADIX+1:0] add_step_dout_carry_out_buf_buf;

reg mem_res_rd_running;
wire mem_res_wr_running;
wire mem_res_rd_en;
wire mem_res_wr_en;
wire [RES_MEM_DEPTH_LOG-1:0] mem_res_wr_addr;
wire [RES_MEM_DEPTH_LOG-1:0] mem_res_rd_addr;

wire [RES_MEM_WIDTH-1:0] sub_mem_res_din;
wire [RES_MEM_WIDTH-1:0] sub_mem_res_dout;
wire [RADIX-1:0] sub_mem_res_dout_left; // t[2*i]
wire [RADIX-1:0] sub_mem_res_dout_left_buf; // t[2*i+1]
wire [RADIX-1:0] sub_mem_res_dout_right;
wire [RADIX-1:0] sub_mem_res_dout_right_buf;
wire [RADIX-1:0] sub_mem_res_dout_right_buf_buf;

wire [RES_MEM_WIDTH-1:0] add_mem_res_din;
wire [RES_MEM_WIDTH-1:0] add_mem_res_dout;
wire [RADIX-1:0] add_mem_res_dout_left; // t[2*i]
wire [RADIX-1:0] add_mem_res_dout_left_buf; // t[2*i+1]
wire [RADIX-1:0] add_mem_res_dout_right;
wire [RADIX-1:0] add_mem_res_dout_right_buf_buf;

// interface to fp_adder
wire adder_start;
reg adder_digit_in_valid;
wire adder_carry_in;
wire [RADIX-1:0] adder_digit_a;
wire [RADIX-1:0] adder_digit_b;
wire adder_digit_out_valid;
wire [RADIX-1:0] adder_digit_res;
wire [RADIX-1:0] adder_digit_res_buf;
wire adder_done;
wire adder_carry_out;

// correction signals
// indicate if the result from the sub part needs a correction or not
reg mult_sub_negative_res_need_correction;
reg correction_running; 
wire correction_done;
wire correction_sub_mult_mem_res_wr_en;
wire correction_sub_mult_mem_res_rd_en;
reg [RES_MEM_DEPTH_LOG-1:0] correction_sub_mult_mem_res_wr_addr; 
wire [RES_MEM_DEPTH_LOG-1:0] correction_sub_mult_mem_res_rd_addr; 
wire [RES_MEM_WIDTH-1:0] correction_sub_mult_mem_res_din;


assign width_real_is_odd = (WIDTH > WIDTH_REAL) ? 1'b1 : 1'b0; 

assign correction_sub_mult_mem_res_rd_en = correction_running & ~(odd_even_counter);
assign correction_sub_mult_mem_res_rd_addr = correction_running ? (step_counter >> 1) : {RES_MEM_DEPTH_LOG{1'b0}};
assign correction_sub_mult_mem_res_din = {adder_digit_res_buf, adder_digit_res};
assign correction_done = correction_sub_mult_mem_res_wr_en & (correction_sub_mult_mem_res_wr_addr == (RES_MEM_DEPTH-1));

assign adder_start = mult_done;
assign adder_carry_in = 1'b0;
assign adder_digit_a = odd_even_counter ? sub_mem_res_dout_left : sub_mem_res_dout_right_buf;
assign adder_digit_b = mult_sub_negative_res_need_correction ? px2_mem_dout : {RADIX{1'b0}}; 

assign px2_mem_rd_en = correction_running;
assign px2_mem_rd_addr = correction_running ? step_counter : {`CLOG2(WIDTH_REAL){1'b0}};

assign busy = running;

assign mem_res_rd_en = mem_res_rd_running & (~odd_even_counter);
assign mem_res_wr_en = mem_res_wr_running & odd_even_counter;
assign mem_res_rd_addr = (step_counter < WIDTH) ? (step_counter >> 1) :
                         {RES_MEM_DEPTH_LOG{1'b0}}; 

assign sub_mem_res_dout_left = sub_mem_res_dout[RES_MEM_WIDTH-1:RADIX]; // t[2*i]
assign sub_mem_res_dout_right = sub_mem_res_dout[RADIX-1:0]; // t[2*i+1]
assign sub_mem_res_din = (width_real_is_odd & (mem_res_wr_addr == (RES_MEM_DEPTH-1))) ? {{sub_step_dout_carry_out_buf_buf[RADIX-1:0]}, {RADIX{1'b0}}} :
                         ((~width_real_is_odd) & (mem_res_wr_addr == (RES_MEM_DEPTH-1))) ? {sub_step_dout_sum_buf, {sub_step_dout_carry_out_buf[RADIX-1:0]}} :
                         {sub_step_dout_sum_buf, sub_step_dout_sum};

assign add_mem_res_dout_left = add_mem_res_dout[RES_MEM_WIDTH-1:RADIX]; // t[2*i]
assign add_mem_res_dout_right = add_mem_res_dout[RADIX-1:0]; // t[2*i+1]
assign add_mem_res_din = (width_real_is_odd & (mem_res_wr_addr == (RES_MEM_DEPTH-1))) ? {{add_step_dout_carry_out_buf_buf[RADIX-1:0]}, {RADIX{1'b0}}} :
                         ((~width_real_is_odd) & (mem_res_wr_addr == (RES_MEM_DEPTH-1))) ? {add_step_dout_sum_buf, {add_step_dout_carry_out_buf[RADIX-1:0]}} :
                         {add_step_dout_sum_buf, add_step_dout_sum};

// memory interface to a_0
assign mem_a_0_rd_en = running | start | real_start;  
assign mem_a_1_rd_en = mem_a_0_rd_en;
assign mem_a_1_rd_addr = mem_a_0_rd_addr;
// memory interface to b_0
assign mem_b_0_rd_en = mem_a_0_rd_en;
assign mem_b_0_rd_addr = mem_b_1_rd_addr;
// memory interface to b_1
assign mem_b_1_rd_en = mem_a_0_rd_en; 
// memory interface to c_1
assign mem_c_1_rd_en = mem_a_0_rd_en;
assign mem_c_1_rd_addr = mem_a_0_rd_addr;
 
assign sub_step_din_c_0 = sub_sum_step_0_buf; // 0 or mm 

assign sub_step_din_d = (round_counter == {WIDTH_LOG{1'b0}}) ? {RADIX{1'b0}} : // first round = 0
                        (step_counter == 1) ? sub_mem_res_dout_left :
                        odd_even_counter ? sub_mem_res_dout_right_buf_buf :
                        sub_mem_res_dout_left_buf;
 
assign sub_step_din_carry_in = (step_counter < 2) ? {(RADIX+2){1'b0}} :
                               (step_counter == 3) ? sub_step_dout_carry_out_buf :
                               sub_step_dout_carry_out;

assign add_step_din_a_0 = sub_step_din_a_0;
assign add_step_din_a_1 = sub_step_din_b_1;
assign add_step_din_b_0 = sub_step_din_b_0;
assign add_step_din_b_1 = sub_step_din_a_1;
assign add_step_din_c_0 = add_sum_step_0_buf; // 0 or mm
assign add_step_din_c_1 = sub_step_din_c_1;

assign add_step_din_d = (round_counter == {WIDTH_LOG{1'b0}}) ? {RADIX{1'b0}} : // first round = 0
                        (step_counter == 1) ? add_mem_res_dout_left :
                        odd_even_counter ? add_mem_res_dout_right_buf_buf :
                        add_mem_res_dout_left_buf;

assign add_step_din_carry_in = (step_counter < 2) ? {(RADIX+2){1'b0}} :
                               (step_counter == 3) ? add_step_dout_carry_out_buf :
                               add_step_dout_carry_out;

assign sub_mult_mem_res_dout = sub_mem_res_dout;
assign add_mult_mem_res_dout = add_mem_res_dout; 
assign done = correction_done;


always @(posedge clk) begin
  if (rst) begin
    odd_even_counter <= 1'b0;
    running <= 1'b0;
    round_counter <= {WIDTH_LOG{1'b0}};
    step_counter <= {(`CLOG2(WIDTH+2)){1'b0}}; 
    mem_res_rd_running <= 1'b0; 
    mem_a_0_rd_addr <= {INPUT_MEM_DEPTH_LOG{1'b0}};
    mem_b_1_rd_addr <= {INPUT_MEM_DEPTH_LOG{1'b0}}; 
    sub_sum_step_0_buf <= {RADIX{1'b0}}; 
    add_sum_step_0_buf <= {RADIX{1'b0}}; 
    step_din_d_last <= 1'b0;
    round_done <= 1'b0;  
    correction_running <= 1'b0; 
    mult_sub_negative_res_need_correction <= 1'b0;  
    correction_sub_mult_mem_res_wr_addr <= {RES_MEM_DEPTH_LOG{1'b0}};
    adder_digit_in_valid <= 1'b0;
    mult_running <= 1'b0;
    real_start <= 1'b0;
  end
  else begin
    real_start <= start;

    running <= real_start ? 1'b1 :
               done ? 1'b0 :
               running;

    mem_a_0_rd_addr <= done ? {INPUT_MEM_DEPTH_LOG{1'b0}} :
                       real_start | (step_counter == (WIDTH+1)) ? mem_a_0_rd_addr + 1 :
                       (mem_a_0_rd_addr == (WIDTH_REAL-1)) ? {INPUT_MEM_DEPTH_LOG{1'b0}} :
                       (mem_a_0_rd_addr > 0) ? mem_a_0_rd_addr + 1 :
                       mem_a_0_rd_addr;

    mult_running <= real_start ? 1'b1 :
                    mult_done ? 1'b0 :
                    mult_running;

    adder_digit_in_valid <= correction_running;
       
    step_counter <= (real_start | round_done | mult_done) ? {WIDTH_LOG{1'b0}} :
                    running ? step_counter + 1 :
                    step_counter;

    round_counter <= (real_start | mult_done | ((step_counter == (WIDTH+1)) & (round_counter == (WIDTH_REAL-1)))) ?  {WIDTH_LOG{1'b0}} :
                      round_done ? round_counter + 1 :
                      round_counter;

    round_done <= (step_counter == WIDTH) & mult_running; 

    mem_b_1_rd_addr <= (real_start | done) ? {INPUT_MEM_DEPTH_LOG{1'b0}} :
                       (mem_a_0_rd_addr == (WIDTH_REAL-1)) ? mem_b_1_rd_addr + 1 :
                       mem_b_1_rd_addr;

    mem_res_rd_running <= (real_start | (round_done & (round_counter < (WIDTH_REAL-1)))) ? 1'b1 :
                          (step_counter == (WIDTH-1)) ? 1'b0 :
                          mem_res_rd_running;

    odd_even_counter <= (real_start | mult_done | round_done) ? 1'b0 :
                        running ? ~odd_even_counter :
                        odd_even_counter; 
    
    step_din_d_last <= (step_counter == WIDTH_REAL) & mult_running; 

    sub_sum_step_0_buf <= (real_start | round_done | mult_done) ? {RADIX{1'b0}} :
                          (step_counter == 1) ?  sub_step_dout_sum_comb :
                          sub_sum_step_0_buf;
    
    add_sum_step_0_buf <= (real_start | round_done | mult_done) ? {RADIX{1'b0}} :
                          (step_counter == 1) ?  add_step_dout_sum_comb :
                          add_sum_step_0_buf;

    correction_running <= mult_done ? 1'b1 :
                          (step_counter == (WIDTH_REAL-1)) ? 1'b0 :
                          correction_running;

    mult_sub_negative_res_need_correction <= real_start ? 1'b0 :
                                              mult_done & width_real_is_odd ? sub_mem_res_din[RES_MEM_WIDTH-1] :
                                              mult_done & (~width_real_is_odd) ? sub_mem_res_din[RADIX-1] :
                                              mult_sub_negative_res_need_correction;

    correction_sub_mult_mem_res_wr_addr <= adder_start ? {RES_MEM_DEPTH_LOG{1'b0}} :
                                           correction_sub_mult_mem_res_wr_en ? correction_sub_mult_mem_res_wr_addr + 1 :
                                           correction_sub_mult_mem_res_wr_addr;
 
  end
end

step_sub #(.RADIX(RADIX)) step_sub_inst (
  .rst(rst),
  .clk(clk),
  .a_0(sub_step_din_a_0),
  .a_1(sub_step_din_a_1),
  .b_0(sub_step_din_b_0),
  .b_1(sub_step_din_b_1),
  .c_0(sub_step_din_c_0),
  .c_1(sub_step_din_c_1),
  .d(sub_step_din_d),
  .d_last(step_din_d_last),
  .carry_in(sub_step_din_carry_in),
  .sum_comb(sub_step_dout_sum_comb),
  .sum(sub_step_dout_sum),
  .carry_out(sub_step_dout_carry_out)
  );

step_add #(.RADIX(RADIX)) step_add_inst (
  .rst(rst),
  .clk(clk),
  .a_0(add_step_din_a_0),
  .a_1(add_step_din_a_1),
  .b_0(add_step_din_b_0),
  .b_1(add_step_din_b_1),
  .c_0(add_step_din_c_0),
  .c_1(add_step_din_c_1),
  .d(add_step_din_d),
  .d_last(step_din_d_last),
  .carry_in(add_step_din_carry_in),
  .sum_comb(add_step_dout_sum_comb),
  .sum(add_step_dout_sum),
  .carry_out(add_step_dout_carry_out)
  );

// result for multiplication sub part
single_port_mem #(.WIDTH(RES_MEM_WIDTH), .DEPTH(RES_MEM_DEPTH)) sub_single_port_mem_inst_res (  
  .clock(clk),
  .data(mem_res_wr_en ? sub_mem_res_din : correction_sub_mult_mem_res_din),
  .address(mem_res_wr_en ? mem_res_wr_addr : (correction_sub_mult_mem_res_wr_en ? correction_sub_mult_mem_res_wr_addr : (correction_running ? correction_sub_mult_mem_res_rd_addr : (running ? mem_res_rd_addr : sub_mult_mem_res_rd_addr)))),
  .wr_en(mem_res_wr_en | correction_sub_mult_mem_res_wr_en),
  .q(sub_mem_res_dout)
  );

fp_adder #(.RADIX(RADIX), .DIGITS(WIDTH_REAL)) fp_adder_inst (
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

// result for multiplication add part
single_port_mem #(.WIDTH(RES_MEM_WIDTH), .DEPTH(RES_MEM_DEPTH)) add_single_port_mem_inst_res (  
  .clock(clk),
  .data(add_mem_res_din),
  .address(mem_res_wr_en ? mem_res_wr_addr : (running ? mem_res_rd_addr : add_mult_mem_res_rd_addr)),
  .wr_en(mem_res_wr_en),
  .q(add_mem_res_dout)
  );

delay #(.WIDTH(1), .DELAY(4)) delay_inst_mem_res_wr_running (
  .clk(clk),
  .rst(rst),
  .din(mem_res_rd_running),
  .dout(mem_res_wr_running)
  );

delay #(.WIDTH(RES_MEM_DEPTH_LOG), .DELAY(5)) delay_inst_mem_res_wr_addr (
  .clk(clk),
  .rst(rst),
  .din(mem_res_rd_addr),
  .dout(mem_res_wr_addr)
  );

delay #(.WIDTH(1), .DELAY(2)) delay_inst_done (
  .clk(clk),
  .rst(rst),
  .din((step_counter == (WIDTH+1)) & (round_counter == (WIDTH_REAL-1))),
  .dout(mult_done)
  ); 

delay #(.WIDTH(RADIX), .DELAY(1)) sub_delay_inst_mem_res_dout_left_buf (
  .clk(clk),
  .rst(rst),
  .din(sub_mem_res_dout_left),
  .dout(sub_mem_res_dout_left_buf)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) sub_delay_inst_mem_res_dout_right_buf (
  .clk(clk),
  .rst(rst),
  .din(sub_mem_res_dout_right),
  .dout(sub_mem_res_dout_right_buf)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) sub_delay_inst_mem_res_dout_right_buf_buf (
  .clk(clk),
  .rst(rst),
  .din(sub_mem_res_dout_right_buf),
  .dout(sub_mem_res_dout_right_buf_buf)
  );

 
delay #(.WIDTH(RADIX+2), .DELAY(1)) sub_delay_inst_step_dout_carry_out_buf (
  .clk(clk),
  .rst(rst),
  .din(sub_step_dout_carry_out), 
  .dout(sub_step_dout_carry_out_buf)
  ); 

delay #(.WIDTH(RADIX+2), .DELAY(1)) sub_delay_inst_step_dout_carry_out_buf_buf (
  .clk(clk),
  .rst(rst),
  .din(sub_step_dout_carry_out_buf), 
  .dout(sub_step_dout_carry_out_buf_buf)
  ); 

delay #(.WIDTH(RADIX), .DELAY(1)) sub_delay_inst_step_dout_sum_buf (
  .clk(clk),
  .rst(rst),
  .din(sub_step_dout_sum),
  .dout(sub_step_dout_sum_buf)
  ); 


delay #(.WIDTH(RADIX), .DELAY(1)) add_delay_inst_mem_res_dout_left_buf (
  .clk(clk),
  .rst(rst),
  .din(add_mem_res_dout_left),
  .dout(add_mem_res_dout_left_buf)
  );

delay #(.WIDTH(RADIX), .DELAY(2)) add_delay_inst_mem_res_dout_right_buf_buf (
  .clk(clk),
  .rst(rst),
  .din(add_mem_res_dout_right),
  .dout(add_mem_res_dout_right_buf_buf)
  );

 
delay #(.WIDTH(RADIX+2), .DELAY(1)) add_delay_inst_step_dout_carry_out_buf (
  .clk(clk),
  .rst(rst),
  .din(add_step_dout_carry_out), 
  .dout(add_step_dout_carry_out_buf)
  ); 

delay #(.WIDTH(RADIX+2), .DELAY(1)) add_delay_inst_step_dout_carry_out_buf_buf (
  .clk(clk),
  .rst(rst),
  .din(add_step_dout_carry_out_buf), 
  .dout(add_step_dout_carry_out_buf_buf)
  ); 

delay #(.WIDTH(RADIX), .DELAY(1)) add_delay_inst_step_dout_sum_buf (
  .clk(clk),
  .rst(rst),
  .din(add_step_dout_sum),
  .dout(add_step_dout_sum_buf)
  ); 

delay #(.WIDTH(RADIX), .DELAY(1)) delay_inst_adder_digit_res_buf (
  .clk(clk),
  .rst(rst),
  .din(adder_digit_res),
  .dout(adder_digit_res_buf)
  );

delay #(.WIDTH(1), .DELAY(3)) delay_inst_correction_sub_mult_mem_res_wr_en (
  .clk(clk),
  .rst(rst),
  .din(correction_sub_mult_mem_res_rd_en),
  .dout(correction_sub_mult_mem_res_wr_en)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) delay_inst_sub_step_din_a_0 (
  .clk(clk),
  .rst(rst),
  .din(mem_a_0_dout),
  .dout(sub_step_din_a_0)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) delay_inst_sub_step_din_a_1 (
  .clk(clk),
  .rst(rst),
  .din(mem_b_0_dout),
  .dout(sub_step_din_a_1)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) delay_inst_sub_step_din_b_0 (
  .clk(clk),
  .rst(rst),
  .din(mem_a_1_dout),
  .dout(sub_step_din_b_0)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) delay_inst_sub_step_din_b_1 (
  .clk(clk),
  .rst(rst),
  .din(mem_b_1_dout),
  .dout(sub_step_din_b_1)
  );

delay #(.WIDTH(RADIX), .DELAY(1)) delay_inst_sub_step_din_c_1 (
  .clk(clk),
  .rst(rst),
  .din(mem_c_1_dout),
  .dout(sub_step_din_c_1)
  ); 

endmodule