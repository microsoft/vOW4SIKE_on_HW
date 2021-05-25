/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      unified unit for F(p^2) and F(p) addition and subtraction
 * 
*/

// F(p^2)/F(p) add/sub/correction unit

// When cmd = 1:
// Function as fp2add() / fpadd()
// Computation: c = a + b mod 2*prime, with correction
// Inputs: a, b in [0, 2*prime-1]
// Output: c in [0, 2*prime-1]

// When cmd = 2: 
// Function as fp2sub() / fpsub()
// Computation: c = a - b mod 2*prime, with correction
// Inputs: a, b in [0, 2*prime-1]
// Output: c in [0, 2*prime-1]

// When cmd = 3:
// Function as: mp_add()
// Computation: c = a + b, without correction   
// Inputs: a, b in [0, 2^5*prime-1]
// Output: c in [0, 2^6*prime-1]

// When cmd = 4:
// Function as: mp_sub434_p2()
// Computation: c = a - b + 2*prime, without correction 
// Inputs: a, b in [0, 2*prime-1]
// Output: c in [0, 4*prime-1]

// When cmd = 5:
// Function as: mp_sub434_p4()
// Computation: c = a - b + 4*prime, without correction 
// Inputs: a, b in [0, 4*prime-1]
// Output: c in [0, 8*prime-1]

