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

entity ALU_test is
end ALU_test;

architecture Behavioral of ALU_test is 
    component gameboy_wrapper
        Port ( clk : in std_logic;
        	reset : in std_logic;
        	ac_adc_sdata : in std_logic;
        	ac_bclk : in std_logic;
        	ac_lrclk : in std_logic;
        	btn_l : in std_logic;
        	btn_r : in std_logic;
        	btn_u : in std_logic;
        	btn_d : in std_logic;
        	btn_a : in std_logic);
    end component;
    
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL stop : STD_LOGIC := '0';
    
begin
    UUT: gameboy_wrapper port map (clk => clk, ac_adc_sdata => '0', ac_bclk => '0', btn_l => '0', btn_r => '0', btn_u => '0', btn_d => '0', ac_lrclk => '0', reset => '1', btn_a => '0');
    
    process
    begin
        clk <= '0';
        wait for 1ns;
        for I in 0 to 100000000 loop
        	--if stop = '1' then
        	--	exit;
        	--end if;
            clk <= NOT clk;
            wait for 1ns;
        end loop;
    end process;
    
end Behavioral;