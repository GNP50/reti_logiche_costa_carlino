LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY max_min IS
	PORT 
	(
		i_clk : IN std_logic;
		i_rst : IN std_logic;
		i_en : IN std_logic;
		i_current_pixel_value : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		o_min : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		o_max : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		o_shift : OUT INTEGER RANGE 0 TO 8
	);
END max_min;

ARCHITECTURE Behavioral OF max_min IS
	SIGNAL max_s : INTEGER RANGE 0 TO 255;
	SIGNAL min_s : INTEGER RANGE 0 TO 255;
	SIGNAL delta : STD_LOGIC_VECTOR (8 DOWNTO 0);
BEGIN
	PROCESS (i_clk, i_rst)
	BEGIN
		o_max <= std_logic_vector(to_unsigned(max_s, 8));
		o_min <= std_logic_vector(to_unsigned(min_s, 8));

		IF (i_rst = '1') THEN
			min_s <= 255;
			max_s <= 0;
		ELSIF rising_edge(i_clk) AND i_en = '1' THEN
			IF (unsigned(i_current_pixel_value) > max_s) THEN
				max_s <= to_integer(unsigned(i_current_pixel_value));
			ELSIF (unsigned(i_current_pixel_value) < min_s) THEN
				min_s <= to_integer(unsigned(i_current_pixel_value));
			END IF; 
		END IF;
	END PROCESS;
	
	delta <=std_logic_vector(to_unsigned(max_s-min_s+1,9));
	
