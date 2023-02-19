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

library gameboy;
use gameboy.Common.ALL;

entity INT is
     Port ( clk : in STD_LOGIC;
    	   addr : in STD_LOGIC_VECTOR (15 downto 0);
    	   re : in STD_LOGIC;
    	   we : in STD_LOGIC;
    	   vblk : in STD_LOGIC;
           lcdc : in STD_LOGIC;
           tmr : in STD_LOGIC;
           ser : in STD_LOGIC;
           joy : in STD_LOGIC;
           bus_in : in STD_LOGIC_VECTOR (7 downto 0);
           bus_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           int_ack : in STD_LOGIC;
           int_out : out STD_LOGIC := '0');
end INT;

architecture Behavioral of INT is
SIGNAL REG_IE : STD_LOGIC_VECTOR (4 downto 0) := "00000";
SIGNAL REG_IF : STD_LOGIC_VECTOR (4 downto 0) := "00000";
SIGNAL INT : STD_LOGIC_VECTOR (3 downto 0) := x"0";
SIGNAL last_int : STD_LOGIC := '0';

begin

process(clk, int_ack, tmr, vblk, lcdc, REG_IE, REG_IF)
begin
	if rising_edge(clk) then
		if (int_ack = '1') then
			bus_out <= "0" & INT & "000";
		elsif (we = '1') then
			if (addr = x"FF0F") then
				echo("IF: " & to_HexChar("000" & reg_IF));
				REG_IF <= bus_in(4 downto 0);
			elsif (addr = x"FFFF") then
				REG_IE <= bus_in(4 downto 0);
			end if;
		elsif (re = '1') then
			if (addr = x"FF0F") then
				bus_out <= "000" & REG_IF;
			else
				bus_out <= x"00";
			end if;
		end if;
		
		if joy = '1' then
			REG_IF(4) <= '1';
		end if;
		if ser = '1' then
			REG_IF(3) <= '1';
		end if;
		if tmr = '1' then
			REG_IF(2) <= '1';
		end if;
		if lcdc = '1' then
			REG_IF(1) <= '1';
		end if;
		if vblk = '1' then
			REG_IF(0) <= '1';
		end if;
		
		if (REG_IE(0) = '1' AND REG_IF(0) = '1') then
			int_out <= '1';
		elsif (REG_IE(1) = '1' AND REG_IF(1) = '1') then
			int_out <= '1';
		elsif (REG_IE(2) = '1' AND REG_IF(2) = '1') then
			int_out <= '1';
		elsif (REG_IE(3) = '1' AND REG_IF(3) = '1') then
			int_out <= '1';
		elsif (REG_IE(4) = '1' AND REG_IF(4) = '1') then
			int_out <= '1';
		else
			int_out <= '0';
		end if;
		
		if int_ack = '1' AND last_int='0' then
			if (REG_IE(0) = '1' AND REG_IF(0) = '1') then
				INT <= x"8";
			elsif (REG_IE(1) = '1' AND REG_IF(1) = '1') then
				INT <= x"9";
			elsif (REG_IE(2) = '1' AND REG_IF(2) = '1') then
				INT <= x"A";
			elsif (REG_IE(3) = '1' AND REG_IF(3) = '1') then
				INT <= x"B";
			elsif (REG_IE(4) = '1' AND REG_IF(4) = '1') then
				INT <= x"C";
			end if;
		end if;
		if int_ack='0' AND last_int='1' then
			REG_IF(to_integer(unsigned(INT(2 downto 0)))) <= '0';
		end if;
		last_int <= int_ack;
	end if;
end process;

end Behavioral;
