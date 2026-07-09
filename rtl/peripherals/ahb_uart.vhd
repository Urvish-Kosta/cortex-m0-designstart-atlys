--------------------------------------------------------------------------------
-- ahb_uart.vhd
--
-- AHB-Lite UART peripheral for the Cortex-M0 DesignStart SoC.
--
-- 8N1, configurable baud via the BAUD divisor register. The default divisor is
-- set for 9600 baud at the SoC system clock (see generic CLK_HZ). Word access
-- only; byte/halfword strobes are not decoded.
--
-- Register map (offsets from the peripheral base):
--   0x00 DATA  : write -> load TX byte; read -> last RX byte
--   0x04 STATE : bit0 TX busy, bit1 RX data ready
--   0x08 BAUD  : baud divisor = CLK_HZ / baud_rate
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ahb_uart is
    generic (
        CLK_HZ    : integer := 50_000_000;  -- SoC system clock
        BAUD_RATE : integer := 9600
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
        -- Serial pins
        rx        : in  std_logic;
        tx        : out std_logic
    );
end entity ahb_uart;

architecture rtl of ahb_uart is

    constant DEFAULT_DIV : integer := CLK_HZ / BAUD_RATE;

    -- AHB address phase capture
    signal addr_q  : std_logic_vector(3 downto 0);
    signal write_q : std_logic;
    signal valid_q : std_logic;

    -- Register file
    signal baud_div : unsigned(15 downto 0) := to_unsigned(DEFAULT_DIV, 16);

    -- Transmitter
    signal tx_shift  : std_logic_vector(9 downto 0) := (others => '1');
    signal tx_bits   : integer range 0 to 10 := 0;
    signal tx_cnt    : unsigned(15 downto 0) := (others => '0');
    signal tx_busy   : std_logic := '0';
    signal tx_start  : std_logic := '0';
    signal tx_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_line   : std_logic := '1';

    -- Receiver
    signal rx_sync   : std_logic_vector(1 downto 0) := (others => '1');
    signal rx_bits   : integer range 0 to 10 := 0;
    signal rx_cnt    : unsigned(15 downto 0) := (others => '0');
    signal rx_shift  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_busy   : std_logic := '0';
    signal rx_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ready  : std_logic := '0';

begin

    tx <= tx_line;

    --------------------------------------------------------------------------
    -- AHB address phase: capture request when selected and active.
    --------------------------------------------------------------------------
    ahb_addr_phase : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                addr_q  <= (others => '0');
                write_q <= '0';
                valid_q <= '0';
            elsif HREADYin = '1' then
                -- HTRANS(1) = '1' indicates NONSEQ/SEQ (a real transfer)
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
    -- AHB data phase: register writes, and TX kick-off.
    --------------------------------------------------------------------------
    ahb_write : process (HCLK)
    begin
        if rising_edge(HCLK) then
            tx_start <= '0';
            if HRESETn = '0' then
                baud_div <= to_unsigned(DEFAULT_DIV, 16);
            elsif valid_q = '1' and write_q = '1' then
                case addr_q is
                    when x"0" =>                      -- DATA: transmit
                        if tx_busy = '0' then
                            tx_byte  <= HWDATA(7 downto 0);
                            tx_start <= '1';
                        end if;
                    when x"8" =>                      -- BAUD
                        baud_div <= unsigned(HWDATA(15 downto 0));
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- AHB read data mux (data phase, one cycle after address phase).
    --------------------------------------------------------------------------
    ahb_read : process (addr_q, rx_data, tx_busy, rx_ready, baud_div)
    begin
        HRDATA <= (others => '0');
        case addr_q is
            when x"0" =>
                HRDATA(7 downto 0) <= rx_data;
            when x"4" =>
                HRDATA(0) <= tx_busy;
                HRDATA(1) <= rx_ready;
            when x"8" =>
                HRDATA(15 downto 0) <= std_logic_vector(baud_div);
            when others =>
                HRDATA <= (others => '0');
        end case;
    end process;

    -- Reading the DATA register clears the RX-ready flag.
    rx_clear : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                rx_ready <= '0';
            else
                if rx_busy = '0' and rx_bits = 10 then
                    rx_ready <= '1';          -- byte just completed
                elsif valid_q = '1' and write_q = '0' and addr_q = x"0" then
                    rx_ready <= '0';          -- cleared on read of DATA
                end if;
            end if;
        end if;
    end process;

    -- This peripheral never stalls and never errors.
    HREADYout <= '1';
    HRESP     <= '0';

    --------------------------------------------------------------------------
    -- Transmitter: shift out start bit, 8 data bits (LSB first), stop bit.
    --------------------------------------------------------------------------
    transmit : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                tx_line  <= '1';
                tx_busy  <= '0';
                tx_bits  <= 0;
                tx_cnt   <= (others => '0');
                tx_shift <= (others => '1');
            else
                if tx_busy = '0' then
                    tx_line <= '1';
                    if tx_start = '1' then
                        -- Load {stop, data[7:0], start}; drive the start bit now.
                        tx_line  <= '0';                       -- start bit
                        tx_shift <= '1' & '1' & tx_byte;        -- next: data then stop
                        tx_bits  <= 9;                          -- 8 data + 1 stop remain
                        tx_cnt   <= baud_div - 1;
                        tx_busy  <= '1';
                    end if;
                else
                    if tx_cnt = 0 then
                        tx_line  <= tx_shift(0);
                        tx_shift <= '1' & tx_shift(9 downto 1);
                        tx_cnt   <= baud_div - 1;
                        if tx_bits = 1 then
                            tx_busy <= '0';
                        else
                            tx_bits <= tx_bits - 1;
                        end if;
                    else
                        tx_cnt <= tx_cnt - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- Receiver: 2-FF synchroniser, start-bit detect, mid-bit sampling.
    --------------------------------------------------------------------------
    receive : process (HCLK)
        variable half : unsigned(15 downto 0);
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                rx_sync  <= (others => '1');
                rx_busy  <= '0';
                rx_bits  <= 0;
                rx_cnt   <= (others => '0');
                rx_shift <= (others => '0');
                rx_data  <= (others => '0');
            else
                rx_sync <= rx_sync(0) & rx;
                half    := '0' & baud_div(15 downto 1);

                if rx_busy = '0' then
                    if rx_sync(1) = '0' then          -- falling edge = start bit
                        rx_busy <= '1';
                        rx_cnt  <= half;              -- sample at mid-bit
                        rx_bits <= 0;
                    end if;
                else
                    if rx_cnt = 0 then
                        rx_cnt <= baud_div;
                        if rx_bits = 0 then
                            -- confirm start bit still low, then move to data
                            rx_bits <= rx_bits + 1;
                        elsif rx_bits <= 8 then
                            rx_shift <= rx_sync(1) & rx_shift(7 downto 1);
                            rx_bits  <= rx_bits + 1;
                        else
                            -- stop bit
                            rx_data <= rx_shift;
                            rx_bits <= 10;
                            rx_busy <= '0';
                        end if;
                    else
                        rx_cnt <= rx_cnt - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
