--------------------------------------------------------------------------------
-- ahb_decoder.vhd
--
-- Minimal AHB-Lite interconnect for a single master (Cortex-M0 DesignStart) and
-- four slaves: boot memory, UART, GPIO, PWM. It decodes HADDR to generate the
-- per-slave HSEL, multiplexes read data / HREADY / HRESP back to the master,
-- and holds the selected-slave index across the address-to-data phase.
--
-- Address decode (see docs/memory-map.md):
--   slave 0 : 0x0000_0000 .. 0x0000_FFFF   boot memory (64 KB)
--   slave 1 : 0x4000_0000 .. 0x4000_0FFF   UART
--   slave 2 : 0x4000_1000 .. 0x4000_1FFF   GPIO
--   slave 3 : 0x4000_2000 .. 0x4000_2FFF   PWM
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ahb_decoder is
    port (
        HCLK       : in  std_logic;
        HRESETn    : in  std_logic;
        -- From master
        HADDR      : in  std_logic_vector(31 downto 0);
        HTRANS     : in  std_logic_vector(1 downto 0);
        -- Per-slave select
        HSEL_mem   : out std_logic;
        HSEL_uart  : out std_logic;
        HSEL_gpio  : out std_logic;
        HSEL_pwm   : out std_logic;
        -- Read-data / handshake from each slave
        HRDATA_mem  : in std_logic_vector(31 downto 0);
        HRDATA_uart : in std_logic_vector(31 downto 0);
        HRDATA_gpio : in std_logic_vector(31 downto 0);
        HRDATA_pwm  : in std_logic_vector(31 downto 0);
        HREADY_mem  : in std_logic;
        HREADY_uart : in std_logic;
        HREADY_gpio : in std_logic;
        HREADY_pwm  : in std_logic;
        HRESP_mem   : in std_logic;
        HRESP_uart  : in std_logic;
        HRESP_gpio  : in std_logic;
        HRESP_pwm   : in std_logic;
        -- To master
        HRDATA     : out std_logic_vector(31 downto 0);
        HREADY     : out std_logic;
        HRESP      : out std_logic
    );
end entity ahb_decoder;

architecture rtl of ahb_decoder is
    -- Slave select codes.
    constant SEL_MEM  : std_logic_vector(1 downto 0) := "00";
    constant SEL_UART : std_logic_vector(1 downto 0) := "01";
    constant SEL_GPIO : std_logic_vector(1 downto 0) := "10";
    constant SEL_PWM  : std_logic_vector(1 downto 0) := "11";

    signal sel_addr : std_logic_vector(1 downto 0);
    signal sel_data : std_logic_vector(1 downto 0) := SEL_MEM;
    signal active   : std_logic;
begin

    active <= HTRANS(1);

    --------------------------------------------------------------------------
    -- Combinational address decode (address phase).
    --------------------------------------------------------------------------
    decode : process (HADDR)
    begin
        if HADDR(31 downto 28) = x"4" then
            case HADDR(15 downto 12) is
                when x"0"   => sel_addr <= SEL_UART;
                when x"1"   => sel_addr <= SEL_GPIO;
                when x"2"   => sel_addr <= SEL_PWM;
                when others => sel_addr <= SEL_UART; -- default within periph win
            end case;
        else
            sel_addr <= SEL_MEM;                     -- 0x0xxx_xxxx -> memory
        end if;
    end process;

    HSEL_mem  <= '1' when (sel_addr = SEL_MEM  and active = '1') else '0';
    HSEL_uart <= '1' when (sel_addr = SEL_UART and active = '1') else '0';
    HSEL_gpio <= '1' when (sel_addr = SEL_GPIO and active = '1') else '0';
    HSEL_pwm  <= '1' when (sel_addr = SEL_PWM  and active = '1') else '0';

    --------------------------------------------------------------------------
    -- Hold selected slave for the data phase.
    --------------------------------------------------------------------------
    hold : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                sel_data <= SEL_MEM;
            elsif active = '1' then
                sel_data <= sel_addr;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- Response mux (data phase).
    --------------------------------------------------------------------------
    with sel_data select HRDATA <=
        HRDATA_uart when SEL_UART,
        HRDATA_gpio when SEL_GPIO,
        HRDATA_pwm  when SEL_PWM,
        HRDATA_mem  when others;

    with sel_data select HREADY <=
        HREADY_uart when SEL_UART,
        HREADY_gpio when SEL_GPIO,
        HREADY_pwm  when SEL_PWM,
        HREADY_mem  when others;

    with sel_data select HRESP <=
        HRESP_uart when SEL_UART,
        HRESP_gpio when SEL_GPIO,
        HRESP_pwm  when SEL_PWM,
        HRESP_mem  when others;

end architecture rtl;
