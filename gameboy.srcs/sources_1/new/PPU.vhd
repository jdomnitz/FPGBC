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

entity PPU is
    Port ( clk : in STD_LOGIC;
    	   rst_n : in STD_LOGIC;
    	   we : in STD_LOGIC;
    	   re : in STD_LOGIC;
    	   vblk : out STD_LOGIC := '0';
    	   lcdc_out : out STD_LOGIC := '0';
           addr : in STD_LOGIC_VECTOR (15 downto 0);
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
           vram_e : out STD_LOGIC := '0';
           vram_wr : out STD_LOGIC := '0';
           vram_a : out STD_LOGIC_VECTOR (12 downto 0) := "0000000000000";
           dma_req : out STD_LOGIC := '0';
           vram_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           vram_data_out : out STD_LOGIC_VECTOR (7 downto 0);
           lcd_vsync : out STD_LOGIC;
           lcd_hsync : out STD_LOGIC;
           lcd_valid : out STD_LOGIC;
           lcd_pixel : out STD_LOGIC_VECTOR(1 downto 0);
           lcd_en : out STD_LOGIC;
           dma_addr : out STD_LOGIC_VECTOR (15 downto 0));
end PPU;

architecture Behavioral of PPU is
SIGNAL LCDC : STD_LOGIC_VECTOR (7 downto 0) := x"80";
SIGNAL STAT : STD_LOGIC_VECTOR (7 downto 3) := "00000";
SIGNAL SCY : UNSIGNED (7 downto 0);
SIGNAL SCX : UNSIGNED (7 downto 0);
SIGNAL LYC : UNSIGNED (7 downto 0) := x"FF";
SIGNAL DMA : STD_LOGIC_VECTOR(7 downto 0) := x"00";
SIGNAL WY : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL WX : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL BGP : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL OBP0 : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL OBP1 : STD_LOGIC_VECTOR (7 downto 0);
TYPE mem IS ARRAY(0 TO 159) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL OAM : mem;

SIGNAL mode : STD_LOGIC_VECTOR(1 downto 0) := "10";
SIGNAL LY : UNSIGNED(7 downto 0) := x"00";
SIGNAL CX : STD_LOGIC_VECTOR(8 downto 0) := "000000000";
SIGNAL CP : UNSIGNED(7 downto 0):= x"00";

type FETCHER_STATE is (fetch_map, fetch_high, fetch_low, push, pause);
SIGNAL bg_state : FETCHER_STATE := fetch_map;

--BG Pixel FIFO
type FIFO_DATA is array (0 to 15) of std_logic_vector(1 downto 0);
signal bg_FIFO_DATA : FIFO_DATA := (others => (others => '0'));
signal bg_WR_INDEX   : integer range 0 to 15 := 0;
signal bg_RD_INDEX   : integer range 0 to 15 := 0;
signal bg_FIFO_COUNT : integer range 0 to 16 := 0;
SIGNAL rst_fifos : STD_LOGIC := '0';
SIGNAL BG_div : STD_LOGIC := '0';
SIGNAL BG_valid : STD_LOGIC := '0';
SIGNAL FX : UNSIGNED(4 downto 0) := "00000";
SIGNAL bg_TILE : STD_LOGIC_VECTOR(12 downto 0) := "0000000000000";
SIGNAL bg_low : STD_LOGIC_VECTOR(7 downto 0) := x"00";
SIGNAL bg_high : STD_LOGIC_VECTOR(7 downto 0) := x"00";

SIGNAL BG_vram_rd : STD_LOGIC := '0';
SIGNAL BG_vram_a : STD_LOGIC_VECTOR (12 downto 0) := "0000000000000";
SIGNAL BG_vram_in : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL PP_vram_rd : STD_LOGIC := '0';
SIGNAL PP_vram_w : STD_LOGIC := '0';
SIGNAL PP_vram_a : STD_LOGIC_VECTOR (12 downto 0) := "0000000000000";
SIGNAL PP_vram_in : STD_LOGIC_VECTOR (7 downto 0);

begin

vram_arbiter : process(BG_vram_rd, BG_vram_a, PP_vram_rd, PP_vram_w, PP_vram_a, vram_data_in)
begin
	if PP_vram_rd = '1' OR PP_vram_w = '1' then
		vram_a <= PP_vram_a;
		vram_e <= PP_vram_rd OR PP_vram_w;
		vram_wr <= PP_vram_w;
		PP_vram_in <= vram_data_in;
		BG_vram_in <= x"FF";
	else
		vram_a <= BG_vram_a;
		vram_e <= BG_vram_rd;
		vram_wr <= '0';
		BG_vram_in <= vram_data_in;
		PP_vram_in <= x"FF";
	end if;
end process;

clock_gate : process(BG_valid, clk)
begin
	if BG_valid = '1' then
		lcd_valid <= clk;
	else
		lcd_valid <= '0';
	end if;
end process;

