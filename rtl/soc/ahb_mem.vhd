--------------------------------------------------------------------------------
-- ahb_mem.vhd
--
-- AHB-Lite boot memory for the Cortex-M0 DesignStart SoC. Implemented as a
-- single-port synchronous RAM inferred into Spartan-6 block RAM. Holds the
-- vector table, code and data. Initialised at elaboration from a hex file so
-- that simulation and (optionally) synthesis start with the firmware in place.
--
-- Word-addressed internally; the AHB byte address is shifted right by 2. Only
-- 32-bit word accesses are supported, which matches the demonstrator firmware.
--
-- The init file "firmware.hex" contains one 32-bit hex word per line (see
-- scripts/bin2hex.py). If the file is absent, memory starts cleared.
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
-- std_logic_textio provides hread() for std_logic_vector. It ships with both
-- Xilinx ISE (as ieee.std_logic_textio) and GHDL. If your simulator only
-- provides it under a different library, adjust this use clause accordingly.
use ieee.std_logic_textio.all;

entity ahb_mem is
    generic (
        MEM_SIZE_BYTES : integer := 65536;          -- 64 KB
        INIT_FILE      : string  := "firmware.hex"
    );
    port (
        HCLK      : in  std_logic;
        HRESETn   : in  std_logic;
        HSEL      : in  std_logic;
        HADDR     : in  std_logic_vector(31 downto 0);
        HWRITE    : in  std_logic;
        HTRANS    : in  std_logic_vector(1 downto 0);
        HSIZE     : in  std_logic_vector(2 downto 0);
        HWDATA    : in  std_logic_vector(31 downto 0);
        HREADYin  : in  std_logic;
        HRDATA    : out std_logic_vector(31 downto 0);
        HREADYout : out std_logic;
        HRESP     : out std_logic
    );
end entity ahb_mem;

architecture rtl of ahb_mem is

    constant WORDS : integer := MEM_SIZE_BYTES / 4;
    constant AW    : integer := 16;   -- word-address bits (64 KB / 4 = 16 Kwords -> 14 bits; extra headroom)

    type ram_t is array (0 to WORDS-1) of std_logic_vector(31 downto 0);

    -- Load init file at elaboration.
    impure function load_hex(fname : string) return ram_t is
        file     f    : text;
        variable l    : line;
        variable w    : std_logic_vector(31 downto 0);
        variable idx  : integer := 0;
        variable mem  : ram_t := (others => (others => '0'));
        variable ok   : file_open_status;
    begin
        file_open(ok, f, fname, read_mode);
        if ok = open_ok then
            while not endfile(f) and idx < WORDS loop
                readline(f, l);
                hread(l, w);
                mem(idx) := w;
                idx := idx + 1;
            end loop;
            file_close(f);
        end if;
        return mem;
    end function;

    signal ram : ram_t := load_hex(INIT_FILE);

    signal word_addr : integer range 0 to WORDS-1 := 0;
    signal rd_en     : std_logic := '0';

begin

    HREADYout <= '1';
    HRESP     <= '0';

    process (HCLK)
        variable a : integer;
    begin
        if rising_edge(HCLK) then
            rd_en <= '0';
            if HREADYin = '1' and HSEL = '1' and HTRANS(1) = '1' then
                a := to_integer(unsigned(HADDR(AW+1 downto 2)));  -- byte->word
                if a < WORDS then
                    word_addr <= a;
                    if HWRITE = '1' then
                        ram(a) <= HWDATA;
                    else
                        rd_en <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    HRDATA <= ram(word_addr);

end architecture rtl;
