----------------------------------------------------------------------------------
-- This file is part of FPGBC.
-- FPGBC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
-- FPGBC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with FPGBC. If not, see <https://www.gnu.org/licenses/>.
-- Author: jdomnitz
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

entity HRAM is
port(
 clk: in STD_LOGIC;
 addr: in STD_LOGIC_VECTOR(6 downto 0);
 data_in: in STD_LOGIC_VECTOR(7 downto 0);
 en: in STD_LOGIC;
 wr: in STD_LOGIC;
 data_out: out STD_LOGIC_VECTOR(7 downto 0) := x"00"
);
end HRAM;

architecture Behavioral of HRAM is
type ram_array is array (0 to 127) of STD_LOGIC_VECTOR (7 downto 0);
signal RAM: ram_array;

begin
process(clk)
begin
	if(rising_edge(clk)) then
		if en = '1' then
			if wr='1' then
				RAM(to_integer(UNSIGNED(addr))) <= data_in;
			end if;
			data_out <= RAM(to_integer(unsigned(addr)));
		end if;
	end if;
end process;
end Behavioral;