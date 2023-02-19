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

library gameboy;
use gameboy.Common.ALL;

entity MMU is
    Port ( clk : in STD_LOGIC;
           addr : in STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           we : in STD_LOGIC;
           re : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           bus2_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           cart_a : out STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           cart_re_n : out STD_LOGIC := '1';
           cart_we_n : out STD_LOGIC := '1';
           cart_cs_n : out STD_LOGIC := '1';
           cart_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           cart_data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           wram_a : out STD_LOGIC_VECTOR (12 downto 0) := "0000000000000";
           wram_e : out STD_LOGIC := '0';
           wram_we : out STD_LOGIC := '0';
           wram_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           wram_data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           tmr_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           apu_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           icu_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           ppu_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           ppu_read : in STD_LOGIC := '0');
end MMU;

architecture Behavioral of MMU is
    
begin

process(clk, addr)
begin
    if rising_edge (clk) then	
        --if (we = '1') then
        --    echo ("Writing " & to_HexChar(data_in) & " @ " & to_DHexChar(addr));
        --end if;
		case addr(15 downto 12) is
			when "0000" | "0001"  | "0010" | "0011" | "0100" | "0101"  | "0110" | "0111" | "1010" | "1011" => --BOOT ROM / Cart MMC
				cart_re_n <= NOT re;
				cart_we_n <= NOT we;
				cart_data_out <= data_in;
				data_out <= cart_data_in;
				if re = '1' then
					echo("CART READ " & to_HexChar(cart_data_in) & " @ " & to_DHexChar(addr));
				end if;
				wram_we <= '0';
				wram_e <= '0';
			when "1000" | "1001" => --VRAM
				data_out <= ppu_data_in;
				cart_re_n <= '1';
				cart_we_n <= '1';
				wram_we <= '0';
				wram_e <= '0';
			when "1100" | "1101" | "1110" => --WRAM / ECHO (lower half)
				wram_we <= we;
				wram_e <= we or re;
				wram_data_out <= data_in;
				data_out <= wram_data_in;
				cart_re_n <= '1';
				cart_we_n <= '1';
				if re = '1' then
					echo("WRAM READ " & to_HexChar(wram_data_in) & " @ " & to_DHexChar(addr));
				end if;
				--if we = '1' then
				--	echo("WRAM WRITE " & to_HexChar(data_in) & " @ " & to_DHexChar(addr));
				--end if;
			when "1111" =>
				if (addr(11 downto 7) = "11111") then --HRAM
					--HRAM
					cart_re_n <= '1';
				cart_we_n <= '1';
					wram_we <= '0';
					wram_e <= '0';
				elsif (addr(11 downto 8) = x"E") then --OAM
					data_out <= ppu_data_in;
					cart_re_n <= '1';
					cart_we_n <= '1';
					wram_we <= '0';
					wram_e <= '0';
					if we = '1' then
						echo("OAM WRITE " & to_HexChar(data_in) & " @ " & to_DHexChar(addr));
					end if;
					if re = '1' then
						echo("OAM READ " & to_HexChar(ppu_data_in) & " @ " & to_DHexChar(addr));
					end if;
				elsif (addr(11 downto 9) /= "111") then --ECHO RAM High
					wram_we <= we;
					wram_e <= we or re;
					wram_data_out <= data_in;
					data_out <= wram_data_in;
					cart_re_n <= '1';
					cart_we_n <= '1';
					if we = '1' then
						echo("ECHO WRITE " & to_HexChar(data_in) & " @ " & to_DHexChar(addr));
					end if;
					if re = '1' then
						echo("ECHO READ " & to_HexChar(wram_data_in) & " @ " & to_DHexChar(addr));
					end if;
				elsif (addr(11 downto 5) = "1111101" OR addr(11 downto 5) = "1111110" OR addr(11 downto 5) = "1111111") then
					data_out <= x"FF";
					cart_re_n <= '1';
					cart_we_n <= '1';
					wram_we <= '0';
					wram_e <= '0';
					echo("BAD READ: " & to_DHexChar(addr));
				else
					--if (we='1' OR re='1') then
					--	echo ("Accessing " & to_DHexChar(addr));
					--end if;
					data_out <= tmr_data_in OR ppu_data_in OR apu_data_in OR icu_data_in;
					cart_re_n <= '1';
					cart_we_n <= '1';
					wram_we <= '0';
					wram_e <= '0';
				end if;
			when others =>
				data_out <= x"00";
				cart_re_n <= '1';
				cart_we_n <= '1';
				wram_we <= '0';
				wram_e <= '0';
		end case;
		cart_a <= addr;
		wram_a <= addr(12 downto 0);
	end if;
end process;

process(data_in)
begin
	bus2_out <= data_in;
end process;

end Behavioral;
