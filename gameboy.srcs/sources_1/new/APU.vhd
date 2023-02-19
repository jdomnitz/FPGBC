----------------------------------------------------------------------------------
-- This file is part of FPGBC.
-- FPGBC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
-- FPGBC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with FPGBC. If not, see <https://www.gnu.org/licenses/>.
-- Author: jdomnitz
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity APU is
    Port ( clk : in STD_LOGIC;
    	   rst_n : in STD_LOGIC;
    	   frame_tck : in STD_LOGIC;
    	   we : in STD_LOGIC;
    	   re : in STD_LOGIC;
           addr : in STD_LOGIC_VECTOR (15 downto 0);
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           left : out STD_LOGIC_VECTOR (15 downto 0);
           right : out STD_LOGIC_VECTOR (15 downto 0);
           c1_en : out STD_LOGIC
           );
end APU;

architecture Behavioral of APU is

type wave_mem is ARRAY (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);

SIGNAL NR10 : STD_LOGIC_VECTOR (6 downto 0) := "0000000";
SIGNAL NR11 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR12 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR13 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR14 : STD_LOGIC_VECTOR (6 downto 0) := "0000000";

SIGNAL NR21 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR22 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR23 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR24 : STD_LOGIC_VECTOR (6 downto 0) := "0000000";

SIGNAL NR30 : STD_LOGIC := '0';
SIGNAL NR31 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR32 : STD_LOGIC_VECTOR (6 downto 5) := "00";
SIGNAL NR33 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR34 : STD_LOGIC_VECTOR (6 downto 0) := "0000000";

SIGNAL FF3 : wave_mem;

SIGNAL NR41 : STD_LOGIC_VECTOR (5 downto 0) := "000000";
SIGNAL NR42 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR43 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR44 : STD_LOGIC := '0';

SIGNAL NR50 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR51 : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL NR52 : STD_LOGIC_VECTOR (7 downto 0) := x"00";

SIGNAL frame_num : UNSIGNED(2 downto 0) := "000";

SIGNAL len_trig : STD_LOGIC := '0';
SIGNAL vol_trig : STD_LOGIC := '0';
SIGNAL sweep_trig : STD_LOGIC := '0';

SIGNAL c1_freq : STD_LOGIC_VECTOR(10 downto 0) := "00000000000";
SIGNAL c1_trig : STD_LOGIC;
SIGNAL c1_audio : SIGNED(4 downto 0);

SIGNAL c2_freq : STD_LOGIC_VECTOR(10 downto 0) := "00000000000";
SIGNAL c2_trig : STD_LOGIC;
SIGNAL c2_audio : SIGNED(4 downto 0);

SIGNAL c3_freq : STD_LOGIC_VECTOR(10 downto 0) := "00000000000";
SIGNAL c3_trig : STD_LOGIC;
SIGNAL c3_audio : SIGNED(4 downto 0) := "00000";
SIGNAL wave_sample : STD_LOGIC_VECTOR(3 downto 0) := x"0";
SIGNAL wave_pos : UNSIGNED(4 downto 0) := "00000";

SIGNAL c4_trig : STD_LOGIC;
SIGNAL c4_audio : SIGNED(4 downto 0);

component apu_square
     Port ( clk : in STD_LOGIC;
           len_trig : in STD_LOGIC;
           vol_trig : in STD_LOGIC;
           duty : in STD_LOGIC_VECTOR (1 downto 0);
           envelope : in STD_LOGIC_VECTOR (7 downto 0);
           freq : in STD_LOGIC_VECTOR (10 downto 0);
           start : in STD_LOGIC;
           len_en : in STD_LOGIC;
           len : in STD_LOGIC_VECTOR (5 downto 0) := "000000";
           enabled : out STD_LOGIC;
           audio : out SIGNED(4 downto 0));
end component;

component apu_wave is
     Port ( clk : in STD_LOGIC;
           len_trig : in STD_LOGIC;
           vol : in STD_LOGIC_VECTOR (1 downto 0);
           en : in STD_LOGIC;
           freq : in STD_LOGIC_VECTOR (10 downto 0);
           start : in STD_LOGIC;
           sample : in STD_LOGIC_VECTOR(3 downto 0);
           len_en : in STD_LOGIC;
           len : in STD_LOGIC_VECTOR (7 downto 0) := x"00";
           enabled : out STD_LOGIC;
           pos : buffer UNSIGNED(4 downto 0);
           audio : out SIGNED(4 downto 0));
end component;

