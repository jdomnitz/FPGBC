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

entity apu_wave is
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
end apu_wave;

architecture Behavioral of apu_wave is

SIGNAL freq_cnt : STD_LOGIC_VECTOR(11 downto 0) := "111111111111";
SIGNAL waveform : STD_LOGIC_VECTOR(3 downto 0) := x"0";

SIGNAL len_cnt : STD_LOGIC_VECTOR(7 downto 0) := x"00";
SIGNAL len_lmt : STD_LOGIC := '0';

begin

freq_timer : process (clk)
begin
	if rising_edge(clk) then
		if start = '1' then
			freq_cnt <= freq & "0";
			pos <= "00000";
		else
			if freq_cnt = "111111111111" then
				freq_cnt <= freq & "0";
				waveform <= sample;
			else
				if (freq_cnt = freq & "0") then
					pos <= pos + 1;
				end if;
				freq_cnt <= STD_LOGIC_VECTOR(UNSIGNED(freq_cnt) + 1);
			end if;
		end if;
	end if;
end process;

limiter : process (clk)
begin
	if rising_edge(clk) then
		if start = '1' then
			if len_cnt = "11111111" then
				len_cnt <= len;
			end if;
			len_lmt <= '0';
		else
			if len_trig = '1' then
				if len_en='0' then
					len_lmt <= '0';
				elsif len_cnt = "11111111" then
					len_lmt <= '1';
				else
					len_cnt <= STD_LOGIC_VECTOR(UNSIGNED(len_cnt) + 1);
					len_lmt <= '0';
				end if;
			end if;
		end if;
	end if;
end process;

dac : process (waveform, vol, len_lmt, en)
variable atten_wave : STD_LOGIC_VECTOR(3 downto 0);
begin
	if en = '1' AND len_lmt='0' then
		enabled <= '1';
		case vol is
			when "01" =>
				audio <= SIGNED(waveform & "0");
			when "10" =>
				audio <= SIGNED("00" & waveform(3 downto 2) & "0");
			when "11" =>
				audio <= SIGNED(shift_right(UNSIGNED("0" & waveform), 3));
			when others =>
				audio <= "00000";
		end case;
	else
		enabled <= '0';
		audio <= "00000";
	end if;
end process;

end Behavioral;
