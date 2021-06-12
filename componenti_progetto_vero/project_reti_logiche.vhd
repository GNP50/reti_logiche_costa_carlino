LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

ENTITY max_min IS
	PORT (
		i_clk : IN STD_LOGIC;
		i_rst : IN STD_LOGIC;
		i_en : IN STD_LOGIC;
		i_current_pixel_value : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		o_min : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		o_max : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		o_shift : OUT INTEGER RANGE 0 TO 8
	);
END max_min;

ARCHITECTURE mm_behavioral OF max_min IS
	SIGNAL max_s : INTEGER RANGE 0 TO 255;
	SIGNAL min_s : INTEGER RANGE 0 TO 255;
	SIGNAL delta : STD_LOGIC_VECTOR (8 DOWNTO 0);
BEGIN
	PROCESS (i_clk, i_rst, i_en, min_s, max_s)
	BEGIN
		IF (i_rst = '1') THEN
			min_s <= 255;
			max_s <= 0;
		ELSIF rising_edge(i_clk) AND i_en = '1' THEN
			IF (unsigned(i_current_pixel_value) > max_s) THEN
				max_s <= to_integer(unsigned(i_current_pixel_value));
			END IF;
			IF (unsigned(i_current_pixel_value) < min_s) THEN
				min_s <= to_integer(unsigned(i_current_pixel_value));
			END IF;
		END IF;
	END PROCESS;

	o_max <= STD_LOGIC_VECTOR(to_unsigned(max_s, 8));
	o_min <= STD_LOGIC_VECTOR(to_unsigned(min_s, 8));

	delta <= STD_LOGIC_VECTOR(to_unsigned(max_s - min_s + 1, 9));

	o_shift <= 8 WHEN delta <= 1 ELSE
		7 WHEN delta > 1 AND delta <= 3 ELSE
		6 WHEN delta > 3 AND delta <= 7 ELSE
		5 WHEN delta > 7 AND delta <= 15 ELSE
		4 WHEN delta > 15 AND delta <= 31 ELSE
		3 WHEN delta > 31 AND delta <= 63 ELSE
		2 WHEN delta > 63 AND delta <= 127 ELSE
		1 WHEN delta > 127 AND delta <= 255 ELSE
		0;

END mm_behavioral;



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY counter IS
	PORT (
		i_clk : IN STD_LOGIC;
		i_rst : IN STD_LOGIC;
		i_en : IN STD_LOGIC;
		i_width : IN INTEGER RANGE 0 TO 255;
		i_height : IN INTEGER RANGE 0 TO 255;
		i_offset : IN INTEGER RANGE 0 TO 65535;
		o_count : OUT INTEGER RANGE 0 TO 65535;
		o_end : OUT STD_LOGIC
	);
END counter;

ARCHITECTURE counter_behavioral OF counter IS
	SIGNAL cur_w : INTEGER RANGE 0 TO 255;
	SIGNAL cur_h : INTEGER RANGE 0 TO 255;
	SIGNAL cur_count : INTEGER RANGE 0 TO 65535;
	SIGNAL next_w : INTEGER RANGE 0 TO 255;
	SIGNAL next_h : INTEGER RANGE 0 TO 255;
	SIGNAL next_count : INTEGER RANGE 0 TO 65535;
	SIGNAL int_end : STD_LOGIC;
BEGIN
	PROCESS (i_clk, i_rst, int_end, i_en)
	BEGIN
		IF (i_rst = '1') THEN
			cur_count <= 0;
			cur_w <= 1;
			cur_h <= 1;
		ELSIF rising_edge(i_clk) AND i_clk = '1' AND i_en = '1' AND int_end = '0' THEN
			cur_count <= next_count;
			cur_w <= next_w;
			cur_h <= next_h;
		END IF;
	END PROCESS;
	next_count <= cur_count WHEN int_end = '1' ELSE cur_count + 1;

	next_w <=
		cur_w + 1 WHEN cur_w < i_width ELSE
		1;

	next_h <=
		cur_h WHEN cur_w /= i_width ELSE
		cur_h + 1;

	int_end <= '1' WHEN (cur_w = i_width AND cur_h = i_height) OR i_width = 0 OR i_height = 0 ELSE '0';

	o_count <= i_offset + cur_count;
	o_end <= int_end;

