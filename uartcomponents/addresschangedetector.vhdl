----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 12:22:42
-- Design Name: 
-- Module Name: addresschangedetector - Behavioral
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
use ieee.std_logic_misc.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity addresschangedetector is
  port (
    rst:in std_logic;
    clk:in std_logic;
    in_data:in std_logic_vector(15 downto 0);
    changed:in std_logic
  );
end addresschangedetector;

architecture Behavioral of addresschangedetector is
type state_s is (REST,CONTROLL);    
signal state:state_s:=REST;
signal old:std_logic_vector(16 downto 0);
signal changed_s:std_logic:='1';
    
begin
process(clk)
begin
if rst='1' then
    state<= REST;
elsif rising_edge(clk) then
    case state is
        when REST=>
            old<=in_data;
            state<=CONTROLL;
        when CONTROLL=>
            changed_s<=or_reduce(old xor in_data);
            old<=in_data;
    end case;
end if;
end process;
end Behavioral;

