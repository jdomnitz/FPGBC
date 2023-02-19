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

entity Bus_Latch is
  Port (clk : in STD_LOGIC;
  		set : in STD_LOGIC;
        bus_in : in STD_LOGIC_VECTOR (7 downto 0);
        O : out STD_LOGIC_VECTOR (7 downto 0) := x"00");
end Bus_Latch;

architecture Behavioral of Bus_Latch is

begin
process(clk)

begin
	if rising_edge(clk) then
		if set = '1' then
			O <= bus_in;
		end if;
	end if;
end process;

end Behavioral;
