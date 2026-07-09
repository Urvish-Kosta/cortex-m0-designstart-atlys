# Memory map

The Cortex-M0 DesignStart core is an AHB-Lite **master**. A small address
decoder (`rtl/soc/ahb_decoder.vhd`) routes accesses to memory and to the
peripheral slaves. All peripherals are AHB-Lite slaves with a 4 KB region each.

Cortex-M0 (ARMv6-M) requires the vector table at address `0x0000_0000` and
executes from low memory after reset, so the boot memory is placed there.

## Regions

| Region        | Base         | Size   | Slave index | Contents                          |
|---------------|--------------|--------|-------------|-----------------------------------|
| Boot ROM/RAM  | `0x0000_0000`| 64 KB  | 0           | Vector table + code + data (BRAM) |
| Reserved      | `0x0001_0000`| ...    | -           | Unmapped (fault on access)        |
| UART          | `0x4000_0000`| 4 KB   | 1           | Serial console, 9600 8N1 default  |
| GPIO          | `0x4000_1000`| 4 KB   | 2           | LEDs, switches, buttons           |
| PWM           | `0x4000_2000`| 4 KB   | 3           | 8-bit PWM channel (LED brightness)|

> The 64 KB boot region is implemented in Spartan-6 block RAM. The XC6SLX45 has
> ~2.1 Mbit of BRAM, so 64 KB (512 Kbit) is comfortably within budget. Reduce
> `MEM_SIZE_BYTES` in the VHDL if you need the BRAM elsewhere.

## UART register map (base `0x4000_0000`)

| Offset | Name    | Access | Bits      | Description                                   |
|--------|---------|--------|-----------|-----------------------------------------------|
| `0x00` | `DATA`  | R/W    | `[7:0]`   | Write = transmit byte; Read = last RX byte    |
| `0x04` | `STATE` | R      | `[0]` TXF | 1 = transmitter busy/full                     |
|        |         |        | `[1]` RXNE| 1 = received byte available                   |
| `0x08` | `BAUD`  | R/W    | `[15:0]`  | Baud divisor = f_clk / baud_rate              |

## GPIO register map (base `0x4000_1000`)

| Offset | Name     | Access | Bits     | Description                          |
|--------|----------|--------|----------|--------------------------------------|
| `0x00` | `LED`    | R/W    | `[7:0]`  | Drive the 8 user LEDs                 |
| `0x04` | `SWITCH` | R      | `[7:0]`  | Read the 8 slide switches            |
| `0x08` | `BUTTON` | R      | `[4:0]`  | Read the push buttons (debounced)    |

## PWM register map (base `0x4000_2000`)

| Offset | Name    | Access | Bits     | Description                                |
|--------|---------|--------|----------|--------------------------------------------|
| `0x00` | `DUTY`  | R/W    | `[7:0]`  | Duty cycle 0-255 (0 = off, 255 = full on)  |
| `0x04` | `EN`    | R/W    | `[0]`    | 1 = PWM output enabled                      |

All registers are 32-bit word-aligned. Byte/halfword strobes are ignored by the
peripherals (word access only), which is sufficient for the demonstrator
firmware.
