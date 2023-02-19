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

entity ALU is
    Port ( op : in STD_LOGIC_VECTOR (4 downto 0);
           bit_sel : in STD_LOGIC_VECTOR (2 downto 0);
           A_in : in STD_LOGIC_VECTOR (7 downto 0);
           bus_in : in STD_LOGIC_VECTOR (7 downto 0);
           F_in : in STD_LOGIC_VECTOR (7 downto 4) := "0000";
           F_out : out STD_LOGIC_VECTOR (7 downto 4);
           bus_out : out STD_LOGIC_VECTOR (7 downto 0));
end ALU;

architecture Behavioral of ALU is

begin
process(A_in, bus_in, op, F_in, bit_sel)
variable high : STD_LOGIC_VECTOR (4 downto 0);
variable low : STD_LOGIC_VECTOR (4 downto 0);
variable R : STD_LOGIC_VECTOR (7 downto 0);

begin
	case op is
		when ALU_ADD | ALU_ADDC =>
			 low := ('0' & A_in(3 downto 0)) + bus_in(3 downto 0) + (op(0) and F_in(FLAG_CARRY));
			 high := ('0' & A_in(7 downto 4)) + bus_in(7 downto 4) +  low(4);
			 R := high(3 downto 0) & low(3 downto 0);
			 F_out(FLAG_HALF_CARRY) <= low(4);
			 F_out(FLAG_CARRY) <= high(4);
			 F_out(FLAG_ZERO) <= is_zero(R);
			 F_out(FLAG_SUB) <= '0';
			 bus_out <= R;
		when ALU_SUB | ALU_SUBC | ALU_COMP =>
			 low := ('0' & A_in(3 downto 0)) + NOT(('0' & bus_in(3 downto 0)) + (op(0) and F_in(FLAG_CARRY))) + "00001";
			 high := ('0' & A_in(7 downto 4)) + NOT('0' & bus_in(7 downto 4)) + NOT low(4);
			 
			 if (op = ALU_COMP) then
				bus_out <= A_in;
			 else
				bus_out <= high(3 downto 0) & low(3 downto 0);
			 end if;
			 F_out(FLAG_ZERO) <= is_zero(high(3 downto 0) & low(3 downto 0));
			 F_out(FLAG_HALF_CARRY) <= low(4);
			 F_out(FLAG_CARRY) <= high(4);
			 F_out(FLAG_SUB) <= '1';
		when ALU_INC => -- Increment
			 low := ('0' & A_in(3 downto 0)) + 1;
			 high := ('0' & A_in(7 downto 4)) + low(4);
			 bus_out <= high(3 downto 0) & low(3 downto 0);
			 F_out(FLAG_ZERO) <= is_zero(high(3 downto 0) & low(3 downto 0));
			 F_out(FLAG_HALF_CARRY) <= low(4);
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_CARRY) <= F_in(FLAG_CARRY);
		when ALU_DEC => -- Decrement
			 low := ('0' & A_in(3 downto 0)) - 1;
			 high := ('0' & A_in(7 downto 4)) -  low(4);
			 bus_out <= high(3 downto 0) & low(3 downto 0);
			 F_out(FLAG_ZERO) <= is_zero(high(3 downto 0) & low(3 downto 0));
			 F_out(FLAG_HALF_CARRY) <= low(4);
			 F_out(FLAG_SUB) <= '1';
			 F_out(FLAG_CARRY) <= F_in(FLAG_CARRY);
		when ALU_AND =>
			 R:= A_in and bus_in;
			 bus_out <= R;
			 F_out(FLAG_ZERO) <= is_zero(R);
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '1';
			 F_out(FLAG_CARRY) <= '0';
		when ALU_XOR =>
			 R:= A_in xor bus_in; -- XOR
			 bus_out <= R;
			 F_out(FLAG_ZERO) <= is_zero(R);
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '0';
			 F_out(FLAG_CARRY) <= '0';
		when ALU_OR =>
			 R:= A_in or bus_in; -- OR
			 bus_out <= R;
			 F_out(FLAG_ZERO) <= is_zero(R);
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '0';
			 F_out(FLAG_CARRY) <= '0';
		when ALU_RL | ALU_RLC | ALU_RLA | ALU_RLCA =>
			 R(7 downto 1) := bus_in(6 downto 0);
			 if (op = ALU_RL OR op = ALU_RLA) then
				R(0) := F_in(FLAG_CARRY);
			 else
				R(0) := bus_in(7);
			 end if;
			 bus_out <= R;
			 if (op = ALU_RLCA OR op = ALU_RLA) then
				F_out(FLAG_ZERO) <= '0';
			 else
				F_out(FLAG_ZERO) <= is_zero(R);
			 end if;
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '0';
			 F_out(FLAG_CARRY) <= bus_in(7);
		when ALU_RR | ALU_RRA | ALU_RRC | ALU_RRCA =>
			 R(6 downto 0) := bus_in(7 downto 1);
			 if (op = ALU_RR OR op = ALU_RRA) then
				R(7) := F_in(FLAG_CARRY);
			 else
				R(7) := bus_in(0);
			 end if;
			 bus_out <= R;
			 if (op = ALU_RR OR op = ALU_RRC) then
				F_out(FLAG_ZERO) <= is_zero(R);
			 else
				F_out(FLAG_ZERO) <= '0';
			 end if;
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '0';
			 F_out(FLAG_CARRY) <= bus_in(0);
		when ALU_SWAP =>
			R:= bus_in(3 downto 0) & bus_in(7 downto 4);
			bus_out <= R;
			F_out(FLAG_CARRY) <= '0';
			F_out(FLAG_ZERO) <= is_zero(R);
			F_out(FLAG_SUB) <= '0';
			F_out(FLAG_HALF_CARRY) <= '0';
		when ALU_SL =>
			R := bus_in(6 downto 0) & '0';
			F_out(FLAG_CARRY) <= bus_in(7);
			bus_out <= R;
			F_out(FLAG_ZERO) <= is_zero(R);
			F_out(FLAG_SUB) <= '0';
			F_out(FLAG_HALF_CARRY) <= '0';
		when ALU_SR | ALU_SRC =>
			 R(6 downto 0) := bus_in(7 downto 1);
			 if (op = ALU_SRC) then
				R(7) := '0';
			 else
				R(7) := bus_in(7);
			 end if;
			 bus_out <= R;
			 F_out(FLAG_ZERO) <= is_zero(R);
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '0';
			 F_out(FLAG_CARRY) <= bus_in(0);
		when ALU_SET =>
			 R := bus_in;
			 R(to_integer(unsigned(bit_sel))) := '1';
			 bus_out <= R;
			 F_out <= F_in;
		when ALU_BIT =>
			 F_out(FLAG_ZERO) <= NOT bus_in(to_integer(unsigned(bit_sel)));
			 F_out(FLAG_SUB) <= '0';
			 F_out(FLAG_HALF_CARRY) <= '1';
			 F_out(FLAG_CARRY) <= F_in(FLAG_CARRY);
			 bus_out <= bus_in;
		when ALU_NOT =>
			 bus_out<= not A_in;
			 F_out(FLAG_SUB) <= '1';
			 F_out(FLAG_HALF_CARRY) <= '1';
			 F_out(FLAG_ZERO) <= F_in(FLAG_ZERO);
			 F_out(FLAG_CARRY) <= F_in(FLAG_CARRY);
		when ALU_SCF =>
			F_out(FLAG_CARRY) <= '1';
			F_out(FLAG_SUB) <= '0';
			F_out(FLAG_HALF_CARRY) <= '0';
			F_out(FLAG_ZERO) <= F_in(FLAG_ZERO);
			bus_out <= bus_in;
		when ALU_DAA =>
			high := '0' & bus_in(7 downto 4);
			low := '0' & bus_in(3 downto 0);
			if F_in(FLAG_SUB) = '1' then
				if (F_in(FLAG_HALF_CARRY) = '1') then
					low := low + "11010"; -- sub 6
					if low(4) = '1' then
						high := high + "11111"; --borrow 1
					end if;
				end if;
				if (F_in(FLAG_CARRY) = '1') then
					high := high + "11010"; -- sub 6
				end if;
				F_out(FLAG_CARRY) <= F_in(FLAG_CARRY);
			else
				if (low > 9 OR F_in(FLAG_HALF_CARRY) = '1') then
					low := low + x"6";
					high := high + low(4);
				end if;
				if (high > 9 OR F_in(FLAG_CARRY) = '1') then
					high := high + x"6";
			 		F_out(FLAG_CARRY) <= '1';
				else
					F_out(FLAG_CARRY) <= '0';
				end if;
			end if;
			R := high(3 downto 0) & low(3 downto 0);
			F_out(FLAG_HALF_CARRY) <= '0';
			F_out(FLAG_ZERO) <= is_zero(R);
			F_out(FLAG_SUB) <= F_in(FLAG_SUB);
			bus_out <= R;
		when ALU_CCF =>
			F_out(FLAG_CARRY) <= NOT F_in(FLAG_CARRY);
			F_out(FLAG_SUB) <= '0';
			F_out(FLAG_HALF_CARRY) <= '0';
			F_out(FLAG_ZERO) <= F_in(FLAG_ZERO);
			bus_out <= bus_in;
		when ALU_RES =>
			R := bus_in;
			R(to_integer(unsigned(bit_sel))) := '0';
			bus_out <= R;
			F_out(FLAG_ZERO) <= F_in(FLAG_ZERO);
			F_out(FLAG_SUB) <= F_in(FLAG_SUB);
			F_out(FLAG_CARRY) <= F_in(FLAG_CARRY);
			F_out(FLAG_HALF_CARRY) <= F_in(FLAG_HALF_CARRY);
		when ALU_FOUT =>
			bus_out <= F_in & "0000";
			F_out <= F_in;
		when others => -- ALU_DISABLED
			bus_out <= bus_in;
			F_out <= F_in;
	end case;
end process;

end Behavioral;
