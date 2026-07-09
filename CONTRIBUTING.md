# Contributing

This is a personal portfolio project, but issues and pull requests are
welcome — especially hardware-verification reports on real Atlys boards.

## Ground rules
- **Never commit Arm IP.** The `.gitignore` blocks
  `third_party/arm_cortex_m0_designstart/`; do not work around it.
- All CI checks must pass: GHDL testbenches, Unity tests, firmware build
  (warning-free under `-Wall -Wextra -Werror`).
- RTL changes need a testbench change (new behaviour = new checks).
- Keep the memory map consistent in all three places it is defined:
  `docs/memory-map.md`, the VHDL peripherals, `firmware/include/soc_regs.h`.

## Commit style
Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`,
`build:`, `ci:`, `chore:`. One logical change per commit.

## Running the checks locally
```bash
./sim/scripts/run_tests.sh
make -C firmware/test
make -C firmware
```
