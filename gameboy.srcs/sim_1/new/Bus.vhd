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

entity DataBus is
    Port ( clk : in STD_LOGIC;
    	   rst_n : in STD_LOGIC;
    	   int_ack : in STD_LOGIC;
    	   re : in STD_LOGIC;
    	   we : in STD_LOGIC;
    	   addr : in STD_LOGIC_VECTOR(15 downto 0);
    	   REG_in : in STD_LOGIC_VECTOR (7 downto 0);
           bus2_in : in STD_LOGIC_VECTOR (7 downto 0);
           BOOT_in : in STD_LOGIC_VECTOR (7 downto 0);
           HRAM_in : in STD_LOGIC_VECTOR (7 downto 0);
           INT_in : in STD_LOGIC_VECTOR (7 downto 0);
           ALU_in : in STD_LOGIC_VECTOR (7 downto 0);
           bus1_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           SEL : in STD_LOGIC_VECTOR (2 downto 0);
           HRAM_addr : out STD_LOGIC_VECTOR (6 downto 0);
           HRAM_en : out STD_LOGIC;
           HRAM_wr : out STD_LOGIC;
           HRAM_data_out : out STD_LOGIC_VECTOR(7 downto 0);
           BOOT_addr : out STD_LOGIC_VECTOR (7 downto 0);
           BOOT_en : out STD_LOGIC;
           done : out STD_LOGIC;
           MASK_e : in STD_LOGIC);
end DataBus;

architecture RTL of DataBus is

SIGNAL buff : STD_LOGIC_VECTOR(7 downto 0) := x"00";
SIGNAL use_buff : STD_LOGIC := '0';
SIGNAL rom_disabled : STD_LOGIC := '1';

begin
process(SEL, use_buff, buff, REG_in, bus2_in, ALU_in, MASK_e, int_ack, INT_in)
begin
	if int_ack = '1' then
		bus1_out <= INT_in;
	else
		case SEL is
			when BUS_REG =>
				bus1_out <= REG_in;
			when BUS_MMU =>
				if use_buff = '1' then
					if MASK_e = '1' then
						bus1_out <= "00" & buff(5 downto 3) & "000"; 
					else
						bus1_out <= buff;
					end if;
				else
					if MASK_e = '1' then
						bus1_out <= "00" & bus2_in(5 downto 3) & "000"; 
					else
						bus1_out <= bus2_in;
					end if;
				end if;
			when BUS_ALU =>
				bus1_out <= ALU_in;
			when others =>
				bus1_out <= x"00";
		end case;
    end if;
end process;

process(clk)
begin
	if rising_edge(clk) then
		if rst_n = '0' then
			rom_disabled <= '0';
		else
			if rom_disabled = '0' AND addr(15 downto 8) = x"00" then
				use_buff <= '1';
				BOOT_en <= re;
				HRAM_en <= '0';
				HRAM_wr <= '0';
				--if re = '1' then
				--	echo("ROM READ " & to_HexChar(rom_data_in) & " @ " & to_DHexChar(addr));
				--end if;
				buff <= BOOT_in;
			elsif addr(15 downto 7) = "111111111" then
				use_buff <= '1';
				BOOT_en <= '0';
				buff <= HRAM_in;
				HRAM_en <= re OR we;
				HRAM_wr <= we;
				if SEL=BUS_ALU then
					HRAM_data_out <= alu_in;
				elsif SEL=BUS_REG then
					HRAM_data_out <= reg_in;
				else
					HRAM_data_out <= bus2_in;
				end if;
				
				if re = '1' then
					echo("HRAM READ " & to_HexChar(HRAM_in) & " @ " & to_DHexChar(addr));
				end if;
				if we = '1' then
					if SEL=BUS_ALU then
						--echo("HRAM WRITE " & to_HexChar(alu_in) & " @ " & to_DHexChar(addr));
					elsif SEL=BUS_REG then
						--echo("HRAM WRITE " & to_HexChar(reg_in) & " @ " & to_DHexChar(addr));
					else
						--echo("HRAM WRITE " & to_HexChar(bus2_in) & " @ " & to_DHexChar(addr));
					end if;
				end if;
			elsif (addr = x"ff50") then --ROM Disable
				use_buff <= '1';
				if (we = '1') then
					rom_disabled <= '1';
					buff <= x"FF";
					echo("SUCCESS!!!!");
				else
					buff <= "0000000" & rom_disabled;
				end if;
				BOOT_en <= '0';
				HRAM_en <= '0';
				HRAM_wr <= '0';
			elsif (addr = x"FF0F") then
				use_buff <= '1';
				buff <= INT_in;
				BOOT_en <= '0';
				HRAM_en <= '0';
				HRAM_wr <= '0';
			else
				use_buff <= '0';
				buff <= x"00";
				BOOT_en <= '0';
				HRAM_en <= '0';
				HRAM_wr <= '0';
			end if;
			HRAM_addr <= addr(6 downto 0);
			BOOT_addr <= addr(7 downto 0);
			done <= rom_disabled;
		end if;
	end if;
end process;

end RTL;
