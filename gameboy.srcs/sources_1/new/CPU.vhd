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
use gameboy.Common.all;

entity CPU is
    Port ( clk : in STD_LOGIC;
    	   rst_n : in STD_LOGIC := '1';
           irq_in : in STD_LOGIC := '0';
           int_ack : out STD_LOGIC :='0';
           bus_in : in STD_LOGIC_VECTOR (7 downto 0) := x"00";
           mw : out STD_LOGIC := '0';
           mr : out STD_LOGIC := '0';
           bus_sel : out STD_LOGIC_VECTOR (2 downto 0) := "100"; --BUS_MMU
           bus_mask_en : out STD_LOGIC := '0';
           rr : out STD_LOGIC := '0';
           rw : out STD_LOGIC := '0';
           reg_sel : out STD_LOGIC_VECTOR (3 downto 0) := "0000";
           temp_latch : out STD_LOGIC := '0';
           acu_latch : out STD_LOGIC := '0';
           drr : out STD_LOGIC := '0';
           drw : out STD_LOGIC := '0';
           dreg_sel : out STD_LOGIC_VECTOR (2 downto 0) := "000";
           addr_op : out STD_LOGIC_VECTOR (1 downto 0) := "01"; --OP_LATCH
           addr_mask : out STD_LOGIC := '0';
           alu_op : out STD_LOGIC_VECTOR (4 downto 0) := "11111"; --ALU_DISABLED
           alu_bit_sel : out STD_LOGIC_VECTOR (2 downto 0) := "000";
           alu_f_w : out STD_LOGIC_VECTOR (1 downto 0) := "00";
           f_in : in STD_LOGIC_vector(7 downto 4) := "0000";
           tmp_out : out STD_LOGIC;
           STOP : out STD_LOGIC:= '0');
end CPU;

architecture Behavioral of CPU is

type CPU_STATE is (load_op, load_imm, exec, halt, interrupt, fault);
SIGNAL t_cycle : UNSIGNED (1 downto 0) := "00";
SIGNAL m_cycle : UNSIGNED (2 downto 0) := "000";
SIGNAL state : CPU_STATE := load_op;
SIGNAL IME_REQ : STD_LOGIC := '0';
SIGNAL IME : STD_LOGIC := '0';
SIGNAL cb_op : STD_LOGIC:= '0';
SIGNAL reg_op : STD_LOGIC_VECTOR (8 downto 0) :="000000000";
SIGNAL check_reg : STD_LOGIC:= '0';
SIGNAL carry_reg : STD_LOGIC:= '0';

begin
process(clk)
variable CIR : STD_LOGIC_VECTOR (8 downto 0);

