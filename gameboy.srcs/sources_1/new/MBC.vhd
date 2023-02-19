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

entity MBC is
    Port (  clk : in STD_LOGIC;
    		rd_n : in STD_LOGIC := '0';
    		wr_n : in STD_LOGIC := '0';
    		cs_n : in STD_LOGIC := '0';
    		rom_0 : out STD_LOGIC;
    		rom_1 : out STD_LOGIC;
    	   a_in : in STD_LOGIC_VECTOR (15 downto 0);
           a_out : out STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           d_out : out STD_LOGIC_VECTOR (7 downto 0);
           rom_in : in STD_LOGIC_VECTOR (7 downto 0));
end MBC;

architecture Behavioral of MBC is
SIGNAL rom_bank : STD_LOGIC_VECTOR(1 downto 0):= "01";
SIGNAL ram_bank : STD_LOGIC_VECTOR(1 downto 0):= "00";
SIGNAL ram_en : STD_LOGIC := '0';
SIGNAL mode : STD_LOGIC := '0';
SIGNAL ram_out : STD_LOGIC_VECTOR(7 downto 0) := x"00";

type ram_array is array (0 to 8191) of STD_LOGIC_VECTOR (7 downto 0);
signal RAM: ram_array;
begin

process(clk)
begin
	if rising_edge(clk) then
		rom_0 <= rom_bank(0);
		rom_1 <= rom_bank(1);
		if wr_n='0' AND a_in(15) = '0' then
			case a_in(14 downto 13) is
				when "00" =>
					if (d_in(3 downto 0) = x"A") then
						ram_en <= '1';
					else
						ram_en <= '0';
					end if;
					echo("RAM ENABLED!");
				when "01" =>
					if d_in(1 downto 0) = "00" then
						rom_bank <= "01";
					else
						rom_bank <= d_in(1 downto 0);
					end if;
					echo("ROM Bank: " & to_HexChar(d_in));
				when "10" =>
					ram_bank <= d_in(1 downto 0);
					echo("RAM Bank: " & to_HexChar(d_in));
				when "11" =>
					mode <= d_in(0);
					echo("Mode: " & to_HexChar(d_in));
				when others =>
					NULL;
			end case;
		end if;
		
		if a_in(15) = '1' AND ram_en = '1' then
			if wr_n = '0' then
				RAM(to_integer(UNSIGNED(a_in(12 downto 0)))) <= d_in;
				ram_out <= x"00";
			else
				ram_out <= RAM(to_integer(UNSIGNED(a_in(12 downto 0))));
			end if;
		else
			ram_out <= x"00";
		end if;
	end if;
end process;

process(a_in, rd_n, rom_in, rom_bank, ram_out)
begin
	if rd_n = '0' AND a_in(15) = '0' then
		if a_in(14) = '0' then
				a_out <= "00" & a_in(13 downto 0);
				d_out <= rom_in;
		else
				--MODE 1 not implemented
				a_out <= rom_bank & a_in(13 downto 0);
				d_out <= rom_in;
		end if;
	else
		d_out <= ram_out;
		a_out <= x"0000";
	end if;
 end process;

end Behavioral;
