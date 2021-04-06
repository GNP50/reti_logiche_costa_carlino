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
            o_max : out STD_LOGIC_VECTOR (7 downto 0);
            done : out std_logic
        );
end max_min;

architecture Behavioral of max_min is
    signal max_s: integer range 0 to 255;
    signal min_s: integer range 0 to 255;
begin
    process(i_clk,i_rst)
    begin
        o_max <= std_logic_vector(to_unsigned(max_s,8));
        o_min <= std_logic_vector(to_unsigned(min_s,8));

        if(i_rst = '1') then
            min_s<=255;
            max_s<=0;
        elsif falling_edge(i_clk) and i_en='1' then
            if(unsigned(i_current_pixel_value)>max_s) then
                max_s <= to_integer(unsigned(i_current_pixel_value));
            elsif(unsigned(i_current_pixel_value)<min_s) then
                min_s <= to_integer(unsigned(i_current_pixel_value));
            end if;  
        end if;
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
    type signal_type is(RST,ASKWIDTH,GETWIDTH,ASKHEIGTH,READIMAGE,CALCULATE_SHIFT,CHANGE_PIXEL_VALUE,WRITE,DONE); --else
    signal state:signal_type:=RST;
    
    component max_min
    port (  i_clk : in std_logic;
            i_rst : in std_logic;
            i_en : in std_logic;
            i_current_pixel_value : in STD_LOGIC_VECTOR (7 downto 0);
            o_min : out STD_LOGIC_VECTOR (7 downto 0);
            o_max : out STD_LOGIC_VECTOR (7 downto 0)
    );
    end component;



    
    signal mm_en: std_logic := '0';
    signal width:integer range 0 to 255 := 0;
    signal heigth:integer range 0 to 255 := 0;
    signal current_address:integer range 0 to 65535:= 0;
    signal tmp_w: integer range 0 to 255 := 0;
    signal tmp_h:integer range 0 to 255 := 0;
    signal max:std_logic_vector(7 downto 0);
    signal min:std_logic_vector(7 downto 0);
    
    signal out_off: integer range 0 to 65535 := 0;
   
    
    
begin
    mm: max_min port map(i_clk,i_rst,mm_en,i_data,min,max); 
     
    process(i_clk,i_rst)
    --variables for change values
    variable delta:integer range 0 to 255 := 0;
    variable shift_level: integer range 1 to 8 := 0;
    variable tmp_value:unsigned(15 downto 0);
    variable tmp_diff: unsigned(15 downto 0);
    
    
    begin
        o_done <= '0';
        o_en <= '0';

        if(i_rst = '1') then
            state <= RST;
            
        elsif falling_edge(i_clk) then
            
       
        case state is
            when RST=>
                heigth <=0;
                width <= 0;
                tmp_w <= 0;
                tmp_h <= 0;
                out_off<= 0;
                o_we <= '0';
                o_address <= "0000000000000000";

                if i_start='1' then
                    o_en <='1';
                    state <=ASKHEIGTH;
                end if;
           
            when ASKHEIGTH=>
                if(i_data="00000000") then
                    state <=DONE;
                else
                    heigth <= to_integer(unsigned(i_data));
                    o_en <='1';

                    o_address <= "0000000000000001";
                    state <=ASKWIDTH;
                end if;
             when ASKWIDTH=>
                o_en <='1';

                if(i_data="00000000") then
                    state <=DONE;
                else
                    width <= to_integer(unsigned(i_data));
                    tmp_h<= heigth-1;
                    current_address <= 2;
                    o_address <= "0000000000000010";
                    mm_en <= '1';
                    state <=GETWIDTH;
                end if;
            when GETWIDTH=>
                o_en <='1';

                tmp_w<= width-1;
                state <= READIMAGE;
            when READIMAGE=>     
                 o_en <='1';
         
                 if tmp_w = 0 then
                    tmp_w <= width-1;
                    tmp_h <= tmp_h-1;
                    if tmp_h = 0 then
                        state <= CALCULATE_SHIFT;   
                        o_address <= std_logic_vector(to_unsigned(current_address,16));
                    else
                        current_address <= current_address +1;
                        o_address <= std_logic_vector(to_unsigned(current_address,16));
                        state <= READIMAGE;
                    end if;
                 else
                    current_address <= current_address +1;
                    tmp_w <= tmp_w -1;
                    o_address <= std_logic_vector(to_unsigned(current_address,16));
                    state <= READIMAGE;
                 end if;                
                 
            when CALCULATE_SHIFT=>
                --resetting value
                o_en <='1';
                        tmp_h <= heigth-1;
                        tmp_w <= width-1;
                        state <= CHANGE_PIXEL_VALUE;   
                        out_off <= current_address-2;

                        
                        
                        current_address <= 2;
                        o_address <= "0000000000000010";
                        mm_en <= '0';
                        --calculate parameter
                        delta := to_integer(unsigned(max)) - to_integer(unsigned(min))+1;
                         if delta= 1 then
                            shift_level:=8;
                        elsif delta>=2 and delta<=3 then
                            shift_level := 7;
                        elsif delta>=4 and delta<=7 then
                            shift_level := 6;
                        elsif delta>=8 and delta<=15 then
                            shift_level := 5;
                        elsif delta>=16 and delta<=31 then
                            shift_level := 4;
                        elsif delta>=32 and delta<=63 then
                            shift_level := 3;
                        elsif delta>=64 and delta<=127 then
                            shift_level := 2;
                        elsif delta>=128 and delta<=255 then
                            shift_level := 1;
            
                        end if;
            
            when CHANGE_PIXEL_VALUE=>
               o_en <='1';

               if tmp_w = 0 then
                    tmp_w <= width;
                    tmp_h <= tmp_h -1;
                    
                 else
                    tmp_w <= tmp_w -1;
                 end if;         
                
                 -- change value and write to memory
                 o_we <= '1';
                 
                 tmp_diff(15 downto 8) := "00000000";
                 tmp_diff(7 downto 0) := unsigned(i_data)-unsigned(min);
                 tmp_value := shift_left(tmp_diff,shift_level);
                 if tmp_value(15 downto 8) = "00000000" then
                    o_data <= std_logic_vector(tmp_value(7 downto 0));
                 else
                    o_data <= "11111111";
                 end if;
                 
                 state <= WRITE;
                
                o_address <= std_logic_vector(to_unsigned(out_off+current_address,16));
                if tmp_w = 0 and tmp_h = 0 then
                     state <= DONE;
                     o_done <= '1';
                     --resetting value
                     tmp_h <= heigth-1;
                     tmp_w <= width-1;
                     current_address <= 2;
                     mm_en <= '0';
                     o_we <= '0';
                 end if;

            when WRITE=>
                o_en <='1';

                state <=CHANGE_PIXEL_VALUE;
                o_address <= std_logic_vector(to_unsigned(current_address,16));
                current_address <= current_address +1;
                o_we <= '0';

            when DONE =>
                o_done <= '1';
                if i_start = '0' then
                    state <= RST;
                else
                    state <= DONE;
                end if; 
        end case; 
        end if;
        
    end process;

end Behavioral;