process (clk)
begin
	if rst_n = '0' then
		LCDC <= x"00";
	end if;
	if rising_edge(clk) then
		if mode /= "11" then
			if addr(15 downto 13) = "100" then
				PP_vram_rd <= re;
				PP_vram_w <= we;
				PP_vram_a <= addr(12 downto 0);
			else
				PP_vram_rd <= '0';
				PP_vram_w <= '0';
				PP_vram_a <= "0000000000000";
			end if;
		else
			PP_vram_rd <= '0';
			PP_vram_w <= '0';
			PP_vram_a <= "0000000000000";
		end if;
		lcd_en <= LCDC(7);
		if re='1' then
			case addr is
				when x"FF40" =>
					data_out <= LCDC;
				when x"FF41" =>
					if (LY = LYC) then
						data_out <= STAT & '1' & mode;
					else
						data_out <= STAT & '0' & mode;
					end if;
				when x"FF42" =>
					data_out <= STD_LOGIC_VECTOR(SCY);
				when x"FF43" =>
					data_out <= STD_LOGIC_VECTOR(SCX);
				when x"FF44" =>
					if LY = x"99" AND CX >= x"004" then --TODO - Figure out hardware reason
						data_out <= x"00";
					else
						data_out <= STD_LOGIC_VECTOR(LY);
					end if;
				when x"FF45" =>
					data_out <= STD_LOGIC_VECTOR(LYC);
				when x"FF4A" =>
					data_out <= WY;
				when x"FF4B" =>
					data_out <= WX;
				when x"FF46" =>
					data_out <= DMA;
				when x"FF47" =>
					data_out <= BGP;
				when x"FF48" =>
					data_out <= OBP0;
				when x"FF49" =>
					data_out <= OBP1;
				when others =>
					if (addr(15 downto 8) = x"FE") then
						if mode(1) = '0' AND (addr(7) = '0' OR addr(6 downto 5) = "00") then
							data_out <= OAM(to_integer(unsigned(addr(7 downto 0))));
						else
							data_out <= x"FF";
						end if;
					elsif addr(15 downto 13) = "100" then
						if mode /= "11" OR LCDC(7) = '0' then
							data_out <= PP_vram_in;
						else
							data_out <= x"FF";
						end if;
					else
						data_out <= x"00";
					end if;
			end case;
		end if;
		if we='1' then
    		case addr is
    			when x"FF40" =>
    				LCDC <= data_in;
    				echo("LCDC Set " & to_HexChar(data_in));
    			when x"FF41" =>
    				STAT <= data_in(7 downto 3);
    			when x"FF42" =>
    				SCY <= UNSIGNED(data_in);
    			when x"FF43" =>
    				SCX <= UNSIGNED(data_in);
    			when x"FF44" =>
    				NULL;
    			when x"FF45" =>
    				LYC <= UNSIGNED(data_in);
    			when x"FF46" =>
    				DMA <= data_in;
    				echo("DMA Requested");
    				dma_req <= '1';
    			when x"FF4A" =>
    				WY <= data_in;
    			when x"FF4B" =>
    				WX <= data_in;
    			when x"FF47" =>
    				BGP <= data_in;
    			when x"FF48" =>
    				OBP0 <= data_in(7 downto 2) & "00";
    			when x"FF49" =>
    				OBP1 <= data_in(7 downto 2) & "00";
    			when others =>
    			if (addr(15 downto 8) = x"FE") AND mode(1) = '0' AND (addr(7) = '0' OR addr(6 downto 5) = "00") then
					OAM(to_integer(unsigned(addr(7 downto 0)))) <= data_in;
				elsif addr(15 downto 13) = "100" AND mode /= "11" then
					vram_data_out <= data_in;
					echo("VRAM WRITE " & to_HexChar(data_in) & " @ " & to_DHexChar(addr));
				end if;
    		end case;
    	end if;
    	
    	if (LCDC(7) = '1') then
			if CX = x"1C7" then --One Scanline
				CX <= "000000000";
				LY <= LY + 1;
				--if LY=x"40" then
				if LY < x"90" then
					lcd_hsync <= '1';
				else
					lcd_hsync <= '0';
				end if;
				--end if;
			else
				CX <= CX + 1;
				lcd_hsync <= '0';
			end if;
			if LY = x"99" AND CX = 8 then --One Frame
				LY <= x"00";
				lcd_vsync <= '1';
			else
				lcd_vsync <= '0';
			end if;
			if LY >= x"90" then
				mode <= "01";
				if (STAT(4) = '1') then
					lcdc_out <= '1';
				else
					lcdc_out <= '0';
				end if;
				vblk <= '1';
			elsif CX < x"50" then
				mode <= "10";
				vblk <= '0';
				if (STAT(5) = '1') then
					lcdc_out <= '1';
				else
					lcdc_out <= '0';
				end if;
			elsif CX < x"120" then
				mode <= "11";
				vblk <= '0';
				lcdc_out <= '0';
			else
				mode <= "00";
				vblk <= '0';
				if (STAT(3) = '1') then
					lcdc_out <= '1';
				else
					lcdc_out <= '0';
				end if;
			end if;
			
			if (STAT(6) = '1') AND (LY = LYC) then
				lcdc_out <= '1';
			end if;
		else
			--CX := "011110100";
			CX <= "000000000";
			LY <= x"00";
			mode <= "00";
			lcdc_out <= '0';
			lcd_hsync <= '0';
			lcd_vsync <= '0';
			vblk <= '0';
    	end if;
	end if;
