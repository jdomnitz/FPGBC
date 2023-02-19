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

package common is
constant ALU_ADD : STD_LOGIC_VECTOR(4 downto 0) := "00000";
constant ALU_ADDC : STD_LOGIC_VECTOR(4 downto 0) := "00001";
constant ALU_SUB : STD_LOGIC_VECTOR(4 downto 0) := "00010";
constant ALU_SUBC : STD_LOGIC_VECTOR(4 downto 0) := "00011";
constant ALU_INC : STD_LOGIC_VECTOR(4 downto 0) := "00100";
constant ALU_FOUT : STD_LOGIC_VECTOR(4 downto 0) := "00101";
constant ALU_DEC: STD_LOGIC_VECTOR(4 downto 0) := "00110";
constant ALU_RESERVED: STD_LOGIC_VECTOR(4 downto 0) := "00111";
constant ALU_AND : STD_LOGIC_VECTOR(4 downto 0) := "01000";
constant ALU_RRCA : STD_LOGIC_VECTOR(4 downto 0) := "01001";
constant ALU_XOR : STD_LOGIC_VECTOR(4 downto 0) := "01010";
constant ALU_RLCA : STD_LOGIC_VECTOR(4 downto 0) := "01011";
constant ALU_OR : STD_LOGIC_VECTOR(4 downto 0) := "01100";
constant ALU_RRA : STD_LOGIC_VECTOR(4 downto 0) := "01101";
constant ALU_COMP : STD_LOGIC_VECTOR(4 downto 0) := "01110";
constant ALU_RLA : STD_LOGIC_VECTOR(4 downto 0) := "01111";
constant ALU_RLC : STD_LOGIC_VECTOR(4 downto 0) := "10000";
constant ALU_RL : STD_LOGIC_VECTOR(4 downto 0) := "10001";
constant ALU_RRC : STD_LOGIC_VECTOR(4 downto 0) := "10010";
constant ALU_RR : STD_LOGIC_VECTOR(4 downto 0) := "10011";
constant ALU_SL : STD_LOGIC_VECTOR(4 downto 0) := "10100";
constant ALU_SWAP : STD_LOGIC_VECTOR(4 downto 0) := "10101";
constant ALU_SR : STD_LOGIC_VECTOR(4 downto 0) := "10110";
constant ALU_SRC : STD_LOGIC_VECTOR(4 downto 0) := "10111";
constant ALU_BIT : STD_LOGIC_VECTOR(4 downto 0) := "11000";
constant ALU_SET : STD_LOGIC_VECTOR(4 downto 0) := "11001";
constant ALU_NOT : STD_LOGIC_VECTOR(4 downto 0) := "11010";
constant ALU_CCF : STD_LOGIC_VECTOR(4 downto 0) := "11011";
constant ALU_DAA : STD_LOGIC_VECTOR(4 downto 0) := "11100";
constant ALU_SCF : STD_LOGIC_VECTOR(4 downto 0) := "11101";
constant ALU_RES : STD_LOGIC_VECTOR(4 downto 0) := "11110";
constant ALU_DISABLED : STD_LOGIC_VECTOR(4 downto 0) := "11111";

constant REG_B : STD_LOGIC_VECTOR(3 downto 0) := "0000";
constant REG_C : STD_LOGIC_VECTOR(3 downto 0) := "0001";
constant REG_D : STD_LOGIC_VECTOR(3 downto 0) := "0010";
constant REG_E : STD_LOGIC_VECTOR(3 downto 0) := "0011";
constant REG_H : STD_LOGIC_VECTOR(3 downto 0) := "0100";
constant REG_L : STD_LOGIC_VECTOR(3 downto 0) := "0101";
constant REG_F : STD_LOGIC_VECTOR(3 downto 0) := "0110"; --Flag Reg
constant REG_M : STD_LOGIC_VECTOR(3 downto 0) := "0110"; --Memory Location (HL)
constant REG_A : STD_LOGIC_VECTOR(3 downto 0) := "0111";
constant REG_W : STD_LOGIC_VECTOR(3 downto 0) := "1000";
constant REG_Z : STD_LOGIC_VECTOR(3 downto 0) := "1001";
constant REG_SPH : STD_LOGIC_VECTOR(3 downto 0) := "1010";
constant REG_SPL : STD_LOGIC_VECTOR(3 downto 0) := "1011";
constant REG_PCH : STD_LOGIC_VECTOR(3 downto 0) := "1100";
constant REG_PCL : STD_LOGIC_VECTOR(3 downto 0) := "1101";

