----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/20/2026 04:29:30 PM
-- Design Name: 
-- Module Name: lab7_clk60hz - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lab7_clk60hz is
    Port (
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        clkout : out STD_LOGIC
    );
end lab7_clk60hz;

architecture Behavioral of lab7_clk60hz is

    signal counter : natural := 0;
    signal clk_reg : STD_LOGIC := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            clk_reg <= '0';
        elsif rising_edge(clk) then
            if counter >= 99999 then
                counter <= 0;
                clk_reg <= not clk_reg;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    clkout <= clk_reg;

end Behavioral;
