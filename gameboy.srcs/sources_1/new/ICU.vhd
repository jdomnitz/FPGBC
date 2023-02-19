----------------------------------------------------------------------------------
-- This file is part of FPGBC.
-- FPGBC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
-- FPGBC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with FPGBC. If not, see <https://www.gnu.org/licenses/>.
-- Author: jdomnitz
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library gameboy;
use gameboy.Common.ALL;

use IEEE.NUMERIC_STD.ALL;

entity ICU is
    Port ( clk : in STD_LOGIC;
    	   addr : in STD_LOGIC_VECTOR (15 downto 0);
    	   re : in STD_LOGIC;
    	   we : in STD_LOGIC;
           btn_u : in STD_LOGIC := '0';
           btn_d : in STD_LOGIC := '0';
           btn_l : in STD_LOGIC := '0';
           btn_r : in STD_LOGIC := '0';
           btn_a : in STD_LOGIC := '0';
           btn_b : in STD_LOGIC := '0';
           btn_str : in STD_LOGIC := '0';
           btn_sel : in STD_LOGIC := '0';
           sin : in STD_LOGIC := '1';
           sout : out STD_LOGIC := '1';
           sck : out STD_LOGIC := '1';
           ser : out STD_LOGIC := '0';
           joy : out STD_LOGIC := '0';
           bus_in : in STD_LOGIC_VECTOR (7 downto 0);
           bus_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00");
end ICU;

architecture Behavioral of ICU is

SIGNAL REG_SB : STD_LOGIC_VECTOR (7 downto 0) := x"FF";
SIGNAL REG_JOY : STD_LOGIC_VECTOR (1 downto 0) := "00";
SIGNAL serial_clock_en : STD_LOGIC := '0';
SIGNAL internal_clock : STD_LOGIC := '1';
SIGNAL sbit : STD_LOGIC_VECTOR (2 downto 0) := "000";
SIGNAL DIV : STD_LOGIC_VECTOR (8 downto 0) := "000000000";

begin
process(clk)
begin
	if rising_edge(clk) then
		if (we = '1') then
			if (addr = x"FF00") then --Joypad
				REG_JOY <= bus_in(5 downto 4);
			elsif (addr = x"FF01") then --Serial Write
				print("" & character'val(to_integer(unsigned(bus_in))));
				REG_SB <= bus_in;
			elsif (addr = x"FF02") then --Serial Control
				serial_clock_en <= bus_in(7);
				internal_clock <= bus_in(0);
			end if;
		elsif (re = '1') then
			if (addr = x"FF00") then --Joypad
				bus_out <= "11" & REG_JOY & NOT ((btn_d AND REG_JOY(0)) OR (btn_str AND REG_JOY(1)))
								& NOT ((btn_u AND REG_JOY(0)) OR (btn_sel AND REG_JOY(1)))
								& NOT ((btn_l AND REG_JOY(0)) OR (btn_b AND REG_JOY(1)))
								& NOT ((btn_r AND REG_JOY(0)) OR (btn_a AND REG_JOY(1)));
			elsif (addr = x"FF01") then --Serial Read
			 	bus_out <= REG_SB;
			elsif (addr = x"FF02") then --Serial Control
				bus_out <= serial_clock_en & "111111" & internal_clock;
			else
				bus_out <= x"00";
			end if;
		end if;
		
		sout <= REG_SB(0);
		if serial_clock_en = '1' then
			sck <= NOT DIV(8);
			if DIV = "111111111" then
				if sbit = "111" then
					serial_clock_en <= '0';
					ser <= '1';
				else
					ser <= '0';
				end if;
				REG_SB <= '1' & REG_SB(7 downto 1);
				sbit <= STD_LOGIC_VECTOR(UNSIGNED(sbit) + 1);
			else
					ser <= '0';
			end if;
			DIV <= STD_LOGIC_VECTOR(UNSIGNED(DIV) + 1);
		else
			sck <= '1';
			ser <= '0';
		end if;
	end if;
end process;

joy_int: process(btn_d, btn_str, btn_u, btn_sel, btn_l, btn_b, btn_r, btn_a, REG_JOY)
begin	
	joy <= ((btn_d AND REG_JOY(0)) OR (btn_str AND REG_JOY(1)) OR (btn_u AND REG_JOY(0)) OR (btn_sel AND REG_JOY(1)) OR (btn_l AND REG_JOY(0)) OR (btn_b AND REG_JOY(1)) OR (btn_r AND REG_JOY(0)) OR (btn_a AND REG_JOY(1)));
end process;

end Behavioral;
