# Matrix Multiplication in hardware

## Overview
This repository contains the Verilog RTL design and verification environment for a hardware-accelerated matrix multiplication system, originally developed for the Digital Systems II coursework at the University of California, Davis. The core system is designed to compute the product of two 8x8 matrices using custom multiply-accumulate (MAC) architecture.

## System Architecture
* **MAC Unit:** Implements a custom Multiply Accumulator (MAC) that processes two 8-bit signed 2's complement inputs and maintains the running sum in a 19-bit signed accumulator register.
* **Parallel Processing:** Features a dual-ported memory architecture coupled with two independent MAC modules, allowing the system to fetch multiple operands and calculate two product entries in parallel.
* **Memory Management:** The 8x8 input matrices are stored in 64x8 RAM blocks formatted in column-major order. To handle simultaneous calculations, computed values are held in a 19-bit buffer register before being written sequentially to the single-ported 64x19 output RAM.
* **Control Logic:** Orchestrated by a custom Finite State Machine (FSM) that manages complex memory addressing schemes to fetch data efficiently without relying on standard software FOR-loops. 
* **Throughput Optimization:** Datapath pipelining and parallel MAC usage were implemented to maximize computational throughput (MAC/s). 

## Verification & Synthesis
* **Functional Verification:** Rigorously tested using custom testbenches, extracting and comparing internal RAM contents against expected matrix calculation results to ensure functional correctness.
* **Performance Tracking:** Integrated a custom clock cycle counter into the FSM to accurately profile execution time and identify architectural bottlenecks.
* **Resource Utilization:** Analyzed synthesis results for hardware resource usage, including logic elements, flip-flops, and specialized M9K dual-ported memory blocks.

## Technologies & Tools
* **Hardware Description Language:** Verilog
* **Simulation:** ModelSim
* **Target Architecture:** FPGA (utilizing embedded multipliers and M9K memory blocks)

## Repository Structure
* `/src`: Contains all Verilog RTL source files (`.v`), including the MAC module, FSM controller, and top-level design.
* `/tb`: Contains testbenches and initialization files (`ram_a_init.txt`, `ram_b_init.txt`) used for memory loading via `$readmemb()`.

## Visuals
> <img width="284" height="339" alt="Screenshot 2026-03-19 at 12 24 07 PM" src="https://github.com/user-attachments/assets/7f56c462-083a-47cb-9030-29757bf40894" />

<img width="292" height="307" alt="Screenshot 2026-03-19 at 12 23 43 PM" src="https://github.com/user-attachments/assets/d8705355-5389-4e29-87c2-3d0dc4423b39" />
