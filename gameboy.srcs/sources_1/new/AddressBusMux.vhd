----------------------------------------------------------------------------------
-- This file is part of FPGBC.
-- FPGBC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
-- FPGBC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with FPGBC. If not, see <https://www.gnu.org/licenses/>.
-- Author: jdomnitz
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AddressBusMux is
    Port ( addr_a : in STD_LOGIC_VECTOR (15 downto 0);
           addr_b : in STD_LOGIC_VECTOR (15 downto 0);
           addr : out STD_LOGIC_VECTOR (15 downto 0);
           hold : in STD_LOGIC);
end AddressBusMux;

architecture Behavioral of AddressBusMux is
begin

process(hold, addr_a, addr_b)
begin

if hold = '1' then
	addr <= addr_b;
else
	addr <= addr_a;
end if;

end process;
end Behavioral;
