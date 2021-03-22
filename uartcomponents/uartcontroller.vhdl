----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2021 10:58:54
-- Design Name: 
-- Module Name: uartcontroller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity uartcontroller is

    port(
        clk:in std_logic;
        rx:in std_logic;
        tx:out std_logic;
        tx_enable,rx_enable:in std_logic;
        read_ok,write_ok:out std_logic;
        read_data:out std_logic_vector(7 downto 0);
        in_data:in std_logic_vector(7 downto 0)
    );
end uartcontroller;

architecture Behavioral of uartcontroller is

    signal writing_d_s:std_logic:='0';
    signal read_ok_s:std_logic:='0';
    signal write_ok_s:std_logic:='0';
    signal txclk:std_logic;
	signal rxclk:std_logic;
	 
    type state is (WAITING,READING,TRANSMITTING);
    signal curr_state:state:=WAITING;
    
    component UART_TX
	port(
		tx:out std_logic;
		clk: in std_logic;
		in_data: in std_logic_vector(7 downto 0);
		write_ok: in std_logic;
		write_done: out std_logic;
		writing_d:out std_logic
	);
	end component;
	
	component UART_RX
	port(
		rx:in std_logic;
		clk: in std_logic;
		out_data: out std_logic_vector(7 downto 0);
		read_ok: out std_logic
	);
	end component;
	
	
    begin
       txclk <=clk and tx_enable;
       rxclk <= clk and rx_enable;
       
       r_if:uart_rx port map(rx,rxclk,read_data,read_ok_s);
       t_if:uart_tx port map(tx,txclk,in_data,tx_enable,write_ok_s,writing_d_s);
		 write_ok<=write_ok_s;
		 read_ok<=read_ok_s;
	process(clk)
    begin    
        if rising_edge(clk) then
            case curr_state is
                when WAITING=>
                    if rx_enable = '1' then
                        curr_state <= READING;
                    elsif tx_enable = '1' then
                        curr_state <= TRANSMITTING;
                    end if;
                when READING=>
                    if read_ok_s='1' then
                        curr_state <= WAITING;
                    end if;
                    
                when TRANSMITTING=>
                    if write_ok_s = '1' then
                        curr_state <= WAITING;
                    end if;
            end case;
        end if;
	end process;



end Behavioral;
