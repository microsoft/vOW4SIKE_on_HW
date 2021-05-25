/* Released to the public domain */

/* 
 * Author:        Ruben Niederhagen <ruben@polycephaly.org >  
 * Abstract:      top level module main 
 * 
*/

module main ( 
  input [3:0] SW,
  input [3:0] BTN,
  input CLK,
  input RST,
  output [3:0] LED,
  output TDO,
  input TDI,
  input TMS,
  input TCK,
  output UART_TXD,
  input UART_RXD 
  ); 

wire [7:0] m_axis_tdata;
wire m_axis_tvalid;

wire [7:0] s_axis_tdata;
wire s_axis_tvalid;
wire s_axis_tready;


Murax murax_inst(
       .io_asyncReset(RST),
       .io_mainClk(CLK), 
       .io_jtag_tms(TMS),
       .io_jtag_tdi(TDI),
       .io_jtag_tdo(TDO),
       .io_jtag_tck(TCK),
       .io_gpioA_read(),
       .io_gpioA_write(),
       .io_gpioA_writeEnable(),
       .io_uart_txd(),
       .io_uart_rxd(UART_RXD)
  );

uart uart_inst (
    .clk(CLK), //     : in  std_logic;
    //-- external interface signals
    .rxd(UART_RXD), //     : in  std_logic;
    .txd(UART_TXD), //UART_TXD     : out std_logic;
    //-- internal interface signals
    //-- master axi stream interface
    .m_axis_tready(1'b1), // : in  std_logic;
    .m_axis_tdata(m_axis_tdata),  //: out std_logic_vector(DATA_WIDTH-1 downto 0);
    .m_axis_tvalid(m_axis_tvalid), //: out std_logic;
    //-- slave axi stream interface
    .s_axis_tvalid(s_axis_tvalid), //: in  std_logic;
    .s_axis_tdata(s_axis_tdata),  //: in  std_logic_vector(DATA_WIDTH-1 downto 0);
    .s_axis_tready(s_axis_tready) //: out std_logic
); 


delay #(.WIDTH(8), .DELAY(1000)) (
  .clk(CLK),
  .rst(RST),
  .din(m_axis_tdata),
  .dout(s_axis_tdata) 
  );

delay #(.WIDTH(1), .DELAY(1000)) (
  .clk(CLK),
  .rst(RST),
  .din(m_axis_tvalid),
  .dout(s_axis_tvalid) 
  );
 
endmodule


