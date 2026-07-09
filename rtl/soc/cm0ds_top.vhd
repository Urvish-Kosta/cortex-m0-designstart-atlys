--------------------------------------------------------------------------------
-- cm0ds_top.vhd
--
-- Top-level SoC for the Cortex-M0 DesignStart port on the Digilent Atlys
-- (Spartan-6 XC6SLX45) board. Instantiates:
--   * the Arm Cortex-M0 DesignStart core   (CORTEXM0DS, provided by Arm)
--   * clock/reset generation               (clk_reset_gen)
--   * AHB-Lite interconnect / decoder       (ahb_decoder)
--   * boot memory                           (ahb_mem)
--   * UART / GPIO / PWM peripherals          (ahb_*)
--
-- The Cortex-M0 DesignStart core exposes a single AHB-Lite MASTER. Its port
-- list is fixed by Arm (see the DesignStart TRM / release note). If the package
-- you download uses different names, update the component declaration below.
--
-- Author: Urvish Kosta
-- License: MIT for this file (see LICENSE). The CORTEXM0DS core is NOT included
--          and is covered by its own Arm licence.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cm0ds_top is
    generic (
        CLK_HZ    : integer := 50_000_000;  -- system clock after divide
        BAUD_RATE : integer := 9600
    );
    port (
        -- Board
        clk_100m : in  std_logic;               -- 100 MHz oscillator
        rst_btn  : in  std_logic;               -- reset push button (active high)
        -- UART (to USB-UART bridge on Atlys)
        uart_rx  : in  std_logic;
        uart_tx  : out std_logic;
        -- User I/O
        led      : out std_logic_vector(7 downto 0);
        sw       : in  std_logic_vector(7 downto 0);
        btn      : in  std_logic_vector(4 downto 0);
        pwm_led  : out std_logic
    );
end entity cm0ds_top;

architecture rtl of cm0ds_top is

    ----------------------------------------------------------------------------
    -- Arm Cortex-M0 DesignStart core component (provided by Arm, not in repo).
    -- Port names follow the standard CORTEXM0DS deliverable.
    ----------------------------------------------------------------------------
    component CORTEXM0DS is
        port (
            -- clock and reset
            HCLK      : in  std_logic;
            HRESETn   : in  std_logic;
            -- AHB-Lite master
            HADDR     : out std_logic_vector(31 downto 0);
            HBURST    : out std_logic_vector(2 downto 0);
            HMASTLOCK : out std_logic;
            HPROT     : out std_logic_vector(3 downto 0);
            HSIZE     : out std_logic_vector(2 downto 0);
            HTRANS    : out std_logic_vector(1 downto 0);
            HWDATA    : out std_logic_vector(31 downto 0);
            HWRITE    : out std_logic;
            HRDATA    : in  std_logic_vector(31 downto 0);
            HREADY    : in  std_logic;
            HRESP     : in  std_logic;
            -- misc
            NMI       : in  std_logic;
            IRQ       : in  std_logic_vector(15 downto 0);
            TXEV      : out std_logic;
            RXEV      : in  std_logic;
            LOCKUP    : out std_logic;
            SYSRESETREQ : out std_logic;
            SLEEPING  : out std_logic;
            -- debug (SWD)
            SWCLKTCK  : in  std_logic;
            SWDIO     : inout std_logic
        );
    end component;

    -- Clock / reset
    signal hclk     : std_logic;
    signal hresetn  : std_logic;

    -- Master AHB bus
    signal m_haddr  : std_logic_vector(31 downto 0);
    signal m_htrans : std_logic_vector(1 downto 0);
    signal m_hwrite : std_logic;
    signal m_hsize  : std_logic_vector(2 downto 0);
    signal m_hwdata : std_logic_vector(31 downto 0);
    signal m_hrdata : std_logic_vector(31 downto 0);
    signal m_hready : std_logic;
    signal m_hresp  : std_logic;

    -- Per-slave selects
    signal sel_mem, sel_uart, sel_gpio, sel_pwm : std_logic;

    -- Per-slave response
    signal rd_mem,  rd_uart,  rd_gpio,  rd_pwm  : std_logic_vector(31 downto 0);
    signal rdy_mem, rdy_uart, rdy_gpio, rdy_pwm : std_logic;
    signal rsp_mem, rsp_uart, rsp_gpio, rsp_pwm : std_logic;

    -- Tied-off core inputs
    signal irq_zero : std_logic_vector(15 downto 0) := (others => '0');

