--------------------------------------------------------------------------------
-- cortexm0ds_stub.vhd
--
-- SIMULATION-ONLY stub of the Arm Cortex-M0 DesignStart core (CORTEXM0DS).
--
-- This is NOT the Arm core and does NOT execute any instructions. It exists
-- purely so that the SoC elaborates and the AHB fabric / peripherals can be
-- syntax-checked and (optionally) exercised without the licensed IP present.
-- It drives a few dummy AHB transactions so waveforms are non-trivial.
--
-- For real simulation or synthesis, replace this with the actual CORTEXM0DS
-- deliverable from Arm (see third_party/arm_cortex_m0_designstart/README.md).
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CORTEXM0DS is
    port (
        HCLK        : in  std_logic;
        HRESETn     : in  std_logic;
        HADDR       : out std_logic_vector(31 downto 0);
        HBURST      : out std_logic_vector(2 downto 0);
        HMASTLOCK   : out std_logic;
        HPROT       : out std_logic_vector(3 downto 0);
        HSIZE       : out std_logic_vector(2 downto 0);
        HTRANS      : out std_logic_vector(1 downto 0);
        HWDATA      : out std_logic_vector(31 downto 0);
        HWRITE      : out std_logic;
        HRDATA      : in  std_logic_vector(31 downto 0);
        HREADY      : in  std_logic;
        HRESP       : in  std_logic;
        NMI         : in  std_logic;
        IRQ         : in  std_logic_vector(15 downto 0);
        TXEV        : out std_logic;
        RXEV        : in  std_logic;
        LOCKUP      : out std_logic;
        SYSRESETREQ : out std_logic;
        SLEEPING    : out std_logic;
        SWCLKTCK    : in  std_logic;
        SWDIO       : inout std_logic
    );
end entity CORTEXM0DS;

architecture stub of CORTEXM0DS is
    type state_t is (IDLE, WR_ADDR, WR_DATA, RD_ADDR, RD_DATA);
    signal st : state_t := IDLE;
    -- Small script of accesses to the peripheral space:
    --   write LED = 0xAA (GPIO 0x4000_1000)
    --   write UART DATA = 'K' (0x4000_0000)
    --   read  SWITCH     (GPIO 0x4000_1004)
    signal step : integer range 0 to 4 := 0;
begin

    HBURST    <= "000";
    HMASTLOCK <= '0';
    HPROT     <= "0011";
    HSIZE     <= "010";        -- word
    TXEV      <= '0';
    LOCKUP    <= '0';
    SYSRESETREQ <= '0';
    SLEEPING  <= '0';

    process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                st     <= IDLE;
                step   <= 0;
                HADDR  <= (others => '0');
                HTRANS <= "00";
                HWRITE <= '0';
                HWDATA <= (others => '0');
            elsif HREADY = '1' then
                case st is
                    when IDLE =>
                        st <= WR_ADDR;

                    when WR_ADDR =>
                        HTRANS <= "10";           -- NONSEQ
                        HWRITE <= '1';
                        HADDR  <= x"40001000";     -- GPIO LED
                        st     <= WR_DATA;

                    when WR_DATA =>
                        HTRANS <= "00";
                        HWRITE <= '0';
                        HWDATA <= x"000000AA";
                        st     <= RD_ADDR;

                    when RD_ADDR =>
                        HTRANS <= "10";
                        HWRITE <= '0';
                        HADDR  <= x"40001004";     -- GPIO SWITCH
                        st     <= RD_DATA;

                    when RD_DATA =>
                        HTRANS <= "00";
                        st     <= IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture stub;