--	o_shift <= 
--	   0 WHEN delta(0)='1' ELSE
--	   1 WHEN delta(1)='1' ELSE
--	   2 WHEN delta(2)='1' ELSE
--	   3 WHEN delta(3)='1' ELSE
--	   4 WHEN delta(4)='1' ELSE
--	   5 WHEN delta(5)='1' ELSE
--	   6 WHEN delta(6)='1' ELSE
--	   7 WHEN delta(7)='1' ELSE
--	   8;
	
	o_shift <=  8 WHEN delta <= 1 ELSE 
			7 WHEN delta>1 AND delta <= 3 ELSE
			6 WHEN delta>3 AND delta <= 7 ELSE
			5 WHEN delta>7 AND delta <= 15 ELSE
			4 WHEN delta>15 AND delta <= 31 ELSE
			3 WHEN delta>31 AND delta <= 63 ELSE
			2 WHEN delta>63 AND delta <= 127 ELSE
			1 WHEN delta>127 AND delta <= 255 ELSE
			0;	
	
	END Behavioral;

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
	LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE ieee.numeric_std.ALL;

	-- Uncomment the following library declaration if using
	-- arithmetic functions with Signed or Unsigned values
	--use IEEE.NUMERIC_STD.ALL;

	-- Uncomment the following library declaration if instantiating
	-- any Xilinx leaf cells in this code.
	--library UNISIM;
	--use UNISIM.VComponents.all;

	ENTITY project_reti_logiche IS
		PORT 
		(
		i_clk : IN std_logic;
		i_rst : IN std_logic;
		i_start : IN std_logic;
		i_data : IN std_logic_vector(7 DOWNTO 0);
		o_address : OUT std_logic_vector(15 DOWNTO 0);
		o_done : OUT std_logic;
		o_en : OUT std_logic;
		o_we : OUT std_logic;
		o_data : OUT std_logic_vector (7 DOWNTO 0)
		);
	END project_reti_logiche;
	ARCHITECTURE Behavioral OF project_reti_logiche IS
		TYPE s IS(RST, ASKWIDTH, GETWIDTH, ASKHEIGTH, READIMAGE, WAIT_LAST_READ, WAIT_LAST_MM, CALCULATE_SHIFT, CHANGE_PIXEL_VALUE, WRITE, DONE); --else
		SIGNAL state, next_state : s := RST;
 
		COMPONENT max_min
			PORT 
			(
				i_clk : IN std_logic;
				i_rst : IN std_logic;
				i_en : IN std_logic;
				i_current_pixel_value : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				o_min : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
				o_max : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			    o_shift : OUT INTEGER RANGE 0 TO 8
			);
		END COMPONENT;
 
		SIGNAL mm_en : std_logic := '0';
		SIGNAL width : INTEGER RANGE 0 TO 255 := 0;
		SIGNAL heigth : INTEGER RANGE 0 TO 255 := 0;
		SIGNAL current_address : INTEGER RANGE 0 TO 65535 := 0;
		SIGNAL tmp_w : INTEGER RANGE 0 TO 255 := 0;
		SIGNAL tmp_h : INTEGER RANGE 0 TO 255 := 0;
		SIGNAL max : std_logic_vector(7 DOWNTO 0);
		SIGNAL min : std_logic_vector(7 DOWNTO 0); 
		SIGNAL out_off : INTEGER RANGE 0 TO 65535 := 0;
		SIGNAL int_rst : std_logic;
		SIGNAL int_rst_cmd : std_logic;
		SIGNAL shift_level : INTEGER RANGE 0 TO 8 := 0; 
	BEGIN
		mm : max_min PORT MAP(i_clk => i_clk, i_rst => int_rst, i_en=> mm_en, i_current_pixel_value => i_data, o_min => min, o_max=>max, o_shift => shift_level);
		
		int_rst <= '1' WHEN (state = RST OR i_rst = '1') ELSE '0';
		
		process(i_clk, i_rst)
        begin
            if(i_rst = '1') then
                state <= RST;
            elsif rising_edge(i_clk) then
                state <= next_state;
            end if;
        end process;
		
		
		PROCESS (i_clk, i_rst)
		
		BEGIN
		  next_state <= state;
		      CASE state IS
					WHEN RST => 						
						IF i_start = '1' THEN
							next_state <= ASKHEIGTH;
						END IF;
 
					WHEN ASKHEIGTH => 
						IF (i_data = "00000000") THEN
							next_state <= DONE;
						ELSE
							next_state <= ASKWIDTH;
						END IF;
					WHEN ASKWIDTH => 
						IF (i_data = "00000000") THEN
							next_state <= DONE;
						ELSE
							next_state <= GETWIDTH;
						END IF;
					WHEN GETWIDTH => 
						next_state <= READIMAGE;
					WHEN READIMAGE => 
						
						IF tmp_w = 0 THEN
							IF tmp_h = 0 THEN
								next_state <= WAIT_LAST_READ; 
							ELSE
								next_state <= READIMAGE;
							END IF;
						ELSE
							next_state <= READIMAGE;
						END IF;
 
					WHEN WAIT_LAST_READ => 
						next_state <= WAIT_LAST_MM; 
					WHEN WAIT_LAST_MM => 
						next_state <= CALCULATE_SHIFT; 
 
					WHEN CALCULATE_SHIFT => 
						next_state <= CHANGE_PIXEL_VALUE; 		
 
					WHEN CHANGE_PIXEL_VALUE => 						 
						next_state <= WRITE; 
						IF tmp_w = 1 AND tmp_h = 0 THEN
							next_state <= DONE;
						END IF;

					WHEN WRITE => 
						next_state <= CHANGE_PIXEL_VALUE;
					WHEN DONE => 						
						IF i_start = '0' THEN
							next_state <= RST;
						ELSE
							next_state <= DONE;
						END IF;
				END CASE;
		END PROCESS;
		
		
		PROCESS (i_clk, i_rst)
		--variables for change values
		VARIABLE tmp_value : unsigned(15 DOWNTO 0);
		VARIABLE tmp_diff : unsigned(15 DOWNTO 0);
 
 
		BEGIN
		
		  IF i_clk = '0' then
			o_done <= '0';
			o_en <= '0';
			mm_en <= '0';
 

				CASE state IS
					WHEN RST => 
						heigth <= 0;
						width <= 0;
						tmp_w <= 0;
						tmp_h <= 0;
						out_off <= 0;
						current_address <= 0;
						IF i_start = '1' THEN
							o_en <= '1';
							o_we <= '0';
							o_address <= "0000000000000000";
						END IF;
 
					WHEN ASKHEIGTH => 
						IF (i_data /= "00000000") THEN
							heigth <= to_integer(unsigned(i_data));
							o_en <= '1';
							o_address <= "0000000000000001";
						END IF;
					WHEN ASKWIDTH => 
						o_en <= '1';

						IF (i_data /= "00000000") THEN
							width <= to_integer(unsigned(i_data));
							tmp_h <= heigth - 1;
							current_address <= 2;
							o_address <= "0000000000000010";
						END IF;
					WHEN GETWIDTH => 
						o_en <= '1';

						tmp_w <= width - 1;
						mm_en <= '1';
					WHEN READIMAGE => 
						o_en <= '1';
						mm_en <= '1';
 
						IF tmp_w = 0 THEN
							tmp_w <= width - 1;
							tmp_h <= tmp_h - 1;
							IF tmp_h = 0 THEN
								o_address <= std_logic_vector(to_unsigned(current_address, 16));
							ELSE
								current_address <= current_address + 1;
								o_address <= std_logic_vector(to_unsigned(current_address, 16));
							END IF;
						ELSE
							current_address <= current_address + 1;
							tmp_w <= tmp_w - 1;
							o_address <= std_logic_vector(to_unsigned(current_address, 16));
						END IF;
 
					WHEN WAIT_LAST_READ => 
						mm_en <= '1'; 
 
					WHEN CALCULATE_SHIFT => 
						--resetting value
						o_en <= '1';
						tmp_h <= heigth - 1;
						tmp_w <= width - 1;
						out_off <= current_address - 2;

 
 
						current_address <= 3;
						o_address <= "0000000000000010";
						mm_en <= '0';
						--calculate parameter						
 
					WHEN CHANGE_PIXEL_VALUE => 
						o_en <= '1';

						IF tmp_w = 0 THEN
							tmp_w <= width;
							tmp_h <= tmp_h - 1;
 
						ELSE
							tmp_w <= tmp_w - 1;
						END IF; 
 
						-- change value and write to memory
						o_we <= '1';
 
						tmp_diff(15 DOWNTO 8) := "00000000";
						tmp_diff(7 DOWNTO 0) := unsigned(i_data) - unsigned(min);
						tmp_value := shift_left(tmp_diff, shift_level);
						IF tmp_value(15 DOWNTO 8) = "00000000" THEN
							o_data <= std_logic_vector(tmp_value(7 DOWNTO 0));
						ELSE
							o_data <= "11111111";
						END IF;
 
						o_address <= std_logic_vector(to_unsigned(out_off + current_address, 16));
						IF tmp_w = 0 AND tmp_h = 0 THEN
							o_done <= '1';
							--resetting value
							tmp_h <= heigth - 1;
							tmp_w <= width - 1;
							current_address <= 2;
							mm_en <= '0';
							--o_we <= '0';
						END IF;

					WHEN WRITE => 
						o_en <= '1';
						current_address <= current_address + 1;
						o_address <= std_logic_vector(to_unsigned(current_address, 16));
 
						o_we <= '0';

					WHEN DONE => 
						o_done <= '1';
						
					WHEN OTHERS =>
				END CASE;
            end if;
		END PROCESS;

END Behavioral;