constant REG_BC : STD_LOGIC_VECTOR(2 downto 0) := "000";
constant REG_DE : STD_LOGIC_VECTOR(2 downto 0) := "001";
constant REG_HL : STD_LOGIC_VECTOR(2 downto 0) := "010";
constant REG_SP : STD_LOGIC_VECTOR(2 downto 0) := "011";
constant REG_PC : STD_LOGIC_VECTOR(2 downto 0) := "100";
constant REG_WZ : STD_LOGIC_VECTOR(2 downto 0) := "101";
constant REG_AF : STD_LOGIC_VECTOR(2 downto 0) := "110";
constant REG_FX : STD_LOGIC_VECTOR(2 downto 0) := "111";

constant OP_NONE : STD_LOGIC_VECTOR(1 downto 0) := "00";
constant OP_LATCH : STD_LOGIC_VECTOR(1 downto 0) := "01";
constant OP_INC : STD_LOGIC_VECTOR(1 downto 0) := "10";
constant OP_DEC : STD_LOGIC_VECTOR(1 downto 0) := "11";
constant OP_BUS : STD_LOGIC_VECTOR(1 downto 0) := "10";
constant OP_LATCH_NO_ZERO : STD_LOGIC_VECTOR(1 downto 0) := "11";

constant BUS_IDLE : STD_LOGIC_VECTOR(2 downto 0) := "000";
--constant BUS_TMP : STD_LOGIC_VECTOR(2 downto 0) := "010";
constant BUS_REG : STD_LOGIC_VECTOR(2 downto 0) := "011";
constant BUS_MMU : STD_LOGIC_VECTOR(2 downto 0) := "100";
constant BUS_ALU : STD_LOGIC_VECTOR(2 downto 0) := "101";

constant FLAG_ZERO : integer := 7;
constant FLAG_SUB : integer := 6;
constant FLAG_HALF_CARRY : integer := 5;
constant FLAG_CARRY : integer := 4;

function is_zero(bool : STD_LOGIC_VECTOR) return std_logic;
function to_HexChar(Value : STD_LOGIC_VECTOR(7 downto 0)) return string;
function to_DHexChar(Value : STD_LOGIC_VECTOR(15 downto 0)) return string;
function to_String(a : STD_LOGIC_VECTOR) return string;

procedure echo (arg : in string := "");
procedure print (arg : in string := "");

end package common;

package body common is 

function is_zero(bool : STD_LOGIC_VECTOR) return std_logic is
   begin
     if (bool = x"00") then
      return '1';
     else
      return '0';
     end if;
end function is_zero;

function to_DHexChar(Value : STD_LOGIC_VECTOR(15 downto 0)) return string is
  constant HEX : STRING := "0123456789ABCDEF";
begin
  return "x" & HEX(to_integer(unsigned(Value(15 downto 12))) + 1) & HEX(to_integer(unsigned(Value(11 downto 8))) + 1) & HEX(to_integer(unsigned(Value(7 downto 4))) + 1) & HEX(to_integer(unsigned(Value(3 downto 0))) + 1);
end function;

function to_HexChar(Value : STD_LOGIC_VECTOR(7 downto 0)) return string is
  constant HEX : STRING := "0123456789ABCDEF";
begin
  return "x" & HEX(to_integer(unsigned(Value(7 downto 4))) + 1) & HEX(to_integer(unsigned(Value(3 downto 0))) + 1);
end function;

function to_String ( a: std_logic_vector) return string is
variable b : string (1 to a'length) := (others => NUL);
variable stri : integer := 1; 
begin
    for i in a'range loop
        b(stri) := std_logic'image(a((i)))(2);
    stri := stri+1;
    end loop;
return b;
end function;

procedure echo (arg : in string := "") is
begin
  std.textio.write(std.textio.output, arg & LF);
end procedure echo;

procedure print (arg : in string := "") is
begin
  std.textio.write(std.textio.output, arg);
end procedure print;

end package body common;
