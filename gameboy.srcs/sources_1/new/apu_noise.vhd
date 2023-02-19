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

entity apu_noise is
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
end apu_noise;

architecture Behavioral of apu_noise is
constant pre_root : UNSIGNED(13 downto 0) := "00000000000001";

SIGNAL waveform : STD_LOGIC := '0';
SIGNAL duty_cyc : STD_LOGIC := '0';
SIGNAL cur_vol : STD_LOGIC_VECTOR(3 downto 0) := x"0";
SIGNAL vol_cnt : STD_LOGIC_VECTOR(2 downto 0) := "000";
SIGNAL len_cnt : STD_LOGIC_VECTOR(5 downto 0) := "000000";
SIGNAL len_lmt : STD_LOGIC := '0';
SIGNAL lfsr : STD_LOGIC_VECTOR(14 downto 0) := "111111111111111";
SIGNAL freq_cnt : STD_LOGIC_VECTOR(4 downto 0) := "00000";
SIGNAL prescaler : STD_LOGIC_VECTOR(13 downto 0) := "00000000000000";

begin

freq_timer : process (clk)
begin
	if rising_edge(clk) then
		if start = '1' then
			freq_cnt <= "00000";
		else
			if (freq(2 downto 0)="000" AND freq_cnt="00010") OR (freq(2 downto 0) /= "000" AND freq_cnt = (freq(2 downto 0) & "00")) then
				duty_cyc <= '1'; --FIXME: This is double the correct rate
				freq_cnt <= "00000";
			else
				duty_cyc <= '0';
				freq_cnt <= STD_LOGIC_VECTOR(UNSIGNED(freq_cnt) + 1);
			end if;
		end if;
	end if;
end process;

wave_gen : process (clk)
begin
	if rising_edge(clk) then
		if start='1' then
			lfsr <= "111111111111111";
		elsif duty_cyc = '1' then
			if prescaler = STD_LOGIC_VECTOR(shift_left(pre_root, to_integer(UNSIGNED(freq(7 downto 4))))) then
				if freq(3) = '1' then
					lfsr <= (lfsr(0) XOR lfsr(1)) & lfsr(14 downto 8) & (lfsr(0) XOR lfsr(1)) & lfsr(6 downto 1);
				else
					lfsr <= (lfsr(0) XOR lfsr(1)) & lfsr(14 downto 1);
				end if;
				prescaler <= "00000000000000";
			else
				prescaler <= STD_LOGIC_VECTOR(UNSIGNED(prescaler) + 1);
			end if;
			waveform <= NOT lfsr(0);
		end if;
	end if;
end process;

shaper : process (clk)
variable vol_tgt : STD_LOGIC_VECTOR(2 downto 0) := "000";
begin
	if rising_edge(clk) then
		if start = '1' then
			cur_vol <= envelope(7 downto 4);
			vol_cnt <= "000";
		else
			if vol_trig = '1' then
				if envelope(2 downto 0)="000" then
					vol_tgt := "111";
				else
					vol_tgt := envelope(2 downto 0);
				end if;
				if vol_cnt = vol_tgt then
					vol_cnt <= "000";
					if (envelope(3) = '1') AND (cur_vol /= x"F") then --addition
						cur_vol <= STD_LOGIC_VECTOR(UNSIGNED(cur_vol) + 1);
					elsif (envelope(3) = '0') AND (cur_vol /= x"0") then --subtraction
						cur_vol <= STD_LOGIC_VECTOR(UNSIGNED(cur_vol) - 1);
					end if;
				else
					vol_cnt <= STD_LOGIC_VECTOR(UNSIGNED(vol_cnt) + 1);
				end if;
			end if;
		end if;
	end if;
end process;

limiter : process (clk)
begin
	if rising_edge(clk) then
		if start = '1' then
			if len_cnt = "111111" then
				len_cnt <= len;
			end if;
			len_lmt <= '0';
--		elsif len_trig = '1' then
--			len_cnt <= len;
		else
			if len_trig = '1' then
				if len_en='0' then
					len_lmt <= '0';
				elsif len_cnt = "111111" then
					len_lmt <= '1';
				else
					len_cnt <= STD_LOGIC_VECTOR(UNSIGNED(len_cnt) + 1);
					len_lmt <= '0';
				end if;
			end if;
		end if;
	end if;
end process;

dac : process (waveform, cur_vol, envelope, len_lmt)
begin
	if envelope(7 downto 3) /= "00000" AND len_lmt='0' then
		enabled <= '1';
		if cur_vol = "0000" then
			audio <= "00000";
		elsif waveform = '0' then
			audio <= SIGNED("0" & cur_vol);
		else
			audio <= SIGNED("1" & STD_LOGIC_VECTOR(UNSIGNED(NOT cur_vol) + 1));
		end if;
	else
		enabled <= '0';
		audio <= "00000";
	end if;
end process;

end Behavioral;
