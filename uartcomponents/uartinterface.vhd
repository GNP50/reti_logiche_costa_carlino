library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity uartinterface is
	port (
		i_clk: in std_logic;
		rst:in std_logic;
		rx: in  std_logic;
		tx: out std_logic
	);
end uartinterface;

architecture UART_INTERFACE_A of uartinterface is

component baudgenerator
    generic(
		clkPBit:integer := 434 -- 115200 baurate with 50 MHz of clock
	);
    port(
		clk: in std_logic;
		out_clk: out std_logic
	);
end component;

component addresschangedetector
port (
    rst:in std_logic;
    clk:in std_logic;
    in_data:in std_logic_vector(15 downto 0);
    changed:in std_logic
  );
end component;

component project_reti_logiche
port (
      i_clk         : in  std_logic;
      i_rst         : in  std_logic;
      i_start       : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;
component uartcontroller

    port(
        clk:in std_logic;
        rx:in std_logic;
        tx:out std_logic;
        tx_enable,rx_enable:in std_logic;
        read_ok,write_ok:out std_logic;
        read_data:out std_logic_vector(7 downto 0);
        in_data:in std_logic_vector(7 downto 0)
    );
end component;

signal rtx_clk:std_logic;
signal read_ok_s:std_logic := '0';
signal write_ok_s:std_logic := '0';
signal tx_enable_s:std_logic := '0';
signal rx_enable_s:std_logic := '1';
signal i_data:std_logic_vector(7 downto 0) := "00000000";
signal o_data:std_logic_vector(7 downto 0) := "00000000";

--signal for project component
signal porta_clk:std_logic;
signal i_start_s:std_logic:= '0';
signal address:std_logic_vector(15 downto 0);
signal o_done_s:std_logic:='0';
signal o_en_s:std_logic:='0';
signal o_we_s:std_logic:='0';


--STATE MACHINE CODE
type state_t is (IDLE,CHOICE_STATE,SENDADDRESS,WAITDATA,SENDDATA);
signal state:state_t := IDLE;

type operation_t is (READ,WRITE);
signal op:operation_t := READ;

type address_t is (FIRSTP,SECONDP);
signal part:address_t:=FIRSTP;

--address change detector signal
signal address_change:std_logic:='0';
begin
    addrch:addresschangedetector port map(rst,i_clk,address,address_change);
    b_comp:baudgenerator 
        generic map(8860*3)
        port map(i_clk,porta_clk);
    b_uart:baudgenerator 
        generic map(443)
        port map(i_clk,rtx_clk);
    u_ctl:uartcontroller port map(rtx_clk,rx,tx,tx_enable_s,rx_enable_s,read_ok_s,write_ok_s,i_data,o_data);
    cmp:project_reti_logiche port map(porta_clk,rst,i_start_s,i_data,address,o_done_s,o_en_s,o_we_s,o_data);
process(address)
begin

if rising_edge(i_clk) then
    case state is
         when IDLE =>
            if read_ok_s = '1' and to_integer(unsigned(i_data)) = 1 then
                i_start_s<= '1';
                state <= CHOICE_STATE;
            end if;
         when CHOICE_STATE=>
            if address_change <='1' then
                if o_we_s = '0' then
                    op<= READ;
                else
                    op<=WRITE;
                end if;
                rx_enable_s<='0';
                tx_enable_s<= '1';
                state<=SENDADDRESS;
            end if;
         when SENDADDRESS=>
            if part=FIRSTP then
                
                part <= SECONDP;
            end if;
    end case;
end if;

end process;

end UART_INTERFACE_A;
	
