/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      APB bridge module for the top_controller module, also supports interaction with the F(p^2) multiplier
 * 
*/

// RADIX = 32 = width of BUS 

module Apb3Controller
  #(
  // encoded commands
  parameter XDBLE_COMMAND = 1,                                       // 1
  parameter GET_4_ISOG_AND_EVAL_4_ISOG_COMMAND = XDBLE_COMMAND + 1,  // 2
  parameter GET_4_ISOG_COMMAND = GET_4_ISOG_AND_EVAL_4_ISOG_COMMAND, // 2
  parameter EVAL_4_ISOG_COMMAND = GET_4_ISOG_COMMAND + 1,            // 3
  parameter XADD_LOOP_COMMAND = EVAL_4_ISOG_COMMAND + 1,          // 4
  // encoded sub-functions
  parameter XDBL_FUNCTION = 1,
  parameter GET_4_ISOG_FUNCTION = XDBL_FUNCTION + 1,
  parameter XADD_FUNCTION = GET_4_ISOG_FUNCTION + 1,
  parameter EVAL_4_ISOG_FUNCTION = XADD_FUNCTION + 1,
  // fixed as 32 in this case = width of APB bus
  parameter RADIX = 32,
  // number of digits 
  parameter WIDTH_REAL = 4,
  // configuration of the secret key (input m of xADD loop)
  parameter SK_MEM_WIDTH = 32,
  parameter SK_MEM_WIDTH_LOG = `CLOG2(SK_MEM_WIDTH),
  parameter SK_MEM_DEPTH = 32 ,
  parameter SK_MEM_DEPTH_LOG = `CLOG2(SK_MEM_DEPTH),
  // others
  parameter SINGLE_MEM_WIDTH = RADIX,
  parameter SINGLE_MEM_DEPTH = WIDTH_REAL,
  parameter SINGLE_MEM_DEPTH_LOG = `CLOG2(SINGLE_MEM_DEPTH),
  parameter DOUBLE_MEM_WIDTH = RADIX*2,
  parameter DOUBLE_MEM_DEPTH = (WIDTH_REAL+1)/2,
  parameter DOUBLE_MEM_DEPTH_LOG = `CLOG2(DOUBLE_MEM_DEPTH),
  // constant memories
  // p+1
  parameter FILE_CONST_P_PLUS_ONE = "mem_p_plus_one.mem",
  // 2*p
  parameter FILE_CONST_PX2 = "px2.mem",
  // 4*p
  parameter FILE_CONST_PX4 = "px4.mem",
  // pre-loaded secret key (Alice/Bob)
  parameter FILE_SK = "sk.mem"

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

wire ctrl_doWrite; 
wire ctrl_doRead;
assign ctrl_doWrite = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && io_apb_PWRITE);
assign ctrl_doRead = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && (! io_apb_PWRITE)); 
assign io_apb_PREADY = 1'b1;
assign io_apb_PSLVERROR = 1'b0;

// sw -> hw, memory write
// commonly used memory interface
reg mem_wr_en;
reg [SK_MEM_DEPTH_LOG-1:0] mem_wr_addr;
reg [SINGLE_MEM_WIDTH-1:0] mem_din; 
reg mem_rd_en;
reg [SINGLE_MEM_DEPTH_LOG-1:0] mem_rd_addr;
// separate wr_en signals for each memory piece
  // input for xDBLe
reg mem_X_0_wr_en;
reg mem_X_1_wr_en;
reg mem_Z_0_wr_en;
reg mem_Z_1_wr_en;
reg mem_X_0_rd_en;
reg mem_X_1_rd_en;
reg mem_Z_0_rd_en;
reg mem_Z_1_rd_en;
  // input for get/eval_4_isog
reg mem_X4_0_wr_en;
reg mem_X4_1_wr_en;
reg mem_Z4_0_wr_en;
reg mem_Z4_1_wr_en; 
reg mem_t10_0_rd_en;
reg mem_t10_1_rd_en;
reg mem_t11_0_rd_en;
reg mem_t11_1_rd_en;
  // input for xADD loop
reg mem_XP_0_wr_en;
reg mem_XP_1_wr_en;
reg mem_ZP_0_wr_en;
reg mem_ZP_1_wr_en; 
reg mem_XQ_0_wr_en;
reg mem_XQ_1_wr_en;
reg mem_ZQ_0_wr_en;
reg mem_ZQ_1_wr_en;
reg mem_xPQ_0_wr_en;
reg mem_xPQ_1_wr_en;
reg mem_zPQ_0_wr_en;
reg mem_zPQ_1_wr_en;
reg mem_XP_0_rd_en;
reg mem_XP_1_rd_en;
reg mem_ZP_0_rd_en;
reg mem_ZP_1_rd_en; 
reg mem_XQ_0_rd_en;
reg mem_XQ_1_rd_en;
reg mem_ZQ_0_rd_en;
reg mem_ZQ_1_rd_en;
reg mem_xPQ_0_rd_en;
reg mem_xPQ_1_rd_en;
reg mem_zPQ_0_rd_en;
reg mem_zPQ_1_rd_en;
  // constants A24 and C24
