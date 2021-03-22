library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity UART_TX is
	generic(
		clkPBit:integer := 434
	);
	port(
		tx:out std_logic;
		clk: in std_logic;
		in_data: in std_logic_vector(7 downto 0);
		write_ok: in std_logic;
		write_done: out std_logic;
		writing_d:out std_logic
	);
	
end UART_TX;


architecture UART_TX_A of UART_TX is
	type state is(IDLE,START_BIT,TRASMISSION,END_BIT);
	signal curr_state:state := IDLE;
	signal writing_d_s:std_logic:='0';
	
	begin
	writing_d<=writing_d_s;
	
	
	process(clk)
	variable clk_counter:integer range 0 to clkPBit-1:= 0;
	variable bit_counter:integer range 0 to 9 := 0;
	
	begin
		if rising_edge(clk) then
			case curr_state is
				when IDLE=>
				    tx<='1';
					
					if write_ok = '1' then
						write_done <= '0';
						curr_state <= START_BIT;
					end if;
					
				when START_BIT =>
                    write_done <= '0';
					tx<='0';
					if clk_counter = clkPBit-1 then
						curr_state <= TRASMISSION;
						clk_counter := 0;
						bit_counter :=0;
					else
						clk_counter := clk_counter +1;
					end if;
				when TRASMISSION=>
					if clk_counter = 0 then
						if bit_counter /= 8 then
							 tx<=in_data(bit_counter);
							 bit_counter := bit_counter +1;
						else
							tx<='1';
							bit_counter := bit_counter +1;
						end if;
						clk_counter := clk_counter +1;
					elsif clk_counter = clkPBit -1 then
						    if bit_counter = 9 then
								
								curr_state <= END_BIT;
								bit_counter := 0;
							 end if;
							 clk_counter := 0;
					else
						    clk_counter := clk_counter +1;
					end if;
				when END_BIT =>
					writing_d_s <= '1';
					write_done <= '1';
					tx<='1';
					curr_state <= IDLE;
			end case;
		end if;
		
	end process;

end UART_TX_A;
