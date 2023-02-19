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


entity Timer is
    Port ( clk : in STD_LOGIC;
    		rst_n : in STD_LOGIC;
    		we : in STD_LOGIC;
    		re : in STD_LOGIC;
    		int_out : out STD_LOGIC := '0';
           	data_in : in STD_LOGIC_VECTOR (7 downto 0);
           	data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           	apu_tck : out STD_LOGIC := '0';
           	addr : in STD_LOGIC_VECTOR (15 downto 0));
end Timer;

architecture Behavioral of Timer is
SIGNAL DIV : UNSIGNED (16 downto 0) := "00000000000000000";
SIGNAL TIMA : STD_LOGIC_VECTOR (8 downto 0) := "000000000";
SIGNAL TMA : STD_LOGIC_VECTOR (7 downto 0) := x"00";
SIGNAL freq_div : STD_LOGIC_VECTOR (1 downto 0) := "00";
SIGNAL TIMA_en : STD_LOGIC := '0';
SIGNAL tima_bit_last : STD_LOGIC := '0';
SIGNAL apu_bit_last  : STD_LOGIC := '0';
SIGNAL we_bit_last : STD_LOGIC := '0';

begin

process(clk, re, addr)
variable tima_bit : STD_LOGIC := '0';

begin
    if rising_edge (clk) then
    	if rst_n = '0' then
    		DIV <= "00000000000000000";
    		TIMA <= "000000000";
    		TMA <= x"00";
    		TIMA_en <= '0';
    		freq_div <= "00";
    		tima_bit_last <= '0';
    		apu_bit_last <= '0';
    		we_bit_last <= '0';
    	else
			DIV <= DIV+1;
			if re = '1' then
				case addr is
						when x"FF04" =>
							data_out <= STD_LOGIC_VECTOR(DIV(15 downto 8));
						when x"FF05" =>
							data_out <= TIMA(7 downto 0);
							--echo("TIMA: " & to_HexChar(TIMA(7 downto 0)));
						when x"FF06" =>
							data_out <= TMA;
							--echo("TMA: " & to_HexChar(TMA));
						when x"FF07" =>
							data_out <= "00000" & TIMA_en & freq_div;
						when others =>
							data_out <= x"00";
					end case;
			end if;
			if we='1' then
				case addr is
					when x"FF04" =>
						if we_bit_last ='0' then
							DIV <= "00000000000000000";
						end if;
					when x"FF05" =>
						TIMA <= '0' & data_in;
					when x"FF06" =>
						TMA <= data_in;
					when x"FF07" =>
						TIMA_en <= data_in(2);
						freq_div <= data_in(1 downto 0);
					when others =>
						NULL;
				end case;
			end if;
			we_bit_last <= we;
			
			case freq_div is
				when "01" =>
					tima_bit := DIV(3);
				when "10" =>
					tima_bit := DIV(5);
				when "11" =>
					tima_bit := DIV(7);
				when "00" =>
					tima_bit := DIV(9);
				when others =>
					NULL;
			end case;
			
			if TIMA(8) = '1' AND DIV(1) = '1' then
				TIMA <= '0' & TMA;
				int_out <= '1';
			else
				int_out <= '0';
			end if;
			
			if tima_bit_last='1' AND tima_bit='0' AND TIMA_en='1' then
				TIMA <= STD_LOGIC_VECTOR(UNSIGNED(TIMA) + 1);
			end if;
			if apu_bit_last ='1' AND DIV(12) = '0' then
				apu_tck <= '1';
			else
				apu_tck <= '0';
			end if;
			tima_bit_last <= tima_bit;
			apu_bit_last <= DIV(12);
    	end if;
    end if;
    
end process;

end Behavioral;