reg mem_A24_0_wr_en;
reg mem_A24_1_wr_en;
reg mem_C24_0_wr_en;
reg mem_C24_1_wr_en;
reg mem_A24_0_rd_en;
reg mem_A24_1_rd_en;
reg mem_C24_0_rd_en;
reg mem_C24_1_rd_en;
  // secret key memory
reg sk_mem_wr_en;

wire top_controller_xDBL_and_xADD_busy;

// memory dout
wire [SINGLE_MEM_WIDTH-1:0] mem_X_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_X_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_Z_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_t10_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_t11_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_t11_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_XP_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_XP_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZP_1_dout; 
wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_XQ_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_ZQ_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_xPQ_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_zPQ_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_A24_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_A24_1_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_C24_0_dout;
wire [SINGLE_MEM_WIDTH-1:0] mem_C24_1_dout;


// interface to top_controller
reg top_controller_start;
reg top_controller_rst;
wire top_controller_get_4_isog_busy;
wire top_controller_busy;
wire top_controller_done;
reg [7:0] command_encoded;
reg [15:0] xDBLe_NUM_LOOPS;
reg [15:0] xADD_loop_start_index;
reg [15:0] xADD_loop_end_index;

reg eval_4_isog_XZ_newly_init;
wire eval_4_isog_XZ_can_overwrite;
wire last_eval_4_isog;
wire eval_4_isog_result_ready;
reg eval_4_isog_result_can_overwrite;

assign last_eval_4_isog = 1'b0;

reg xADD_P_newly_loaded;
wire xADD_P_can_overwrite;

//---------------------------------------------------------------------
    // logic for get_4_isog and eval_4_isog
//---------------------------------------------------------------------
// 2-phase handshake signals with eval_4_isog
reg eval_4_isog_XZ_newly_init_pre;
reg eval_4_isog_XZ_newly_init_pre_buf;
reg eval_4_isog_result_can_overwrite_pre;
reg eval_4_isog_result_can_overwrite_pre_buf;

reg xADD_P_newly_loaded_pre;
reg xADD_P_newly_loaded_pre_buf;

// logic for mult A
reg out_mult_A_rst;
reg out_mult_A_start;
wire mult_A_busy;
wire mult_A_done;
 
  // reading sub and add parts' results share the same set of registers
reg [DOUBLE_MEM_DEPTH_LOG-1:0] mult_A_res_rd_addr;

reg out_mult_A_mem_a_0_wr_en; 
reg out_mult_A_mem_a_1_wr_en; 

reg out_mult_A_mem_b_0_wr_en; 
reg out_mult_A_mem_b_1_wr_en; 

reg out_sub_mult_A_mem_res_rd_en;
wire [DOUBLE_MEM_WIDTH-1:0] sub_mult_A_mem_res_dout;
reg out_add_mult_A_mem_res_rd_en;
wire [DOUBLE_MEM_WIDTH-1:0] add_mult_A_mem_res_dout;


always @ (posedge io_mainClk or posedge io_systemReset) begin
  if (io_systemReset) begin
    eval_4_isog_XZ_newly_init_pre_buf <= 1'b0;
    eval_4_isog_result_can_overwrite_pre_buf <= 1'b0;

    eval_4_isog_XZ_newly_init <= 1'b0;
    eval_4_isog_result_can_overwrite <= 1'b1;

    xADD_P_newly_loaded_pre_buf <= 1'b0;
  end
  else begin
    eval_4_isog_XZ_newly_init_pre_buf <= eval_4_isog_XZ_newly_init_pre;
    eval_4_isog_result_can_overwrite_pre_buf <= eval_4_isog_result_can_overwrite_pre;

    eval_4_isog_XZ_newly_init <= eval_4_isog_XZ_newly_init_pre | eval_4_isog_XZ_newly_init_pre_buf ? 1'b1 : 
                                 eval_4_isog_XZ_can_overwrite ? 1'b0 :
                                 eval_4_isog_XZ_newly_init;

    eval_4_isog_result_can_overwrite <= eval_4_isog_result_can_overwrite_pre | eval_4_isog_result_can_overwrite_pre_buf ? 1'b1 :
                                        eval_4_isog_result_ready ? 1'b0 :
                                        eval_4_isog_result_can_overwrite;

    xADD_P_newly_loaded_pre_buf <= xADD_P_newly_loaded_pre;

    xADD_P_newly_loaded <= xADD_P_newly_loaded_pre | xADD_P_newly_loaded_pre_buf ? 1'b1 :
                           xADD_P_can_overwrite ? 1'b0 :
                           xADD_P_newly_loaded;    
  end  
end
//---------------------------------------------------------------------


