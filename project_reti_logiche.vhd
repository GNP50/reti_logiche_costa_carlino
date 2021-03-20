----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.02.2021 16:29:07
-- Design Name: 
-- Module Name: new_pixel_value - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity new_pixel_value is
    Port ( current_pixel_value : in STD_LOGIC_VECTOR (7 downto 0);
           min_pixel_value : in STD_LOGIC_VECTOR (7 downto 0);
           shift_level : in STD_LOGIC_VECTOR (3 downto 0);
           new_pixel_value : out STD_LOGIC_VECTOR (7 downto 0));
end new_pixel_value;

architecture Behavioral of new_pixel_value is
signal diff: STD_LOGIC_VECTOR (15 downto 0);
signal temp: STD_LOGIC_VECTOR (15 downto 0);
begin
    diff(15 downto 8) <= "00000000";
    diff(7 downto 0) <= current_pixel_value - min_pixel_value;
    temp <= shl(diff,shift_level);
    --new_pixel_value <= '11111111' when true else temp (7 downto 0);
    new_pixel_value <= "11111111" when temp(15 downto 8) /= "00000000" else temp(7 downto 0);
end Behavioral;


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.02.2021 16:29:07
-- Design Name: 
-- Module Name: new_pixel_value - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity max_min is
    Port (  i_clk : in std_logic;
            i_rst : in std_logic;
            i_en : in std_logic;
            i_current_pixel_value : in STD_LOGIC_VECTOR (7 downto 0);
            o_min : out STD_LOGIC_VECTOR (7 downto 0);
            o_max : out STD_LOGIC_VECTOR (7 downto 0));
end max_min;

architecture Behavioral of max_min is
    signal max: STD_LOGIC_VECTOR (7 downto 0);
    signal min: STD_LOGIC_VECTOR (7 downto 0);
begin
    process(i_clk,i_rst)
    begin
        if(i_rst = '1') then
            min<="11111111";
            max<="00000000";
        elsif falling_edge(i_clk) and i_en='1' then
            max <= max;
            min <= min;
            if(unsigned(i_current_pixel_value)>unsigned(max)) then
                max <= i_current_pixel_value;
            end if;  
            
            if(unsigned(i_current_pixel_value)<unsigned(min)) then
                min <= i_current_pixel_value;
            end if;  
        end if;
        o_max <= max;
        o_min <= min;
        
    end process;
end Behavioral;



----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.02.2021 22:24:59
-- Design Name: 
-- Module Name: stateMachine - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;


architecture Behavioral of project_reti_logiche is
component max_min
    Port (  i_clk : in std_logic;
            i_rst : in std_logic;
            i_en : in std_logic;
            i_current_pixel_value : in STD_LOGIC_VECTOR (7 downto 0);
            o_min : out STD_LOGIC_VECTOR (7 downto 0);
            o_max : out STD_LOGIC_VECTOR (7 downto 0));
end component;


    type signal_type is(A_RESET,B_LW,C_WW_RL,D_WL_START,E,F,G,H,I,Z); --else
    signal state:signal_type;
    signal max: std_logic_vector (7 downto 0);
    signal min: std_logic_vector (7 downto 0);
    signal mm_en: std_logic;
    signal width:unsigned(7 downto 0);
    signal heigth:unsigned(7 downto 0);
    signal current_address:unsigned(15 downto 0);
    signal tmp_w: unsigned(7 downto 0);
    signal tmp_h: unsigned(7 downto 0);
    signal hasDone:std_logic;   
    
begin
    mm: max_min PORT MAP (i_clk=>i_clk, i_rst=>i_rst, i_en => mm_en, o_max => max, o_min => min,i_current_pixel_value=>i_data); 

    process(i_clk,i_rst)
    begin
      
        if(i_rst = '1') then
            state <= A_RESET;
        elsif rising_edge(i_clk) then
            
        o_en <='0';
        o_done <='0';
        o_we <='0';
        o_data <="00000000";
        o_address <="0000000000000000";
        mm_en <= '0';
        --current_address <=current_address;
        case state is
            when A_RESET=>
                heigth <="00000000";
                width <="00000000";
                tmp_w <= "00000000";
                tmp_h <= "00000000";
                hasDone <='0';
                
                if i_start='1' then
                    state <=B_LW;
                 else
                    state <=A_RESET;
                end if;
            when B_LW=>
                o_address <= "0000000000000000";
                o_en <='1';            
                state <=C_WW_RL;
            when C_WW_RL=>
                if(i_data="00000000") then
                    state <=Z;
                else
                    width <= unsigned(i_data);
                    tmp_w<= width - 1 ;
                    o_address <= "0000000000000001";
                    o_en <='1';  
                    state <=D_WL_START;
                end if;
                
            when D_WL_START=>              
                if(i_data="00000000") then
                    state <=Z;
                else                
                    heigth<= unsigned(i_data);  
                    tmp_h <=heigth;
                    o_address <= "0000000000000010";
                    o_en <='1'; 
                    mm_en<='1'; 
                    current_address <= "0000000000000011";
                    state <=E;
                end if;               
            when E=>
                
                if(tmp_h=0 and tmp_w=0) then
                    state <=F;
                else               
                    if(tmp_w=0) then
                        tmp_w <= width;
                        tmp_h <=tmp_h -1;
                    end if;
                    tmp_w <= tmp_w -1;                    
                    current_address <= current_address+1;
                    o_address <= std_logic_vector(current_address);
                    o_en <='1';                    
                    mm_en <= '1'; 
                end if;   
                
            when F =>    
            when G =>
            when H =>
            when I =>
            when Z =>
                
        end case; 
        end if;
        
    end process;

end Behavioral;
