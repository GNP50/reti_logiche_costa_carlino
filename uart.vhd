library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity uart is
	port (
		i_clk: in std_logic;
		i_data: out std_logic_vector(7 downto 0);
		o_address : in std_logic_vector(15 downto 0);
		o_done: in std_logic;
		o_data: in std_logic_vector (7 downto 0);
		m_enable: in std_logic;
		o_enable: in std_logic;
		--put output_signals
		rx: out std_logic;
		tx: out std_logic
	);
end uart;

architecture UART_INTERFACE of uart is
	
	component uartinterface 
	port (
		i_clk: in std_logic;
		i_data: out std_logic_vector(7 downto 0);
		o_address : in std_logic_vector(15 downto 0);
		o_done: in std_logic;
		o_data: in std_logic_vector (7 downto 0);
		m_enable: in std_logic;
		o_enable: in std_logic;
		
		--data for interfacing with components
		uartdata:buffer std_logic_vector(7 downto 0);
		--signals for components
		--tx_components
		
		write_ok: out std_logic;
		write_done: in std_logic;
		
		--rx components
		read_ok: buffer std_logic
	);
	end component;
	component UART_TX
	port(
		tx:out std_logic;
		clk: in std_logic;
		in_data: buffer std_logic_vector(7 downto 0);
		write_ok: in std_logic;
		write_done: out std_logic
	);
	end component;
	
	component UART_RX
	port(
		rx:in std_logic;
		clk: in std_logic;
		out_data: buffer std_logic_vector(7 downto 0);
		read_ok: buffer std_logic
	);
	
	end component;
	
	
	
	--signal to connect components
	signal uartdata_s:std_logic_vector(7 downto 0);
	signal write_ok_s:std_logic;
	signal write_done_s:std_logic;
	signal read_ok_s:std_logic;
	signal rx_out_s:std_logic;
	signal tx_out_s:std_logic;
	
begin
	rx_part: UART_RX port map(
		rx => rx_out_s,
		clk => i_clk,
		out_data => uartdata_s,
		read_ok => read_ok_s
	);
	
	tx_part: UART_TX port map(
		tx => tx_out_s,
		clk => i_clk,
		in_data => uartdata_s,
		write_ok => write_ok_s,
		write_done => write_done_s
	);
	
	u_if: uartinterface port map(
		i_clk=>i_clk,
		i_data=>i_data,
		o_address=>o_address,
		o_done=>o_done,
		m_enable=>m_enable,
		o_enable=>o_enable,
		o_data => o_data,
		--start the signal part
		uartdata=>uartdata_s,
		write_ok => write_ok_s,
		write_done => write_done_s,
		read_ok => read_ok_s
	);
	
	
	
	rx<=rx_out_s;
	tx<=tx_out_s;
	
end UART_INTERFACE;
	
