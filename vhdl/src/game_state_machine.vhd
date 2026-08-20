----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/26/2026 12:35:38 PM
-- Design Name: 
-- Module Name: game_state_machine - Behavioral
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

entity game_state_machine is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        player1 : in  std_logic;
        player2 : in  std_logic;
        state   : out std_logic_vector(3 downto 0);
        leds    : out std_logic_vector(2 downto 0)
    );
end game_state_machine;

architecture Behavioral of game_state_machine is
    signal curr_state : std_logic_vector(2 downto 0) := "000";
    signal next_state : std_logic_vector(2 downto 0);
    signal curr_leds  : std_logic_vector(2 downto 0) := "000";
    signal next_leds  : std_logic_vector(2 downto 0);
begin
    clk_proc : process(clk, reset)
    begin
        if reset = '1' then
            curr_state <= "000";
            curr_leds  <= "000";
        elsif rising_edge(clk) then
            curr_state <= next_state;
            curr_leds  <= next_leds;
        end if;
    end process;

    next_state_proc : process(curr_state, curr_leds, player1, player2)
    begin
        next_state <= curr_state;
        next_leds  <= curr_leds;
        case curr_state is
            when "000" =>
                next_leds  <= "000";
                next_state <= "001";
            when "001" =>
                if curr_leds = "110" then
                    next_state <= "010";
                    next_leds  <= "111";
                else
                    next_state <= "001";
                    next_leds  <= curr_leds + 1;
                end if;
            when "010" =>
                if player2 = '1' then
                    next_state <= "011";
                    next_leds  <= "110";
                else
                    next_state <= "000";
                    next_leds  <= "000";
                end if;
            when "011" =>
                if curr_leds = "001" then
                    next_state <= "100";
                    next_leds  <= "000";
                else
                    next_state <= "011";
                    next_leds  <= curr_leds - 1;
                end if;
            when "100" =>
                if player1 = '1' then
                    next_state <= "001";
                    next_leds  <= "001";
                else
                    next_state <= "000";
                    next_leds  <= "000";
                end if;
            when others =>
                next_state <= "000";
                next_leds  <= "000";
        end case;
    end process;

    state <= '0' & curr_state;
    leds  <= curr_leds;
end Behavioral;
