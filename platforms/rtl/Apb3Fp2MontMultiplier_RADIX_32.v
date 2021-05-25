/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      APB bridge module for the F(p^2) multiplier
 * 
*/
 
// RADIX = 32 = width of bus

module Apb3Fp2MontMultiplier
	#(
  // size of one digit
  // w = 8/16/32/64/128, etc
  parameter RADIX = 32,
  // number of digits
  // WIDTH has to be a multiple of 2
  parameter WIDTH_REAL = 4,
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
  parameter RES_MEM_DEPTH_LOG = `CLOG2(RES_MEM_DEPTH),
  parameter MULT_FILE_CONST = "mem_p_plus_one.mem",
  parameter P2_FILE_CONST = "px2.mem"
    )
  (
    input wire io_mainClk,
    input wire io_systemReset,

    input wire [0:0] io_apb_PSEL,
    input wire io_apb_PENABLE,
    output wire io_apb_PREADY,
    input wire io_apb_PWRITE,
    output wire io_apb_PSLVERROR, 
    input wire [7:0] io_apb_PADDR,
    input wire signed [31:0] io_apb_PWDATA,
    output reg signed [31:0] io_apb_PRDATA 
    );

// APB signals
wire ctrl_doWrite; 
wire ctrl_doRead;
assign ctrl_doWrite = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && io_apb_PWRITE);
assign ctrl_doRead = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && (! io_apb_PWRITE)); 
assign io_apb_PREADY = 1'b1;
assign io_apb_PSLVERROR = 1'b0;

// memory interface
  // a0, a1, b0, b1, c1 share the same registers for writing interface
reg mem_wr_en;
reg [INPUT_MEM_DEPTH_LOG-1:0] mem_wr_addr;
reg [INPUT_MEM_WIDTH-1:0] mem_din;

  // reading sub and add parts' results share the same set of registers
reg [RES_MEM_DEPTH_LOG-1:0] mult_rd_addr;

// inputs of the multiplier
reg mult_start;
reg mult_rst; 

// outputs of the multiplier
wire done;
wire busy;

// interface with the memories
reg mem_a_0_wr_en;
wire mem_a_0_rd_en; 
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_a_0_rd_addr; 
wire [INPUT_MEM_WIDTH-1:0] mem_a_0_dout;

reg mem_a_1_wr_en;
wire mem_a_1_rd_en; 
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_a_1_rd_addr; 
wire [INPUT_MEM_WIDTH-1:0] mem_a_1_dout;

reg mem_b_0_wr_en;
wire mem_b_0_rd_en; 
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_b_0_rd_addr; 
wire [INPUT_MEM_WIDTH-1:0] mem_b_0_dout;

reg mem_b_1_wr_en;
wire mem_b_1_rd_en; 
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_b_1_rd_addr; 
wire [INPUT_MEM_WIDTH-1:0] mem_b_1_dout;

reg mem_c_1_wr_en;
wire mem_c_1_rd_en; 
wire [INPUT_MEM_DEPTH_LOG-1:0] mem_c_1_rd_addr; 
wire [INPUT_MEM_WIDTH-1:0] mem_c_1_dout; 

reg px2_mem_wr_en;
wire px2_mem_rd_en; 
wire [INPUT_MEM_DEPTH_LOG-1:0] px2_mem_rd_addr; 
wire [INPUT_MEM_WIDTH-1:0] px2_mem_dout;

reg sub_mult_mem_res_rd_en; 
wire [RES_MEM_WIDTH-1:0] sub_mult_mem_res_dout; 

reg add_mult_mem_res_rd_en; 
wire [RES_MEM_WIDTH-1:0] add_mult_mem_res_dout; 
 
always @ (posedge io_mainClk or posedge io_systemReset) begin
    if (io_systemReset) begin 
      mult_start <= 1'b0;
      mult_rst <= 1'b0;
      mem_a_0_wr_en <= 1'b0;  
      mem_a_1_wr_en <= 1'b0;  
      mem_b_0_wr_en <= 1'b0;  
      mem_b_1_wr_en <= 1'b0;  
      mem_c_1_wr_en <= 1'b0; 
      px2_mem_wr_en <= 1'b0; 
      mem_wr_en <= 1'b0;
      mem_din <= {INPUT_MEM_WIDTH{1'b0}};
      mem_wr_addr <= {INPUT_MEM_DEPTH_LOG{1'b0}};
    end else begin
      mult_start <= 1'b0;
      mult_rst <= 1'b0;
      mem_a_0_wr_en <= 1'b0;
      mem_a_1_wr_en <= 1'b0;
      mem_b_0_wr_en <= 1'b0;
      mem_b_1_wr_en <= 1'b0;
      mem_c_1_wr_en <= 1'b0;
      px2_mem_wr_en <= 1'b0;
      mem_wr_en <= 1'b0;
      mem_din <= io_apb_PWDATA;
      mem_wr_addr <= mem_wr_en & (mem_wr_addr == (INPUT_MEM_DEPTH-1)) ? {INPUT_MEM_DEPTH_LOG{1'b0}} :
                     mem_wr_en ? mem_wr_addr + 1 :
                     mem_wr_addr; 
 

      case(io_apb_PADDR)
        7'b0000000 : begin
          // do nothing
        end

        // set reset signal
        // start the computation
        7'b0000100 : begin
          if(ctrl_doWrite) begin 
            mult_rst <= io_apb_PWDATA[2];
            mult_start <= io_apb_PWDATA[3];
          end
        end

        // transfer a_0
        7'b0001000 : begin
          if(ctrl_doWrite) begin
            mem_a_0_wr_en <= 1'b1;
            mem_wr_en <= 1'b1;
          end
        end

        7'b0001100 : begin
          if(ctrl_doWrite) begin
            mem_a_1_wr_en <= 1'b1;
            mem_wr_en <= 1'b1;
          end
        end

        7'b0010000 : begin
          if(ctrl_doWrite) begin
            mem_b_0_wr_en <= 1'b1;
            mem_wr_en <= 1'b1;
          end
        end

        7'b0010100 : begin
          if(ctrl_doWrite) begin
            mem_b_1_wr_en <= 1'b1;
            mem_wr_en <= 1'b1;
          end
        end
 

        default : begin
        end
      endcase  
    end
end 

always @ (posedge io_mainClk or posedge io_systemReset) begin
    if (io_systemReset) begin 
      mult_rd_addr <= {RES_MEM_DEPTH_LOG{1'b0}};
    end else begin
      mult_rd_addr <= (sub_mult_mem_res_rd_en | add_mult_mem_res_rd_en) & (mult_rd_addr == (RES_MEM_DEPTH-1)) ? {RES_MEM_DEPTH_LOG{1'b0}} :
                      (sub_mult_mem_res_rd_en | add_mult_mem_res_rd_en) ? mult_rd_addr + 1 :
                      mult_rd_addr;
    end
  end
  

  always @ (*) begin
    io_apb_PRDATA = (32'b00000000000000000000000000000000);
    sub_mult_mem_res_rd_en = 1'b0;  
    add_mult_mem_res_rd_en = 1'b0;
    case(io_apb_PADDR)
      7'b0000000 : begin
          // do nothing
        end
      
      // check if the computation is finished
      7'b0000100: begin 
        if (ctrl_doRead) begin
          io_apb_PRDATA = {{31{1'b0}}, busy}; 
        end
      end

      // return the sub result
      7'd1110000: begin
        if (ctrl_doRead) begin
          io_apb_PRDATA = sub_mult_mem_res_dout[RES_MEM_WIDTH-1:RADIX]; // t[2*i]
        end
      end

      7'd1110100: begin
        if (ctrl_doRead) begin
          io_apb_PRDATA = sub_mult_mem_res_dout[RADIX-1:0]; // t[2*i+1]
          sub_mult_mem_res_rd_en = 1'b1;
        end
      end

      // return the add result
      7'd1111000: begin
        if (ctrl_doRead) begin
          io_apb_PRDATA = add_mult_mem_res_dout[RES_MEM_WIDTH-1:RADIX]; // t[2*i] 
        end
      end

      7'd1111100: begin
        if (ctrl_doRead) begin
          io_apb_PRDATA = add_mult_mem_res_dout[RADIX-1:0]; // t[2*i+1] 
          add_mult_mem_res_rd_en = 1'b1;
        end
      end
     
     default : begin
        end
     endcase
  end


fp2_mont_mul #(.RADIX(RADIX), .WIDTH_REAL(INPUT_MEM_DEPTH)) DUT (
  .rst(mult_rst),
  .clk(io_mainClk),
  .start(mult_start),
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
  .sub_mult_mem_res_rd_addr(mult_rd_addr),
  .sub_mult_mem_res_dout(sub_mult_mem_res_dout),
  .add_mult_mem_res_rd_en(add_mult_mem_res_rd_en),
  .add_mult_mem_res_rd_addr(mult_rd_addr),
  .add_mult_mem_res_dout(add_mult_mem_res_dout),
  .px2_mem_rd_en(px2_mem_rd_en),
  .px2_mem_rd_addr(px2_mem_rd_addr),
  .px2_mem_dout(px2_mem_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(WIDTH_REAL), .FILE(P2_FILE_CONST)) single_port_mem_inst_px2 (  
  .clock(io_mainClk),
  .data(mem_din),
  .address(px2_mem_wr_en ? mem_wr_addr : px2_mem_rd_addr),
  .wr_en(px2_mem_wr_en),
  .q(px2_mem_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_a_0 (
  .clock(io_mainClk),
  .data(mem_din),
  .address(mem_a_0_wr_en ? mem_wr_addr : mem_a_0_rd_addr),
  .wr_en(mem_a_0_wr_en),
  .q(mem_a_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_a_1 (
  .clock(io_mainClk),
  .data(mem_din), 
  .address(mem_a_1_wr_en ? mem_wr_addr : (mem_a_1_rd_en ? mem_a_1_rd_addr : 0)),
  .wr_en(mem_a_1_wr_en),
  .q(mem_a_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_b_0 (
  .clock(io_mainClk),
  .data(mem_din),
  .address(mem_b_0_wr_en ? mem_wr_addr : (mem_b_0_rd_en ? mem_b_0_rd_addr : 0)),
  .wr_en(mem_b_0_wr_en),
  .q(mem_b_0_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(INPUT_MEM_DEPTH)) single_port_mem_inst_b_1 (
  .clock(io_mainClk),
  .data(mem_din),
  .address(mem_b_1_wr_en ? mem_wr_addr : mem_b_1_rd_addr),
  .wr_en(mem_b_1_wr_en),
  .q(mem_b_1_dout)
  );

single_port_mem #(.WIDTH(RADIX), .DEPTH(INPUT_MEM_DEPTH), .FILE(MULT_FILE_CONST)) single_port_mem_inst_c_1 (
  .clock(io_mainClk),
  .data(mem_din),
  .address(mem_c_1_wr_en ? mem_wr_addr : mem_c_1_rd_addr),
  .wr_en(mem_c_1_wr_en),
  .q(mem_c_1_dout)
  );

endmodule