module fp2_sub_add_correction
#(
  parameter RADIX = 32,
  parameter DIGITS = 14,
  parameter DIGITS_LOG = `CLOG2(DIGITS), 
  parameter FILE_CONST_PX2 = "px2.mem",
  parameter FILE_CONST_PX4 = "px4.mem"
)
(
  input wire start,
  input wire rst,
  input wire clk,
  input wire [2:0] cmd, // stay valid
  input wire extension_field_op, // stay valid, 1'b1: GF(p^2) operation; 1'b0: GF(p) operation

   // memory interface with inputs a0, a1, b0, and b1; a = a0 + i*a1; b = b0 + i*b1
    // a0
  output wire mem_a_0_rd_en,
  output wire [DIGITS_LOG-1:0] mem_a_0_rd_addr,
  input  wire [RADIX-1:0] mem_a_0_dout,
    // a1
  output wire mem_a_1_rd_en,
  output wire [DIGITS_LOG-1:0] mem_a_1_rd_addr,
  input  wire [RADIX-1:0] mem_a_1_dout,
    // b0
  output wire mem_b_0_rd_en,
  output wire [DIGITS_LOG-1:0] mem_b_0_rd_addr,
  input  wire [RADIX-1:0] mem_b_0_dout,
    // b1
  output wire mem_b_1_rd_en,
  output wire [DIGITS_LOG-1:0] mem_b_1_rd_addr,
  input  wire [RADIX-1:0] mem_b_1_dout,
  
  // memory interface with consts memories
    // px2
  output wire px2_mem_rd_en,
  output wire [DIGITS_LOG-1:0] px2_mem_rd_addr,
  input  wire [RADIX-1:0] px2_mem_dout,
    // px4
  output wire px4_mem_rd_en,
  output wire [DIGITS_LOG-1:0] px4_mem_rd_addr,
  input  wire [RADIX-1:0] px4_mem_dout,

  // memory interface with output c0 and c1; c = c0 + i*c1
    // c0
  input wire mem_c_0_rd_en,
  input wire [DIGITS_LOG-1:0] mem_c_0_rd_addr,
  output  wire [RADIX-1:0] mem_c_0_dout,
    // c1
  input wire mem_c_1_rd_en,
  input wire [DIGITS_LOG-1:0] mem_c_1_rd_addr,
  output  wire [RADIX-1:0] mem_c_1_dout,

  output reg busy,
  output reg done


);

// interface to fp_adder
wire left_adder_start;
wire left_adder_digit_in_valid;
wire left_adder_carry_in;
wire [RADIX-1:0] left_adder_digit_a;
wire [RADIX-1:0] left_adder_digit_b;
wire left_adder_digit_out_valid;
wire [RADIX-1:0] left_adder_digit_res;
wire left_adder_done;
wire left_adder_carry_out;

wire right_adder_start;
wire right_adder_digit_in_valid;
wire right_adder_carry_in;
wire [RADIX-1:0] right_adder_digit_a;
wire [RADIX-1:0] right_adder_digit_b;
wire right_adder_digit_out_valid;
wire [RADIX-1:0] right_adder_digit_res;
wire right_adder_done;
wire right_adder_carry_out;

// interface to serial_comparator
reg left_comparator_start;
reg left_comparator_digit_valid;
wire [RADIX-1:0] left_comparator_digit_a;
wire [RADIX-1:0] left_comparator_digit_b;
wire left_comparator_a_bigger_than_b;
wire left_comparator_done;

wire right_comparator_start;
wire right_comparator_digit_valid;
wire [RADIX-1:0] right_comparator_digit_a;
wire [RADIX-1:0] right_comparator_digit_b;
wire right_comparator_a_bigger_than_b;
wire right_comparator_done;

// interface with result memories
// c0
wire mem_c_0_add_0_wr_en;
wire [DIGITS_LOG-1:0] mem_c_0_add_0_wr_addr;
wire [DIGITS_LOG-1:0] mem_c_0_wr_addr;
wire [RADIX-1:0] mem_c_0_add_0_din;
wire mem_c_0_add_0_rd_en;
wire [DIGITS_LOG-1:0] mem_c_0_add_0_rd_addr;
wire [RADIX-1:0] mem_c_0_add_0_dout;

wire mem_c_0_add_1_wr_en;
wire [DIGITS_LOG-1:0] mem_c_0_add_1_wr_addr;
wire [RADIX-1:0] mem_c_0_add_1_din; 
wire [RADIX-1:0] mem_c_0_add_1_dout; 

// c1
wire mem_c_1_add_0_wr_en;
wire [DIGITS_LOG-1:0] mem_c_1_add_0_wr_addr;
wire [RADIX-1:0] mem_c_1_add_0_din;
wire mem_c_1_add_0_rd_en;
wire [DIGITS_LOG-1:0] mem_c_1_add_0_rd_addr;
wire [RADIX-1:0] mem_c_1_add_0_dout;

wire mem_c_1_add_1_wr_en;
wire [DIGITS_LOG-1:0] mem_c_1_add_1_wr_addr;
wire [RADIX-1:0] mem_c_1_add_1_din; 
wire [RADIX-1:0] mem_c_1_add_1_dout; 

// other signals
reg [DIGITS_LOG-1:0] rd_counter;
reg [DIGITS_LOG-1:0] rd_counter_buf;
reg add_0_running_pre;
reg add_0_running;
reg left_fpadd_correction_needed;
reg left_fpsub_correction_needed;
reg right_fpadd_correction_needed;
reg right_fpsub_correction_needed;
reg add_1_running_pre;
reg add_1_running;
reg add_counter;

wire comparator_enabled;
wire adder_1_start;

wire init_carry_in;

assign mem_c_0_dout = (cmd == 3'd3) ? mem_c_0_add_0_dout : mem_c_0_add_1_dout;
assign mem_c_1_dout = (cmd == 3'd3) ? mem_c_1_add_0_dout : mem_c_1_add_1_dout;

assign init_carry_in = (start & ((cmd == 3'd2) || (cmd == 3'd4) || (cmd == 3'd5)));

assign left_adder_start = start | adder_1_start;
assign left_adder_carry_in =  init_carry_in || (adder_1_start & left_fpadd_correction_needed);
assign left_adder_digit_in_valid = add_0_running | add_1_running;

assign left_adder_digit_a = add_0_running ? mem_a_0_dout :
                            add_1_running ? mem_c_0_add_0_dout :
                            {RADIX{1'b0}}; 

assign left_adder_digit_b = add_0_running & ((cmd == 3'd1) || (cmd == 3'd3)) ? mem_b_0_dout :
                            add_0_running ? ~(mem_b_0_dout) :
                            add_1_running & (cmd == 3'd1) & left_fpadd_correction_needed ? ~(px2_mem_dout) :
                            add_1_running & (((cmd == 3'd2) & left_fpsub_correction_needed) || (cmd == 3'd4)) ? px2_mem_dout :
                            add_1_running & (cmd == 3'd5)? px4_mem_dout :
                            {RADIX{1'b0}};

assign right_adder_start = left_adder_start & extension_field_op;
assign right_adder_carry_in = init_carry_in || ((cmd == 3'd1) & right_fpadd_correction_needed);
assign right_adder_digit_in_valid = left_adder_digit_in_valid & extension_field_op;

assign right_adder_digit_a = add_0_running & extension_field_op ? mem_a_1_dout :
                             add_1_running & extension_field_op ? mem_c_1_add_0_dout :
                            {RADIX{1'b0}}; 

assign right_adder_digit_b = add_0_running & extension_field_op & ((cmd == 3'd1) || (cmd == 3'd3)) ? mem_b_1_dout :
                             add_0_running & extension_field_op ? ~(mem_b_1_dout) :
                             add_1_running & extension_field_op & (cmd == 3'd1) & right_fpadd_correction_needed ? ~(px2_mem_dout) :
                             add_1_running & extension_field_op & (((cmd == 3'd2) & right_fpsub_correction_needed) || (cmd == 3'd4)) ? px2_mem_dout :
                             add_1_running & extension_field_op & (cmd == 3'd5)? px4_mem_dout :
                             {RADIX{1'b0}};

assign mem_a_0_rd_en = add_0_running_pre;
assign mem_a_0_rd_addr = mem_a_0_rd_en ? rd_counter : {DIGITS_LOG{1'b0}};
assign mem_b_0_rd_en = mem_a_0_rd_en;
assign mem_b_0_rd_addr = mem_a_0_rd_addr;

assign mem_c_0_add_0_wr_en = left_adder_digit_out_valid & (add_counter == 1'b0);
assign mem_c_0_add_0_wr_addr = (add_counter == 1'b0) ? mem_c_0_wr_addr : {DIGITS_LOG{1'b0}};
assign mem_c_0_add_0_din = (add_counter == 1'b0) ? left_adder_digit_res : {RADIX{1'b0}};
assign mem_c_0_add_0_rd_en = add_1_running_pre;
assign mem_c_0_add_0_rd_addr = (add_counter == 1'b1) ? rd_counter : {DIGITS_LOG{1'b0}};

assign mem_c_0_add_1_wr_en = left_adder_digit_out_valid & (add_counter == 1'b1);
assign mem_c_0_add_1_wr_addr = (add_counter == 1'b1) ? mem_c_0_wr_addr : {DIGITS_LOG{1'b0}};
assign mem_c_0_add_1_din = (add_counter == 1'b1) ? left_adder_digit_res : {RADIX{1'b0}};

assign mem_a_1_rd_addr = mem_a_0_rd_addr;
assign mem_a_1_rd_en = mem_a_0_rd_en;
assign mem_b_1_rd_addr = mem_b_0_rd_addr;
assign mem_b_1_rd_en = mem_b_0_rd_en;

assign mem_c_1_add_0_wr_en = extension_field_op & mem_c_0_add_0_wr_en;
assign mem_c_1_add_0_wr_addr = extension_field_op ? mem_c_0_add_0_wr_addr : {DIGITS_LOG{1'b0}};
assign mem_c_1_add_0_din = (add_counter == 1'b0) & extension_field_op ? right_adder_digit_res : {RADIX{1'b0}};
assign mem_c_1_add_0_rd_en = extension_field_op & add_1_running_pre;
assign mem_c_1_add_0_rd_addr = extension_field_op ? mem_c_0_add_0_rd_addr : {DIGITS_LOG{1'b0}};

assign mem_c_1_add_1_wr_en = extension_field_op & mem_c_0_add_1_wr_en;
assign mem_c_1_add_1_wr_addr = extension_field_op ? mem_c_0_add_1_wr_addr : {DIGITS_LOG{1'b0}};
assign mem_c_1_add_1_din = extension_field_op & (add_counter == 1'b1) ? right_adder_digit_res : {RADIX{1'b0}};

assign comparator_enabled = (add_counter == 1'b0) & (cmd == 3'd1);
assign left_comparator_digit_a = comparator_enabled ? left_adder_digit_res : {RADIX{1'b0}};
assign left_comparator_digit_b = comparator_enabled ? px2_mem_dout : {RADIX{1'b0}};
assign right_comparator_start = left_comparator_start & extension_field_op;
assign right_comparator_digit_valid = left_comparator_digit_valid & extension_field_op;
assign right_comparator_digit_a = comparator_enabled & extension_field_op ? right_adder_digit_res : {RADIX{1'b0}};
assign right_comparator_digit_b = extension_field_op ? left_comparator_digit_b : {RADIX{1'b0}};

assign px2_mem_rd_en = (cmd == 3'd1) || (((cmd == 3'd2) || (cmd == 3'd4)) & add_1_running_pre);
assign px2_mem_rd_addr = (add_1_running_pre & px2_mem_rd_en) ? rd_counter : 
                         px2_mem_rd_en ? rd_counter_buf :
                         {DIGITS_LOG{1'b0}};

assign px4_mem_rd_en = (cmd == 3'd5) & add_1_running_pre;
assign px4_mem_rd_addr = px4_mem_rd_en ? rd_counter : {DIGITS_LOG{1'b0}}; 


always @(posedge clk) begin
  if (rst) begin
    add_0_running_pre <= 1'b0;
    add_0_running <= 1'b0;
    add_1_running_pre <= 1'b0;
    add_1_running <= 1'b0;
    busy <= 1'b0;
    done <= 1'b0;
    add_counter <= 1'b0;  
    rd_counter <= {DIGITS_LOG{1'b0}};
    rd_counter_buf <= {DIGITS_LOG{1'b0}};
    left_comparator_start <= 1'b0;
    left_comparator_digit_valid <= 1'b0; 
    left_fpadd_correction_needed <= 1'b0;
    right_fpadd_correction_needed <= 1'b0;
    left_fpsub_correction_needed <= 1'b0; 
    right_fpsub_correction_needed <= 1'b0;  
  end 
  else begin
    add_0_running_pre <= start ? 1'b1 :
                         (rd_counter == (DIGITS-1)) ? 1'b0 :
                         add_0_running_pre;

    add_0_running <= add_0_running_pre;

    add_1_running_pre <= adder_1_start ? 1'b1 :  
                         (rd_counter == (DIGITS-1)) ? 1'b0 :
                         add_1_running_pre;

    add_1_running <= add_1_running_pre;

    add_counter <= start | done ? 1'b0 :
                   left_adder_done ? 1'b1 :
                   add_counter;

    busy <= start ? 1'b1 :
            done ? 1'b0 :
            busy;

    rd_counter <= start | adder_1_start ? {DIGITS_LOG{1'b0}} :  
                  busy & (rd_counter < (DIGITS-1)) ? rd_counter + 1 :
                  rd_counter;

    rd_counter_buf <= rd_counter;

    left_comparator_start <= left_adder_start & (add_counter == 1'b0) & (cmd == 3'd1);

    left_comparator_digit_valid <= (add_counter == 1'b0) & (cmd == 3'd1) ? left_adder_digit_in_valid : 1'b0; 

    left_fpadd_correction_needed <= start | done ? 1'b0 :
                                    (cmd == 3'd1) & left_comparator_a_bigger_than_b & left_comparator_done ? 1'b1 :
                                    left_fpadd_correction_needed;

    right_fpadd_correction_needed <= start | done ? 1'b0 :
                                    (cmd == 3'd1) & right_comparator_a_bigger_than_b & right_comparator_done ? 1'b1 :
                                    right_fpadd_correction_needed;

    left_fpsub_correction_needed <= start | done ? 1'b0 :
                                    (mem_c_0_add_0_wr_en & (mem_c_0_add_0_wr_addr == (DIGITS-1))) ? mem_c_0_add_0_din[RADIX-1] :
                                    left_fpsub_correction_needed;

    right_fpsub_correction_needed <= start | done ? 1'b0 :
                                    (mem_c_1_add_0_wr_en & (mem_c_1_add_0_wr_addr == (DIGITS-1))) ? mem_c_1_add_0_din[RADIX-1] :
                                    right_fpsub_correction_needed;

    done <= (cmd == 3'd3) ? mem_c_0_add_0_wr_en & (mem_c_0_wr_addr == (DIGITS-1)) :
            (add_counter == 1'b1) & mem_c_0_add_1_wr_en & (mem_c_0_wr_addr == (DIGITS-1));
 
  end
end

fp_adder #(.RADIX(RADIX), .DIGITS(DIGITS)) fp_left_adder_inst (
  .start(left_adder_start),
  .rst(rst),
  .clk(clk),
  .digit_in_valid(left_adder_digit_in_valid),
  .carry_in(left_adder_carry_in),
  .digit_a(left_adder_digit_a),
  .digit_b(left_adder_digit_b),
  .digit_out_valid(left_adder_digit_out_valid),
  .digit_res(left_adder_digit_res),
  .done(left_adder_done),
  .carry_out(left_adder_carry_out)
  );

fp_adder #(.RADIX(RADIX), .DIGITS(DIGITS)) fp_right_adder_inst (
  .start(right_adder_start),
  .rst(rst),
  .clk(clk),
  .digit_in_valid(right_adder_digit_in_valid),
  .carry_in(right_adder_carry_in),
  .digit_a(right_adder_digit_a),
  .digit_b(right_adder_digit_b),
  .digit_out_valid(right_adder_digit_out_valid),
  .digit_res(right_adder_digit_res),
  .done(right_adder_done),
  .carry_out(right_adder_carry_out)
  );

serial_comparator #(.RADIX(RADIX), .DIGITS(DIGITS)) left_serial_comparator_inst (
  .start(left_comparator_start),
  .rst(rst),
  .clk(clk),
  .digit_valid(left_comparator_digit_valid), 
  .digit_a(left_comparator_digit_a),
  .digit_b(left_comparator_digit_b), 
  .a_bigger_than_b(left_comparator_a_bigger_than_b),
  .done(left_comparator_done)
  );

serial_comparator #(.RADIX(RADIX), .DIGITS(DIGITS)) right_serial_comparator_inst (
  .start(right_comparator_start),
  .rst(rst),
  .clk(clk),
  .digit_valid(right_comparator_digit_valid), 
  .digit_a(right_comparator_digit_a),
  .digit_b(right_comparator_digit_b), 
  .a_bigger_than_b(right_comparator_a_bigger_than_b),
  .done(right_comparator_done)
  );

// memory storing c_0_add_0 result
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_c_0_add_0 (  
  .clock(clk),
  .data(mem_c_0_add_0_din),
  .address(mem_c_0_add_0_wr_en ? mem_c_0_add_0_wr_addr : (mem_c_0_add_0_rd_en ? mem_c_0_add_0_rd_addr : mem_c_0_rd_addr)),
  .wr_en(mem_c_0_add_0_wr_en),
  .q(mem_c_0_add_0_dout)
  );

// memory storing c_0_add_1 result
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_c_0_add_1 (  
  .clock(clk),
  .data(mem_c_0_add_1_din),
  .address(mem_c_0_add_1_wr_en ? mem_c_0_add_1_wr_addr : mem_c_0_rd_addr),
  .wr_en(mem_c_0_add_1_wr_en),
  .q(mem_c_0_add_1_dout)
  );

// memory storing c_1_add_0 result
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_c_1_add_0 (  
  .clock(clk),
  .data(mem_c_1_add_0_din),
  .address(mem_c_1_add_0_wr_en ? mem_c_1_add_0_wr_addr : (mem_c_1_add_0_rd_en ? mem_c_1_add_0_rd_addr : mem_c_1_rd_addr)),
  .wr_en(mem_c_1_add_0_wr_en),
  .q(mem_c_1_add_0_dout)
  );

// memory storing c_1_add_1 result
single_port_mem #(.WIDTH(RADIX), .DEPTH(DIGITS)) single_port_mem_inst_c_1_add_1 (  
  .clock(clk),
  .data(mem_c_1_add_1_din),
  .address(mem_c_1_add_1_wr_en ? mem_c_1_add_1_wr_addr : mem_c_1_rd_addr),
  .wr_en(mem_c_1_add_1_wr_en),
  .q(mem_c_1_add_1_dout)
  );

delay #(.WIDTH(1), .DELAY(3)) delay_inst_adder_1_start (
  .clk(clk),
  .rst(rst),
  .din(left_adder_done & (add_counter == 1'b0) & (cmd != 3'd3)),
  .dout(adder_1_start)
  );

delay #(.WIDTH(DIGITS_LOG), .DELAY(1)) delay_inst_mem_c_0_wr_addr (
  .clk(clk),
  .rst(rst),
  .din(rd_counter_buf),
  .dout(mem_c_0_wr_addr)
  );

endmodule

