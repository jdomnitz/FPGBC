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

entity Registers is
    Port ( clk : in STD_LOGIC;
    	   rst_n : in STD_LOGIC;
           rr : in STD_LOGIC;
           rw : in STD_LOGIC;
           drr : in STD_LOGIC;
           drw : in STD_LOGIC;
           tmp_in : in STD_LOGIC;
           flag_op : in STD_LOGIC_VECTOR(1 downto 0);
           flag_in : in STD_LOGIC_VECTOR(7 downto 4);
           flag_out : out STD_LOGIC_VECTOR(7 downto 4) := x"0";
           mask_en : in STD_LOGIC;
           addr_in : in STD_LOGIC_VECTOR (15 downto 0);
           addr_out : out STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           sel_reg : in STD_LOGIC_VECTOR (3 downto 0);
           sel_dreg : in STD_LOGIC_VECTOR (2 downto 0);
           addr_op : in STD_LOGIC_VECTOR (1 downto 0));
end Registers;

architecture Behavioral of Registers is
SIGNAL BANK : STD_LOGIC_VECTOR (111 downto 0) := x"0000001300D8014D01B0FFFE0100"; --x"0000000000000000000000000000";
SIGNAL mem : STD_LOGIC_VECTOR (15 downto 0) := x"0000";

begin

process(clk)
begin
    if rising_edge(clk) then
    	if rst_n = '0' then
    		BANK <= x"0000000000000000000000000000";
    		flag_out <= x"0";
    		mem <= x"0000";
    	else
			if tmp_in = '1' then
				echo("A: " & to_HexChar(BANK(47 downto 40)));
				echo("B: " & to_HexChar(BANK(95 downto 88)));
				echo("C: " & to_HexChar(BANK(87 downto 80)));
				echo("D: " & to_HexChar(BANK(79 downto 72)));
				echo("F: " & to_HexChar(BANK(39 downto 36) & x"0"));
				echo("PC: " & to_DHexChar(BANK(15 downto 0)));
				--echo("HL: " & to_DHexChar(BANK(63 downto 48)));
				--echo("SP: " & to_DHexChar(BANK(31 downto 16)));
			end if;
			if (rw = '1') then
				case sel_reg is
					when REG_W =>
						BANK(111 downto 104) <= data_in;
						echo("Set W: " & to_HexChar(data_in));
					when REG_Z =>
						BANK(103 downto 96) <= data_in;
						echo("Set Z: " & to_HexChar(data_in));
					when REG_B =>
						BANK(95 downto 88) <= data_in;
						--echo("Set B: " & to_HexChar(data_in));
					when REG_C =>
						BANK(87 downto 80) <= data_in;
						--echo("Set C: " & to_HexChar(data_in));
					when REG_D =>
						BANK(79 downto 72) <= data_in;
						--echo("Set D: " & to_HexChar(data_in));
					when REG_E =>
						BANK(71 downto 64) <= data_in;
						--echo("Set E: " & to_HexChar(data_in));
					when REG_H =>
						BANK(63 downto 56) <= data_in;
						--echo("Set H: " & to_HexChar(data_in));
					when REG_L =>
						BANK(55 downto 48) <= data_in;
						--echo("Set L: " & to_HexChar(data_in));
					when REG_A =>
						BANK(47 downto 40) <= data_in;
						--echo("Set A: " & to_HexChar(data_in));
					when REG_F =>
						BANK(39 downto 32) <= data_in(7 downto 4) & "0000";
					when REG_SPH =>
						BANK(31 downto 24) <= data_in;
						--echo("Set S: " & to_HexChar(data_in));
					when REG_SPL =>
						BANK(23 downto 16) <= data_in;
						--echo("Set P: " & to_HexChar(data_in));
					when REG_PCH =>
						BANK(15 downto 8) <= data_in;
						--echo("Set PCH: " & to_HexChar(data_in));
					when REG_PCL =>
						BANK(7 downto 0) <= data_in;
						--echo("Set PCL: " & to_HexChar(data_in));
					when others =>
						echo("Bad Reg Write Attempted");
						NULL;
				end case;
			end if;
			case flag_op is
				when OP_LATCH =>
					BANK(39 downto 36) <= flag_in;
					--echo("Set F: " & to_HexChar(flag_in & "0000"));
				when OP_LATCH_NO_ZERO =>
					BANK(38 downto 36) <= flag_in(6 downto 4);
					--echo("Set F: " & to_HexChar(BANK(39) & flag_in(6 downto 4) & "0000"));
				when OP_BUS => --Mask Clear Zero
					BANK(39 downto 36) <= "0" & flag_in(6 downto 4);
					--echo("Set F: " & to_HexChar("0" & flag_in(6 downto 4) & "0000"));
				when others =>
					NULL;
			end case;
			flag_out <= BANK(39 downto 36);
			if (drw = '1') then
				case sel_dreg is
					when REG_WZ =>
						BANK(111 downto 96) <= addr_in;
						--echo("Set WZ: " & to_DHexChar(addr_in));
					when REG_BC =>
						BANK(95 downto 80) <= addr_in;
						--echo("Set BC: " & to_DHexChar(addr_in));
					when REG_DE =>
						BANK(79 downto 64) <= addr_in;
						--echo("Set DE: " & to_DHexChar(addr_in));
					when REG_HL =>
						BANK(63 downto 48) <= addr_in;
						--echo("Set HL: " & to_DHexChar(addr_in));
					when REG_SP =>
						BANK(31 downto 16) <= addr_in;
						echo("Set SP: " & to_DHexChar(addr_in));
					when REG_PC =>
						BANK(15 downto 0) <= addr_in;
						echo("Set PC: " & to_DHexChar(addr_in));
					when others =>
						NULL;
				end case;
			end if;
        end if;
        if addr_op = OP_LATCH then
			if (drr = '1') then
				case sel_dreg is
					when REG_WZ => 
						mem <= BANK(111 downto 96);
					when REG_FX =>
						if mask_en = '1' then
							if sel_reg = REG_C then
								mem <= x"FF" & BANK(87 downto 80);
							else
								mem <= x"FF" & BANK(103 downto 96);
							end if;
						else
							mem <= x"00" & BANK(103 downto 96);
						end if;
					when REG_BC => 
						mem <= BANK(95 downto 80);
					when REG_DE => 
						mem <= BANK(79 downto 64);
					when REG_HL =>
						mem <= BANK(63 downto 48);
					when REG_SP =>
						mem <= BANK(31 downto 16);
					when REG_PC =>
						mem <= BANK(15 downto 0);
					when others =>
						mem <= x"0000";
				end case;
			else
				mem <= x"0000";
			end if;
        end if;
    end if;
