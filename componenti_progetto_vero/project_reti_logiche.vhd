LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

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


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

ENTITY counter IS
	PORT 
	(
		i_clk : IN std_logic;
		i_rst : IN std_logic;
		i_en : IN std_logic;
		i_width : IN INTEGER RANGE 0 TO 255 := 0;
		i_height : IN INTEGER RANGE 0 TO 255 := 0;
		i_offset : IN INTEGER RANGE 0 TO 65535 := 0;
		o_count : OUT INTEGER RANGE 0 TO 65535 := 0;
		o_end : OUT std_logic
	);
END counter;

ARCHITECTURE Behavioral OF counter IS
	SIGNAL cur_w : INTEGER RANGE 0 TO 255;
	SIGNAL cur_h : INTEGER RANGE 0 TO 255;
	SIGNAL cur_count : INTEGER RANGE 0 TO 65535 := 0;
	SIGNAL next_w: INTEGER RANGE 0 TO 65535 := 0;
	SIGNAL next_h: INTEGER RANGE 0 TO 65535 := 0;
	SIGNAL next_count: INTEGER RANGE 0 TO 65535 := 0;
	SIGNAL int_end: std_logic;
BEGIN    
	PROCESS (i_clk, i_rst)
	BEGIN
        if(i_rst='1') then
            cur_count <= 0;
            cur_w<=1;
            cur_h<=1;
        ELSIF rising_edge(i_clk) and i_clk='1' and i_en ='1' and int_end/='1' THEN 
            cur_count<=next_count;
            cur_w<=next_w;
            cur_h<=next_h;
        end if;	
	END PROCESS;
	
	next_count <= cur_count when int_end='1' else cur_count+1 when i_en='1' else cur_count;
	next_w <= 
	    cur_w when int_end ='1' or i_en = '0' else
	    cur_w+1 when cur_w<i_width else 
	    1;
	next_h <= 
	    cur_h when cur_w /= i_width or int_end='1' else	
	    cur_h+1 when i_en='1' else 
	    cur_h;
	
	int_end <='1' when (cur_w = i_width and cur_h = i_height) or i_width=0 or i_height=0 else '0';
	
	o_count <=i_offset + cur_count;
	o_end<=int_end when i_en='1' else '0';

