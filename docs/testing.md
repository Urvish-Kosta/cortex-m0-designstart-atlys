# Testing

## Philosophy

Everything that can be verified without the Arm core or the board **is**
verified automatically, in CI, on every push. Hardware bring-up then only has
to debug what simulation cannot see (pinout, clocking, the core itself).

## Layers

| Layer | Tool | What it proves | Command |
|---|---|---|---|
| VHDL peripherals | GHDL testbenches | AHB protocol handling, UART framing, debounce, PWM duty | `./sim/scripts/run_tests.sh` |
| Firmware logic | Unity (host) | animation behaviour, exhaustively | `make -C firmware/test` |
| Firmware build | arm-none-eabi-gcc | image links, vectors at 0x0, warning-free | `make -C firmware` |
| Full SoC | hardware / real core | instruction execution, end-to-end demo | manual |

## VHDL testbenches (sim/testbenches/)

- **tb_ahb_uart** writes a byte through the AHB interface, then decodes the
  serial waveform bit-by-bit at the configured baud rate: start bit, 8 data
  bits LSB-first, stop bit, and the byte value.
- **tb_ahb_gpio** drives AHB write/read transactions: LED register write is
  checked at the pins; switch and debounced-button values are checked through
  AHB reads. The debounce window is shrunk via generic for fast simulation.
- **tb_ahb_pwm** programs a duty cycle, then counts high cycles over one full
  256-cycle period and checks the measured duty.
- **cortexm0ds_stub** is a bus-transaction stub standing in for the Arm core
  so the full SoC elaborates without licensed IP. It is explicitly NOT a CPU
  model and must never be included in a synthesis project.

All benches are self-checking (`assert ... severity failure`) — a failing run
exits non-zero, which is what CI keys on.

## Unit tests (firmware/test/)

Seven Unity tests cover the pure pattern-generator functions, including
invariants (output always one-hot) checked over 1000 iterations and the exact
14-step Cylon bounce period. They compile with the host gcc; no target
toolchain or hardware involved.

## What is intentionally not covered

- Cortex-M0 instruction execution — requires the Arm core (co-simulation with
  the real DesignStart RTL is on the roadmap).
- Timing closure and utilisation — requires an ISE build; numbers will be
  published only when re-measured, never estimated.
