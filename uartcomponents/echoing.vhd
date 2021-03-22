library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity echoing is
	 port(
        clk:in std_logic;
        rx:in std_logic;
        tx:out std_logic;
		  led1,led2,led3: out std_logic
    );
end echoing;

architecture echotest_a of echoing is
	
	signal rx_enable_s:std_logic := '0';
	signal tx_enable_s:std_logic := '0';
	signal data_r:std_logic_vector(7 downto 0) :="00000000";
	signal data_t:std_logic_vector(7 downto 0) :="00000000";
	
	signal read_ok_s:std_logic:='0';
	signal write_ok_s :std_logic:='0';
	
	type state is (READING,WRITING,WAITREADING,WAITWRITING);
	signal crr_state:state := READING;
	
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
    
    begin
        uart_if:uartcontroller port map(clk,rx,tx,tx_enable_s,rx_enable_s,read_ok_s,write_ok_s,data_r,data_t);
        
    process(clk)
    begin
    
        if rising_edge(clk) then
        
            case crr_state is
                when READING=>
					 
						  led1 <='0';
						  led2<='1';
						  led3<='1';
						  
                    rx_enable_s<='1';
						  tx_enable_s<='0';
                    if read_ok_s = '1' then
                        rx_enable_s <= '0';
                        crr_state <=  WAITWRITING;
                    end if;
                when WRITING=>
						  led1 <='0';
						  led2<='0';
						  led3<='1';
						  
                    tx_enable_s<='1';
						  rx_enable_s<='0';
                    if write_ok_s = '1' then
                        tx_enable_s <= '0';
                        crr_state <=  WAITREADING;
                    end if;
                    
                when WAITREADING=>
					     led1 <='0';
						  led2<='0';
						  led3<='0';
                    rx_enable_s<='1';
                    tx_enable_s <='0';
                    if read_ok_s<='0' then
                        crr_state <= READING;
                    end if;
                
                when WAITWRITING=>
					 led1 <='1';
						  led2<='1';
						  led3<='0';
						  data_t <= data_r;
                    tx_enable_s<='1';
				    rx_enable_s<='0';
                    if write_ok_s='0' then
                        crr_state <= WRITING;
                    end if;
            end case;
        
        end if;
    
    
    end process;
    
	
end echotest_a;
	