END counter_behavioral;




LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY project_reti_logiche IS
	PORT (
		i_clk : IN STD_LOGIC;
		i_rst : IN STD_LOGIC;
		i_start : IN STD_LOGIC;
		i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		o_done : OUT STD_LOGIC;
		o_en : OUT STD_LOGIC;
		o_we : OUT STD_LOGIC;
		o_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END project_reti_logiche;

ARCHITECTURE Behavioral OF project_reti_logiche IS
	TYPE s IS(RST, START_ASK_NCOL, READ_NROW, PREPARE_READIMAGE, READ_NCOL_ASK_NROW, READIMAGE, WAIT_LAST_READ, WAIT_LAST_MM, CALCULATE_SHIFT, WRITE_NEW_VALUE, READ_OLD_VALUE, DONE);
	SIGNAL state, next_state : s;

	COMPONENT max_min
		PORT (
			i_clk : IN STD_LOGIC;
			i_rst : IN STD_LOGIC;
			i_en : IN STD_LOGIC;
			i_current_pixel_value : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			o_min : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			o_max : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			o_shift : OUT INTEGER RANGE 0 TO 8
		);
	END COMPONENT;
	COMPONENT counter IS
		PORT (
			i_clk : IN STD_LOGIC;
			i_rst : IN STD_LOGIC;
			i_en : IN STD_LOGIC;
			i_width : IN INTEGER RANGE 0 TO 255;
			i_height : IN INTEGER RANGE 0 TO 255;
			i_offset : IN INTEGER RANGE 0 TO 65535;
			o_count : OUT INTEGER RANGE 0 TO 65535;
			o_end : OUT STD_LOGIC
		);
	END COMPONENT counter;

	SIGNAL mm_en : STD_LOGIC;
	SIGNAL width : INTEGER RANGE 0 TO 255;
	SIGNAL height : INTEGER RANGE 0 TO 255;
	SIGNAL read_address : INTEGER RANGE 0 TO 65535;
	SIGNAL write_address : INTEGER RANGE 0 TO 65535;
	SIGNAL max : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL min : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL out_offset : INTEGER RANGE 0 TO 65535;
	SIGNAL shift_level : INTEGER RANGE 0 TO 8;
	SIGNAL end_read : STD_LOGIC;
	SIGNAL read_rst : STD_LOGIC;
	SIGNAL write_rst : STD_LOGIC;
	SIGNAL read_en : STD_LOGIC;
	SIGNAL write_en : STD_LOGIC;
	SIGNAL shifted_value : unsigned(15 DOWNTO 0);
	SIGNAL current_diff : unsigned(15 DOWNTO 0);
	SIGNAL mm_rst : STD_LOGIC;
BEGIN
	mm : max_min PORT MAP(i_clk => i_clk, i_rst => mm_rst, i_en => mm_en, i_current_pixel_value => i_data, o_min => min, o_max => max, o_shift => shift_level);
	mm_rst <=
		'1' WHEN i_rst = '1' OR state = RST ELSE
		'0';
	mm_en <=
		'1' WHEN state = READIMAGE OR state = WAIT_LAST_READ ELSE
		'0';

	counter_read : counter PORT MAP(i_clk => i_clk, i_rst => read_rst, i_en => read_en, i_width => width, i_height => height, i_offset => 2, o_count => read_address, o_end => end_read);
	read_rst <=
		'1' WHEN i_rst = '1' OR state = RST OR state = WAIT_LAST_MM ELSE
		'0';
	read_en <=
		'1' WHEN (state = READIMAGE OR state = PREPARE_READIMAGE OR state = WRITE_NEW_VALUE) ELSE
		'0';

	counter_write : counter PORT MAP(i_clk => i_clk, i_rst => write_rst, i_en => write_en, i_width => width, i_height => height, i_offset => out_offset, o_count => write_address, o_end => OPEN);
	write_en <=
		'1' WHEN (state = READ_OLD_VALUE) ELSE
		'0';
	write_rst <=
		'1' WHEN i_rst = '1' OR state = RST ELSE
		'0';

	o_en <= '1' WHEN (state = START_ASK_NCOL OR state = READ_NCOL_ASK_NROW OR state = READ_NROW OR state = PREPARE_READIMAGE OR state = READIMAGE OR state = WAIT_LAST_READ OR state = WAIT_LAST_MM OR state = WRITE_NEW_VALUE OR state = READ_OLD_VALUE) ELSE '0';

	o_address <=
		"0000000000000000" WHEN state = RST OR state = START_ASK_NCOL ELSE
		"0000000000000001" WHEN state = READ_NCOL_ASK_NROW ELSE
		STD_LOGIC_VECTOR(to_unsigned(read_address, 16)) WHEN state = READ_NROW OR state = PREPARE_READIMAGE OR state = READIMAGE OR state = READ_OLD_VALUE OR state = CALCULATE_SHIFT OR state = WAIT_LAST_MM ELSE
		STD_LOGIC_VECTOR(to_unsigned(write_address, 16));
	o_we <= '1' WHEN state = WRITE_NEW_VALUE ELSE '0';
	
	current_diff(15 DOWNTO 8) <= "00000000";
	current_diff(7 DOWNTO 0) <= unsigned(i_data) - unsigned(min);
	shifted_value <= current_diff SLL shift_level;
	o_data <= "00000000" WHEN state /= WRITE_NEW_VALUE AND state /= READ_OLD_VALUE ELSE STD_LOGIC_VECTOR(shifted_value(7 DOWNTO 0)) WHEN shifted_value(15 DOWNTO 8) = "00000000" ELSE "11111111";
	
	o_done <= '1' WHEN state = DONE ELSE '0';

	PROCESS (i_clk, i_rst)
	BEGIN
		IF (i_rst = '1') THEN
			state <= RST;
		ELSIF rising_edge(i_clk) AND i_clk = '1' THEN
			state <= next_state;
		END IF;
	END PROCESS;

	PROCESS (i_clk, i_rst, state, i_start, end_read)
	BEGIN
		next_state <= state;
		CASE state IS
			WHEN RST =>
				IF i_start = '1' THEN
					next_state <= START_ASK_NCOL;
				END IF;
			WHEN START_ASK_NCOL =>
				next_state <= READ_NCOL_ASK_NROW;
			WHEN READ_NCOL_ASK_NROW =>
				next_state <= READ_NROW;
			WHEN READ_NROW =>
				next_state <= PREPARE_READIMAGE;
			WHEN PREPARE_READIMAGE =>
			IF end_read = '1' and not (width=1 and height = 1) THEN
			     next_state<=done;
			     else
				next_state <= READIMAGE;
				end if;
			WHEN READIMAGE =>
				IF end_read = '1' THEN
					next_state <= WAIT_LAST_READ;
				ELSE
					next_state <= READIMAGE;
				END IF;
			WHEN WAIT_LAST_READ =>
				next_state <= WAIT_LAST_MM;
			WHEN WAIT_LAST_MM =>
				next_state <= CALCULATE_SHIFT;
			WHEN CALCULATE_SHIFT =>
				next_state <= WRITE_NEW_VALUE;
			WHEN WRITE_NEW_VALUE =>
				next_state <= READ_OLD_VALUE;
				IF end_read = '1' THEN
					next_state <= DONE;
				END IF;
			WHEN READ_OLD_VALUE =>
				next_state <= WRITE_NEW_VALUE;
			WHEN DONE =>
				IF i_start = '0' THEN
					next_state <= RST;
				ELSE
					next_state <= DONE;
				END IF;
		END CASE;
	END PROCESS;

	PROCESS (i_clk, i_rst)
	BEGIN
		IF rising_edge(i_clk) AND i_clk = '1' THEN
			CASE state IS
				WHEN RST =>
					height <= 0;
					width <= 0;
					out_offset <= 0;
				WHEN READ_NCOL_ASK_NROW =>
					height <= to_integer(unsigned(i_data));
				WHEN READ_NROW =>
					width <= to_integer(unsigned(i_data));
				WHEN WAIT_LAST_READ =>
					out_offset <= read_address + 1;
				WHEN OTHERS =>
			END CASE;
		END IF;
	END PROCESS;

END Behavioral;
