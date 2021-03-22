library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity UART_RX is
    generic(
		clkPBit:integer := 434
	);
	port(
		rx:in std_logic;
		clk: in std_logic;
		out_data: out std_logic_vector(7 downto 0);
		read_ok: out std_logic
	);
	
end UART_RX;


architecture UART_RX_A of UART_RX is
	type state_type is (WAITING,STARTREADING);
	signal state:state_type := WAITING;
	signal read_ok_s:std_logic:='0';
begin
    read_ok<=read_ok_s;
	process(clk)
	variable clk_counter:integer range 0 to clkPBit-1:= 0;
	variable bit_counter:integer range 0 to 9 := 0;
	
	begin
	if rising_edge(clk) then
	   case state is
	       when WAITING=>
	           if rx='0' then
	               read_ok_s<='0';
	               clk_counter := clk_counter +1;
	               if clk_counter = clkPBit-1 then
	                   clk_counter :=0;
	                   state <= STARTREADING;
	               end if;
	           end if;
	       when STARTREADING=>
						clk_counter :=clk_counter +1;
	               if clk_counter = clkPBit/2 then
	                   if bit_counter /= 8 then
	                       out_data(bit_counter) <= rx;
	                       bit_counter := bit_counter+1;	                       
							 elsif bit_counter = 8 then
								bit_counter := bit_counter +1;
							 end if;
	               elsif clk_counter = clkPBit-1 then
	                   clk_counter := 0;
							 if bit_counter = 9 then
								  bit_counter :=0;
	                       state <= WAITING;
	                       read_ok_s<='1';
							 end if;
	               end if;
	   end case;
	end if;
	end process;

end UART_RX_A;