begin

    ----------------------------------------------------------------------------
    -- Clock and reset
    ----------------------------------------------------------------------------
    u_clkrst : entity work.clk_reset_gen
        generic map (CLK_DIV => 2, RESET_CYCLES => 16)
        port map (
            clk_in  => clk_100m,
            rst_in  => rst_btn,
            clk_sys => hclk,
            hresetn => hresetn
        );

    ----------------------------------------------------------------------------
    -- Cortex-M0 DesignStart core
    ----------------------------------------------------------------------------
    u_cpu : CORTEXM0DS
        port map (
            HCLK      => hclk,
            HRESETn   => hresetn,
            HADDR     => m_haddr,
            HBURST    => open,
            HMASTLOCK => open,
            HPROT     => open,
            HSIZE     => m_hsize,
            HTRANS    => m_htrans,
            HWDATA    => m_hwdata,
            HWRITE    => m_hwrite,
            HRDATA    => m_hrdata,
            HREADY    => m_hready,
            HRESP     => m_hresp,
            NMI       => '0',
            IRQ       => irq_zero,
            TXEV      => open,
            RXEV      => '0',
            LOCKUP    => open,
            SYSRESETREQ => open,
            SLEEPING  => open,
            SWCLKTCK  => '0',
            SWDIO     => open
        );

    ----------------------------------------------------------------------------
    -- Interconnect
    ----------------------------------------------------------------------------
    u_dec : entity work.ahb_decoder
        port map (
            HCLK        => hclk,
            HRESETn     => hresetn,
            HADDR       => m_haddr,
            HTRANS      => m_htrans,
            HSEL_mem    => sel_mem,
            HSEL_uart   => sel_uart,
            HSEL_gpio   => sel_gpio,
            HSEL_pwm    => sel_pwm,
            HRDATA_mem  => rd_mem,
            HRDATA_uart => rd_uart,
            HRDATA_gpio => rd_gpio,
            HRDATA_pwm  => rd_pwm,
            HREADY_mem  => rdy_mem,
            HREADY_uart => rdy_uart,
            HREADY_gpio => rdy_gpio,
            HREADY_pwm  => rdy_pwm,
            HRESP_mem   => rsp_mem,
            HRESP_uart  => rsp_uart,
            HRESP_gpio  => rsp_gpio,
            HRESP_pwm   => rsp_pwm,
            HRDATA      => m_hrdata,
            HREADY      => m_hready,
            HRESP       => m_hresp
        );

    ----------------------------------------------------------------------------
    -- Boot memory
    ----------------------------------------------------------------------------
    u_mem : entity work.ahb_mem
        generic map (MEM_SIZE_BYTES => 65536, INIT_FILE => "firmware.hex")
        port map (
            HCLK      => hclk,
            HRESETn   => hresetn,
            HSEL      => sel_mem,
            HADDR     => m_haddr,
            HWRITE    => m_hwrite,
            HTRANS    => m_htrans,
            HSIZE     => m_hsize,
            HWDATA    => m_hwdata,
            HREADYin  => m_hready,
            HRDATA    => rd_mem,
            HREADYout => rdy_mem,
            HRESP     => rsp_mem
        );

    ----------------------------------------------------------------------------
    -- UART
    ----------------------------------------------------------------------------
    u_uart : entity work.ahb_uart
        generic map (CLK_HZ => CLK_HZ, BAUD_RATE => BAUD_RATE)
        port map (
            HCLK      => hclk,
            HRESETn   => hresetn,
            HSEL      => sel_uart,
            HADDR     => m_haddr,
            HWRITE    => m_hwrite,
            HTRANS    => m_htrans,
            HWDATA    => m_hwdata,
            HREADYin  => m_hready,
            HRDATA    => rd_uart,
            HREADYout => rdy_uart,
            HRESP     => rsp_uart,
            rx        => uart_rx,
            tx        => uart_tx
        );

    ----------------------------------------------------------------------------
    -- GPIO
    ----------------------------------------------------------------------------
    u_gpio : entity work.ahb_gpio
        port map (
            HCLK      => hclk,
            HRESETn   => hresetn,
            HSEL      => sel_gpio,
            HADDR     => m_haddr,
            HWRITE    => m_hwrite,
            HTRANS    => m_htrans,
            HWDATA    => m_hwdata,
            HREADYin  => m_hready,
            HRDATA    => rd_gpio,
            HREADYout => rdy_gpio,
            HRESP     => rsp_gpio,
            led       => led,
            sw        => sw,
            btn       => btn
        );

    ----------------------------------------------------------------------------
    -- PWM
    ----------------------------------------------------------------------------
    u_pwm : entity work.ahb_pwm
        port map (
            HCLK      => hclk,
            HRESETn   => hresetn,
            HSEL      => sel_pwm,
            HADDR     => m_haddr,
            HWRITE    => m_hwrite,
            HTRANS    => m_htrans,
            HWDATA    => m_hwdata,
            HREADYin  => m_hready,
            HRDATA    => rd_pwm,
            HREADYout => rdy_pwm,
            HRESP     => rsp_pwm,
            pwm_out   => pwm_led
        );

end architecture rtl;
