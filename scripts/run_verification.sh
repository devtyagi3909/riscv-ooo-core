#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

mkdir -p sim waveforms

iverilog -g2012 -o sim/cpu_sim rtl/*.v tb/cpu_tb.v
vvp sim/cpu_sim

echo "Verification completed. Waveform written to waveforms/cpu.vcd"
