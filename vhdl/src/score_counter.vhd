----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2026 04:10:42 PM
-- Design Name: 
-- Module Name: counter - Behavioral
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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter is
    Port ( clk     : in  STD_LOGIC;
           reset   : in  STD_LOGIC;
           state   : in  STD_LOGIC_VECTOR(3 downto 0);
           output1 : out STD_LOGIC_VECTOR(3 downto 0);
           output2 : out STD_LOGIC_VECTOR(3 downto 0);
           winner  : out STD_LOGIC_VECTOR(1 downto 0)
         );
end counter;

architecture Behavioral of counter is
    signal player1    : std_logic_vector(3 downto 0) := "0000";
    signal player2    : std_logic_vector(3 downto 0) := "0000";
    signal prev_state : std_logic_vector(3 downto 0) := "0000";
    signal win_reg    : std_logic_vector(1 downto 0) := "00";
begin
    process(clk, reset)
    begin
        if (reset = '1') then
            player1    <= "0000";
            player2    <= "0000";
            prev_state <= "0000";
            win_reg    <= "00";
        elsif (rising_edge(clk)) then
            prev_state <= state;
            if (win_reg = "00") then
                if (prev_state = "0010" and state = "0000") then
                    if (player1 = "1001") then
                        win_reg <= "01";
                        player1 <= "0000";
                    else
                        player1 <= player1 + 1;
                    end if;
                elsif (prev_state = "0100" and state = "0000") then
                    if (player2 = "1001") then
                        win_reg <= "10";
                        player2 <= "0000";
                    else
                        player2 <= player2 + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    output1 <= player1;
    output2 <= player2;
    winner  <= win_reg;
end Behavioral;
