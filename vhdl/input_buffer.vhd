----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2026 04:11:46 PM
-- Design Name: 
-- Module Name: input_buffer - Behavioral
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

entity input_buffer is
    Port ( clk          : in  STD_LOGIC;
           reset_in     : in  STD_LOGIC;
           p1           : in  STD_LOGIC;
           p2           : in  STD_LOGIC;
           game_clk_in  : in  STD_LOGIC;
           p1Buf        : out STD_LOGIC;
           p2Buf        : out STD_LOGIC;
           resetBuf_out : out STD_LOGIC
         );
end input_buffer;

architecture Behavioral of input_buffer is
    signal game_clk_d : std_logic := '0';
    signal p1Buf_reg  : std_logic := '0';
    signal p2Buf_reg  : std_logic := '0';
begin
    clocking : process(clk)
    begin
        if (rising_edge(clk)) then
            game_clk_d <= game_clk_in;
            if ((game_clk_d /= game_clk_in) and game_clk_in = '1') then
                p1Buf_reg <= '0';
                p2Buf_reg <= '0';
            elsif (p1 = '1') then
                p1Buf_reg <= '1';
            elsif (p2 = '1') then
                p2Buf_reg <= '1';
            end if;
        end if;
    end process;

    p1Buf        <= p1Buf_reg;
    p2Buf        <= p2Buf_reg;
    resetBuf_out <= reset_in;
end Behavioral;

