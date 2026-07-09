#!/usr/bin/env bash
# ==============================================================================
# run_tests.sh -- analyse the RTL and run all peripheral testbenches with GHDL.
#
# Usage:  ./sim/scripts/run_tests.sh          (from the repository root)
#
# Requires: ghdl (apt install ghdl). Uses VHDL-93 + Synopsys libraries, which
# mirrors the Xilinx ISE simulation environment the project originally used.
#
# Author: Urvish Kosta
# License: MIT (see LICENSE at repository root)
# ==============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$ROOT/sim/work"
GHDL_FLAGS="--std=93 -fsynopsys --workdir=$WORK"

mkdir -p "$WORK"

echo "== Analysing RTL =="
ghdl -a $GHDL_FLAGS \
    "$ROOT/sim/testbenches/cortexm0ds_stub.vhd" \
    "$ROOT/rtl/peripherals/ahb_uart.vhd" \
    "$ROOT/rtl/peripherals/ahb_gpio.vhd" \
    "$ROOT/rtl/peripherals/ahb_pwm.vhd" \
    "$ROOT/rtl/soc/clk_reset_gen.vhd" \
    "$ROOT/rtl/soc/ahb_decoder.vhd" \
    "$ROOT/rtl/soc/ahb_mem.vhd" \
    "$ROOT/rtl/soc/cm0ds_top.vhd" \
    "$ROOT/sim/testbenches/tb_ahb_uart.vhd" \
    "$ROOT/sim/testbenches/tb_ahb_gpio.vhd" \
    "$ROOT/sim/testbenches/tb_ahb_pwm.vhd" \
    "$ROOT/sim/testbenches/tb_cm0ds_top.vhd"

run_tb () {
    local tb="$1" stop="$2"
    echo "== Running $tb =="
    ghdl -e $GHDL_FLAGS "$tb"
    (cd "$WORK" && ghdl -r --std=93 -fsynopsys "$tb" --stop-time="$stop")
}

run_tb tb_ahb_uart 500us
run_tb tb_ahb_gpio 10us
run_tb tb_ahb_pwm  20us

# Full-SoC smoke test: the CPU stub drives AHB transactions through the whole
# fabric. Needs --syn-binding so the CORTEXM0DS *component* binds to the stub
# *entity*. (Requires cm0ds_top + stub, analysed above.)
echo "== Running tb_cm0ds_top (full-SoC smoke test) =="
ghdl -e $GHDL_FLAGS --syn-binding tb_cm0ds_top
(cd "$WORK" && ghdl -r --std=93 -fsynopsys --syn-binding tb_cm0ds_top --stop-time=5us)

echo ""
echo "All testbenches PASSED."
