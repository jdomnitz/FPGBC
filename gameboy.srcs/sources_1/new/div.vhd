----------------------------------------------------------------------------------
-- This file is part of FPGBC.
-- FPGBC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
-- FPGBC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with FPGBC. If not, see <https://www.gnu.org/licenses/>.
-- Author: jdomnitz
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity div is
    Port ( clk_in : in STD_LOGIC;
           clk_out : out STD_LOGIC);
end div;

architecture Behavioral of div is

SIGNAL clk : STD_LOGIC := '0';
begin

process (clk_in, clk) begin
	if rising_edge(clk_in) then
		clk <= NOT clk;
	end if;
	clk_out <= clk;
end process;

end Behavioral;
