----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/26/2026 12:51:25 PM
-- Design Name: 
-- Module Name: ssd_decoder - Behavioral
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
use IEEE.NUMERIC_STD.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ssd_decoder is
    port (
        clk    : in  std_logic;
        digit1 : in  std_logic_vector(3 downto 0);
        digit2 : in  std_logic_vector(3 downto 0);
        seg    : out std_logic_vector(6 downto 0);
        cat    : out std_logic
    );
end ssd_decoder;

architecture Behavioral of ssd_decoder is
    signal counter : unsigned(16 downto 0) := (others => '0');
    signal toggle  : std_logic := '0';
    signal curr    : std_logic_vector(3 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            counter <= counter + 1;
            toggle <= counter(16);
        end if;
    end process;

    curr <= digit1 when toggle = '0' else digit2;
    cat  <= toggle;

with curr select
        seg <= "0111111" when "0000",
               "0110000" when "0001",
               "1011011" when "0010",
               "1111001" when "0011",
               "1110100" when "0100",
               "1101101" when "0101",
               "1101111" when "0110",
               "0111000" when "0111",
               "1111111" when "1000",
               "1111101" when "1001",
               "0000000" when others;

end Behavioral;
