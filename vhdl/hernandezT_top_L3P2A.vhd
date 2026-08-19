----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/11/2026 11:37:28 AM
-- Design Name: 
-- Module Name: hernandezT_top_L3P2A - Behavioral
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

entity hernandezT_top_L3P2A is
    Port ( A : in STD_LOGIC;
           B : in STD_LOGIC;
           C : in STD_LOGIC;
           S : out STD_LOGIC;
           O : out STD_LOGIC);
end hernandezT_top_L3P2A;

architecture Behavioral of hernandezT_top_L3P2A is

signal and1_sig : std_logic;  
signal and2_sig : std_logic;
signal xor1_sig : std_logic; 

component and_gate is
    Port ( A_and : in STD_LOGIC;
           B_and : in STD_LOGIC;
           Output_and : out STD_LOGIC);
end component;

component or_gate is
    Port ( A_or : in STD_LOGIC;
           B_or : in STD_LOGIC;
           Output_or : out STD_LOGIC);
end component;

component xor_gate is
    Port ( A_xor : in STD_LOGIC;
           B_xor : in STD_LOGIC;
           Output_xor : out STD_LOGIC);
end component;

begin

xor_gate1: xor_gate port map(A_xor => A, B_xor => B, Output_xor => xor1_sig);
xor_gate2: xor_gate port map(A_xor => xor1_sig, B_xor => C, Output_xor => S);
and_gate1: and_gate port map(A_and => A, B_and => B, Output_and => and1_sig);
and_gate2: and_gate port map(A_and => xor1_sig, B_and => C, Output_and => and2_sig);
or_gate1: or_gate port map(A_or => and1_sig, B_or => and2_sig, Output_or => O);

end Behavioral;