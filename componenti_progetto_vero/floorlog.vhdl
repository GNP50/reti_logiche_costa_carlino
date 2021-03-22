----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.02.2021 21:23:13
-- Design Name: 
-- Module Name: floorlog - Behavioral
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity floorlog is
    port(
        x: in std_logic_vector(0 to 7);
        result: out std_logic_vector(0 to 2)
    );
end floorlog;

architecture Behavioral of floorlog is
    
begin
    process(x)
    begin
        if unsigned(x) +1= 1 then
            result<=std_logic_vector(TO_UNSIGNED(0,3));
        if unsigned(x)+1>=2 and unsigned(x)+1<=3 then
            result<=std_logic_vector(TO_UNSIGNED(1,3));
        elsif unsigned(x)+1>=4 and unsigned(x)+1<=7 then
            result<=std_logic_vector(TO_UNSIGNED(2,3));
        elsif unsigned(x)+1>=8 and unsigned(x)+1<=15 then
            result<=std_logic_vector(TO_UNSIGNED(3,3));
        elsif unsigned(x)+1>=16 and unsigned(x)+1<=31 then
            result<=std_logic_vector(TO_UNSIGNED(4,3));
        elsif unsigned(x)+1>=32 and unsigned(x)+1<=63 then
            result<=std_logic_vector(TO_UNSIGNED(5,3));
        elsif unsigned(x)+1>=64 and unsigned(x)+1<=127 then
            result<=std_logic_vector(TO_UNSIGNED(6,3));
        elsi  f unsigned(x)+1>=128 and unsigned(x)+1<=255 then
            result<=std_logic_vector(TO_UNSIGNED(7,3));
            
        end if;
        
    end process;

end Behavioral;
