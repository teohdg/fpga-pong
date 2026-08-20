----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/26/2026 12:35:55 PM
-- Design Name: 
-- Module Name: led_array - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity led_array is
    port (
        led_in  : in  std_logic_vector(2 downto 0);
        led_out : out std_logic_vector(7 downto 0)
    );
end led_array;

architecture Behavioral of led_array is
begin
    with led_in select
        led_out <= "00000001" when "000",
                   "00000010" when "001",
                   "00000100" when "010",
                   "00001000" when "011",
                   "00010000" when "100",
                   "00100000" when "101",
                   "01000000" when "110",
                   "10000000" when "111",
                   "00000000" when others;
end Behavioral;
