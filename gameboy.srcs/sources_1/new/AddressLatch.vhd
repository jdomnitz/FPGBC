----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/07/2020 01:11:20 PM
-- Design Name: 
-- Module Name: AddressLatch - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library gameboy;
use gameboy.Common.ALL;

entity AddressLatch is
    Port ( clk: in STD_LOGIC;
           addr_in : in STD_LOGIC_VECTOR (15 downto 0);
           addr_out : out STD_LOGIC_VECTOR (15 downto 0);
           op : in STD_LOGIC_VECTOR (1 downto 0));
end AddressLatch;

architecture Behavioral of AddressLatch is
SIGNAL mem : STD_LOGIC_VECTOR (15 downto 0);

begin

process(clk)
begin
    if rising_edge(clk) then
        case op is
            when OP_LATCH =>
                mem <= addr_in;
                addr_out <= addr_in;
            when OP_INC =>
                addr_out <=  mem + 1;
            when OP_DEC =>
                addr_out <=  mem - 1;
            when others =>
                addr_out <= mem;
        end case;
    end if;
end process;

end Behavioral;
