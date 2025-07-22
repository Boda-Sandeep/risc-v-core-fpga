# 🚀 RISC-V Processor Implementation on FPGA

Welcome to my customized implementation of a pipelined RISC-V processor on FPGA. This project represents my individual understanding and contributions to a collaborative academic effort, focused on building a functional Verilog-based RISC-V CPU core, integrated into a minimal System-on-Chip (SoC) environment.

---

## 🎯 Project Overview

The project showcases a modular, 5-stage pipelined RISC-V CPU architecture built from scratch in Verilog. It explores key aspects of hardware design such as instruction execution, memory access, pipeline hazards, and peripheral integration. The SoC supports basic memory-mapped I/O and UART communication, making it both educational and practically deployable.

---

## 📌 Key Features

- **Pipelined RISC-V CPU Core** – Implements a 5-stage pipeline (IF, ID, EX, MEM, WB)
- **Matrix Multiplication Example** – A test program implemented in RISC-V assembly to demonstrate functionality
- **Data Hazard Detection** – Load-use hazard detection and stall insertion using `DataHazard.sv`
- **Data Memory (BRAM)** – Byte-addressable memory with handshake support
- **UART Output** – Serial communication via a simple UART module (`uart.v`)
- **Instruction ROM** – Easily modifiable for uploading custom assembly programs
- **Configurable Modules** – Enable/disable features like multiplication or bypassing

---

## 🛠️ My Contributions

As this is a group projrct, during the development of this project, I focused on the following key areas:

 Implemented matrix multiplication using **blocked DGEMM** approach.
- Analyzed performance bottlenecks and realized the potential of **systolic array** architecture.
- Developed a separate systolic array-based matrix multiplication accelerator using FSM and pipelined Verilog modules.
- Connected memory modules to simulate and validate data loading and storage.
- Integrated UART interface to support data transfer and debugging.
- Debugged interconnections between modules to understand the RISC-V pipeline and accelerator interface.

---

## ⚙️ System Architecture Overview

The SoC includes the following major components:

- **Instruction Fetch** – Instructions loaded from `instruction_memory.v`
- **Pipelined Execution** – Instructions processed across the pipeline stages
- **Memory Access** – Reads and writes handled via `memory.v` or `data_BRAM.v`
- **Hazard Handling** – `DataHazard.sv` ensures correct stall cycles
- **UART Transmission** – Debug output or program results sent serially

---

## 💡 Customization Guide

- **To Run Custom Programs** – Modify `instruction_memory.v` with your own compiled RISC-V instructions
- **Memory Size** – Adjustable in `data_BRAM.v` or `memory.v`
- **Baud Rate** – Change the UART divisor in `uart.v` for different communication speeds

---

## 🧪 Simulation & Deployment

- **Simulation Tools** – Use Vivado Simulator, ModelSim, or Icarus Verilog to run testbenches
- **Hardware Deployment** – Synthesizable on FPGAs like Xilinx Artix-7 or Zynq. UART output can be monitored via USB-to-serial interface

---

## 📜 License

This project is distributed under the BSD license. The base design references modules and concepts from [Ultra-Embedded.com](https://www.ultra-embedded.com/risc-v/). All source files include license headers where applicable.

---  
## Project Structure 
├── matrix_multiplier/
│ ├── dgemm_blocked.v # 4x4 blocked matrix multiplication (DGEMM approach)
│ ├── systolic_array.v # Systolic array accelerator
│ ├── fsm_controller.v # FSM to control stages of computation
│ └── testbench/ # Testbenches for simulation and verification
├── memory/
│ ├── data_memory.v # Memory interface for matrices
│ └── uart_interface.v # UART module for data IO
├── riscv_debug/
│ └── riscv_connections.v # Debugging module-to-module connections
├── README.md # This file

## 👤 Maintainer

**Boda Sandeep**  
📧 stylesandeep053@gmail.com  
🔗 [GitHub: Boda-Sandeep](https://github.com/Boda-Sandeep)

> This repository reflects my individual implementation and understanding as part of a group project completed for academic purposes.

