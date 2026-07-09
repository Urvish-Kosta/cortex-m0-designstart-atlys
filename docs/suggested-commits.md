# Suggested commit sequence

The repository ships as a snapshot. To present a clean, logical history on
GitHub, initialise and commit in these stages (Conventional Commits style,
one logical change each) rather than a single "initial commit".

```bash
git init

# 1. Licensing and project scaffolding first — establishes IP boundaries.
git add LICENSE .gitignore third_party/ CODE_OF_CONDUCT.md CONTRIBUTING.md SECURITY.md
git commit -m "chore: add licensing, IP boundary, and community docs"

# 2. Memory map — the contract everything else follows.
git add docs/memory-map.md
git commit -m "docs: define SoC memory map and register layout"

# 3. Peripherals.
git add rtl/peripherals/
git commit -m "feat: add AHB-Lite UART, GPIO, and PWM peripherals (VHDL)"

# 4. SoC fabric.
git add rtl/soc/
git commit -m "feat: add SoC top level, AHB decoder, boot memory, clocking"

# 5. Simulation and testbenches.
git add sim/
git commit -m "test: add self-checking testbenches and CPU bus stub"

# 6. Firmware.
git add firmware/src firmware/include firmware/link.ld firmware/Makefile scripts/
git commit -m "feat: add bare-metal demonstrator firmware and image tooling"

# 7. Firmware unit tests.
git add firmware/test/
git commit -m "test: add host-side Unity tests for LED pattern logic"

# 8. Constraints.
git add constraints/
git commit -m "build: add Atlys pin and timing constraints"

# 9. CI.
git add .github/
git commit -m "ci: run testbenches, unit tests, and firmware build on push"

# 10. Documentation and diagrams.
git add docs/ diagrams/ examples/ README.md CHANGELOG.md
git commit -m "docs: add architecture, hardware, build, usage, and diagrams"

git branch -M main
# git remote add origin git@github.com:Urvish-Kosta/cortex-m0-designstart-atlys.git
# git push -u origin main
```

Suggested repository metadata on GitHub:
- **Description**: "Arm Cortex-M0 DesignStart SoC on Spartan-6 (Atlys): VHDL
  AHB-Lite peripherals, bare-metal firmware, verified testbenches, CI."
- **Topics**: `fpga`, `vhdl`, `cortex-m0`, `arm`, `designstart`, `spartan-6`,
  `soc`, `ahb-lite`, `embedded`, `bare-metal`, `xilinx`, `rtl`
- Create a **v1.0.0 release** tag once pushed.
