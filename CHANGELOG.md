# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[SemVer](https://semver.org/).

## [1.0.0] - 2026-07-08

Reconstruction release. The original 2022 implementation (M.Tech project,
Nirma University) was developed in Xilinx ISE with Keil MDK; its sources were
not preserved. This release rebuilds the project from the surviving project
report with modern engineering practice.

### Added
- VHDL SoC: top level, AHB-Lite decoder, 64 KB BRAM boot memory,
  clock/reset generation.
- VHDL peripherals: UART (8N1, programmable baud), GPIO (debounced buttons),
  8-bit PWM — all AHB-Lite slaves.
- Bare-metal C firmware reproducing the original BTN0–BTN3 serial-menu
  demonstrator; ARMv6-M startup and linker script; GNU Make build.
- Self-checking GHDL testbenches for all three peripherals + CPU bus stub.
- Host-side Unity unit tests (7) for the LED pattern logic.
- `bin2hex.py` firmware-image conversion for VHDL memory init.
- Atlys pin constraints (`.ucf`) with verification warning.
- CI (GitHub Actions): testbenches, unit tests, firmware cross-build.
- Documentation: architecture, memory map, hardware, build, usage, testing,
  roadmap.

### Not included
- The Arm Cortex-M0 DesignStart core (licensed IP — obtain from Arm; see
  `third_party/arm_cortex_m0_designstart/README.md`).
- Utilisation/timing figures (not preserved from the original run; will be
  added when re-measured).
