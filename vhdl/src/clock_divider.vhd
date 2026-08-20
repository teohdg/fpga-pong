----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/20/2026 04:31:01 PM
-- Design Name: 
-- Module Name: lab6_clock_divider - Behavioral
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
entity lab6_clock_divider is
    Port (
        clk_in : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        sel    : in  STD_LOGIC;
        clkout : out STD_LOGIC
    );
end lab6_clock_divider;

architecture Behavioral of lab6_clock_divider is
    signal counter : natural := 0;
    signal clk_reg : STD_LOGIC := '0';
begin
    process(clk_in, reset)
    begin
        if reset = '1' then
            counter <= 0;
            clk_reg <= '0';
        elsif rising_edge(clk_in) then
            if sel = '0' then
                if counter >= 49999999 then
                    counter <= 0;
                    clk_reg <= not clk_reg;
                else
                    counter <= counter + 1;
                end if;
            else
                if counter >= 24999999 then
                    counter <= 0;
                    clk_reg <= not clk_reg;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;
    clkout <= clk_reg;
end Behavioral;