begin
    if rising_edge(clk) then
	--double check - can instructions not read/write same reg except A?
		if rst_n = '0' then
			t_cycle <= "00";
			m_cycle <= "000";
			state <= load_op;
			IME <= '0';
			IME_REQ <= '0';
			cb_op <= '0';
			CIR := "000000000";
			reg_op <= "000000000";
			MR <= '0';
			MW <= '0';
			addr_op <= OP_LATCH;
			dreg_sel <= REG_PC;
			rw <= '0';
			rr <= '0';
			drr <= '0';
			drw <= '0';
			bus_sel <= "100";
			bus_mask_en <= '0';
			int_ack <= '0';
		else
			if t_cycle = "00" AND m_cycle = "000" AND state = load_op then
				CIR := cb_op & bus_in;
				reg_op <= cb_op & bus_in;
				if bus_in /= x"0CB" then
					tmp_out <= '1';
				else
					tmp_out <= '0';
				end if;
			else
				CIR := reg_op;
				tmp_out <= '0';
			end if;
			-- Cycle FSM
			case t_cycle is
				when "00" => --Read
					if state = load_op OR state = load_imm OR (state = halt AND irq_in = '1') then
						mr <= '1';
						mw <= '0';
						addr_op <= OP_LATCH;
						dreg_sel <= REG_PC;
						rw <= '0';
						rr <= '0';
						drr <= '1';
						drw <= '0';
						if (state = load_op) then
							if m_cycle /= "000" then
								echo("M CYCLE PROBLEM");
								STOP <= '1';
							end if;
							if (irq_in = '1' AND IME = '1' AND cb_op = '0') then
								echo("Interrupt Fired");
								CIR := "0" & x"DD";
								reg_op <= "0" & x"DD";
							end if;
							if (bus_in = x"CB" AND cb_op = '0') then
								cb_op <= '1';
							else
								cb_op <= '0';
								echo ("Executing OP" & to_DHexChar("0000000" & CIR));
							end if;
							if (IME_REQ = '1') then
								IME_REQ <= '0';
								IME <= '1';
							end if;
						end if;
					end if;
				when "01" => --Fetch
					NULL;
				when "10" => --Exec
					if (state = load_op OR state = load_imm) then
						mw <= '0';
					end if;
				when "11" => --READ/WRITE
					if (state = load_op OR state = load_imm) then
						bus_sel <= BUS_MMU;
						addr_op <= OP_INC;
						dreg_sel <= REG_PC;
						drr <= '0';
						drw <= '1';
						mr <= '0';
					end if;
					if (state = load_op OR state = halt) then
						m_cycle <= "000";
					else
						m_cycle <= m_cycle + 1;
					end if;
					when others =>
						NULL;
		   end case;
	
		   case CIR(8 downto 4) is
				when "00000" | "00001" | "00010" | "00011" => -- Top 64 instructions
					case CIR(3 downto 0) is
						when x"0" | x"8" => -- JR
							if (CIR = x"000") then
								NULL; --NOP
							elsif CIR = x"010" then
								STOP <= '1';
								echo("STOPPED!");
							elsif CIR = x"008" then --LD nn, SP
								if m_cycle="000" then
									if (t_cycle="10") then
										state <= load_imm;
									elsif (t_cycle="11") then
										rw <= '1';
										reg_sel <= REG_Z;
									end if;
								elsif m_cycle="001" AND t_cycle="11" then
										rw <= '1';
										reg_sel <= REG_W;
								elsif m_cycle="010" OR m_cycle="011" then
									case t_cycle is
										when "00" =>
											mr <= '0';
											rr <= '1';
											rw <= '0';
											state <= exec;
											dreg_sel <= REG_WZ;
											bus_sel <= BUS_REG;
											if m_cycle="010" then
												reg_sel <= REG_SPL;
											else
												reg_sel <= REG_SPH;
												addr_op <= OP_INC;
											end if;
										when "01" =>
											mr <= '0';
											mw <= '1';
										when "11" =>
											mw <= '0';
											rr <= '0';
											rw <= '0';
											if m_cycle="011" then
												state <= load_imm;
												bus_sel <= BUS_MMU;
											end if;
										when others =>
											NULL;
									end case;
								elsif m_cycle="100" then
									state <= load_op;
								end if;
							elsif (m_cycle="000" AND t_cycle="00") then --JR r8
								alu_op <= ALU_DISABLED;
								bus_sel <= BUS_ALU;
							elsif (m_cycle="000" AND t_cycle="01") then
								if (CIR = x"020") then
									check_reg <= NOT f_in(FLAG_ZERO);
								elsif (CIR = x"028") then
									check_reg <= f_in(FLAG_ZERO);
								elsif (CIR = x"030") then
								   check_reg <= NOT f_in(FLAG_CARRY);
								elsif (CIR = x"038") then
									check_reg <= f_in(FLAG_CARRY);
								else
									check_reg <= '1';
								end if;
								state <= load_imm;
								bus_sel <= BUS_MMU;
							elsif (m_cycle="000" AND t_cycle="11") then
								reg_sel <= REG_Z;
								rw <= '1';
								alu_op <= ALU_ADD;
								temp_latch <= '1';
								acu_latch <= '1';
							elsif m_cycle="001" then
								if check_reg = '0' then
									state <= load_op;
									temp_latch <= '0';
									acu_latch <= '0';
								else
									case t_cycle is
									   when "00" =>
											acu_latch <= '0';
											rr <= '1';
											rw <= '0';
											reg_sel <= REG_PCL;
											bus_sel <= BUS_REG;
											mr <= '0';
										when "01" =>
											carry_reg <= f_in(FLAG_CARRY);
											temp_latch <= '0';
											bus_sel <= BUS_ALU;
											rr <= '0';
											rw <= '1';
										when "10" =>
											if (carry_reg xor f_in(FLAG_CARRY)) = '1' then
												if (f_in(FLAG_CARRY) = '1') then
													alu_op <= ALU_INC;
												else
													alu_op <= ALU_DEC;
												end if;
												reg_sel <= REG_PCH;
												acu_latch <= '1';
												bus_sel <= BUS_REG;
												carry_reg <= '1';
												rr <= '1';
											else
												carry_reg <= '0';
												rr <= '0';
											end if;
											rw <= '0';
											addr_op <= OP_LATCH;
										when "11" =>
											if (carry_reg = '1') then
												rw <= '1';
												bus_sel <= BUS_ALU;
											end if;
											acu_latch <= '0';
											addr_op <= OP_NONE;
										when others =>
											NULL;
									end case;
								end if;
							elsif (m_cycle="010" AND t_cycle="00") then
								bus_sel <= BUS_MMU;
								drw <= '0';
							elsif (m_cycle="010" AND t_cycle="10") then
								state <= load_op;
							end if;
						when x"1" => -- LD (double reg)
							if (m_cycle="000" AND t_cycle="10") then
								state <= load_imm;
							elsif (m_cycle="000" AND t_cycle="11") then
								rw <= '1';
								if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
									reg_sel <= REG_SPL;
								else
									reg_sel <= '0' & CIR(5 downto 4) & '1';
								end if;
							elsif (m_cycle="001" AND t_cycle="11") then
								rw <= '1';
								if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
									reg_sel <= REG_SPH;
								else
									reg_sel <= '0' & CIR(5 downto 4) & '0';
								end if;
							elsif (m_cycle="010") then
								state <= load_op;
							end if;
						when x"2" => -- LD xx, A
							if (m_cycle="000" AND t_cycle="00") then
								state <= exec;
								mr <= '0';
								mw <= '1';
								rr <= '1';
								drr <= '1';
								reg_sel <= REG_A;
								bus_sel <= BUS_REG;
								addr_op <= OP_LATCH;
								if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
									dreg_sel <= REG_HL;
								else
									dreg_sel <= '0' & CIR(5 downto 4);
								end if;
							elsif (m_cycle="000" AND t_cycle="10") then
								mw <= '0';
								case ('0' & CIR(5 downto 4)) is
									when REG_HL =>
										addr_op <= OP_INC;
									when REG_SP =>
										addr_op <= OP_DEC;
									when others =>
										addr_op <= OP_NONE;
								end case;
								bus_sel <= BUS_MMU;
								drw <= '1';
							elsif (m_cycle="000" AND t_cycle="11") then
								drw <= '0';
								drr <= '0';
								rr <= '0';
								dreg_sel <= REG_PC;
								addr_op <= OP_LATCH;
								state <= load_imm;
							elsif (m_cycle="001" AND t_cycle="00") then
								state <= load_op;
							end if;
						when x"3" => -- INC (double reg)
							if (m_cycle="000") then
								case t_cycle is
								   when "00" =>
										mr <= '0';
										dreg_sel <= '0' & CIR(5 downto 4);
										state <= exec;
									when "01" =>
										addr_op <= OP_INC;
										drr <= '0';
									when "10" =>
										drw <= '1';
									when "11" =>
										drw <= '0';
										state <= load_imm;
									when others =>
										NULL;
								end case;
							else
								 state <= load_op;
							end if;
						when x"4" | x"5" | x"C" | x"D" => -- INC / DEC (single reg)
							if CIR(5 downto 3) = REG_M(2 downto 0) then
								if m_cycle="000" then
									case t_cycle is
										when "00" =>
											state <= exec;
											dreg_sel <= REG_HL;
										when "10" =>
											bus_sel <= BUS_MMU;
										when "11" =>
											mr <= '0';
											reg_sel <= REG_Z;
											rw <= '1';
										when others =>
											NULL;
									end case;
								elsif m_cycle="010" AND t_cycle="00" then
									mw <= '0';
									state <= load_op;
									bus_sel <= BUS_MMU;
								end if;
							end if;
							if CIR(5 downto 3) /= REG_M(2 downto 0) OR m_cycle="001" then
								case t_cycle is
									when "00" =>
										if CIR(5 downto 3) = REG_M(2 downto 0) then
											reg_sel <= REG_Z;
										else
											reg_sel <= '0' & CIR(5 downto 3);
										end if;
										rr <= '1';
										rw <= '0';
										bus_sel <= BUS_REG;
										if CIR(0) = '0' then
											alu_op <= ALU_INC;
										else
											alu_op <= ALU_DEC;
										end if;
										acu_latch <= '1';
									when "01" =>
										acu_latch <= '0';
										rw <= '0';
										rr <= '0';
										bus_sel <= BUS_ALU;
									when "10" =>
										rw <= '1';
										alu_f_w <= OP_LATCH;
										if CIR(5 downto 3) = REG_M(2 downto 0) then
											mw <= '1';
										end if;
									when "11" =>
										rw <= '0';
										alu_f_w <= OP_NONE;
										if CIR(5 downto 3) = REG_M(2 downto 0) then
											state <= load_imm;
										end if;
									when others =>
										NULL;
								end case;
							end if;
						when x"6" | x"E" => -- LD d8
							if CIR = x"036" then
								if (m_cycle="000" AND t_cycle="10") then
									state <= load_imm;
								elsif (m_cycle="000" AND t_cycle="11") then
									rw <= '1';
									reg_sel <= REG_Z;
								elsif (m_cycle="001" AND t_cycle="00") then
									state <= exec;
									mr <= '0';
									mw <= '1';
									rr <= '1';
									bus_sel <= BUS_REG;
									dreg_sel <= REG_HL;
								elsif (m_cycle="001" AND t_cycle="10") then
									state <= load_imm;
									mw <= '0';
								elsif (m_cycle="001" AND t_cycle="11") then
									drw <= '0';
								elsif (m_cycle="010") then
									state <= load_op;
								end if;
							else
								if (m_cycle="000" AND t_cycle="10") then
									state <= load_imm;
								elsif (m_cycle="000" AND t_cycle="11") then
									rw <= '1';
									reg_sel <= '0' & CIR(5 downto 3);
								elsif (m_cycle="001") then
									state <= load_op;
								end if;
							end if;
						when x"7" | x"F" => -- RLCA / RLA / DAA / SCF / RRCA / RRA / CPL / CCF
							case t_cycle is
								when "00" =>
									reg_sel <= REG_A;
									rr <= '1';
									bus_sel <= BUS_REG;
									temp_latch <= '1';
									acu_latch <= '1';
									case CIR(5 downto 3) is 
										when "000" =>
											alu_op <= ALU_RLCA;
										when "001" =>
											alu_op <= ALU_RRCA;
										when "010" =>
											alu_op <= ALU_RLA;
										when "011" =>
											alu_op <= ALU_RRA;
										when "100" =>
											alu_op <= ALU_DAA;
										when "101" =>
											alu_op <= ALU_NOT;
										when "110" =>
											alu_op <= ALU_SCF;
										when "111" =>
											alu_op <= ALU_CCF;
										when others =>
											NULL;
									end case;
								when "01" =>
									temp_latch <= '0';
									acu_latch <= '0';
									bus_sel <= BUS_ALU;
									rr <= '0';
									rw <= '1';
									alu_f_w <= OP_LATCH;
								when "10" =>
									rw <= '0';
									alu_f_w <= OP_NONE;
								when others =>
									NULL;
							end case;
						when x"9" => -- ADD (double reg)
							case t_cycle is
							   when "00" =>
									if (m_cycle = "000") then
										reg_sel <= REG_L;
										state <= exec;
										mr <= '0';
									else
										reg_sel <= REG_H;
									end if;
									rr <= '1';
									bus_sel <= BUS_REG;
									alu_op <= ALU_ADD(4 downto 1) & m_cycle(0);
									acu_latch <= '1';
								when "01" =>
									acu_latch <= '0';
									temp_latch <= '1';
									if CIR(5 downto 4) = REG_SP then
										if m_cycle="000" then
											reg_sel <= REG_SPL;
										else
											reg_sel <= REG_SPH;
										end if;
									else
										reg_sel <= '0' & CIR(5 downto 4) & (NOT m_cycle(0));
									end if;  
								when "10" =>
									rw <= '1';
									rr <= '0';
									temp_latch <= '0';
									alu_f_w <= OP_LATCH_NO_ZERO;
									if (m_cycle = "000") then
										reg_sel <= REG_L;
									else
										reg_sel <= REG_H;
										state <= load_op;
									end if;
									bus_sel <= BUS_ALU;
								when "11" =>
									alu_f_w <= OP_NONE;
									rw <= '0';
									if m_cycle="000" then
										state <= load_imm;
									end if;
								when others =>
									NULL;
							end case;
						when x"A" => -- LD A, XX
							if (m_cycle="000" AND t_cycle="00") then
								state <= exec;
								drr <= '1';
								if CIR(5 downto 4) = REG_SP(1 downto 0) then
									dreg_sel <= REG_HL;
								else
									dreg_sel <= '0' & CIR(5 downto 4);
								end if;
							elsif (m_cycle="000" AND t_cycle="11") then
								case '0' & CIR(5 downto 4) is
									when REG_HL =>
										addr_op <= OP_INC;
									when REG_SP =>
										addr_op <= OP_DEC;
									when others =>
										addr_op <= OP_NONE;
								end case;
								mr <= '0';
								drw <= '1';
								drr <= '0';
								state <= load_imm;
								reg_sel <= REG_A;
							elsif (m_cycle="001" AND t_cycle="00") then
								state <= load_op;
								rw <= '1';
							elsif (m_cycle="001" AND t_cycle="01") then
								rw <= '0';
							end if;
						when x"B" => -- DEC (double reg)
							if (m_cycle="000") then
								case t_cycle is
								   when "00" =>
										mr <= '0';
										dreg_sel <= '0' & CIR(5 downto 4);
										state <= exec;
									when "01" =>
										addr_op <= OP_DEC;
										drr <= '0';
									when "11" =>
										drw <= '1';
										state <= load_imm;
									when others =>
										NULL;
								end case;
							else
								state <= load_op;
							end if;
						when others =>
							NULL;
					end case;
				when "00100" | "00101" | "00110" | "00111" => -- LD (single op)
					if (CIR = x"076") then
						if t_cycle = "00" then
							if irq_in = '0' then
								state <= halt;
								echo("HALTED");
							else
								state <= load_op;
								echo("HALT Skipped");
							end if;
						end if;
					else
						if CIR(2 downto 0) = REG_M(2 downto 0) and m_cycle="000" then
							state <= load_imm;
							dreg_sel <= REG_HL;
							addr_op <= OP_LATCH;
							drw <= '0';
							temp_latch <= '1';
						else
							case t_cycle is
							   when "00" =>
									reg_sel <= '0' & CIR(2 downto 0);
									rr <= '1';
									rw <= '0';
									temp_latch <= '1';
									if CIR(5 downto 3) = REG_M(2 downto 0) then
										if m_cycle = "000" then
											mr <= '0';
											mw <= '0';
											state <= exec;
											dreg_sel <= REG_HL;
										else
											state <= load_op;
											drw <= '0';
										end if;
									end if;
									if CIR(2 downto 0) = REG_M(2 downto 0) then
										bus_sel <= BUS_MMU;
										temp_latch <= '0';
										state <= load_op;
									else
										bus_sel <= BUS_REG;
									end if;
								when "01" =>
									temp_latch <= '0';
									if CIR(5 downto 3) /= REG_M(2 downto 0) then
										reg_sel <= '0' & CIR(5 downto 3);
										rr <= '0';
										rw <= '1';
										alu_op <= ALU_DISABLED;
										bus_sel <= BUS_ALU;
									elsif m_cycle = "000" then
										mw <= '1';
									end if;
								when "10" =>
									if CIR(5 downto 3) = REG_M(2 downto 0) AND m_cycle = "000" then
										state <= load_imm;
									end if;
								when "11" =>
									if CIR(5 downto 3) = REG_M(2 downto 0) AND m_cycle = "000" then
										addr_op <= OP_LATCH;
									end if;
									rw <= '0';
									mw <= '0';
								when others =>
									NULL;
							end case;
						end if;
					end if;
				when "01000" | "01001" | "01010" | "01011" => -- ADD / ADC / SUB / SBC / AND / XOR / OR / CP
					if CIR(2 downto 0) = REG_M(2 downto 0) then
						if m_cycle="000" then
							state <= load_imm;
							dreg_sel <= REG_HL;
							addr_op <= OP_LATCH;
							drw <= '0';
							temp_latch <= '1';
						else
							state <= load_op;
						end if;
					end if;
					if CIR(2 downto 0) /= REG_M(2 downto 0) or m_cycle="001" then
						case t_cycle is
						   when "00" =>
								reg_sel <= '0' & CIR(2 downto 0);
								rr <= '1';
								if CIR(2 downto 0) = REG_M(2 downto 0) then
									bus_sel <= BUS_MMU;
									temp_latch <= '0';
								else
									bus_sel <= BUS_REG;
									temp_latch <= '1';
								end if;
								if CIR(5) = '1' then
									alu_op <= CIR(6 downto 3) & '0';
								else
									alu_op <= "000" & CIR(4 downto 3);
								end if;
							when "01" =>
								temp_latch <= '0';
								reg_sel <= REG_A;
								bus_sel <= BUS_REG;
								acu_latch <= '1';
							when "10" =>
								acu_latch <= '0';
								bus_sel <= BUS_ALU;
								rr <= '0';
								rw <= '1';
								alu_f_w <= OP_LATCH;
							when "11" =>
								rw <= '0';
								alu_f_w <= OP_NONE;
							when others =>
								NULL;
						end case;
					end if;
				when "01100" | "01101" | "01110" | "01111" => --Jumps / MSC
					case CIR(3 downto 0) is
						when x"1"  => --POP
							case t_cycle is
								when "00" =>
									rw <= '0';
									if m_cycle="000" then
										state <= load_imm;
										dreg_sel <= REG_SP;
									elsif m_cycle="001" then
										dreg_sel <= REG_SP;
									end if;
								when "10" =>
									if m_cycle="000" OR m_cycle="001" then
										dreg_sel <= REG_SP;
									elsif m_cycle="010" then
										state <= load_op;
									end if;
								when "11" =>
									if m_cycle="000" then
										rw <= '1';
										if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
											reg_sel <= REG_F;
										else
											reg_sel <= '0' & CIR(5 downto 4) & '1';
										end if;
									elsif m_cycle="001" then
										rw <= '1';
										if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
											reg_sel <= reg_A;
										else
											reg_sel <= '0' & CIR(5 downto 4) & '0';
										end if;
									end if;
								when others =>
									NULL;
							end case;
						when x"4" | x"C" | x"D"  => --CALL / Interrupt
							if CIR(5) = '1' then
								state <= fault;
								STOP <= '1';
								echo("INVALID OP " & to_DHexChar("0000000" & CIR));
							elsif CIR = x"0DD" then --Interrupt
								if (irq_in = '0' OR IME='0') AND m_cycle="000" AND t_cycle="00" then
									state <= fault;
									STOP <= '1';
									echo("INVALID OP " & to_DHexChar("0000000" & CIR));
								end if;
								case t_cycle is
									when "00" =>
										case m_cycle is
											when "000" =>
												IME <= '0';
												IME_REQ <= '0';
												int_ack <= '1';
												state <= load_imm;
											when "001" =>
												mr <= '0';
												mw <= '0';
												dreg_sel <= REG_SP;
												int_ack <= '0';
											when "010" =>
												dreg_sel <= REG_SP;
												mr <= '0';
												mw <= '1';
												rr <= '1';
												reg_sel <= REG_PCH;
												bus_sel <= BUS_REG;
											when "011" =>
												dreg_sel <= REG_SP;
												mr <= '0';
												mw <= '1';
												rr <= '1';
												reg_sel <= REG_PCL;
												bus_sel <= BUS_REG;
											when "100" =>
												dreg_sel <= REG_FX;
												reg_sel <= REG_Z;
												addr_mask <= '0';
											when others =>
												NULL;
										end case;
									when "10" =>
										rr <= '0';
										if m_cycle="000" then
											addr_op <= OP_DEC;
										elsif m_cycle="001" OR m_cycle="010" then
											addr_op <= OP_NONE;
										elsif m_cycle="100" then
											state <= load_op;
										end if;
									when "11" =>
										if m_cycle="001" OR m_cycle="010" then
											drw <= '1';
											dreg_sel <= REG_SP;
											addr_op <= OP_DEC;
										elsif m_cycle="011" then
											drw <= '0';
											dreg_sel <= REG_SP;
											addr_op <= OP_LATCH;
										elsif m_cycle="000" then
											rw <= '1';
											reg_sel <= REG_Z;
										end if;
									when others =>
										NULL;
								end case;
							else --CALL
								case t_cycle is
									when "00" =>
										case m_cycle is
											when "000" =>
												alu_op <= ALU_DISABLED;
												state <= load_imm;
												bus_sel <= BUS_MMU;
											when "010" =>
												if check_reg = '1' then
													mr <= '0';
													mw <= '0';
													dreg_sel <= REG_SP;
												else
													state <= load_op;
												end if;
											when "011" =>
												dreg_sel <= REG_SP;
												mr <= '0';
												mw <= '1';
												rr <= '1';
												reg_sel <= REG_PCH;
												bus_sel <= BUS_REG;
											when "100" =>
												dreg_sel <= REG_SP;
												mw <= '1';
												mr <= '0';
												rr <= '1';
												reg_sel <= REG_PCL;
												bus_sel <= BUS_REG;
											when "101" =>
												dreg_sel <= REG_WZ;
											when others =>
												NULL;
										end case;
									when "01" =>
										if m_cycle = "000" then
											if (CIR = x"0C4") then
												check_reg <= NOT f_in(FLAG_ZERO);
											elsif (CIR = x"0CC") then
												check_reg <= f_in(FLAG_ZERO);
											elsif (CIR = x"0D4") then
												check_reg <= NOT f_in(FLAG_CARRY);
											elsif (CIR = x"0DC") then
												check_reg <= f_in(FLAG_CARRY);
											else --0CD
												check_reg <= '1';
											end if;
											bus_sel <= BUS_MMU;
										end if;
									when "10" =>
										rr <= '0';
										if m_cycle="010" OR m_cycle="011" then
											addr_op <= OP_NONE;
										elsif m_cycle="101" then
											state <= load_op;
										end if;
									when "11" =>
										if (m_cycle="010" OR m_cycle="011") AND check_reg = '1' then
											drw <= '1';
											dreg_sel <= REG_SP;
											addr_op <= OP_DEC;
										elsif m_cycle="000" then
											rw <= '1';
											reg_sel <= REG_Z;
										elsif m_cycle="100" then
											drw <= '0';
											dreg_sel <= REG_SP;
											addr_op <= OP_LATCH;
										elsif m_cycle="001" then
											rw <= '1';
											reg_sel <= REG_W;
										end if;
									when others =>
										NULL;
								end case;
							end if;
						when x"5"  => --PUSH
							case t_cycle is
								when "00" =>
									if m_cycle="000" then
										mr <= '0';
										mw <= '0';
										dreg_sel <= REG_SP;
										state <= load_imm;
									elsif m_cycle="001" then
										dreg_sel <= REG_SP;
										mr <= '0';
										mw <= '1';
										bus_sel <= BUS_REG;
										rr <= '1';
										if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
											reg_sel <= reg_A;
										else
											reg_sel <= '0' & CIR(5 downto 4) & '0';
										end if;
									elsif m_cycle="010" then
										dreg_sel <= REG_SP;
										mr <= '0';
										mw <= '1';
										if (CIR(5 downto 4) = REG_SP(1 downto 0)) then
											reg_sel <= REG_F;
										else
											reg_sel <= '0' & CIR(5 downto 4) & '1';
										end if;
										bus_sel <= BUS_REG;
										rr <= '1';
									end if;
								when "10" =>
									rr <= '0';
									if m_cycle="011" then
										state <= load_op;
									end if;
								when "11" =>
									if m_cycle="000" OR m_cycle="001" OR m_cycle="010" then
										dreg_sel <= REG_SP;
										if m_cycle="010" then
											addr_op <= OP_LATCH;
										else
											addr_op <= OP_DEC;
										end if;
										if m_cycle="010" then
											drw <= '0';
										end if;
									end if;
								when others =>
									NULL;
							end case;
						when x"6" | x"E"  => -- ADD / SUB / AND / OR / ADC / SBC / XOR / CP d8
							if (m_cycle="000" AND t_cycle="00") then
								state <= load_imm;
							elsif (m_cycle="000" AND t_cycle="11") then
								reg_sel <= REG_Z;
								rw <= '1';
							elsif (m_cycle="001") then
								case t_cycle is
								   when "00" =>
										if CIR(5) = '0' then
											alu_op <= "000" & CIR(4 downto 3);
										else
											alu_op <= '0' & CIR(5 downto 3) & '0';
										end if;
										temp_latch <= '1';
										state <= load_op;
										rr <= '1';
										bus_sel <= BUS_REG;
									when "01" =>
										reg_sel <= REG_A;
										acu_latch <= '1';
										temp_latch <= '0';
									when "10" =>
										acu_latch <= '0';
										bus_sel <= BUS_ALU;
										rr <= '0';
										rw <= '1';
										alu_f_w <= OP_LATCH;
									when "11" =>
										rw <= '0';
										alu_f_w <= OP_NONE;
									when others =>
										NULL;
								end case;
							end if;
						when x"7" | x"F"  => --RST
							case t_cycle is
								when "00" =>
									case m_cycle is
										when "000" =>
											mw <= '0';
											bus_mask_en <= '1';
											reg_sel <= REG_Z;
											rw <= '1';
										when "001" =>
											dreg_sel <= REG_SP;
											mr <= '0';
											mw <= '1';
											rr <= '1';
											reg_sel <= REG_PCH;
											bus_sel <= BUS_REG;
										when "010" =>
											dreg_sel <= REG_SP;
											rr <= '1';
											reg_sel <= REG_PCL;
											bus_sel <= BUS_REG;
											mw <= '1';
											mr <= '0';
										when "011" =>
											dreg_sel <= REG_FX;
											addr_mask <= '0';
										when others =>
											NULL;
									end case;
								when "01" =>
									if m_cycle="000" then
										dreg_sel <= REG_SP;
										rw <= '0';
										mr <= '0';
									end if;
								when "10" =>
									rr <= '0';
									bus_mask_en <= '0';
									if m_cycle="000" OR m_cycle="001" OR m_cycle="010" then
										dreg_sel <= REG_SP;
										state <= load_imm; --May need addr op similar to call
									elsif m_cycle="011" then
										state <= load_op;
									end if;
								when "11" =>
									if m_cycle="000" OR m_cycle="001" OR m_cycle="010" then
										dreg_sel <= REG_SP;
										if m_cycle="010" then
											addr_op <= OP_LATCH;
										else
											addr_op <= OP_DEC;
										end if;
										if m_cycle="000" OR m_cycle="001" then
											drw <= '1';
										elsif m_cycle="010" then
											drw <= '0';
										end if;
									end if;
								when others =>
									NULL;
							end case;
						when x"B"  =>
							if (CIR = x"0FB") then
								IME_REQ <= '1';
								echo("IME Enabled");
							elsif (CIR /= x"CB") then
								state <= fault;
								STOP <= '1';
								echo("INVALID OP DB/EB");
							end if;
						when others =>
							if CIR(5) = '1' then --BOTTOM
								case CIR(3 downto 0) is
									when x"0" => --LDH
										if m_cycle="000" then
											if (t_cycle="10") then
												state <= load_imm;
											elsif (t_cycle="11") then
												rw <= '1';
												reg_sel <= REG_Z;
											end if;
										elsif m_cycle="001" then
											if t_cycle = "00" then
												mr <= CIR(4);
												mw <= '0';
												rr <= NOT CIR(4);
												rw <= '0';
												state <= exec;
												dreg_sel <= REG_FX;
												addr_mask <= '1';
												reg_sel <= REG_Z;
												if CIR(4) = '1' then
													bus_sel <= BUS_MMU;
												else
													bus_sel <= BUS_REG;
												end if;
											elsif t_cycle="01" then
												rw <= CIR(4);
												mw <= NOT CIR(4);
												reg_sel <= REG_A;
												addr_op <= OP_NONE;
											elsif t_cycle="11" then
												mr <= '0';
												mw <= '0';
												rr <= '0';
												bus_sel <= BUS_MMU;
												state <= load_imm;
												addr_mask <= '0';
											end if;
										else
											state <= load_op;
										end if;
									when x"2" => --LD (C)
										if m_cycle="000" then
											if t_cycle = "00" then
												mr <= CIR(4);
												mw <= '0';
												rr <= '1';
												state <= exec;
												dreg_sel <= REG_FX;
												addr_mask <= '1';
												bus_sel <= BUS_REG;
												reg_sel <= REG_C;
											elsif t_cycle = "01" then
												mw <= NOT CIR(4);
												rr <= NOT CIR(4);
												rw <= CIR(4);
												reg_sel <= REG_A;
												addr_op <= OP_NONE;
											elsif t_cycle = "11" then
												mw <= '0';
												rr <= '0';
												bus_sel <= BUS_MMU;
												drr <= '0';
												state <= load_imm;
												addr_mask <= '0';
											end if;
										else
											state <= load_op;
										end if;
									when x"3" => --DI
										if CIR = x"0E3" then
											state <= fault;
											STOP <= '1';
											echo("INVALID OP (E3)");
										elsif t_cycle = "01" then --F3
											IME <= '0';
											IME_REQ <= '0';
										end if;
									when x"A" => --LD A addr
										if m_cycle="000" then
											if (t_cycle="10") then
												state <= load_imm;
											elsif (t_cycle="11") then
												rw <= '1';
												reg_sel <= REG_Z;
											end if;
										elsif m_cycle="001" AND t_cycle="11" then
												rw <= '1';
												reg_sel <= REG_W;
										elsif m_cycle="010" then
											case t_cycle is
												when "00" =>
													mr <= CIR(4);
													mw <= '0';
													rr <= NOT CIR(4);
													rw <= '0';
													state <= exec;
													dreg_sel <= REG_WZ;
													if CIR(4)='1' then
														bus_sel <= BUS_MMU;
													else
														bus_sel <= BUS_REG;
													end if;
													reg_sel <= REG_A;
												when "01" =>
													rw <= CIR(4);
													mw <= NOT CIR(4);
												when "11" =>
													rr <= '0';
													mw <= '0';
													bus_sel <= BUS_MMU;
													state <= load_imm;
												when others =>
													NULL;
											end case;
										elsif m_cycle="011" then
											state <= load_op;
										end if;
									when x"8" => --ADD SP r8 / LD HL, SP+r8
										if (m_cycle="000" AND t_cycle="00") then
											state <= load_imm;
										elsif (m_cycle="000" AND t_cycle="11") then
											reg_sel <= REG_Z;
											rw <= '1';
											alu_op <= ALU_ADD;
											temp_latch <= '1';
											acu_latch <= '1';
										elsif m_cycle="001" then
											case t_cycle is
											   when "00" =>
													acu_latch <= '0';
													rr <= '1';
													rw <= '0';
													reg_sel <= REG_SPL;
													bus_sel <= BUS_REG;
													mr <= '0';
												when "01" =>
													carry_reg <= f_in(FLAG_CARRY);
													temp_latch <= '0';
													bus_sel <= BUS_ALU;
													rr <= '0';
													rw <= '1';
													alu_f_w <= OP_BUS; --latch with no zero
													if CIR(4)='1' then
														reg_sel <= REG_L;
													else
														reg_sel <= REG_Z;
													end if;
												when "10" =>
													if (carry_reg xor f_in(FLAG_CARRY)) = '1' then
														if (f_in(FLAG_CARRY) = '1') then
															alu_op <= ALU_INC;
														else
															alu_op <= ALU_DEC;
														end if;
													else
														alu_op <= ALU_DISABLED; --Pass SPH through unchanged
													end if;
													reg_sel <= REG_SPH;
													temp_latch <= '1';
													acu_latch <= '1';
													bus_sel <= BUS_REG;
													rr <= '1';
													alu_f_w <= OP_NONE;
													rw <= '0';
												when "11" =>
													addr_op <= OP_LATCH;
													rw <= '1';
													bus_sel <= BUS_ALU;
													if CIR(4)='1' then
														reg_sel <= REG_H;
													else
														reg_sel <= REG_W;
													end if;
													acu_latch <= '0';
													drw <= '0';
												when others =>
													NULL;
											end case;
										elsif m_cycle="010" then
											if CIR=x"0E8" then
												case t_cycle is
													when "00" =>
														state <= exec;
														mr <= '0';
														dreg_sel <= REG_WZ;
													when "01" =>
														addr_op <= OP_NONE;
														drr <= '0';
													when "10" =>
														addr_op <= OP_NONE;
														drw <= '1';
														dreg_sel <= REG_SP;
													when "11" =>
														addr_op <= OP_NONE;
														state <= load_imm;
														drw <= '0';
													when others =>
														NULL;
												end case;
												temp_latch <= '0';
											else
												state <= load_op;
											end if;
										elsif (m_cycle="011" AND t_cycle="00") then
											state <= load_op;
										end if;
									when x"9" => --JP HL / LD SP HL
										if CIR = x"0F9" then
											if m_cycle = "00" then
												case t_cycle is
													when "00" =>
														state <= exec;
														mr <= '0';
														dreg_sel <= REG_HL;
													when "01" =>
														addr_op <= OP_NONE;
														drr <= '0';
													when "10" =>
														drw <= '1';
														addr_op <= OP_NONE;
														dreg_sel <= REG_SP;
													when "11" =>
														dreg_sel <= REG_SP;
														addr_op <= OP_NONE;
														state <= load_imm;
														drw <= '0';
													when others =>
														NULL;
												end case;
											else
												state <= load_op;
											end if;
										else --JP HL
											if t_cycle = "00" then
												dreg_sel <= REG_HL;
											elsif t_cycle = "10" then
												drr <= '0';
											end if;
										end if;
									when others =>
										NULL;
								end case;
							else
								case CIR(3 downto 0) is
									when x"0" | x"8" => --RET C
										case t_cycle is
											when "00" =>
												case m_cycle is
													when "000" =>
														state <= exec;
														mr <= '0';
														alu_op <= ALU_DISABLED;
														bus_sel <= BUS_ALU;
													when "001" =>
														mr <= '1';
														if check_reg = '0' then
															state <= load_op;
														else
															dreg_sel <= REG_SP;
															state <= load_imm;
														end if;
													when "010" =>
														dreg_sel <= REG_SP;
													when "011" =>
														mr <= '0';
													when "100" =>
														state <= load_op;
													when others =>
														NULL;
												end case;
											when "01" =>
												if (m_cycle = "000") then
													if (CIR = x"0C0") then
														check_reg <= NOT f_in(FLAG_ZERO);
													elsif (CIR = x"0C8") then
														check_reg <= f_in(FLAG_ZERO);
													elsif (CIR = x"0D0") then
														check_reg <= NOT f_in(FLAG_CARRY);
													elsif (CIR = x"0D8") then
														check_reg <= f_in(FLAG_CARRY);
													end if;
													bus_sel <= BUS_MMU;
												end if;
											when "10" =>
												if (m_cycle="001" OR m_cycle="010") AND check_reg = '1' then
													dreg_sel <= REG_SP;
												end if;
											when "11" =>
												if m_cycle="000" AND check_reg = '0' then
													state <= load_imm;
												elsif m_cycle="001" AND check_reg = '1' then
													rw <= '1';
													reg_sel <= REG_PCL;
													dreg_sel <= REG_SP;
												elsif m_cycle="010" then
													rw <= '1';
													reg_sel <= REG_PCH;
													dreg_sel <= REG_SP;
												elsif m_cycle="011" then
													drw <= '0';
													addr_op <= OP_LATCH;
												end if;
											when others =>
												NULL;
										end case;
									when x"9" => --RET / RETI
										case t_cycle is
											when "00" =>
												case m_cycle is
													when "000" =>
														dreg_sel <= REG_SP;
														state <= load_imm;
													when "001" =>
														dreg_sel <= REG_SP;
													when "010" =>
														mr <= '0';
													when "011" =>
														state <= load_op;
													when others =>
														NULL;
												end case;
											when "10" =>
												if m_cycle="000" OR m_cycle="001" then
													dreg_sel <= REG_SP;
												elsif CIR=x"0D9" then
													IME <= '1';
												end if;
											when "11" =>
												case m_cycle is
													when "000" =>
														rw <= '1';
														reg_sel <= REG_PCL;
														dreg_sel <= REG_SP;
													when "001" =>
														rw <= '1';
														reg_sel <= REG_PCH;
														dreg_sel <= REG_SP;
													when "010" =>
														drw <= '0';
														addr_op <= OP_LATCH;
													when others =>
														NULL;
												end case;
											when others =>
												NULL;
										end case;
									when x"2" | x"3" | x"A" => --JP
										if CIR = x"0D3" then
											state <= fault;
											STOP <= '1';
											echo("INVALID OP (D3)");
										else
											case t_cycle is
												when "00" =>
													if m_cycle="011" OR (m_cycle="010" AND check_reg='0') then
														state <= load_op;
														alu_op <= ALU_DISABLED;
														bus_sel <= BUS_ALU;
													elsif m_cycle="010" then
														dreg_sel <= REG_WZ;
														mr <= '0';
													end if;
												when "01" =>
													if (m_cycle = "001") then
														if (CIR = x"0C2") then
															check_reg <= NOT f_in(FLAG_ZERO);
														elsif (CIR = x"0CA") then
															check_reg <= f_in(FLAG_ZERO);
														elsif (CIR = x"0D2") then
															check_reg <= NOT f_in(FLAG_CARRY);
														elsif (CIR = x"0DA") then
															check_reg <= f_in(FLAG_CARRY);
														else --C3
															check_reg <= '1';
														end if;
														bus_sel <= BUS_MMU;
													end if;
												when "10" =>
													if m_cycle="000" then
														state <= load_imm;
														alu_op <= ALU_DISABLED;
													elsif m_cycle="010" AND check_reg='1' then
														addr_op <= OP_NONE;
													end if;
												when "11" =>
													if m_cycle="000" then
														reg_sel <= REG_Z;
														rw <= '1';
													elsif m_cycle="001" then
														reg_sel <= REG_W;
														rw <= '1';
													elsif m_cycle="010" AND check_reg='1' then
														addr_op <= OP_NONE;
													end if;
												when others =>
													NULL;
											end case;
										end if;
									when others =>
										NULL;
								end case;
							end if;
					end case;
				when "10000" | "10001" | "10010" | "10011" => --RLC / RRC / RL / RR / SLA / SRA / SWAP / SRL
					if CIR(2 downto 0) = REG_M(2 downto 0) then
						if m_cycle="000" then
							state <= exec;
							dreg_sel <= REG_HL;
							addr_op <= OP_LATCH;
							if (t_cycle="11") then
								rw <= '1';
								reg_sel <= REG_Z;
							end if;
						elsif m_cycle="001" then
							case t_cycle is
								when "01" =>
									mr <= '0';
									mw <= '1';
								when "11" =>
									mw <= '0';
									bus_sel <= BUS_MMU;
									state <= load_imm;
								when others =>
									NULL;
							end case;
						else
							state <= load_op;
						end if;
					end if;
					if (CIR(2 downto 0) /= REG_M(2 downto 0) AND m_cycle="000") OR m_cycle="001" then
						case t_cycle is
						   when "00" =>
								if CIR(2 downto 0) = REG_M(2 downto 0) then
									reg_sel <= REG_Z;
									rw <= '0';
								else
									reg_sel <= '0' & CIR(2 downto 0);
								end if;
								rr <= '1';
								bus_sel <= BUS_REG;
								temp_latch <= '1';
								alu_op <= "10" & CIR(5) & CIR(3) & CIR(4);
							when "01" =>
								temp_latch <= '0';
								bus_sel <= BUS_ALU;
								rr <= '0';
								if CIR(2 downto 0) /= REG_M(2 downto 0) then
									rw <= '1';
								end if;
								alu_f_w <= OP_LATCH;
							when "10" =>
								rw <= '0';
								alu_f_w <= OP_NONE;
							when "11" =>
								alu_op <= ALU_DISABLED;
							when others =>
								NULL;
						end case;
					end if;
				when "10100" | "10101" | "10110" | "10111" => --BIT
					if CIR(2 downto 0) = REG_M(2 downto 0) then
						if m_cycle="000" then
							state <= load_imm;
							dreg_sel <= REG_HL;
							addr_op <= OP_LATCH;
							drw <= '0';
							if (t_cycle="11") then
								rw <= '1';
								reg_sel <= REG_Z;
							end if;
						else
							state <= load_op;
						end if;
					end if;
					if CIR(2 downto 0) /= REG_M(2 downto 0) OR m_cycle="001" then
						case t_cycle is
						   when "00" =>
								if CIR(2 downto 0) = REG_M(2 downto 0) then
									reg_sel <= REG_Z;
									rw <= '0';
								else
									reg_sel <= '0' & CIR(2 downto 0);
								end if;
								bus_sel <= BUS_REG;
								alu_bit_sel <= CIR(5 downto 3);
								alu_op <= ALU_BIT;
								temp_latch <= '1';
								rr <= '1';
							when "01" =>
								temp_latch <= '0';
								rr <= '0';
								alu_f_w <= OP_LATCH;
							when "10" =>
								alu_f_w <= OP_NONE;
								alu_op <= ALU_DISABLED;
							when others =>
								NULL;
						end case;
					end if;
				when "11000" | "11001" | "11010" | "11011" | "11100" | "11101" | "11110" | "11111" => --RES / SET
					if CIR(2 downto 0) = REG_M(2 downto 0) then
						if m_cycle="000" then
							state <= exec;
							dreg_sel <= REG_HL;
							addr_op <= OP_LATCH;
						elsif m_cycle="001" then
							case t_cycle is
								when "01" =>
									mr <= '0';
									mw <= '1';
								when "11" =>
									mw <= '0';
									bus_sel <= BUS_MMU;
									state <= load_imm;
								when others =>
									NULL;
							end case;
						else
							state <= load_op;
						end if;
					end if;
					if (CIR(2 downto 0) /= REG_M(2 downto 0) AND m_cycle="000") OR m_cycle="001" then
						case t_cycle is
						   when "00" =>
								if CIR(2 downto 0) = REG_M(2 downto 0) then
									bus_sel <= BUS_MMU;
								else
									bus_sel <= BUS_REG;
									reg_sel <= '0' & CIR(2 downto 0);
									rr <= '1';
								end if;
								alu_op <= "11" & NOT CIR(6) & NOT CIR(6) & CIR(6);
								alu_bit_sel <= CIR(5 downto 3);
								temp_latch <= '1';
							when "01" =>
								bus_sel <= BUS_ALU;
								temp_latch <= '0';
								rr <= '0';
								if CIR(2 downto 0) /= REG_M(2 downto 0) then
									rw <= '1';
								end if;
							when "10" =>
								rw <= '0';
							when "11" =>
								alu_op <= ALU_DISABLED;
							when others =>
								NULL;
						end case;
					end if;
				 when others =>
					NULL;
			end case;
			t_cycle <= t_cycle + 1;
		end if;
    end if;
end process;

end Behavioral;
