/* Released to the public domain */

---
 --- Author:        Ruben Niederhagen <ruben@polycephaly.org >  
 --- Abstract:      top level module main  
---

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity main is
    Port ( SW       : in    std_logic_vector (3 downto 0);
           BTN      : in    std_logic_vector (3 downto 0);
           CLK      : in    std_logic;
           RST      : in    std_logic;
           LED      : out   std_logic_vector (3 downto 0);
           TDO      : out   std_logic;
           TDI      : in    std_logic;
           TMS      : in    std_logic;
           TCK      : in    std_logic;
           UART_TXD : out   std_logic;
           UART_RXD : in    std_logic;
           led0_r   : out   std_logic;
           led0_g   : out   std_logic;
           led0_b   : out   std_logic;    
           led1_r   : out   std_logic;
           led1_g   : out   std_logic;
           led1_b   : out   std_logic
        );
end main;

architecture Behavioral of main is

component MuraxControllerMontgomeryMultiplier
  port(
    io_asyncReset : in std_logic;
    io_mainClk : in std_logic;
    io_jtag_tms : in std_logic;
    io_jtag_tdi : in std_logic;
    io_jtag_tdo : out std_logic;
    io_jtag_tck : in std_logic;
    io_gpioA_read : in std_logic_vector(31 downto 0);
    io_gpioA_write : out std_logic_vector(31 downto 0);
    io_gpioA_writeEnable : out std_logic_vector(31 downto 0);
    io_uart_txd : out std_logic;
    io_uart_rxd : in std_logic
  );
end component;

signal CPU_CLK : std_logic := '0'; 
signal wait_counter_din : natural := 0;
constant max_wait_counter_din : natural := 0;

signal gpioA_write  : std_logic_vector(31 downto 0);
signal gpioA_enable  : std_logic_vector(31 downto 0);

begin

  CLK_GEN: process(CLK) is
  begin
    if(rising_edge(CLK)) then
      if (wait_counter_din = max_wait_counter_din) then
        CPU_CLK <= not CPU_CLK; 
        wait_counter_din <= 0;
      else
        wait_counter_din <= wait_counter_din + 1;
      end if;
    end if;
  end process;

  LED <= gpioA_write(3 downto 0);

  led0_r <= gpioA_write(4);
  led0_g <= gpioA_write(5);
  led0_b <= gpioA_write(6);

  led1_r <= gpioA_write(7);
  led1_g <= gpioA_write(8);
  led1_b <= gpioA_write(9);
 
  core: MuraxControllerMontgomeryMultiplier port map(
       io_asyncReset  => RST,
       io_mainClk     => CPU_CLK, -- CLK
       io_jtag_tms    => TMS,
       io_jtag_tdi    => TDI,
       io_jtag_tdo    => TDO,
       io_jtag_tck    => TCK,
       io_gpioA_read  => (31 downto 8 => '0') & SW & BTN,
       io_gpioA_write  => gpioA_write,
       io_gpioA_writeEnable => gpioA_enable,
       io_uart_txd    => UART_TXD,
       io_uart_rxd    => UART_RXD
  );
 
end Behavioral;

