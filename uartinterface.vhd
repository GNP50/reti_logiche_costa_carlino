library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity uartinterface is
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
end uartinterface;

architecture UART_INTERFACE_A of uartinterface is
	--declaring states type
	type state is (RX,TX,NONE,WAITINGRX,WAITINGTX);
	type message_chain is (CODE,ADDRESS2,ADDRESS1,DATA);
	signal waited:std_logic:='0';
	--declare state signals
	signal tx_chain_state: message_chain :=CODE;
	signal curr_state:state := NONE;
	signal working_signal: std_logic;
	begin
	working_signal <= read_ok or write_done;
	
	
	
	process (i_clk)
	begin
		case curr_state is
		when  NONE=>
			if (m_enable='1') then
				if(o_enable = '0') then
					curr_state <= RX;
				else
					curr_state <= TX;
				end if;
			
			end if;
			when RX=>
					--code for reading
					--send_reading code
				if(tx_chain_state = CODE) then
					if(waited = '0') then
						uartdata <= std_logic_vector(to_unsigned(1,8));
						write_ok <= '1';
						curr_state <= WAITINGRX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=ADDRESS1;
					end if;
				elsif(tx_chain_state=ADDRESS1) then
					--send address
					if(waited = '0') then
						uartdata <= o_address(7 downto 0);
						write_ok <= '1';
						curr_state <= WAITINGRX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=ADDRESS2;
					end if;
				elsif(tx_chain_state=ADDRESS2) then
					if(waited = '0') then
						uartdata <= o_address(15 downto 8);
						write_ok <= '1';
						curr_state <= WAITINGRX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=DATA;
					end if;
				elsif(tx_chain_state= DATA) then
					--read data
					if(waited = '0') then
						read_ok <= '1';
						i_data <= uartdata;
						curr_state <= WAITINGRX;
					else
						waited <= '0';
						read_ok<= '0';
						curr_state <= NONE;
						tx_chain_state<=CODE;
					end if;
				end if;
			when TX=>
					--code for reading
					--send_reading code
				if(tx_chain_state = CODE) then
					if(waited = '0') then
						uartdata <= std_logic_vector(to_unsigned(2,8));
						write_ok <= '1';
						curr_state <= WAITINGTX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=ADDRESS1;
					end if;
				elsif(tx_chain_state=ADDRESS1) then
					--send address
					if(waited = '0') then
						uartdata <= o_address(7 downto 0);
						write_ok <= '1';
						curr_state <= WAITINGTX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=ADDRESS2;
					end if;
				elsif(tx_chain_state=ADDRESS2) then
					if(waited = '0') then
						uartdata <= o_address(15 downto 8);
						write_ok <= '1';
						curr_state <= WAITINGTX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=DATA;
					end if;
				elsif(tx_chain_state= DATA) then
					if(waited = '0') then
						uartdata <= o_data;
						write_ok <= '1';
						curr_state <= WAITINGTX;
					else
						waited <= '0';
						write_ok <= '0';
						tx_chain_state<=DATA;
					end if;
				end if;
				
				when WAITINGRX=>
					if(working_signal = '0') then
						curr_state <= RX;
					end if;
				when WAITINGTX=>
					if(working_signal = '0') then
						curr_state <= TX;
					end if;
		end case;
		
	end process;
	
end UART_INTERFACE_A;
	