end process;

bg_fetcher : process (clk) is
	variable bg_wr_en : STD_LOGIC;
	variable bg_rd_en : STD_LOGIC;
	variable bg_wr_data : STD_LOGIC_VECTOR(1 downto 0);
	variable tile_idx : UNSIGNED(11 downto 0);
	variable tile_sel : STD_LOGIC;
	variable y : STD_LOGIC_VECTOR(7 downto 0);
	begin
	if rising_edge(clk) then
		if LCDC(7) = '1' AND mode = "11" then
			if rst_fifos = '1' then
				bg_FIFO_COUNT <= 0;
				bg_WR_INDEX   <= 0;
				bg_RD_INDEX   <= 0;
				bg_state <= fetch_map;
				BG_div <= '0';
				BG_vram_rd <= '0';
				BG_vram_a <= "0000000000000";
				FX <= "00000";
			else
				BG_div <= NOT BG_div;
				case bg_state is
					when fetch_map =>
						BG_vram_rd <= '1';
						y := STD_LOGIC_VECTOR(LY + SCY);
						BG_vram_a <= "11" & LCDC(3) & y(7 downto 3) & STD_LOGIC_VECTOR(FX + SCX(7 downto 3));
						if BG_div = '1' then
							bg_state <= fetch_low;
						end if;
					when fetch_low =>
						BG_vram_rd <= '1';
						if BG_div = '0' then
							FX <= FX + 1;
							y := STD_LOGIC_VECTOR(LY + SCY);
							tile_idx := shift_left(RESIZE(UNSIGNED(BG_vram_in), 12), 4) + UNSIGNED(y(2 downto 0) & '0');
							tile_sel := LCDC(4) NOR BG_vram_in(7);
							BG_vram_a <= tile_sel & STD_LOGIC_VECTOR(tile_idx);
							bg_TILE <= tile_sel & STD_LOGIC_VECTOR(tile_idx);
						else
							BG_vram_a <= bg_TILE;
							bg_TILE <= bg_TILE + 1;
							bg_state <= fetch_high;
						end if;
					when fetch_high =>
						BG_vram_rd <= '1';
						BG_vram_a <= bg_TILE;
						if BG_div = '0' then
							bg_low <= BG_vram_in;
						else
							bg_state <= push;
						end if;
					when push =>
						BG_vram_rd <= '0';
						BG_vram_a <= "0000000000000";
						if BG_div = '0' then
							bg_high <= BG_vram_in;
						else
							if bg_FIFO_COUNT = 0 then
								bg_FIFO_COUNT <= 8;
								if bg_WR_INDEX = 0 then
									bg_WR_INDEX <= 8;
								else
									bg_WR_INDEX <= 0;
								end if;
								for i in 0 to 7 loop
									bg_wr_data := bg_high(i) & bg_low(i);
									if LCDC(0) = '1' then
										case bg_wr_data is
											when "00" =>
												bg_wr_data := BGP(1 downto 0);
											when "01" =>
												bg_wr_data := BGP(3 downto 2);
											when "10" =>
												bg_wr_data := BGP(5 downto 4);
											when others =>
												bg_wr_data := BGP(7 downto 6);
										end case;
									else
										bg_wr_data := "00";
									end if;
									if bg_WR_INDEX = 0 then
										bg_FIFO_DATA(7 - i) <= bg_wr_data;
									else
										bg_FIFO_DATA(15 - i) <= bg_wr_data;
									end if;
								end loop;
								bg_state <= fetch_map;
							end if;
						end if;
					when others=>
						BG_vram_rd <= '0';
						BG_vram_a <= "0000000000000";
				end case;
				
				if bg_FIFO_COUNT > 0 AND CP /= 160 then
					BG_valid <= '1';
					bg_FIFO_COUNT <= bg_FIFO_COUNT - 1;
					if bg_RD_INDEX = 15 then
						bg_RD_INDEX <= 0;
					else
						bg_RD_INDEX <= bg_RD_INDEX + 1;
					end if;
					lcd_pixel <= bg_FIFO_DATA(bg_RD_INDEX);
					CP <= CP + 1;
				else
					BG_valid <= '0';
					lcd_pixel <= "00";
				end if;
			end if;
		else
			BG_vram_rd <= '0';
			BG_vram_a <= "0000000000000";
			bg_state <= fetch_map;
			BG_div <= '0';
			FX <= "00000";
			bg_TILE <= "0000000000000";
			BG_valid <= '0';
			CP <= x"00";
			bg_FIFO_COUNT <= 0;
			bg_WR_INDEX   <= 0;
			bg_RD_INDEX   <= 0;
		end if;
	end if;
end process bg_fetcher;

end Behavioral;
