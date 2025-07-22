# 🚀 RISC-V Processor Implementation on FPGA

Welcome to the official repository for the RISC-V Processor Implementation on FPGA project. This project provides a complete Verilog implementation of a pipelined RISC-V CPU core, integrated into a simple System-on-Chip (SoC) framework. It's designed for educational purposes, rapid prototyping, and exploring RISC-V architecture on hardware.

## 🎯 Project Overview

This project focuses on building a functional RISC-V processor from the ground up in Verilog, emphasizing modularity and hardware efficiency. It demonstrates a practical approach to CPU design, including essential SoC components and a robust data hazard detection mechanism for reliable pipelined execution.

## 📌 Key Features

* **RISC-V CPU Core**: A pipelined CPU core implementing the RISC-V instruction set.
    * **Pipelining**: Enhances instruction throughput.
    * **Data Hazard Detection**: Includes a dedicated unit (`DataHazard.sv`) to detect load-use hazards and implement pipeline stalling, ensuring correct execution.
    * **Configurable**: Parameters allow for enabling/disabling features like multiplication/division and pipeline bypassing.
* **Instruction Memory**: A hardcoded ROM (`instruction_memory.v`) to supply instructions. Easily customizable for different programs.
* **Data Memory (BRAM)**: A block RAM-based data memory (`memory.v`, `data_BRAM.v`) with byte-enable support, communicating with the CPU via a handshake protocol.
* **UART Transmitter**: A simple UART module (`uart.v`) for serial output, useful for debugging and displaying program results on a PC or testbench.
* **Test Programs**: Pre-loaded example programs (e.g., sorting, Fibonacci, arithmetic) in the instruction memory for quick functional verification.

## ⚙️ How It Works

The SoC integrates the custom RISC-V CPU with essential peripherals:

* **Instruction Fetch**: The CPU fetches instructions from the `instruction_memory.v` module.
* **Pipelined Execution**: Instructions move through the pipeline (Fetch, Decode, Execute, Memory, Write-back) for efficient processing.
* **Data Memory Access**: Load and Store instructions interact with the `data_BRAM.v` or `memory.v` modules to read from or write to memory.
* **Hazard Resolution**: The `DataHazard.sv` module continuously monitors the pipeline for potential data hazards (e.g., an instruction needing data not yet available from a previous load) and inserts stall cycles to prevent incorrect behavior.
* **UART Output**: Results or debugging information can be serialized by the `uart.v` module and transmitted serially, allowing observation on a host machine.

*Note: The actual folder names and file placements depend on your exact local organization. The above is a suggested structure based on common practices.*

## 🛠️ Customization & Usage

### Programs:
* To run your own RISC-V code, modify the `instruction_memory.v` module.
* Update the instruction words (Verilog `initial` blocks) with your compiled RISC-V assembly.

### Memory Size:
* Adjust BRAM parameters in `data_BRAM.v` or `memory.v` to change the size of the data memory.

### UART Baud Rate:
* Modify the baud rate divisor in `uart.v` to set your desired serial communication speed.

## 🚀 Simulation & Hardware Deployment

### Simulation:
* Use any Verilog simulator (e.g., Xilinx Vivado Simulator, ModelSim, Icarus Verilog) to run the `top_instruction_reader.v` module (or your main testbench).
* Monitor the UART output for program results and debugging information.

### Synthesis & FPGA Deployment:
* The design is fully synthesizable. Target your specific FPGA board (e.g., Xilinx Artix-7, Zynq).
* Connect the UART output (TxD pin) from your FPGA to a serial-to-USB adapter or a logic analyzer to view the output on your PC's terminal.

## 📜 License

This project is released under the **BSD license**, allowing for free use, modification, and distribution. Please refer to the license header within the individual source files for full details.

## ✉️ Contact

The original core design is attributed to Ultra-Embedded.com. For specific questions regarding this project's implementation, please refer to the detailed comments within the Verilog files or contact the repository maintainer.
