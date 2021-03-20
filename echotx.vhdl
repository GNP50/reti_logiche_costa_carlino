library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity echotx is
port(
    rx,clk:in std_logic;
    tx,led1,led4,led3,done:out std_logic
);
end entity;

architecture echotx_a of echotx is
    type state is(SENDING,WAITING);
    signal curr_state:state := SENDING;
    signal write_ok_s:std_logic:='0';
	
   component uart_tx
	port(
		tx:out std_logic;
		clk: in std_logic;
		in_data: in std_logic_vector(7 downto 0);
		write_ok: in std_logic;
		write_done: out std_logic;
		writing_d:out std_logic
	);
    end component;

    signal data:std_logic_vector(7 downto 0) := "11100010";
    signal write_done_s:std_logic;
	 signal led1_s:std_logic:='0';
	 signal led4_s:std_logic:='1';
	 
begin
    e_if:uart_tx port map(tx,clk,data,write_ok_s,write_done_s,led3);
    led1<=led1_s;
	 led4<=led4_s;
	 process(clk,rx,write_ok_s,write_done_s)
    begin
		if rising_edge(clk) then
        case curr_state is
            when SENDING=>
					led1_s<=not led1_s;
					led4_s<=not led4_s;
                    write_ok_s<='1';
                    curr_state <= WAITING;
                    done <='0';
                when WAITING=>
                    led1_s<= not led1_s;
                    led4_s<=not led4_s;
                    if write_done_s='1' then
                        curr_state<=SENDING;
                        write_ok_s <= '0'  ;
                        done <= '1';
                    end if;
            end case;
        end if;
    end process;

end echotx_a;

