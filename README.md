# RISC-V Out-of-Order Superscalar Core (Partial Implementation)

A Verilog implementation of a dual-issue, out-of-order execution pipeline based on the RISC-V architecture. 

This project currently demonstrates a fully functional front-end superscalar dispatcher with dynamic Register Alias Table (RAT) allocation and hazard detection. The back-end (Common Data Bus broadcast, Reorder Buffer commit) is still under active development.

## Architecture Highlights

* Dual-Issue Fetch and Decode: Fetches and decodes two 32-bit instructions per clock cycle.
* Dynamic Register Renaming (RAT): Maps 32 architectural registers to 64 physical registers. Handles simultaneous dual-allocation to prevent structural hazards and implements combinatorial intra-group bypassing.
* Superscalar Dispatcher: Detects Read-After-Write (RAW) hazards and dynamically stalls dependent instructions in the issue queue while allowing independent instructions to proceed simultaneously.

## Current Status

* [x] Dual Instruction Fetch
* [x] Instruction Decode
* [x] Register Renaming (RAT) and Free List Management
* [x] Issue Queue Dispatch and RAW Hazard Scoreboarding
* [ ] Execution Units (ALU) and Common Data Bus (CDB) Wakeup
* [ ] Reorder Buffer (ROB) and Precise In-Order Commit

## Getting Started

### Prerequisites
* Icarus Verilog (iverilog) with SystemVerilog support (-g2012).
* Surfer or GTKWave for waveform viewing.

### Running the Simulation
1. Clone the repository.
2. Run the lightweight verification script:
   ./scripts/run_verification.sh
3. Open the waveform in Surfer:
   surfer waveforms/cpu.vcd

### Verification
`tb/cpu_tb.v` now performs directed self-checks and fails the simulation on mismatch. The checks cover:

* Reset behavior (PC held at 0).
* 2-wide fetch/decode of the first instruction pair (`ADDI`, `ADDI`).
* RAT dual-allocation behavior (`prd_0`/`prd_1` and `free_ptr` increments by 2 on active cycles).
* Basic scheduler/execution liveness (`issue0_valid` and `broadcast_valid` observed).

If all checks pass, simulation prints:
`PASS: cpu_tb directed verification completed with no errors.`

### Proof of Dual-Issue Dispatch
![Surfer Waveform: Dual Issue Dispatch Proof](assets/surfer_trace.png)