END Behavioral;


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY project_reti_logiche IS
    PORT (
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
    TYPE s IS(RST, START, ASKWIDTH, GETWIDTH, ASKHEIGHT, READIMAGE, WAIT_LAST_READ, WAIT_LAST_MM, CALCULATE_SHIFT, CHANGE_PIXEL_VALUE, WRITE, DONE); 
    SIGNAL state, next_state : s := RST;

    COMPONENT max_min
        PORT (
            i_clk : IN std_logic;
            i_rst : IN std_logic;
            i_en : IN std_logic;
            i_current_pixel_value : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            o_min : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            o_max : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            o_shift : OUT INTEGER RANGE 0 TO 8
        );
    END COMPONENT;
    component counter IS
	PORT 
	(
		i_clk : IN std_logic;
		i_rst : IN std_logic;
		i_en : IN std_logic;
		i_width : IN INTEGER RANGE 0 TO 255 := 0;
		i_height : IN INTEGER RANGE 0 TO 255 := 0;
		i_offset : IN INTEGER RANGE 0 TO 65535 := 0;
		o_count : OUT INTEGER RANGE 0 TO 65535 := 0;
		o_end : OUT std_logic
	);
    END component counter;

    SIGNAL mm_en : std_logic := '0';
    SIGNAL width : INTEGER RANGE 0 TO 255 := 0;
    SIGNAL height : INTEGER RANGE 0 TO 255 := 0;
    SIGNAL read_address : INTEGER RANGE 0 TO 65535 := 0;
    SIGNAL write_address : INTEGER RANGE 0 TO 65535 := 0;
    SIGNAL max : std_logic_vector(7 DOWNTO 0);
    SIGNAL min : std_logic_vector(7 DOWNTO 0);
    SIGNAL out_off : INTEGER RANGE 0 TO 65535 := 0;
    SIGNAL int_rst : std_logic;
    SIGNAL shift_level : INTEGER RANGE 0 TO 8 := 0;
    SIGNAL end_read: std_logic;
    SIGNAL increment_read_clk: std_logic;
    SIGNAL increment_write_clk: std_logic;
    SIGNAL read_rst: std_logic;
    SIGNAL write_rst: std_logic;
    SIGNAL read_en: std_logic;
    SIGNAL write_en: std_logic;
    SIGNAL tmp_value : unsigned(15 DOWNTO 0);
    SIGNAL tmp_diff : unsigned(15 DOWNTO 0);
BEGIN
    mm : max_min
    PORT MAP(i_clk => i_clk, i_rst => int_rst, i_en => mm_en, i_current_pixel_value => i_data, o_min => min, o_max => max, o_shift => shift_level);
    
    counter_read: counter port map (i_clk=>i_clk,i_rst=>read_rst,i_en=>read_en,i_width=>width,i_height=>height,i_offset=>2,o_count=>read_address,o_end=>end_read); 
    counter_write: counter port map (i_clk=>i_clk,i_rst=>write_rst,i_en=>write_en,i_width=>width,i_height=>height,i_offset=>out_off,o_count=>write_address,o_end=>open); 
    
    increment_read_clk <= 
        '1' when i_clk ='1' and (state = READIMAGE or state = GETWIDTH or state = CHANGE_PIXEL_VALUE) else 
        '0';
    
    read_en<=
        '1' when (state = READIMAGE or state = GETWIDTH or state = CHANGE_PIXEL_VALUE) else 
        '0';
    
    increment_write_clk <= 
        '1' when i_clk ='1' and (state = WRITE) else 
        '0';
        
    write_en<=
        '1' when (state = WRITE) else 
        '0';
    read_rst <= 
        '1' when i_rst='1' or state = RST or state = WAIT_LAST_MM else 
        '0';
        
    write_rst <= 
        '1' when i_rst='1' or state = RST else 
        '0';
 
    int_rst <= '1' WHEN (state = RST OR i_rst = '1') ELSE '0';
    
    o_done <= '1' when state = DONE else '0';
    o_en <= '1' when (state = START OR state = ASKheight OR state = ASKWIDTH OR state = GETWIDTH OR state = READIMAGE OR state = WAIT_LAST_READ OR state = WAIT_LAST_MM OR state = CHANGE_PIXEL_VALUE OR state = WRITE) else '0';
 
    o_we <= '1' when state = CHANGE_PIXEl_VALUE else '0';
 
    PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            state <= RST;
        ELSIF rising_edge(i_clk) THEN
            state <= next_state;
        END IF;
    END PROCESS;
 
    o_address <= 
        "0000000000000000" when state = RST OR state = START else 
        "0000000000000001" when state = ASKheight else 
        std_logic_vector(to_unsigned(read_address,16)) when state = ASKWIDTH or state = GETWIDTH or state = READIMAGE or state = WRITE or state = CALCULATE_SHIFT or state = WAIT_LAST_MM else 
        std_logic_vector(to_unsigned(write_address,16));

    PROCESS (i_clk, i_rst) 
        BEGIN
            next_state <= state;
            CASE state IS
                WHEN RST => 
                    IF i_start = '1' THEN
                        next_state <= START;
                    END IF;
                WHEN START => 
                    next_state <= ASKheight;
                WHEN ASKheight => 
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
                    IF end_read='1' THEN
                        next_state <= WAIT_LAST_READ;
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
                    IF end_read='1' THEN
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
 
        mm_en <= '1' WHEN state = ASKWIDTH OR state = GETWIDTH OR state = READIMAGE OR state = WAIT_LAST_READ ELSE '0';
        
        tmp_diff(15 DOWNTO 8) <= "00000000";
        tmp_diff(7 DOWNTO 0) <= unsigned(i_data) - unsigned(min);
        tmp_value <= shift_left(tmp_diff, shift_level);
        
        o_data <= std_logic_vector(tmp_value(7 DOWNTO 0)) when tmp_value(15 DOWNTO 8) = "00000000" else "11111111";
        
        PROCESS (i_clk, i_rst)
            BEGIN
                IF rising_edge(i_clk) THEN
                    CASE state IS
                        WHEN RST => 
                            height <= 0;
                            width <= 0;
                            out_off <= 0;
                        WHEN ASKheight => 
                              height <= to_integer(unsigned(i_data));
                        WHEN ASKWIDTH => 
                              width <= to_integer(unsigned(i_data));
                        WHEN WAIT_LAST_READ => 
                            out_off <= read_address+1;                       
                        WHEN OTHERS => 
                    END CASE;
                END IF;
            END PROCESS;

END Behavioral;