end process;

process(rr, sel_reg, BANK)
begin
    if (rr = '1') then
        case sel_reg is
			when REG_W =>
				data_out <= BANK(111 downto 104);
			when REG_Z =>
				data_out <= BANK(103 downto 96);
			when REG_B =>
				data_out <= BANK(95 downto 88);
			when REG_C =>
				data_out <= BANK(87 downto 80);
			when REG_D =>
				data_out <= BANK(79 downto 72);
			when REG_E =>
				data_out <= BANK(71 downto 64);
			when REG_H =>
				data_out <= BANK(63 downto 56);
			when REG_L =>
				data_out <= BANK(55 downto 48);
			when REG_A =>
				data_out <= BANK(47 downto 40);
			when REG_F =>
				data_out <= BANK(39 downto 32);
			when REG_SPH =>
				data_out <= BANK(31 downto 24);
			when REG_SPL =>
				data_out <= BANK(23 downto 16);
			when REG_PCH =>
				data_out <= BANK(15 downto 8);
			when REG_PCL =>
				data_out <= BANK(7 downto 0);
			when others =>
				data_out <= x"00";
		end case;
    else
        data_out <= x"00";
    end if;
end process;

process(clk, addr_op, drr, sel_reg, sel_dreg, mask_en, BANK, mem)

begin
     case addr_op is
		when OP_LATCH =>
			if (drr = '1') then
				case sel_dreg is
					when REG_WZ => 
						addr_out <= BANK(111 downto 96);
					when REG_FX =>
						if mask_en = '1' then
							if sel_reg = REG_C then
								addr_out <= x"FF" & BANK(87 downto 80);
							else
								addr_out <= x"FF" & BANK(103 downto 96);
							end if;
						else
							addr_out <= x"00" & BANK(103 downto 96);
						end if;
					when REG_BC => 
						addr_out <= BANK(95 downto 80);
					when REG_DE => 
						addr_out <= BANK(79 downto 64);
					when REG_HL =>
						addr_out <= BANK(63 downto 48);
					when REG_SP =>
						addr_out <= BANK(31 downto 16);
					when REG_PC =>
						addr_out <= BANK(15 downto 0);
					when others =>
						addr_out <= x"0000";
				end case;
			else
				addr_out <= x"0000";
			end if;
		when OP_INC =>
			addr_out <= STD_LOGIC_VECTOR(UNSIGNED(mem) + 1);
		when OP_DEC =>
			addr_out <= STD_LOGIC_VECTOR(UNSIGNED(mem) - 1);
		when others =>
			addr_out <= mem;
	end case;
end process;

end Behavioral;
