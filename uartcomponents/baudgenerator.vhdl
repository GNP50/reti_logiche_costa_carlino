library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity baudgenerator is
    generic(
		clkPBit:integer := 434 -- 115200 baurate with 50 MHz of clock
	);
	port(
		clk: in std_logic;
		out_clk: out std_logic
	);
	
end baudgenerator;


architecture ba of baudgenerator is
	type state_t is (UP,DOWN);
	signal state:state_t := DOWN;
	
begin

process(clk)
variable clk_counter: integer range 0 to clkPBit-1;
begin
	if rising_edge(clk) then
		case state is
			when UP=>
				if clk_counter = clkPBit-1 then
					clk_counter := 0;
					state <= DOWN;
					out_clk<='1';
				else
					clk_counter := clk_counter +1;
			    end if;
			when DOWN=>
				if clk_counter = clkPBit-1 then
					clk_counter := 0;
					state <= UP;
					out_clk<='0';
				else
					clk_counter := clk_counter +1;
			    end if;
		end case;
	end if;
end process;


end architecture;

