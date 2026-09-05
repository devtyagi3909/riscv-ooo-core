<div align="center">

# riscv-ooo-core

**Dual-Issue Out-of-Order Superscalar RV32I Processor**

1st Place + Special Jury Award — SanDisk Hardware Hackathon · 100+ competing teams

<br/>
<a href="https://devtyagi3909.github.io/riscv-ooo-core/" target="_blank">
  <img src="https://img.shields.io/badge/Open_Interactive_Architecture_Explorer-cc3d10?style=for-the-badge&logo=vercel&logoColor=white" alt="Architecture Explorer"/>
</a>
<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-cc3d10?style=flat-square)](LICENSE)
[![Language](https://img.shields.io/badge/Language-SystemVerilog-1e4db7?style=flat-square)](rtl/)
[![Simulator](https://img.shields.io/badge/Simulator-Icarus_Verilog-444?style=flat-square)](scripts/)
[![Verified](https://img.shields.io/badge/Verification-UVM-cc3d10?style=flat-square)](tb/)

</div>

---

## Overview

A fully synthesizable out-of-order execution engine implementing the Tomasulo algorithm for the RISC-V RV32I ISA. The front-end — fetch, decode, register renaming, and dynamic hazard-aware dispatch — is complete and verified. ROB commit-stage integration is under active development.

The front-end has been verified in simulation with directed self-checking testbenches. The waveform below demonstrates simultaneous dual-issue dispatch with correct RAT allocation and RAW hazard detection working.

---

## Architecture

```mermaid
flowchart TD
    %% Styling definitions for a sleek, dark aesthetic
    classDef frontEnd fill:#2d3748,stroke:#4a5568,stroke-width:2px,color:#fff
    classDef backEnd fill:#1a365d,stroke:#2b6cb0,stroke-width:2px,color:#fff
    classDef mem fill:#742a2a,stroke:#c53030,stroke-width:2px,color:#fff
    classDef bus fill:#b7791f,stroke:#d69e2e,stroke-width:2px,color:#fff
    
    subgraph FrontEnd ["Front-End (In-Order)"]
        direction LR
        Fetch["2-Wide Fetch<br/>(PC + IMEM)"]:::frontEnd
        Decode["2-Wide Decode<br/>(RV32I)"]:::frontEnd
        RAT["Register Alias Table (RAT)<br/>32 Arch → 64 Phys Regs"]:::frontEnd
        
        Fetch ==> Decode
        Decode ==> RAT
    end
    
    subgraph DispatchQueue ["Out-of-Order Dispatch"]
        direction TB
        Scoreboard["Superscalar Dispatcher<br/>RAW Hazard Scoreboarding"]:::frontEnd
        IQ["Dual-Slot Issue Queue"]:::frontEnd
        Scoreboard --> IQ
    end
    
    RAT ==> Scoreboard
    
    subgraph BackEnd ["Execution & Commit (Out-of-Order)"]
        direction TB
        ALU0["Execution Unit 0<br/>(ALU)"]:::backEnd
        ALU1["Execution Unit 1<br/>(ALU)"]:::backEnd
        
        CDB{{"Common Data Bus (CDB)<br/>Broadcast & Wakeup"}}:::bus
        
        ROB["Reorder Buffer (ROB)<br/>In-Order Commit (WIP)"]:::mem
        
        ALU0 ==> CDB
        ALU1 ==> CDB
        CDB ==> ROB
    end
    
    IQ -->|Issue 0| ALU0
    IQ -->|Issue 1| ALU1
    
    %% Feedback loops
    CDB -.->|Wakeup / Result Bypass| Scoreboard
    ROB -.->|Retire / Free Phys Reg| RAT
```

---

## Verified Functionality

| Component | Status | Notes |
|-----------|--------|-------|
| 2-wide instruction fetch | Complete | PC + IMEM, handles branch boundaries |
| 2-wide decode | Complete | RV32I full decode, immediate gen |
| Register Alias Table (RAT) | Complete | 32 arch → 64 phys, dual-alloc per cycle |
| Free list management | Complete | Circular free list with head/tail pointers |
| RAW hazard detection | Complete | Combinatorial intra-group bypass, scoreboard |
| Issue queue dispatch | Complete | `issue0_valid` + `issue1_valid` verified in sim |
| CDB broadcast | Complete | `broadcast_valid` confirmed in waveform |
| Execution units (ALU) | Complete | Verified via directed self-check |
| ROB commit stage | In progress | Precise exception support being integrated |

---

## Waveform — Dual-Issue Dispatch Proof

![Surfer Waveform: Dual Issue Dispatch](assets/surfer_trace.png)

The waveform shows:
- `issue0_valid` and `issue1_valid` asserting simultaneously — dual-issue working
- `prd_0` and `prd_1` incrementing by 2 each active cycle — RAT dual-allocation correct
- `broadcast_valid` asserted — CDB writeback path active
- `free_ptr` advancing correctly — no free list corruption under back-to-back dispatch

---

## Getting Started

### Prerequisites

```bash
# Icarus Verilog with SystemVerilog support
brew install icarus-verilog   # macOS
sudo apt install iverilog     # Ubuntu

# Waveform viewer
# Surfer (recommended): https://surfer-project.org
# or GTKWave: sudo apt install gtkwave
```

### Run Simulation

```bash
git clone https://github.com/devtyagi3909/riscv-ooo-core.git
cd riscv-ooo-core

# Full directed testbench
./scripts/run_verification.sh

# Expected output:
# [PASS] Reset: PC held at 0
# [PASS] 2-wide fetch/decode: ADDI pair decoded correctly
# [PASS] RAT: prd_0/prd_1 allocated, free_ptr +2 on active cycle
# [PASS] Dispatch: issue0_valid and issue1_valid asserted simultaneously
# [PASS] CDB: broadcast_valid observed
# PASS: cpu_tb directed verification completed with no errors.
```

### View Waveform

```bash
surfer waveforms/cpu.vcd
# or
gtkwave waveforms/cpu.vcd
```

---

## Repository Structure

```
riscv-ooo-core/
├── rtl/                  # Synthesizable SystemVerilog
│   ├── fetch/            # 2-wide instruction fetch
│   ├── decode/           # RV32I decode, immediate generation
│   ├── rename/           # RAT, free list, physical register file
│   ├── dispatch/         # Issue queue, hazard scoreboard
│   └── execute/          # ALU, CDB broadcast
├── tb/
│   └── cpu_tb.v          # Directed self-checking testbench
├── scripts/
│   └── run_verification.sh
├── waveforms/
│   └── cpu.vcd
└── assets/
    └── surfer_trace.png  # Waveform screenshot
```

---

## Hackathon Context

This core was built at the **SanDisk Hardware Hackathon** — a 48-hour hardware design competition judged by senior engineers from Sandisk/Western Digital and academic faculty, fielding over 100 teams from across India.

The submission was awarded:
- **1st Place** — overall hardware design category
- **Special Jury Award** — for microarchitectural depth and correctness of the OoO implementation

---

## References

- Patterson & Hennessy — *Computer Organization and Design: RISC-V Edition*
- Tomasulo, R. (1967). *An Efficient Algorithm for Exploiting Multiple Arithmetic Units*
- RISC-V International — [RISC-V ISA Specification](https://riscv.org/technical/specifications/)

---

## License

MIT — see [LICENSE](LICENSE)