component apu_noise is
    Port ( clk : in STD_LOGIC;
           len_trig : in STD_LOGIC;
           vol_trig : in STD_LOGIC;
           start : in STD_LOGIC;
           len : in STD_LOGIC_VECTOR(5 downto 0);
           envelope : in STD_LOGIC_VECTOR (7 downto 0);
           freq : in STD_LOGIC_VECTOR (7 downto 0);
           len_en : in STD_LOGIC := '0';
           audio : out SIGNED(4 downto 0);
           enabled : out STD_LOGIC);
end component;

begin

ch1 : apu_square port map (clk => clk, len_trig => len_trig, vol_trig => vol_trig, duty => NR11(7 downto 6), 
							envelope => NR12, freq => c1_freq, start => c1_trig, len_en => NR14(6),
							len => NR11(5 downto 0), enabled => NR52(0), audio => c1_audio);
							
ch2 : apu_square port map (clk => clk, len_trig => len_trig, vol_trig => vol_trig, duty => NR21(7 downto 6), 
							envelope => NR22, freq => c2_freq, start => c2_trig, len_en => NR24(6),
							len => NR21(5 downto 0), enabled => NR52(1), audio => c2_audio);
							
ch3 : apu_wave port map (clk => clk, len_trig => len_trig, en => NR30,
							vol => NR32(6 downto 5), freq => c3_freq, start => c3_trig, len_en => NR34(6),
							len => NR31, enabled => NR52(2), audio => c3_audio, pos => wave_pos, sample => wave_sample);
							
ch4 : apu_noise port map (clk => clk, len_trig => len_trig, vol_trig => vol_trig,  
							envelope => NR42, freq => NR43, start => c4_trig, len_en => NR44,
							len => NR41(5 downto 0), enabled => NR52(3), audio => c4_audio);

process (clk)

begin
	if rising_edge(clk) then
		if rst_n = '0' then
			NR52(7) <= '0';
			NR51 <= x"00";
			NR50 <= x"00";
			NR11 <= x"00";
			NR21 <= x"00";
			NR30 <= '0';
			NR41 <= "000000";
			c1_trig <= '1';
			c2_trig <= '1';
			c3_trig <= '1';
			c4_trig <= '1';
			c1_en <= '0';
		else
			c1_en <= NR52(0);
			if re='1' then
				case addr is
					when x"FF10" =>
						data_out <= "0" & NR10;
					when x"FF11" =>
						data_out <= NR11;
					when x"FF12" =>
						data_out <= NR12;
					when x"FF13" =>
						data_out <= x"00";
					when x"FF14" =>
						data_out <= "0" & NR14(6) & "000000";
					when x"FF15" => --Unused
						data_out <= x"FF";
					when x"FF16" =>
						data_out <= NR21(7 downto 6) & "000000";
					when x"FF17" =>
						data_out <= NR22;
					when x"FF18" =>
						data_out <= x"00";
					when x"FF19" =>
						data_out <= "0" & NR24(6) & "000000";
					when x"FF1A" =>
						data_out <= NR30 & "0000000";
					when x"FF1B" =>
						data_out <= x"00";
					when x"FF1C" =>
						data_out <= "0" & NR32(6 downto 5) & "00000";
					when x"FF1D" =>
						data_out <= x"00";
					when x"FF1E" =>
						data_out <= "0" & NR34(6) & "000000";
					when x"FF1F" => --Unused
						data_out <= x"FF";
					when x"FF20" =>
						data_out <= x"00";
					when x"FF21" =>
						data_out <= NR42;
					when x"FF22" =>
						data_out <= NR43;
					when x"FF23" =>
						data_out <= "0" & NR44 & "000000";
					when x"FF24" =>
						data_out <= NR50;
					when x"FF25" =>
						data_out <= NR51;
					when x"FF26" =>
						data_out <= NR52;
					when others =>
						if addr(15 downto 4) = x"FF3" then
							if NR52(2) = '0' then
								data_out <= FF3(to_integer(unsigned(addr(3 downto 0))));
							else
								data_out <= x"FF";
							end if;
						elsif addr(15 downto 4) = x"FF2" then
							data_out <= x"FF";
						else	
							data_out <= x"00";
						end if;
				end case;
			end if;
			if we='1' then
				case addr is
					when x"FF10" =>
						NR10 <= data_in(6 downto 0);
					when x"FF11" =>
						NR11 <= data_in;
					when x"FF12" =>
						NR12 <= data_in;
					when x"FF13" =>
						NR13 <= data_in;
						c1_freq <= NR14(2 downto 0) & data_in;
					when x"FF14" =>
						NR14 <= data_in(6 downto 0) AND "1000111";
						c1_freq <= data_in(2 downto 0) & NR13;
					when x"FF16" =>
						NR21 <= data_in;
					when x"FF17" =>
						NR22 <= data_in;
					when x"FF18" =>
						NR23 <= data_in;
						c2_freq <= NR24(2 downto 0) & data_in;
					when x"FF19" =>
						NR24 <= data_in(6 downto 0) AND "1000111";
						c2_freq <= data_in(2 downto 0) & NR23;
					when x"FF1A" =>
						NR30 <= data_in(7);
					when x"FF1B" =>
						NR31 <= data_in;
					when x"FF1C" =>
						NR32(6 downto 5) <= data_in(6 downto 5);
					when x"FF1D" =>
						NR33 <= data_in;
						c3_freq <= NR34(2 downto 0) & data_in;
					when x"FF1E" =>
						NR34 <= data_in(6 downto 0) AND "1000111";
						c3_freq <= data_in(2 downto 0) & NR33;
					when x"FF20" =>
						NR41(5 downto 0) <= data_in(5 downto 0);
					when x"FF21" =>
						NR42 <= data_in;
					when x"FF22" =>
						NR43 <= data_in;
					when x"FF23" =>
						NR44 <= data_in(6);
					when x"FF24" =>
						NR50 <= data_in;
					when x"FF25" =>
						NR51 <= data_in;
					when x"FF26" =>
						NR52(7) <= data_in(7);
					when others =>
						if addr(15 downto 4) = x"FF3" then
							FF3(to_integer(unsigned(addr(3 downto 0)))) <= data_in;
						end if;
				end case;
			end if;
			if addr = x"FF14" then
				c1_trig <= data_in(7) AND we;
			else
				c1_trig <= '0';
			end if;
			if addr = x"FF19" then
				c2_trig <= data_in(7) AND we;
			else
				c2_trig <= '0';
			end if;
			if addr = x"FF23" then
				c3_trig <= data_in(7) AND we;
			else
				c3_trig <= '0';
			end if;
			if addr = x"FF23" then
				c4_trig <= data_in(7) AND we;
			else
				c4_trig <= '0';
			end if;
			if NR52(2) = '1' then
				if wave_pos(0) = '0' then
					wave_sample <= FF3(to_integer(UNSIGNED(wave_pos(4 downto 1))))(7 downto 4);
				else
					wave_sample <= FF3(to_integer(UNSIGNED(wave_pos(4 downto 1))))(3 downto 0);
				end if;
			end if;
		end if;
	end if;