// sw writes to hw
always @ (posedge io_mainClk or posedge io_systemReset) begin
  if (io_systemReset) begin 
    top_controller_start <= 1'b0;
    top_controller_rst <= 1'b0; 
    //
    out_mult_A_start <= 1'b0;
    out_mult_A_rst <= 1'b0;
    out_mult_A_mem_a_0_wr_en <= 1'b0;
    out_mult_A_mem_a_1_wr_en <= 1'b0;
    out_mult_A_mem_b_0_wr_en <= 1'b0;
    out_mult_A_mem_b_1_wr_en <= 1'b0;
    //
    mem_X_0_wr_en <= 1'b0;
    mem_X_1_wr_en <= 1'b0;
    mem_Z_0_wr_en <= 1'b0;
    mem_Z_1_wr_en <= 1'b0;
    mem_X4_0_wr_en <= 1'b0;
    mem_X4_1_wr_en <= 1'b0;
    mem_Z4_0_wr_en <= 1'b0;
    mem_Z4_1_wr_en <= 1'b0;
    mem_XP_0_wr_en <= 1'b0;
    mem_XP_1_wr_en <= 1'b0;
    mem_ZP_0_wr_en <= 1'b0;
    mem_ZP_1_wr_en <= 1'b0; 
    mem_XQ_0_wr_en <= 1'b0;
    mem_XQ_1_wr_en <= 1'b0;
    mem_ZQ_0_wr_en <= 1'b0;
    mem_ZQ_1_wr_en <= 1'b0;
    mem_xPQ_0_wr_en <= 1'b0;
    mem_xPQ_1_wr_en <= 1'b0;
    mem_zPQ_0_wr_en <= 1'b0;
    mem_zPQ_1_wr_en <= 1'b0;
    mem_A24_0_wr_en <= 1'b0;
    mem_A24_1_wr_en <= 1'b0;
    mem_C24_0_wr_en <= 1'b0;
    mem_C24_1_wr_en <= 1'b0;
    sk_mem_wr_en <= 1'b0; 
    //
    mem_wr_en <= 1'b0;
    mem_din <= {SINGLE_MEM_WIDTH{1'b0}};
    mem_wr_addr <= {SK_MEM_DEPTH_LOG{1'b0}};
    //
    xDBLe_NUM_LOOPS <= 16'd0;
    xADD_loop_start_index <= 16'd0;
    xADD_loop_end_index <= 16'd0;
    // 
    eval_4_isog_XZ_newly_init_pre <= 1'b0;
    xADD_P_newly_loaded_pre <= 1'b0;
    //
    command_encoded <= 8'd0;
  end 
  else begin
    top_controller_start <= 1'b0;
    top_controller_rst <= 1'b0;
    //
    out_mult_A_start <= 1'b0;
    out_mult_A_rst <= 1'b0;
    out_mult_A_mem_a_0_wr_en <= 1'b0;
    out_mult_A_mem_a_1_wr_en <= 1'b0;
    out_mult_A_mem_b_0_wr_en <= 1'b0;
    out_mult_A_mem_b_1_wr_en <= 1'b0;
    //
    mem_X_0_wr_en <= 1'b0;
    mem_X_1_wr_en <= 1'b0;
    mem_Z_0_wr_en <= 1'b0;
    mem_Z_1_wr_en <= 1'b0;
    mem_X4_0_wr_en <= 1'b0;
    mem_X4_1_wr_en <= 1'b0;
    mem_Z4_0_wr_en <= 1'b0;
    mem_Z4_1_wr_en <= 1'b0;
    mem_XP_0_wr_en <= 1'b0;
    mem_XP_1_wr_en <= 1'b0;
    mem_ZP_0_wr_en <= 1'b0;
    mem_ZP_1_wr_en <= 1'b0; 
    mem_XQ_0_wr_en <= 1'b0;
    mem_XQ_1_wr_en <= 1'b0;
    mem_ZQ_0_wr_en <= 1'b0;
    mem_ZQ_1_wr_en <= 1'b0;
    mem_xPQ_0_wr_en <= 1'b0;
    mem_xPQ_1_wr_en <= 1'b0;
    mem_zPQ_0_wr_en <= 1'b0;
    mem_zPQ_1_wr_en <= 1'b0;
    mem_A24_0_wr_en <= 1'b0;
    mem_A24_1_wr_en <= 1'b0;
    mem_C24_0_wr_en <= 1'b0;
    mem_C24_1_wr_en <= 1'b0;
    sk_mem_wr_en <= 1'b0;
    //
    mem_wr_en <= 1'b0;
    mem_din <= io_apb_PWDATA;
    mem_wr_addr <= (top_controller_rst | (mem_wr_en & (mem_wr_addr == (SINGLE_MEM_DEPTH-1)))) ? {SINGLE_MEM_DEPTH_LOG{1'b0}} :
                   (mem_wr_en | sk_mem_wr_en) ? mem_wr_addr + 1 :
                   mem_wr_addr; 
    //
    eval_4_isog_XZ_newly_init_pre <= mem_Z4_1_wr_en & (mem_wr_addr == (SINGLE_MEM_DEPTH-1)) & (command_encoded == EVAL_4_ISOG_COMMAND);
    xADD_P_newly_loaded_pre <= mem_ZP_1_wr_en & (mem_wr_addr == (SINGLE_MEM_DEPTH-1)) & (command_encoded == XADD_LOOP_COMMAND);
    //
    case(io_apb_PADDR)
      7'b0000000 : begin
        // do nothing
      end

      // set reset signal
      // start the computation
      // send command NOTE: command should come before start signal
      7'b0000100 : begin
        if(ctrl_doWrite) begin 
          top_controller_rst <= io_apb_PWDATA[0];
          command_encoded <= io_apb_PWDATA[15:8];
          top_controller_start <= io_apb_PWDATA[1];
          out_mult_A_rst <= io_apb_PWDATA[2];
          out_mult_A_start <= io_apb_PWDATA[3];          
        end
      end
 

      // transfer xDBLe_NUM_LOOPS
      7'b0001000 : begin
        if(ctrl_doWrite) begin
          xDBLe_NUM_LOOPS <= io_apb_PWDATA[15:0];
        end
      end
      
      // transfer xADD loop start and end indices
      7'b0001100 : begin
        if(ctrl_doWrite) begin
          xADD_loop_start_index <= io_apb_PWDATA[15:0];
          xADD_loop_end_index <= io_apb_PWDATA[31:16];
        end
      end

      7'b0010000 : begin
        if(ctrl_doWrite) begin
          mem_X_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
          out_mult_A_mem_a_0_wr_en <= 1'b1;
        end
      end

      7'b0010100 : begin
        if(ctrl_doWrite) begin
          mem_X_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
          out_mult_A_mem_a_1_wr_en <= 1'b1;
        end
      end 

      7'b0011000 : begin
        if (ctrl_doWrite) begin
          mem_Z_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;  
          out_mult_A_mem_b_0_wr_en <= 1'b1;       
        end
      end

      7'b0011100 : begin
        if (ctrl_doWrite) begin
          mem_Z_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
          out_mult_A_mem_b_1_wr_en <= 1'b1;
        end
      end
      
      7'b0100000 : begin
        if (ctrl_doWrite) begin
          mem_A24_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0100100 : begin
        if (ctrl_doWrite) begin
          mem_A24_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0101000 : begin
        if (ctrl_doWrite) begin
          mem_C24_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0101100 : begin
        if (ctrl_doWrite) begin
          mem_C24_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0110000 : begin
        if (ctrl_doWrite) begin
          mem_XP_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0110100 : begin
        if (ctrl_doWrite) begin
          mem_XP_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0111000 : begin
        if (ctrl_doWrite) begin
          mem_ZP_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b0111100 : begin
        if (ctrl_doWrite) begin
          mem_ZP_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1000000 : begin
        if (ctrl_doWrite) begin
          mem_XQ_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1000100 : begin
        if (ctrl_doWrite) begin
          mem_XQ_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1001000 : begin
        if (ctrl_doWrite) begin
          mem_ZQ_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
       
      7'b1001100 : begin
        if (ctrl_doWrite) begin
          mem_ZQ_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end

      7'b1010000 : begin
        if (ctrl_doWrite) begin
          mem_xPQ_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1010100 : begin
        if (ctrl_doWrite) begin
          mem_xPQ_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1011000 : begin
        if (ctrl_doWrite) begin
          mem_zPQ_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1011100 : begin
        if (ctrl_doWrite) begin
          mem_zPQ_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1100000 : begin
        if (ctrl_doWrite) begin
          mem_X4_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end

      7'b1100100 : begin
        if (ctrl_doWrite) begin
          mem_X4_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1101000 : begin
        if (ctrl_doWrite) begin
          mem_Z4_0_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end
      
      7'b1101100 : begin
        if (ctrl_doWrite) begin
          mem_Z4_1_wr_en <= 1'b1;
          mem_wr_en <= 1'b1;
        end
      end

      7'b1110000: begin
        if (ctrl_doWrite) begin
          sk_mem_wr_en <= 1'b1;
          // mem_wr_en <= 1'b1;
        end
      end  
      
      default : begin
      end
    endcase  
  end
end 
 
// sw reads from hw
always @ (posedge io_mainClk or posedge io_systemReset) begin
    if (io_systemReset) begin 
      mem_rd_addr <= {SINGLE_MEM_DEPTH_LOG{1'b0}};
      eval_4_isog_result_can_overwrite_pre <= 1'b0;
      mult_A_res_rd_addr <= {DOUBLE_MEM_DEPTH_LOG{1'b0}};
      mem_X_0_rd_en <= 1'b0;
      mem_X_1_rd_en <= 1'b0;
      mem_Z_0_rd_en <= 1'b0;
      mem_Z_1_rd_en <= 1'b0; 
      mem_XP_0_rd_en <= 1'b0;
      mem_XP_1_rd_en <= 1'b0;
      mem_ZP_0_rd_en <= 1'b0;
      mem_ZP_1_rd_en <= 1'b0; 
      mem_XQ_0_rd_en <= 1'b0;
      mem_XQ_1_rd_en <= 1'b0;
      mem_ZQ_0_rd_en <= 1'b0;
      mem_ZQ_1_rd_en <= 1'b0;
      mem_xPQ_0_rd_en <= 1'b0;
      mem_xPQ_1_rd_en <= 1'b0;
      mem_zPQ_0_rd_en <= 1'b0;
      mem_zPQ_1_rd_en <= 1'b0;
      mem_A24_0_rd_en <= 1'b0;
      mem_A24_1_rd_en <= 1'b0;
      mem_C24_0_rd_en <= 1'b0;
      mem_C24_1_rd_en <= 1'b0;
    end 
    else begin
      mult_A_res_rd_addr <= (out_sub_mult_A_mem_res_rd_en | out_add_mult_A_mem_res_rd_en) & (mult_A_res_rd_addr == (DOUBLE_MEM_DEPTH-1)) ? {DOUBLE_MEM_DEPTH_LOG{1'b0}} :
                            (out_sub_mult_A_mem_res_rd_en | out_add_mult_A_mem_res_rd_en) ? mult_A_res_rd_addr + 1 :
                            mult_A_res_rd_addr;

      mem_rd_addr <= mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? {SINGLE_MEM_DEPTH_LOG{1'b0}} :
                     mem_rd_en ? mem_rd_addr + 1 :
                     mem_rd_addr;
      
      eval_4_isog_result_can_overwrite_pre <= mem_t11_1_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 :
                                              eval_4_isog_result_can_overwrite_pre ? 1'b0 :
                                              eval_4_isog_result_can_overwrite_pre;

      mem_X_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0000100) & (io_apb_PRDATA[0] == 1'b0) & (command_encoded == 8'd1) ? 1'b1 : 
                       (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                       mem_X_0_rd_en;
      mem_X_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0010000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                       (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                       mem_X_1_rd_en;
      mem_Z_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0010100) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                       (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                       mem_Z_0_rd_en;
      mem_Z_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0011000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                       (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                       mem_Z_1_rd_en;

      mem_A24_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0001000) & (top_controller_get_4_isog_busy == 1'b0) & (command_encoded == 8'd2) ? 1'b1 : 
                         (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                         mem_A24_0_rd_en;
      mem_A24_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0100000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                         (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         mem_A24_1_rd_en;
      mem_C24_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0100100) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                         (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         mem_C24_0_rd_en;
      mem_C24_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0101000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                         (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         mem_C24_1_rd_en;
 

      mem_XQ_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b0000100) & (io_apb_PRDATA[0] == 1'b0) & (command_encoded == 8'd4) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_XQ_0_rd_en;
      mem_XQ_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1000000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_XQ_1_rd_en;
      mem_ZQ_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1000100) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_ZQ_0_rd_en;
      mem_ZQ_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1001000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_ZQ_1_rd_en;
      mem_xPQ_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1001100) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_xPQ_0_rd_en;
      mem_xPQ_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1010000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_xPQ_1_rd_en;
      mem_zPQ_0_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1010100) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_zPQ_0_rd_en;
      mem_zPQ_1_rd_en <= ctrl_doRead & (io_apb_PADDR == 7'b1011000) & (mem_rd_addr == (SINGLE_MEM_DEPTH-1)) ? 1'b1 : 
                        (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 : 
                        mem_zPQ_1_rd_en;
                        
      mem_t10_0_rd_en <= (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         ctrl_doRead & (io_apb_PADDR == 7'b1100000) ? 1'b1 : 
                         mem_t10_0_rd_en;
      mem_t10_1_rd_en <= (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         ctrl_doRead & (io_apb_PADDR == 7'b1100100) ? 1'b1 : 
                         mem_t10_1_rd_en;
      mem_t11_0_rd_en <= (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         ctrl_doRead & (io_apb_PADDR == 7'b1101000) ? 1'b1 : 
                         mem_t11_0_rd_en;
      mem_t11_1_rd_en <= (ctrl_doRead & (io_apb_PADDR == 7'b0000100)) | (mem_rd_en & (mem_rd_addr == (SINGLE_MEM_DEPTH-1))) ? 1'b0 :
                         ctrl_doRead & (io_apb_PADDR == 7'b1101100) ? 1'b1 : 
                         mem_t11_1_rd_en;
  end
end
  

always @ (*) begin
  io_apb_PRDATA = (32'b00000000000000000000000000000000);
  mem_rd_en = 1'b0;
  out_sub_mult_A_mem_res_rd_en = 1'b0;
  out_add_mult_A_mem_res_rd_en = 1'b0;

  case(io_apb_PADDR)
    7'b0000000 : begin
        // do nothing
      end
    
    // check if the computation is finished
    7'b0000100 : begin 
      if (ctrl_doRead) begin
        io_apb_PRDATA = {{16{1'b0}}, {7'b0, xADD_P_can_overwrite}, {7'b0, (top_controller_xDBL_and_xADD_busy | mult_A_busy)}}; 
      end
    end

    7'b0001000: begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = {8'd0, {7'd0, eval_4_isog_result_ready}, {7'd0, eval_4_isog_XZ_can_overwrite}, {7'd0, top_controller_get_4_isog_busy}}; 
      end
    end
 
 
    7'b0010000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_X_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0010100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_X_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0011000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_Z_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0011100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_Z_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0100000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_A24_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0100100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_A24_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0101000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_C24_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0101100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_C24_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0110000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_XP_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0110100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_XP_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0111000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_ZP_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b0111100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_ZP_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1000000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_XQ_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1000100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_XQ_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1001000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_ZQ_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1001100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_ZQ_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1010000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_xPQ_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1010100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_xPQ_1_dout;
        mem_rd_en = 1'b1;
      end
    end 

    7'b1011000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_zPQ_0_dout;
        // io_apb_PRDATA = 32'hdeadbeef;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1011100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_zPQ_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1100000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_t10_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1100100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_t10_1_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1101000 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_t11_0_dout;
        mem_rd_en = 1'b1;
      end
    end
    
    7'b1101100 : begin
      if (ctrl_doRead) begin 
        io_apb_PRDATA = mem_t11_1_dout;
        mem_rd_en = 1'b1;
      end
    end    

    7'd1110000: begin
      if (ctrl_doRead) begin
        io_apb_PRDATA = sub_mult_A_mem_res_dout[DOUBLE_MEM_WIDTH-1:SINGLE_MEM_WIDTH]; // t[2*i]
      end
    end

    7'd116: begin
      if (ctrl_doRead) begin
        io_apb_PRDATA = sub_mult_A_mem_res_dout[SINGLE_MEM_WIDTH-1:0]; // t[2*i]
        out_sub_mult_A_mem_res_rd_en = 1'b1;
      end
    end

    7'd120: begin
      if (ctrl_doRead) begin
        io_apb_PRDATA = add_mult_A_mem_res_dout[DOUBLE_MEM_WIDTH-1:SINGLE_MEM_WIDTH]; // t[2*i]
      end
    end

    7'd124: begin
      if (ctrl_doRead) begin
        io_apb_PRDATA = add_mult_A_mem_res_dout[SINGLE_MEM_WIDTH-1:0]; // t[2*i]
        out_add_mult_A_mem_res_rd_en = 1'b1;
      end
    end

   default : begin
      end
      
  endcase
end


top_controller #(.XDBLE_COMMAND(XDBLE_COMMAND), .GET_4_ISOG_AND_EVAL_4_ISOG_COMMAND(GET_4_ISOG_AND_EVAL_4_ISOG_COMMAND), .XADD_LOOP_COMMAND(XADD_LOOP_COMMAND), .RADIX(RADIX), .WIDTH_REAL(WIDTH_REAL), .SK_MEM_WIDTH(SK_MEM_WIDTH), .SK_MEM_DEPTH(SK_MEM_DEPTH)) top_controller_inst (
  .rst(top_controller_rst),
  .clk(io_mainClk),
  .start(top_controller_start),
  .xDBL_and_xADD_busy(top_controller_xDBL_and_xADD_busy),
  .xADD_P_newly_loaded(xADD_P_newly_loaded),
  .xADD_P_can_overwrite(xADD_P_can_overwrite),
  //
  .out_mult_A_rst(out_mult_A_rst),
  .out_mult_A_start(out_mult_A_start),
  .mult_A_busy(mult_A_busy),
  .mult_A_done(mult_A_done),
  .out_mult_A_mem_a_0_wr_en(out_mult_A_mem_a_0_wr_en),
  .out_mult_A_mem_a_0_wr_addr(mem_wr_addr),
  .out_mult_A_mem_a_0_din(mem_din),
  .out_mult_A_mem_a_1_wr_en(out_mult_A_mem_a_1_wr_en),
  .out_mult_A_mem_a_1_wr_addr(mem_wr_addr),
  .out_mult_A_mem_a_1_din(mem_din),
  .out_mult_A_mem_b_0_wr_en(out_mult_A_mem_b_0_wr_en),
  .out_mult_A_mem_b_0_wr_addr(mem_wr_addr),
  .out_mult_A_mem_b_0_din(mem_din),
  .out_mult_A_mem_b_1_wr_en(out_mult_A_mem_b_1_wr_en),
  .out_mult_A_mem_b_1_wr_addr(mem_wr_addr),
  .out_mult_A_mem_b_1_din(mem_din),
  .out_sub_mult_A_mem_res_rd_en(out_sub_mult_A_mem_res_rd_en),
  .out_sub_mult_A_mem_res_rd_addr(mult_A_res_rd_addr),
  .sub_mult_A_mem_res_dout(sub_mult_A_mem_res_dout),
  .out_add_mult_A_mem_res_rd_en(out_add_mult_A_mem_res_rd_en),
  .out_add_mult_A_mem_res_rd_addr(mult_A_res_rd_addr),
  .add_mult_A_mem_res_dout(add_mult_A_mem_res_dout),
  //
  .command_encoded(command_encoded), 
  .xDBLe_NUM_LOOPS(xDBLe_NUM_LOOPS),
  .eval_4_isog_XZ_newly_init(eval_4_isog_XZ_newly_init),
  .last_eval_4_isog(last_eval_4_isog),
  .eval_4_isog_result_can_overwrite(eval_4_isog_result_can_overwrite),
  .eval_4_isog_XZ_can_overwrite(eval_4_isog_XZ_can_overwrite),
  .eval_4_isog_result_ready(eval_4_isog_result_ready),
  .xADD_loop_start_index(xADD_loop_start_index),
  .xADD_loop_end_index(xADD_loop_end_index), 
  .done(top_controller_done),
  .get_4_isog_busy(top_controller_get_4_isog_busy),
  .busy(top_controller_busy), 
  .out_mem_X_0_wr_en(mem_X_0_wr_en),
  .out_mem_X_0_wr_addr(mem_wr_addr),
  .out_mem_X_0_din(mem_din), 
  .mem_X_0_dout(mem_X_0_dout),
  .out_mem_X_0_rd_en(mem_X_0_rd_en),
  .out_mem_X_0_rd_addr(mem_rd_addr), 
  .out_mem_X_1_wr_en(mem_X_1_wr_en),
  .out_mem_X_1_wr_addr(mem_wr_addr),
  .out_mem_X_1_din(mem_din), 
  .mem_X_1_dout(mem_X_1_dout),
  .out_mem_X_1_rd_en(mem_X_1_rd_en),
  .out_mem_X_1_rd_addr(mem_rd_addr), 
  .out_mem_Z_0_wr_en(mem_Z_0_wr_en),
  .out_mem_Z_0_wr_addr(mem_wr_addr),
  .out_mem_Z_0_din(mem_din), 
  .mem_Z_0_dout(mem_Z_0_dout),
  .out_mem_Z_0_rd_en(mem_Z_0_rd_en),
  .out_mem_Z_0_rd_addr(mem_rd_addr), 
  .out_mem_Z_1_wr_en(mem_Z_1_wr_en),
  .out_mem_Z_1_wr_addr(mem_wr_addr),
  .out_mem_Z_1_din(mem_din), 
  .mem_Z_1_dout(mem_Z_1_dout),
  .out_mem_Z_1_rd_en(mem_Z_1_rd_en),
  .out_mem_Z_1_rd_addr(mem_rd_addr), 
  .out_mem_X4_0_wr_en(mem_X4_0_wr_en),
  .out_mem_X4_0_wr_addr(mem_wr_addr),
  .out_mem_X4_0_din(mem_din), 
  .out_mem_X4_1_wr_en(mem_X4_1_wr_en),
  .out_mem_X4_1_wr_addr(mem_wr_addr),
  .out_mem_X4_1_din(mem_din), 
  .out_mem_Z4_0_wr_en(mem_Z4_0_wr_en),
  .out_mem_Z4_0_wr_addr(mem_wr_addr),
  .out_mem_Z4_0_din(mem_din), 
  .out_mem_Z4_1_wr_en(mem_Z4_1_wr_en),
  .out_mem_Z4_1_wr_addr(mem_wr_addr),
  .out_mem_Z4_1_din(mem_din), 
  .out_mem_t10_0_rd_en(mem_t10_0_rd_en),
  .out_mem_t10_0_rd_addr(mem_rd_addr), 
  .mem_t10_0_dout(mem_t10_0_dout), 
  .out_mem_t10_1_rd_en(mem_t10_1_rd_en),
  .out_mem_t10_1_rd_addr(mem_rd_addr), 
  .mem_t10_1_dout(mem_t10_1_dout), 
  .out_mem_t11_0_rd_en(mem_t11_0_rd_en),
  .out_mem_t11_0_rd_addr(mem_rd_addr), 
  .mem_t11_0_dout(mem_t11_0_dout), 
  .out_mem_t11_1_rd_en(mem_t11_1_rd_en),
  .out_mem_t11_1_rd_addr(mem_rd_addr), 
  .mem_t11_1_dout(mem_t11_1_dout), 
  .out_mem_XP_0_wr_en(mem_XP_0_wr_en),
  .out_mem_XP_0_wr_addr(mem_wr_addr),
  .out_mem_XP_0_din(mem_din), 
  .out_mem_XP_1_wr_en(mem_XP_1_wr_en),
  .out_mem_XP_1_wr_addr(mem_wr_addr),
  .out_mem_XP_1_din(mem_din), 
  .mem_XP_0_dout(mem_XP_0_dout),
  .out_mem_XP_0_rd_en(mem_XP_0_rd_en),
  .out_mem_XP_0_rd_addr(mem_rd_addr), 
  .mem_XP_1_dout(mem_XP_1_dout),
  .out_mem_XP_1_rd_en(mem_XP_1_rd_en),
  .out_mem_XP_1_rd_addr(mem_rd_addr), 
  .out_mem_ZP_0_wr_en(mem_ZP_0_wr_en),
  .out_mem_ZP_0_wr_addr(mem_wr_addr),
  .out_mem_ZP_0_din(mem_din), 
  .out_mem_ZP_1_wr_en(mem_ZP_1_wr_en),
  .out_mem_ZP_1_wr_addr(mem_wr_addr),
  .out_mem_ZP_1_din(mem_din), 
  .mem_ZP_0_dout(mem_ZP_0_dout),
  .out_mem_ZP_0_rd_en(mem_ZP_0_rd_en),
  .out_mem_ZP_0_rd_addr(mem_rd_addr), 
  .mem_ZP_1_dout(mem_ZP_1_dout),
  .out_mem_ZP_1_rd_en(mem_ZP_1_rd_en),
  .out_mem_ZP_1_rd_addr(mem_rd_addr), 
  .out_mem_XQ_0_wr_en(mem_XQ_0_wr_en),
  .out_mem_XQ_0_wr_addr(mem_wr_addr),
  .out_mem_XQ_0_din(mem_din), 
  .out_mem_XQ_1_wr_en(mem_XQ_1_wr_en),
  .out_mem_XQ_1_wr_addr(mem_wr_addr),
  .out_mem_XQ_1_din(mem_din), 
  .mem_XQ_0_dout(mem_XQ_0_dout),
  .out_mem_XQ_0_rd_en(mem_XQ_0_rd_en),
  .out_mem_XQ_0_rd_addr(mem_rd_addr), 
  .mem_XQ_1_dout(mem_XQ_1_dout),
  .out_mem_XQ_1_rd_en(mem_XQ_1_rd_en),
  .out_mem_XQ_1_rd_addr(mem_rd_addr), 
  .out_mem_ZQ_0_wr_en(mem_ZQ_0_wr_en),
  .out_mem_ZQ_0_wr_addr(mem_wr_addr),
  .out_mem_ZQ_0_din(mem_din), 
  .out_mem_ZQ_1_wr_en(mem_ZQ_1_wr_en),
  .out_mem_ZQ_1_wr_addr(mem_wr_addr),
  .out_mem_ZQ_1_din(mem_din), 
  .mem_ZQ_0_dout(mem_ZQ_0_dout),
  .out_mem_ZQ_0_rd_en(mem_ZQ_0_rd_en),
  .out_mem_ZQ_0_rd_addr(mem_rd_addr), 
  .mem_ZQ_1_dout(mem_ZQ_1_dout),
  .out_mem_ZQ_1_rd_en(mem_ZQ_1_rd_en),
  .out_mem_ZQ_1_rd_addr(mem_rd_addr), 
  .out_mem_xPQ_0_wr_en(mem_xPQ_0_wr_en),
  .out_mem_xPQ_0_wr_addr(mem_wr_addr),
  .out_mem_xPQ_0_din(mem_din), 
  .out_mem_xPQ_1_wr_en(mem_xPQ_1_wr_en),
  .out_mem_xPQ_1_wr_addr(mem_wr_addr),
  .out_mem_xPQ_1_din(mem_din),  
  .mem_xPQ_0_dout(mem_xPQ_0_dout),
  .out_mem_xPQ_0_rd_en(mem_xPQ_0_rd_en),
  .out_mem_xPQ_0_rd_addr(mem_rd_addr), 
  .mem_xPQ_1_dout(mem_xPQ_1_dout),
  .out_mem_xPQ_1_rd_en(mem_xPQ_1_rd_en),
  .out_mem_xPQ_1_rd_addr(mem_rd_addr), 
  .out_mem_zPQ_0_wr_en(mem_zPQ_0_wr_en),
  .out_mem_zPQ_0_wr_addr(mem_wr_addr),
  .out_mem_zPQ_0_din(mem_din), 
  .out_mem_zPQ_1_wr_en(mem_zPQ_1_wr_en),
  .out_mem_zPQ_1_wr_addr(mem_wr_addr),
  .out_mem_zPQ_1_din(mem_din),
  .mem_zPQ_0_dout(mem_zPQ_0_dout), 
  .out_mem_zPQ_0_rd_en(mem_zPQ_0_rd_en),
  .out_mem_zPQ_0_rd_addr(mem_rd_addr), 
  .mem_zPQ_1_dout(mem_zPQ_1_dout),
  .out_mem_zPQ_1_rd_en(mem_zPQ_1_rd_en),
  .out_mem_zPQ_1_rd_addr(mem_rd_addr), 
  .out_mem_A24_0_wr_en(mem_A24_0_wr_en),
  .out_mem_A24_0_wr_addr(mem_wr_addr),
  .out_mem_A24_0_din(mem_din), 
  .out_mem_A24_1_wr_en(mem_A24_1_wr_en),
  .out_mem_A24_1_wr_addr(mem_wr_addr),
  .out_mem_A24_1_din(mem_din), 
  .mem_A24_0_dout(mem_A24_0_dout),
  .out_mem_A24_0_rd_en(mem_A24_0_rd_en),
  .out_mem_A24_0_rd_addr(mem_rd_addr), 
  .mem_A24_1_dout(mem_A24_1_dout),
  .out_mem_A24_1_rd_en(mem_A24_1_rd_en),
  .out_mem_A24_1_rd_addr(mem_rd_addr), 
  .out_mem_C24_0_wr_en(mem_C24_0_wr_en),
  .out_mem_C24_0_wr_addr(mem_wr_addr),
  .out_mem_C24_0_din(mem_din), 
  .out_mem_C24_1_wr_en(mem_C24_1_wr_en),
  .out_mem_C24_1_wr_addr(mem_wr_addr),
  .out_mem_C24_1_din(mem_din), 
  .mem_C24_0_dout(mem_C24_0_dout),
  .out_mem_C24_0_rd_en(mem_C24_0_rd_en),
  .out_mem_C24_0_rd_addr(mem_rd_addr), 
  .mem_C24_1_dout(mem_C24_1_dout),
  .out_mem_C24_1_rd_en(mem_C24_1_rd_en),
  .out_mem_C24_1_rd_addr(mem_rd_addr),
  .out_sk_mem_wr_en(sk_mem_wr_en),
  .out_sk_mem_wr_addr(mem_wr_addr),
  .out_sk_mem_din(mem_din)
);

endmodule
