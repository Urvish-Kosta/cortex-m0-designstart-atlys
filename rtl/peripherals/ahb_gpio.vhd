--------------------------------------------------------------------------------
-- ahb_gpio.vhd
--
-- AHB-Lite GPIO peripheral for the Cortex-M0 DesignStart SoC.
--
-- Drives the 8 user LEDs and reads the 8 slide switches and 5 push buttons on
-- the Digilent Atlys board. Buttons are debounced with a simple counter so the
-- firmware sees clean level changes.
--
-- Register map (offsets from the peripheral base):
--   0x00 LED    : R/W  [7:0] LED outputs
--   0x04 SWITCH : R    [7:0] slide switches
--   0x08 BUTTON : R    [4:0] debounced buttons
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ahb_gpio is
    generic (
        DEBOUNCE_CYCLES : integer := 500_000   -- ~10 ms at 50 MHz
    );
    port (
        HCLK      : in  std_logic;
        HRESETn   : in  std_logic;
        -- AHB-Lite slave interface
        HSEL      : in  std_logic;
        HADDR     : in  std_logic_vector(31 downto 0);
        HWRITE    : in  std_logic;
        HTRANS    : in  std_logic_vector(1 downto 0);
        HWDATA    : in  std_logic_vector(31 downto 0);
        HREADYin  : in  std_logic;
        HRDATA    : out std_logic_vector(31 downto 0);
        HREADYout : out std_logic;
        HRESP     : out std_logic;
        -- Board I/O
        led       : out std_logic_vector(7 downto 0);
        sw        : in  std_logic_vector(7 downto 0);
        btn       : in  std_logic_vector(4 downto 0)
    );
end entity ahb_gpio;

architecture rtl of ahb_gpio is

    signal addr_q  : std_logic_vector(3 downto 0);
    signal write_q : std_logic;
    signal valid_q : std_logic;

    signal led_reg : std_logic_vector(7 downto 0) := (others => '0');

    -- Input synchronisers
    signal sw_sync   : std_logic_vector(7 downto 0) := (others => '0');
    signal btn_sync0 : std_logic_vector(4 downto 0) := (others => '0');
    signal btn_sync1 : std_logic_vector(4 downto 0) := (others => '0');

    -- Debounce
    signal btn_stable : std_logic_vector(4 downto 0) := (others => '0');
    signal db_cnt     : integer range 0 to DEBOUNCE_CYCLES := 0;

begin

    led <= led_reg;

    --------------------------------------------------------------------------
    -- AHB address phase capture.
    --------------------------------------------------------------------------
    ahb_addr_phase : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                valid_q <= '0';
                write_q <= '0';
                addr_q  <= (others => '0');
            elsif HREADYin = '1' then
                if HSEL = '1' and HTRANS(1) = '1' then
                    valid_q <= '1';
                    write_q <= HWRITE;
                    addr_q  <= HADDR(3 downto 0);
                else
                    valid_q <= '0';
                    write_q <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- Register writes.
    --------------------------------------------------------------------------
    ahb_write : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                led_reg <= (others => '0');
            elsif valid_q = '1' and write_q = '1' and addr_q = x"0" then
                led_reg <= HWDATA(7 downto 0);
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- Read data mux.
    --------------------------------------------------------------------------
    ahb_read : process (addr_q, led_reg, sw_sync, btn_stable)
    begin
        HRDATA <= (others => '0');
        case addr_q is
            when x"0" => HRDATA(7 downto 0) <= led_reg;
            when x"4" => HRDATA(7 downto 0) <= sw_sync;
            when x"8" => HRDATA(4 downto 0) <= btn_stable;
            when others => HRDATA <= (others => '0');
        end case;
    end process;

    HREADYout <= '1';
    HRESP     <= '0';

    --------------------------------------------------------------------------
    -- Input synchronise + debounce.
    --------------------------------------------------------------------------
    inputs : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                sw_sync    <= (others => '0');
                btn_sync0  <= (others => '0');
                btn_sync1  <= (others => '0');
                btn_stable <= (others => '0');
                db_cnt     <= 0;
            else
                sw_sync   <= sw;              -- switches: sync only, no debounce
                btn_sync0 <= btn;
                btn_sync1 <= btn_sync0;

                if btn_sync1 /= btn_stable then
                    if db_cnt = DEBOUNCE_CYCLES then
                        btn_stable <= btn_sync1;
                        db_cnt     <= 0;
                    else
                        db_cnt <= db_cnt + 1;
                    end if;
                else
                    db_cnt <= 0;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