end process;

frame_sequencer: process (clk)
begin
	if rising_edge(clk) then
		if NR52(7) = '1' AND frame_tck = '1' then
			len_trig <= frame_num(0);
			if frame_num = 7 then
				vol_trig <= '1';
			else
				vol_trig <= '0';
			end if;
			if frame_num = 0 OR frame_num = 4 then
				sweep_trig <= '1';
			else
				sweep_trig <= '0';
			end if;
			frame_num <= frame_num + 1;
		else
			len_trig <= '0';
			vol_trig <= '0';
			sweep_trig <= '0';
		end if;
	end if;
end process;

mixer: process (c1_audio, c2_audio, c3_audio, c4_audio, NR52, NR51)
variable so1 : SIGNED (7 downto 0); --right
variable so2 : SIGNED (7 downto 0); --left
begin
	so1 := x"00";
	so2 := x"00";
	if NR52(7) = '1' then
		if NR51(7) = '1' then
			so2 := so2 + c4_audio;
		end if;
		if NR51(6) = '1' then
			so2 := so2 + c3_audio;
		end if;
		if NR51(5) = '1' then
			so2 := so2 + c2_audio;
		end if;
		if NR51(4) = '1' then
			so2 := so2 + c1_audio;
		end if;
		if NR51(3) = '1' then
			so1 := so1 + c4_audio;
		end if;
		if NR51(2) = '1' then
			so1 := so1 + c3_audio;
		end if;
		if NR51(1) = '1' then
			so1 := so1 + c2_audio;
		end if;
		if NR51(0) = '1' then
			so1 := so1 + c1_audio;
		end if;
	end if;
	left <= STD_LOGIC_VECTOR(so2 & x"00"); --STD_LOGIC_VECTOR(so2 * (SIGNED(UNSIGNED(NR50(6 downto 4)) + 1))) & "00000"
	right <= STD_LOGIC_VECTOR(so1 & x"00"); --STD_LOGIC_VECTOR(so1 * (SIGNED(UNSIGNED(NR50(2 downto 0)) + 1))) & "00000"
end process;

end Behavioral;
