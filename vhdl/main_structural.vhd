----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/26/2026 12:35:19 PM
-- Design Name: 
-- Module Name: main_structural - Structural
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

entity main_structural is
    port (
        clk_in  : in  std_logic;
        reset   : in  std_logic;
        player1 : in  std_logic;
        player2 : in  std_logic;
        sw      : in  std_logic;
        led     : out std_logic_vector(7 downto 0);
        seg     : out std_logic_vector(6 downto 0);
        cat     : out std_logic
    );
end main_structural;

architecture Structural of main_structural is
    signal game_clk    : std_logic;
    signal clk_60      : std_logic;
    signal ball_pos    : std_logic_vector(2 downto 0);
    signal curr_state  : std_logic_vector(3 downto 0);

    signal p1_buf      : std_logic;
    signal p2_buf      : std_logic;
    signal reset_buf   : std_logic;

    signal p1_score    : std_logic_vector(3 downto 0);
    signal p2_score    : std_logic_vector(3 downto 0);
    signal winner      : std_logic_vector(1 downto 0);

    signal digit_left  : std_logic_vector(3 downto 0);
    signal digit_right : std_logic_vector(3 downto 0);
    signal flash_tick  : std_logic;
    signal mux_out     : std_logic_vector(3 downto 0);
begin
    IBUF : entity work.input_buffer
        port map (
            clk          => clk_in,
            reset_in     => reset,
            p1           => player1,
            p2           => player2,
            game_clk_in  => game_clk,
            p1Buf        => p1_buf,
            p2Buf        => p2_buf,
            resetBuf_out => reset_buf
        );

    CLK_DIV : entity work.lab6_clock_divider
        port map (
            clk_in => clk_in,
            reset  => reset_buf,
            sel    => sw,
            clkout => game_clk
        );

    CLK60 : entity work.lab7_clk60hz
        port map (
            clk    => clk_in,
            reset  => reset_buf,
            clkout => clk_60
        );

    FSM : entity work.game_state_machine
        port map (
            clk     => game_clk,
            reset   => reset_buf,
            player1 => p1_buf,
            player2 => p2_buf,
            state   => curr_state,
            leds    => ball_pos
        );

    LEDS : entity work.led_array
        port map (
            led_in  => ball_pos,
            led_out => led
        );

    CNT : entity work.counter
        port map (
            clk     => game_clk,
            reset   => reset_buf,
            state   => curr_state,
            output1 => p1_score,
            output2 => p2_score,
            winner  => winner
        );

    flash_tick <= game_clk;
    digit_left  <= "1111" when (winner = "01" and flash_tick = '0') else p1_score;
    digit_right <= "1111" when (winner = "10" and flash_tick = '0') else p2_score;

    MUX : entity work.lab7_mux
        port map (
            sel => clk_60,
            I0  => p1_score,
            I1  => p2_score,
            Y   => mux_out
        );

    SSD : entity work.ssd_decoder
        port map (
            clk    => clk_in,
            digit1 => digit_left,
            digit2 => digit_right,
            seg    => seg,
            cat    => cat
        );
end Structural;